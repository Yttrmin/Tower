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

struct immutable ModInfo
{
	// ModName.
	var String M;
	// MajorVersion, MinorVersion.
	var byte Ma, Mi;
};

const SAVE_FILE_VERSION = 3;

var string SaveTowerName;
var array<ModInfo> Mods;
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
final function NativeSaveGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	local TowerBlock Block;
	local BlockSaveInfo Info;
	CleanupSaveLoadVariables();
	SaveTowerName = Player.GetTower().TowerName;
	PopulateModList(TowerGameReplicationInfo(Player.WorldInfo.GRI));
	
	foreach Player.DynamicActors(class'TowerBlock', Block)
	{
//		`log("Saving:"@Block.ModIndex@Block.ModBlockInfoIndex);
		Info.M = Block.ModIndex;
		Info.I = Block.ModBlockIndex;
		Info.G = Block.GridLocation;
		Info.P = Block.ParentDirection;
		Info.H = Block.Health;
		Blocks.AddItem(Info);
	}
	class'Engine'.static.BasicSaveObject(Self, FileName$".bin", true, SAVE_FILE_VERSION);
}

//@TODO - We have a player by then?
/** Loads the game using Engine.uc's BasicLoadObject function, serializing this class. PC and iOS. */
final function NativeLoadGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	local int i;
	local TowerGameReplicationInfo GRI;
	local BlockSaveInfo BlockInfo;
	local TowerModInfo Mod;
	local array<TowerModInfo> ModsArray;
	local TowerBlock BlockArchetype;
	local Vector SpawnLocation;
	GRI = TowerGameReplicationInfo(Player.WorldInfo.GRI);
	CleanupSaveLoadVariables();
	class'Engine'.static.BasicLoadObject(Self, FileName$".bin", true, SAVE_FILE_VERSION);
	TowerGame(Player.WorldInfo.Game).SetTowerName(Player.GetTower(), Self.SaveTowerName);
	for(Mod = GRI.RootMod; Mod != None; Mod = Mod.NextMod)
	{
		ModsArray.AddItem(Mod);
	}
	foreach Blocks(BlockInfo, i)
	{
		SpawnLocation = ToVect(BlockInfo.G*256);
		//@TODO - NO MORE TOWERTREE.
		BlockArchetype = ModsArray[BlockInfo.M].ModBlocks[BlockInfo.I];
		BlockArchetype.AttachBlock(BlockArchetype, None, None, SpawnLocation,
			BlockInfo.G, TowerPlayerReplicationInfo(Player.PlayerReplicationInfo));
	}
	//@TODO - parenting!
}

final function PopulateModList(TowerGameReplicationInfo GRI)
{
	local ModInfo Info;
	local TowerModInfo Mod;
	for(Mod = GRI.RootMod; Mod != None; Mod = Mod.NextMod)
	{
		Info.M = Mod.ModName;
		Info.Ma = Mod.MajorVersion;
		Info.Mi = Mod.MinorVersion;
		Mods.AddItem(Info);
	}
}

final function CleanupSaveLoadVariables()
{
	Blocks.Remove(0, Blocks.Length);
	Mods.Remove(0, Mods.Length);
	SaveTowerName = "MAKE_SURE_I_GET_SET";
}