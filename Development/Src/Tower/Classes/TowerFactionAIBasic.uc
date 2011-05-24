/**
TowerFactionAIBasic

The basic FactionAI for the game. Operates primarily be sending out a random assortment of units, keeping track
of the biggest obstacles for its units, and using that data to send out units to counter it.
This class will be fully released for modding, implementation and everything!
*/
class TowerFactionAIBasic extends TowerFactionAI;

//@TODO - Move relevant TowerFactionAI stuff into here.

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
		local int Budget;
		local int ConsumedBudget;
		local FormationSpawnInfo NewFormation;
		local int FormationIndex;
		Budget = TroopBudget;

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
		local PlaceableTargetInfo Info;
		local int i;
		// Sort by most killed and by type.
		Killers.sort(SortKillers);
		for(i = 0; i < Killers.Length; i++)
		{
			CreatePlaceableTargetInfo(Killers[i], Info);
			Targets.AddItem(Info);
		}
		GotoState('Counter');
	}

	function CreatePlaceableTargetInfo(PlaceableKillInfo KillInfo, out PlaceableTargetInfo TargetInfo)
	{
		TargetInfo.Placeable = KillInfo.Placeable;
		TargetInfo.ArchetypeIndex = Hivemind.Placeables.Find('PlaceableArchetype', KillInfo.Placeable.ObjectArchetype);
		if(TargetInfo.ArchetypeIndex == -1)
		{
			TargetInfo.ArchetypeIndex = AddPlaceableInfoFromKillInfo(KillInfo);
		}
	}

	function int AddPlaceableInfoFromKillInfo(PlaceableKillInfo Info)
	{
		local PlaceableInfo NewInfo;
		NewInfo.PlaceableArchetype = Info.Placeable.ObjectArchetype;
		// Assign flags!
		Hivemind.Placeables.AddItem(NewInfo);
		return Hivemind.Placeables.Length-1;
	}

	function int SortKillers(out PlaceableKillInfo P1, out PlaceableKillInfo P2)
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

	event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerPlaceable PlaceableKiller)
	{
		local int Index;
		if(TargetableKiller != None)
		{
		//	Index = Killers.find('PlaceableArchetype', Targetable
		}
		else if(PlaceableKiller != None)
		{
			Index = Killers.find('Placeable', PlaceableKiller);
			if(Index != -1)
			{
				AppendToKillersArray(Index, Targetable);
			}
			else
			{
				Killers.Add(1);
				Index = Killers.Length-1;
				Killers[Index].Placeable = PlaceableKiller;
				AppendToKillersArray(Index, Targetable);
			}
		}
	}
}

state Counter extends Active
{

}