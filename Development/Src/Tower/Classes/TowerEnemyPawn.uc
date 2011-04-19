/**
TowerEnemyPawn

Class of infantry units sent in by enemies.
*/
class TowerEnemyPawn extends TowerPawn
	implements(TowerTargetable);

var() const int Cost;
var() editconst TowerFaction OwnerFaction;

event Initialize(TowerFormationAI Squad)
{
	Super.PostBeginPlay();
	Controller = Spawn(ControllerClass);
	Controller.Possess(self, false);
	TowerEnemyController(Controller).Squad = Squad;
}

static function TowerTargetable CreateTargetable(TowerTargetable TargetableArchetype, out Vector SpawnLocation,
	TowerFaction NewOwningFaction)
{
	local TowerEnemyPawn Pawn;
	Pawn = NewOwningFaction.Spawn(class'TowerEnemyPawn',,,SpawnLocation,,TowerEnemyPawn(TargetableArchetype));
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
	ControllerClass=class'Tower.TowerEnemyController'
}