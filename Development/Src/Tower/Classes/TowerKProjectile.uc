/**
TowerKProjectile

Base class for any sort of projectiles that are affected by physics (e.g. cannonball, rocks, etc).
*/
class TowerKProjectile extends KActorSpawnable
	abstract;

function Launch(Vector Direction)
{
	local Vector LaunchVector;
	LaunchVector = Vect(0,0,0)-Location;
	LaunchVector.Z = 0.75;
	Initialize();
	ApplyImpulse(LaunchVector, 50000, Vect(0,0,0));
}

/** Called from RigidBodyCollision() on impact with a TowerBlock. */
event ImpactedBlock(TowerBlock Block, const out CollisionImpactData RigidCollisionData)
{
	`log("PROJECTILE IMPACTED BLOCK!"@Block);
	Destroy();
}

event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
				const out CollisionImpactData RigidCollisionData, int ContactIndex )
{
	`log("PROJECTILE IN COLLISION!"@OtherComponent.Owner);
	if(TowerBlock(OtherComponent.Owner) != None)
	{
		ImpactedBlock(TowerBlock(OtherComponent.Owner), RigidCollisionData);
	}
}

DefaultProperties
{
	bCollideActors=TRUE
	bCollideWorld=false
	bBlockActors=TRUE
	BlockRigidBody=TRUE
	bCollideComplex=false
	Begin Object Name=StaticMeshComponent0
		ScriptRigidBodyCollisionThreshold=500
		BlockRigidBody=true
		BlockActors=true
		bNotifyRigidBodyCollision=TRUE
	End Object
	bWakeOnLevelStart=true
}