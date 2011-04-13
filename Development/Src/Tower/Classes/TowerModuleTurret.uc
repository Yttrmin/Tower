class TowerModuleTurret extends TowerModule
	placeable;

//var StaticMeshComponent StaticMeshComponent;
//var SkeletalMeshComponent SkeletalMeshComponent;

var SkelControlLookAt Barrel;

function Vector CalculateShootVector(Actor ShotTarget)
{
	local vector Origin;
	Origin = Translation;
	Origin.Z += 128;
	return Normal(ShotTarget.Location - Origin);
}

/** called after initializing the AnimTree for the given SkeletalMeshComponent that has this Actor as its Owner
 * this is a good place to cache references to skeletal controllers, etc that the Actor modifies
 */
event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	`log("PostInitAnimTree!");
}

function Shoot(Vector Direction)
{
	local vector HitLocation, HitNormal;
	local vector ShotOrigin;
	local Actor HitActor;

	ShotOrigin = Translation;
	ShotOrigin.Z += 128;
	HitActor = Owner.Trace(HitLocation, HitNormal, ShotOrigin+Direction*10000, ShotOrigin, true);
	
	Owner.DrawDebugLine(ShotOrigin, ShotOrigin+Direction*10000, 1, 0, 0, True);
	
	`log(Self@"shot"@HitActor@"through the path ending at"@ShotOrigin+Direction*10000$"!");
	if(HitActor != None)
	{
		// Call TakeDamage();
		//HitActor.Destroy();
	}
}

event Think()
{
	Super.Think();
	if(Target != None)
	{
		Shoot(CalculateShootVector(Actor(Target)));
	}
}

DefaultProperties
{

}