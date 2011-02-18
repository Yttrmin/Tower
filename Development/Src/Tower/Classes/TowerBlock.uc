/**
TowerBlock

Base class of all the blocks that make up a Tower.

Keep in mind this class and its children will likely be opened up to modding!
*/
class TowerBlock extends DynamicSMActor_Spawnable
	placeable
	abstract;

struct BlockInfo
{
	var string DisplayName;
	var class<TowerBlock> BaseClass;
	var StaticMesh BlockMesh;
	var Material BlockMaterial;
	// Used for saving/loading.
	var int ModIndex, ModBlockInfoIndex;
};

//@TODO - Figure out how acceleration is calculated.
var const float ZAcceleration;
var const int DropRate;
var int BlocksFallen;
var int StartZ;

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

var int ModIndex, ModBlockInfoIndex;

/** User-friendly name. Used for things like the build menu. */
var String DisplayName;

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
			StopFall();
		}
	}
}

/** State for root blocks of orphan branches. Block falls with all its attachments. */
state Unstable
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
		}
		// NEED TO CHANGE GRID LOCATION FOR CHILDREN TOO
		
	}
	event BeginState(name PreviousStateName)
	{
		`log(Self@"I AM NOW UNSTABLE!!!!!!");
		BlocksFallen = 0;
		StartZ = Location.Z;
		SetTimer(TimeToDrop(), false, 'DroppedSpace');
	}
	event Tick(float DeltaTime)
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

function Initialize(out BlockInfo Info, Vector NewGridLocation, Vector NewParentDirection,
	TowerPlayerReplicationInfo NewOwnerPRI, bool bNewRootBlock)
{
	if(Info.BlockMesh != None)
	{
		StaticMeshComponent.SetStaticMesh(Info.BlockMesh);
	}
	//@TODO - Can't have highlighting if we replace the material like this.
	if(Info.BlockMaterial != None)
	{
		StaticMeshComponent.SetMaterial(0, Info.BlockMaterial);
	}
	if(Info.DisplayName != "")
	{
		DisplayName = Info.DisplayName;
	}
	ModIndex = Info.ModIndex;
	ModBlockInfoIndex = Info.ModBlockInfoIndex;
	`log("added"@ModIndex@ModBlockInfoIndex);
	GridLocation = NewGridLocation;
	ParentDirection = NewParentDirection;
	OwnerPRI = NewOwnerPRI;
	bRootBlock = bNewRootBlock;
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
	GotoState('Unstable');
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