/**
TowerGame

Base game mode of Tower, will probably be extending in the future.
Right now this mode is leaning towards regular game with drop-in/drop-out co-op.
*/

class TowerGame extends FrameworkGame
	dependson(TowerMusicManager)
	config(Tower);

`define debugconfig `if(`isdefined(debug)) config `else `define debugconfig `endif
`define releasedefault x `if(`notdefined(debug)) x `else `define releasedefault `endif
`define GAMEINFO(dummy)
	`include(Tower\Classes\TowerStats.uci);
`undefine(GAMEINFO)

enum FactionLocation
{
	FL_None,
	FL_PosX,
	FL_NegX,
	FL_PosY,
	FL_NegY,
	FL_All
};

enum DifficultyLevel
{
	DL_Easy,
	DL_Normal,
	DL_Hard,
	DL_Impossible
};

struct ModCheck
{
	var String ModName;
	var byte MajorVersion, MinorVersion;
};

struct DifficultySettings
{
	var int BlockPriceMultiplier;
};

/** Used to compare to ?Mod= strings passed in during PreLogin(). Can be used after CheckForMods(). */
var array<ModCheck> LoadedMods;

var array<TowerFaction> Factions;
var TowerFactionAIHivemind Hivemind;
var TowerGameplayEventsWriter GameplayEventsWriter;
var byte FactionCount;
/** Number of factions that either have enemies alive or the capability to spawn more. */
var private byte RemainingActiveFactions;
var protected byte Round;
var privatewrite DifficultyLevel Difficulty;
var const config float CoolDownTime;
var const config array<String> FactionAIs;
var const config bool bLogGameplayEvents;
var const config float GameplayEventsHeartbeatDelta;

var array<TowerSpawnPoint> SpawnPoints; //,InfantryPoints, ProjectilePoints, VehiclePoints;

var globalconfig const bool bCheckClientMods;
`if(`notdefined(DEMO))
var globalconfig const array<String> ModPackages;
`endif
/** First element of the TowerModInfo linked list. This is always assumed to be TowerMod! */
var TowerModInfo RootMod;
/** Archetype to use for spawning the root blocks of towers. */
var TowerBlock RootArchetype;
/** Archetype to use for spawning air surrounding blocks. */
var TowerBlock AirArchetype;

/** The root TowerStart for the world, represents space (0,0,0) for GridLocations. Typically the first player's spot. */
var TowerStart RootTowerStart;

var bool bPendingLoad;
var string PendingLoadFile;

var const Vector Borders[4];

event PreBeginPlay()
{
	Super.PreBeginPlay();
	CheckForMods();
}

event PostBeginPlay()
{
//	local TowerModInfo ZMOd;
	Super.PostBeginPlay();
	if(bLogGameplayEvents)
	{
		GameplayEventsWriter = new(Self) class'TowerGameplayEventsWriter';
		GameplayEventsWriter.StartLogging(GameplayEventsHeartbeatDelta);
		`log("Gameplay logging enabled.");
		`RecordGameIntStat(MAX_EVENTID, 12345);
	}
	Hivemind = Spawn(class'TowerFactionAIHivemind');
	Hivemind.Initialize();
	PopulateSpawnPointArrays();
	CheckTowerStarts();
	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		class'Engine'.static.StopMovie(true);
	}
//	ZMod = Spawn(class'TowerModInfo',,,,,TowerModInfo(DynamicLoadObject("MyModd.ZModModInfo",class'TowerModInfo',false)));
//	StartNextRound();
}

event PreExit()
{
	if(GameplayEventsWriter != None)
	{
		GameplayEventsWriter.EndLogging();
	}
	`log("Shutting down!");
}

event InitGame(string Options, out string ErrorMessage)
{
	Super.InitGame(Options, ErrorMessage);
}

event PreLogin(string Options, string Address, out string ErrorMessage)
{
	`if(`notdefined(DEMO))
	//@TODO - Check mod list in Options.
	// New -> ModName|Major.Minor;OtherMod|Major.Minor
	// Tower|0.1;MyMod|1.0
	local int ModIndex;
	local byte MissingMods, OutdatedMods;//, OutdatedButUsableMods;
	local byte MajorVersion, MinorVersion;
	local TowerModInfo Mod;
	local String ModsList, VersionString;
	local array<String> ModNames;
	`endif
	Super.PreLogin(Options, Address, ErrorMessage);
	`if(`notdefined(DEMO))
	ModsList = ParseOption(Options, "Mods");
	ModNames = SplitString(ModsList, ";");
	if(bCheckClientMods)
	{
		`log("PreLogin:"@Options@Address@ErrorMessage,,'PreLogin');
		for(Mod = Rootmod; Mod != None; Mod = Mod.NextMod)
		{
			ModIndex = ModNames.Find(Mod.ModName);
			if(ModIndex == -1)
			{
				`log("Missing mod:"@Mod.ModName$"!",,'PreLogin');
				ErrorMessage $= "Mod missing:"$Mod.ModName@"Version:"$Mod.MajorVersion$"."$Mod.MinorVersion;
				MissingMods++;
			}
			else
			{
				VersionString = Right(ModNames[ModIndex], InStr(ModNames[ModIndex], "|"));
				MajorVersion = Byte(Left(VersionString, InStr(VersionString, ".")));
				MinorVersion = Byte(Right(VersionString, InStr(VersionString, ".")));
				if(MajorVersion == Mod.MajorVersion)
				{
					if(MinorVersion != Mod.MinorVersion)
					{
	//					OutdatedButUsableMods++;
					}
				}
				else
				{
					ErrorMessage $= "Mod outdated:"$Mod.ModName@"Your Version:"$MajorVersion$"."$MinorVersion@"Server Version:"$Mod.MajorVersion$"."$Mod.MinorVersion;
					OutdatedMods++;
				}
			}
		}
		if(MissingMods > 0 || OutdatedMods > 0)
		{
			`log("Player rejected.",,'PreLogin');
			ErrorMessage $= "Failed to join server! Missing"@MissingMods@"mods!"@OutdatedMods@"Mods outdated!";
		}
	}
	`endif
}

event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local string LoadString;
	LoadString = ParseOption(Options, "LoadGame");
//	`log("LoadString:"@LoadString);
	if(LoadString != "")
	{
		`log("Load from file:"@LoadString);
		bPendingLoad = true;
		PendingLoadFile = LoadString;
	}
	return super.Login(Portal, Options, UniqueID, ErrorMessage);
}

event PostLogin(PlayerController NewPlayer)
{
	Super.PostLogin(NewPlayer);
	//@TODO - Maybe not make this automatic?
	AddTower(TowerPlayerController(NewPlayer), !bPendingLoad);
	if(bPendingLoad)
	{
		if(!TowerPlayerController(NewPlayer).SaveSystem.LoadGame(PendingLoadFile, false, TowerPlayerController(NewPlayer)))
		{
			`log("Failed to load file"@"'"$PendingLoadFile$"' (Should have NO extension)! Does the file exist?"
				@"It might be from a previous version of save files that is no longer supported. If that's the case"
				@"there's no solution to it for now.",,'Error');
			`log("Continuing as a new game due to loading failure.",,'Loading');
			AddRootBlock(TowerPlayerController(NewPlayer));
		}
		bPendingLoad = false;
		PendingLoadFile = "";
	}
	//@TODO - bDelayedStart == true means RestartPlayer() isn't called for clients, so we do it here.
	if(NewPlayer.Pawn == None)
	{
		RestartPlayer(newPlayer);
	}
	if(!MatchIsInProgress())
	{
		StartMatch();
	}
}

function RestartPlayer(Controller NewPlayer)
{
	local Vector SpawnLocation;
	local Rotator SpawnRotation;
	if(TowerPlayerController(NewPlayer).SaveSystem.bLoaded)
	{
		SpawnLocation = TowerPlayerController(NewPlayer).SaveSystem.PlayerInfo.L;
		SpawnRotation = TowerPlayerController(NewPlayer).SaveSystem.PlayerInfo.R;
	}
	else
	{
		SpawnLocation = Vect(500,200,90);
	}
	if (NewPlayer.Pawn == None)
	{
		NewPlayer.Pawn = Spawn(DefaultPawnClass,,,SpawnLocation, SpawnRotation);
	}
	if (NewPlayer.Pawn == None)
	{
		`log("failed to spawn player at "/*$StartSpot*/);
		NewPlayer.GotoState('Dead');
		if ( PlayerController(NewPlayer) != None )
		{
			PlayerController(NewPlayer).ClientGotoState('Dead','Begin');
		}
	}
	else
	{
		NewPlayer.Possess(NewPlayer.Pawn, false);
		NewPlayer.ClientSetRotation(NewPlayer.Pawn.Rotation, TRUE);
		SetPlayerDefaults(NewPlayer.Pawn);
		NewPlayer.GotoState('PlayerFlying');
	}
	if( bRestartLevel && WorldInfo.NetMode!=NM_DedicatedServer && WorldInfo.NetMode!=NM_ListenServer )
	{
		`warn("bRestartLevel && !server, abort from RestartPlayer"@WorldInfo.NetMode);
		return;
	}
}

/** Modding:

*/

/** Called from PreBeginPlay. Loads any mods listed in the config file. */
final function CheckForMods()
{
	`if(`notdefined(DEMO))
	//@TODO - Convert package name to class name and such.
	local int i;
	local ModCheck Check;
	local TowerModInfo LoadedMod;

	local String ModPackage;
	local String ModInfoPath;
	`log("Number of listed mods:"@ModPackages.Length);
	foreach ModPackages(ModPackage, i)
	{
		`log("Loading Mod:"@ModPackage$"...");
		ModInfoPath = ModPackage$".ModInfo";
		LoadedMod = Spawn(class'TowerModInfo',,,,,TowerModInfo(DynamicLoadObject(ModInfoPath,class'TowerModInfo',false)));
		LoadedMod.PreInitialize(i);
		`log("Loaded Mod:"@LoadedMod@LoadedMod.AuthorName@LoadedMod.Contact@LoadedMod.Website@LoadedMod.Description@LoadedMod.MajorVersion$"."$LoadedMod.MinorVersion);
		if(RootMod == None)
		{
			RootMod = LoadedMod;
			TowerGameReplicationInfo(GameReplicationInfo).RootMod = RootMod;
			RootArchetype = RootMod.ModBlocks[0];
			AirArchetype = RootMod.ModBlocks[5];
		}
		else
		{
			RootMod.AddMod(LoadedMod);
		}
//		GameMods.AddItem(TMI);
	}
	`log("Number of loaded mods:"@RootMod.GetModCount());
	for(LoadedMod = RootMod; LoadedMod != None; LoadedMod = LoadedMod.NextMod)
	{
		Check.ModName = LoadedMod.ModName;
		Check.MajorVersion = LoadedMod.MajorVersion;
		Check.MinorVersion = LoadedMod.MinorVersion;
		LoadedMods.AddItem(Check);
	}
//	`log("ReplicatedModList:"@ReplicatedModList);
//	TowerGameReplicationInfo(GameReplicationInfo).ServerMods = ReplicatedModList;
	TowerGameReplicationInfo(GameReplicationInfo).ModCount = RootMod.GetModCount();
//	TowerGameReplicationInfo(GameReplicationInfo).AreModsLoaded();
	`else
	// Hardcode to only check for TowerMod since mods aren't supported in the demo.
	`endif
}

function PopulateSpawnPointArrays()
{
	local TowerSpawnPoint Point;
	foreach WorldInfo.AllNavigationPoints(class'TowerSpawnPoint', Point)
	{
		Point.Faction = GetPointFactionLocation(Point.Location);
		SpawnPoints.AddItem(Point);
	}
}

final function CheckTowerStarts()
{

}

/** Returns the FactionLocation that the given point is in.
Useful for determining who's land the Point is on. */
function FactionLocation GetPointFactionLocation(Vector Point)
{
	if(Point dot Borders[0] > 0)
	{
		// NegX or PosY.
		if(Point dot Borders[1] > 0)
		{
			return FL_PosY;
		}
		else if(Point dot Borders[3] > 0)
		{
			return FL_NegX;
		}
	}
	// PosX or NegY.
	else if(Point dot Borders[1] > 0)
	{
		return FL_PosX;
	}
	else if(Point dot Borders[3] > 0)
	{
		return FL_NegY;
	}
	ScriptTrace();
	`warn("Determined FactionLocation was FL_None for point:"@Point$"!");
	return FL_None;
}

function GenericPlayerInitialization(Controller C)
{
	local PlayerController PC;

	PC = PlayerController(C);
	if (PC != None)
	{
		// Keep track of the best host to migrate to in case of a disconnect
		UpdateBestNextHosts();

		// Notify the game that we can now be muted and mute others
		UpdateGameplayMuteList(PC);

		// tell client what hud class to use
		PC.ClientSetHUD(HudType);

		ReplicateStreamingStatus(PC);

		// see if we need to spawn a CoverReplicator for this player
		if (CoverReplicatorBase != None)
		{
			PC.SpawnCoverReplicator();
		}

		// Set the rich presence strings on the client (has to be done there)
		PC.ClientSetOnlineStatus();
	}

	if (BaseMutator != None)
	{
		BaseMutator.NotifyLogin(C);
	}
}

`if(`isdefined(DEBUG))
exec function DebugGetFactionLocation(Vector Point)
{
	`log(GetEnum(Enum'FactionLocation', GetPointFactionLocation(Point)));
}

exec function DebugKillAllTargetables()
{
	local Actor Targetable;
	foreach DynamicActors(class'Actor', Targetable, class'TowerTargetable')
	{
		Targetable.TakeDamage(999999, None, Vect(0,0,0), Vect(0,0,0), class'DmgType_Telefragged');
	}
//	GotoState('CoolDown');
}

/** Forces the server and all clients to play this index on their OverrideMusic list. */
exec function DebugServerMusicForcePlay(byte Index)
{
	local TowerPlayerController Controller;
	Controller = TowerPlayerController(GetALocalPlayerController());
	PlaySound(Controller.MusicManager.CurrentMusicList.OverrideMusic[Index], false, false, true);
}

exec function DebugServerMusicForceStop()
{

}

exec function DebugListSpawnPoints()
{
	local TowerSpawnPoint Point;
	local array<TowerSpawnPoint> PosX, NegX, PosY, NegY;
	foreach WorldInfo.AllNavigationPoints(class'TowerSpawnPoint', Point)
	{
		switch(Point.Faction)
		{
		case FL_PosX:
			PosX.AddItem(Point);
			break;
		case FL_PosY:
			PosY.AddItem(Point);
			break;
		case FL_NegX:
			NegX.AddItem(Point);
			break;
		case FL_NegY:
			NegY.AddItem(Point);
			break;
		default:
			`log(Point@"has no assigned faction!"@Point.Location);
			break;
		}
	}
	`log("=============================================================================");
	`log("FL_PosX Points:");
	foreach PosX(Point)
	{
		`log(Point@Point.Location);
	}
	`log("-----------------------------------------------------------------------------");
	`log("FL_PosY Points:");
	foreach PosY(Point)
	{
		`log(Point@Point.Location);
	}
	`log("-----------------------------------------------------------------------------");
	`log("FL_NegX Points:");
	foreach NegX(Point)
	{
		`log(Point@Point.Location);
	}
	`log("-----------------------------------------------------------------------------");
	`log("FL_NegY Points:");
	foreach NegY(Point)
	{
		`log(Point@Point.Location);
	}
	`log("=============================================================================");
}

exec function DebugKillAllRootBlocks()
{
	local TowerPlayerController Controller;
	foreach WorldInfo.AllControllers(class'TowerPlayerController', Controller)
	{
		Controller.GetTower().Root.TakeDamage(99999, Controller, Vect(0,0,0), Vect(0,0,0), class'DmgType_Telefragged');
	}
}

exec function DebugForceGarbageCollection(optional bool bFullPurge)
{
	WorldInfo.ForceGarbageCollection(bFullPurge);
}
`endif

exec function StartGame()
{
	StartMatch();
}

function StartMatch()
{
	local byte i;
	`log("StartMatch!");
	Super.StartMatch();
	AddFactionHuman(0);
	//;PosX, PosY, NegX, NegY
	//@TODO
	for(i = 0; i < 4 && i+1 <= FactionAIs.length; i++)
	{
		AddFactionAI(5+i, TowerFactionAI(DynamicLoadObject(FactionAIs[i], class'TowerFactionAI', true)), FactionLocation(1+i));
	}
	GotoState('CoolDown');
}

function AddFactionAI(int TeamIndex, TowerFactionAI Archetype, FactionLocation Faction)
{
	local array<TowerSpawnPoint> FactionSpawnPoints;
	local TowerSpawnPoint Point;
	// Fill an array of spawn points for the AI.
	foreach SpawnPoints(Point)
	{
		if(Point.Faction == Faction)
		{
			FactionSpawnPoints.AddItem(Point);
		}
	}
	Factions[TeamIndex] = Spawn(Archetype.class,,,,,Archetype);
	Factions[TeamIndex].TeamIndex = TeamIndex;
	TowerFactionAI(Factions[TeamIndex]).Hivemind = HiveMind;
	TowerFactionAI(Factions[TeamIndex]).Faction = FactionLocation(Faction);
	TowerFactionAI(Factions[TeamIndex]).ReceiveSpawnPoints(FactionSpawnPoints);
	FactionCount++;
	GameReplicationInfo.SetTeam(TeamIndex, Factions[TeamIndex]);
}

function AddFactionHuman(int TeamIndex)
{
	Factions[TeamIndex] = Spawn(class'TowerFactionHuman');
	Factions[TeamIndex].TeamIndex = TeamIndex;
	FactionCount++;
	GameReplicationInfo.SetTeam(TeamIndex, Factions[TeamIndex]);
}

//@TODO - Need Tower, not TPRI.
function AddTower(TowerPlayerController Player, bool bAddRootBlock, optional string TowerName="")
{
	local TowerPlayerReplicationInfo TPRI;
	
	TPRI = TowerPlayerReplicationInfo(Player.PlayerReplicationInfo);
	TPRI.Tower = Spawn(class'Tower', self);
	TPRI.Tower.OwnerPRI = TPRI;
	// Initial budget!
	//@FIXME
	TPRI.Tower.Budget = 99999;
//	TPRI.Tower.Initialize(TPRI);
	if(bAddRootBlock)
	{
		AddRootBlock(Player);
	}
//	AddBlock(TPRI.Tower, class'TowerModInfo_Tower'.default.ModBlockInfo[0], None, GridLocation, true);
	if(TowerName != "")
	{
		SetTowerName(TPRI.Tower, TowerName);
	}
	TPRI.Tower.Initialize();
}

//@TODO - Need Tower, not TPRI.
function AddRootBlock(TowerPlayerController Player)
{
	local IVector GridLocation;
	// Need to make this dependent on player count in future.
	//@FIXME - This can be done a bit more cleanly and safely. Define in map maybe?
	GridLocation.X = 4*(NumPlayers-1);
	
	TowerPlayerReplicationInfo(Player.PlayerReplicationInfo).Tower
		.SetRootBlock(TowerBlockRoot(AddBlock(TowerPlayerReplicationInfo(Player.PlayerReplicationInfo).Tower, RootArchetype, None, GridLocation)));
	//@FIXME - Have Root do this by itself?
	Hivemind.OnRootBlockSpawn(TowerPlayerReplicationInfo(Player.PlayerReplicationInfo).Tower.Root);
}

function SetTowerName(Tower Tower, string NewTowerName)
{
	Tower.TowerName = NewTowerName;
}

event FactionInactive(TowerFactionAI Faction)
{
	`warn("FactionInactive called when not in RoundInProgress!");
}

function bool IsRoundInProgress()
{
	`log("RoundInProgress called outside proper states!"@GetStateName());
	return false;
}

state CoolDown
{
	event BeginState(Name PreviousStateName)
	{
		SetTimer(CoolDownTime, false);
		TowerGameReplicationInfo(GameReplicationInfo).CheckRoundInProgress();
	}

	event Timer()
	{
		GotoState('RoundInProgress');
	}

	function bool IsRoundInProgress()
	{
		return false;
	}
}

state RoundInProgress
{
	event BeginState(Name PreviousStateName)
	{
		local TowerFaction Faction;
		local int BudgetPerFaction;
		TowerGameReplicationInfo(GameReplicationInfo).CheckRoundInProgress();
		IncrementRound();
		CalculateRemainingActiveFactions();
		SendMusicEvent(ME_StartRound);
		//@FIXME - Remove +1
		BudgetPerFaction = 50 / (GetFactionAICount()+1);
		foreach Factions(Faction)
		{
			if(TowerFactionAI(Faction) != None)
			{
				TowerFactionAI(Faction).RoundStarted(BudgetPerFaction);
			}
		}
	}

	/** Increments the round number and sends it all PlayerControllers. */
	function IncrementRound()
	{
		Round++;
		TowerGameReplicationInfo(GameReplicationInfo).Round = Round;
		// Force update Round for the server since it won't get replicated to it.
		TowerGameReplicationInfo(GameReplicationInfo).ReplicatedEvent('Round');
	}

	/** */
	event FactionInactive(TowerFactionAI Faction)
	{
		`log(Faction@"is now inactive. RemainingActiveFactions:"@RemainingActiveFactions,,'Round');
		RemainingActiveFactions--;
		TriggerGlobalEventClass(class'SeqEvent_FactionInactive', Faction, 0);
		if(RemainingActiveFactions <= 0)
		{
			`log("No more active factions, cooling down!",,'Round');
			GotoState('CoolDown');
		}
	}

	event EndState(Name NextStateName)
	{
		local TowerFaction Faction;
		foreach Factions(Faction)
		{
			if(TowerFactionAI(Faction) != None)
			{
				TowerFactionAI(Faction).RoundEnded();
			}
		}
	}

	function bool IsRoundInProgress()
	{
		return true;
	}
}

function SendMusicEvent(MusicEvent Event)
{
	TowerGameReplicationInfo(GameReplicationInfo).MusicEvent = Event;
	TowergameReplicationInfo(GameReplicationInfo).ReplicatedEvent('MusicEvent');
}

function byte GetFactionAICount()
{
	local TowerFaction Faction;
	local byte Count;
	foreach Factions(Faction)
	{
		if(TowerFactionAI(Faction) != None)
		{
			Count++;
		}
	}
	return Count;
}

function CalculateRemainingActiveFactions()
{
	RemainingActiveFactions = GetFactionAICount();
}

function TowerBlock AddBlock(Tower Tower, TowerBlock BlockArchetype, TowerBlock Parent, 
	out IVector GridLocation)
{
	local Vector SpawnLocation;
	local TowerBlock Block;
	SpawnLocation = GridLocationToVector(GridLocation);
	// Pivot point in middle, bump up.
	SpawnLocation.Z += 128;
	`assert(BlockArchetype != None);
	if(CanAddBlock(GridLocation, Parent))
	{
		Block = Tower.AddBlock(BlockArchetype, Parent, SpawnLocation, GridLocation);
		if(Block != None)
		{
			`RecordGamePositionStat(PLAYER_SPAWNED_BLOCK, SpawnLocation, 5);
		}
	}
	return Block;
}

function RemoveBlock(Tower Tower, TowerBlock Block)
{
	Tower.RemoveBlock(Block);
}

/** Returns TRUE if GridLocation is on the grid and there's no Unstable blocks currently falling into GridLocation. */
function bool CanAddBlock(out const IVector GridLocation, TowerBlock Parent)
{
	return (IsGridLocationOnGrid(GridLocation) && (Parent == None || !IsBlockFallingOntoBlock(GridLocation, Parent)));
}

static function Vector GridLocationToVector(out const IVector GridLocation, optional class<TowerBlock> BlockClass)
{
	local Vector NewBlockLocation;
	//@FIXME: Block dimensions. Constant? At least have a constant, traceable part?
	NewBlockLocation.X = (GridLocation.X * 256);
	NewBlockLocation.Y = (GridLocation.Y * 256);
	NewBlockLocation.Z = (GridLocation.Z * 256);
	//@TODO - Are we doing this here or what?
	// Pivot point in middle, bump it up.
//	NewBlockLocation.Z += 128;
	return NewBlockLocation;
}

/** Returns TRUE if the GridLocation is inside the bounds specified in TowerMapInfo. */
function bool IsGridLocationOnGrid(out const IVector GridLocation)
{
	local int MapXBlocks; 
	local int MapYBlocks; 
	local int MapZBlocks;
	MapXBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).XBlocks;
	MapYBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).YBlocks;
	MapZBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).ZBlocks;
	return	((GridLocation.X <= MapXBlocks/2 && GridLocation.X >= -MapXBlocks/2) && 
			(GridLocation.Y <= MapYBlocks/2 && GridLocation.Y >= -MapYBlocks/2) &&
			(GridLocation.Z <= MapZBlocks/2 && GridLocation.Z >= -MapZBlocks/2));
}

/** Returns TRUE if there are any Unstable blocks in the process of falling into TestGridLocation. */
function bool IsBlockFallingOntoBlock(out const IVector TestGridLocation, TowerBlock Block)
{
	local TowerBlock IteratorBlock;
	local Vector HitLocation, HitNormal, Extent, Start, End;

	Start = Block.Location;
	Start.Z -= 128;

	End = Start;
	End.Z += 512;

	Extent = Vect(384, 384, 0);

	foreach TraceActors(class'TowerBlock', IteratorBlock, HitLocation, HitNormal, End, Start, Extent)
	{
		if(IteratorBlock.IsInState('Unstable') || IteratorBlock.IsChildState(IteratorBlock.GetStateName(), 'Unstable'))
		{
			if(IteratorBlock.GridLocation - Vect(0,0,1) == TestGridLocation)
			{
				return true;
			}
		}
	}
	return false;
}

function int GetRemainingTime()
{
	return (GetTimerRate('GameTimerExpired') - GetTimerCount('GameTimerExpired')+1);
}

DefaultProperties
{
	MaxPlayersAllowed=4
	PlayerControllerClass=class'Tower.TowerPlayerController'
	PlayerReplicationInfoClass=class'Tower.TowerPlayerReplicationInfo'
	GameReplicationInfoClass=class'Tower.TowerGameReplicationInfo'
	DefaultPawnClass=class'Tower.TowerPlayerPawn'
	HUDType=class'Tower.TowerHUD'

	Borders[0]=(X=-1,Y=1,Z=0)
	Borders[1]=(X=1,Y=1,Z=0)
	Borders[2]=(X=1,Y=-1,Z=0)
	Borders[3]=(X=-1,Y=-1,Z=0)
}