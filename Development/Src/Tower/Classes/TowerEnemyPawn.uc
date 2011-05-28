/**
TowerEnemyPawn

Class of infantry units sent in by enemies.
*/
class TowerEnemyPawn extends TowerPawn
	implements(TowerTargetable);

var() const int Cost;
var() editconst TowerFaction OwnerFaction;
var() editconst byte TeamIndex;

var protectedwrite TowerWeaponAttachment WeaponAttachment;

replication
{
	if(bNetInitial)
		TeamIndex;
}

event Initialize(TowerFormationAI Squad, TowerEnemyPawn PreviousSquadMember)
{
//	Super.PostBeginPlay();
	Controller = Spawn(ControllerClass);
	Controller.Possess(self, false);
	TowerEnemyController(Controller).Squad = Squad;
	Weapon = Spawn(class'Tower.TowerWeapon_Rifle', self);
	Weapon.Activate();
	WeaponAttachment = Spawn(TowerWeapon(Weapon).AttachmentClass, self);
	WeaponAttachment.AttachTo(Self);
	if(PreviousSquadMember != None)
	{
		TowerEnemyController(PreviousSquadMember.Controller).NextSquadMember = TowerEnemyController(Controller);
	}
}

/**
AI Interface for combat
**/
function bool BotFire(bool bFinished)
{
	StartFire(0);
	return true;
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	Super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	ScriptTrace();
}

function bool OnSameFaction(TowerEnemyPawn Other)
{
	return Other.ScriptGetTeamNum() == ScriptGetTeamNum();
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local bool Value;
	`log(Self@"died. He owned"@Weapon);
	Value = Super.Died(Killer, DamageType, HitLocation);
	Destroy();
	if(Weapon != None)
	{
		Weapon.Destroy();
	}
	return Value;
}

static function TowerTargetable CreateTargetable(TowerTargetable TargetableArchetype, out Vector SpawnLocation,
	TowerFaction NewOwningFaction)
{
	local TowerEnemyPawn Pawn;
	Pawn = NewOwningFaction.Spawn(class'TowerEnemyPawn',,,SpawnLocation,,TowerEnemyPawn(TargetableArchetype), true);
	if(Pawn != None)
	{
		Pawn.OwnerFaction = NewOwningFaction;
	}
	return Pawn;
}

simulated event byte ScriptGetTeamNum()
{
	return TeamIndex;
}

/* epic ===============================================
* ::StopsProjectile()
*
* returns true if Projectiles should call ProcessTouch() when they touch this actor
*/
simulated function bool StopsProjectile(Projectile P)
{
	return TowerEnemyPawn(P.Instigator).TeamIndex != TeamIndex && (bProjTarget || bBlockActors);
}

function bool IsProjectile()
{
	return FALSE;
}

function bool IsVehicle()
{
	return FALSE;
}

function bool IsInfantry()
{
	return TRUE;
}

static function int GetCost(TowerTargetable SelfArchetype)
{
	return TowerEnemyPawn(SelfArchetype).Cost;
}

//@TODO - Combine interface and component instead?
function TowerFaction GetOwningFaction();

DefaultProperties
{
	bCanJump=false
	bJumpCapable=false
	ControllerClass=class'Tower.TowerEnemyController'
}