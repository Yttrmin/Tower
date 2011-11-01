class TowerAttackHitscanComponent extends TowerAttackComponent;

var() private const float Damage;
var() private const float DamageRadius;
var() private const float MomentumTransfer;
var() private const class<TowerDamageType> DamageType;

// Used in HasLineOfSight so we can save doing an extra trace when we actually shoot. Overwritten every call.
var private Vector CachedHitLoc, CachedHitNorm;

protected function Attack(TowerTargetable Targetable)
{
	if(ValidTarget(Targetable))
	{
		Super.Attack(Targetable);
	}
}

private final function bool ValidTarget(TowerTargetable Targetable)
{
	return HasLineOfSight(Actor(Targetable));
}

private final function bool HasLineOfSight(Actor Actor)
{
	return Trace(CachedHitLoc, CachedHitNorm, Actor.Location, Location, true) == Actor;
}

private final function Shoot(TowerTargetable Targetable)
{
	local Vector Momentum;
	Targetable.TakeDamage(Damage, None, CachedHitLoc, Momentum, DamageType,, Outer);
}