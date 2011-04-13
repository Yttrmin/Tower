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
/** If FALSE, this Placeable will not be accessible to the player for placing in the world. */
var() const bool bAddToPlaceablesList;

var() const PriorityTarget PrioritizedTargets[3]<FullyExpand=true>;

var TowerTargetable Target;

var const float ThinkRate;
var IVector GridLocation, ParentDirection;

event Initialize(out IVector NewGridLocation, out IVector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI)
{
	`log("MODULE INITIALIZE");
	GridLocation = NewGridLocation;
	ParentDirection = NewParentDirection;
	TowerBlock(Owner).OwnerPRI.Tower.Root.AddRangeNotifyCallback(OnEnterRange, 
		PrioritizedTargets[0].Priority > 0 ? true : false, 
		PrioritizedTargets[2].Priority > 0 ? true : false, 
		PrioritizedTargets[1].Priority > 0 ? true : false );
	Owner.SetTimer(ThinkRate, true, 'Think', Self);
}

static function TowerPlaceable AttachPlaceable(TowerPlaceable PlaceableTemplate,
	TowerBlock Parent, out TowerTree NodeTree, out Vector SpawnLocation,
	out IVector NewGridLocation, optional TowerPlayerReplicationInfo OwnerTPRI)
{
	local TowerModule Module;
	local IVector NewParentDirection;
	local Vector NewTranslation;
	local Rotator NewRotation;
	`assert(Parent != None);
	NewParentDirection = FromVect(Normal(SpawnLocation - Parent.Location));
	//@FIXME - Fixed?
	Module = new(None) TowerModule(PlaceableTemplate).class (PlaceableTemplate);
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
	Parent.AttachComponent(Module);
	Module.Initialize(NewGridLocation, NewParentDirection, Parent.OwnerPRI);
	return Module;
}

static function RemovePlaceable(TowerPlaceable Placeable, out TowerTree NodeTree)
{
	ActorComponent(Placeable).Owner.ClearTimer('Think', Placeable);

	ActorComponent(Placeable).Owner.DetachComponent(ActorComponent(Placeable));
}

static final function bool IsReplicable()
{
	return FALSE;
}

simulated function IVector GetGridLocation()
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

/** This would be extremely useful if not for collision issues between the PlayerController and TowerBlocks. */
reliable server function RemoveSelf()
{
	`log(Self@"Says to remove self!");
}

simulated function OnEnterRange(TowerTargetable Targetable)
{
	`log("Targetable in range!"@Targetable);
	if(Target == None)
	{
		SetTarget(Targetable);
	}
	else
	{
		// Priority and stuff to decide if we want to switch targets!
	}
}

function SetTarget(TowerTargetable NewTarget)
{
	`log(Self@"setting new target! From"@Target@"to"@NewTarget$"!");
	Target = NewTarget;
	Think();
}

event Think()
{
	`log("Think");
}

DefaultProperties
{
	DisplayName="GIVE ME A NAME"
	bAddToPlaceablesList=TRUE
	ThinkRate=2.0
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