/**
TowerGame

Base game mode of Tower, will probably be extending in the future.
Right now this mode is leaning towards regular game with drop-in/drop-out co-op.
*/

class TowerGame extends FrameworkGame
	config(Tower);

enum FactionLocation
{
	FL_None,
	FL_PosX,
	FL_NegX,
	FL_PosY,
	FL_NegY,
	FL_All
};

struct ModCheck
{
	var String ModName;
	var byte MajorVersion, MinorVersion;
};

/** Used to compare to ?Mod= strings passed in during PreLogin(). Can be used after CheckForMods(). */
var array<ModCheck> LoadedMods;

var array<TowerFaction> Factions;
var TowerFactionAIHivemind Hivemind;
var byte FactionCount;
/** Number of factions that either have enemies alive or the capability to spawn more. */
var protected byte RemainingActiveFactions;
var protected byte Round;

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
	Hivemind = Spawn(class'TowerFactionAIHivemind');
	Hivemind.Initialize();
	PopulateSpawnPointArrays();
	CheckTowerStarts();
	class'Engine'.static.StopMovie(true);
//	ZMod = Spawn(class'TowerModInfo',,,,,TowerModInfo(DynamicLoadObject("MyModd.ZModModInfo",class'TowerModInfo',false)));
//	StartNextRound();
}

event PreExit()
{
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
	`log("LoadString:"@LoadString);
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
		TowerPlayerController(NewPlayer).SaveSystem.LoadGame(PendingLoadFile, false, TowerPlayerController(NewPlayer));
	}
	if(!MatchIsInProgress())
	{
		StartMatch();
	}
	TowerPlayerController(NewPlayer).UpdateRoundNumber(Round);
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
`endif

exec function StartGame()
{
	StartMatch();
}

function StartMatch()
{
//	local int i;
	`log("StartMatch!");
	Super.StartMatch();
	AddFactionHuman(0);
	AddFactionAI(5, RootMod.ModFactionAIs[1], FL_NegX);
	RemainingActiveFactions = GetFactionCount() - 1;
	GotoState('CoolDown');
}

final function byte GetFactionCount()
{
	local byte Count;
	local int i;
	for(i = 0; i < Factions.Length; i++)
	{
		if(Factions[i] != None)
		{
			Count++;
		}
	}
	return Count;
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
		SetTimer(5, false);
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
		BudgetPerFaction = 50 / GetFactionCount();
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
		local TowerPlayerController PC;
		Round++;
		foreach LocalPlayerControllers(class'TowerPlayerController', PC)
		{
			PC.UpdateRoundNumber(Round);
		}
	}

	/** */
	event FactionInactive(TowerFactionAI Faction)
	{
		RemainingActiveFactions--;
		if(RemainingActiveFactions <= 0)
		{
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

//
// Restart a player.
//
function RestartPlayer(Controller NewPlayer)
{
	if (NewPlayer.Pawn == None)
	{
		NewPlayer.Pawn = Spawn(DefaultPawnClass,,,Vect(500, 200, 90));
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

}

exec function DebugServerMusicForceStop()
{

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

function AddTower(TowerPlayerController Player, bool bAddRootBlock,  optional string TowerName="")
{
	local TowerPlayerReplicationInfo TPRI;
	local IVector GridLocation;
	TPRI = TowerPlayerReplicationInfo(Player.PlayerReplicationInfo);
	TPRI.Tower = Spawn(class'Tower', self);
	TPRI.Tower.OwnerPRI = TPRI;
	// Initial budget!
	TPRI.Tower.Budget = 50;
//	TPRI.Tower.Initialize(TPRI);
	if(bAddRootBlock)
	{
		// Need to make this dependent on player count in future.
		//@FIXME - This can be done a bit more cleanly and safely. Define in map maybe?
		GridLocation.X = 8*(NumPlayers-1);
	
		TPRI.Tower.Root = TowerBlockRoot(AddBlock(TPRI.Tower, RootArchetype, None, GridLocation));
		//@FIXME - Have Root do this by itself?
		Hivemind.OnRootBlockSpawn(TPRI.Tower.Root);
	}
//	AddBlock(TPRI.Tower, class'TowerModInfo_Tower'.default.ModBlockInfo[0], None, GridLocation, true);
	if(TowerName != "")
	{
		SetTowerName(TPRI.Tower, TowerName);
	}
}

function SetTowerName(Tower Tower, string NewTowerName)
{
	Tower.TowerName = NewTowerName;
}

function TowerBlock AddBlock(Tower Tower, TowerBlock BlockArchetype, TowerBlock Parent, 
	out IVector GridLocation)
{
	local Vector SpawnLocation;
	local Vector VectorGridLocation;
	VectorGridLocation = ToVect(GridLocation);
	SpawnLocation = GridLocationToVector(VectorGridLocation);
	// Pivot point in middle, bump up.
	SpawnLocation.Z += 128;
	`assert(BlockArchetype != None);
	if(CanAddBlock(VectorGridLocation))
	{
		return Tower.AddBlock(BlockArchetype, Parent, SpawnLocation, GridLocation);
	}
	else
	{
		return None;
	}
}

function RemoveBlock(Tower Tower, TowerBlock Block)
{
	Tower.RemoveBlock(Block);
}

function bool CanAddBlock(out Vector GridLocation)
{
	return (IsGridLocationFree(GridLocation) && IsGridLocationOnGrid(GridLocation));
}

static function Vector GridLocationToVector(out Vector GridLocation, optional class<TowerBlock> BlockClass)
{
//	local int MapBlockWidth, MapBlockHeight;
	local Vector NewBlockLocation;
//	MapBlockHeight = TowerMapInfo(WorldInfo.GetMapInfo()).BlockHeight;
//	MapBlockWidth = TowerMapInfo(WorldInfo.GetMapInfo()).BlockWidth;
	//@FIXME: Block dimensions. Constant? At least have a constant, traceable part?
	NewBlockLocation.X = (GridLocation.X * 256);
	NewBlockLocation.Y = (GridLocation.Y * 256);
	// Z is the very bottom of the block.
	NewBlockLocation.Z = (GridLocation.Z * 256);
	// Pivot point in middle, bump it up.
//	NewBlockLocation.Z += 128;
	return NewBlockLocation;
}

function bool IsGridLocationOnGrid(out Vector GridLocation)
{
	local int MapXBlocks; 
	local int MapYBlocks; 
	local int MapZBlocks;
	MapXBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).XBlocks;
	MapYBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).YBlocks;
	MapZBlocks = TowerMapInfo(WorldInfo.GetMapInfo()).ZBlocks;
	if((GridLocation.X <= MapXBlocks/2 && GridLocation.X >= -MapXBlocks/2) && 
		(GridLocation.Y <= MapYBlocks/2 && GridLocation.Y >= -MapYBlocks/2) &&
		(GridLocation.Z <= MapZBlocks/2 && GridLocation.Z >= -MapZBlocks/2))
	{
		return true;
	}
	else
	{
		return false;
	}
}

function bool IsGridLocationFree(out Vector GridLocation)
{
	return true;
}

function TowerBlock GetBlockFromGrid(int XBlock, int YBlock, int ZBlock, out int BlockIndex)
{
	/*
	// Seriously need a helper function to make grid vectors, or at least make all XBlocks etc into vectors.
	local Vector GridLocation;
	local TowerBlock Block;
	local PlayerReplicationInfo PRI;
	local TowerPlayerReplicationInfo TPRI;

	GridLocation.X = XBlock;
	GridLocation.Y = YBlock;
	GridLocation.Z = ZBlock;
	foreach GameReplicationInfo.PRIArray(PRI)
	{
		TPRI = TowerPlayerReplicationInfo(PRI);
		foreach TPRI.Tower.Blocks(Block, BlockIndex)
		{
			if(Block.GridLocation == GridLocation)
			{
				return Block;
			}
		}
	}
	*/
	return None;
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