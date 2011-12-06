class TowerModuleGun extends TowerBlockModule;

var SkelControlLookAt Barrel;
var TowerTargetable Target;
var bool bCanFire;
var bool bThinking;

var() protected const instanced TowerAttackComponent AttackComponent;
var() float CoolDownTime;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(3, true, NameOf(Think));
}

event Initialize(out IVector NewGridLocation, out IVector NewParentDirection, 
	TowerPlayerReplicationInfo NewOwnerPRI)
{
	Super.Initialize(NewGridLocation, NewParentDirection, NewOwnerPRI);
	if(AttackComponent != None)
	{
		AttackComponent.Initialize();
	}
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
//	`log(SELF@"TOUCHED BY"@OTHER);
	Super.Touch(Other, OtherComp, HitLocation, HitNormal);
	RangeComponent.Touch(Other, OtherComp, HitLocation, HitNormal);
}

event UnTouch(Actor Other)
{
	Super.UnTouch(Other);
	RangeComponent.UnTouch(Other);
}

//@TODO - Move prototype to TowerBlockModule.
simulated event OnEnterRange(TowerTargetable Targetable)
{
	if(!bThinking)
	{
		Think();
		SetTimer(3, true, NameOf(Think));
		`log(Self@"OnEnterRange");
		bThinking = true;
	}
	/*
	if((Target == None || Actor(Target).bDeleteMe || !HasLineOfSight(Actor(Target))) && HasLineOfSight(Actor(Targetable)))
	{
		Target = Targetable;
		Think();
		SetTimer(3, true, NameOf(Think));
	}
	*/
}

simulated function StopThinking()
{
	ClearTimer('Think');
	bThinking = false;
}

simulated event OnExitRange(TowerTargetable Targetable)
{
	if(RangeComponent.EnemiesInRange() == 0)
	{
		AttackComponent.StopAttack();
		StopThinking();
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
	if(RangeComponent.EnemiesInRange() > 0)
	{
		AttackComponent.StartAttack();
	}
	/*
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
	*/
}

function GetNewTarget()
{
	Target = RangeComponent.GetATargetable();
	/*
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
	*/
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
	if(HitActor != None && TowerBlock(HitActor) == None)
	{
		// Call TakeDamage();
		HitActor.TakeDamage(4, None, HitLocation, HitLocation, class'TowerDmgType_Rifle',,Self);
		//HitActor.Destroy();
	}
}

DefaultProperties
{
	/*
	Begin Object Name=StaticMeshComponent0
		Translation=(Z=-128)
	End Object
	*/
}