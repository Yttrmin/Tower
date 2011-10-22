class TowerRangeGlobalComponent extends TowerRangeComponent;

struct RangeCallbacks
{
	var() bool bInfantry, bVehicle, bProjectile;
};

/** Whichever variables are TRUE will result in this object getting OnEnterRange() called on it when such an 
enemy comes in range. */ 
var() private const RangeCallbacks Callbacks;

event Initialize()
{
	Super.Initialize();
	RegisterRangeCallbacks();
}

event ModuleDestroyed()
{
	Super.ModuleDestroyed();
	UnRegisterRangeCallbacks();
}

private function RegisterRangeCallbacks()
{
	OwnerPRI.Tower.Root.AddRangeNotifyCallback(OnEnterRange, Callbacks.bInfantry, Callbacks.bVehicle, Callbacks.bProjectile);
}

private function UnRegisterRangeCallbacks()
{
	OwnerPRI.Tower.Root.RemoveRangeNotifyCallback(OnEnterRange, Callbacks.bInfantry, Callbacks.bVehicle, Callbacks.bProjectile);
}