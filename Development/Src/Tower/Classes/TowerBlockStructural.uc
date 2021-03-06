//=============================================================================
// TowerBlockStructural
// 
// Base class for blocks that provide support for other blocks, can have modules attached to them,
// and fall if they're not connected to any blocks that have a path to the root block.
// While the root block meets some of these criteria, it is considered a special type and is not
// a subclass of this.
//=============================================================================
class TowerBlockStructural extends TowerBlock
	implements(SavableDynamic);

const GRID_LOCATION_X_ID = "G_X";
const GRID_LOCATION_Y_ID = "G_Y";
const GRID_LOCATION_Z_ID = "G_Z";
const PARENT_DIRECTION_ID = "P";
const PARENT_DIRECTION_X_ID = "P_X";
const PARENT_DIRECTION_Y_ID = "P_Y";
const PARENT_DIRECTION_Z_ID = "P_Z";
const MOD_INDEX_ID = "M";
const MOD_BLOCK_ID = "B";
const STATE_ID = "S";

//=============================================================================
// Replication Notes
//
// TowerBlockStructurals have bReplicateMovement set to false. This means the following variables aren't replicated:
// Location, Rotation, Base, RelativeRotation, RelativeLocation, Velocity, and Physics.
//=============================================================================

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == NameOf(ReplicatedBase))
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
			//UpdateLocation();
			//@BUG I DONT UNDERSTAND
//			CalculateBlockRotation();
		}
	}
	else if(VarName == NameOf(GridLocation))
	{
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
	return 256 / DropRate; 
}

simulated final function bool IsTouchingGround()
{
	return GridLocation.Z == 0 || GetBaseMost().Class == class'TowerBlockRoot';
}

// Recursion can suck it.
// If we ever need the specific block touching, add an optional out TowerBlockStructural.
/** Returns TRUE if the block is touching the "ground" (GridLocation.Z == 0).
If bCheckHierarchy is TRUE, returns TRUE if any block in the hierarchy (through parent or children) is touching the ground.
If bCheckHierarchyFromSelf is TRUE, only this block and its children are checked for touching.
GridLocation is NOT updated before checking anymore! */
simulated final function bool IsTouchingGroundIterative(bool bStartFromRoot)
{
	// "Stack" to replace recursion. Please don't do non-stack things to it (Find, RemoveItem, etc).
	local array<TowerBlockStructural> BlockStack;
	local TowerBlockStructural ItrBlock;
	local TowerBlock CurrentBlock;

	if(bStartFromRoot && TowerBlock(GetBaseMost()) != None)
	{
		CurrentBlock = TowerBlock(GetBaseMost());
	}
	else
	{
		CurrentBlock = Self;
	}
	// Convenience macros so we can think like a stack. See top of file for definitions.
	// We know we're done if we iterate all the way back to None.
	`Push(BlockStack, None);

	// Check through children now. Loop until the stack is back at index 0...
	while(CurrentBlock != None)
	{
		//@TODO - TowerBlock, not just TowerBlockStructural.
		if(CurrentBlock.GridLocation.Z == 0)
		{
			return true;
		}
		foreach CurrentBlock.BasedActors(class'TowerBlockStructural', ItrBlock)
		{
			`Push(BlockStack, ItrBlock);
		}
		CurrentBlock = `Pop(BlockStack);
	}
	`assert(BlockStack.Length == 0); 
	
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
//		`log(Self@"saying LostOrphan!");
		BaseMost.LostOrphan();
		Super.Destroyed();
//		`log(Self@"destroying.");
	}
};

/** State for root blocks of orphan branches. Block falls with all its attachments. */
simulated state UnstableParent extends Unstable
{
	simulated event BeginState(name PreviousStateName)
	{
		SetBase(None);
		if(IsTouchingGroundIterative(true))
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
		//@README - Move is fine, but diagonal blocks will touch each other and prevent each other from falling.
		// But if we disable collision on falling blocks, won't that break our detection for placing blocks in spots
		// that other blocks are falling into?
		/*
		NewLocation.Z = - (DropRate * DeltaTime);
		Move(NewLocation);
		*/
		NewLocation.X = Location.X;
		NewLocation.Y = Location.Y;
		NewLocation.Z = Location.Z - (DropRate * DeltaTime);

		SetLocation(NewLocation);
	}

	/** Called after block should have dropped 256 units.  */
	simulated event DroppedSpace()
	{
		UpdateGridLocationIterative(true);
		if(IsTouchingGroundIterative(true))
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

	simulated event DroppedSpaceInitial()
	{
		DroppedSpace();
		SetTimer(TimeToDrop(), true, NameOf(DroppedSpace));
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
	simulated event Destroyed()
	{
		Super.Destroyed();
	}
	simulated event EndState(Name NextStateName)
	{
		ClearTimer(NameOf(DroppedSpace));
		ClearTimer('DroppedSpaceInitial');
	}
};

//@TODO - Remove?
simulated state InActive
{
	event LostOrphan()
	{
		//@BUG
		if(!IsTouchingGroundIterative(true))
		{
			GotoState('UnstableParent');
		}
	}
	// Need this since that FindNewParentInterative call could immediately change state to Stable.
	simulated event EndState(Name NextStateName)
	{
		OwnerPRI.Tower.OrphanRoots.RemoveItem(Self);
	}
Begin:
	`log(Self@"Checking for parent in InActive...");
	if(OwnerPRI.Tower.FindNewParentAStar(Self))
	{
		//@BUG - Dead code, see GotoState in FNPI.
		ScriptTrace();
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
	local array<TowerBlockStructural> BlockStack;
	local TowerBlock CurrentBlock;
	local TowerBlockStructural ItrBlock;
	
	OwnerPRI.Tower.OrphanRoots.RemoveItem(Self);
	GotoState('Stable');
	UpdateGridLocationIterative(false);

	CurrentBlock = Self;
	`Push(BlockStack, None);

	while(CurrentBlock != None)
	{
		foreach CurrentBlock.BasedActors(class'TowerBlockStructural', ItrBlock)
		{
			`Push(BlockStack, ItrBlock);
		}
		CurrentBlock = `Pop(BlockStack);
		if(CurrentBlock != None)
		{
			CurrentBlock.AdoptedChild();
		}
	}
	`assert(BlockStack.Length == 0); 
}

event AdoptedChild()
{
	GotoState('Stable');
}

/********************************
Save/Loading
********************************/

public event JSonObject OnSave(const SaveType SaveType)
{
	local JSonObject JSON;
	JSON = new () class'JSonObject';
	if (JSON == None)
	{
		`warn(self@"Could not save!");
		return None;
	}

	JSon.SetIntValue(MOD_INDEX_ID, ModIndex);
	JSon.SetIntValue(MOD_BLOCK_ID, ModBlockIndex);

	JSon.SetIntValue(GRID_LOCATION_X_ID, GridLocation.X);
	JSon.SetIntValue(GRID_LOCATION_Y_ID, GridLocation.Y);
	JSon.SetIntValue(GRID_LOCATION_Z_ID, GridLocation.Z);
	
	JSon.SetIntValue(PARENT_DIRECTION_X_ID, ParentDirection.X);
	JSon.SetIntValue(PARENT_DIRECTION_Y_ID, ParentDirection.Y);
	JSon.SetIntValue(PARENT_DIRECTION_Z_ID, ParentDirection.Z);

	JSon.SetStringValue(STATE_ID, String(GetStateName()));
	return JSon;
}

public event OnLoad(JSONObject Data, TowerGameBase GameInfo, out const GlobalSaveInfo SaveInfo)
{
	local TowerBlockStructural NewBlock;
	// WHY does the compiler complain about name conflicts in a static function?
	local int SavedModIndex, BlockIndex;
	local IVector SavedGridLocation;

	SavedModIndex = Data.GetIntValue(MOD_INDEX_ID);
	BlockIndex = Data.GetIntValue(MOD_BLOCK_ID);
	SavedGridLocation.X = Data.GetIntValue(GRID_LOCATION_X_ID);
	SavedGridLocation.Y = Data.GetIntValue(GRID_LOCATION_Y_ID);
	SavedGridLocation.Z = Data.GetIntValue(GRID_LOCATION_Z_ID);

	//@TODO - TransferBlocks()
	NewBlock = TowerBlockStructural(GameInfo.ServerTower.AddBlock(GetSavedBlockArchetype(SavedModIndex, BlockIndex, SaveInfo),
		None, SavedGridLocation));
	//NewBlock = class'WorldInfo'.static.GetWorldInfo().Spawn(class'TowerBlockStrutural);

//	NewBlock.ModIndex = ModInde
//	NewBlock.ModBlockIndex = 

	NewBlock.ParentDirection.X = Data.GetIntValue(PARENT_DIRECTION_X_ID);
	NewBlock.ParentDirection.X = Data.GetIntValue(PARENT_DIRECTION_Y_ID);
	NewBlock.ParentDirection.X = Data.GetIntValue(PARENT_DIRECTION_Z_ID);
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

