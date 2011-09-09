/**
TowerAIObjective

Used to mark a TowerBlock target for AI, and stores points where units should go to get a good shot at the target.
*/
class TowerAIObjective extends UDKGameObjective
	dependson(TowerGame);

/** Represents what you'll have to pull of to get to THIS objective!
So a OT_ClimbUp objective means you have to climb up to achieve it/get to THIS! */
enum ObjectiveType
{
	/** Not set. A fully initialized objective should NEVER be OT_NULL! */
	OT_NULL,
	OT_Destroy,
	OT_GoTo,
	OT_ClimbUp,
	OT_ClimbDown
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
		StaticMesh=StaticMesh'DebugMeshes.DebugRectangle'
	End Object
	Components.Add(MarkerMesh)
	DrawScale3D=(X=2,Y=2,Z=2)
	Mesh = MarkerMesh;

	Type=OT_NULL
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