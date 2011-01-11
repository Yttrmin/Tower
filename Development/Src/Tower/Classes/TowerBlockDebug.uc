/**
TowerBlockDebug

Classic requirement for any game I make. At this point its a functionless, materialless, 256x256x256 cube.
*/
class TowerBlockDebug extends TowerBlock;

DefaultProperties
{
	XSize = 256
	YSize = 256
	ZSize = 256
	Begin Object Name=StaticMeshComponent0
		CollideActors=True
		BlockActors=true
	    StaticMesh=StaticMesh'TowerBlocks.DebugBlock'
		Materials(0)=Material'TowerBlocks.DebugBlockMaterial'
	End Object
	CollisionComponent=StaticMeshComponent0
}