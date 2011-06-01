/**
TowerTargetable

Interface to represent things like infantry, vehicles, and projectiles that the player's tower can target.
It's assumed that all classes implementing this are extended from Actor.
*/
interface TowerTargetable;

//delegate OnDeathDelegate();

static function TowerTargetable CreateTargetable(TowerTargetable TargetableArchetype, out Vector SpawnLocation,
	TowerFaction NewOwningFaction);

function bool IsProjectile();

function bool IsVehicle();

function bool IsInfantry();

static function int GetCost(TowerTargetable SelfArchetype);

//@TODO - Combine interface and component instead?
function TowerFaction GetOwningFaction();

//@TODO - Don't use TowerEnemyPawn.
event Initialize(TowerFormationAI Squad, TowerEnemyPawn PreviousSquadMember);

//function AddOnDeathDelegate(delegate<OnDeathDelegate> Callback);

//function int GetCost();

//event TargetableInitialize(TowerFactionAI SpawningAI);