class TowerModuleRadar extends TowerModule
	deprecated;

var Volume RadarVolume;

// Put volume in map instead of iterating?

var array<delegate<OnProximity> > Blah;

delegate OnProximity(Actor Attacker);

event Initialize()
{
	Super.Initialize();
	/*
	RadarVolume = TowerMapInfo(Owner.WorldInfo.GetMapInfo()).RadarVolume;
	RadarVolume.AssociatedActor = Self;
	RadarVolume.InitialState = GetStateName();
	RadarVolume.GotoState('AssociatedTouch');
	*/
}

function CheckProximity()
{
//	local Actor Test;
//	local delegate<OnProximity> SelectedDelegate;
//	SelectedDelegate = Blah[0];
//	SelectedDelegate(Test);
}