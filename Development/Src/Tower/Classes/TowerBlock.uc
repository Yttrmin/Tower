/**
TowerBlock

Base class of all the blocks that make up a Tower. Blocks can be of different shapes and sizes, and have their own
features. Weapons are typically added on to blocks, rather than blocks coming already armed.
*/
class TowerBlock extends DynamicSMActor_Spawnable
	abstract;

/** Blocks that rely on this one for support. */
var array<TowerBlock> DependantBlocks;
/** Blocks that this one relies on for support. */
var array<TowerBlock> SupportBlocks;

/** Block's position on the grid. */
var Vector GridLocation;
var const editconst int XSize, YSize, ZSize;
var bool bRootBlock;

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
	Begin Object Name=StaticMeshComponent0
		BlockRigidBody=true
	    StaticMesh=StaticMesh'EngineMeshes.Cube'
	End Object
}