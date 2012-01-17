//=============================================================================
// TowerBlockStructural
// 
// Base class for blocks that provide support for other blocks, can have modules attached to them,
// and fall if they're not connected to any blocks that have a path to the root block.
// While the root block meets some of these criteria, it is considered a special type and is not
// a subclass of this.
//=============================================================================
class TowerBlockStructural extends TowerBlock;

//=============================================================================
// Replication Notes
//
// TowerBlockStructurals have bReplicateMovement set to false. This means the following variables aren't replicated:
// Location, Rotation, Base, RelativeRotation, RelativeLocation, Velocity, and Physics.
//=============================================================================

simulated event ReplicatedEvent(name VarName)
{
	/*
	if(VarName == 'bFallingParent')
	{
		if(bFallingParent)
		{
			GotoState('UnstableParent');
		}
		else
		{
			GotoState('Stable');
		}
	}
	else if(VarName == 'bFallingChild')
	{
		if(bFallingChild)
		{
			GotoState('Unstable');
		}
		else
		{
			GotoState('Stable');
		}
	}
	*/
	if(VarName == 'ReplicatedBase')
	{
		if(GridLocation != default.GridLocation && (Base == None || Base != ReplicatedBase))
		{
//			`log(self@"ReplicatedBase:"@ReplicatedBase);
			SetBase(ReplicatedBase);
			if(Base == None)
			{
				GotoState('UnstableParent');
			}
			else
			{

			}
			SetGridLocation(true, false);
			//@BUG I DONT UNDERSTAND
//			CalculateBlockRotation();
		}
	}
	else if(VarName == 'GridLocation')
	{
		//SetGridLocation(true, false);
		if(ReplicatedBase != None)
		{
			ReplicatedEvent('ReplicatedBase');
		}
		return;
	}
	Super.ReplicatedEvent(VarName);
}

simulated final function float TimeToDrop()
{
	local float Time;
	Time = 256 / DropRate;	
	return Time;
}

simulated function bool IsTouchingGround(bool bChildrenCheck)
{
	local TowerBlockStructural Block;
	SetGridLocation(false);
	if(GridLocation.Z == 0)
	{
		`log(Self@"is touching the ground!");
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
//			bReplicateMovement = true;
		}
	}
}

simulated event BaseChange()
{
	/*
	if(Role < ROLE_Authority)
	{
		`log(Self@"BaseChange:"@Base@GetStateName());
	}
	*/
}

/** State for blocks that are part of an orphan branch, but not the root of it. */
simulated state Unstable
{
	simulated event Destroyed()
	{
		local TowerBlock BaseMost;
		BaseMost = TowerBlock(GetBaseMost());
		SetBase(None);
		`log(Self@"saying LostOrphan!");
		BaseMost.LostOrphan();
		Super.Destroyed();
		`log(Self@"destroying.");
	}
};

/** State for root blocks of orphan branches. Block falls with all its attachments. */
simulated state UnstableParent extends Unstable
{
	simulated event BeginState(name PreviousStateName)
	{
		if(IsTouchingGround(true))
		{
			GotoState('InActive');
		}
		else
		{
			SetTimer(TimeToDrop(), true, NameOf(DroppedSpace));
		}
	}
	simulated event Tick(float DeltaTime)
	{
		local Vector NewLocation;
		Super.Tick(DeltaTime);
		NewLocation.X = Location.X;
		NewLocation.Y = Location.Y;
		NewLocation.Z = Location.Z - (DropRate * DeltaTime);

		SetLocation(NewLocation);
	}

	/** Called after block should have dropped 256 units.  */
	simulated event DroppedSpace()
	{
		if(IsTouchingGround(true))
		{
			GotoState('InActive');
		}
		// Make sure our children check for bases too.
		if(OwnerPRI.Tower.FindNewParent(Self, None, true))
		{
//			`log("Found parent:"@Base);
			GotoState('Stable');
		}
		//@TODO - NEED TO CHANGE GRID LOCATION FOR CHILDREN TOO
		
	}
	simulated event BaseChange()
	{
		Global.BaseChange();
		if(Role < ROLE_Authority)
		{
			if(Base != None)
			{
				GotoState('Stable');
			}
		}
	}
	simulated event EndState(Name NextStateName)
	{
		ClearTimer(NameOf(DroppedSpace));
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

/** Called on TowerBlocks that are the root node of an orphan branch. */
event OrphanedParent()
{
	local TowerBlock Node;
	GotoState('UnstableParent');
	OwnerPRI.Tower.OrphanRoots.AddItem(Self);
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
/** Called on orphan parent when adopted. */
event AdoptedParent()
{
	local TowerBlockStructural Node;
	SetGridLocation(true);
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
	bReplicateMovement=false
	GridLocation=(X=-1,Y=-1,Z=-1)

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		ScriptRigidBodyCollisionThreshold=999999
		BlockActors=true
		RBChannel=RBCC_GameplayPhysics
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE)
		bNotifyRigidBodyCollision=false
		BlockRigidBody=true
		BlockNonZeroExtent=true
	End Object
	CollisionComponent=StaticMeshComponent0
	MeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)
}

