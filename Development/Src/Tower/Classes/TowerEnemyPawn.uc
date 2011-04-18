/**
TowerEnemyPawn

Class of infantry units sent in by enemies.
*/
class TowerEnemyPawn extends TowerPawn
	implements(TowerTargetable);

var() const int Cost;

static function TowerTargetable CreateTargetable(TowerTargetable TargetableArchetype, out Vector SpawnLocation,
	TowerFaction NewOwningFaction)
{
	return None;
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