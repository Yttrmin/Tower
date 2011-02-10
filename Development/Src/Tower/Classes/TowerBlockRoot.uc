class TowerBlockRoot extends TowerBlock;

var Volume RadarVolume;
var array<delegate<OnEnterRange> > InfantryRangeNotify, ProjectileRangeNotify, VehicleRangeNotify,
	AllRangeNotify;

delegate OnEnterRange(Actor Attacker);

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	ServerInitialize();
}

reliable server function ServerInitialize()
{
	RadarVolume = TowerMapInfo(WorldInfo.GetMapInfo()).RadarVolume;
	`assert(RadarVolume != None);
	RadarVolume.AssociatedActor = Self;
	RadarVolume.InitialState = GetStateName();
	RadarVolume.GotoState('AssociatedTouch');
}

/** RadarVolume's Touch. */
event k2override Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation,
	vector HitNormal)
{

}

/** RadarVolume's UnTouch. */
event k2override UnTouch(Actor Other)
{

}

function AddRangeNotifyCallback(delegate<OnEnterRange> Callback, bool bInfantryNotify, 
	bool bProjectileNotify, bool bVehicleNotify)
{
	if(bInfantryNotify && bProjectileNotify && bVehicleNotify)
	{
		AllRangeNotify.AddItem(Callback);
		return;
	}
	else if(bInfantryNotify)
	{
		InfantryRangeNotify.AddItem(Callback);
	}
	else if(bProjectileNotify)
	{
		ProjectileRangeNotify.AddItem(Callback);
	}
	else if(bVehicleNotify)
	{
		VehicleRangeNotify.AddItem(Callback);
	}
	return;
}

DefaultProperties
{
	DisplayName="Root Block"
	XSize = 256
	YSize = 256
	ZSize = 256
	Begin Object Name=StaticMeshComponent0
	    StaticMesh=StaticMesh'TowerBlocks.DebugBlock'
		Materials(0)=Material'TowerBlocks.DebugBlockMaterial'
	End Object
	CollisionComponent=StaticMeshComponent0
}