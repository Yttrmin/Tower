/** Faction AI used solely for testing. */
class TowerFactionAIDebug extends TowerFactionAI;

event PostBeginPlay()
{
	super.PostBeginPlay();
	WorldInfo.Game.Broadcast(None, "Debug Faction spawned and ready.");
}

DefaultProperties
{
	AtWar.Add(F_Player)
}