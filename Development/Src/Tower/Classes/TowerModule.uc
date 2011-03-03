class TowerModule extends StaticMeshComponent // This will be SkeletalMeshComponent in the future.
	HideCategories(Object)
	implements(TowerPlaceable)
	ClassGroup(Tower)
	abstract;

struct PriorityTarget
{
	var() const editconst name TargetType;
	var() byte Priority;
};

/** User-friendly name. Used for things like the build menu. */
var() const String DisplayName;
var() const bool bAddToPlaceablesList;

var() const PriorityTarget PrioritizedTargets[3]<FullyExpand=true>;

var() editconst int ID;

var Vector GridLocation, ParentDirection;

event Initialize(out Vector NewGridLocation, out Vector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI)
{
	`log("MODULE INITIALIZE");
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
//	`log("NewRotation:"@NewRotation);
	NewTranslation.X = NewParentDirection.X*128;
	NewTranslation.Y = NewParentDirection.Y*128;
	NewTranslation.Z = NewParentDirection.Z*128;
	Module.SetTranslation(NewTranslation);
	Module.SetRotation(NewRotation);
	Module.Initialize(NewGridLocation, NewParentDirection, Parent.OwnerPRI);
	Parent.AttachComponent(Module);
	return Module;
}

static function RemovePlaceable(TowerPlaceable Placeable, out TowerTree NodeTree)
{
	ActorComponent(Placeable).Owner.DetachComponent(ActorComponent(Placeable));
}

static final function bool IsReplicable()
{
	return FALSE;
}

simulated function Vector GetGridLocation()
{
	return GridLocation;
}

function StaticMesh GetPlaceableStaticMesh()
{
	return StaticMesh;
}

function MaterialInterface GetPlaceableMaterial(int Index)
{
	return GetMaterial(Index);
}

final simulated function Highlight()
{
//	MaterialInstance.SetVectorParameterValue('HighlightColor', 
//		OwnerPRI.HighlightColor);
}

final simulated function UnHighlight()
{
//	MaterialInstance.SetVectorParameterValue('HighlightColor', Black);
}

reliable server function RemoveSelf()
{
	`log(Self@"Says to remove self!");
}

DefaultProperties
{
	DisplayName="GIVE ME A NAME"
	bAddToPlaceablesList=TRUE
	PrioritizedTargets(0)=(TargetType=Infantry,Priority=0)
	PrioritizedTargets(1)=(TargetType=Vehicle,Priority=0)
	PrioritizedTargets(2)=(TargetType=Projectile,Priority=0)

	CollideActors=TRUE
	BlockActors=True
	BlockZeroExtent=TRUE
	BlockNonZeroExtent=TRUE
	BlockRigidBody=TRUE
	AlwaysCheckCollision=TRUE
}