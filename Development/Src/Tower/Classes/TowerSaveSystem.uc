/** 
TowerSaveSystem

Class used to save and load games on the PC and iOS. */
class TowerSaveSystem extends Object
	config(Tower);

struct immutable BlockSaveInfo
{
	// ModIndex, BlockInfoIndex
	var int M, I;
	// GridLocation, ParentDirection.
	var IVector G, P;
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

static final function TestStaticSave(string Filename, TowerPlayerController Player)
{
	local TowerSaveSystem Save;
	Save = new class'TowerSaveSystem';
	Save.SaveTowerName = "AJAJAJAJAJAJA";
	class'Engine'.static.BasicSaveObject(Save, FileName$".bin", true, SAVE_FILE_VERSION);
}

static final function LoadStaticSave(string Filename, TowerPlayerController Player)
{
	local TowerSaveSystem Save;
	Save = new class'TowerSaveSystem';
//	Save.SaveTowerName = "AJAJAJAJAJAJA";
	class'Engine'.static.BasicLoadObject(Save, FileName$".bin", true, SAVE_FILE_VERSION);
	`log("Save file TowerName:"@Save.SaveTowerName);
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
//		`log("Saving:"@Block.ModIndex@Block.ModBlockInfoIndex);
//		Info.M = Block.ModIndex;
//		Info.I = Block.ModBlockInfoIndex;
		Info.G = Block.GridLocation;
		Info.P = Block.ParentDirection;
		Blocks.AddItem(Info);
	}
	class'Engine'.static.BasicSaveObject(Self, FileName$".bin", true, SAVE_FILE_VERSION);
}

/*
[0008.54] Log: Assembled 366 auto-complete commands, manual: 78, exec: 273, kismet: 0
[0009.80] ScriptLog: Load: 0 0 0.00,0.00,0.00 0.00,0.00,0.00
[0009.80] ScriptLog: Load: 0 0 0.00,0.00,1.00 0.00,0.00,-1.00
[0009.80] ScriptWarning: Accessed array 'TowerSaveSystem_0.Mods' out of bounds (0/0)
	TowerSaveSystem Transient.TowerSaveSystem_0
	Function Tower.TowerSaveSystem:NativeLoadGame:0379
[0009.80] ScriptWarning: Accessed None 'Mods'
	TowerSaveSystem Transient.TowerSaveSystem_0
	Function Tower.TowerSaveSystem:NativeLoadGame:0379
[0009.80] ScriptWarning: Script call stack:
	Function Tower.TowerPlayerController:LoadGame
	Function Tower.TowerSaveSystem:LoadGame
	Function Tower.TowerSaveSystem:NativeLoadGame
	Function Tower.TowerGame:AddPlaceable

	TowerGame TowerLevel.TheWorld:PersistentLevel.TowerGame_0
	Function Tower.TowerGame:AddPlaceable:0085
[0009.80] Critical: appError called: Assertion failed, line 369
	TowerGame TowerLevel.TheWorld:PersistentLevel.TowerGame_0
	Function Tower.TowerGame:AddPlaceable:0085
	Script call stack:
	Function Tower.TowerPlayerController:LoadGame
	Function Tower.TowerSaveSystem:LoadGame
	Function Tower.TowerSaveSystem:NativeLoadGame
	Function Tower.TowerGame:AddPlaceable

[0009.80] Critical: Windows GetLastError: The operation completed successfully. (0)
[0021.21] Log: === Critical error: ===
Assertion failed, line 369
	TowerGame TowerLevel.TheWorld:PersistentLevel.TowerGame_0
	Function Tower.TowerGame:AddPlaceable:0085
*/

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
		`log("Load:"@LoadBlockInfo.M@LoadBlockInfo.I@ToVect(LoadBlockInfo.G)@ToVect(LoadBlockInfo.P));
//		`log("Loaded Block:"@"Mod:"@ModNames[LoadBlockInfo.I]@"GridLoc:"@LoadBlockInfo.G@"ParentDir:"@LoadBlockInfo.P);
//		LoadClass = class<TowerBlock>(DynamicLoadObject(ClassNames[LoadBlockInfo.I], class'class'
//			, false));
		//@FIXME - Seriously.
		if(i == 0)
		{

		}
		else if(i == 1)
		{
			TowerGame(Player.WorldInfo.Game).AddPlaceable(Player.GetTower(), 
				TowerGame(Player.WorldInfo.Game).Mods[LoadBlockInfo.M].ModPlaceables[LoadBlockInfo.I], 
				Player.GetTower().NodeTree.Root, LoadBlockInfo.G);
		}
		else
		{
			TowerGame(Player.WorldInfo.Game).AddPlaceable(Player.GetTower(), 
				TowerGame(Player.WorldInfo.Game).Mods[LoadBlockInfo.M].ModPlaceables[LoadBlockInfo.I], 
				Player.GetTower().GetBlockFromLocationAndDirection(LoadBlockInfo.G, LoadBlockInfo.P), 
				LoadBlockInfo.G);
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