class TowerCrowdDestinationSpawnable extends GameCrowdDestination;

/** Typically a TowerBlock or TowerModule that agents going here should attack. */
var Actor Target;

//var IVector GridLocation;

DefaultProperties
{
	bStatic=false
	bNoDelete=false
}