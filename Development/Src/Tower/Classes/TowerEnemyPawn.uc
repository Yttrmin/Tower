/**
TowerEnemyPawn

Class of infantry units sent in by enemies.
*/
class TowerEnemyPawn extends TowerPawn
	implements(TowerTargetable);

var() const int Cost;
var() editconst TowerFaction OwnerFaction;

var protectedwrite TowerWeaponAttachment WeaponAttachment;

event Initialize(TowerFormationAI Squad, TowerEnemyPawn PreviousSquadMember)
{
//	Super.PostBeginPlay();
	Controller = Spawn(ControllerClass);
	Controller.Possess(self, false);
	TowerEnemyController(Controller).Squad = Squad;

	Weapon = Spawn(class'Tower.TowerWeapon_Rifle', self);
//	Weapon.Activate();
	WeaponAttachment = Spawn(TowerWeapon(Weapon).AttachmentClass, self);
	WeaponAttachment.AttachTo(Self);
	if(PreviousSquadMember != None)
	{
		TowerEnemyController(PreviousSquadMember.Controller).NextSquadMember = TowerEnemyController(Controller);
	}
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