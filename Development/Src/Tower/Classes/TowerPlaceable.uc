/** 
TowerPlaceable

Interface for all classes that can be placed by the player.
Primarily implemented by TowerBlock and TowerModule so there doesn't need to be a set of functions for each. 
*/
interface TowerPlaceable;

function StaticMesh GetPlaceableStaticMesh();

function MaterialInterface GetPlaceableMaterial(int Index);

simulated function Vector GetGridLocation();

simulated function Highlight();

simulated function UnHighlight();

// Placeable.CreatePlaceable(Placeable, Parent, NodeTree, SpawnLocation, GridLocation);
static function TowerPlaceable AttachPlaceable(TowerPlaceable PlaceableTemplate,
	TowerBlock Parent, out TowerTree NodeTree, out Vector SpawnLocation,
	out Vector NewGridLocation, optional TowerPlayerReplicationInfo OwnerTPRI);

static function RemovePlaceable(TowerPlaceable Placeable, out TowerTree NodeTree);

reliable server function RemoveSelf();

/** Whether or not this TowerPlaceable is capable of normal replication, or we'll have to use the Ticket system.
Return TRUE for normal replication, FALSE for Ticket system. 
Mostly used for TowerModules, as they're ActorComponent-derived and can't be normally replicated. */
static function bool IsReplicable();

/**  */
event Initialize(out Vector NewGridLocation, out Vector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI);