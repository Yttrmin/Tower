/** 
TowerPlaceable

Interface for all classes that can be placed by the player.
Primarily implemented by TowerBlock and TowerModule so there doesn't need to be a set of functions for each. 
*/
interface TowerPlaceable
	//@deprecated
	dependson(TowerGame);

/**  */
event Initialize(out IVector NewGridLocation, out IVector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI);

// Placeable.CreatePlaceable(Placeable, Parent, NodeTree, SpawnLocation, GridLocation);
static function TowerPlaceable AttachPlaceable(TowerPlaceable PlaceableTemplate,
	TowerBlock Parent, out TowerTree NodeTree, out Vector SpawnLocation,
	out IVector NewGridLocation, optional TowerPlayerReplicationInfo OwnerTPRI);

static function RemovePlaceable(TowerPlaceable Placeable, out TowerTree NodeTree);

/** Called whenever a TowerTargetable of a type that this Placeable can attack touches the RadarVolume controlled
by a TowerBlockRoot. */
simulated function OnEnterRange(TowerTargetable Targetable);

/** Whether or not this TowerPlaceable is capable of normal replication, or we'll have to use the Ticket system.
Return TRUE for normal replication, FALSE for Ticket system. 
Mostly used for TowerModules, as they're ActorComponent-derived and can't be normally replicated. */
static function bool IsReplicable();

function StaticMesh GetPlaceableStaticMesh();

function MaterialInterface GetPlaceableMaterial(int Index);

simulated function IVector GetGridLocation();

simulated function Highlight();

simulated function UnHighlight();