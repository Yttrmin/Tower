class TowerModule extends StaticMeshComponent // This will be SkeletalMeshComponent in the future.
	HideCategories(Object)
	implements(TowerPlaceable)
	ClassGroup(Tower)
	abstract;

struct ModuleInfo
{
	var String DisplayName;
	var class<TowerModule> BaseClass;
};

/** User-friendly name. Used for things like the build menu. */
var() const String DisplayName;
var() const bool bAddToPlaceablesList;

var Vector GridLocation, ParentDirection;

event Initialize(out Vector NewGridLocation, out Vector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI)
{
	GridLocation = NewGridLocation;
	ParentDirection = NewParentDirection;
}

static function TowerPlaceable AttachPlaceable(TowerPlaceable PlaceableTemplate,
	TowerBlock Parent, out TowerTree NodeTree, out Vector SpawnLocation,
	out Vector NewGridLocation, optional TowerPlayerReplicationInfo OwnerTPRI)
{
	local TowerModule Module;
	local Vector NewParentDirection, NewTranslation;
	local Rotator NewRotation;
	`assert(Parent != None);
	NewParentDirection = Normal(SpawnLocation - Parent.Location);
	Module = new(None) PlaceableTemplate.class (PlaceableTemplate);
	if(round(NewParentDirection.Z) == 0)
	{
		NewRotation.Pitch = NewParentDirection.X * (-90 * DegToUnrRot);
		NewRotation.Roll = NewParentDirection.Y * (90 * DegToUnrRot);
		NewRotation.Yaw = NewParentDirection.Z * (90 * DegToUnrRot);
	}
	else if(round(NewParentDirection.Z) == -1)
	{
		NewRotation.Roll = 180 * DegToUnrRot;
	}
	else
	{
		NewRotation = Module.Rotation;
	}
	NewTranslation.X = NewParentDirection.X*128;
	NewTranslation.Y = NewParentDirection.Y*128;
	NewTranslation.Z = NewParentDirection.Z*128;
	Module.SetTranslation(NewTranslation);
	Module.SetRotation(NewRotation);
	Module.Initialize(NewGridLocation, NewParentDirection, Parent.OwnerPRI);
	Parent.AttachComponent(Module);
	return Module;
}

function StaticMesh GetPlaceableStaticMesh()
{
	return StaticMesh;
}

function MaterialInterface GetPlaceableMaterial(int Index)
{
	return GetMaterial(Index);
}

DefaultProperties
{
	DisplayName="GIVE ME A NAME"
	bAddToPlaceablesList=TRUE
}