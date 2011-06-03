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

/** Uses A* to determine a path of blocks to work through to get to the root!
Please call me from AsyncTick! 
May have to defer over multiple ticks if it has an impact on gameplay. */
//@TODO - Document ASAP!
final function GeneratePathToRoot()
{
	local int BestScore, HeuristicScore, i, LowestCostIndex; 
	local array<TowerBlock> OpenList;
	local TowerBlock Start, Finish;
	local TowerBlockAir IteratorAirBlock;
	local TowerBlock IteratorBlock, LowestCostBlock;

	Start = GetStartingBlock();
	Finish = Hivemind.RootBlock.Target;
	OpenList.AddItem(Start);

	// Estimate of cost. Can be way lower than the actual just fine, but not more than the actual! Underestimate!
	HeuristicScore = GetHeuristicCost(Start, Finish);

	while(OpenList.Length > 0)
	{
		LowestCostBlock = OpenList[0];
		LowestCostIndex = 0;
		foreach OpenList(IteratorBlock, i)
		{
			if(IteratorBlock.BaseCost < LowestCostBlock.BaseCost)
			{
				LowestCostBlock = IteratorBlock;
				LowestCostIndex = i;
			}			
		}
		if(LowestCostBlock == Finish)
		{
			//reconstructpath
		}
		OpenList.Remove(LowestCostIndex, 1);
		foreach CollidingActors(class'TowerBlock', IteratorBlock, 136, LowestCostBlock.Location, true)
		{
			if(true)
			{
				//check for air
				foreach IteratorBlock.BasedActors(class'TowerBlockAir', IteratorAirBlock)
				{
					if(IsDiagonalTo(IteratorAirBlock, LowestCostBlock))
					{

					}
				}
				//@todo if not in openset
				OpenList.AddItem(IteratorBlock);
			}
		}
	}
}

final function TowerBlockAir GetStartingBlock()
{
	local TowerBlock HitActor;
	local TowerBlockAir Start;
	local Vector HitLocation, HitNormal;
	local IVector DesiredGridLocation;
	HitActor = TowerBlock(Trace(HitLocation, HitNormal, Vect(0,0,0), GetFactionLocationDirection()*8192, true));
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

final function int GetHeuristicCost(TowerBlock Start, TowerBlock End)
{
	return 0;
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

event AsyncTick();

DefaultProperties
{
	bDebug=true
}