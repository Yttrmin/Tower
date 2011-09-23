/**
TowerFactionAIBasic

The basic FactionAI for the game. Operates primarily be sending out a random assortment of units, keeping track
of the biggest obstacles for its units, and using that data to send out units to counter it.
This class will be fully released for modding, implementation and everything!
*/
class TowerFactionAIBasic extends TowerFactionAI;

//@TODO - Move relevant TowerFactionAI stuff into here.

struct BlockKillInfo
{
	var TowerBlock Block;
	var int InfantryKillCount, ProjectileKillCount, VehicleKillCount;
};

struct BlockTargetInfo
{
	var TowerBlock Block;
	var int ArchetypeIndex;
};

//============================================================================================================
// CollectData-related variables.

var array<BlockKillInfo> Killers;

var array<BlockTargetInfo> Targets;

//============================================================================================================

state Active
{
	protected function DetermineStrategy()
	{
		// Actually, you know, determine a strategy.
		GotoState('CollectData');
	}
}

state CollectData extends Active
{
	event BeginState(Name PreviousStateName)
	{
		QueueFormations();
		BeginCoolDown();
//		SetTimer(45, false, 'DoneCollecting');
	}

	event Think()
	{
		
	}

	event CooledDown()
	{
		SpawnFromQueue();
	}

	function SpawnFromQueue()
	{
		if(OrderQueue.Length > 0)
		{
			if(SpawnFormation(OrderQueue[0].FormationIndex, OrderQueue[0].SpawnPoint, OrderQueue[0].Target))
			{
				OrderQueue.Remove(0, 1);
			}
		}
	}

	function QueueFormations()
	{
		local int ConsumedBudget;
		local FormationSpawnInfo NewFormation;
		local int FormationIndex;

		while(ConsumedBudget + CalculateBaseFormationCost(3) <= Budget)
		{
			ConsumedBudget += CalculateBaseFormationCost(3);
			FormationIndex = 3;
			NewFormation.SpawnPoint = GetSpawnPoint(FormationIndex);
			NewFormation.Target = Hivemind.RootBlock;
			NewFormation.FormationIndex = FormationIndex;
			OrderQueue.AddItem(NewFormation);
		}
	}

	function DoneCollecting()
	{
		local BlockTargetInfo Info;
		local int i;
		// Sort by most killed and by type.
		Killers.sort(SortKillers);
		for(i = 0; i < Killers.Length; i++)
		{
			CreateBlockTargetInfo(Killers[i], Info);
			Targets.AddItem(Info);
		}
		GotoState('Counter');
	}

	function CreateBlockTargetInfo(BlockKillInfo KillInfo, out BlockTargetInfo TargetInfo)
	{
		TargetInfo.Block = KillInfo.Block;
		TargetInfo.ArchetypeIndex = Hivemind.Blocks.Find('BlockArchetype', TowerBlock(KillInfo.Block.ObjectArchetype));
		if(TargetInfo.ArchetypeIndex == -1)
		{
			TargetInfo.ArchetypeIndex = AddBlockInfoFromKillInfo(KillInfo);
		}
	}

	function int AddBlockInfoFromKillInfo(BlockKillInfo Info)
	{
		local AIBlockInfo NewInfo;
		NewInfo.BlockArchetype = TowerBlock(Info.Block.ObjectArchetype);
		// Assign flags!
		Hivemind.Blocks.AddItem(NewInfo);
		return Hivemind.Blocks.Length-1;
	}

	function int SortKillers(out BlockKillInfo P1, out BlockKillInfo P2)
	{
		local int P1Count, P2Count;
		P1Count = P1.InfantryKillCount + P1.ProjectileKillCount + P1.VehicleKillCount;
		P2Count = P2.InfantryKillCount + P2.ProjectileKillCount + P2.VehicleKillCount;
		if(P1Count > P2Count)
		{
			return 1;
		}
		else if(P1Count < P2Count)
		{
			return -1;
		}
		else
		{
			return 0;
		}
	}

	event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerBlock BlockKiller)
	{
		local int Index;
		Super.OnTargetableDeath(Targetable, TargetableKiller, BlockKiller);
		if(TargetableKiller != None)
		{
		//	Index = Killers.find('PlaceableArchetype', Targetable
		}
		else if(BlockKiller != None)
		{
			Index = Killers.find('Block', BlockKiller);
			if(Index != -1)
			{
				AppendToKillersArray(Index, Targetable);
			}
			else
			{
				Killers.Add(1);
				Index = Killers.Length-1;
				Killers[Index].Block = BlockKiller;
				AppendToKillersArray(Index, Targetable);
			}
		}
	}

	function AppendToKillersArray(int Index, TowerTargetable KilledTargetable)
	{
		if(KilledTargetable.IsInfantry())
		{
			Killers[Index].InfantryKillCount++;
		}
		if(KilledTargetable.IsVehicle())
		{
			Killers[Index].VehicleKillCount++;
		}
		if(KilledTargetable.IsProjectile())
		{
			Killers[Index].ProjectileKillCount++;
		}
	}
}

state Counter extends Active
{

}