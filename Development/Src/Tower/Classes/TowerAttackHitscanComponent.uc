class TowerAttackHitscanComponent extends TowerAttackNonProjectileComponent;

/** If TRUE, shots can continue through a target (dealing damage to it), hit another target, and repeat
for up to MaxPenetrations times.
If FALSE, shots "stop" after hitting a single target. */
var() private const bool bShotsPenetrateTargets;
/** Maximum number of times a shot can penetrate. For example, if this is 1, the shot can hit a target, go through,
and then hit another target where it then "stops". 
0 means there's no limit. */
var() private const byte MaxPenetrations<EditCondition=bShotsPenetrateTargets>;

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

DefaultProperties
{
	MaxPenetrations=1
	bShotsPenetrateTargets=false
}