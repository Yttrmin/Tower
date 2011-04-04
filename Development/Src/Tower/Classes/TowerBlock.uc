/**
TowerBlock

Base class of all the blocks that make up a Tower.

Keep in mind this class and its children will likely be opened up to modding!
*/
class TowerBlock extends DynamicSMActor_Spawnable /*Actor*/
	config(Tower)
	HideCategories(Movement,Attachment,Collision,Physics,Advanced,Object)
	AutoExpandCategories(TowerBlock)
	dependson(TowerModule, TowerGame)
	ClassGroup(Tower)
	implements(TowerPlaceable)
	placeable
	abstract;

//@TODO - Figure out how acceleration is calculated.
var const float ZAcceleration;
var const int DropRate;
var int BlocksFallen;
var int StartZ;

var repnotify bool bFalling;

/** If FALSE, only StaticMeshComponents will be used with TowerBlocks. */
var private const globalconfig bool bEnableApexDestructibles;

/** Unit vector pointing in direction of this block's parent.
Used in loading to allow TowerTree to reconstruct the hierarchy. Has no other purpose. */
var protectedwrite editconst IVector ParentDirection;
/** Block's position on the grid. */
var protectedwrite editconst IVector GridLocation;
var() const editconst int XSize, YSize, ZSize;
var protectedwrite deprecated bool bRootBlock;

var protected MaterialInstanceConstant MaterialInstance;
var const LinearColor Black;
var protectedwrite TowerPlayerReplicationInfo OwnerPRI;

var private DynamicNavMeshObstacle Obstacle;

/** Block's MeshComponent. Will be either StaticMeshComponent or ApexStaticDestructibleComponent. */
var private MeshComponent MeshComponent;

var int ModIndex, ModPlaceablesIndex;

/** User-friendly name. Used for things like the build menu. */
var() const String DisplayName;
var() const bool bAddToPlaceablesList;
var() const bool bUseApexDestructible;
var() const editconst editinline MeshComponent MeshComponents[2];

replication
{
	if(bNetDirty)
		bFalling;
	if(bNetInitial)
		GridLocation, OwnerPRI;
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
	Super.PostBeginPlay();
	MaterialInstance = StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0);
	//@FIXME - This can cause some huuuuuge performance drops. Disabled for now.
//	Obstacle = Spawn(class'NavMeshObstacle');
//	Obstacle.SetEnabled(TRUE);
}

static function TowerPlaceable AttachPlaceable(TowerPlaceable PlaceableTemplate,
	TowerBlock Parent, out TowerTree NodeTree, out Vector SpawnLocation,
	out IVector NewGridLocation, optional TowerPlayerReplicationInfo OwnerTPRI)
{
	local TowerPlaceable Block;
	local IVector ParentDir;
	if(Parent != None)
	{
		// Get PRI somewhere else since it might be none.
		Block = Parent.Spawn(TowerBlock(PlaceableTemplate).class, Parent,, SpawnLocation,,PlaceableTemplate,TRUE);
		ParentDir = FromVect(Normal(Parent.Location - SpawnLocation));
		Block.Initialize(NewGridLocation, ParentDir, Parent.OwnerPRI);
	}
	else
	{
		`assert(OwnerTPRI != None);
		Block = OwnerTPRI.Spawn(TowerBlock(PlaceableTemplate).class, Parent,, SpawnLocation,,PlaceableTemplate,TRUE);
		ParentDir = IVect(0,0,0);
		Block.Initialize(NewGridLocation, ParentDir, OwnerTPRI);
	}
	NodeTree.AddNode(Block, Parent);
	return Block;
}

static function RemovePlaceable(TowerPlaceable Placeable, out TowerTree NodeTree)
{
	NodeTree.RemoveNode(Placeable);
}

function StaticMesh GetPlaceableStaticMesh()
{
	return StaticMeshComponent.StaticMesh;
}

function MaterialInterface GetPlaceableMaterial(int Index)
{
	return StaticMeshComponent.GetMaterial(Index);
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
	InitializeMeshComponent();
//	SetOwner(OwnerPRI);
}

function InitializeMeshComponent()
{
	local MeshComponent NewMeshComponent;
	if(bEnableApexDestructibles && TowerBlock(ObjectArchetype).bUseApexDestructible)
	{
		NewMeshComponent = new class'ApexStaticDestructibleComponent' (MeshComponents[1]);
	}
	else
	{
		NewMeshComponent = new class'StaticMeshComponent' (MeshComponents[0]);
	}
	MeshComponent = NewMeshComponent;
	AttachComponent(MeshComponent);
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
	GridLocation.X = int(Location.X) / 256;
	GridLocation.Y = int(Location.Y) / 256;
	GridLocation.Z = int(Location.Z) / 256;
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

/** This would be extremely useful if not for collision issues between the PlayerController and TowerBlocks. */
reliable server function RemoveSelf()
{
	`log(Self@"Says to remove self!");
}

/** Blocks don't care about Targetables. */
simulated function OnEnterRange(TowerTargetable Targetable)
{

}

auto simulated state Stable
{
	function StopFall()
	{
		local Vector NewLocation;
		// Can't use SetLocation without breaking base.
		NewLocation = Location;
		NewLocation.X -= Base.Location.X;
		NewLocation.Y -= Base.Location.Y;
		NewLocation.Z = (StartZ - (256*BlocksFallen)) - Base.Location.Z ;
		SetRelativeLocation(NewLocation);
		SetGridLocation();
		ClearTimer('DroppedSpace');
	}

	event BeginState(name PreviousStateName)
	{
		if(PreviousStateName == 'Unstable')
		{
			bReplicateMovement = true;
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
		BlocksFallen++;
		// SetRelativeLocation here to be sure?
		//SetFullLocation(Location, false);
		SetGridLocation();
		if(!OwnerPRI.Tower.NodeTree.FindNewParent(Self))
		{
			SetTimer(TimeToDrop(), false, 'DroppedSpace');
		}
		else
		{
			`log("Found parent:"@Base);
			GotoState('Stable');
			bFalling = false;
		}
		// NEED TO CHANGE GRID LOCATION FOR CHILDREN TOO
		
	}
	event BeginState(name PreviousStateName)
	{
		bReplicateMovement = false;
		BlocksFallen = 0;
		StartZ = Location.Z;
		SetTimer(TimeToDrop(), false, 'DroppedSpace');
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
	function bool CanDrop()
	{
		return true;
	}
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

}

//@TODO - Convert from recursion to iteration!
event Adopted()
{
	local TowerBlock Node;
	`log("ADOPTED:"@Self);
	SetGridLocation();
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
	bAddToPlaceablesList=TRUE

	CustomTimeDilation=1

	ZAcceleration=1039.829009434
	DropRate=128
//	BlockFallTime=0.701704103 //0.496179729 //2.01539874//
	bCollideWorld=false
	bAlwaysRelevant = true
	bCollideActors=true
	bBlockActors=TRUE
	bRootBlock = false
	XSize = 0
	YSize = 0
	ZSize = 0

	Begin Object Class=TowerPlaceableStaticMeshComponent Name=TPSMC
	End Object
	Begin Object Class=TowerPlaceableDestructibleMeshComponent Name=TPDMC
	End Object
	MeshComponents(0)=TPSMC
	MeshComponents(1)=TPDMC

	Begin Object Name=MyLightEnvironment
		bEnabled=TRUE
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