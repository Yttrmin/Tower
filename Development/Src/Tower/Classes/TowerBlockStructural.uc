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
			GotoState('Unstable');
		}
		else
		{
			GotoState('Stable');
		}
	}
}

/** State for root blocks of orphan branches. Block falls with all its attachments. */
simulated state Unstable
{
	//@TODO - Experiment with Move() function.
	/** Called after block should have dropped 256 units.  */
	event DroppedSpace()
	{
		`log("Dropped space");
		// SetRelativeLocation here to be sure?
		//SetFullLocation(Location, false);
//		SetGridLocation();
		`log("GridLocation Z:"@GridLocation.Z);
		if(GridLocation.Z == 0)
		{
			GotoState('InActive');
			bFalling = false;
		}
		if(OwnerPRI.Tower.FindNewParent(Self))
		{
			`log("Found parent:"@Base);
			GotoState('Stable');
			bFalling = false;
		}
		// NEED TO CHANGE GRID LOCATION FOR CHILDREN TOO
		
	}
	event BeginState(name PreviousStateName)
	{
		if(GridLocation.Z == 0)
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
	function bool CanDrop()
	{
		return true;
	}
};

//@TODO - Convert from recursion to iteration!
/** Called on TowerBlocks that are the root node of an orphan branch. */
event OrphanedParent()
{
	local TowerBlock Node;
	bFalling = true;
	GotoState('Unstable');
	`log(Self@"is now unstable!");
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
	`log("OrphanedChild");
	GotoState('UnstableParent');
	foreach BasedActors(class'TowerBlock', Node)
	{
		Node.OrphanedChild();
	}
}

DefaultProperties
{
	bAddToBuildList=true
}

