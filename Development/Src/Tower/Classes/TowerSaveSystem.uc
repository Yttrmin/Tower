/** Class used to save and load games on the PC. */
class TowerSaveSystem extends Object
	DLLBind(SaveSystem);

const SAVE_FILE_VERSION = 1; 

/** Always the first function to call when saving. Must be matched with an EndFile call.
The file extension is automatically appended to the given FileName. */
dllimport final function StartFile(string FileName);
dllimport final function SetHeader(int Version, coerce byte bJustTower);
dllimport final function SetTowerData(out string TowerName, out int BlockCount);
dllimport final function AddBlock(out int ID, out vector GridLocation);
dllimport final function SetGameData(out int Round);
dllimport final function EndFile();

function SaveGame(string FileName, bool bJustTower, TowerPlayerController Player)
{
	StartFile(FileName);
	SetHeader(SAVE_FILE_VERSION, bJustTower);
	/**
	SetTowerData();
	foreach 
	*/
}