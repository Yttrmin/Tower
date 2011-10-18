class TowerBlockModule extends TowerBlock
	abstract
	AutoExpandCategories(TowerBlockModule);

/**
// If TowerBlockRoot shuffling around arrays gets slow under high-use, finish this. Each Module holds onto its
// its position in the various arrays. Give these to TowerBlockRoot, and it can simply set them to None and
// overwrite them next AddRangeCallback().
struct CallbackArrayPosition
{
	int Infantry, Vehicle, Projectile;
};

var private CallbackArrayPosition ArrayIndexes;
*/

struct RangeCallbacks
{
	var() bool bInfantry, bVehicle, bProjectile;
};

var() protected const bool bUseRangeCallbacks;
/** Whichever variables are TRUE will result in this object getting OnEnterRange() called on it when such an enemy comes
in range. */ 
var() protected const RangeCallbacks Callbacks<EditCondition=bUseRangeCallbacks>;

event Initialize(out IVector NewGridLocation, out IVector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI)
{
	GridLocation = NewGridLocation;
	ParentDirection = NewParentDirection;
	OwnerPRI = NewOwnerPRI;
	if(bUseRangeCallbacks)
	{
		RegisterRangeCallbacks();
	}
}

simulated event OnEnterRange(TowerTargetable Targetable);

event Think();

function RegisterRangeCallbacks()
{
	OwnerPRI.Tower.Root.AddRangeNotifyCallback(OnEnterRange, Callbacks.bInfantry, Callbacks.bVehicle, Callbacks.bProjectile);
}

function UnRegisterRangeCallbacks()
{
	OwnerPRI.Tower.Root.RemoveRangeNotifyCallback(OnEnterRange, Callbacks.bInfantry, Callbacks.bVehicle, Callbacks.bProjectile);
}

auto simulated state Stable
{

};

/** Enter this state in cases like OrphanedChild (modules don't work if there's no path to Root). */
simulated state InActive
{
	ignores Think;
};

simulated state Unstable
{
	
};

/** Called on TowerBlocks that are the root node of an orphan branch.
For Modules, this means our Owner was destroyed or disconnected from us somehow, so we die. */
event OrphanedParent()
{
	Destroy();
}

simulated event Destroyed()
{
	Super.Destroyed();
	UnRegisterRangeCallbacks();
}