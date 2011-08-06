/** 
TowerSaveSystem

Class used to save and load games on the PC and iOS. */
class TowerSaveSystem extends Object
	config(Tower);

struct immutable BlockSaveInfo
{
	// ModIndex, ModBlockIndex, Health.
	var int M, I, H;
	// GridLocation, ParentDirection.
	var IVector G, P;
};

struct immutable PlayerInfo
{
	// Pawn Location.
	var Vector L;
	// Pawn Rotation.
	var Rotator R;
};

struct immutable ModInfo
{
	// ModName.
	var String M;
	// MajorVersion, MinorVersion.
	var byte Ma, Mi;
};

const SAVE_FILE_VERSION = 3;

var string SaveTowerName;
var array<ModInfo> SaveMods;
var array<BlockSaveInfo> Blocks;

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

final function LoadGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
		NativeLoadGame(FileName, bJustTower, Player);
}

/** Saves the game using Engine.uc's BasicSaveObject function, serializing this class. PC and iOS. */
final function bool NativeSaveGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	local TowerBlock Block;
	local BlockSaveInfo Info;
	CleanupSaveLoadVariables();
	SaveTowerName = Player.GetTower().TowerName;
	PopulateModList(TowerGameReplicationInfo(Player.WorldInfo.GRI), SaveMods);
	
	foreach Player.DynamicActors(class'TowerBlock', Block)
	{
		if(Block.class == class'TowerBlockAir')
		{
			continue;
		}
//		`log("Saving:"@Block.ModIndex@Block.ModBlockInfoIndex);
		Info.M = Block.ModIndex;
		Info.I = Block.ModBlockIndex;
		Info.G = Block.GridLocation;
		Info.P = Block.ParentDirection;
		Info.H = Block.Health;
		Blocks.AddItem(Info);
	}
	return class'Engine'.static.BasicSaveObject(Self, FileName$".bin", true, SAVE_FILE_VERSION);
}

//@TODO - We have a player by then?
//@SOLVED - Yes, it's called from Login.
/** Loads the game using Engine.uc's BasicLoadObject function, serializing this class. PC and iOS.
Called from TowerGame::Login(). Guaranteed to be called on an empty map with towers but no blocks (including root).*/
final function NativeLoadGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	local int i;
	local bool bLoaded;
	local TowerGameReplicationInfo GRI;
	local BlockSaveInfo BlockInfo;
	local TowerModInfo Mod;
	local array<TowerModInfo> ModsArray;
	/** The actual mod index to use. The mod indexes used when saving are used as the indexes in this array. */
	local array<int> TranslatedMods;
	local ModInfo Info;
	local TowerBlock BlockArchetype, Block;
	local Vector SpawnLocation;
	local IVector GridLocation;

	FileName $= ".bin";
	`log("Loading:"@FileName,,'NativeLoad');
	GRI = TowerGameReplicationInfo(Player.WorldInfo.GRI);
	CleanupSaveLoadVariables();

	bLoaded = class'Engine'.static.BasicLoadObject(Self, FileName, true, SAVE_FILE_VERSION);
	if(bLoaded)
	{
		`log("Load successful!",,'NativeLoad');
	}
	else
	{
		`log("Load failed! Aborting!",,'NativeLoad');
		return;
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
	foreach Blocks(BlockInfo, i)
	{
		SpawnLocation = ToVect(BlockInfo.G*256);
		SpawnLocation.Z += 128;
		GridLocation.X = SpawnLocation.X / 256;
		GridLocation.Y = SpawnLocation.Y / 256;
		GridLocation.Z = SpawnLocation.Z / 256;
		//@TODO - NO MORE TOWERTREE.
		BlockArchetype = ModsArray[TranslatedMods[BlockInfo.M]].ModBlocks[BlockInfo.I];
		// Without a parent no block will get spawned.
		Block = Player.GetTower().AddBlock(BlockArchetype, None, SpawnLocation, GridLocation, false);
		Block.Initialize(BlockInfo.G, BlockInfo.P, TowerPlayerReplicationInfo(Player.PlayerReplicationInfo));
		if(BlockArchetype == TowerGame(Player.WorldInfo.Game).RootArchetype)
		{
			Player.GetTower().SetRootBlock(TowerBlockRoot(Block));
		}
	}
	//@TODO - parenting!
	foreach Player.DynamicActors(class'TowerBlock', Block)
	{
		if(Block.class == class'TowerBlockAir')
		{
			continue;
		}
		Block.SetBase(Player.GetTower().GetBlockFromLocationAndDirection(Block.GridLocation, Block.ParentDirection));
		Player.GetTower().CreateSurroundingAir(Block);
	}
	Mod.GameLoaded(FileName);
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

final function CleanupSaveLoadVariables()
{
	Blocks.Remove(0, Blocks.Length);
	SaveMods.Remove(0, SaveMods.Length);
	SaveTowerName = "MAKE_SURE_I_GET_SET";
}