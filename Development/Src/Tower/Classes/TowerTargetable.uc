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

event Initialize(TowerFormationAI Squad);

//function AddOnDeathDelegate(delegate<OnDeathDelegate> Callback);

//function int GetCost();

//event TargetableInitialize(TowerFactionAI SpawningAI);