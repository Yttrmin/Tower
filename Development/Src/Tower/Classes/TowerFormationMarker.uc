class TowerFormationMarker extends Actor;

DefaultProperties
{
	bStatic=false
	bNoDelete=false

	bCollideActors=false
	bCollideWorld=false
	CollisionType=COLLIDE_NoCollision

	/*
	Begin Object Class=StaticMeshComponent Name=MarkerMesh
		StaticMesh'DebugMeshes.DebugRectangle'
	End Object
	Components.Add(MarkerMesh)
	*/

	TickGroup=TG_DuringAsyncWork
}