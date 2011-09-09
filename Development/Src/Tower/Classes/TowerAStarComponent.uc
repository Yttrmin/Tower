/** A component for performing A* searches between two blocks. */
class TowerAStarComponent extends ActorComponent;

var array<TowerAIObjective> Paths;
var TowerBlock DebugStart, DebugFinish;

/** After every IterationsPerTick amount of iterations, save the state of the search and continue next tick. */
var bool bDeferSearching;
/** Enables the ability to step through a search. Overrides IterationsPerTick and bDeferSearching! */
var bool bStepSearch;
/** Draws debug information on the HUD about our current step. */
var bool bDrawStepInfo;
/** How many iterations to do before deferring to the next tick. */
var int IterationsPerTick;
//=============================================================================
// Deferred search variables.
/** Are we currently deferring to next tick? */
var privatewrite bool bDeferred;
/** Is the search done but we're deferring anyways? Used so the final step is of the finished path. */
var private bool bDeferredDone;
/** To step or not. Used when step searching. */
var private bool bStep;
/** A copy of the OpenList and ClosedList before deferring. */
var private array<TowerBlock> DeferredOpenList, DeferredClosedList;
/** Reference to the best block before deferring. */
var private TowerBlock StepBestBlock;
/** Used to represent the different nodes when stepping. */
var private array<TowerAIObjective> StepMarkers;
/** The ACTUAL iteration we're on, regardless of whether we defer or not. */
var private int Iteration;

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

final function bool GeneratePath(TowerBlock Start, TowerBlock Finish)
{
	/** OpenList = Blocks that haven't been explored yet. ClosedList = Blocks that have been explored.
	Explored = Looked at every node connected to this one, calculate dtheir F, G, and H, and placed them in OpenList. */
	local array<TowerBlock> OpenList, ClosedList;
	/** References whichever Block in the OpenList that has the lowest Fitness. */
	local TowerBlock BestBlock;
	local int i;
	// To avoid warning with using variable before assigned.
	BestBlock = None;
	//@TODO - `if `isdefined debug
	if(bStepSearch && !bStep)
	{
		// If we're step searching but haven't been told to step, get out of here!
		return false;
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
		// DebugStart/Finish are used for keeping track of the Start/Finish so we can draw the path later.
		DebugStart = Start;
		DebugFinish = Finish;
		// #2
		CalculateCosts(Start, Finish, GetGoalCost(Start));
		// Add our Starting block to the OpenList and start pathfinding!
		// #3
		OpenList.AddItem(Start);
	}
	while(OpenList.Length > 0)
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
			return false;
		}
		// bDeferredDone means the search IS done, so don't increment any iterator values.
		if(!bDeferredDone)
		{
			i++;
			Iteration++;
		}
		BestBlock = GetBestBlock(OpenList, Finish);
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
				return false;
			}
			bDeferredDone = false;
			ConstructPath(Finish);
			break;
		}
		else if(BestBlock == None)
		{
			// No path?! How?! What?
		}
		AddAdjacentBlocks(OpenList, ClosedList, BestBlock, Finish);
		OpenList.RemoveItem(BestBlock);
		ClosedList.AddItem(BestBlock);
	}
	`log("================== FINISHED A* ==================",,'AStar');
	return true;
}

final function AddAdjacentBlocks(out array<TowerBlock> OpenList, out array<TowerBlock> ClosedList, 
	TowerBlock SourceBlock, TowerBlock Finish)
{
	local array<TowerBlock> AdjacentList;
	local TowerBlock IteratorBlock;
	local TowerBlockAir IteratorAirBlock;
	// Add everything to a single array so we can iterate through it easily.
	foreach SourceBlock.CollidingActors(class'TowerBlock', IteratorBlock, 200,, true)
	{
		//check for each neighbor's air since it won't get picked up by CollidingActors.
		foreach IteratorBlock.BasedActors(class'TowerBlockAir', IteratorAirBlock)
		{
			if(IsDiagonalTo(IteratorAirBlock, SourceBlock) || IsAdjacentTo(IteratorAirBlock, SourceBlock))
			{
				AdjacentList.AddItem(IteratorAirBlock);
			}
		}
		AdjacentList.AddItem(IteratorBlock);
	}
	foreach AdjacentList(IteratorBlock)
	{
		if(OpenList.Find(IteratorBlock) != -1)
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
			OpenList.AddItem(IteratorBlock);
		}
	}
}

/** Returns true if both blocks share just an edge. */
final function bool IsDiagonalTo(TowerBlock A, TowerBlock B)
{
	// If corner checking we'd equate with 3.
	return ISizeSq(A.GridLocation - B.GridLocation) == 2;
}

final function bool IsAdjacentTo(TowerBlock A, TowerBlock B)
{
	return ISizeSq(A.GridLocation - B.GridLocation) == 1;
}

/** @TODO - What is this used for? */
final function UpdateParents(TowerBlock Block, TowerBlock Finish)
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

final function CalculateCosts(TowerBlock Block, TowerBlock Finish, optional int GoalCost)
{
	Block.HeuristicCost = GetHeuristicCost(Block, Finish);
	if(Block.AStarParent != None)
	{
		Block.GoalCost = GoalCost;
	}
	Block.Fitness = Block.HeuristicCost + Block.GoalCost;
}

final function int GetGoalCost(TowerBlock Block)
{
	if(Block.AStarParent != None)
	{
		return Block.BaseCost + GetGoalCost(Block.AStarParent);
	}
	return 0;
}

final function int GetHeuristicCost(TowerBlock Block, TowerBlock Finish)
{
	local IVector Comparison;
	Comparison.X = Abs(Abs(Block.GridLocation.X) - Abs(Finish.GridLocation.X));
	Comparison.Y = Abs(Abs(Block.GridLocation.Y) - Abs(Finish.GridLocation.Y));
	Comparison.Z = Abs(Abs(Block.GridLocation.Z) - Abs(Finish.GridLocation.Z));
	return (Comparison.X+Comparison.Y+Comparison.Z)*2;
}

/** The best block in a list is whichever has the lowest score. */
final function TowerBlock GetBestBlock(out array<TowerBlock> OpenList, TowerBlock Finish)
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
final function ConstructPath(TowerBlock Finish)
{
	local TowerBlock Block;
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
		Objective = Owner.Spawn(class'TowerAIObjective',,, Block.Location);
		InitializeObjective(Objective, Block, PreviousObjective);
	}
	`log("Path construction complete!",,'AStar');
	DebugLogPaths();
}

final function InitializeObjective(TowerAIObjective Objective, TowerBlock Block, out TowerAIObjective PreviousObjective)
{
	Objective.SetTarget(Block);
	if(Block.IsA('TowerBlockStructural') || Block.IsA('TowerBlockAir'))
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

function ReverseArray(out array<TowerBlock> Blocks)
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

simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	if(bStepSearch && bDeferred && bDrawStepInfo)
	{
		DebugDrawStepInfo(Canvas);
	}
	if(Paths.Length > 0)
	{
		DebugDrawPath(DebugStart, DebugFinish, Canvas);
	}
}

final function DebugCreateStepMarkers(out array<TowerBlock> OpenList, out array<TowerBlock> ClosedList)
{
	local TowerAIObjective Marker;
	local TowerBlock Block;
	StepMarkers.Remove(0, StepMarkers.Length);
	foreach OpenList(Block)
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

final function DebugLogPaths()
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

final function DebugDrawPath(TowerBlock Start, TowerBlock Finish, Canvas Canvas)
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

final function DebugDrawStepInfo(Canvas Canvas)
{
	local TowerBlock Block;
	local int i;
	Canvas.SetDrawColor(255,255,255);
	Canvas.SetPos(0,0);
	Canvas.SetPos(0,50);
	Canvas.DrawText("OpenList:");
	i = 62;
	foreach DeferredOpenList(Block)
	{
		Canvas.SetPos(0, i);
		Canvas.DrawText(Block.Name);
		i += 12;
	}
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

final function DebugDrawBlockFitness(Canvas Canvas)
{
	/*
	local TowerBlock Block;
	foreach OpenList(Block)
	{

	}
	*/
}