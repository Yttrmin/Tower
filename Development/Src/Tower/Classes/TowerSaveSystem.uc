/** Class used to save and load games on the PC. */
class TowerSaveSystem extends Object
	DLLBind(SaveSystem);

const SAVE_FILE_VERSION = 1; 

/** Always the first function to call when saving. Must be matched with an EndFile call.
The file extension is automatically appended to the given FileName. */
dllimport final function bool StartFile(string FileName, coerce byte bSaving);
dllimport final function SetHeader(int Version, coerce byte bJustTower);
dllimport final function SetTowerData(out string TowerName, int BlockCount);
dllimport final function AddBlock(out int ID, out vector GridLocation, out vector ParentDirection);
dllimport final function SetGameData(out int Round);
dllimport final function EndFile();

dllimport final function SaveAllData(int Version, coerce byte bTowerOnly, string TowerName, 
	int NodeCount);
dllimport final function ReadAllFile();

dllimport final function GetHeader(out int Version, out byte bJustTower);
dllimport final function GetTowerData(out string TowerName, out int BlockCount);

function SaveGame(string FileName, bool bJustTower, TowerPlayerController Player)
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

	}
	EndFile();
	/**
	SetTowerData();
	foreach 
	*/
}

function LoadGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	local int Version, BlockCount, i;
	local byte bTowerOnly;
	local String TowerName;
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
	for(i = 0; i < 256; i++)
	{
		TowerName $= "X";
	}
	GetTowerData(TowerName, BlockCount);
	`log("Tower Name:"@TowerName);
	`log("BlockCount:"@BlockCount);
	EndFile();
}