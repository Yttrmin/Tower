/** 
TowerSaveSystem

Class used to save and load games on the PC, Mac, and iOS. */
class TowerSaveSystem extends Object
	dependson(TowerGameBase)
	config(TowerSaves);

struct SaveInfo
{
	// With extension!
	var string FileName;
	var bool bVisible;
};

struct immutable BlockSaveInfo
{
	/** Single letters are used to cut down on file size, since variable names are saved. */
	// ModIndex, ModBlockIndex, Health.
	var int M, I, H;
	// GridLocation, ParentDirection.
	var IVector G, P;
	// State.
	var Name S;
};

struct immutable TowerInfo
{

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
	// Safe name, no version.
	var String N;
	// Version.
	var int V;
};

const SAVE_FILE_VERSION = 5;
const SAVE_FILE_EXTENSION = ".bin";
const SAVE_FILE_PATH = "../../UDKGame/Saves/";

var string SaveTowerName;
/** Current mods in TowerGameBase::ModPackages at the time of saving, in order. */
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

/** Saves the game using Engine.uc's BasicSaveObject function, serializing this object. PC, Mac, and iOS. */
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
/** Loads the game using Engine.uc's BasicLoadObject function, serializing this object. PC, Mac, and iOS.
Called from TowerGame::Login(). Guaranteed to be called on an empty map with towers but no blocks (including root).*/
final function bool NativeLoadGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	local int i;
	local TowerModInfo RootMod;
	local BlockSaveInfo BlockInfo;
	local TowerModInfo Mod;
	/** Since block type and mod they belong to uses indices, might as well temporarily use a mod array. */
	local array<TowerModInfo> ModsArray;
	/** The actual mod index to use. The mod indexes used when saving are used as the indexes in this array. */
	local array<int> TranslatedMods;
	local ModInfo Info;
	local TowerBlock BlockArchetype, Block;

	FileName $= SAVE_FILE_EXTENSION;
	`log("Loading:"@FileName,,'NativeLoad');
	RootMod = TowerGameReplicationInfo(Player.WorldInfo.GRI).RootMod;
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
	RootMod.GetAllMods(ModsArray);
	foreach SaveMods(Info, i)
	{
		Mod = RootMod.FindModBySafeName(Info.N);
		if(!VerifyMod(Mod, Info)) {return false;}
		for(Mod = RootMod; Mod != None; Mod = Mod.NextMod)
		{
			if(Info.N == Mod.GetSafeName(false))
			{
				TranslatedMods[i] = RootMod.GetModIndex(Mod);
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
	RootMod.GameLoaded(FileName);
	return true;
}

private final function bool VerifyMod(TowerModInfo Mod, out ModInfo Info)
{
	if(Mod == None)
	{
		`log("Missing Mod: \""$Info.N$"\", aborting!",,'NativeLoad');
		return false;
	}
	else if(Mod.Version != Info.V)
	{
		`log("Mod \""$Info.N$"\" is outdated! Game Version:"$Mod.Version@"Save Version:"$Info.V);
		return false;
	}
	else
	{
		return true;
	}
}

final function PopulateModList(TowerGameReplicationInfo GRI, out array<ModInfo> ModArray)
{
	local ModInfo Info;
	local TowerModInfo Mod;
	for(Mod = GRI.RootMod; Mod != None; Mod = Mod.NextMod)
	{
		Info.N = Mod.GetSafeName(false);
		Info.V = Mod.Version;
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