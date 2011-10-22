class TowerAttackProjectileComponent extends TowerAttackComponent;

var() const class<TowerProjectile> ProjectileClass;
var() const bool bLimitProjectileCount;
var() const int MaxProjectileCount<EditCondition=bLimitProjectileCount>;