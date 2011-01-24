/** Faction AI used solely for testing. */
class TowerFactionAIDebug extends TowerFactionAI;

var bool bTemp;

event PostBeginPlay()
{
	super.PostBeginPlay();
	WorldInfo.Game.Broadcast(None, "Debug Faction spawned and ready.");
}

event Think()
{
	Super.Think();
	if(!bTemp)
		if(LaunchProjectile())
			bTemp = True;
}

DefaultProperties
{
//	AtWar.Add(F_Player)
	Begin Object Name=FactionInfo0
		KProjectiles.Add(class'TowerKProjRock');
	End Object
}