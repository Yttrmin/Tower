class TowerSpawnPoint extends NavigationPoint
	placeable;

var() const bool bCanSpawnInfantry;
var() const bool bCanSpawnProjectile;
var() const bool bCanSpawnVehicle;

var(InGame) editconst FactionLocation Faction;

/** Number of units spawned here this round. */
var(InGame) editconst int InfantrySpawnedCount, ProjectileSpawnedCount, VehicleSpawnedCount;