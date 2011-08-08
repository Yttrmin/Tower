class TowerBlockStructural extends TowerBlock;

//@TODO - Move allllllllll of TowerBlock's dropping code and whatnot here.

var repnotify bool bFalling;

replication
{
	if(bNetDirty)
		bFalling;
}

simulated event ReplicatedEvent(name VarName)
{
	Super.ReplicatedEvent(VarName);
	if(VarName == 'bFalling')
	{
		if(bFalling)
		{
			//@BUG
			GotoState('Unstable');
		}
		else
		{
			GotoState('Stable');
		}
	}
}

final function float TimeToDrop()
{
	local float Time;
	Time = 256 / DropRate;	
	return Time;
}

function bool IsTouchingGround(bool bChildrenCheck)
{
	local TowerBlockStructural Block;
	SetGridLocation(false);
	if(GridLocation.Z == 0)
	{
		return true;
	}
	if(bChildrenCheck)
	{
		foreach BasedActors(class'TowerBlockStructural', Block)
		{
			if(Block.IsTouchingGround(bChildrenCheck))
			{
				return true;
			}
		}
	}
	return false;
}

auto simulated state Stable
{
	event BeginState(name PreviousStateName)
	{
		if(PreviousStateName == 'Unstable')
		{
			bReplicateMovement = true;
		}
	}
}

/** State for blocks that are part of an orphan branch, but not the root of it. */
simulated state Unstable
{
	simulated event Destroyed()
	{
		TowerBlockStructural(GetBaseMost()).LostOrphan();
		Super.Destroyed();
	}
};

/** State for root blocks of orphan branches. Block falls with all its attachments. */
simulated state UnstableParent extends Unstable
{
	simulated event Tick(float DeltaTime)
	{
		local Vector NewLocation;
		Super.Tick(DeltaTime);
		NewLocation.X = Location.X;
		NewLocation.Y = Location.Y;
		NewLocation.Z = Location.Z - (DropRate * DeltaTime);

		/*SetCollision(false, false, true);
		SetPhysics(PHYS_Falling);
		Velocity.Z = 128;*/

		SetLocation(NewLocation);
	}

	//@TODO - Experiment with Move() function.
	/** Called after block should have dropped 256 units.  */
	event DroppedSpace()
	{
//		`log(Self@"Dropped space");
		// SetRelativeLocation here to be sure?
		//SetFullLocation(Location, false);
//		`log(Self@"GridLocation Z:"@GridLocation.Z);
		if(IsTouchingGround(true))
		{
			GotoState('InActive');
			bFalling = false;
		}
		if(OwnerPRI.Tower.FindNewParent(Self))
		{
//			`log("Found parent:"@Base);
			GotoState('Stable');
			bFalling = false;
		}
		//@TODO - NEED TO CHANGE GRID LOCATION FOR CHILDREN TOO
		
	}
	event BeginState(name PreviousStateName)
	{
		if(IsTouchingGround(true))
		{
			GotoState('InActive');
			bFalling = false;
		}
		else
		{
			bReplicateMovement = false;
			SetTimer(TimeToDrop(), true, 'DroppedSpace');
		}
	}
	event EndState(Name NextStateName)
	{
		ClearTimer('DroppedSpace');
	}
};

simulated state InActive
{
	event BeginState(name PreviousStateName)
	{
		ClearTimer('DroppedSpace');
	}
	event LostOrphan()
	{
		if(!IsTouchingGround(true))
		{
			GotoState('UnstableParent');
		}
	}
Begin:
	if(OwnerPRI.Tower.FindNewParent(Self))
	{
		`log(Self@"Found parent:"@Base);
		GotoState('Stable');
	}
	Sleep(5);
	Goto('Begin');
}

//@TODO - Convert from recursion to iteration!
/** Called on TowerBlocks that are the root node of an orphan branch. */
event OrphanedParent()
{
	local TowerBlock Node;
	bFalling = true;
	GotoState('UnstableParent');
	OwnerPRI.Tower.OrphanRoots.AddItem(Self);
	//@TODO - Use attachments instead of having EVERY block start timers and change physics and all that.
	foreach BasedActors(class'TowerBlock', Node)
	{
		Node.OrphanedChild();
	}
}

//@TODO - Convert from recursion to iteration!
/** Called on TowerBlocks that are orphans but not the root node. */
event OrphanedChild()
{
	local TowerBlock Node;
	GotoState('Unstable');
	foreach BasedActors(class'TowerBlock', Node)
	{
		Node.OrphanedChild();
	}
}

//@TODO - Convert from recursion to iteration!
event AdoptedParent()
{
	local TowerBlockStructural Node;
	SetGridLocation(false);
	GotoState('Stable');
	OwnerPRI.Tower.OrphanRoots.RemoveItem(Self);
	foreach BasedActors(class'TowerBlockStructural', Node)
	{
		Node.AdoptedChild();
	}
}

event AdoptedChild()
{
	local TowerBlockStructural Node;
	SetGridLocation(false);
	GotoState('Stable');
	foreach BasedActors(class'TowerBlockStructural', Node)
	{
		Node.AdoptedChild();
	}
}

DefaultProperties
{
	bAddToBuildList=true
}

