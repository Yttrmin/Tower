/** A component for performing A* searches between two blocks. */
class TowerAStarComponent extends ActorComponent
	config(Tower);

// A 3x3x3 cube minus the center.
const POSSIBLE_AIRS_ALL_NEIGHBORS = 26;
// A + sign layered three times vertically minus the center.
const POSSIBLE_AIRS_NO_CORNERS = 14;
const INVALID_PATH_ID = -1;

struct PathRoot
{
	var bool bReady;
	var bool bSuccess;
	var TowerAIObjective ObjectiveStart;
	var TowerBlock Start, Finish;
	var int ID;
	
	/*structdefaultproperties
	{
		ID=-1
		bReady=true
		bSuccess=false
	}*/
};

var const private PathRoot NullPathRoot;

var privatewrite array<TowerAIObjective> Paths;
var const private IVector PossibleAirs[POSSIBLE_AIRS_NO_CORNERS];

/** Enables the ability to step through a search. Overrides IterationsPerTick and bDeferSearching! */
var privatewrite bool bStepSearch;
/** Draws debug information on the HUD about our current step. */
var private bool bDrawStepInfo;
var private bool bLogIterationTime;
var private array<delegate<OnPathGenerated> > PathGeneratedDelegates;

var private TowerGame Game;
var private TowerFactionAIHivemind Hivemind;

/** Next PathID to use when we need one for GeneratePath. */
var private int NextPathID;
/** Current Path we're working on. Should it be first-come first-serve or what? */
var private PathRoot CurrentPath;
/** Holds all the paths that need generating, including the CurrentPathID one. */
var private array<PathRoot> QueuedPaths;

//=============================================================================
// Deferred search variables.
/** After every IterationsPerTick amount of iterations, save the state of the search and continue next tick. */
var private config bool bDeferSearching;
/** How many iterations to do before deferring to the next tick. */
var private config int IterationsPerTick;
/** Are we currently deferring to next tick? */
var deprecated privatewrite bool bDeferred;
/** Is the search done but we're deferring anyways? Used so the final step is of the finished path. */
var deprecated private bool bDeferredDone;
/** To step or not. Used when step searching. */
var private bool bStep;
/** A copy of the OpenList and ClosedList before deferring. */
var deprecated private PriorityQueue DeferredOpenList;
var deprecated private array<TowerBlock> DeferredClosedList;
var deprecated private array<IVector> DeferredAirList;
var deprecated private array<IVector> DeferredAirReferenceList;
/** Reference to the best block before deferring. */
var deprecated private TowerBlock StepBestBlock;
/** Used to represent the different nodes when stepping. */
var private array<TowerAIObjective> StepMarkers;
/** The ACTUAL iteration we're on, regardless of whether we defer or not. */
var deprecated private int Iteration;

/** Cached GridOrigin so we don't have to jump through several variables for every air block. */
var private Vector GridOrigin;

delegate OnPathGenerated(const bool bSuccessful, const int PathID, TowerAIObjective Root);

/** Called from TowerGame when requested.
Used to call OnPathGenerated during PreAsync so factions can actually spawn/queue stuff in response. */
final event PreAsyncTick(float DeltaTime)
{
	local int i;
	local delegate<OnPathGenerated> PathGeneratedDelegate;
	// I'm fairly sure a foreach would result in copying the struct for every iteration.
	for(i = 0; i < QueuedPaths.Length; i++)
	{
		if(QueuedPaths[i].bReady)
		{
			if(QueuedPaths[i].bSuccess)
			{
				Paths.AddItem(QueuedPaths[i].ObjectiveStart);
			}
			foreach PathGeneratedDelegates(PathGeneratedDelegate)
			{
				PathGeneratedDelegate(QueuedPaths[i].bSuccess, QueuedPaths[i].ID, 
					QueuedPaths[i].ObjectiveStart);
			}
			QueuedPaths[i] = NullPathRoot;
		}
	}
	QueuedPaths.RemoveItem(NullPathRoot);
	Game.UnRegisterForPreAsyncTick(PreAsyncTick);
}

/** Called from TowerFactionAIHivemind when requested.
Used to call GeneratePath for our CurrentPathID, for maximum efficiency. */
final event AsyncTick(float DeltaTime)
{
	GeneratePath(CurrentPath.Start,CurrentPath.Finish,CurrentPath.ID);
}

final event Initialize(optional delegate<OnPathGenerated> PathGeneratedDelegate, 
	optional bool bNewDeferSearching=default.bDeferSearching,
	optional int NewIterationsPerTick=default.IterationsPerTick, optional bool bNewStepSearch=false,
	optional bool bNewDrawStepInfo=false)
{
	GridOrigin = TowerGameReplicationInfo(Owner.WorldInfo.GRI).GridOrigin;
	Game = TowerGame(Owner.WorldInfo.Game);
	Hivemind = Game.Hivemind;
	AddOnPathGeneratedDelegate(PathGeneratedDelegate);
	bDeferSearching = bNewDeferSearching;
	IterationsPerTick = NewIterationsPerTick;
	bStepSearch = bNewStepSearch;
	bDrawStepInfo = bNewDrawStepInfo;
}

function int CompareBlocks(Object A, Object B)
{
	return TowerBlock(A).Fitness - TowerBlock(B).Fitness;
}

final function Step()
{
	local TowerAIObjective Marker;
	// Clean out old markers now since we can't during AsyncTick.
	foreach StepMarkers(Marker)
	{
		Marker.Destroy();
	}
	bStep = true;
}

final function AddOnPathGeneratedDelegate(delegate<OnPathGenerated> ToAdd)
{
	if(ToAdd != None && PathGeneratedDelegates.Find(ToAdd) == INDEX_NONE)
	{
		PathGeneratedDelegates.AddItem(ToAdd);
	}
}

final function RemoveOnPathGeneratedDelegate(delegate<OnPathGenerated> ToRemove)
{
	local int RemoveIndex;

	RemoveIndex = PathGeneratedDelegates.Find(ToRemove);
	if(RemoveIndex != INDEX_NONE)
	{
		PathGeneratedDelegates.Remove(RemoveIndex, 1);
	}
}

/** Runs the A* search from Start to Finish.
YOU should NEVER supply a PathID! It's used internally by other classes to handle deferred/queued searching.
*/
//@TODO - Return PathID. Either the one passed in or a generated one if -1.
final function int GeneratePath(TowerBlock Start, TowerBlock Finish, optional int PathID=-1)
{
	local PathRoot Path;
	/** OpenList = Blocks that haven't been explored yet. ClosedList = Blocks that have been explored.
	Explored = Looked at every node connected to this one, calculate dtheir F, G, and H, and placed them in OpenList. */
	local PriorityQueue OpenList;
	local array<TowerBlock> ClosedList;
	local array<IVector> AirList;
	local array<TowerBlockAir> AirReferenceList;
	/** References whichever Block in the OpenList that has the lowest Fitness. */
	local TowerBlock BestBlock;
	local int i;
	// To avoid warning with using variable before assigned.
	BestBlock = None;
	if(PathID == -1)
	{
		PathID = NextPathID;
		NextPathID++;
		Path.ID = PathID;
		Path.Start = Start;
		Path.Finish = Finish;
		CurrentPath = Path;
		QueuedPaths.AddItem(Path);
		if(CurrentPath.ID == -1)
		{
			CurrentPath.ID = PathID;
		}
		if(bDeferSearching && IterationsPerTick > 0)
		{
			// Could be deferring, register for AsyncTick.
			Hivemind.RegisterForAsyncTick(AsyncTick);
		}
	}
	//@TODO - `if `isdefined debug
	if(bStepSearch && !bStep)
	{
		// If we're step searching but haven't been told to step, get out of here!
		return PathID;
	}
	else
	{
		// Set to false so the user has to press step again to step.
		bStep = false;
	}
	// If we just got back from deferring, copy the deferred data back.
	if(bDeferSearching && bDeferred)
	{
		OpenList = DeferredOpenList;
		ClosedList = DeferredClosedList;
		bDeferred = false;
	}
	else
	{
		Iteration = 0;
		`log("================== STARTING A* ==================",,'AStar');
		`log("Start:"@Start@" "@"Finish:"@Finish,,'AStar');
		Start.BaseCost = 0;
		// #2
		CalculateCosts(Start, Finish, GetGoalCost(Start));
		// Add our Starting block to the OpenList and start pathfinding!
		// #3
		OpenList = new class'PriorityQueue';
		OpenList.Add(Start);
	}
	while(OpenList.Length() > 0)
	{
		// If we're defer searching and hit IterationsPerTick, defer!
		if(bDeferSearching && i >= IterationsPerTick)
		{
			// Defer.
			StepBestBlock = BestBlock;
			if(bStepSearch)
			{
				// If we're stepping, draw debug information.
				DebugCreateStepMarkers(OpenList, ClosedList);
			}
			bDeferred = true;
			DeferredOpenList = OpenList;
			DeferredClosedList = ClosedList;
			return PathID;
		}
		// bDeferredDone means the search IS done, so don't increment any iterator values.
		if(!bDeferredDone)
		{
			i++;
			Iteration++;
		}
//		`log("Iteration"@Iteration);
		BestBlock = OpenList.Remove();
//		`log("Iteration"@Iteration$": Best:"@BestBlock@"Score:"@BestBlock.Fitness,!bDeferredDone,'AStar');
		if(BestBlock == Finish)
		{
			// We're done.
			// Buy us one more step so the user can see the final result before the search is finished.
			bDeferredDone = !bDeferredDone;
			if(bStepSearch && bDeferredDone)
			{
				StepBestBlock = BestBlock;
				// If we're stepping, draw debug information.
				DebugCreateStepMarkers(OpenList, ClosedList);
				// Defer one last time so we can see the end.
				bDeferred = true;
				DeferredOpenList = OpenList;
				DeferredClosedList = ClosedList;
				return PathID;
			}
			bDeferredDone = false;
			ConstructPath(Finish);
			break;
		}
		else if(BestBlock == None)
		{
			// No path?! How?! What?
		}
		AddAdjacentBlocks(OpenList, ClosedList, BestBlock, Finish, AirList, AirReferenceList);
		ClosedList.AddItem(BestBlock);
	}
	`log("================== FINISHED A* ==================",,'AStar');
	OpenList.Dispose();
	return PathID;
}

private final function AddAdjacentBlocks(out PriorityQueue OpenList, out array<TowerBlock> ClosedList, 
	TowerBlock SourceBlock, TowerBlock Finish, out array<IVector> AirList, out array<TowerBlockAir> AirReferenceList)
{
	local array<TowerBlock> AdjacentList;
	local TowerBlock IteratorBlock;
	local TowerBlockAir IteratorAirBlock;
	// Add everything to a single array so we can iterate through it easily.
	foreach SourceBlock.CollidingActors(class'TowerBlock', IteratorBlock, 200,, true)
	{
		if(IteratorBlock.bDebugIgnoreForAStar)
		{
			continue;
		}
		//check for each neighbor's air since it won't get picked up by CollidingActors.
		/*foreach IteratorBlock.BasedActors(class'TowerBlockAir', IteratorAirBlock)
		{
			if((IsDiagonalTo(IteratorAirBlock, SourceBlock) || IsAdjacentTo(IteratorAirBlock, SourceBlock)))
			{
				AdjacentList.AddItem(IteratorAirBlock);
			}
		}
		*/
		AdjacentList.AddItem(IteratorBlock);
	}
	AddAdjacentAirBlocks(SourceBlock.GridLocation, AdjacentList, AirList, AirReferenceList);
	foreach AdjacentList(IteratorBlock)
	{
		if(IteratorBlock == SourceBlock)
		{
			continue;
		}
		if(OpenList.Contains(IteratorBlock))
		{
			// Already in OpenList.
			if(IteratorBlock.GoalCost > SourceBlock.GoalCost)
			{
				// Better path?
				IteratorBlock.AStarParent = SourceBlock;
				CalculateCosts(IteratorBlock, Finish, GetGoalCost(IteratorBlock));
			}
		}
		else if(ClosedList.Find(IteratorBlock) != -1)
		{
			// Already in ClosedList.
			if(IteratorBlock.GoalCost > SourceBlock.GoalCost)
			{
				// Better path?
//				`log("Better path in the closed list shouldn't happen!(?)",,'AStar');
				IteratorBlock.AStarParent = SourceBlock;
				CalculateCosts(IteratorBlock, Finish, GetGoalCost(IteratorBlock));
				UpdateParents(IteratorBlock, Finish);
			}
		}
		else
		{
			// Not in either list.
			IteratorBlock.AStarParent = SourceBlock;
			CalculateCosts(IteratorBlock, Finish, GetGoalCost(IteratorBlock));
			OpenList.Add(IteratorBlock);
		}
	}
}

/** Populates AdjacentList with air blocks adjacent to Center. */
private final function AddAdjacentAirBlocks(const out IVector Center, out array<TowerBlock> AdjacentList
	, out array<IVector> AirList, out array<TowerBlockAir> AirReferenceList)
{
	local array<IVector> PossibleLocations;
	local int i, u, Index;
	
	/** Build up all possible block locations. */
	for(i = 0; i < ArrayCount(PossibleAirs); i++)
	{
		PossibleLocations[i] = PossibleAirs[i] + Center;
	}

	/** If a block's in one of the possible locations, there can't be an air. */
	for(i = 0; i < AdjacentList.Length; i++)
	{
		PossibleLocations.RemoveItem(AdjacentList[i].GridLocation);
	}

	/** Spawn an air for each possible location. */
	for(i = 0; i < PossibleLocations.Length; i++)
	{
		// Set location here.
		//@TODO - Test performance to see if we need a pool.
		if(PossibleLocations[i].Z < 0)
		{
			continue;
		}
		Index = INDEX_NONE;
		for(u = 0; u < AirList.Length; u++)
		{
			if(AirList[u] == PossibleLocations[i])
			{
				Index = u;
				break;
			}
		}
		if(Index != INDEX_NONE)
		{
			AdjacentList.AddItem(AirReferenceList[Index]);
		}
		else
		{
			AdjacentList.AddItem(Owner.Spawn(class'TowerBlockAir',,,GridLocationToVector(PossibleLocations[i]),,
				TowerGameBase(Owner.WorldInfo.Game).AirArchetype));
			AdjacentList[AdjacentList.Length-1].UpdateGridLocation();

			AirList.AddItem(PossibleLocations[i]);
			AirReferenceList.AddItem(TowerBlockAir(AdjacentList[AdjacentList.Length-1]));
		}
//		AdjacentList.AddItem(class'AStarNode'.static.CreateNodeFromArchetype(
//			TowerGameBase(Owner.WorldInfo.Game).AirArchetype, PossibleLocations[i])); 
	}
}

//@TODO - Not duplicate function. Make Tower's static?
/** AI doesn't have Towers so we have to do this here. */
private final function Vector GridLocationToVector(out const IVector GridLocation)
{
	local Vector NewBlockLocation;

	//@FIXME: Block dimensions. Constant? At least have a constant, traceable part?
	NewBlockLocation.X = (GridLocation.X * 256)+GridOrigin.X;
	NewBlockLocation.Y = (GridLocation.Y * 256)+GridOrigin.Y;
	NewBlockLocation.Z = (GridLocation.Z * 256)+GridOrigin.Z;
	// Pivot point in middle, bump it up.
	NewBlockLocation.Z += 128;
	return NewBlockLocation;
}

/** Returns true if both blocks share just an edge. */
private final function bool IsDiagonalTo(TowerBlock A, TowerBlock B)
{
	// If corner checking we'd equate with 3.
	return ISizeSq(A.GridLocation - B.GridLocation) == 2;
}

private final function bool IsAdjacentTo(TowerBlock A, TowerBlock B)
{
	return ISizeSq(A.GridLocation - B.GridLocation) == 1;
}

/** @TODO - What is this used for? */
private final function UpdateParents(TowerBlock Block, TowerBlock Finish)
{
	local TowerBlock IteratorBlock;
	local TowerBlockAir IteratorAirBlock;
	local array<TowerBlock> AdjacentList;
	local int GoalCost;
	GoalCost = Block.GoalCost;
	`log("UPDATEPARENTD* **********************",,'AStar');
	ScriptTrace();
	foreach Block.CollidingActors(class'TowerBlock', IteratorBlock, 200,, true)
	{
		//check for each neighbor's air since it won't get picked up by CollidingActors.
		foreach IteratorBlock.BasedActors(class'TowerBlockAir', IteratorAirBlock)
		{
			if(IsDiagonalTo(IteratorAirBlock, Block))
			{
				AdjacentList.AddItem(IteratorAirBlock);
			}
		}
		AdjacentList.AddItem(IteratorBlock);
	}
	foreach AdjacentList(IteratorBlock)
	{
		IteratorBlock.AStarParent = Block;
		CalculateCosts(IteratorBlock, Finish, GoalCost+1);
	}
}

private final function CalculateCosts(TowerBlock Block, TowerBlock Finish, optional int GoalCost)
{
	if(Block == Finish)
	{
		Block.Fitness = 0;
		return;
	}
	Block.HeuristicCost = GetHeuristicCost(Block, Finish);
	if(Block.AStarParent != None)
	{
		Block.GoalCost = GoalCost;
	}
	Block.Fitness = Block.HeuristicCost + Block.GoalCost;
}

private final function int GetGoalCost(TowerBlock Block)
{
	if(Block.AStarParent != None)
	{
		return Block.BaseCost + GetGoalCost(Block.AStarParent);
	}
	return 0;
}

private final function int GetHeuristicCost(TowerBlock Block, TowerBlock Finish)
{
	return ISizeSq(Block.GridLocation - Finish.GridLocation);
}

/** The best block in a list is whichever has the lowest score. */
private final function TowerBlock GetBestBlock(out array<TowerBlock> OpenList, TowerBlock Finish)
{
	local TowerBlock BestBlock, IteratorBlock;
	foreach OpenList(IteratorBlock)
	{
//		`log("Checking for best:"@IteratorBlock@IteratorBlock.Fitness,,'AStar');
		if(BestBlock == None)
		{
			BestBlock = IteratorBlock;
		}
		else if(IteratorBlock.Fitness < BestBlock.FitNess)
		{
			BestBlock = IteratorBlock;
		}
		//@TODO - Should we really do this?
		if(IteratorBlock == Finish)
		{
			return IteratorBlock;
		}
	}
	return BestBlock;
}

/** Called when a path was found. Builds a linked list of objectives so the AI can navigate it. */
private final function ConstructPath(TowerBlock Finish)
{
	local TowerBlock Block;
	local Vector SpawnLocation;
	local array<TowerBlock> PathToRoot;
	local TowerAIObjective PreviousObjective, Objective;
	`log("* * Path complete, constructing!",,'AStar');

	for(Block = Finish; Block != None; Block = Block.AStarParent)
	{
		`log("Adding block to PathToRoot..."@Block,,'AStar');
		PathToRoot.AddItem(Block);
	}

	ReverseArray(PathToRoot);
	foreach PathToRoot(Block)
	{
		SpawnLocation = Block.Location;
		SpawnLocation.Z -= 70;
		Objective = Owner.Spawn(class'TowerAIObjective',,, SpawnLocation,,,true);
		InitializeObjective(Objective, Block, PreviousObjective);
	}
	`log("Path construction complete!",,'AStar');
	DebugLogPaths();
	PathReady(CurrentPath.ID, true);
	Hivemind.UnRegisterForAsyncTick(AsyncTick);
	CurrentPath.ID = -1;
	CurrentPath = NullPathRoot;
}

private final function PathReady(const int PathID, const bool bSuccess)
{
	local int PathIndex;
	PathIndex = QueuedPaths.Find('ID', PathID);
	if(PathIndex == -1)
	{
		`log("WHY");
	}
	Game.RegisterForPreAsyncTick(PreAsyncTick);
	QueuedPaths[PathIndex].bReady = true;
	QueuedPaths[PathIndex].bSuccess = bSuccess;
}

private final function InitializeObjective(TowerAIObjective Objective, TowerBlock Block, out TowerAIObjective PreviousObjective)
{
	local IVector Edge;
	Objective.SetTarget(Block);
	if(TowerBlockStructural(Block) != None || TowerBlockRoot(Block) != None)
	{
		Objective.SetType(OT_Destroy);
	}
	else if(PreviousObjective != None)
	{
		if(IsDiagonalTo(Block, PreviousObjective.Target))
		{
			if(Block.GridLocation.Z == PreviousObjective.Target.GridLocation.Z+1)
			{
				// This block is 1 higher.
				Objective.SetType(OT_ClimbUp);
				Edge = Objective.Target.GridLocation - PreviousObjective.Target.GridLocation;
				Edge.Z = 0;
				`assert(ISize(Edge) > 0);
				PreviousObjective.MoveToEdgeOfTarget(Edge);
			}
			else if(Block.GridLocation.Z == PreviousObjective.Target.GridLocation.Z-1)
			{
				// This block is 1 lower.
				Objective.SetType(OT_ClimbDown);
			}
		}
	}
	if(Objective.Type == OT_NULL)
	{
		Objective.SetType(OT_GoTo);
	}
	
	if(PreviousObjective != None)
	{
		PreviousObjective.SetNextObjective(Objective);
	}
	else
	{
		Paths.AddItem(Objective);
	}
	PreviousObjective = Objective;
	`assert(Objective.Type != OT_NULL);
}

private function ReverseArray(out array<TowerBlock> Blocks)
{
	local int i;
	local TowerBlock TempBlock;
	for(i = 0; i < Blocks.Length/2; i++)
	{
		TempBlock = Blocks[Blocks.Length-i-1];
		Blocks[Blocks.Length-i-1] = Blocks[i];
		Blocks[i] = TempBlock;
	}
}

final function Clear()
{
	local TowerAIObjective Objective;
	foreach Paths(Objective)
	{
		Objective.Destroy();
	}
	Paths.Remove(0, Paths.length);
	QueuedPaths.Remove(0, QueuedPaths.length);
}

final simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	if(bStepSearch && bDeferred && bDrawStepInfo)
	{
		DebugDrawStepInfo(Canvas);
	}

	//@TODO - Modify this to work with just the root of a path as input.
	/*
	if(Paths.Length > 0)
	{
		DebugDrawPath(DebugStart, DebugFinish, Canvas);
	}
	*/
}

private final function DebugCreateStepMarkers(out PriorityQueue OpenList, out array<TowerBlock> ClosedList)
{
	local TowerAIObjective Marker;
	local TowerBlock Block;
	local array<TowerBlock> BlockArray;
	StepMarkers.Remove(0, StepMarkers.Length);
	OpenList.AsArray(BlockArray);
	foreach BlockArray(Block)
	{
		if(Block == StepBestBlock)
		{
			continue;
		}
		Marker = Owner.Spawn(class'TowerAIObjective',,,Block.Location);
		Marker.Mesh.SetMaterial(0, Material'EditorMaterials.WidgetMaterial_Y');
		StepMarkers.AddItem(Marker);
	}
	foreach ClosedList(Block)
	{
		if(Block == StepBestBlock)
		{
			continue;
		}
		Marker = Owner.Spawn(class'TowerAIObjective',,,Block.Location);
		Marker.Mesh.SetMaterial(0, Material'NodeBuddies.Materials.NodeBuddy_Brown1');
		StepMarkers.AddItem(Marker);
	}
	if(StepBestBlock != None)
	{
		Marker = Owner.Spawn(class'TowerAIObjective',,,StepBestBlock.Location);
		Marker.Mesh.SetMaterial(0, Material'EditorMaterials.WidgetMaterial_Z');
		StepMarkers.AddItem(Marker);
	}
}

private final function DebugLogPaths()
{
	local int i;
	local TowerAIObjective RootObjective, ChildObjective;
	`log("=================================================",,'AStar');
	foreach Paths(RootObjective, i)
	{
		`log("-------------------------------------------------",,'AStar');
		`log("Path"@i$":"@RootObjective@"("$RootObjective.Target$")",,'AStar');
		for(ChildObjective = RootObjective.NextObjective; ChildObjective != None; ChildObjective = ChildObjective.NextObjective)
		{
			`log(ChildObjective@"("$ChildObjective.Target$")",,'AStar');
		}
	}
}

private final function DebugDrawPath(TowerBlock Start, TowerBlock Finish, Canvas Canvas)
{
	local Vector BeginPoint, EndPoint;
//	local int i;
	BeginPoint = Canvas.Project(Start.Location+Vect(16,16,16));
	Canvas.SetPos(BeginPoint.X, BeginPoint.Y);
	Canvas.bCenter = true;
	Canvas.DrawText("Start");
	EndPoint = Canvas.Project(Finish.Location+Vect(16,16,16));
	Canvas.SetPos(EndPoint.X, EndPoint.Y);
	Canvas.DrawText("Finish");
	Canvas.bCenter = false;
//	DrawDebugString(Start.Location, "Start");
//	DrawDebugStar(Start.Location, 48, 0, 255, 0, true);
//	DrawDebugString(Finish.Location, "Finish", Finish);
//	DrawDebugStar(Finish.Location, 48, 0, 255, 0, true);
	/*
	for(i = Paths.Length-2; i >= 0; i--)
	{
		BeginPoint = Canvas.Project(PathToRoot[i].Location+Vect(16,16,16));
		EndPoint = Canvas.Project(PathToRoot[i+1].Location+Vect(16,16,16));
		Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, EndPoint.X, EndPoint.Y, MakeColor(0, 255, 0));
//		DrawDebugLine(PathToRoot[i].Location+Vect(16,16,16), PathToRoot[i+1].Location+Vect(16,16,16), 0, 0, 255, true);
	}
	*/
}

private final function DebugDrawStepInfo(Canvas Canvas)
{
	local TowerBlock Block;
	local int i;
	Canvas.SetDrawColor(255,255,255);
	Canvas.SetPos(0,0);
	Canvas.SetPos(0,50);
	Canvas.DrawText("OpenList:");
	i = 62;
	/*
	foreach DeferredOpenList(Block)
	{
		Canvas.SetPos(0, i);
		Canvas.DrawText(Block.Name);
		i += 12;
	}
	*/
	Canvas.SetPos(200, 50);
	Canvas.DrawText("ClosedList:");
	i = 62;
	foreach DeferredClosedList(Block)
	{
		Canvas.SetPos(200, i);
		Canvas.DrawText(Block.Name);
		i += 12;
	}
	Canvas.SetPos(400, 50);
	Canvas.DrawText("BestBlock:"@StepBestBlock.Name);
	Canvas.SetPos(350, 75);
	Canvas.DrawText("BestBlock Hierarchy:");
	i = 87;
	for(Block = StepBestBlock; Block != None; Block = Block.ASTarParent)
	{
		Canvas.SetPos(350, i);
		Canvas.DrawText(Block@"("$Block.GridLocation.X$","@Block.GridLocation.Y$","@Block.GridLocation.Z$")");
		if(Block.AStarParent != None)
		{
			if(!(IsDiagonalTo(Block, Block.AStarParent) || IsAdjacentTo(Block, Block.AStarParent)))
			{
				Canvas.SetPos(450, i);
				Canvas.DrawColor = MakeColor(255,0,0);

				Canvas.DrawText("ERROR: Non-adjacent/diagonal blocks!");

				Canvas.DrawColor = Canvas.default.DrawColor;
				Canvas.SetPos(350, i);
			}
		}
		i += 12;
	}

}

private final function DebugDrawBlockFitness(Canvas Canvas)
{
	/*
	local TowerBlock Block;
	foreach OpenList(Block)
	{

	}
	*/
}

DefaultProperties
{
	NextPathID=0
	NullPathRoot=(ID=-1,bReady=true,bSuccess=false)

	// Top +
	PossibleAirs(0)=(X=0,Y=0,Z=1)
	PossibleAirs(1)=(X=1,Y=0,Z=1)
	PossibleAirs(2)=(X=-1,Y=0,Z=1)
	PossibleAirs(3)=(X=0,Y=1,Z=1)
	PossibleAirs(4)=(X=0,Y=-1,Z=1)
	// Middle + minus middle
	PossibleAirs(5)=(X=1,Y=0,Z=0)
	PossibleAirs(6)=(X=-1,Y=0,Z=0)
	PossibleAirs(7)=(X=0,Y=1,Z=0)
	PossibleAirs(8)=(X=0,Y=-1,Z=0)
	// Bottom +
	PossibleAirs(9)=(X=0,Y=0,Z=-1)
	PossibleAirs(10)=(X=1,Y=0,Z=-1)
	PossibleAirs(11)=(X=-1,Y=0,Z=-1)
	PossibleAirs(12)=(X=0,Y=1,Z=-1)
	PossibleAirs(13)=(X=0,Y=-1,Z=-1)
}