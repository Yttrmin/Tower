class TowerRangeGlobalComponent extends TowerRangeComponent;

var() private const bool bUsesProjectile;
var() private const class<TowerProjectile> ProjectileClass<EditCondition=bUsesProjectile>;
var() private const class<TowerDamageType> DamageTypeClass; 