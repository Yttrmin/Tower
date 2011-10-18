/**
TowerFactionAI

Base class for controlling the various factions, deciding on what troops and such to spawn, as well as where and when.
Each faction gets its own AI. Exist server-side only.
Note anytime "Troops" is used it includes missiles and such, not just infantry.
The interface of this class will be released for modding!
*/
class TowerFactionAI extends TowerFaction 
	ClassGroup(Tower)
	dependson(TowerGame, TowerFactionAIHivemind)
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

//@TODO - Deprecate this?
var protected deprecated Tower TargetTower;
var() protected  TowerFactionAILogicComponent LogicComponent;
var() protected TowerFactionInfo FactionInfo;

// These exist purely to cut down on the typecasting and function calling every tick.
var protected TowerGame Game;
var protected TowerGameReplicationInfo GRI;

var() protected const array<Formation> Formations;

/** List of units this faction can spawn. */
var() protected noclear TowerUnitsList UnitList;

/** Array of all factions that this faction is at war with. If not in this array, peace is assumed. */
//var() array<Factions> AtWar;

// Have each type of troop have a specific cost?

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

var private int CheapestTargetable;

var TowerFactionAIHivemind Hivemind;

var array<FormationSpawnInfo> OrderQueue;

var array<NavigationPoint> InfantryDestinations;

var array<TowerSpawnPoint> SpawnPoints;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	`assert(UnitList != None);
	Game = TowerGame(WorldInfo.Game);
	GRI = TowerGameReplicationInfo(Game.GameReplicationInfo);
	CalculateAllCosts();
}

// Called when skipping a round. All subclasses should implement this properly.
event GoInActive()
{
	local TowerEnemyPawn Pawn;
	Budget = -1;
	foreach WorldInfo.AllPawns(class'TowerEnemyPawn', Pawn)
	{
		if(Pawn.OwnerFaction == Self)
		{
			Pawn.TakeDamage(999999, None, Vect(0,0,0), Vect(0,0,0), class'DmgType_Telefragged');
		}
	}
	CheckActivity();
}

event ReceiveSpawnPoints(array<TowerSpawnPoint> NewSpawnPoints)
{
	ScriptTrace();
	`warn("ReceiveSpawnPoints called on"@self@"outside of InActive!");
}

function BeginCoolDown()
{
	bCoolDown = true;
	SetTimer(2, true, NameOf(CooledDown));
}

function ResetCoolDown()
{
	bCoolDown = false;
}

event CooledDown()
{
	
}

event RoundEnded()
{
	`warn("RoundEnded not called in Active state!");
}

function bool SpawnFormation(int Index, TowerSpawnPoint SpawnPoint, TowerAIObjective Target)
{
	`warn("TRIED TO SPAWNFORMATION OUTSIDE ACTIVE");
	return false;
}

auto state InActive
{
	event BeginState(Name PreviousStateName)
	{
		bCanFight = False;
	}
	event RoundStarted(const int AwardedBudget)
	{
		Budget = AwardedBudget;
		`log(Self@"Round started! Budget:"@Budget);
		bCanFight = True;
		GotoState('Active');
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
		CheckActivity();
	}
	// Do we really need to think every tick?
	event Tick(float DeltaTime)
	{
		Super.Tick(DeltaTime);
		Think();
	}

	event Think()
	{
		/*
		if(TargetTower == None)
		{
			GetNewTarget();
		}
		*/
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
		Squad.SquadObjective = Target;
		// Handle when all points are occupied?
//		`log("Spawning formation:"@Formations[Index].Name);

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
		`log("Spawn formation failed. Budget:"@Budget);
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
//		`log("CalculateBaseFormationCost:"@FormationIndex);
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

simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	// Note that drawings on the canvas are NOT persistent.
//	Canvas.CurX = UnitsOut;
//	Canvas.DrawText("HI");
//	UnitsOut++;
	Canvas.SetDrawColor(255,255,255);
	Canvas.SetPos(0,0);
	Canvas.SetPos(0,50);
	Canvas.DrawText("Faction:"@Self, false);

	Canvas.SetPos(0,65);
	Canvas.DrawText("FactionLocation:"@GetEnum(Enum'FactionLocation', Faction));

	Canvas.SetPos(Canvas.SizeX-150, 50);
	Canvas.DrawText("Budget:"@Budget);
	
	Canvas.SetPos(Canvas.SizeX-150, 65);
	Canvas.DrawText("UnitsOut:"@UnitsOut);

	Canvas.SetPos(0, 80);
	Canvas.DrawText("State:"@GetStateName());

	//@TODO - Let each state draw its own stuff.
	if(GetStateName() == 'CollectData')
	{
		Canvas.SetPos(0, 95);
		Canvas.DrawText("Orders Queued:"@OrderQueue.Length);
	}
}

function CalculateAllCosts()
{
	local int i;
	CheapestInfantry = UnitList.InfantryArchetypes[i];
	CheapestInfantry.GetPurchasableComponent(CheapestInfantry).CalculateCost(1);
	for(i = 1; i < UnitList.InfantryArchetypes.Length; i++)
	{
		UnitList.InfantryArchetypes[i].GetPurchasableComponent(UnitList.InfantryArchetypes[i]).CalculateCost(1);
		if(CheapestInfantry.GetCost(CheapestInfantry) > UnitList.InfantryArchetypes[i].GetCost(UnitList.InfantryArchetypes[i]))
		{
			CheapestInfantry = UnitList.InfantryArchetypes[i];
		}
	}
	CheapestTargetable = CheapestInfantry.GetCost(CheapestInfantry);
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

//@TODO - Private to force formation usage?
event TowerTargetable SpawnUnit(TowerTargetable UnitArchetype, TowerSpawnPoint SpawnPoint, const TroopInfo UnitTroopInfo)
{
	local Vector SpawnLocation;
	local TowerTargetable Targetable;

	SpawnLocation = GetSpawnLocation(UnitTroopInfo, SpawnPoint.Location, SpawnPoint.Rotation);
	SpawnLocation.Z += 100;
//	`log("SpawnLocation:"@SpawnLocation@"from SpawnPoint:"@SpawnPoint.Location@"rotation:"@SpawnPoint.Rotation);
	Targetable = UnitArchetype.CreateTargetable(UnitArchetype, SpawnLocation, Self);
	TowerEnemyPawn(Targetable).TeamIndex = TeamIndex;
	if(Targetable != None)
	{
		UnitsOut++;
	}
	return Targetable;
}

function int GetUnitCost(TowerTargetable UnitArchetype)
{

}

function CheckActivity()
{
//	`log(Self@"checking activity."@"UO:"$UnitsOut@"B:"$Budget@"CT:"$CheapestTargetable);
	// Check against minimum cost?
	//@TODO - Should be Budget < CheapestTargetable, or a special check to ask the AI if it wants to stay active.
	if(UnitsOut <= 0 && Budget <= CheapestTargetable)
	{
		Game.FactionInactive(Self);
	}
}

//function TowerSpawnPoint GetSpawnPoint()

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerBlock BlockKiller)
{
	//@TODO - Collect information about deaths so we can figure out what to counter.
	/*
	if(BlockKiller != None)
	{
		//@TODO
		// Award killing Tower points for kill.
		// Keep track of how much damage from each Tower so everyone gets points.
	}
	*/
	Targetable.GetDamageTracker().RewardFactions();
	UnitsOut--;
	CheckActivity();
}

event OnVIPDeath(TowerTargetable VIP)
{
}

DefaultProperties
{
	UnitList=TowerUnitsList'TowerMod.NullObjects.NullUnitsList'

	bPostRenderIfNotVisible=true

	RemoteRole=ROLE_None
	Begin Object Class=TowerFactionInfo Name=FactionInfo0
	End Object
	Components.Add(FactionInfo0)
	FactionInfo=FactionInfo0

	// Consider how to get this during AsyncWork.
	TickGroup=TG_PreAsyncWork
}