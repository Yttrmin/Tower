/**
TowerBlock

Base class of all the blocks that make up a Tower.

Keep in mind this class and its children will likely be opened up to modding!
*/
class TowerBlock extends DynamicSMActor_Spawnable
	abstract;

/** Blocks that rely on this one for support. */
var() array<TowerBlock> DependantBlocks;
/** Blocks that this one relies on for support. */
var() array<TowerBlock> SupportBlocks;

/** Block's position on the grid. */
var() editconst Vector GridLocation;
var const editconst int XSize, YSize, ZSize;
var bool bRootBlock;

var MaterialInstanceConstant MaterialInstance;
var const editconst LinearColor Black;
var TowerPlayerReplicationInfo OwnerPRI;

var NavMeshObstacle Obstacle;

replication
{
	if(bNetInitial)
		GridLocation, OwnerPRI;
}

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

simulated function Highlight()
{
	MaterialInstance.SetVectorParameterValue('HighlightColor', 
		OwnerPRI.HighlightColor);
}

simulated function UnHighlight()
{
	MaterialInstance.SetVectorParameterValue('HighlightColor', Black);
}

simulated function SetColor()
{

}

/** Called by support block when it no longer supports */
event SupportRemoved(TowerBlock Support)
{
	local TowerBlock Block;
	SupportBlocks.RemoveItem(Support);
	// If true, this block was our only support.
	if(SupportBlocks.Length <= 0)
	{
		foreach DependantBlocks(Block)
		{
			Block.SupportRemoved(self);
		}
		Drop();
	}
}

event Destroyed()
{
	local TowerBlock Block;
	foreach DependantBlocks(Block)
	{
		Block.SupportRemoved(self);
	}
}

function Drop()
{
	local Vector NewLocation;
	NewLocation = Location;
	NewLocation.Z -= 256;
	SetLocation(NewLocation);
}

DefaultProperties
{
	bAlwaysRelevant = true;
	bCollideActors=true
	bBlockActors=true
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
	/**
	Begin Object Name=StaticMeshComponent0
		BlockRigidBody=true
	    StaticMesh=StaticMesh'EngineMeshes.Cube'
		Materials(0)=Material'TowerDebugBlocks.DebugBlockMaterial'
	End Object
	*/
}