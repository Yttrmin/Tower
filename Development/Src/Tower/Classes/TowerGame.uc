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
	FL_NegY
};

var array<TowerFactionAI> FactionAIs;
var array<TowerSpawnPoint> SpawnPoints; //,InfantryPoints, ProjectilePoints, VehiclePoints;
var array<TowerModInfo> GameMods;

var array<TowerModInfo> Mods;
var config const array<String> ModPackages;
var TowerCrowdSpawner CrowdSpawner;

var TowerFactionAIHivemind Hivemind;

/** Number of factions that either have enemies alive or the capability to spawn more. */
var protected byte RemainingActiveFactions;

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
	Hivemind = new class'TowerFactionAIHivemind';
	Hivemind.Initialize();
	PopulateSpawnPointArrays();
	`log("PRI Count:"@GameReplicationInfo.PRIArray.Length);
	CrowdSpawner = new class'TowerCrowdSpawner';
//	TowerGameViewportClient(class'Engine'.static.GetEngine().GameViewport).
	class'Engine'.static.StopMovie(true);
	`log(RTransform(Rot(0,16384,0), Rot(0,32768,0)));
//	ZMod = Spawn(class'TowerModInfo',,,,,TowerModInfo(DynamicLoadObject("MyModd.ZModModInfo",class'TowerModInfo',false)));
//	`log("ZMod:"@ZMod@ZMod.ModName);
//	ZMod.TestCallMe();
	/*
	class'Engine'.static.GetFacebookIntegration().UserID = "1637497802";
	class'Engine'.static.GetFacebookIntegration().AppID = "195347980485261";
	class'Engine'.static.GetFacebookIntegration().AddAuthorizationCompleteDelegate(OnAuthorizationComplete);
	class'Engine'.static.GetFacebookIntegration().AddFacebookRequestCompleteDelegate(OnFacebookRequestComplete);
	class'Engine'.static.GetFacebookIntegration().AddWebRequestCompleteDelegate(OnWebRequestComplete);
	class'Engine'.static.GetFacebookIntegration().Init();
	class'Engine'.static.GetFacebookIntegration().Authorize();*/
	//1637497802
//	StartNextRound();
}

event PreExit()
{
	`log("Shutting down!");
}

function OnAuthorizationComplete(bool bSucceeded)
{
	`log("Facebook Authorization Complete. Result:"@bSucceeded);
	class'Engine'.static.GetFacebookIntegration().FacebookRequest("me/friends");
}

function OnFacebookRequestComplete(string JsonString)
{
	`log("OnFacebookRequestComplete:"@JSonString);
}

function OnWebRequestComplete(string Response)
{
	`log("OnWebRequestComplete:"@Response);
}

event InitGame(string Options, out string ErrorMessage)
{
	Super.InitGame(Options, ErrorMessage);
}

event PreLogin(string Options, string Address, out string ErrorMessage)
{
	//@TODO - Check mod list in Options.
	// Tower|0.1;MyMod|1.0
	local int i;
	local TowerModInfo Mod;
	local String ModsList;
	local array<String> ModNames;

	local array<TowerModInfo> MissingMods;

	ModsList = ParseOption(Options, "Mods");
	ModNames = SplitString(ModsList);
	foreach GameMods(Mod)
	{
		if(ModNames.Find(Mod.ModName$Mod.Version) == -1)
		{
			MissingMods.AddItem(Mod);
		}
	}
	if(MissingMods.Length > 0)
	{
		ErrorMessage $= "Missing mods: ";
		foreach MissingMods(Mod, i)
		{
			if(i > 0)
			{
				ErrorMessage $= ", ";
			}
			ErrorMessage $= Mod.ModName$"("$Mod.Version$")";
		}
		ErrorMessage $= ". Can't join server!";
	}
	Super.PreLogin(Options, Address, ErrorMessage);
}

event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local PlayerController NewPlayer;
	NewPlayer = super.Login(Portal, Options, UniqueID, ErrorMessage);
//	TowerPlayerController(NewPlayer).SetModCount(24);
	//TowerPlayerController(NewPlayer).GotoState('Master');
	return NewPlayer;
}

event PostLogin(PlayerController NewPlayer)
{
	Super.PostLogin(NewPlayer);
	//@TODO - Maybe not make this automatic?
	AddTower(TowerPlayerController(NewPlayer));
}

//Mods.AddItem(TowerModInfo(DynamicLoadObject("TowerMod.ModInfo", class'TowerModInfo', false)));

function CheckForMods()
{
	//@TODO - Convert package name to class name and such.
	local int i;
	local TowerModInfo Mod;
//	local String ReplicatedModList;

	local String TMIClass;
	local String ModInfoPath;
	local TowerModInfo TMI;
	`log("LOADING MODS");
	`log("GameMods:"@GameMods.Length);
	foreach ModPackages(TMIClass, i)
	{
		`log("LOADING MOD:"@TMIClass);
		ModInfoPath = TMIClass$".ModInfo";
		TMI = Spawn(class'TowerModInfo',,,,,TowerModInfo(DynamicLoadObject(ModInfoPath,class'TowerModInfo',false)));
//		Spawn(class'TowerBlockDebug',,,,,TowerBlockDebug(DynamicLoadObject("TowerMod.TestBlock",class'TowerBlockDebug',false)));
		`log("SPANWED"@TMI);
//		`log("MOD CLASS:"@ModInfo);
//		TMI = Spawn(ModInfo);
		TMI.PreInitialize(i);
		`log("MOD INFO:"@TMI@TMI.AuthorName@TMI.Description@TMI.Version);
		GameMods.AddItem(TMI);
		if(i == 0)
		{
			TowerGameReplicationInfo(GameReplicationInfo).RootMod = GameMods[0];
		}
		else
		{
			TowerGameReplicationInfo(GameReplicationInfo).RootMod.AddMod(GameMods[GameMods.Length-1]);
		}
	}
	`log("GameMods:"@GameMods.Length);
	foreach GameMods(Mod, i)
	{
		if(i > 0)
		{
//			ReplicatedModList $= ";";
		}
//		ReplicatedModList $= Mod.ModName;
	}
//	`log("ReplicatedModList:"@ReplicatedModList);
//	TowerGameReplicationInfo(GameReplicationInfo).ServerMods = ReplicatedModList;
	TowerGameReplicationInfo(GameReplicationInfo).ModCount = GameMods.Length;
//	TowerGameReplicationInfo(GameReplicationInfo).AreModsLoaded();
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

exec function DebugGetFactionLocation(Vector Point)
{
	`log(GetEnum(Enum'FactionLocation', GetPointFactionLocation(Point)));
}

exec function LaunchMissile()
{

}

exec function StartGame()
{
	StartMatch();
}

function StartMatch()
{
//	local int i;
	`log("StartMatch!");
	Super.StartMatch();
	AddFactionAIs();
//	CrowdSpawner.CreateNewAgent(InfantryPoints[0], 
//		GameCrowdAgent(CrowdSpawner.AgentArchetypes[0].AgentArchetype), New(None) class'GameCrowdGroup');
//	for(i = 0; i < 200; i++)
//		CrowdSpawner.SpawnAgent(InfantryPoints[0]);
//	Agent.CurrentDestination = InfantryPoints[0].NextDestinations[0];
	StartCoolDown();
}

//
// Restart a player.
//
function RestartPlayer(Controller NewPlayer)
{
	if( bRestartLevel && WorldInfo.NetMode!=NM_DedicatedServer && WorldInfo.NetMode!=NM_ListenServer )
	{
		`warn("bRestartLevel && !server, abort from RestartPlayer"@WorldInfo.NetMode);
		return;
	}
}

exec function SkipRound()
{
	ClearTimer('GameTimerExpired');
	GameTimerExpired(); 
}

function AddFactionAIs()
{
	local int i;
	local array<TowerSpawnPoint> FactionSpawnPoints;
	local TowerSpawnPoint Point;
	local byte AssignedFaction;
	AssignedFaction = FL_NegX;
	for(i = 0; i < 1/*4*/; i++)
	{
		// Empty the array each iteration so we don't give the Faction points it doesn't own.
		FactionSpawnPoints.Remove(0, SpawnPoints.Length);
		// Fill an array of spawn points for the AI.
		foreach SpawnPoints(Point)
		{
			if(Point.Faction == AssignedFaction)
			{
				FactionSpawnPoints.AddItem(Point);
			}
		}
		`log("SpawnPoints for faction:"@FactionSpawnPoints.Length);
		FactionAIs.AddItem(Spawn(GameMods[0].ModFactionAIs[0].class,,,,,GameMods[0].ModFactionAIs[0]));
		FactionAIs[FactionAIs.Length-1].Hivemind = Hivemind;
		FactionAIs[FactionAIs.Length-1].Faction = FactionLocation(AssignedFaction);
		FactionAIs[FactionAIs.Length-1].ReceiveSpawnPoints(FactionSpawnPoints);
		AssignedFaction++;
		`log("Spawned AI?:"@FactionAIs[0]);
	}
}

/** Very first part of a game, and happens between every round. */
function StartCoolDown()
{
	`log("Starting 5 second cooldown round!");
	SetCoolDownTimer(5);
}

function StartNextRound()
{
	local TowerFactionAI Faction;
	local int BudgetPerFaction;
	TowerGameReplicationInfo(GameReplicationInfo).NextRound();
	//SetGameTimer(120);
	BudgetPerFaction = TowerGameReplicationInfo(GameReplicationInfo).MaxEnemyCount / FactionAIs.Length;
	foreach FactionAIs(Faction)
	{
		Faction.RoundStarted(BudgetPerFaction);
	}
}

function SetCoolDownTimer(float NewTime)
{
	SetTimer(NewTime, false, 'CoolDownTimerExpired');
	TowerGameReplicationInfo(WorldInfo.GRI).ReplicatedTime = NewTime;
	TowerGameReplicationInfo(WorldInfo.GRI).SetGameTimer();
}

event CoolDownTimerExpired()
{
	`log("Cool down over");
	StartNextRound();
}

function SetGameTimer(float NewTime)
{
	`log("Started"@NewTime@"second round.");
	SetTimer(NewTime, false, 'GameTimerExpired');
	TowerGameReplicationInfo(WorldInfo.GRI).ReplicatedTime = NewTime;
	TowerGameReplicationInfo(WorldInfo.GRI).SetGameTimer();
}

event GameTimerExpired()
{
	`log("Round over.");
	TowerGameReplicationInfo(WorldInfo.GRI).EndRound();
	StartCoolDown();
}

/** */
event FactionInactive(TowerFactionAI Faction)
{
	RemainingActiveFactions--;
	if(RemainingActiveFactions <= 0)
	{
	}
}

function AddTower(TowerPlayerController Player,  optional string TowerName="")
{
	local TowerPlayerReplicationInfo TPRI;
	local TowerPlaceable Root;
	local TowerBlockRoot BlockRoot;
	local IVector GridLocation;
	TPRI = TowerPlayerReplicationInfo(Player.PlayerReplicationInfo);
	//@BUG
	// For whatever reason PlayerController won't collide with children, so we're breaking
	// the ownership chain right here. There's probably a flag for child collision but
	// I can't find it.
	TPRI.Tower = Spawn(class'Tower');
	TPRI.Tower.OwnerPRI = TPRI;
//	TPRI.Tower.Initialize(TPRI);
	// Need to make this dependent on player count in future.
	//@FIXME - This can be done a bit more cleanly and safely. Define in map maybe?
	GridLocation.X = 8*(NumPlayers-1);
	Root = AddPlaceable(TPRI.Tower, GameMods[0].ModPlaceables[0], None, GridLocation);
	TPRI.Tower.Root = TowerBlockRoot(Root);
	Hivemind.OnRootBlockSpawn(TowerBlockRoot(Root));
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

function TowerPlaceable AddPlaceable(Tower Tower, TowerPlaceable Placeable, TowerBlock Parent, 
	out IVector GridLocation)
{
	local Vector SpawnLocation;
	local Vector VectorGridLocation;
	VectorGridLocation = ToVect(GridLocation);
	SpawnLocation = GridLocationToVector(VectorGridLocation);
	// Pivot point in middle, bump up.
//	SpawnLocation.Z += 128;
	`assert(Placeable != None);
	if(CanAddBlock(VectorGridLocation))
	{
		return Tower.AddPlaceable(Placeable, Parent, SpawnLocation, GridLocation);
	}
	else
	{
		return None;
	}
}

function RemovePlaceable(Tower Tower, TowerPlaceable Placeable)
{
	Tower.RemovePlaceable(Placeable);
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
	NewBlockLocation.Z += 128;
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
	DefaultPawnClass=class'Tower.TowerPawn'
	HUDType=class'Tower.TowerHUD'

	Borders[0]=(X=-1,Y=1,Z=0)
	Borders[1]=(X=1,Y=1,Z=0)
	Borders[2]=(X=1,Y=-1,Z=0)
	Borders[3]=(X=-1,Y=-1,Z=0)
}