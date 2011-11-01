/**
TowerTargetable

Interface to represent things like infantry, vehicles, and projectiles that the player's tower can target.
It's assumed that all classes implementing this are extended from Actor.
*/
interface TowerTargetable;

//delegate OnDeathDelegate();

static function TowerTargetable CreateTargetable(TowerTargetable TargetableArchetype, out Vector SpawnLocation,
	TowerFaction NewOwningFaction);

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser);

function bool IsProjectile();

function bool IsVehicle();

function bool IsInfantry();

static function int GetCost(TowerTargetable SelfArchetype);

static function TowerPurchasableComponent GetPurchasableComponent(TowerTargetable Archetype);

function TowerDamageTrackerComponent GetDamageTracker();

//@TODO - Combine interface and component instead?
function TowerFaction GetOwningFaction();

//@TODO - Don't use TowerEnemyPawn.
event Initialize(TowerFormationAI Squad, TowerEnemyPawn PreviousSquadMember);

//function AddOnDeathDelegate(delegate<OnDeathDelegate> Callback);

//function int GetCost();

//event TargetableInitialize(TowerFactionAI SpawningAI);