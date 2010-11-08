/**
TowerBlock

Base class of all the blocks that make up a Tower. Blocks can be of different shapes and sizes, and have their own
features. Weapons are typically added on to blocks, rather than blocks coming already armed.
*/
class TowerBlock extends DynamicSMActor
	abstract;

DefaultProperties
{
	 // 256x256x256 cube.
	Begin Object Name=StaticMeshComponent0
	    StaticMesh=StaticMesh'EngineMeshes.Cube'
	End Object
}