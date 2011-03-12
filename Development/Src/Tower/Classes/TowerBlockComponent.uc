/** 
TowerBlockComponent

Potential class for exploiting Component's speed versus Actor's. Instead of having every block be Actor-derived, they may
instead be TowerBlockComponents attached to a TowerBlock, such as the root. In the case of needing to make a block fall, the root
block of that branch would be made into a TowerBlock, and its children would be attached to it. 
We'll see how this plays out in the future! 
*/
class TowerBlockComponent extends ActorComponent
	implements(TowerPlaceable);

var Vector GridLocation, ParentDirection;

/**  */
event Initialize(out Vector NewGridLocation, out Vector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI);

// Placeable.CreatePlaceable(Placeable, Parent, NodeTree, SpawnLocation, GridLocation);
static function TowerPlaceable AttachPlaceable(TowerPlaceable PlaceableTemplate,
	TowerBlock Parent, out TowerTree NodeTree, out Vector SpawnLocation,
	out Vector NewGridLocation, optional TowerPlayerReplicationInfo OwnerTPRI);

static function RemovePlaceable(TowerPlaceable Placeable, out TowerTree NodeTree);

/** Called whenever a TowerTargetable of a type that this Placeable can attack touches the RadarVolume controlled
by a TowerBlockRoot. */
simulated function OnEnterRange(TowerTargetable Targetable);

/** Whether or not this TowerPlaceable is capable of normal replication, or we'll have to use the Ticket system.
Return TRUE for normal replication, FALSE for Ticket system. 
Mostly used for TowerModules, as they're ActorComponent-derived and can't be normally replicated. */
static function bool IsReplicable()
{
	return FALSE;
}

function StaticMesh GetPlaceableStaticMesh();

function MaterialInterface GetPlaceableMaterial(int Index);

simulated function Vector GetGridLocation()
{
	return GridLocation;
}

simulated function Highlight();

simulated function UnHighlight();