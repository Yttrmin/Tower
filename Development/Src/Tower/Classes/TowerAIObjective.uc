/**
TowerAIObjective

Used to mark a TowerBlock target for AI, and stores points where units should go to get a good shot at the target.
*/
class TowerAIObjective extends UDKGameObjective
	dependson(TowerGame);

enum ObjectiveType
{
	OT_NULL,
	OT_Destroy,
	OT_GoTo
};

var privatewrite TowerBlock Target;
var privatewrite TowerAIObjective NextObjective;
var privatewrite ObjectiveType Type;
var privatewrite StaticMeshComponent Mesh;

/*final function TowerShootPoint GetShootPoint(FactionLocation Faction)
{
	return None;
}*/

// Convenience function to work around some potential bug with interface casting.
final function Actor GetTargetActor()
{
	return Target;
}

final function SetTarget(TowerBlock NewTarget)
{
	Target = NewTarget;
}

final function SetType(ObjectiveType NewType)
{
	Type = NewType;
}

final function SetNextObjective(TowerAIObjective NewNextObjective)
{
	NextObjective = NewNextObjective;
}

DefaultProperties
{
	bStatic=false
	bNoDelete=false
	bCollideActors=false
	bBlockActors=false

	Begin Object Class=StaticMeshComponent Name=MarkerMesh
		StaticMesh=StaticMesh'NodeBuddies.3D_Icons.NodeBuddy__BASE_SHORT'
	End Object
	Components.Add(MarkerMesh)
	DrawScale3D=(X=2,Y=2,Z=2)
	Mesh = MarkerMesh;
	//Material'NodeBuddies.Materials.NodeBuddy_Brown1'
	// light pink
	//Material'NodeBuddies.Materials.NodeBuddy_Text1'
	// green
	//Material'EditorMaterials.WidgetMaterial_Y'
	// blue
	//Material'EditorMaterials.WidgetMaterial_Z'
	// yellow
	//Material'EditorMaterials.WidgetMaterial_Current'
}