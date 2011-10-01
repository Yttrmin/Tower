/**
TowerFactionInfo

Provides a common interface for each AI to deal with its faction's own infantry, missiles, etc.
*/
class TowerFactionInfo extends ActorComponent
	deprecated
	HideCategories(Object)
	AutoExpandCategories(TowerFactionInfo);

// This is all completely made-up pretty much and will be changed!

var() const array<class<TowerKProjectile> > KProjectiles;

var() const array<class<TowerEnemyPawn> > LightInfantry, MediumInfantry, HeavyInfantry;

var() const array<class<TowerProjectile> > LightMissile, MediumMissile, HeavyMissile;

var() const array<class<TowerVehicle> > GroundTransports;

