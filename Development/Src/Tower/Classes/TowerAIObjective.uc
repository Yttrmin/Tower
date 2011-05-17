/**
TowerAIObjective

Used to mark a TowerPlaceable target for AI, and stores points where units should go to get a good shot at the target.
*/
class TowerAIObjective extends UDKGameObjective
	dependson(TowerGame);

var privatewrite TowerPlaceable Target;

final function TowerShootPoint GetShootPoint(FactionLocation Faction)
{
	return None;
}

// Convenience function to work around some potential bug with interface casting.
final function Actor GetTargetActor()
{
	return Actor(Target);
}

final function SetTarget(TowerPlaceable NewTarget)
{
	Target = NewTarget;
}

DefaultProperties
{
	bStatic=false
	bNoDelete=false

	Begin Object Class=StaticMeshComponent Name=MarkerMesh
		StaticMesh=StaticMesh'NodeBuddies.3D_Icons.NodeBuddy__BASE_SHORT'
	End Object
	Components.Add(MarkerMesh)
}