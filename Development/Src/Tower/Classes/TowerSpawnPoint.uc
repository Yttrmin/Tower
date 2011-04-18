class TowerSpawnPoint extends NavigationPoint
	placeable;

var() const bool bCanSpawnInfantry;
var() const bool bCanSpawnProjectile;
var() const bool bCanSpawnVehicle;

var() editconst FactionLocation Faction;

/** Number of units spawned here this round. */
var() editconst int InfantrySpawnedCount, ProjectileSpawnedCount, VehicleSpawnedCount;