class TowerBlockRoot extends TowerBlock;

enum TargetType
{
	TT_Infantry,
	TT_Vehicle,
	TT_Projectile
};

var Volume RadarVolume;
var array<delegate<OnEnterRange> > InfantryRangeNotify, ProjectileRangeNotify, VehicleRangeNotify,
	AllRangeNotify;

simulated delegate OnEnterRange(TowerTargetable Targetable);

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	ServerInitialize();
}

function ServerInitialize()
{
	if(!TowerMapInfo(WorldInfo.GetMapInfo()).bRootBlockSet)
	{
		`log("Initializing root block! This should only be called on servers!");
		RadarVolume = TowerMapInfo(WorldInfo.GetMapInfo()).RadarVolume;
		`assert(RadarVolume != None);
		RadarVolume.AssociatedActor = Self;
		RadarVolume.InitialState = GetStateName();
		RadarVolume.GotoState('AssociatedTouch');
		TowerMapInfo(WorldInfo.GetMapInfo()).bRootBlockSet = true;
	}
}

/** RadarVolume's Touch. */
event k2override Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation,
	vector HitNormal)
{
	local TowerTargetable Targetable;
	Targetable = TowerTargetable(Other);
	if(Targetable != None)
	{
//		`log("RadarVolume touched!"@"Infantry:"@Targetable.IsInfantry()@"Projectile:"@Targetable.IsProjectile()
//			@"Vehicle:"@Targetable.IsVehicle());
		if(Targetable.IsInfantry())
		{
			ExecuteCallbacks(TT_Infantry, Targetable);
		}
		else if(Targetable.IsProjectile())
		{
			ExecuteCallbacks(TT_Projectile, Targetable);
		}
		else if(Targetable.IsVehicle())
		{
			ExecuteCallbacks(TT_Vehicle, Targetable);
		}
	}
}

/** RadarVolume's UnTouch. */
event k2override UnTouch(Actor Other)
{

}

function AddRangeNotifyCallback(delegate<OnEnterRange> Callback, bool bInfantryNotify, 
	bool bProjectileNotify, bool bVehicleNotify)
{
	`log("Adding range callback for Infantry:"@bInfantryNotify@"Projectile:"@bProjectileNotify@"Vehicle:"@bVehicleNotify);
//	if(bInfantryNotify && bProjectileNotify && bVehicleNotify)
//	{
//		AllRangeNotify.AddItem(Callback);
//		return;
//	}
	if(bInfantryNotify)
	{
		InfantryRangeNotify.AddItem(Callback);
	}
	if(bProjectileNotify)
	{
		ProjectileRangeNotify.AddItem(Callback);
	}
	if(bVehicleNotify)
	{
		VehicleRangeNotify.AddItem(Callback);
	}
	return;
}

function ExecuteCallbacks(TargetType Type, TowerTargetable Targetable)
{
	local delegate<OnEnterRange> Callback;
	switch(Type)
	{
	case TT_Infantry:
		foreach InfantryRangeNotify(Callback)
		{
			Callback(Targetable);
		}
		break;
	case TT_Vehicle:
		foreach VehicleRangeNotify(Callback)
		{
			Callback(Targetable);
		}
		break;
	case TT_Projectile:
		foreach ProjectileRangeNotify(Callback)
		{
			Callback(Targetable);
		}
		break;
	}
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