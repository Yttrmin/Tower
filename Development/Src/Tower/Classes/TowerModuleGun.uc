class TowerModuleGun extends TowerBlockModule;

var SkelControlLookAt Barrel;

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

	ShotOrigin = Location;
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

DefaultProperties
{
	Begin Object Name=StaticMeshComponent0
		Translation=(Z=-128)
	End Object
}