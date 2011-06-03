/**
TowerBlockAir

A special block with no physical presence in the world that matters but a GridLocation.
It exists on all non-occupied spots of a TowerBlock, and solely exists for A* searches.
It's also the only block that only exists on the server (as there's no AI on clients).
*/
class TowerBlockAir extends TowerBlock;

DefaultProperties
{
	DisplayName="Air" //@TODO - Make me "".
	bTickIsDisabled=true
	bCollideActors=false
	bCollideWorld=false
	Components.Remove(MyLightEnvironment)
	Components.Remove(StaticMeshComponent0)
	CollisionComponent=None
	bAddToBuildList=true //@TODO - Make me false
	RemoteRole=ROLE_None
	bProjTarget=false
}