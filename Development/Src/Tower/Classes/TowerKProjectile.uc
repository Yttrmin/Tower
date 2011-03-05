/**
TowerKProjectile

Base class for any sort of projectiles that are affected by physics (e.g. cannonball, rocks, etc).
*/
class TowerKProjectile extends KActorSpawnable
	implements(TowerTargetable)
	abstract;

function bool IsProjectile()
{
	return TRUE;
}

function bool IsVehicle()
{
	return FALSE;
}

function bool IsInfantry()
{
	return FALSE;
}

function Launch(Vector Direction)
{
	local Vector LaunchVector;
	LaunchVector = Vect(0,0,0)-Location;
	LaunchVector.Z = 1;
	Initialize();
	ApplyImpulse(LaunchVector, 1000, Vect(0,0,0));
}

/** Called from RigidBodyCollision() on impact with a TowerBlock. */
event ImpactedBlock(TowerBlock Block, const out CollisionImpactData RigidCollisionData)
{
	`log("PROJECTILE IMPACTED BLOCK!"@Block);
	Block.Destroy();
	Destroy();
}

event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
				const out CollisionImpactData RigidCollisionData, int ContactIndex )
{
//	`log("PROJECTILE IN COLLISION!"@OtherComponent.Owner);
	if(TowerBlock(OtherComponent.Owner) != None)
	{
		ImpactedBlock(TowerBlock(OtherComponent.Owner), RigidCollisionData);
	}
}

DefaultProperties
{
	LifeSpan=1500
	bCollideActors=TRUE
	bCollideWorld=false
	bBlockActors=TRUE
	BlockRigidBody=TRUE
	bCollideComplex=false
	Begin Object Name=StaticMeshComponent0
		ScriptRigidBodyCollisionThreshold=250
		BlockRigidBody=true
		BlockActors=true
		bNotifyRigidBodyCollision=TRUE
	End Object
	bWakeOnLevelStart=true
}