/**
TowerBlock

Base class of all the blocks that make up a Tower. Blocks can be of different shapes and sizes, and have their own
features. Weapons are typically added on to blocks, rather than blocks coming already armed.
*/
class TowerBlock extends DynamicSMActor_Spawnable
	abstract;

/** Block's position on the grid. */
var Vector GridLocation;
var const editconst int XSize, YSize, ZSize;
var bool bRootBlock;

DefaultProperties
{
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
	    StaticMesh=StaticMesh'EngineMeshes.Cube'
	End Object
}