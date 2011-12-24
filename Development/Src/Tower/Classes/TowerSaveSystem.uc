/** 
TowerSaveSystem

Class used to save and load games on the PC and iOS. */
class TowerSaveSystem extends Object
	//@TODO - Dedicated config file since it holds save information?
	config(Tower);

struct SaveInfo
{
	// With extension!
	var string FileName;
	var bool bVisible;
};

struct immutable BlockSaveInfo
{
	// ModIndex, ModBlockIndex, Health.
	var int M, I, H;
	// GridLocation, ParentDirection.
	var IVector G, P;
	// State.
	var Name S;
};

struct immutable PlayerSaveInfo
{
	// Pawn Location.
	var Vector L;
	// Pawn Rotation.
	var Rotator R;
};

struct immutable FactionInfo
{
	// AI Archetype. None implies player.
	var TowerFactionAI A;
	// FactionLocation of the faction. Ignored for players.
	var FactionLocation L;
	// Budget.
	var int B;
};

struct immutable ModInfo
{
	// ModName.
	var String M;
	// MajorVersion, MinorVersion.
	var byte Ma, Mi;
};

const SAVE_FILE_VERSION = 4;
const SAVE_FILE_EXTENSION = ".bin";
const SAVE_FILE_PATH = "../../UDKGame/Saves/";

var string SaveTowerName;
var array<ModInfo> SaveMods;
var array<BlockSaveInfo> Blocks;
var PlayerSaveInfo PlayerInfo;
// Format: 2011/08/07 - 22:51:06
var string SaveTimeStamp;

var transient privatewrite bool bLoaded;
var transient config array<SaveInfo> Saves;

/** Dumps what is pretty close of the current gamestate to disk. Anticipated to produce a very
sizable file compared to normal saving. */
final function QuickSave()
{

}

/** Essentially restores a gamestate from disk. Anticipated to take longer than normal loading since
it'll likely result in lots of despawning of existing actors and spawning of new ones. */
final function QuickLoad()
{

}

final function SaveGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	NativeSaveGame(FileName, bJustTower, Player);
}

final function bool LoadGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	return NativeLoadGame(FileName, bJustTower, Player);
}

/** Saves the game using Engine.uc's BasicSaveObject function, serializing this object. PC and iOS. */
final function bool NativeSaveGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	local TowerBlock Block;
	local BlockSaveInfo BlockInfo;
	local bool Result;
	SaveTimeStamp = TimeStamp();
	FileName $= SAVE_FILE_EXTENSION;
	CleanupSaveLoadVariables();
	SaveTowerName = Player.GetTower().TowerName;
	PopulateModList(TowerGameReplicationInfo(Player.WorldInfo.GRI), SaveMods);

	PlayerInfo.L = Player.Pawn.Location;
	PlayerInfo.R = Player.Pawn.Rotation;

	// Save block data.
	foreach Player.DynamicActors(class'TowerBlock', Block)
	{
		if(Block.class == class'TowerBlockAir')
		{
			continue;
		}
//		`log("Saving:"@Block.ModIndex@Block.ModBlockInfoIndex);
		BlockInfo.M = Block.ModIndex;
		BlockInfo.I = Block.ModBlockIndex;
		BlockInfo.G = Block.GridLocation;
		BlockInfo.P = Block.ParentDirection;
		BlockInfo.H = Block.Health;
		BlockInfo.S = Block.GetStateName();
		Blocks.AddItem(BlockInfo);
	}

	Result = class'Engine'.static.BasicSaveObject(Self, GetFilePath(FileName), true, SAVE_FILE_VERSION);
	if(Result)
	{
		AddToSaves(FileName);
	}
	else
	{
		`log("Saving"@FileName@"failed!");
	}
	return Result;
}

//@TODO - We have a player by then?
//@SOLVED - Yes, it's called from Login.
/** Loads the game using Engine.uc's BasicLoadObject function, serializing this object. PC and iOS.
Called from TowerGame::Login(). Guaranteed to be called on an empty map with towers but no blocks (including root).*/
final function bool NativeLoadGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	local int i;
	local TowerGameReplicationInfo GRI;
	local BlockSaveInfo BlockInfo;
	local TowerModInfo Mod;
	local array<TowerModInfo> ModsArray;
	/** The actual mod index to use. The mod indexes used when saving are used as the indexes in this array. */
	local array<int> TranslatedMods;
	local ModInfo Info;
	local TowerBlock BlockArchetype, Block;

	FileName $= SAVE_FILE_EXTENSION;
	`log("Loading:"@FileName,,'NativeLoad');
	GRI = TowerGameReplicationInfo(Player.WorldInfo.GRI);
	CleanupSaveLoadVariables();

	bLoaded = class'Engine'.static.BasicLoadObject(Self, GetFilePath(FileName), true, SAVE_FILE_VERSION);
	if(bLoaded)
	{
		`log("Load successful!",,'NativeLoad');
	}
	else
	{
		`log("Load failed! Aborting!",,'NativeLoad');
		return false;
	}

	TowerGame(Player.WorldInfo.Game).SetTowerName(Player.GetTower(), Self.SaveTowerName);
	for(Mod = GRI.RootMod; Mod != None; Mod = Mod.NextMod)
	{
		ModsArray.AddItem(Mod);
	}
	foreach SaveMods(Info, i)
	{
		for(Mod = GRI.RootMod; Mod != None; Mod = Mod.NextMod)
		{
			if(Info.M == Mod.ModName)
			{
				TranslatedMods[i] = GRI.RootMod.GetModIndex(Mod);
			}
		}
	}

	// Spawn blocks (excluding air).
	foreach Blocks(BlockInfo, i)
	{
		BlockArchetype = ModsArray[TranslatedMods[BlockInfo.M]].ModBlocks[BlockInfo.I];
		Block = Player.GetTower().AddBlock(BlockArchetype, None, BlockInfo.G, false);
		Block.Initialize(BlockInfo.G, BlockInfo.P, TowerPlayerReplicationInfo(Player.PlayerReplicationInfo));
		if(BlockArchetype == TowerGame(Player.WorldInfo.Game).RootArchetype)
		{
			Player.GetTower().SetRootBlock(TowerBlockRoot(Block));
			TowerGame(Player.WorldInfo.Game).Hivemind.OnRootBlockSpawn(TowerBlockRoot(Block));
		}
		Block.GotoState(BlockInfo.S);
	}
	// Recreate hierarchy.
	foreach Player.DynamicActors(class'TowerBlock', Block)
	{
		if(Block.class == class'TowerBlockAir')
		{
			continue;
		}
		if(Block.class != class'TowerBlockRoot')
		{
			Block.SetBase(Player.GetTower().GetBlockFromLocationAndDirection(Block.GridLocation, Block.ParentDirection));
			Block.CalculateBlockRotation();
			if(Block.class == class'TowerBlockStructural')
			{
				TowerBlockStructural(Block).ReplicatedBase = TowerBlock(Block.Base);
			}
		}
		Player.GetTower().CreateSurroundingAir(Block);
	}

	// Mods don't need the extension.
	FileName -= SAVE_FILE_EXTENSION;
	GRI.RootMod.GameLoaded(FileName);
	return true;
}

final function PopulateModList(TowerGameReplicationInfo GRI, out array<ModInfo> ModArray)
{
	local ModInfo Info;
	local TowerModInfo Mod;
	for(Mod = GRI.RootMod; Mod != None; Mod = Mod.NextMod)
	{
		Info.M = Mod.ModName;
		Info.Ma = Mod.MajorVersion;
		Info.Mi = Mod.MinorVersion;
		ModArray.AddItem(Info);
	}
}

final function bool CheckSaveExist(string FileName)
{
	local TowerSaveSystem TestSaveSystem;
	TestSaveSystem = new class'TowerSaveSystem';
	FileName $= SAVE_FILE_EXTENSION;
	if(Saves.find('FileName', FileName) != INDEX_NONE)
	{
		return true;
	}
	else if(class'Engine'.static.BasicLoadObject(TestSaveSystem, GetFilePath(FileName), true, SAVE_FILE_VERSION))
	{
		AddToSaves(FileName);
		return true;
	}
	return false;
}

final function AddToSaves(out string FileName)
{
	local int Index;
	local SaveInfo Info;
	Info.FileName = Filename;
	Info.bVisible = true;

	Index = Saves.Find('FileName', FileName);
	if(Index == INDEX_NONE)
	{
		Saves.AddItem(Info);
	}
	else
	{
		Saves[Index] = Info;
	}
	SaveConfig();
}

final function RemoveFromSaves(out string FileName)
{
	local int Index;
	Index = Saves.Find('FileName', FileName);
	if(Index != INDEX_NONE)
	{
		Saves.Remove(Index, 1);
	}
	SaveConfig();
}

final function CleanupSaveLoadVariables()
{
	Blocks.Remove(0, Blocks.Length);
	SaveMods.Remove(0, SaveMods.Length);
	SaveTowerName = "MAKE_SURE_I_GET_SET";
}

final function String GetFilePath(out const String FileName)
{
	return SAVE_FILE_PATH$FileName;
}

DefaultProperties
{
	bLoaded=false
}