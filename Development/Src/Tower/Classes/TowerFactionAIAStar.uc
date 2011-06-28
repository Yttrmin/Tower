/**
TowerFactionAIStar

A TowerFactionAI that uses data from the Hivemind to do an A* search and find the best route to the root.
Infantry can only climb one block high at once! Keep this in mind!

Some cases I'd like to see work:
1) Root with tons on blocks on its own Z level but none above it. AI will trace through air blocks for the cheapest
path to Root.

--P----------- <-
R| | | | | | |  P


--
*/
class TowerFactionAIAStar extends TowerFactionAI
	config(Tower);

var config float DesiredPathfindTime;
var array<TowerBlock> PathToRoot;
var TowerBlock DebugStart, DebugFinish;
var bool bDrewPath;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(10, false, 'Start');
}

function Start()
{
	`log("Starting TowerFactionAIAStar!");
	Hivemind.RegisterForAsyncTick(AsyncTick);
}

/** Uses A* to determine a path of blocks to work through to get to the root!
Please call me from AsyncTick! 
May have to defer over multiple ticks if it has an impact on frame rate. */
//@TODO - Document ASAP!
final function GeneratePath(TowerBlock Start, TowerBlock Finish)
{
	local array<TowerBlock> OpenList, ClosedList;
	// References whichever Block in the OpenList that has the lowest Fitness.
	local TowerBlock BestBlock;
	local TowerBlock OldAStarParent;
	local int i;

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
	while(OpenList.Length > 0)
	{
		i++;
		BestBlock = GetBestBlock(OpenList, Finish);
		`log("Iteration"@i$": Best:"@BestBlock@"Score:"@BestBlock.Fitness,,'AStar');
		if(BestBlock == Finish)
		{
			// We're done.
			ConstructPath(Finish);
			break;
		}
		else if(BestBlock == None)
		{
			// No path?! How?!
		}
		AddAdjacentBlocks(OpenList, ClosedList, BestBlock, Finish);
		OpenList.RemoveItem(BestBlock);
		ClosedList.AddItem(BestBlock);
	}

	`log("================== FINISHED A* ==================",,'AStar');
}

final function TowerBlock GetBestBlock(out array<TowerBlock> OpenList, TowerBlock Finish)
{
	local TowerBlock BestBlock, IteratorBlock;
	foreach OpenList(IteratorBlock)
	{
		`log("Checking for best:"@IteratorBlock@IteratorBlock.Fitness);
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

final function GenerateObjectives()
{

}

event Think()
{

}

final function ConstructPath(TowerBlock Finish)
{
	local TowerBlock Block;
	local int i;
	local array<TowerBlock> BackwardsPath;
	`log("* * Path complete, constructing!",,'AStar');
	for(Block = Finish; Block != None; Block = Block.AStarParent)
	{
		BackwardsPath.AddItem(Block);
	}
	for(i = BackwardsPath.Length-1; i >= 0; i--)
	{
		PathToRoot.AddItem(BackwardsPath[i]);
		`log(PathToRoot.Length$":"@BackwardsPath[i]);
	}
	`log("Path construction complete!",,'AStar');
}

final function TowerBlockAir GetStartingBlock()
{
	local TowerBlock HitActor;
	local TowerBlockAir Start;
	local Vector HitLocation, HitNormal;
	local IVector DesiredGridLocation;
	HitActor = TowerBlock(Trace(HitLocation, HitNormal, Hivemind.RootBlock.Target.Location, 
		GetFactionLocationDirection()*8192, true));
	DesiredGridLocation = HitActor.GridLocation + GetFactionLocationDirection();
	foreach HitActor.BasedActors(class'TowerBlockAir', Start)
	{
		if(Start.GridLocation == DesiredGridLocation)
		{
			return Start;
		}
	}
	`warn("!!!!!!!!!!"@Self$"::GetStartingBlock() couldn't find a TowerBlockAir in a direction from HitActor!!!!!!!");
	return None;
}

final function AddAdjacentBlocks(out array<TowerBlock> OpenList, out array<TowerBlock> ClosedList, 
	TowerBlock SourceBlock, TowerBlock Finish)
{
	local array<TowerBlock> AdjacentList;
	local TowerBlock IteratorBlock;
	local TowerBlockAir IteratorAirBlock;
	local TowerBlock OldAStarParent;
	local int GoalCost;
	GoalCost = SourceBlock.GoalCost;
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
//		OldAStarParent = IteratorBlock.AStarParent;
//		IteratorBlock.AStarParent = SourceBlock;
//		CalculateCosts(IteratorBlock, SourceBlock, Finish);
//		IteratorBlock.AStarParent = OldAStarParent;
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
			// IRRELEVANT.
			// Already in ClosedList.
			if(IteratorBlock.GoalCost > SourceBlock.GoalCost)
			{
				// Better path?
				`log("Better path in the closed list shouldn't happen!(?)",,'AStar');
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

// SHOULD LITERALLY NEVER BE CALLED FOR OUR TESTS. IRRELEVANT.
final function UpdateParents(TowerBlock Block, TowerBlock Finish)
{
	local TowerBlock IteratorBlock;
	local TowerBlockAir IteratorAirBlock;
	local array<TowerBlock> AdjacentList;
	local int GoalCost;
	GoalCost = Block.GoalCost;
	`log("UPDATEPARENTD* **********************");
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

/** Returns true if both blocks share just an edge. */
final function bool IsDiagonalTo(TowerBlock A, TowerBlock B)
{
	local IVector Comparison;
	local bool bValid;
	local byte Count;
	bValid = true;
	Comparison.X = Abs(Abs(A.GridLocation.X) - Abs(B.GridLocation.X));
	Comparison.Y = Abs(Abs(A.GridLocation.Y) - Abs(B.GridLocation.Y));
	Comparison.Z = Abs(Abs(A.GridLocation.Z) - Abs(B.GridLocation.Z));
	if(Comparison.X == 1)
	{
		Count++;
	}
	else if(Comparison.X > 1)
	{
		bValid = false;
	}
	if(Comparison.Y == 1)
	{
		Count++;
	}
	else if(Comparison.Y > 1)
	{
		bValid = false;
	}
	if(Comparison.Z == 1)
	{
		Count++;
	}
	else if(Comparison.Z > 1)
	{
		bValid = false;
	}
	// If corner-checking we'd look for Count == 3.
	return (Count == 2 && bValid);
}

//@TODO - Make this not awful.
final function bool IsAdjacentTo(TowerBlock A, TowerBlock B)
{
	local IVector Comparison;
	local bool bNoMoreDeviation;
	local bool bValid;
	bValid = true;
	bNoMoreDeviation = false;
	Comparison = A.GridLocation - B.GridLocation;
	if(Comparison.X == 1 || Comparison.X == -1)
	{
		if(bNoMoreDeviation)
		{
			bValid = false;
		}
		else
		{
			bNoMoreDeviation = true;
			bValid = true;
		}
	}
	if(bValid && (Comparison.Y == 1 || Comparison.Y == -1))
	{
		if(bNoMoreDeviation)
		{
			bValid = false;
		}
		else
		{
			bNoMoreDeviation = true;
			bValid = true;
		}
	}
	if(bValid && (Comparison.Z == 1 || Comparison.Z == -1))
	{
		if(bNoMoreDeviation)
		{
			bValid = false;
		}
		else
		{
			bNoMoreDeviation = true;
			bValid = true;
		}
	}
	return bValid && bNoMoreDeviation;
}

final function DebugDrawPath(TowerBlock Start, TowerBlock Finish, Canvas Canvas)
{
	local Vector BeginPoint, EndPoint;
	local int i;
	BeginPoint = Canvas.Project(Start.Location+Vect(16,16,16));
	Canvas.CurX = BeginPoint.X;
	Canvas.CurY = BeginPoint.Y;
	Canvas.bCenter = true;
	Canvas.DrawText("Start");
	EndPoint = Canvas.Project(Finish.Location+Vect(16,16,16));
	Canvas.CurX = EndPoint.X;
	Canvas.CurY = EndPoint.Y;
	Canvas.DrawText("Finish");
	Canvas.bCenter = false;
//	DrawDebugString(Start.Location, "Start");
//	DrawDebugStar(Start.Location, 48, 0, 255, 0, true);
//	DrawDebugString(Finish.Location, "Finish", Finish);
//	DrawDebugStar(Finish.Location, 48, 0, 255, 0, true);
	for(i = PathToRoot.Length-2; i >= 0; i--)
	{
		BeginPoint = Canvas.Project(PathToRoot[i].Location+Vect(16,16,16));
		EndPoint = Canvas.Project(PathToRoot[i+1].Location+Vect(16,16,16));
		Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, EndPoint.X, EndPoint.Y, MakeColor(0, 255, 0));
//		DrawDebugLine(PathToRoot[i].Location+Vect(16,16,16), PathToRoot[i+1].Location+Vect(16,16,16), 0, 0, 255, true);
	}
}

final function DebugDrawNames(Canvas Canvas)
{
	local TowerBlock Block;
	local Vector BeginPoint;
	foreach DynamicActors(class'TowerBlock', Block)
	{
		BeginPoint = Canvas.Project(Block.Location+Vect(16,16,16));
		Canvas.CurX = BeginPoint.X;
		Canvas.CurY = BeginPoint.Y;
		Canvas.DrawText(Block.name);
	}
}

simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	Super.PostRenderFor(PC, Canvas, CameraPosition, CameraDir);
	//@TODO - Move me somewhere appropriate.
	DebugDrawNames(Canvas);
	if(PathToRoot.Length > 0)
	{
		DebugDrawPath(DebugStart, DebugFinish, Canvas);
	}
}

final function int GetHeuristicCost(TowerBlock Block, TowerBlock Finish)
{
	local IVector Comparison;
	Comparison.X = Abs(Abs(Block.GridLocation.X) - Abs(Finish.GridLocation.X));
	Comparison.Y = Abs(Abs(Block.GridLocation.Y) - Abs(Finish.GridLocation.Y));
	Comparison.Z = Abs(Abs(Block.GridLocation.Z) - Abs(Finish.GridLocation.Z));
	return (Comparison.X+Comparison.Y+Comparison.Z)*2;
}

final function Vector GetFactionLocationDirection()
{
	switch(Faction)
	{
	case FL_PosX:
		return Vect(1,0,0);
	case FL_NegX:
		return Vect(-1,0,0);
	case FL_PosY:
		return Vect(0,1,0);
	case FL_NegY:
		return Vect(0,-1,0);
	default:
		`warn(Self@"has a FactionLocation unsupported for AIs!:"@Faction);
		return Vect(0,0,0);
	}
}

event AsyncTick(float DeltaTime)
{
	if(PathToRoot.Length == 0)
	{
		GeneratePath(GetStartingBlock(), Hivemind.RootBlock.Target);
	}
}

DefaultProperties
{
	bDebug=true
	bDrewPath=false
}