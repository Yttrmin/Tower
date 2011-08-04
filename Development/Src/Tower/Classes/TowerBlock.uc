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

//=========================================================
// Used in archetypes when creating new blocks.
/** User-friendly name. Used for things like the build menu. */
var() const Name DisplayName;
/** Description used when selected in the build menu. */
var() edittextbox const String Description;
/** If TRUE, this block will be in the player's build list. */
var() const bool bAddToBuildList;
/** Maximum health of this block, and what value the block will lerp to during construction. May be modified for difficulty. */
var() int HealthMax;
/** Cost for the player to construct this block. Modifiers are applied directly to this value in the archetype. */
var() int Cost;
//=========================================================

//=========================================================
// A*-related
var() int BaseCost;
var() int GoalCost, HeuristicCost, Fitness;
var TowerBlock AStarParent;
//=========================================================

var(InGame) int Health;

const DropRate = 128;

/** If FALSE, only StaticMeshComponents will be used with TowerBlocks. */
var private const globalconfig bool bEnableApexDestructibles;
var private const globalconfig bool bEnableNavMeshObstacleGeneration;

/** Unit vector pointing in direction of this block's parent.
Used in loading to allow TowerTree to reconstruct the hierarchy. Has no other purpose. */
var protectedwrite editconst IVector ParentDirection;
/** Block's position on the grid. */
var protectedwrite editconst IVector GridLocation;

var protected MaterialInstanceConstant MaterialInstance;
var protectedwrite TowerPlayerReplicationInfo OwnerPRI;

var private DynamicNavMeshObstacle Obstacle;

/** Used when saving/loading, set in the archetype by the game during runtime when the mod is loaded. */
var int ModIndex, ModBlockIndex;

replication
{
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

simulated event PostBeginPlay()
{
	local Vector ObstacleLocation;
	Super.PostBeginPlay();
	MaterialInstance = StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0);
	
	if(bEnableNavMeshObstacleGeneration && Location.Z == 128 && Role == Role_Authority)
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
	local LinearColor BlackColor;
	BlackColor = MakeLinearColor(0,0,0,0);
	MaterialInstance.SetVectorParameterValue('HighlightColor', BlackColor);
}

final simulated function SetColor()
{

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

};

simulated state InActive
{
};

/** Called on TowerBlocks that are the root node of an orphan branch. */
event OrphanedParent();

/** Called on TowerBlocks that are orphans but not the root node. */
event OrphanedChild();

event AdoptedParent();

event AdoptedChild();

event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
				const out CollisionImpactData RigidCollisionData, int ContactIndex )
{
	ScriptTrace();
	`log("IS THIS EVEN USED?!");
	`log("BLOCK IN COLLISION!"@HitComponent@OtherComponent);
	`assert(false);
}

DefaultProperties
{
	DisplayName="GIVE ME A NAME"
	bAddToBuildList=TRUE
	Health=100
	HealthMax=100

	BaseCost=10

	CustomTimeDilation=1

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