/** Class used to save and load games on the PC. */
class TowerSaveSystem extends Object
	config(Tower)
	DLLBind(SaveSystem);

struct BlockInfo
{
	// ClassName.
	var int I;
	// GridLocation, ParentDirection.
	var Vector G, P;
};

const SAVE_FILE_VERSION = 1; 
const TOWER_NAME_MAX_LENGTH = 256;

var string SaveTowerName;
var array<String> ClassNames;
var array<BlockInfo> Blocks;

/** If TRUE use BasicSave/LoadObject, if FALSE use the SaveSystem DLL. 
DLL Save/Loading should be considered deprecated.*/
var private transient config const bool bUseNativeSavingAndLoading;

/** Always the first function to call when saving. Must be matched with an EndFile call.
The file extension is automatically appended to the given FileName. */
dllimport final function bool StartFile(string FileName, coerce byte bSaving);
dllimport final function SetHeader(int Version, coerce byte bJustTower);
dllimport final function SetTowerData(out string TowerName, int BlockCount);
dllimport final function AddBlock(coerce string BlockClass, coerce byte bRoot, 
	out const vector GridLocation, out const vector ParentDirection);
dllimport final function EndAddBlock();
dllimport final function SetGameData(out int Round); 
dllimport final function EndFile();

dllimport final function SaveAllData(int Version, coerce byte bTowerOnly, string TowerName, 
	int NodeCount);
dllimport final function ReadAllFile();

dllimport final function GetHeader(out int Version, out byte bJustTower);
/** Allocates memory for an array of Blocks that can hold all block data, and reads it in. */
dllimport final function StartGetBlock();
dllimport final function GetBlock(out String BlockClass, out byte bRoot, out Vector GridLocation,
	out Vector ParentDirection);
dllimport final function ClearAllReadBlockData();
dllimport final function GetTowerData(out string TowerName, out int BlockCount);

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
	if(bUseNativeSavingAndLoading)
	{
		NativeSaveGame(FileName, bJustTower, Player);
	}
	else
	{
		DLLSaveGame(FileName, bJustTower, Player);
	}
}

final function LoadGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	if(bUseNativeSavingAndLoading)
	{
		NativeLoadGame(FileName, bJustTower, Player);
	}
	else
	{
		DLLLoadGame(FileName, bJustTower, Player);
	}
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

/** Saves the game using the SaveSystem DLL and dllimport'd functions. PC only. */
final function DLLSaveGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	local TowerBlock Block;
	if(StartFile(FileName, true))
	{
		`log("Successfully created save file.");
	}
	else
	{
		`log("Failed to create save file. Aborting.");
		return;
	}
//	SaveAllData(SAVE_FILE_VERSION, bJustTOwer, Player.GetTower().TowerName, 
//		Player.GetTower().NodeTree.NodeCount);
	SetHeader(SAVE_FILE_VERSION, bJustTower);
	SetTowerData(Player.GetTower().TowerName, Player.GetTower().NodeTree.NodeCount);
	foreach Player.AllActors(class'TowerBlock', Block)
	{
		`log("Adding Block:"@Block.class.outer$"."$Block.class@Block.bRootBlock@Block.GridLocation@Block.ParentDirection);
		AddBlock(Block.class.outer$"."$Block.class, Block.bRootBlock, Block.GridLocation, Block.ParentDirection);
	}
	EndAddBlock();
	EndFile();
	/**
	SetTowerData();
	foreach 
	*/
}

/** Loads the game using the SaveSystem DLL and dllimport'd functions. PC only. */
final function DLLLoadGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	//	local TowerBlock Block;
	local int Version, BlockCount, i, u;
	local byte bTowerOnly;
	local String TowerName;
	local String LoadClassName;
	local byte bLoadRoot;
	local Vector LoadGridLocation, LoadParentDirection;
	local class<TowerBlock> LoadClass;
//	local array<BlockID> BlockIDs;
	if(StartFile(FileName, false))
	{
		`log("Successfully opened save file.");
	}
	else
	{
		`log("Failed to open save file. Aborting.");
		return;
	}
//	ReadAllFile();
	GetHeader(Version, bTowerOnly);
	`log("File version:"@Version);
	`log("bTowerOnly:"@bool(bTowerOnly));
	for(i = 0; i < TOWER_NAME_MAX_LENGTH; i++)
	{
		TowerName $= "X";
	}
	i = 0;
	GetTowerData(TowerName, BlockCount);
	`log("Tower Name:"@TowerName);
	`log("BlockCount:"@BlockCount);
	StartGetBlock();
	for(i = 0; i < BlockCount; i++)
	{
		LoadClassName = "";
		for(u = 0; u < TOWER_NAME_MAX_LENGTH; u++)
		{
			LoadClassName $= "X";
		}
		GetBlock(LoadClassName, bLoadRoot, LoadGridLocation, LoadParentDirection);
		`log("Loaded Block:"@"Class:"@LoadClassName@"bRoot:"@bLoadRoot@"GridLoc:"@LoadGridLocation@"ParentDir:"@LoadParentDirection);
		LoadClass = class<TowerBlock>(DynamicLoadObject(LoadClassName , class'class', false));
		//@TODO - This really needs to be more elegant.
		if(i == 0)
		{

		}
		else if(i == 1)
		{
			TowerGame(Player.WorldInfo.Game).AddBlock(Player.GetTower(), LoadClass, 
				Player.GetTower().NodeTree.Root, 
				LoadGridLocation.X, LoadGridLocation.Y, LoadGridLocation.Z);
		}
		else
		{
			TowerGame(Player.WorldInfo.Game).AddBlock(Player.GetTower(), LoadClass, 
			Player.GetTower().GetBlockFromLocationDirection(LoadGridLocation, LoadParentDirection), 
			LoadGridLocation.X, LoadGridLocation.Y, LoadGridLocation.Z);
		}
	}
	EndFile();
}