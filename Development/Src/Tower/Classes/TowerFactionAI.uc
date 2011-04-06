/**
TowerFactionAI

Controls the various factions, deciding on what troops and such to spawn, as well as where and when.
Each faction gets its own AI. Exist server-side only.
Note anytime "Troops" is used it includes missiles and such, not just infantry.
*/
class TowerFactionAI extends Info
	implements(TowerFaction)
	ClassGroup(Tower)
	dependson(TowerGame)
//	AutoExpandCategories(TowerFactionAI)
	HideCategories(Display,Attachment,Collision,Physics,Advanced,Object,Debug)
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
	/** If TRUE, this formation will never be randomly spawned. */
	var() const bool bScriptSpecific;
	/** If TRUE, this formation can only be spawned once per round. */
	var() const bool bSingleUse;
	/** If TRUE, this formation is effective against infantry. */
	var() const bool bAntiInfantry;
	/** If TRUE, this formation is effective against vehicles. */
	var() const bool bAntiVehicle;
	/** If TRUE, this formation is effective against blocks. */
	var() const bool bAntiBlock;
	/** If TRUE, this formation is effective against turrets. */
	var() const bool bAntiTurret;
	/** If TRUE, this formation is effective against shields. */
	var() const bool bAntiShield;
	/** If TRUE, this formation is effective against projectiles. */
	var() const bool bAntiProjectile;
	/** */
	var() const bool bSpecial;
	/** */
	var() const bool bAreaDenial;
	/** */
	var() const bool bWave;
	/** */
	var() const bool bSpam;
	/** */
	var() const bool bSuicidal;
	/** If TRUE, this formation can be used to setup a base. */
	var() const bool bPortableBase;
	/** */
	var() const bool bDefensive;
	/** */
	var() const bool bOffensive;
};

struct TroopBehavior
{
	/** If TRUE, OnVIPDeath() will be called in TowerFactionAI when this troop dies. */
	var() const bool bVIP;
	/** */
	var() const bool bGuard;
	/** If TRUE, this troop is not afraid of death. */
	var() const bool bSuicidal;
};

struct TroopInfo
{
	/** Location inside this formation. (0,0,0) is the origin. Forward is along positive X. Formation will be rotated
	with RelativeLocations intact if need be. */
	var() const Vector RelativeLocation;
	/** Rotation inside this formation. (0,0,0) rotation is facing forward (positive X). 
	Keep in mind the troop AI may completely undo this rotation to get to its target. */
	var() const Rotator RelativeRotation;
	var() const TroopBehavior TroopBehaviorFlags;
	var() const TargetType Type;
};

struct Formation
{
	var() const array<TroopInfo> TroopInfo;
	/** Name of this formation. Solely used for human identification. */
	var() const editoronly name Name;
	var() const editoronly string Description;
	var() const FormationUsage FormationUsageFlags;

	// But how do we handle randomly picked formations? Base cost?
	/** Cost of the entire formation. A sum of all Unit costs. */
	var() const editconst int FormationCost;
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
var(InGame) protected Strategy CurrentStrategy;

var() protected array<Formation> Formations;

/** List of units this faction can spawn. */
var() protected noclear TowerUnitsList UnitList;

/** Array of all factions that this faction is at war with. If not in this array, peace is assumed. */
//var() array<Factions> AtWar;

// Have each type of troop have a specific cost?

/** Amount of troops remaining that can be spawned. The AI is free to spend the budget as it sees fit.
Only has an effect when changed ingame.*/
var(InGame) protected int TroopBudget;

/** Whether or not the AI is willing to spawn troops in other faction's borders. */
var(InGame) protected bool bInfringeBorders;

/** Set to TRUE after spawning a troop, during which no more can be spanwed. */
var(InGame) protected editconst bool bCoolDown;

/** FALSE during cool-down between rounds, disallowing the AI from spawning troops. */
var(InGame) protected editconst bool bCanFight;

//var(InGame) protected editconst array<> OrderQueue;

var(InGame) protected editconst int UnitsOut;

state Active
{
	event Tick(float DeltaTime)
	{
		Super.Tick(DeltaTime);
		Think();
	}

	event Think()
	{
		if(TargetTower == None)
		{
			`log("GRAB NEW ONE");
			GetNewTarget();
		}
	//	SpawnFormation(0);
	}

	/** Called directly after the round is declared over, before cool-down period. */
	event RoundEnded()
	{
		bCanFight = False;
		GotoState('InActive');
	}
}

auto state InActive
{
	event RoundStarted(const int AwardedBudget)
	{
		TroopBudget = AwardedBudget;
		bCanFight = True;
		GotoState('Active');
	}
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	`assert(UnitList != None);
	Game = TowerGame(WorldInfo.Game);
	GRI = TowerGameReplicationInfo(Game.GameReplicationInfo);
}

event RoundStarted(const int AwardedBudget);

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

function SpawnFormation(int Index, TowerSpawnPoint SpawnPoint)
{
	local int i;
	local Vector FormationLocation;
	local int FormationCost;
	FormationLocation = SpawnPoint.Location;
	
	if(HasBudget(FormationCost))
	{
		for(i = 0; i < Formations[Index].TroopInfo.Length; i++)
		{
			if(Formations[Index].TroopInfo[i].Type == TT_Infantry)
			{
				SpawnUnit(UnitList.InfantryArchetypes[0], FormationLocation, Formations[Index].TroopInfo[i]);
			}
		}
	}
}

event TowerTargetable SpawnUnit(TowerTargetable UnitArchetype, out vector FormationLocation, const TroopInfo UnitTroopInfo)
{
	local int Cost;
	local TowerTargetable Unit;
	local Vector SpawnLocation;

	Cost = UnitArchetype.GetCost(UnitArchetype);

	if(HasBudget(Cost))
	{
		SpawnLocation = FormationLocation + UnitTroopInfo.RelativeLocation;
		return UnitArchetype.CreateTargetable(UnitArchetype, SpawnLocation, Self);
	}
	else
	{
		CheckActivity();
		return None;
	}
}

function int GetUnitCost(TowerTargetable UnitArchetype)
{

}

function CheckActivity()
{
	// Check against minimum cost?
	if(TroopBudget > 0)
	{
		
	}
}

//function TowerSpawnPoint GetSpawnPoint()

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

event bool LaunchKProjectile(TowerKProjectile KProjectileArchetype)
{

}

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerPlaceable PlaceableKiller)
{

}

event OnVIPDeath(TowerCrowdAgent VIP)
{
}

event CooledDown()
{
	bCoolDown = FALSE;
}

function bool HasBudget(int Amount)
{
	return TRUE;
}

function ConsumeBudget(int Amount);

DefaultProperties
{
	UnitList=TowerUnitsList'TowerMod.NullObjects.NullUnitsList'

	CurrentStrategy=S_Spam_Projectile
	RemoteRole=ROLE_None
	Begin Object Class=TowerFactionInfo Name=FactionInfo0
	End Object
	Components.Add(FactionInfo0)
	FactionInfo=FactionInfo0
}