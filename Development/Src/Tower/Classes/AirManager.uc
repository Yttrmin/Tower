class AirManager extends Actor
	config(Tower);

var privatewrite array<TowerBlockAir> AirBlocks;
var private config bool bAutomaticAirChecks;
var private config float AirCheckInterval;
var private TowerBlockAir AirArchetype;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	AirArchetype = TowerBlockAir(TowerGameBase(WorldInfo.Game).AirArchetype);
}

/** Returns an air block at this location. DOES NOT check for a physical block beforehand! */
public final function TowerBlockAir GetAir(const out IVector GridLocation)
{
	local TowerBlockAir Air;
	/* //@BUG (Fixedish) - Danger of crashing here from runaway loop if too many airs. 
	At 100 ticks per defer, crashes between 2400-2500 iterations, 2560 airs.
	Iteration limit and world bounds check should prevent this. */
	foreach AirBlocks(Air)
	{
		if(Air.GridLocation == GridLocation)
		{
			return Air;
		}
	}
	return AddAir(GridLocation);
}

private public final function TowerBlockAir AddAir(const out IVector GridLocation)
{
	AirBlocks.AddItem(Spawn(class'TowerBlockAir',,,
		class'Tower'.static.GridLocationToVector(GridLocation),,AirArchetype));
	AirBlocks[AirBlocks.Length-1].UpdateGridLocation();
	return AirBlocks[AirBlocks.Length-1];
}

public final function ForceCheckAirs(optional TowerBlock FromBlock)
{
	local array<TowerBlock> BlockStack;
	local TowerBlock CurrentBlock, ItrBlock;
	if(FromBlock == None)
	{
		CheckAirs();
	}
	else
	{
		`Push(BlockStack, None);
		CurrentBlock = FromBlock;
		while(CurrentBlock != None)
		{
			DestroyMatchingAir(CurrentBlock.GridLocation);
			foreach CurrentBlock.BasedActors(class'TowerBlock', ItrBlock)
			{
				`Push(BlockStack, ItrBlock);
			}
			CurrentBlock = `Pop(BlockStack);
		}
		`assert(BlockStack.Length == 0);
	}
}

private event CheckAirs()
{
	// Cleanup airs as needed.
	local array<TowerBlock> BlockStack;
	local TowerBlock CurrentBlock, ItrBlock;
	local TowerBlockStructural OrphanBlock;
	local TowerPlayerController PC;
	local Tower Tower;
	foreach WorldInfo.AllControllers(class'TowerPlayerController', PC)
	{
		Tower = TowerPlayerReplicationInfo(PC.PlayerReplicationInfo).Tower;

		`Push(BlockStack, None);
		CurrentBlock = Tower.Root;

		while(CurrentBlock != None)
		{
			DestroyMatchingAir(CurrentBlock.GridLocation);
			foreach CurrentBlock.BasedActors(class'TowerBlock', ItrBlock)
			{
				`Push(BlockStack, ItrBlock);
			}
			CurrentBlock = `Pop(BlockStack);
		}
		`assert(BlockStack.Length == 0);

		foreach Tower.OrphanRoots(OrphanBlock)
		{
			`Push(BlockStack, None);
			CurrentBlock = OrphanBlock;

			while(CurrentBlock != None)
			{
				DestroyMatchingAir(CurrentBlock.GridLocation);
				foreach CurrentBlock.BasedActors(class'TowerBlock', ItrBlock)
				{
					`Push(BlockStack, ItrBlock);
				}
				CurrentBlock = `Pop(BlockStack);
			}
			`assert(BlockStack.Length == 0);
		}
	}
}

private function DestroyMatchingAir(const IVector GridLocation)
{
	local int i;
	local array<int> ToDestroy;
	local TowerBlockAir Air;

	foreach AirBlocks(Air, i)
	{
		if(Air.GridLocation == GridLocation)
		{
			ToDestroy.AddItem(i);
		}
	}
	foreach ToDestroy(i)
	{
		AirBlocks[i].Destroy();
		AirBlocks.Remove(i, 1);
	}
}

DefaultProperties
{
	
}