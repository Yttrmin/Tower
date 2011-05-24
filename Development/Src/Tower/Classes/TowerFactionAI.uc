/**
TowerFactionAI

Base class for controlling the various factions, deciding on what troops and such to spawn, as well as where and when.
Each faction gets its own AI. Exist server-side only.
Note anytime "Troops" is used it includes missiles and such, not just infantry.
The interface of this class will be released for modding!
*/
class TowerFactionAI extends TowerFaction 
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

struct PlaceableUsage
{
	var bool bStructural;
	var bool bGunHitscan;
	var bool bGunProjectile;
	var bool bShield;
	var bool bAntiInfantry;
	var bool bAntiVehicle;
	var bool bAntiProjectile;
};

struct PlaceableInfo
{
	var TowerPlaceable PlaceableArchetype;
	var PlaceableUsage Flags;
};

struct PlaceableKillInfo
{
	var TowerPlaceable Placeable;
	var int InfantryKillCount, ProjectileKillCount, VehicleKillCount;
};

struct PlaceableTargetInfo
{
	var TowerPlaceable Placeable;
	var int ArchetypeIndex;
};

/** Series of flags to be used with a Formation. Tells AI what this Formation might be good for. */
struct FormationUsage
{
	/** If TRUE, this formation will never be randomly spawned. */
	var() const bool bScriptSpecific;
	/** If TRUE, this formation can only be spawned once per round. */
	var() const bool bSingleUse;
	var() const bool bHasInfantry;
	var() const bool bHasVehicles;
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
	/** If TRUE, this unit is the 'leader' of the squad. It's the only unit that'll do pathfinding, all
	other units will simply follow markers placed around the leader based on their location in the TroopInfo.

	There must be a leader!
	There can only be one leader!
	Making more than one leader will break everything!*/
	var() const bool bLeader;
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
	var() const /*editoronly*/ name Name;
	var() const editoronly string Description;
	var() const FormationUsage FormationUsageFlags;

	// But how do we handle randomly picked formations? Base cost? Low/High cost?
	/** Cost of the entire formation. A sum of all Unit costs. */
	var() const editconst int FormationCost;
};

struct FormationSpawnInfo
{
	var int FormationIndex;
	var TowerSpawnPoint SpawnPoint;
	var TowerAIObjective Target;
};

/** Strategy the AI uses during the current round. */ 
enum Strategy
{
	/** Default, used when not at war with anyone and thus not fighting. */
	S_None,
	/** The AI has enough information about the enemy and is trying to counter its forces. */
	S_Counter,
	/** The AI doesn't know enough about the enemy to counter it. */
	S_CollectData,
	S_Spam_Projectile
};

var protected Tower TargetTower;
var() protected TowerFactionInfo FactionInfo;

// These exist purely to cut down on the typecasting and function calling every tick.
var protected TowerGame Game;
var protected TowerGameReplicationInfo GRI;

/** Current strategy this faction is basing its decisions on. 
Only has an effect when changed ingame. */
var(InGame) protected deprecated Strategy CurrentStrategy;

var() protected const array<Formation> Formations;

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

// Infantry archetype with lowest cost.
var protected TowerTargetable CheapestInfantry;

var TowerFactionAIHivemind Hivemind;

//============================================================================================================
// CollectData-related variables.

var array<PlaceableKillInfo> Killers;

//============================================================================================================

var array<PlaceableTargetInfo> Targets;

var array<FormationSpawnInfo> OrderQueue;

var array<NavigationPoint> InfantryDestinations;

var array<TowerSpawnPoint> SpawnPoints;

event ReceiveSpawnPoints(array<TowerSpawnPoint> NewSpawnPoints)
{
	ScriptTrace();
	`warn("ReceiveSpawnPoints called on"@self@"outside of InActive!");
}

function BeginCoolDown()
{
	bCoolDown = true;
	SetTimer(2, true, 'CooledDown');
}

function ResetCoolDown()
{
	bCoolDown = false;
}

event CooledDown()
{
	
}

auto state InActive
{
	event BeginState(Name PreviousStateName)
	{
		bCanFight = False;
	}
	event RoundStarted(const int AwardedBudget)
	{
		TroopBudget = AwardedBudget;
		`log(Self@"Round started! Budget:"@TroopBudget);
		bCanFight = True;
		GotoState('Active');
		ScriptTrace();
	}
	event ReceiveSpawnPoints(array<TowerSpawnPoint> NewSpawnPoints)
	{
		SpawnPoints = NewSpawnPoints;
	}
	function int SortSpawnPoints(TowerSpawnPoint A, TowerSpawnPoint B)
	{
		//@TODO - Actually sort.
		return 0;
	}
}

state Active
{
	event BeginState(Name PreviousStateName)
	{
		DetermineStrategy();
	}
	// Do we really need to think every tick?
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
		GotoState('InActive');
	}

	protected function DetermineStrategy();

	function bool SpawnFormation(int Index, TowerSpawnPoint SpawnPoint, TowerAIObjective Target)
	{
		local int i;
		local int FormationCost;
		local TowerFormationAI Squad;
		local bool bAbort;
		local TowerTargetable Targetable;
		/** The previous TowerTargetable in the squad's linked list. */
		local TowerTargetable PreviousTargetable;

		Squad = Spawn(class'TowerFormationAI');
		Squad.SquadObjective = Hivemind.RootBlock;
		// Handle when all points are occupied?
		`log("Spawning formation:"@Formations[Index].Name);

		// Actually calculate this.
		FormationCost = CalculateBaseFormationCost(Index);
		if(HasBudget(FormationCost))
		{
			ConsumeBudget(FormationCost);
			SpawnFormationLeader(Squad, SpawnPoint, Index);
			PreviousTargetable = TowerEnemyPawn(Squad.SquadLeader.Pawn);
			for(i = 0; i < Formations[Index].TroopInfo.Length && !bAbort; i++)
			{
				if(!Formations[Index].TroopInfo[i].TroopBehaviorFlags.bLeader && Formations[Index].TroopInfo[i].Type == TT_Infantry)
				{
					Targetable = SpawnUnit(CheapestInfantry, SpawnPoint, Formations[Index].TroopInfo[i]);
					if(Targetable == None)
					{
						bAbort = true;
					}
					else
					{
						Targetable.Initialize(Squad, TowerEnemyPawn(PreviousTargetable));
						TowerEnemyController(TowerEnemyPawn(Targetable).Controller).Marker 
							= SpawnFollowerMarker(Squad, SpawnPoint, Index, i);
						PreviousTargetable = Targetable;
					}
				}
			}
			if(!bAbort)
			{
				Squad.Initialized();
				//BeginCoolDown();
				return true;
			}
			else
			{
				Squad.Destroy();
			}
		}
		`log("Spawn formation failed. Budget:"@TroopBudget);
		return false;
	}

	/** Searches given formation index for the leader, spawns it, and assigns Squad::SquadLeader.
	If a leader isn't found then -1 is returned and Squad::SquadLeader is unchanged. */
	final function SpawnFormationLeader(TowerFormationAI Squad, TowerSpawnPoint SpawnPoint, int Index)
	{
		local TowerTargetable Leader;
		local int i;
		for(i = 0; i < Formations[Index].TroopInfo.Length; i++)
		{
			if(Formations[Index].TroopInfo[i].TroopBehaviorFlags.bLeader)
			{
				Leader = SpawnUnit(UnitList.InfantryArchetypes[0], SpawnPoint, Formations[Index].TroopInfo[i]);
				Leader.Initialize(Squad, None);
				`warn("Failed to spawn Leader!", Leader == None);
				Squad.SquadLeader = TowerEnemyController(TowerEnemyPawn(Leader).Controller);
				//`log("SL:"@Squad.SquadLeader@Leader);
				return;
			}
		}
		`warn("No Leader specified at formation index:"@Index$"!"@"Fix this!");
		return;
	}

	function TowerFormationMarker SpawnFollowerMarker(TowerFormationAI Squad, TowerSpawnPoint SpawnPoint,
		int FormationIndex, int UnitIndex)
	{
		local TowerFormationMarker Marker;
		local Vector SpawnLocation;
		SpawnLocation = GetSpawnLocation((Formations[FormationIndex].TroopInfo[UnitIndex]), SpawnPoint.Location, SpawnPoint.Rotation);
		Marker = Spawn(class'TowerFormationMarker', Squad.SquadLeader.Pawn,, SpawnLocation);
		Marker.SetBase(Squad.SquadLeader.Pawn);
		return Marker;
	}

	protected function int CalculateBaseFormationCost(int FormationIndex)
	{
		local int Cost;
		local int i;
		for(i = 0; i < Formations[FormationIndex].TroopInfo.Length; i++)
		{
			if(Formations[FormationIndex].TroopInfo[i].Type == TT_Infantry)
			{
				Cost += CheapestInfantry.GetCost(CheapestInfantry);
			}
		}
		`log("CalculateBaseFormationCost:"@FormationIndex);
		return Cost;
	}

	function CalculateUnitSpawnLocationRotation(TowerSpawnPoint SpawnPoint, out Vector SpawnLocation, 
		out Rotator SpawnRotation, int FormationIndex, int UnitIndex)
	{
		SpawnLocation = SpawnPoint.Location + Formations[FormationIndex].TroopInfo[UnitIndex].RelativeLocation;

	}
}

function Vector GetSpawnLocation(const TroopInfo Troop, const out Vector OriginLocation, const out Rotator OriginRotation)
	{
		/*
		Out.X = SpawnIn.X + (Math.Cos(DegreeToRadian(Rotation)) * (In.X - SpawnIn.X)
                - Math.Sin(DegreeToRadian(Rotation)) * (In.Y - SpawnIn.Y));
            Out.Y = SpawnIn.Y + (Math.Sin(DegreeToRadian(Rotation)) * (In.X - SpawnIn.X)
                + Math.Cos(DegreeToRadian(Rotation)) * (In.Y - SpawnIn.Y));
		*/
		local Vector Coordinates;
		local Vector ModTroopLocation;
		ModTroopLocation = OriginLocation + Troop.RelativeLocation;
		Coordinates.X = (OriginLocation.X + Cos(OriginRotation.Yaw*UnrRotToRad) * (ModTroopLocation.X - OriginLocation.X)
			- Sin(OriginRotation.Yaw*UnrRotToRad) * (ModTroopLocation.Y - OriginLocation.Y));
		Coordinates.Y = (OriginLocation.Y + Sin(OriginRotation.Yaw*UnrRotToRad) * (ModTroopLocation.X - OriginLocation.X)
			+ Cos(OriginRotation.Yaw*UnrRotToRad) * (ModTroopLocation.Y - OriginLocation.Y));
		//`log("Rotation:"@OriginRotation.Yaw@"degrees:"@OriginRotation.Yaw*UnrRotToDeg@"sin:"@Sin(OriginRotation.Yaw*UnrRotToRad)
		//	@"Cos:"@Cos(OriginRotation.Yaw*UnrRotToRad)@"coordinates:"@Coordinates@"OriginLoc"@OriginLocation@"OriginRot"@OriginRotation);
		return Coordinates;
	}

function AppendToKillersArray(int Index, TowerTargetable KilledTargetable)
{
	if(KilledTargetable.IsInfantry())
	{
		Killers[Index].InfantryKillCount++;
	}
	if(KilledTargetable.IsVehicle())
	{
		Killers[Index].VehicleKillCount++;
	}
	if(KilledTargetable.IsProjectile())
	{
		Killers[Index].ProjectileKillCount++;
	}
}

event PostBeginPlay()
{
	local PlayerController PC;
	foreach LocalPlayerControllers(class'PlayerController', PC)
	{
		PC.myHUD.AddPostRenderedActor(self);
	}
	Super.PostBeginPlay();
	`assert(UnitList != None);
	Game = TowerGame(WorldInfo.Game);
	GRI = TowerGameReplicationInfo(Game.GameReplicationInfo);
	CalculateAllCosts();
}

simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	// Note that drawings on the canvas are NOT persistent.
//	Canvas.CurX = UnitsOut;
//	Canvas.DrawText("HI");
//	UnitsOut++;

	Canvas.CurY = 50;
	Canvas.DrawText("Faction:"@Self);

	Canvas.CurX = 0;
	Canvas.CurY = 65;
	Canvas.DrawText("FactionLocation:"@GetEnum(Enum'FactionLocation', Faction));

	Canvas.CurX = Canvas.SizeX-150;
	Canvas.CurY = 50;
	Canvas.DrawText("TroopBudget:"@TroopBudget);
	
	Canvas.CurX = Canvas.SizeX-150;
	Canvas.CurY = 65;
	Canvas.DrawText("UnitsOut:"@UnitsOut);

	Canvas.CurX = 0;
	Canvas.CurY = 80;
	Canvas.DrawText("State:"@GetStateName());

	//@TODO - Let each state draw its own stuff.
	if(GetStateName() == 'CollectData')
	{
		Canvas.CurX = 0;
		Canvas.CurY = 95;
		Canvas.DrawText("Orders Queued:"@OrderQueue.Length);
	}
}

function CalculateAllCosts()
{
	local int i;
	CheapestInfantry = UnitList.InfantryArchetypes[i];
	for(i = 1; i < UnitList.InfantryArchetypes.Length; i++)
	{
		if(CheapestInfantry.GetCost(CheapestInfantry) > UnitList.InfantryArchetypes[i].GetCost(UnitList.InfantryArchetypes[i]))
		{
			CheapestInfantry = UnitList.InfantryArchetypes[i];
		}
	}
	`log("Cheapest infantry unit:"@CheapestInfantry@CheapestInfantry.GetCost(CheapestInfantry));
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

final function TowerSpawnPoint GetSpawnPoint(int FormationIndex)
{
	local TowerSpawnPoint Point;
	local bool bFailed;
	local array<TowerSpawnPoint> PotentialPoints;
	foreach SpawnPoints(Point)
	{
		if(Formations[FormationIndex].FormationUsageFlags.bHasInfantry == true)
		{
			bFailed = !Point.bCanSpawnInfantry;
		}
		if(Formations[FormationIndex].FormationUsageFlags.bHasVehicles == true && !bFailed)
		{
			bFailed = !Point.bCanSpawnVehicle;
		}
		if(!bFailed)
		{
			PotentialPoints.AddItem(Point);
		}
	}
	return PotentialPoints[Rand(PotentialPoints.Length-1)];
}

event TowerTargetable SpawnUnit(TowerTargetable UnitArchetype, TowerSpawnPoint SpawnPoint, const TroopInfo UnitTroopInfo)
{
	local Vector SpawnLocation;
	local TowerTargetable Targetable;

	SpawnLocation = GetSpawnLocation(UnitTroopInfo, SpawnPoint.Location, SpawnPoint.Rotation);
//	`log("SpawnLocation:"@SpawnLocation@"from SpawnPoint:"@SpawnPoint.Location@"rotation:"@SpawnPoint.Rotation);
	Targetable = UnitArchetype.CreateTargetable(UnitArchetype, SpawnLocation, Self);
	TowerEnemyPawn(Targetable).TeamIndex = TeamIndex;
	return Targetable;
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

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerPlaceable PlaceableKiller)
{
	//@TODO - Collect information about deaths so we can figure out what to counter.
	UnitsOut--;
}

event OnVIPDeath(TowerTargetable VIP)
{
}

function bool HasBudget(int Amount)
{
	if(Amount > TroopBudget)
	{
		return FALSE;
	}
	return TRUE;
}

function ConsumeBudget(int Amount)
{
	TroopBudget = Max(0, TroopBudget - Amount);
}

DefaultProperties
{
	UnitList=TowerUnitsList'TowerMod.NullObjects.NullUnitsList'

	bPostRenderIfNotVisible=true

	CurrentStrategy=S_None
	RemoteRole=ROLE_None
	Begin Object Class=TowerFactionInfo Name=FactionInfo0
	End Object
	Components.Add(FactionInfo0)
	FactionInfo=FactionInfo0

	// Consider how to get this during AsyncWork.
	TickGroup=TG_PreAsyncWork
}