/** 
Tower Placeable

Interface for all classes that can be placed by the player.
Primarily implemented by TowerBlock and TowerModule so there doesn't need to be a set of functions for each. 
*/
interface TowerPlaceable;

function StaticMesh GetPlaceableStaticMesh();

function MaterialInterface GetPlaceableMaterial(int Index);

// Placeable.CreatePlaceable(Placeable, Parent, NodeTree, SpawnLocation, GridLocation);
static function TowerPlaceable AttachPlaceable(TowerPlaceable PlaceableTemplate,
	TowerBlock Parent, out TowerTree NodeTree, out Vector SpawnLocation,
	out Vector NewGridLocation, optional TowerPlayerReplicationInfo OwnerTPRI);

/**  */
event Initialize(out Vector NewGridLocation, out Vector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI);