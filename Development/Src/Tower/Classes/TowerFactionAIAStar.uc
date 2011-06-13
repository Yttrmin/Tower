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
	if(false)
	{
		SetTimer(10, false, 'Start');
	}
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
final function GeneratePathToRoot()
{
	local int TentativeCost, i, LowestCostIndex; 
	local array<TowerBlock> OpenList, ClosedList, AdjacentList;
	local TowerBlock Start, Finish;
	// Used when iterating over a block's based actors for TowerBlockAirs.
	local TowerBlockAir IteratorAirBlock;
	local TowerBlock IteratorBlock, LowestCostBlock;
	local bool bTentativeIsBetter;
	`log("================== STARTING A* ==================",,'AStar');
	// Determine our starting and ending points.
	Start = GetStartingBlock();
	Start.BaseCost = 0;
	Finish = Hivemind.RootBlock.Target;
	// DebugStart/Finish are used for keeping track of the Start/Finish so we can draw the path later.
	DebugStart = Start;
	DebugFinish = Finish;
	`log("Start:"@Start@" "@"Finish:"@Finish,,'AStar');
	// Add our Starting block to the OpenList and start pathfinding!
	OpenList.AddItem(Start);

	// Estimate of cost. Can be way lower than the actual just fine, but not more than the actual! Underestimate!
//	HeuristicScore = GetHeuristicCost(Start, Finish);

	while(OpenList.Length > 0 && LowestCostBlock != Finish)
	{
		// Clear the AdjacentList every iteration.
		AdjacentList.Remove(0, AdjacentList.Length);
		// Search through the OpenList for the lowest cost block.
		LowestCostBlock = OpenList[0];
		LowestCostIndex = 0;
		foreach OpenList(IteratorBlock, i)
		{
			`log(IteratorBlock@"cost:"@GetCost(IteratorBlock, Finish)@"Parent:"@IteratorBlock.AStarParent,,'AStar');
			if(GetCost(IteratorBlock, Finish) < GetCost(LowestCostBlock, Finish))
			{
				LowestCostBlock = IteratorBlock;
				LowestCostIndex = i;
			}			
		}
		`log("Determined LowestCostBlock:"@LowestCostBlock@"Cost:"@GetCost(LowestCostBlock, Finish),,'AStar');
		// Put the lowest cost block in the ClosedList so we don't look at it after this.
		OpenList.Remove(LowestCostIndex, 1);
		ClosedList.AddItem(LowestCostBlock);
		// If LowestCostBlock is our Finish block, skip this iteration. Otherwise...
		if(LowestCostBlock == Finish)
		{
			continue;
		}
		// Add each neighboring block (and any of its diagonal airs) to AdjacentList
		// so we can neatly iterate through every block instead of having to copy/paste
		// code and change variable names.
		foreach LowestCostBlock.CollidingActors(class'TowerBlock', IteratorBlock, 200,, true)
		{
			//check for each neighbor's air since it won't get picked up by CollidingActors.
			foreach IteratorBlock.BasedActors(class'TowerBlockAir', IteratorAirBlock)
			{
				if(IsDiagonalTo(IteratorAirBlock, LowestCostBlock))
				{
					AdjacentList.AddItem(IteratorAirBlock);
				}
			}
			AdjacentList.AddItem(IteratorBlock);
		}
		// Now for real look through our neighboring blocks!
		foreach AdjacentList(IteratorBlock)
		{
			
			// If the block is in the ClosedList, skip it.
			if(ClosedList.Find(IteratorBlock) != -1)
			{
				continue;
			}
			TentativeCost = GetCost(IteratorBlock, Finish);
			// Else add it if it's not already in the OpenList...
			if(OpenList.Find(IteratorBlock) == -1)
			{
				OpenList.AddItem(IteratorBlock);
				bTentativeIsBetter = true;
			}
			// Else
			else if(TentativeCost < GetCost(LowestCostBlock, Finish))
			{
				bTentativeIsBetter = true;
			}
			else
			{
				bTentativeIsBetter = false;
			}
			if(bTentativeIsBetter)
			{
				IteratorBlock.AStarParent = LowestCostBlock;
			}
		}
		
	}
	`log("Finished pathfinding! Saving results!",,'AStar');
	for(IteratorBlock = Finish; IteratorBlock != None; IteratorBlock = IteratorBlock.AStarParent)
	{
		`log(IteratorBlock@"s parent is"@IteratorBlock.AStarParent,,'AStar');
		PathToRoot.AddItem(IteratorBlock);
	}
	bDrewPath = false;
	Start.BaseCost = Start.default.BaseCost;
	`log("================== FINISHED A* ==================",,'AStar');
}

final function GenerateObjectives()
{

}

event Think()
{

}

final function int GetCost(TowerBlock Block, TowerBlock Finish)
{
	local int Cost;
	local TowerBlock IteratorBlock;
	for(IteratorBlock = Block; IteratorBlock != None; IteratorBlock = IteratorBlock.AStarParent)
	{
		Cost += IteratorBlock.BaseCost;
	}
	return Cost + GetHeuristicCost(Block, Finish);
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

final function AddAdjacentBlocksToSet(out array<TowerBlock> Set, TowerBlock SourceBlock)
{

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
	return Count == 2 && bValid;
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
	//DebugDrawNames(Canvas);
	if(!bDrewPath)
	{
		DebugDrawPath(DebugStart, DebugFinish, Canvas);
	}
}

final function int GetHeuristicCost(TowerBlock Start, TowerBlock End)
{
	local IVector Comparison;
	Comparison.X = Abs(Abs(Start.GridLocation.X) - Abs(End.GridLocation.X));
	Comparison.Y = Abs(Abs(Start.GridLocation.Y) - Abs(End.GridLocation.Y));
	Comparison.Z = Abs(Abs(Start.GridLocation.Z) - Abs(End.GridLocation.Z));
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
		GeneratePathToRoot();
	}
}

DefaultProperties
{
	bDebug=true
	bDrewPath=true
}