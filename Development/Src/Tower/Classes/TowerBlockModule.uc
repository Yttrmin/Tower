class TowerBlockModule extends TowerBlock
	abstract;

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

var() protected const editinline TowerRangeComponent RangeComponent;

event Initialize(out IVector NewGridLocation, out IVector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI)
{
	Super.Initialize(NewGridLocation, NewParentDirection, NewOwnerPRI);
	if(RangeComponent != None)
	{
		RangeComponent.Initialize();
	}
}

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == NameOf(ParentDirection))
	{
		CalculateBlockRotation();
	}
	else if(VarName == NameOf(ReplicatedBase))
	{
		if(ReplicatedBase == None)
		{
			Destroy();
		}
		else if(Base != ReplicatedBase)
		{
			SetBase(ReplicatedBase);
		}
	}
	else if(VarName == 'GridLocation')
	{
		//SetGridLocation(true, false);
		if(ReplicatedBase != None)
		{
			UpdateLocation();
		}
		return;
	}
	Super.ReplicatedEvent(VarName);
}

simulated event OnEnterRange(TowerTargetable Targetable);

simulated event OnExitRange(TowerTargetable Targetable);

event Think()
{
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
	if(RangeComponent != None)
	{
		RangeComponent.ModuleDestroyed();
	}
}

DefaultProperties
{
	bReplicateMovement=false
}