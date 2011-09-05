class TowerModuleGun extends TowerBlockModule;

var SkelControlLookAt Barrel;
var TowerTargetable Target;
var() private const bool bUsesProjectile;
var() private const class<TowerProjectile> ProjectileClass<EditCondition=bUsesProjectile>;
var() private const class<TowerDamageType> DamageTypeClass; 

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(3, true, 'Think');
}

simulated event OnEnterRange(TowerTargetable Targetable)
{
	if((Target == None || Actor(Target).bDeleteMe || !HasLineOfSight(Actor(Target))) && HasLineOfSight(Actor(Targetable)))
	{
		Target = Targetable;
		Think();
		SetTimer(3, true, 'Think');
	}
}

function bool HasLineOfSight(Actor Actor)
{
	local Vector HitLoc, HitNorm;
	if(Trace(HitLoc, HitNorm, Actor.Location, Location, true) == Actor)
	{
		return true;
	}
	else
	{
		return false;
	}
}

/** Returns TRUE if Actor is in our FactionLocation. */
function bool IsFacing(Actor Actor);

event Think()
{
	if(Target == None || Actor(Target).bDeleteMe)
	{
		GetNewTarget();
	}
	if(Target != None)
	{
		Shoot(Normal(Actor(Target).Location - Location));
	}
	else
	{
		ClearTimer('Think');
	}
}

function GetNewTarget()
{
	//@TODO - If multiple callbacks, pick at random.
	//@TODO - Pick random array member?
	if(Callbacks.bInfantry && OwnerPRI.Tower.Root.Infantry.Length > 0)
	{
		Target = OwnerPRI.Tower.Root.Infantry[0];
	}
	else if(Callbacks.bVehicle && OwnerPRI.Tower.Root.Vehicles.Length > 0)
	{
		Target = OwnerPRI.Tower.Root.Vehicles[0];
	}
	else if(Callbacks.bProjectile && OwnerPRI.Tower.Root.Projectiles.Length > 0)
	{
		Target = OwnerPRI.Tower.Root.Projectiles[0];
	}
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

	ShotOrigin = Location;
//	ShotOrigin.Z += 128;
	HitActor = Trace(HitLocation, HitNormal, ShotOrigin+Direction*10000, ShotOrigin, true);
	
	DrawDebugLine(ShotOrigin, ShotOrigin+Direction*10000, 1, 0, 0, True);
	
//	`log(Self@"shot"@HitActor@"through the path ending at"@ShotOrigin+Direction*10000$"!");
	if(HitActor != None && !HitActor.IsA('TowerBlock'))
	{
		// Call TakeDamage();
		HitActor.TakeDamage(4, None, HitLocation, HitLocation, class'TowerDmgType_Rifle',,Self);
		//HitActor.Destroy();
	}
}

DefaultProperties
{
	Begin Object Name=StaticMeshComponent0
		Translation=(Z=-128)
	End Object
}