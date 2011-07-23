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

event Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	// Game Over?
//	Super.Died(Killer, DamageType, HitLocation);
}

function ServerInitialize()
{
	if(!TowerMapInfo(WorldInfo.GetMapInfo()).bRootBlockSet)
	{
		RadarVolume = TowerMapInfo(WorldInfo.GetMapInfo()).RadarVolume;
		`assert(RadarVolume != None);
		RadarVolume.AssociatedActor = Self;
		RadarVolume.InitialState = GetStateName();
		RadarVolume.GotoState('AssociatedTouch');
		TowerMapInfo(WorldInfo.GetMapInfo()).bRootBlockSet = true;
	}
}

/** RadarVolume's Touch. */
event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation,
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
event UnTouch(Actor Other)
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
	Begin Object Name=StaticMeshComponent0
	    StaticMesh=StaticMesh'TowerBlocks.DebugBlock'
		Materials(0)=Material'TowerBlocks.DebugBlockMaterial'
	End Object
	CollisionComponent=StaticMeshComponent0
}