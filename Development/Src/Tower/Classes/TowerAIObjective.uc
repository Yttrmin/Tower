/**
TowerAIObjective

Used to mark a TowerBlock target for AI, and stores points where units should go to get a good shot at the target.
*/
class TowerAIObjective extends UDKGameObjective;

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
var privatewrite StaticMeshComponent Mesh, TypeMesh;
var privatewrite int CompletionRadius;
var private Vector GoalPoint;
var private Vector ShootPoint;

/*final function TowerShootPoint GetShootPoint(FactionLocation Faction)
{
	return None;
}*/

function PostBeginPlay()
{
	Super.PostBeginPlay();
	GoalPoint = Location;
}

final function Vector GetGoalPoint()
{
	return Location;
}

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
	switch(Type)
	{
	case OT_GoTo:
		TypeMesh.SetStaticMesh(StaticMesh'NodeBuddies.NodeBuddy_PerchMantle');
		break;
	case OT_ClimbUp:
		TypeMesh.SetStaticMesh(StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_Climb');
		break;
	case OT_Destroy:
		TypeMesh.SetStaticMesh(StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_PopUp');
		break;
	default:
		TypeMesh.SetStaticMesh(StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_Enabled');
		break;
	}
}

final function SetNextObjective(TowerAIObjective NewNextObjective)
{
	NextObjective = NewNextObjective;
}

final function SetCompletionRadius(int NewCompletionRadius)
{
	CompletionRadius = NewCompletionRadius;
}

final function MoveToEdgeOfTarget(IVector Edge)
{
	local Vector NewLocation;
	NewLocation = Location;
	NewLocation += ToVect(Edge) * 128;
//	SetLocation(NewLocation);
	CompletionRadius = 256;
	GoalPoint += NewLocation;
	`log("MTEOT"@Edge.X@Edge.Y@Edge.Z);
}

//@TODO - Disable tick.
event Tick(float DeltaTime);

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	`log(Other@OtherComp);
	`assert(true);
}

event bool Completed(UDKSquadAI Formation)
{
	if(NextObjective != None)
	{
		Formation.SquadObjective = NextObjective;
		return true;
	}
	return false;
}

DefaultProperties
{
	bStatic=false
	bNoDelete=false
	bCollideActors=false
	bBlockActors=false
	bNoEncroachCheck=true

	CompletionRadius = 64

	Begin Object Class=StaticMeshComponent Name=MarkerMesh
		StaticMesh=StaticMesh'DebugMeshes.DebugRectangle'
		Scale3D=(X=0.5,Y=0.5,Z=0.5)
	End Object
	Components.Add(MarkerMesh)
	Begin Object Class=StaticMeshComponent Name=TypeMarkerMesh
		//StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_Climb'
			// OT_ClimbUp
		//StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_Enabled' // Circle crossed out. No backfacing.
		//StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_PopUp' // Bullseye with arrow.
			// OT_Destroy
		//StaticMesh'NodeBuddies.NodeBuddy_PerchMantle'
			// OT_GoTo
		Translation=(Z=-64)
	End Object
	Components.Add(TypeMarkerMesh)
	Mesh = MarkerMesh
	TypeMesh = TypeMarkerMesh

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