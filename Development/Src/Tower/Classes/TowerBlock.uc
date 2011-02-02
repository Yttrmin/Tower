/**
TowerBlock

Base class of all the blocks that make up a Tower.

Keep in mind this class and its children will likely be opened up to modding!
*/
class TowerBlock extends DynamicSMActor_Spawnable
	placeable
	abstract;

// Modders: Don't modify either of these variables. Messing up the hierarchy has a tendency to lead
// to infinite loops or infinite recursion.
/** Reference to this block/node's parent. In the root and orphans this is None. */
var() editconst TowerBlock PreviousNode;
/** Holds references to all of this block/node's children.  */
var() editconst array<TowerBlock> NextNodes;

//@TODO - Figure out how acceleration is calculated.
var const float ZAcceleration;
var Vector StartFallLocation;
var int BlocksFallen, BlocksFalling;

/** Unit vector pointing in direction of this block's parent.
Used in loading to allow TowerTree to reconstruct the hierarchy. Has no other purpose. */
var() protectedwrite editconst Vector ParentDirection;
/** Block's position on the grid. */
var() protectedwrite editconst Vector GridLocation;
var const editconst int XSize, YSize, ZSize;
var protectedwrite bool bRootBlock;

var protected MaterialInstanceConstant MaterialInstance;
var const editconst LinearColor Black;
var protected TowerPlayerReplicationInfo OwnerPRI;

var protected NavMeshObstacle Obstacle;

replication
{
	if(bNetInitial)
		GridLocation, OwnerPRI;
}

auto state Stable
{
	function StopFall()
	{
		local Vector NewLocation;
		NewLocation = StartFallLocation;
		NewLocation.Z = StartFallLocation.Z - (256*BlocksFallen);
//		`log("Old Z:"@StartFallLocation.Z@"New Z:"@NewLocation.Z@"Blocks Fallen:"@BlocksFallen);
		SetPhysics(PHYS_None);
		SetLocation(NewLocation);
		SetCollision(true, true, true);
		BlocksFallen = 0;
		BlocksFalling = 0;
		ClearTimer('DroppedSpace');
	}

	event BeginState(name PreviousStateName)
	{
		if(PreviousStateName == 'Unstable')
		{
			StopFall();
		}
	}
}

state Unstable
{
	//@TODO - Experiment with Move() function.
	/** Called after block should have dropped 256 units.  */
	event DroppedSpace()
	{
		BlocksFallen++;
		BlocksFalling++;
		if(!OwnerPRI.Tower.NodeTree.FindNewParent(Self))
		{
			SetTimer(TimeToDrop(), false, 'DroppedSpace');
		}
	}
	event BeginState(name PreviousStateName)
	{
//		`log("Beginning Unstable state.");
		BlocksFalling = 1;
		BlocksFallen = 0;
		StartFallLocation = Location;
		SetPhysics(PHYS_Falling);
		SetCollision(true, false, true);
		SetTimer(TimeToDrop(), false, 'DroppedSpace');
	}
	function bool CanDrop()
	{
		return true;
	}
};

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	MaterialInstance = new(None) class'MaterialInstanceConstant';
	MaterialInstance.SetParent(StaticMeshComponent.GetMaterial(0));
	StaticMeshComponent.SetMaterial(0, MaterialInstance);
	//@FIXME - This can cause some huuuuuge performance drops. Disabled for now.
//	Obstacle = Spawn(class'NavMeshObstacle');
//	Obstacle.SetEnabled(TRUE);
}

function Initialize(Vector NewGridLocation, Vector NewParentDirection,
	TowerPlayerReplicationInfo NewOwnerPRI, bool bNewRootBlock)
{
	GridLocation = NewGridLocation;
	ParentDirection = NewParentDirection;
	OwnerPRI = NewOwnerPRI;
	bRootBlock = bNewRootBlock;
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

function float TimeToDrop()
{
	local float Time;
	//ScriptTrace();
	Time = sqrt(((512/(BlocksFalling+BlocksFallen))/ZAcceleration)/BlocksFalling);
	`log("TimeToDrop:"@Time);
	return Time;
}

//@TODO - Convert from recursion to iteration!
/** Called when this Block loses its support and there are no other blocks available to support it. */
event Orphaned()
{
	local TowerBlock Node;
	GotoState('Unstable');
	foreach NextNodes(Node)
	{
		Node.Orphaned();
	}
}

//@TODO - Convert from recursion to iteration!
event Adopted(optional int FallCount = -1)
{
	local TowerBlock Node;
	if(FallCount == -1)
	{
//		`log("I'm an orphan parent, tell my children to fall:"@BlocksFallen@"blocks.");
		FallCount = BlocksFallen;
	}
//	`log("Fallcount:"@FallCount);
	BlocksFallen = FallCount;
	// State change is immediate since we're in a state, make sure this is after
	// BlocksFallen's assignment.
	GotoState('Stable');
	foreach NextNodes(Node)
	{
		Node.Adopted(FallCount);
	}
}

event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
				const out CollisionImpactData RigidCollisionData, int ContactIndex )
{
	`log("BLOCK IN COLLISION!"@HitComponent@OtherComponent);
}

DefaultProperties
{
	ZAcceleration=1039.829009434
//	BlockFallTime=0.701704103 //0.496179729 //2.01539874//
	bCollideWorld=false
	bAlwaysRelevant = true
	bCollideActors=true
	bBlockActors=TRUE
	bRootBlock = false
	XSize = 0
	YSize = 0
	ZSize = 0
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
	End Object
}