class TowerAIObjective extends UDKGameObjective
	dependson(TowerGame);

var TowerPlaceable Target;

function TowerShootPoint GetShootPoint(FactionLocation Faction)
{
	return None;
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