/**
TowerFactionAI

Controls the various factions, deciding on what troops and such to spawn, as well as where and when.
Each faction gets its own AI. Exist server-side only.
Note anytime "Troops" is used it includes missiles and such, not just infantry.
*/
class TowerFactionAI extends Info
	ClassGroup(Tower)
	dependson(TowerGame)
	AutoExpandCategories(TowerFactionAI)
	HideCategories(Object)
	placeable // Please don't actually place me. =(
	/*abstract*/;

/**
Archetype? - Just like everything else, easy to mod! Different types of FactionAIs then?
Hardcoded? - Ehh. Might even be harder.

Strategies:
* Lists of general troop formations for AI to spawn? (Type independent?)
	* For example (but dumb): 11 infantry arranged in a ^ formation which would be used to rush target?
	* Or: 5 infantry in front of 1 vehicle as some type of escort?
	* Flags to represent what the formation should be used for?
* AI would then mix and match these with its overall strategy, supplying actual types for each troop.
* Sounds pretty good!
* An in-game visual editor would be pretty cool...
	* MAYBE LATER
* Some sort of troop behavior struct? Eg, so troops will actually stick around the vehicle they're escorting.
*/

/** Series of flags to be used with a Formation. Tells AI what this Formation might be good for. */
struct FormationUsage
{
	/** */
	var() const bool bbbbb; 
};

struct TroopBehavior
{
	var() bool bb;
};

struct TroopInfo
{
	/** Location inside this formation. (0,0,0) is the origin. Forward is along positive X. Formation will be rotated
	with RelativeLocations intact if need be. */
	var() const Vector RelativeLocation;
	/** Rotation inside this formation. (0,0,0) rotation is facing forward (positive X). 
	Keep in mind the troop AI may completely undo this rotation to get to its target. */
	var() const Rotator RelativeRotation;
	var() const TargetType Type;
};

struct Formation
{
	var() const array<TroopInfo> TroopInfo;
	/** Name of this formation. Solely used for human identification. */
	var() const name Name;
	var() const editoronly string Description;
	var() const FormationUsage Usage;
};

/** Strategy the AI uses during the current round. */ 
enum Strategy
{
	/** Default, used when not at war with anyone and thus not fighting. */
	S_None,
	S_Spam_Projectile
};

var() protected const name FactionName;

var protected Tower TargetTower;
var() protected TowerFactionInfo FactionInfo;

// These exist purely to cut down on the typecasting and function calling every tick.
var protected TowerGame Game;
var protected TowerGameReplicationInfo GRI;

/** Current strategy this faction is basing its decisions on. 
Only has an effect when changed ingame. */
var() protected Strategy CurrentStrategy;

var() protected array<Formation> Formations;

/** Array of all factions that this faction is at war with. If not in this array, peace is assumed. */
//var() array<Factions> AtWar;

// Have each type of troop have a specific cost?

/** Amount of troops remaining that can be spawned. The AI is free to spend the budget as it sees fit.
Only has an effect when changed ingame.*/
var() protected int TroopBudget;

/** Whether or not the AI is willing to spawn troops in other faction's borders. */
var() protected bool bInfringeBorders;

/** Set to TRUE after spawning a troop, during which no more can be spanwed. */
var() protected editconst bool bCoolDown;

/** FALSE during cool-down between rounds, disallowing the AI from spawning troops. */
var() protected editconst bool bCanFight;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	Game = TowerGame(WorldInfo.Game);
	GRI = TowerGameReplicationInfo(Game.GameReplicationInfo);
}

function GetNewTarget()
{
	//@TODO - 3rd player and on are not counted, make something better.
	local Tower PlayerTower;
	foreach AllActors(class'Tower', PlayerTower)
	{
		if(PlayerTower != TargetTower)
		{
			TargetTower = PlayerTower;
			`log("FOUND TARGETTOWER:"@TargetTower);
			return;
		}
	}
}

function TowerSpawnPoint GetSpawnPoint()
{
	local TowerSpawnPoint SpawnPoint;
	foreach TowerGame(WorldInfo.Game).ProjectilePoints(SpawnPoint)
	{
		return SpawnPoint;
	}
}

event RoundStarted(const int AwardedBudget)
{
	TroopBudget = AwardedBudget;
	bCanFight = True;
}

event Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);
	if(GRI.bRoundInProgress)
	{
		Think();
	}
}

event Think()
{
	if(TargetTower == None)
	{
		`log("GRAB NEW ONE");
		GetNewTarget();
	}
}

// How will we get cost? Archetype+Cost in struct? No, that's awful. Aggggh...
// Or just not use this!
// But it seems so wrong...
// Typecast? Hey you still only have to use one function!
// How dumb is the idea of typecasting to the archetypes class and calling a variable we know will be in all their classes? VERY.
// How dumb is the idea of using a switch statement for determining the class? Very I guess.
// Can static functions return components? Probably not.
// Spawn and then get cost? If you're spawning a lot of units this could get expensive.
// Create a cache to relate the name of a unit to its cost!?/12
event bool SpawnUnit(TowerTargetable UnitArchetype)
{
	local int Cost;
	if(UnitArchetype.class == class'TowerProjectile')
	{
//		Cost = TowerProjectile.
	}
	else if(UnitArchetype.class == class'TowerKProjectile')
	{

	}
	else if(UnitArchetype.class == class'TowerCrowdAgent')
	{

	}
	else if(UnitArchetype.class == class'TowerEnemyPawn')
	{

	}
	else if(UnitArchetype.class == class'TowerVehicle')
	{

	}
	else
	{
		`warn(UnitARchetype.class@"is not handled by SpawnUnit!");
	}
	if(HasBudget(Cost))
	{

	}
}

event bool LaunchProjectile(TowerProjectile ProjectileArchetype)
{
	local TowerSpawnPoint SpawnPoint;
	local TowerKProjRock Proj;
	local TowerBlock Block, TargetBlock;
	SpawnPoint = GetSpawnPoint();
	Proj = Spawn(class'TowerKProjRock',,, SpawnPoint.Location);
	foreach DynamicActors(class'TowerBlock', Block)
	{
		TargetBlock = Block;
		break;
	}
//	`log(0.5*ASin((1039.829009434*VSize(Vect(-1756,1755,78) - Proj.Location))/5000));
	Proj.Launch(TargetBlock.Location);
	`log("SHOT PROJECTILE, COOL DOWN");
	SetTimer(0.5, false, 'CooledDown');
	bCoolDown = TRUE;
	
	return true;
}

event bool LaunchKProjectile(TowerKProjectile KProjectileArchetype);

//@TODO - Pawn support? Are we really even going to use pawns ever?
event bool SpawnInfantry(TowerCrowdAgent InfantryArchetype);

event bool SpawnVehicle(TowerVehicle VehicleArchetype);

/** Called directly after the round is declared over, before cool-down period. */
event RoundEnded()
{
	bCanFight = False;
}

event CooledDown()
{
	bCoolDown = FALSE;
}

function bool HasBudget(int Amount);

function ConsumeBudget(int Amount);

DefaultProperties
{
	bTest=FALSE

	CurrentStrategy=S_Spam_Projectile
	RemoteRole=ROLE_None
	Begin Object Class=TowerFactionInfo Name=FactionInfo0
	End Object
	Components.Add(FactionInfo0)
	FactionInfo=FactionInfo0
}