/**
TowerBlock

Base class of all the blocks that make up a Tower.

Keep in mind this class and its children will likely be opened up to modding!
*/
class TowerBlock extends TowerBlockBase
	config(Tower)
	HideCategories(Attachment,Collision,Physics,Advanced,Object)
	ClassGroup(Tower)
	placeable
	abstract;

//=========================================================
// Used in archetypes when creating new blocks.
/** User-friendly name. Used for things like the build menu. 
Non-const and string so players can nickname blocks. */
var() String DisplayName;
/** Description used when selected in the build menu. */
var() edittextbox const String Description;
/** If TRUE, this block will be in the player's build list. */
var() const bool bAddToBuildList;
/** Maximum health of this block, and what value the block will lerp to during construction. 
May be modified for difficulty. */
var() int HealthMax;
/**  */
var() editinline TowerPurchasableComponent PurchasableComponent;
//=========================================================
var const LinearColor BlackColor;
var const LinearColor UnownedColor;
//=========================================================
// A*-related
/** Base cost to go "through" (destroy) this block in AStar. */
var() int BaseCost<DisplayName=A* Base Cost>;
//@DEBUG @DELETEME
var() bool bDebugIgnoreForAStar<DisplayName=Debug Ignore For A*?>;
var(InGame) int GoalCost, HeuristicCost, Fitness;
var TowerBlock AStarParent;
//=========================================================

var(InGame) int Health;

const DropRate = 128;

/** If FALSE, only StaticMeshComponents will be used with TowerBlocks. */
var private const globalconfig bool bEnableApexDestructibles;
var private const globalconfig bool bEnableNavMeshObstacleGeneration;

/** Unit vector pointing in direction of this block's parent.
Used in loading to allow TowerTree to reconstruct the hierarchy. Has no other purpose. */
var repnotify protectedwrite IVector ParentDirection;
/** Block's position on the grid. */
var(InGame) repnotify protectedwrite editconst IVector GridLocation;
/** This block's current base, only used by clients since Base isn't replicated. */
var repnotify TowerBlock ReplicatedBase;

var protectedwrite MaterialInstanceConstant MaterialInstance;
var protectedwrite TowerPlayerReplicationInfo OwnerPRI;

var private DynamicNavMeshObstacle Obstacle;

/** Used when saving/loading, set in the archetype by the game when the mod is loaded. */
var int ModIndex, ModBlockIndex;

replication
{
	// ParentDirection never changes does it?
	if(bNetInitial)
		OwnerPRI/*, ParentDirection*/;
	if(bNetDirty || bNetInitial)
		GridLocation, ParentDirection, ReplicatedBase;
}

//@FIXED - Normally Detach turns rigid body physics for some insane reason. Let's not do that.
event Detach(Actor Other){}

simulated function StaticMesh GetStaticMesh()
{
	return StaticMeshComponent(MeshComponent) != None ? StaticMeshComponent(MeshComponent).StaticMesh : None;
}

simulated function SkeletalMesh GetSkeletalMesh()
{
	return SkeletalMeshComponent(MeshComponent) != None ? SkeletalMeshComponent(MeshComponent).SkeletalMesh : None;
}

/** Returns TRUE if the Block was rendered this most recent frame. */
simulated final function bool Rendered()
{
	return (WorldInfo.TimeSeconds - LastRenderTime) < 0.25 ;
}

simulated event PostBeginPlay()
{
	local Vector ObstacleLocation;
	Super.PostBeginPlay();
	if(MeshComponent != None)
	{
		AttachComponent(MeshComponent);
		MaterialInstance = MeshComponent.CreateAndSetMaterialInstanceConstant(0);
	}
	if(bEnableNavMeshObstacleGeneration && Location.Z == 128 && Role == Role_Authority)
	{
		Obstacle = Spawn(class'DynamicNavMeshObstacle');
		ObstacleLocation = Location;
		ObstacleLocation.Z -= 128;
		Obstacle.SetLocation(ObstacleLocation);
		Obstacle.SetAsSquare(128);
		Obstacle.RegisterObstacle();
	}
	PurchasableComponent = None;
}

simulated event Destroyed()
{
	Super.Destroyed();
	if(Role == Role_Authority && Obstacle != None)
	{
		Obstacle.UnRegisterObstacle();
		Obstacle.Destroy();
	}
}

event Initialize(out IVector NewGridLocation, out IVector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI)
{
	GridLocation = NewGridLocation;
	ParentDirection = NewParentDirection;
	OwnerPRI = NewOwnerPRI;
//	SetOwner(OwnerPRI);
}

simulated function Vector GetLocation()
{
	if(OwnerPRI.Tower != None)
	{
		return OwnerPRI.Tower.GridLocationToVector(GridLocation);
	}
	else
	{
		return Vect(0,0,0);
	}
}

simulated function IVector GetGridLocation()
{
	return OwnerPRI.Tower.VectorToGridLocation(Location);
}

static function TowerPurchasableComponent GetPurchasableComponent(TowerBlock Archetype)
{
	return Archetype.PurchasableComponent;
}

final function TowerBlock GetParent()
{
	return TowerBlock(Base);
}

/** Calculates the GridLocation based on current Location. */
simulated final function UpdateGridLocation()
{
	GridLocation = GetGridLocation();
}

/** Convenience function for calling UpdateGridLocation() on our hierarchy without recursion.
If bStartFromRoot is TRUE, we start the calls at GetBaseMost() (if valid) instead of Self. */
simulated final function UpdateGridLocationIterative(bool bStartFromRoot)
{
	local array<TowerBlockStructural> BlockStack;
	local TowerBlockStructural ItrBlock;
	local TowerBlock CurrentBlock;
	local TowerBlockModule ModuleBlock;

	if(bStartFromRoot && (TowerBlockStructural(GetBaseMost()) != None || TowerBlockRoot(GetBaseMost()) != None))
	{
		CurrentBlock = TowerBlock(GetBaseMost());
	}
	else
	{
		CurrentBlock = Self;
	}

	`Push(BlockStack, None);

	while(CurrentBlock != None)
	{
		CurrentBlock.UpdateGridLocation();
		foreach CurrentBlock.BasedActors(class'TowerBlockStructural', ItrBlock)
		{
			`Push(BlockStack, ItrBlock);
		}
		foreach CurrentBlock.BasedActors(class'TowerBlockModule', ModuleBlock)
		{
			ModuleBlock.UpdateGridLocation();
		}
		CurrentBlock = `Pop(BlockStack);
	}
	`assert(BlockStack.Length == 0); 
}

/** Calculates the Location based on current GridLocation.
If bPreserveBase is FALSE, Base is guaranteed to be None on return. */
simulated final function UpdateLocation(optional bool bPreserveBase=true)
{
	local Vector NewLocation;
	local Actor TempBase;
	NewLocation = GetLocation();
	TempBase = Base;
	SetBase(None);
	SetLocation(NewLocation);
	if(bPreserveBase)
	{
		SetBase(TempBase);
	}
}

simulated final function UpdateLocationIterative(bool bStartFromRoot)
{
	local array<TowerBlockStructural> BlockStack;
	local TowerBlock CurrentBlock;
	local TowerBlockStructural ItrBlock;
			
	CurrentBlock = Self;
	`Push(BlockStack, None);

	while(CurrentBlock != None)
	{
		CurrentBlock.UpdateLocation();
		foreach CurrentBlock.BasedActors(class'TowerBlockStructural', ItrBlock)
		{
			`Push(BlockStack, ItrBlock);
		}
		CurrentBlock = `Pop(BlockStack);
	}
	`assert(BlockStack.Length == 0); 
}

simulated final function CalculateLocations()
{

}

simulated function CalculateBlockRotation()
{
	//@TODO - Use ParentDirection?
	local Rotator NewRotation;
	local TowerBlock TempBase;
	local IVector ParentDir;
	TempBase = TowerBlock(Base);
	if(TempBase != None)
	{
		ParentDir = FromVect(Normal(TempBase.Location - Location));
		if(ParentDir.Z == 0)
		{
			NewRotation.Pitch = ParentDir.X * (90 * DegToUnrRot);
			NewRotation.Roll = ParentDir.Y * (-90 * DegToUnrRot);
			NewRotation.Yaw = ParentDir.Z * (-90 * DegToUnrRot);
		}
		else if(ParentDir.Z == -1)
		{
//			NewRotation.Roll = -180 * DegToUnrRot;
		}
		else if(ParentDir.Z == 1)
		{
			NewRotation.Roll = 180 * DegToUnrRot;
		}
		else
		{
//			NewRotation = Block.Rotation;
		}
		SetBase(None);
		SetRotation(NewRotation);
		SetBase(TempBase);
	}
	else
	{
		`warn("Tried to CalculateBlockRotation of"@Self@"which has no parent! Role:"@Self.Role);
	}
}

final simulated function Highlight()
{
	MaterialInstance.SetVectorParameterValue('HighlightColor', 
		OwnerPRI != None ? OwnerPRI.HighlightColor : UnOwnedColor);
}

final simulated function UnHighlight()
{
	MaterialInstance.SetVectorParameterValue('HighlightColor', BlackColor);
}

final simulated function SetColor()
{

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
	Max(0, Damage);
	Super.TakeDamage(Damage, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	Health -= Damage;
//	`log(Self@"Took damage"@Damage@DamageType@DamageCauser@EventInstigator);
	if(Health <= 0)
	{
		Died(EventInstigator, DamageType, HitLocation);
	}
}

/** Called when this block reaches 0 health. Just tells the Tower to remove it.
Should be overridden in a subclass to add any effects and the Super version called to remove it. */
function Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	OwnerPRI.Tower.RemoveBlock(self);
}

protected static function TowerBlock GetSavedBlockArchetype(out int SavedModIndex, out int BlockIndex, 
	out const GlobalSaveInfo SaveInfo)
{
	return TowerGameReplicationInfo(class'WorldInfo'.static.GetWorldInfo().GRI).RootMod
		.GetModAtIndex(SavedModIndex).ModBlocks[BlockIndex];
}

auto simulated state Stable
{

};

/** Called on root blocks of an orphan branch that lost an orphan child. */
event LostOrphan();

/** Called on TowerBlocks that are the root node of an orphan branch. */
event OrphanedParent();

/** Called on TowerBlocks that are orphans but not the root node. */
event OrphanedChild();

event AdoptedParent();

event AdoptedChild();

event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
				const out CollisionImpactData RigidCollisionData, int ContactIndex )
{
	`log("IS THIS EVEN USED?! BLOCK IN COLLISION!"@HitComponent@OtherComponent);
}

DefaultProperties
{
	DisplayName="GIVE ME A NAME"
	bAddToBuildList=TRUE
	Health=100
	HealthMax=100

	BaseCost=10

	CustomTimeDilation=1

	BlackColor=(R=0,G=0,B=0,A=0)
	UnOwnedColor=(R=6,G=6,B=6,A=1)

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

	/*
	 // 256x256x256 cube.
	Begin Object Name=StaticMeshComponent0
		ScriptRigidBodyCollisionThreshold=999999
		BlockActors=true
		RBChannel=RBCC_GameplayPhysics
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE)
		bNotifyRigidBodyCollision=false
		BlockRigidBody=true
		BlockNonZeroExtent=true
	End Object
	*/
}