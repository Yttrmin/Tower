class SaveSystemJSON extends Object;

const SITE_URL = "http://www.cubedefense.com/BugReport.php";
const SAVE_VERSION = 1;

var array<string> SaveData;

enum SaveType
{
	/** The "standard" save. Saves to a file on the computer. Only happens during CoolDowns. */
	ST_ToDisk,
	ST_ToCloud,
	ST_ToSite,
	/**  */
	ST_QuickSave
};

struct IntKeyValue
{
	var int Key;
	var int Value;
};

struct SaveInfo
{
	var array<IntKeyValue> VirtualToRealModIndex;
};

public function SaveGame(string FileName, TowerPlayerController Player)
{

}

private function SerializeSaveInfo()
{

}