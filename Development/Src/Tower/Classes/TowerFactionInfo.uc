/**
TowerFactionInfo

Provides a common interface for each AI to deal with its faction's own infantry, missiles, etc.
*/
class TowerFactionInfo extends ActorComponent;

// This is all completely made-up pretty much and will be changed!

var() const editconst array<class<TowerKProjectile> > KProjectiles;

var() const editconst array<class<TowerEnemyPawn> > LightInfantry, MediumInfantry, HeavyInfantry;

var() const editconst array<class<TowerProjectile> > LightMissile, MediumMissile, HeavyMissile;

var() const editconst array<class<TowerVehicle> > GroundTransports;

