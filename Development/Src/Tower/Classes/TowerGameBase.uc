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

struct ModCheck
{
	var String ModName;
	var byte MajorVersion, MinorVersion;
};

/** If TRUE, PreLogin checks the mods string before letting clients join. */
var private globalconfig const bool bCheckClientMods;
`if(`notdefined(DEMO))
var privatewrite globalconfig const array<String> ModPackages;
`endif
/** Used to compare to ?Mod= strings passed in during PreLogin(). Can be used after CheckForMods(). */
var private array<ModCheck> LoadedMods;
/** First element of the TowerModInfo linked list. This is always assumed to be TowerMod! */
var privatewrite TowerModInfo RootMod;
/** Archetype to use for spawning the root blocks of towers. */
var privatewrite TowerBlock RootArchetype;
/** Archetype to use for spawning air surrounding blocks. */
var privatewrite TowerBlock AirArchetype;

//@TODO - Decouple loading from Tower/TowerGame. Make these private.
var protected bool bPendingLoad;
var protected string PendingLoadFile;

var privatewrite TowerFactionAIHivemind Hivemind;

var private array<delegate<TickDelegate> > ToTick;

var const Vector Borders[4];
var privatewrite Vector GridOrigin;
var privatewrite TowerStart TowerStarts[4];

delegate TickDelegate(float DeltaTime);

event PreBeginPlay()
{
	Super.PreBeginPlay();
	DetermineTowerStarts();
	CheckForMods();
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	Hivemind = Spawn(class'TowerFactionAIHivemind');
	Hivemind.Initialize();
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

//@TODO - Why is loading done in Login?
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
			AirArchetype = RootMod.ModBlocks[6];
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
}

event Tick(float DeltaTime)
{
	local delegate<TickDelegate> ToTickDelegate;
	if(ToTick.Length == 0)
	{
		return;
	}
	foreach ToTick(ToTickDelegate)
	{
		ToTickDelegate(DeltaTime);
	}
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

function Vector GridLocationToVector(out const IVector GridLocation)
{
	local Vector NewBlockLocation;
	//@FIXME: Block dimensions. Constant? At least have a constant, traceable part?
	NewBlockLocation.X = (GridLocation.X * 256)+GridOrigin.X;
	NewBlockLocation.Y = (GridLocation.Y * 256)+GridOrigin.Y;
	NewBlockLocation.Z = (GridLocation.Z * 256)+GridOrigin.Z;
	//@TODO - Are we doing this here or what?
	// Pivot point in middle, bump it up.
//	NewBlockLocation.Z += 128;
	return NewBlockLocation;
}