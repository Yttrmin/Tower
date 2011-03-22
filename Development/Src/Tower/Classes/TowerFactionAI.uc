/**
TowerFactionAI

Controls the various factions, deciding on what troops and such to spawn, as well as where and when.
Each faction gets its own AI. Exist server-side only.
Note anytime "Troops" is used it includes missiles and such, not just infantry.
*/
class TowerFactionAI extends Actor
	dependson(TowerGame)
	abstract;

/** Strategy the AI uses during the current round. */ 
enum Strategies
{
	/** Default, used when not at war with anyone and thus not fighting. */
	S_None,
	S_Spam_Projectile
};

var Tower TargetTower;
var TowerFactionInfo FactionInfo;

// These exist purely to cut down on the typecasting and function calling every tick.
var protected TowerGame Game;
var protected TowerGameReplicationInfo GRI;

var() Strategies Strategy;

/** Array of all factions that this faction is at war with. If not in this array, peace is assumed. */
//var() array<Factions> AtWar;

// Have each type of troop have a specific cost?
/** Amount of troops remaining that can be spawned. 
The AI is free to spend the budget as it sees fit.*/
var() int TroopBudget;

/** Whether or not the AI is willing to spawn troops in other faction's borders. */
var() bool bInfringeBorders;

/** Set to TRUE after spawning a troop, during which no more can be spanwed. */
var() editconst protected bool bCoolDown;

/** FALSE during cool-down between rounds, disallowing the AI from spawning troops. */
var bool bCanFight;

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

event bool LaunchProjectile()
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

/** Called directly after the round is declared over, before cool-down period. */
event RoundEnded()
{
	bCanFight = False;
}

event CooledDown()
{
	bCoolDown = FALSE;
}

DefaultProperties
{
	Strategy=S_Spam_Projectile
	RemoteRole=ROLE_None
	Begin Object Class=TowerFactionInfo Name=FactionInfo0
	End Object
	Components.Add(FactionInfo0)
	FactionInfo=FactionInfo0
}