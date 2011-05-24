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
		StaticMesh=StaticMesh'NodeBuddies.3D_Icons.NodeBuddy__BASE_SHORT'
	End Object
	Components.Add(MarkerMesh)
	*/

	TickGroup=TG_DuringAsyncWork
}