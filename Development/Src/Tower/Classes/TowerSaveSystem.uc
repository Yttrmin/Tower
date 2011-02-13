/** Class used to save and load games on the PC. */
class TowerSaveSystem extends Object
	config(Tower);

struct BlockInfo
{
	// ClassName.
	var int I;
	// GridLocation, ParentDirection.
	var Vector G, P;
};

const SAVE_FILE_VERSION = 1; 

var string SaveTowerName;
var array<String> ClassNames;
var array<BlockInfo> Blocks;

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
	local BlockInfo Info;
	local int ClassIndex;
	CleanupSaveLoadVariables();
	SaveTowerName = Player.GetTower().TowerName;
	//@TODO - Would traversing the tree be safer than this?
	foreach Player.DynamicActors(class'TowerBlock', Block)
	{
		ClassIndex = ClassNames.Find(string(Block.class.outer)$"."$string(Block.class));
		if(ClassIndex == -1)
		{
			ClassNames.AddItem(string(Block.class.outer)$"."$string(Block.class));
			Info.I = ClassNames.Length - 1;
		}
		else
		{
			Info.I = ClassIndex;
		}
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
	local BlockInfo LoadBlockInfo;
	local class<TowerBlock> LoadClass;
	CleanupSaveLoadVariables();
	class'Engine'.static.BasicLoadObject(Self, FileName$".bin", true, SAVE_FILE_VERSION);
	TowerGame(Player.WorldInfo.Game).SetTowerName(Player.GetTower(), Self.SaveTowerName);
	foreach Blocks(LoadBlockInfo, i)
	{
		`log("Loaded Block:"@"Class:"@ClassNames[LoadBlockInfo.I]@"GridLoc:"@LoadBlockInfo.G@"ParentDir:"@LoadBlockInfo.P);
		LoadClass = class<TowerBlock>(DynamicLoadObject(ClassNames[LoadBlockInfo.I], class'class'
			, false));
		//@FIXME - Seriously.
		if(i == 0)
		{

		}
		else if(i == 1)
		{
			TowerGame(Player.WorldInfo.Game).AddBlock(Player.GetTower(), LoadClass, 
				Player.GetTower().NodeTree.Root, 
				LoadBlockInfo.G.X, LoadBlockInfo.G.Y, LoadBlockInfo.G.Z);
		}
		else
		{
		TowerGame(Player.WorldInfo.Game).AddBlock(Player.GetTower(), LoadClass, 
				Player.GetTower().GetBlockFromLocationDirection(LoadBlockInfo.G, LoadBlockInfo.P), 
				LoadBlockInfo.G.X, LoadBlockInfo.G.Y, LoadBlockInfo.G.Z);
		}
	}
}

final function CleanupSaveLoadVariables()
{
	Blocks.Remove(0, Blocks.Length);
	ClassNames.Remove(0, ClassNames.Length);
	SaveTowerName = "MAKE_SURE_I_GET_SET";
}