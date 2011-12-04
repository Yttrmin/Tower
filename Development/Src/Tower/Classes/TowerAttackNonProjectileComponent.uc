/**
TowerAttackNonProjectileComponent

Maybe the dumbest class name ever.
Basically projectiles hold their damage amount, damage type, and such in them. With anything but projectiles,
you have to define the damage some other way. This holds those damage properties so we don't have to copy
and paste blocks of variables for every non-projectile class.
*/
class TowerAttackNonProjectileComponent extends TowerAttackComponent
	abstract;

var() protected const int Damage;
var() protected const float DamageRadius;
var() protected const float MomentumTransfer;
var() protected const class<TowerDamageType> DamageType;