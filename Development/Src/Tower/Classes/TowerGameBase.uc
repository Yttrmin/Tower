class TowerGameBase extends FrameworkGame
	Config(Tower);

enum FactionLocation
{
	FL_None,
	FL_PosX,
	FL_NegX,
	FL_PosY,
	FL_NegY,
	FL_All
};

/** If TRUE, PreLogin checks the mods string before letting clients join. */
var private globalconfig const bool bCheckClientMods;
`if(`notdefined(DEMO))
var privatewrite globalconfig const array<String> ModPackages;
`endif
/** First element of the TowerModInfo linked list. This is always assumed to be TowerMod! */
var privatewrite TowerModInfo RootMod;
/** Archetype to use for spawning the root blocks of towers. */
var privatewrite TowerBlock RootArchetype;
/** Archetype to use for spawning air surrounding blocks. */
var privatewrite TowerBlock AirArchetype;

//@TODO - Decouple loading from Tower/TowerGame. Make these private.
var protected bool bPendingLoad;
var protected string PendingLoadFile;

var private globalconfig const string DedicatedServerLoadFile;
var protected globalconfig const bool bAIGame;
var private globalconfig const bool bResetLevelOnEmptyServer;
var private globalconfig const bool bPauseLevelOnEmptyServer;
var private Tower DedicatedServerTower;

var privatewrite TowerFactionAIHivemind Hivemind;
var privatewrite AirManager AirManager;

var private array<delegate<TickDelegate> > ToTick;

var const Vector Borders[4];
var privatewrite Vector GridOrigin;
var privatewrite TowerStart TowerStarts[4];

/** Sits between a version number and different mod's name in a mod list. Guaranteed that no packages use this character. */
const MOD_DIVIDER = "|";
/** Sits between a mod's name and its version number in a mod list. Guaranteed that no packages use this character. */
const VERSION_DIVIDER = "=";
const ROOT_BLOCK_INDEX = 0;
const AIR_BLOCK_INDEX = 6;

delegate TickDelegate(float DeltaTime);

event PreBeginPlay()
{
	Super.PreBeginPlay();
	TowerMapInfo(WorldInfo.GetMapInfo()).Initialize();
	DetermineTowerStarts();
	CheckForMods();
	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		WorldInfo.MyFractureManager.Destroy();
	}
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	Hivemind = Spawn(class'TowerFactionAIHivemind');
	Hivemind.Initialize();
	AirManager = Spawn(class'AirManager');
	if(WorldInfo.NetMode == NM_DedicatedServer)
	{
		`log("Starting NM_DedicatedServer game. LoadFile:"@DedicatedServerLoadFile);
		if(DedicatedServerLoadFile != "")
		{
			bPendingLoad = true;
			PendingLoadFile = DedicatedServerLoadFile;
		}
	}
}

private function LogStringArray(out array<String> StrArray, String Category)
{
	local String Output;
	local String Temp;
	local int i;
	Output @= "\n";
	foreach StrArray(Temp, i)
	{
		Output @= i$":"@StrArray[i]$"\n";
	}
	`log(Output,,Name(Category));
}

event InitGame( string Options, out string ErrorMessage )
{
	Super.InitGame(Options, ErrorMessage);
	//@TODO - Loading here, not the Login functions.
}

/** Only called for joining clients in network games. */
event PreLogin(string Options, string Address, const UniqueNetId UniqueId, bool bSupportsAuth, out string ErrorMessage)
{
	`if(`notdefined(DEMO))
	//@TODO - Check mod list in Options.
	// New -> ModName|Major.Minor;OtherMod|Major.Minor
	// Tower|0.1;MyMod|1.0 - Old.
	// Tower=0.1|MyMod=1.0 - New
	local int ModIndex;
	local byte MissingMods, OutdatedMods;//, OutdatedButUsableMods;
	local TowerModInfo Mod;
	local String ModsList;
	local int Version;
	local array<String> ModNames;
	`endif
	Super.PreLogin(Options, Address, UniqueID, bSupportsAuth, ErrorMessage);
	`if(`notdefined(DEMO))
	ModsList = ParseOption(Options, "Mods");
	ModNames = SplitString(ModsList, "|");
	if(bCheckClientMods)
	{
		`log("PreLogin:"@Options@Address@ErrorMessage,,'PreLogin');
		LogStringArray(ModNames, "ModNames");
		for(Mod = Rootmod; Mod != None; Mod = Mod.NextMod)
		{
			ModIndex = ModNames.Find(Mod.GetSafeName(true));
			if(ModIndex == INDEX_NONE)
			{
				`log("Missing mod:"@Mod.GetSafeName(true)$"!",,'PreLogin');
				ErrorMessage @= "Mod missing:"$Mod.GetSafeName(true);
				MissingMods++;
			}
			else
			{
				Version = ParseVersion(ModNames[ModIndex]);
				if(Version != Mod.Version)
				{
					`log("Outdated mod:"@Mod.ModName@Mod.Version,,'PreLogin');
					ErrorMessage @= "Mod outdated:"$Mod.ModName@"Your Version:"$ModNames[ModIndex]@"Server Version:"$Mod.GetSafeName(true);
					OutdatedMods++;
				}
			}
		}
		if(MissingMods > 0 || OutdatedMods > 0)
		{
			ErrorMessage $= "Failed to join server! Missing"@MissingMods@"mods!"@OutdatedMods@"Mods outdated!";
			`log("Player rejected. ErrorMessage:"@ErrorMessage,,'PreLogin');
		}
	}
	`endif
}

private function int ParseVersion(out const String ModSafeName)
{
	return int(Right(ModSafeName, Len(ModSafeName) - InStr(ModSafeName, class'TowerGameBase'.const.VERSION_DIVIDER)-1));
}

//@TODO - Why is loading done in Login? Because it can't be done in PreLogin.
event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local string LoadString;
	local PlayerController Controller;
	Controller = Super.Login(Portal, Options, UniqueID, ErrorMessage);
	LoadString = ParseOption(Options, "LoadGame");
	
//	`log("LoadString:"@LoadString;
	if(WorldInfo.NetMode != NM_DedicatedServer && LoadString != "")
	{
		bPendingLoad = true;
		PendingLoadFile = LoadString;
	}
	return Controller;
}

event PostLogin( PlayerController NewPlayer )
{
	Super.PostLogin(NewPlayer);
	
	/* We can only confirm now whether or not this is us or a client joining.
	You could have technically used GetNumPlayers() earlier but then you have to 
	account for dedicated or listen server and such. */
	if(!NewPlayer.IsLocalPlayerController())
	{
		// We don't want clients making the server load a game.
		if(WorldInfo.NetMode != NM_DedicatedServer)
		{
			bPendingLoad = false;
			PendingLoadFile = "";
		}
		`log(NewPlayer@"is logged in. Asking to wait 2.5 seconds to help replication.",,'CDNet');
		TowerPlayerController(NewPlayer).WaitFor(2.5);
//		TowerPlayerController(NewPlayer).ReceiveModList(RootMod.GetList(false));
	}
	else
	{
		TowerHUD(NewPlayer.myHUD).SetupBuildList();
	}
	if(bPendingLoad)
	{
		`log("Load from file:"@PendingLoadFile);
	}
}

function Logout( Controller Exiting )
{
	Super.Logout(Exiting);
	if(WorldInfo.NetMode == NM_DedicatedServer && NumPlayers == 0)
	{
		OnEmptyServer();
	}
}

/** Only called on NM_DedicatedServer. Called from LogOut when NumPlayers is 0.*/
private event OnEmptyServer()
{
	if(bResetLevelOnEmptyServer || (!bResetLevelOnEmptyServer && !bPauseLevelOnEmptyServer))
	{
		ConsoleCommand("ServerTravel?LoadGame="@DedicatedServerLoadFile);
	}
	else if(bPauseLevelOnEmptyServer)
	{

	}
}

private exec function GetSteamAddress()
{
	`log(GetSteamServerID());
}

//@TODO - Is this accessible on clients?
static final function string GetSteamServerID()
{
	local String URL;
	local UniqueNetID ID;

	if(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).AuthInterfaceImpl.GetServerUniqueId(ID))
	{
		URL = "steam."$OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).UniqueNetIdToInt64(ID);
	}
	else
	{
		`warn("GetServerUniqueId() call in TowerGameBase::GetSteamServerID() failed! Are you using Steam sockets?");
		URL = "";
	}
	return URL;
}

/* ProcessServerTravel()
 Optional handling of ServerTravel for network games.
*/
function ProcessServerTravel(string URL, optional bool bAbsolute)
{
	Super.ProcessServerTravel(URL, bAbsolute);
}

protected event OnLoadGame();

/** Called from PreBeginPlay. Loads any mods listed in the config file. */
private final function CheckForMods()
{
	`if(`notdefined(DEMO))
	RootMod = static.LoadMods(, true);
	TowerGameReplicationInfo(WorldInfo.GRI).RootMod = RootMod;
	RootArchetype = RootMod.ModBlocks[ROOT_BLOCK_INDEX];
	AirArchetype = RootMod.ModBlocks[AIR_BLOCK_INDEX];
	`assert(RootArchetype != None && AirArchetype != None);
	`assert(AirArchetype.Class == class'TowerBlockAir');
//	`log("ReplicatedModList:"@ReplicatedModList);
//	TowerGameReplicationInfo(GameReplicationInfo).ServerMods = ReplicatedModList;
//	TowerGameReplicationInfo(GameReplicationInfo).ModCount = RootMod.GetModCount();
//	TowerGameReplicationInfo(GameReplicationInfo).AreModsLoaded();
	`else
	// Hardcode to only check for TowerMod since mods aren't supported in the demo.
	`endif
}

/** Returns RootMod. If passed SafeNameList, will load all specified mods as ordered.
If passed nothing, will load all mods in ModPackages as ordered.
For clients this happens after they have verified mods in PreLogin, so nothing should go wrong. */
public static function TowerModInfo LoadMods(optional String SafeNameList, optional bool bLog=false)
{
	local TowerModInfo NewRootMod;
	local TowerModInfo TempMod;
	local String ModPackageName;
	local array<String> ModPackagesToLoad;
	local int i;
	// Load everything in ModPackages.
	if(SafeNameList == "")
	{
		ModPackagesToLoad = default.ModPackages;
	}
	else
	{
		ModPackagesToLoad = SplitString(SafeNameList, const.MOD_DIVIDER, true);
	}
	`log("Number of listed mods:"@ModPackagesToLoad.Length,bLog,'Mod');
	foreach ModPackagesToLoad(ModPackageName, i)
	{
		`log("Loading mod from:"@ModPackageName$"...",bLog,'Mod');
		TempMod = new class'TowerModInfo' (TowerModInfo(DynamicLoadObject(ModPackageName$".ModInfo",class'TowerModInfo',false)));
		TempMod.PreInitialize(i);
		`log("Loaded Mod:"@TempMod.ModName@TempMod.AuthorName@TempMod.Contact@TempMod.Website
			@"v."$TempMod.Version,bLog,'Mod');
		if(NewRootMod == None)
		{
			NewRootMod = TempMod;
		}
		else
		{
			NewRootMod.AddMod(TempMod);
		}
	}
	`log("Number of loaded mods:"@NewRootMod.GetModCount(),bLog,'Mod');
	return NewRootMod;
}

private function DetermineTowerStarts()
{
	local TowerStart Start;
	foreach WorldInfo.AllActors(class'TowerStart', Start)
	{
		if(TowerStarts[Start.PlayerNumber-1] == None)
		{
			TowerStarts[Start.PlayerNumber-1] = Start;
		}
		else
		{
			`warn(Start@"has the same PlayerNumber as"@TowerStarts[Start.PlayerNumber-1]$"! Ignoring!");
		}
	}
	`assert(ArrayCount(TowerStarts) != 0);
	if(ArrayCount(TowerStarts) < MaxPlayersAllowed)
	{
		`warn("There are only"@ArrayCount(TowerStarts)@"TowerStarts, but this game mode supports"@MaxPlayersAllowed@"players!");
	}
	GridOrigin = TowerStarts[0].Location;
	TowerGameReplicationInfo(WorldInfo.GRI).GridOrigin = GridOrigin;
}

event Tick(float DeltaTime)
{
	local delegate<TickDelegate> ToTickDelegate;
//	`log(DeltaTime);
	if(ToTick.Length == 0)
	{
		return;
	}
	foreach ToTick(ToTickDelegate)
	{
		ToTickDelegate(DeltaTime);
	}
}

function bool AllowCheats(PlayerController P)
{
	return ( WorldInfo.NetMode == NM_Standalone );
}

final function RegisterForPreAsyncTick(delegate<TickDelegate> Tick)
{
	if(ToTick.Find(Tick) == INDEX_NONE)
	{
		ToTick.AddItem(Tick);
	}
}

final function UnRegisterForPreAsyncTick(delegate<TickDelegate> Tick)
{
	local int RemoveIndex;
	RemoveIndex = ToTick.Find(Tick);
	if(RemoveIndex != INDEX_NONE)
	{
		ToTick.Remove(RemoveIndex, 1);
	}
	// Don't disable Tick since TowerGame has timers!
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

final function byte GetNextAvailablePlayerNumber()
{
	local array<byte> Available;
	local byte i;
	local TowerPlayerController Controller; 

	for(i = 1; i <= MaxPlayersAllowed; i++)
	{
		Available.AddItem(i);
	}

	foreach WorldInfo.AllControllers(class'TowerPlayerController', Controller)
	{
		Available.RemoveItem(TowerPlayerReplicationInfo(Controller.PlayerReplicationInfo).PlayerNumber);
	}

	`assert(Available.Length != 0 && Available[0] != 0);
	return Available[0];
}