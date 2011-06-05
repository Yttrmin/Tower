/**
TowerBlock

Base class of all the blocks that make up a Tower.

Keep in mind this class and its children will likely be opened up to modding!
*/
class TowerBlock extends DynamicSMActor_Spawnable /*Actor*/
	config(Tower)
	HideCategories(Movement,Attachment,Collision,Physics,Advanced,Object)
	AutoExpandCategories(TowerBlock)
	dependson(TowerGame)
	ClassGroup(Tower)
	placeable
	abstract;

var() int Health;
var() int HealthMax;
/** User-friendly name. Used for things like the build menu. */
//@TODO - Why not make this type name?
var() const Name DisplayName;
var() const String Description;
/** If FALSE, this Placeable will not be accessible to the player for placing in the world. */
var() const bool bAddToBuildList;

//=========================================================
// A*-related
var() int BaseCost;
var TowerBlock AStarParent;
//=========================================================

var const int DropRate;

var repnotify bool bFalling;

/** If FALSE, only StaticMeshComponents will be used with TowerBlocks. */
var private const globalconfig bool bEnableApexDestructibles;

/** Unit vector pointing in direction of this block's parent.
Used in loading to allow TowerTree to reconstruct the hierarchy. Has no other purpose. */
var protectedwrite editconst IVector ParentDirection;
/** Block's position on the grid. */
var protectedwrite editconst IVector GridLocation;

var protected MaterialInstanceConstant MaterialInstance;
var const LinearColor Black;
var protectedwrite TowerPlayerReplicationInfo OwnerPRI;

var private DynamicNavMeshObstacle Obstacle;

var int ModIndex, ModBlockIndex;

replication
{
	if(bNetDirty)
		bFalling;
	if(bNetInitial)
		GridLocation, OwnerPRI;
}

simulated function StaticMesh GetStaticMesh()
{
	return StaticMeshComponent.StaticMesh;
}

simulated function SkeletalMesh GetSkeletalMesh()
{
	return None;
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

simulated event PostBeginPlay()
{
	local Vector ObstacleLocation;
	Super.PostBeginPlay();
	MaterialInstance = StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0);
	
	if(Role == Role_Authority && Location.Z == 128)
	{
		Obstacle = Spawn(class'DynamicNavMeshObstacle');
		ObstacleLocation = Location;
		ObstacleLocation.Z -= 128;
		Obstacle.SetLocation(ObstacleLocation);
		Obstacle.SetAsSquare(128);
		Obstacle.RegisterObstacle();
	}
}

simulated event Destroyed()
{
	if(Role == Role_Authority && Obstacle != None)
	{
		Obstacle.UnRegisterObstacle();
		Obstacle.Destroy();
	}
}

static function TowerBlock AttachBlock(TowerBlock BlockArchetype,
	TowerBlock Parent, out TowerTree NodeTree, out Vector SpawnLocation,
	out IVector NewGridLocation, optional TowerPlayerReplicationInfo OwnerTPRI)
{
	local TowerBlock Block;
	local IVector ParentDir;
	local Rotator NewRotation;
	// Only let stable blocks add stuff to them, otherwise things get wonky.
	if(Parent.IsInState('Stable') || BlockArchetype.class == class'TowerBlockRoot')
	{
		if(Parent != None)
		{
			// Get PRI somewhere else since it might be none.
			//TODO - Simple bool to check if we can just ignore this rotation stuff.
			Block = Parent.Spawn(BlockArchetype.class, Parent,, SpawnLocation,,BlockArchetype,FALSE);
			ParentDir = FromVect(Normal(Parent.Location - SpawnLocation));
//			`log(Block@"AttachBlock. ParentDir:"@Normal(Parent.Location - SpawnLocation));
			if(round(ParentDir.Z) == 0)
			{
				NewRotation.Pitch = ParentDir.X * (90 * DegToUnrRot);
				NewRotation.Roll = ParentDir.Y * (-90 * DegToUnrRot);
				NewRotation.Yaw = ParentDir.Z * (-90 * DegToUnrRot);
			}
			else if(round(ParentDir.Z) == -1)
			{
//				NewRotation.Roll = -180 * DegToUnrRot;
			}
			else if(round(ParentDir.Z) == 1)
			{
				NewRotation.Roll = 180 * DegToUnrRot;
			}
			else
			{
				NewRotation = Block.Rotation;
			}
			Block.SetRelativeRotation(NewRotation);
			Block.Initialize(NewGridLocation, ParentDir, Parent.OwnerPRI);
		}
		else
		{
			`assert(OwnerTPRI != None);
			Block = OwnerTPRI.Spawn(BlockArchetype.class, Parent,, SpawnLocation,,BlockArchetype,TRUE);
			ParentDir = IVect(0,0,0);
			Block.Initialize(NewGridLocation, ParentDir, OwnerTPRI);
		}
		NodeTree.AddNode(Block, Parent);
	}
	return Block;
}

static function RemoveBlock(TowerBlock Block, out TowerTree NodeTree)
{
	NodeTree.RemoveNode(Block);
}

simulated function IVector GetGridLocation()
{
	return GridLocation;
}

event Initialize(out IVector NewGridLocation, out IVector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI)
{
	GridLocation = NewGridLocation;
	ParentDirection = NewParentDirection;
	OwnerPRI = NewOwnerPRI;
//	SetOwner(OwnerPRI);
}

final function TowerBlock GetParent()
{
	return TowerBlock(Base);
}

function SetFullLocation(Vector NewLocation, bool bRelative, 
	optional Vector BaseLocation)
{
	local Vector NewRelativeLocation;
	if(bRelative)
	{
		NewRelativeLocation.X = NewLocation.X - BaseLocation.X;
		NewRelativeLocation.Y = NewLocation.Y - BaseLocation.Y;
		NewRelativeLocation.Z = NewLocation.Z - BaseLocation.Z;
		SetRelativeLocation(NewRelativeLocation);
	}
	else
	{
		SetLocation(NewLocation);
		GridLocation.X = NewLocation.X / 256;
		GridLocation.Y = NewLocation.Y / 256;
		GridLocation.Z = NewLocation.Z / 256;
	}
}

final function SetGridLocation()
{
	local Vector NewLocation;
	GridLocation.X = Round(int(Location.X) / 256);
	GridLocation.Y = Round(int(Location.Y) / 256);
	GridLocation.Z = Round(int(Location.Z) / 256);
	NewLocation.X = 256 * (GridLocation.X - TowerBlock(Base).GridLocation.X);
	NewLocation.Y = 256 * (GridLocation.Y - TowerBlock(Base).GridLocation.Y);
	NewLocation.Z = 256 * (GridLocation.Z - TowerBlock(Base).GridLocation.Z);
	SetRelativeLocation(NewLocation);
}

final simulated function Highlight()
{
	MaterialInstance.SetVectorParameterValue('HighlightColor', 
		OwnerPRI.HighlightColor);
}

final simulated function UnHighlight()
{
	MaterialInstance.SetVectorParameterValue('HighlightColor', Black);
}

final simulated function SetColor()
{

}

static final function bool IsReplicable()
{
	return TRUE;
}

/** */
reliable server function Remove()
{
	`log(Self@"Says to remove self!");
}

/** Blocks don't care about Targetables. */
simulated function OnEnterRange(TowerTargetable Targetable)
{

}

/** apply some amount of damage to this actor
 * @param DamageAmount the base damage to apply
 * @param EventInstigator the Controller responsible for the damage
 * @param HitLocation world location where the hit occurred
 * @param Momentum force caused by this hit
 * @param DamageType class describing the damage that was done
 * @param HitInfo additional info about where the hit occurred
 * @param DamageCauser the Actor that directly caused the damage (i.e. the Projectile that exploded, 
 the Weapon that fired, etc)
 */
event TakeDamage(int Damage, Controller EventInstigator, vector HitLocation, vector Momentum, 
class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
//	`log("Took damage"@Damage@DamageType@DamageCauser@EventInstigator);
	Max(0, Damage);
	Super.TakeDamage(Damage, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	Health -= Damage;
	if(Health <= 0)
	{
		Died(EventInstigator, DamageType, HitLocation);
	}
}

/** Called when this block reaches 0 health. Just tells the Tower to remove it.
Should be overridden in a subclass to add any effects and the Super version called to remove it. */
event Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	OwnerPRI.Tower.RemoveBlock(self);
}

auto simulated state Stable
{
	function StopFall()
	{
		ClearTimer('DroppedSpace');
	}

	event BeginState(name PreviousStateName)
	{
		if(PreviousStateName == 'Unstable')
		{
			`log("Now stable!");
			bReplicateMovement = true;
			ClearTimer('DroppedSpace');
			StopFall();
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
		if(OwnerPRI.Tower.NodeTree.FindNewParent(Self))
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

simulated state UnstableParent
{

};

simulated state Building
{

};

simulated state InActive
{
	event BeginState(name PreviousStateName)
	{
		ClearTimer('DroppedSpace');
	}
Begin:
	if(OwnerPRI.Tower.NodeTree.FindNewParent(Self))
	{
		`log("Found parent:"@Base);
		GotoState('Stable');
	}
	`log("Ping");
	Sleep(5);
	Goto('Begin');
};


function float TimeToDrop()
{
	local float Time;
	//ScriptTrace();
//	Time = sqrt(((512/(BlocksFalling+BlocksFallen))/ZAcceleration)/BlocksFalling);
	Time = 256 / DropRate;	
	`log("TimeToDrop:"@Time);
	return Time;
}

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

//@TODO - Convert from recursion to iteration!
event Adopted()
{
	local TowerBlock Node;
	`log("ADOPTED:"@Self);
	SetGridLocation();
	GotoState('Stable');
	foreach BasedActors(class'TowerBlock', Node)
	{
		Node.Adopted();
	}
}

event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
				const out CollisionImpactData RigidCollisionData, int ContactIndex )
{
	`log("BLOCK IN COLLISION!"@HitComponent@OtherComponent);
}

DefaultProperties
{
	DisplayName="GIVE ME A NAME"
	bAddToBuildList=TRUE
	Health=100
	HealthMax=100

	BaseCost=10

	CustomTimeDilation=1

//	ZAcceleration=1039.829009434
	DropRate=128
//	BlockFallTime=0.701704103 //0.496179729 //2.01539874//
	bCollideWorld=false
	bAlwaysRelevant = true
	bCollideActors=true
	bBlockActors=TRUE

	Begin Object Name=MyLightEnvironment
		bDynamic=FALSE
		bForceNonCompositeDynamicLights=TRUE
		bEnabled=TRUE
		bCastShadows=FALSE
		TickGroup=TG_DuringAsyncWork
		// Using a skylight for secondary lighting by default to be cheap
		// Characters and other important skeletal meshes should set bSynthesizeSHLight=true
	End Object

	 // 256x256x256 cube.
	Begin Object Name=StaticMeshComponent0
		ScriptRigidBodyCollisionThreshold=0.01
		BlockActors=true
		RBChannel=RBCC_GameplayPhysics
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE)
		bNotifyRigidBodyCollision=TRUE
		BlockRigidBody=true
		BlockNonZeroExtent=true
	End Object
}