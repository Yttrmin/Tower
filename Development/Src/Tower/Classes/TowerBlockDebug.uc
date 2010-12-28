/**
TowerBlockDebug

Classic requirement for any game I make. At this point its a functionless, materialless, 256x256x256 cube.
*/
class TowerBlockDebug extends TowerBlock;

var MaterialInstanceConstant MaterialInstance;

event PostBeginPlay()
{
	Super.PostBeginPlay();
}

DefaultProperties
{
	XSize = 256
	YSize = 256
	ZSize = 256
	Begin Object Name=StaticMeshComponent0
	    StaticMesh=StaticMesh'TowerBlocks.DebugBlock'
		//Materials(0)=Material'TowerDebugBlocks.DebugBlockMaterial'
	End Object
	CollisionComponent=StaticMeshComponent0
}