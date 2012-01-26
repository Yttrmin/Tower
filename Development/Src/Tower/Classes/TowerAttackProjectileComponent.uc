class TowerAttackProjectileComponent extends TowerAttackComponent;

var() const class<TowerProjectile> ProjectileClass;
var() const bool bLimitProjectileCount;
var() const int MaxProjectileCount<EditCondition=bLimitProjectileCount>;
/** If TRUE, projectiles are initialized in the direction that StartFireSocketName is rotated in.
Else, projectiles are always shot towards its target with no regard for socket rotation. */
var() const bool bOnlyFireAlongSocketRotation;

protected function Attack(TowerTargetable Targetable)
{
	ProjectileFire().Init(GetAimDirection(Targetable));
}

private function TowerProjectile ProjectileFire()
{
//	local Vector FireDirection;
	local Vector FireLocation;
	local TowerProjectile Projectile;

	Projectile = Spawn(ProjectileClass, Owner,,FireLocation);
	/*
	GetAimDirection(
	if(Projectile != None && !Projectile.bDeleteMe)
	{
		Projectile.Init(FireDirection);
	}
	*/
	return Projectile;
}

protected function Vector GetAimDirection(TowerTargetable Target)
{
	local Vector Direction;
	//@TODO - Cache if multiple shots per attack?
	local Vector SocketLocation;
	local Rotator SocketRotation;
	`assert(SkeletalMeshComponent(MeshComponent).
		GetSocketWorldLocationAndRotation(StartFireSocket, SocketLocation, SocketRotation));
	if(bOnlyFireAlongSocketRotation)
	{
		Direction = Vector(SocketRotation);
	}
	else
	{
		return Super.GetAimDirection(Target);
	}
	return Direction;
}