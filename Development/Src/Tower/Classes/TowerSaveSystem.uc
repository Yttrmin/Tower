/** 
TowerSaveSystem

Class used to save and load games on the PC and iOS. */
class TowerSaveSystem extends Object
	config(Tower);

struct BlockSaveInfo
{
	// ModIndex, BlockInfoIndex
	var int M, I;
	// GridLocation, ParentDirection.
	var Vector G, P;
};

const SAVE_FILE_VERSION = 2;

var string SaveTowerName;
var array<String> ModNames;
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
	PopulateModList(TowerPlayerReplicationInfo(Player.PlayerReplicationInfo));
	//@TODO - Would traversing the tree be safer than this?
	foreach Player.DynamicActors(class'TowerBlock', Block)
	{
		`log("Saving:"@Block.ModIndex@Block.ModBlockInfoIndex);
		Info.M = Block.ModIndex;
		Info.I = Block.ModBlockInfoIndex;
		Info.G = Block.GridLocation;
		Info.P = Block.ParentDirection;
		Blocks.AddItem(Info);
	}
	class'Engine'.static.BasicSaveObject(Self, FileName$".bin", true, SAVE_FILE_VERSION);
}

/** Loads the game using Engine.uc's BasicLoadObject function, serializing this class. PC and iOS. */
final function NativeLoadGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	local int i;
	local BlockSaveInfo LoadBlockInfo;
	CleanupSaveLoadVariables();
	class'Engine'.static.BasicLoadObject(Self, FileName$".bin", true, SAVE_FILE_VERSION);
	TowerGame(Player.WorldInfo.Game).SetTowerName(Player.GetTower(), Self.SaveTowerName);
	foreach Blocks(LoadBlockInfo, i)
	{
		`log("Load:"@LoadBlockInfo.M@LoadBlockInfo.I@LoadBlockInfo.G@LoadBlockInfo.P);
//		`log("Loaded Block:"@"Mod:"@ModNames[LoadBlockInfo.I]@"GridLoc:"@LoadBlockInfo.G@"ParentDir:"@LoadBlockInfo.P);
//		LoadClass = class<TowerBlock>(DynamicLoadObject(ClassNames[LoadBlockInfo.I], class'class'
//			, false));
		//@FIXME - Seriously.
		if(i == 0)
		{

		}
		else if(i == 1)
		{
			/*
			TowerGame(Player.WorldInfo.Game).AddBlock(Player.GetTower(), 
				Player.GetTPRI().Mods[LoadBlockInfo.M].ModBlockInfo[LoadBlockInfo.I], 
				Player.GetTower().NodeTree.Root, LoadBlockInfo.G);
				*/
		}
		else
		{
			/*
			TowerGame(Player.WorldInfo.Game).AddBlock(Player.GetTower(), 
				Player.GetTPRI().Mods[LoadBlockInfo.M].ModBlockInfo[LoadBlockInfo.I], 
				Player.GetTower().GetBlockFromLocationAndDirection(LoadBlockInfo.G, LoadBlockInfo.P), 
				LoadBlockInfo.G);
				*/
				
		}
	}
}

final function PopulateModList(TowerPlayerReplicationInfo TPRI)
{
	/*
	local TowerModInfo TMI;
	foreach TPRI.Mods(TMI)
	{
		ModNames.AddItem(TMI.ModName);
	}
	*/
}

final function CleanupSaveLoadVariables()
{
	Blocks.Remove(0, Blocks.Length);
	ModNames.Remove(0, ModNames.Length);
	SaveTowerName = "MAKE_SURE_I_GET_SET";
}