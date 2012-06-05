/** A component for performing A* searches between two arbitrary grid locations. */
class TowerAStarComponent extends ActorComponent
	config(Tower);

`define CHECK_WORLD_BOUNDS
`define CHECK_MAX_ITERATIONS

// A 3x3x3 cube minus the center. Edges and corners.
const POSSIBLE_AIRS_ALL_NEIGHBORS = 26;
// A + sign layered three times vertically minus the center. Only edges.
const POSSIBLE_AIRS_NO_CORNERS = 14;

const POSSIBLE_AIRS_ONLY_ADJACENT = 6;
const POSSIBLE_AIRS_ONLY_DIAGONAL = 4;
const POSSIBLE_AIRS_ONLY_SIDES = 6;
const POSSIBLE_AIRS_ONLY_EDGES = 12;
const POSSIBLE_AIRS_ONLY_CORNERS = 8;

const POSSIBLE_AIRS_ADJACENT_AND_DIAGONAL = 10;
const INVALID_PATH_ID = -1;
const NONDEFERRED_PATH_ID = -2;

`define POSSIBLE_AIRS_COUNT POSSIBLE_AIRS_ONLY_SIDES

// Since there's no bitflag support...
/**================================= Path Rule Flags ================================*/
// At least one flag for each category must be set for a valid search.
// Use the `HasFlag() macro to check instead of doing the bitwise stuff yourself.

/**== Rules for what blocks to check. ==**/
/***/
const PR_Null						= 0x0;
/** Includes air blocks at Z=0. */
const PR_Ground						= 0x1; // Check done in AAA.
/** Not implemented. */
const PR_ClimbableAir				= 0x2;
/** Includes air blocks at Z>0. */
//@TODO - Make me less ridiculously misleading.
const PR_Air						= 0x4; // PR_AboveGround? // Check done in AAA.
/** Includes all blocks. */
const PR_Blocks						= 0x8; // Check done in AL.
/** Includes all modules. */
const PR_Modules					= 0x10; // Check done in AL.

/**== Composite values. ==**/
/** Includes all air blocks. */
const PR_GroundAndAir				= 0x5; // PR_Air | PR_Ground
/** Includes all blocks and all modules. */
const PR_BlocksAndModules			= 0x18; // PR_Blocks | PR_Modules
/** Same rules as your bog-standard 2D A* demo. */
const PR_XYSearch					= 0x19; // PR_Ground | PR_BlocksAndModules

/** Optional, there's no "normal" goal. Immediately returns a valid path 
on the first node that's connected to the root. */
const PR_Goal_ConnectedToRoot		= 0x20;
/**==================================================================================*/

enum SearchResult
{
	SR_NULL,
	/** Everything went fine and there's a valid path. */
	SR_Success,
	/** Given the rules, there's no valid path between Start and Finish.
	All values should be considered garbage. */
	SR_NoPath,
	/** Given the rules, without doing any pathfinding, it's impossible for there to be a valid path.
	All values should be considered garbage. */
	SR_ImpossiblePath,
};

//@TODO - Privatize.
var privatewrite array<TowerAIObjective> Paths;
var const private IVector PossibleAirs[`POSSIBLE_AIRS_COUNT];

/** Enables the ability to step through a search. Overrides IterationsPerTick and bDeferSearching! */
var privatewrite bool bStepSearch;
/** Draws debug information on the HUD about our current step. */
var private bool bDrawStepInfo;
var private bool bLogIterationTime;
var private bool bInitialized;
/** If we exceed this many iterations with no path, return SR_NoPath. */
`if(`isdefined(CHECK_MAX_ITERATIONS))
var private const int MaxIterations;
`endif
var private array<delegate<OnPathGenerated> > PathGeneratedDelegates;

var private TowerGame Game;
var private AirManager AirManager;
var private TowerFactionAIHivemind Hivemind;
`if(`isdefined(CHECK_WORLD_BOUNDS))
var private IBox WorldBounds;
`endif

/** Next PathID to use when we need one for GeneratePath. */
var private int NextPathID;
/** Current Path we're working on. Should it be first-come first-serve or what? */
var private PathInfo CurrentPath;
/** Holds all the paths that need generating, including the CurrentPathID one. */
var private array<PathInfo> QueuedPaths;
var private array<PathInfo> ToNotifyPaths;

//=============================================================================
// Deferred search variables.
/** After every IterationsPerTick amount of iterations, save the state of the search and continue next tick. */
var private config bool bDeferSearching;
/** How many iterations to do before deferring to the next tick. */
var private config int IterationsPerTick;
/** To step or not. Used when step searching. */
var private bool bStep;

/** Cached GridOrigin so we don't have to jump through several variables for every air block. */
var private Vector GridOrigin;

delegate OnPathGenerated(const PathInfo Path);

/** Called from TowerGame when requested.
Used to call OnPathGenerated during PreAsync so factions can actually spawn/queue stuff in response. */
final event PreAsyncTick(float DeltaTime)
{
	HandleCompletedPaths();
	Game.UnRegisterForPreAsyncTick(PreAsyncTick);
}

private final function HandleCompletedPaths()
{
	local int i;
	local delegate<OnPathGenerated> PathGeneratedDelegate;

	for(i = 0; i < ToNotifyPaths.Length; i++)
	{
		foreach PathGeneratedDelegates(PathGeneratedDelegate)
		{
			PathGeneratedDelegate(ToNotifyPaths[i]);
		}
		//@TODO - Add to some master list?
	}

	ToNotifyPaths.Remove(0, ToNotifyPaths.Length);
}

/** Called from TowerFactionAIHivemind when requested.
Used to call GeneratePath for our CurrentPathID, for maximum efficiency. */
final event AsyncTick(float DeltaTime)
{
	GeneratePath(QueuedPaths[0]);
}

//@DEPRECATED ? How should we do this?
final event Initialize(optional delegate<OnPathGenerated> PathGeneratedDelegate, 
	optional bool bNewDeferSearching=default.bDeferSearching,
	optional int NewIterationsPerTick=default.IterationsPerTick, optional bool bNewStepSearch=false,
	optional bool bNewDrawStepInfo=false)
{
	GridOrigin = TowerGameReplicationInfo(Owner.WorldInfo.GRI).GridOrigin;
	Game = TowerGame(Owner.WorldInfo.Game);
	AirManager = Game.AirManager;
	Hivemind = Game.Hivemind;
	AddOnPathGeneratedDelegate(PathGeneratedDelegate);
	bDeferSearching = bNewDeferSearching;
	IterationsPerTick = NewIterationsPerTick;
	bStepSearch = bNewStepSearch;
	bDrawStepInfo = bNewDrawStepInfo;
}

final function Step()
{
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

public final function int StartGeneratePath(const IVector Start, const IVector Finish, int Rules)
{
	local TowerBlock BStart, BFinish;
	local int PathId;
	if(!bInitialized)
	{
		//@TODO - Why is initializing a thing.
		`log(self@"wasn't Initialize()'d before use!");
		return INVALID_PATH_ID;
	}
	BStart = GetBlockAt(Start);
	BFinish = GetBlockAt(Finish);
	`if(`isdefined(CHECK_WORLD_BOUNDS))
	Game.ExpandBoundsTo(BStart.GridLocation);
	Game.ExpandBoundsTo(BFinish.GridLocation);
	`endif
	QueuedPaths.AddItem(class'PathInfo'.static.CreateNewPathInfo(GetNextPathID(), BStart, BFinish, Rules, self));
	if(!IsPathPossibleWithRules(BStart, BFinish, Rules))
	{
		ConstructPath(QueuedPaths[QueuedPaths.Length-1], BFinish, SR_ImpossiblePath);
		return INVALID_PATH_ID;
	}
	if(!bDeferSearching)
	{
		PathID = NextPathID;
		GeneratePath(QueuedPaths[QueuedPaths.Length-1]);
		//@TODO - Why bother returning a PathID if not doing a deferred search?
		// It'll be useless by the time the caller gets it.
		return PathID;
	}
	else
	{
		Hivemind.RegisterForAsyncTick(AsyncTick);
		return QueuedPaths[QueuedPaths.Length-1].PathID;
	}
}

private final function bool IsPathPossibleWithRules(TowerBlock Start, TowerBlock Finish, const out int Rules)
{
	local string Error;
	if(!`HasFlag(Rules, PR_Blocks) && (TowerBlockStructural(Finish) != None || TowerBlockRoot(Finish) != None))
	{
		Error @= "IMPOSSIBLE: Goal is occupied by a block ("$Finish$") but the PR_Blocks rule is not set!";
	}
	if(!`HasFlag(Rules, PR_Modules) && TowerBlockModule(Finish) != None)
	{
		Error @= "IMPOSSIBLE: Goal is occupied by a module ("$Finish$") but the PR_Modules rule is not set!";
	}
	/** PR_Air/PR_Ground sanity checks only done when there's no PR_Blocks or PR_Modules. 
		Otherwise it's too hard to tell if there's no Air AND no blocks/modules for a path without, well,
		doing an A* search. */
	if(!`HasFlag(Rules, PR_Modules) && !`HasFlag(Rules, PR_Blocks))
	{
		/* Technically the Start block is never checked, so it's fine if its Z=1. 
			It just means the block under it is the only choice. 
			We could do a check on that under block, but it'll fail the first step anyways if its bad. */
		if(!`HasFlag(Rules, PR_Air) && (Start.GridLocation.Z > 1 || Finish.GridLocation.Z > 0))
		{
			Error @= "IMPOSSIBLE: Either Start ("$`IVectStr(Start.GridLocation)$") or Finish ("
				$`IVectStr(Finish.GridLocation)$") is above ground but the PR_Air rule is not set!";
		}
		/** Don't check Start here since if it was at Z=0, the block above it is the only choice.
			Again we could do a check on that block but see above. */
		if(!`HasFlag(Rules, PR_Ground) && Finish.GridLocation.Z == 0)
		{
			Error @= "IMPOSSIBLE: Finish ("$`IVectStr(Finish.GridLocation)
				$") is on the ground but the PR_Ground rule is not set!";
		}
	}

	if(Error != "")
	{
		`log(Error,,'AStarFailure');
		return false;
	}
	else
	{
		return true;
	}
}

private final function int GetNextPathID()
{
	NextPathID++;
	return NextPathID-1;
}

private final function GeneratePath(PathInfo Path)
{
	local int IterationsThisTick;
	local TowerBlock BestNode;
	local array<TowerBlock> AdjacentList;
	local bool bDoStep;

	if(bStepSearch && !bStep && Path.Iteration != 0)
	{
		return;
	}
	else
	{
		bStep = false;
		bDoStep = true;
	}
	if(Path.Iteration == 0)
	{
		Path.OpenList.Add(Path.Start);
		`log("================== STARTING A* ==================",,'AStar');
		`log("Start:"@Path.Start$`IVectStr(Path.Start.GridLocation)@" "
			@"Finish:"@Path.Finish$`IVectStr(Path.Finish.GridLocation),,'AStar');
	}
	`if(`isdefined(CHECK_WORLD_BOUNDS))
	WorldBounds = Game.WorldBounds;
	`endif
	while(Path.OpenList.Length() > 0)
	{
//		`log("Iteration"@IterationsThisTick);
		`if(`isdefined(CHECK_MAX_ITERATIONS))
		if(Path.Iteration > MaxIterations)
		{
			`log("Exceeded"@MaxIterations@"iterations, aborting search!",,'AStar');
			ConstructPath(Path, None, SR_NoPath);
			break;
		}
		`endif
		if(bStepSearch)
		{
			if(bDoStep)
			{
				bDoStep = false;
			}
			else
			{
//				DebugCreateStepMarkers(Path.OpenList, Path.ClosedList);
				return;
			}
			// If we're stepping, draw debug information.
		}
		if(bDeferSearching && IterationsThisTick >= IterationsPerTick)
		{
			return;
		}
		BestNode = Path.OpenList.Remove();
		Path.ClosedList.AddItem(BestNode);
		if(BestNode.GridLocation == Path.Finish.GridLocation 
			|| (`HasFlag(Path.PathRules, PR_Goal_ConnectedToRoot) && class'Tower'.static.TraceNodeToRoot(BestNode)))
		{
			`log(BestNode == Path.Finish);
			`log(BestNode.AStarParent@PAth.Finish.AStarParent);
			ConstructPath(Path, BestNode, SR_Success);
			break;
		}
		AddAdjacentBlocks(AdjacentList, BestNode, Path);
		AdjacentLogic(AdjacentList, BestNode, Path);
		IterationsThisTick++;
		Path.Iteration++;
	}
	if(Path.Result == SR_NULL)
	{
		ConstructPath(Path, Path.Start, SR_NoPath);
	}
	`log("================== FINISHED A* ==================",,'AStar');
	Path.OpenList.Dispose();
}

private final function TowerBlock GetBlockAt(out const IVector GridLocation)
{
	local TowerBlock Block;
	foreach Owner.CollidingActors(class'TowerBlock', Block, 32,
		class'Tower'.static.GridLocationToVector(GridLocation), true)
	{
		return Block;
	}
	return AirManager.GetAir(GridLocation);
}

private final function AdjacentLogic(out array<TowerBlock> AdjacentList, const TowerBlock SourceBlock,
	const PathInfo Path)
{
	local TowerBlock IteratorBlock;

	foreach AdjacentList(IteratorBlock)
	{
		`assert(IteratorBlock != SourceBlock);
		//@TODO - Really.
		if(TowerBlockAir(IteratorBlock) != None
				|| (`HasFlag(Path.PathRules, PR_Blocks) && (TowerBlockStructural(IteratorBlock) != None
																|| TowerBlockRoot(IteratorBlock) != None))
				|| (`HasFlag(Path.PathRules, PR_Modules) && TowerBlockModule(IteratorBlock) != None))
		{

		}
		else
		{
			continue;
		}
		if(Path.ClosedList.Find(IteratorBlock) != INDEX_NONE)
		{
			// Already in ClosedList. Ignore it.
			continue;
		}
		else if(!Path.OpenList.Contains(IteratorBlock))
		{
			// Not in OpenList. Add it and compute score.
			IteratorBlock.AStarParent = SourceBlock; // Do we do this?
			CalculateCosts(IteratorBlock, Path.Finish, GetGoalCost(IteratorBlock));
			Path.OpenList.Add(IteratorBlock);
		}
		else
		{
			// Already in OpenList. Check if F is lower when we use the current path to get there.
			// If it is, update its score and parent.
			if(IteratorBlock.GoalCost > SourceBlock.GoalCost)
			{
				// Better path?
				IteratorBlock.AStarParent = SourceBlock;
				CalculateCosts(IteratorBlock, Path.Finish, GetGoalCost(IteratorBlock));
			}
		}
	}
}

/** Populates OutAdjacentList with all blocks adjacent to SourceBlock.
Will create air blocks if needed. Will handle clearing the list if not already empty. */
private final function AddAdjacentBlocks(out array<TowerBlock> OutAdjacentList, const out TowerBlock SourceBlock,
	const PathInfo Path)
{
	local TowerBlock IteratorBlock;

	if(OutAdjacentList.Length != 0)
	{
		OutAdjacentList.Remove(0, OutAdjacentList.Length);
	}
	foreach SourceBlock.CollidingActors(class'TowerBlock', IteratorBlock, 132, 
		class'Tower'.static.GridLocationToVector(SourceBlock.GridLocation), true)
	{
		if(!IteratorBlock.bDebugIgnoreForAStar && IteratorBlock != SourceBlock)
		{
			OutAdjacentList.AddItem(IteratorBlock);
		}
	}
	AddAdjacentAirBlocks(SourceBlock.GridLocation, OutAdjacentList, Path);
}

/** Populates AdjacentList with air blocks adjacent to Center. */
private final function AddAdjacentAirBlocks(const out IVector Center, out array<TowerBlock> AdjacentList,
	const PathInfo Path)
{
	local array<IVector> PossibleLocations;
	local int i;
	
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
		if(PossibleLocations[i].Z < 0)
		{
			continue;
		}
		if((`HasFlag(Path.PathRules, PR_Ground) && PossibleLocations[i].Z == 0)
				|| (`HasFlag(Path.PathRules, PR_Air) && PossibleLocations[i].Z > 0))
		{

		}
		else
		{
//			`log("Aborting PossibleLocations"@IVectStr(PossibleLocations[i]);
			continue;
		}
		`if(`isdefined(CHECK_WORLD_BOUNDS))
		if(PossibleLocations[i].X < WorldBounds.Min.X || PossibleLocations[i].X > WorldBounds.Max.X
			|| PossibleLocations[i].Y < WorldBounds.Min.Y || PossibleLocations[i].Y > WorldBounds.Max.Y
			|| PossibleLocations[i].Z < WorldBounds.Min.Z || PossibleLocations[i].Z > WorldBounds.Max.Z)
		{
			continue;
		}
		`endif
		AdjacentList.AddItem(AirManager.GetAir(PossibleLocations[i]));
	}
}

`define IsDiagonalTo(A,B) (ISizeSq(`A - `B) == 2)
/** Returns true if both blocks share just an edge. */
private final function bool IsDiagonalTo(const out IVector A, const out IVector B)
{
	// If corner checking we'd equate with 3.
	return ISizeSq(A - B) == 2;
}

`define IsAdjacentTo(A,B) (ISizeSq(`A - `B) == 1)
private final function bool IsAdjacentTo(const out IVector A, const out IVector B)
{
	return ISizeSq(A - B) == 1;
}

/** @TODO - What is this used for? */
private final function UpdateParents(TowerBlock Block, TowerBlock Finish, const PathInfo Path)
{
	local TowerBlock IteratorBlock;
	local array<TowerBlock> AdjacentList;
	local int GoalCost;
	GoalCost = Block.GoalCost;
	`log("UPDATEPARENTD* **********************",,'AStar');
	AddAdjacentBlocks(AdjacentList, Block, Path);
	foreach AdjacentList(IteratorBlock)
	{
		IteratorBlock.AStarParent = Block;
		CalculateCosts(IteratorBlock, Finish, GoalCost+1);
	}
}

private final function CalculateCosts(TowerBlock Block, TowerBlock Finish, optional int GoalCost)
{
	// Fix for A* dancing around the goal. If it's there just go for it!
	if(Block.GridLocation == Finish.GridLocation)
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

//@NOTE - Can't just do Manhattan!
private final function int GetGoalCost(TowerBlock Block)
{
	local int GoalCost;
	for(Block = Block; Block != None; Block = Block.AStarParent)
	{
//		`log(Block@Block.AStarParent);
		GoalCost += Block.BaseCost;
	}
	/*if(Block.AStarParent != None)
	{
		return Block.BaseCost + GetGoalCost(Block.AStarParent);
	}*/
	return GoalCost;
}

private final function int GetHeuristicCost(TowerBlock Block, TowerBlock Finish)
{
	// Only use ISizeSq, don't use ISize or paths will be less optimal!
	return ISizeSq(Block.GridLocation - Finish.GridLocation);
}

/** Called when a path was found. Builds a linked list of objectives so the AI can navigate it. */
private final function ConstructPath(const PathInfo Path, TowerBlock Finish, SearchResult Result)
{
	local TowerBlock Block;
	local Vector SpawnLocation;
	local array<TowerBlock> PathToRoot;
	local TowerAIObjective PreviousObjective, Objective;
	`log("* * Path complete, constructing!",,'AStar');
	Path.Result = Result;

	for(Block = Finish; Block != None; Block = Block.AStarParent)
	{
		`log("Adding block to PathToRoot..."@Block@"P:"@Block.AStarParent,,'AStar');
		PathToRoot.AddItem(Block);
	}

	ReverseArray(PathToRoot);
	foreach PathToRoot(Block)
	{
		SpawnLocation = Block.Location;
		SpawnLocation.Z -= 70;
		Objective = Owner.WorldInfo.Spawn(class'TowerAIObjective',,, SpawnLocation,,,true);
		if(Path.ObjectiveRoot == None)
		{
			Path.ObjectiveRoot = Objective;
		}
		InitializeObjective(Objective, Block, PreviousObjective);
	}
	`log("Path construction complete!",,'AStar');
	DebugLogPaths();
	PathReady(Path);
	Hivemind.UnRegisterForAsyncTick(AsyncTick);
}

private final function PathReady(const PathInfo Path)
{
	local int Index;
	Index = QueuedPaths.Find(Path);
	`assert(Index != INDEX_NONE);
	QueuedPaths.Remove(Index, 1);
	ToNotifyPaths.AddItem(Path);
	ZeroAllAStarParents(Path);
	if(bDeferSearching)
	{
		Game.RegisterForPreAsyncTick(PreAsyncTick);
	}
	else
	{
		HandleCompletedPaths();
	}
}

private final function ZeroAllAStarParents(const PathInfo Path)
{
	local TowerBlock Block;
	local array<TowerBlock> OpenList;
	foreach Path.ClosedList(Block)
	{
		Block.AStarParent = None;
	}
	Path.OpenList.AsArray(OpenList);
	foreach OpenList(Block)
	{
		Block.AStarParent = None;
	}
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
		if(IsDiagonalTo(Block.GridLocation, PreviousObjective.Target.GridLocation))
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
	if(bStepSearch && bDrawStepInfo)
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

private final function DebugDrawStepInfo(Canvas Canvas)
{
	local PathInfo Path;
	local TowerBlock IteratorBlock;
	local array<TowerBlock> OpenList;
	if(QueuedPaths.Length == 0)
	{
		return;
	}
	Path = QueuedPaths[0];
	Path.OpenList.AsArray(OpenList);

	foreach OpenList(IteratorBlock)
	{
		Owner.DrawDebugBox(IteratorBlock.Location, Vect(64,64,64), 255, 255, 0, false);
		Owner.DrawDebugString(Vect(0,0,32), IteratorBlock.Fitness, IteratorBlock, , 0.1);
	}
	foreach Path.ClosedList(IteratorBlock)
	{
		Owner.DrawDebugBox(IteratorBlock.Location, Vect(64,64,64), 0, 255, 255, false);
		Owner.DrawDebugString(Vect(0,0,32), IteratorBlock.Fitness, IteratorBlock, , 0.1);
	}
	Owner.DrawDebugBox(OpenList[0].Location, Vect(80,80,80), 255, 255, 200, false);
}

DefaultProperties
{
	NextPathID=0
	`if(`isdefined(CHECK_MAX_ITERATIONS))
	MaxIterations=400
	`endif
	/*
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
	*/

	
	// ShareSides
	PossibleAirs(0)=(X=1,Y=0,Z=0)
	PossibleAirs(1)=(X=-1,Y=0,Z=0)
	PossibleAirs(2)=(X=0,Y=1,Z=0)
	PossibleAirs(3)=(X=0,Y=-1,Z=0)
	PossibleAirs(4)=(X=0,Y=0,Z=1)
	PossibleAirs(5)=(X=0,Y=0,Z=-1)
/**
	// ShareEdges
	// Top
	PossibleAirs(1)=(X=1,Y=0,Z=1)
	PossibleAirs(2)=(X=-1,Y=0,Z=1)
	PossibleAirs(3)=(X=0,Y=1,Z=1)
	PossibleAirs(4)=(X=0,Y=-1,Z=1)
	// Middle
	PossibleAirs(0)=(X=1,Y=1,Z=0)
	PossibleAirs(0)=(X=1,Y=-1,Z=0)
	PossibleAirs(0)=(X=-1,Y=1,Z=0)
	PossibleAirs(0)=(X=-1,Y=-1,Z=0)
	// Bottom
	PossibleAirs(10)=(X=1,Y=0,Z=-1)
	PossibleAirs(11)=(X=-1,Y=0,Z=-1)
	PossibleAirs(12)=(X=0,Y=1,Z=-1)
	PossibleAirs(13)=(X=0,Y=-1,Z=-1)

	// ShareCorners
	// Same as ShareEdges' middle, but moved up or down.
	// Top
	PossibleAirs(0)=(X=1,Y=1,Z=1)
	PossibleAirs(0)=(X=1,Y=-1,Z=1)
	PossibleAirs(0)=(X=-1,Y=1,Z=1)
	PossibleAirs(0)=(X=-1,Y=-1,Z=1)
	// Bottom
	PossibleAirs(0)=(X=1,Y=1,Z=-1)
	PossibleAirs(0)=(X=1,Y=-1,Z=-1)
	PossibleAirs(0)=(X=-1,Y=1,Z=-1)
	PossibleAirs(0)=(X=-1,Y=-1,Z=-1)
	**/
}