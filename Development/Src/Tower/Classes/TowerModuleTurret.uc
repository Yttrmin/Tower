class TowerModuleTurret extends TowerModule
	placeable;

//var StaticMeshComponent StaticMeshComponent;
//var SkeletalMeshComponent SkeletalMeshComponent;

function Vector CalculateShootVector(Actor ShotTarget)
{
	return Normal(ShotTarget.Location - Owner.Location);
}

function Shoot(Vector Direction)
{
	local vector HitLocation, HitNormal;
	local Actor HitActor;
	HitActor = Owner.Trace(HitLocation, HitNormal, Owner.Location+Direction*10000, Owner.Location, true);
	
	Owner.DrawDebugLine(Owner.Location, Owner.Location+Direction*10000, 1, 0, 0, True);
	
	`log(Self@"shot"@HitActor@"through the path ending at"@Owner.Location+Direction*10000$"!");
	if(HitActor != None)
	{
		HitActor.Destroy();
	}
}

event Think()
{
	Super.Think();
	if(Target != None)
	{
		Shoot(CalculateShootVector(Target));
	}
}

DefaultProperties
{

}