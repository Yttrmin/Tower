/**
SaveSystemJSON

New save system that makes use of JSON instead of hardcoded structs.
*/

/**
JSON Notes:

Ignore JSonObject::ObjectArray!!! Length is not updated when adding objects or anything!
*/
class SaveSystemJSON extends Object;

const SITE_URL = "http://www.cubedefense.com/BugReport.php";
const SAVE_VERSION = 1;
const HARDCODED_MAPPINGS_COUNT = 4;

const MOD_NAME_ID = "SafeName";
const MOD_VERSION_ID = "Version";
const COUNT_ID = "INTERNAL_COUNT";
const UNDEFINED_ID = "UNDEFINED_ASSIGN_A_MAPPING_USING_AddClassCategoryMapping()!";

enum SaveType
{
	ST_NULL,
	/** The "standard" save. Saves to a file on the computer. Only happens during CoolDowns. */
	ST_ToDisk,
	ST_ToCloud,
	ST_ToSite,
	/**  */
	ST_QuickSave
};

struct ClassKeyValue
{
	var Class Key;
	var String Value;
};

struct IntKeyValue
{
	var int Key;
	var int Value;
};

struct GlobalSaveInfo
{
	var array<IntKeyValue> VirtualToRealModIndex;
};

var array<string> SaveData;
var transient ClassKeyValue HardcodedClassCategoryMapping[HARDCODED_MAPPINGS_COUNT];
var array<ClassKeyValue> ClassCategoryMapping;

public function string SaveGame(string FileName, TowerPlayerController Player)
{
	local Actor Actor;
	local SavableDynamic SavableDynamic;
	local JSonObject SaveObject;
	local JSonObject SaveRoot;
	local JSonObject SaveInfo;
	local JSonObject UndefinedObject;

	local String Key;
	local int Count;
	local JSonObject Obj;

	SaveRoot = new class'JSonObject';
	InitializeSaveObjects(SaveRoot);

	UndefinedObject = new class'JSonObject';
	UndefinedObject.SetIntValue(COUNT_ID, 0);
	SaveInfo = new class'JSonObject';

	SerializeSaveInfo(Player, SaveInfo);
	SaveRoot.SetObject("Header", SaveInfo);
	foreach Player.DynamicActors(class'Actor', Actor, class'SavableDynamic')
	{
		SavableDynamic = SavableDynamic(Actor);
		SaveObject = SavableDynamic.OnSave(ST_NULL);
		if(SaveObject != None)
		{
//			`log("Saving"@Actor$"...");
			Key = GetKeyFromClass(SavableDynamic.class);
			if(Key == UNDEFINED_ID)
			{
				`log(Actor@"has an undefined class-key mapping!");
			}
			else
			{
				Obj = SaveRoot.GetObject(Key);
			}
			Count = Obj.GetIntValue(COUNT_ID);
			Obj.SetObject(String(Count), SaveObject);
			Obj.SetIntValue(COUNT_ID, Count+1);
		}
	}
	if(UndefinedObject.GetIntValue(COUNT_ID) != 0)
	{
		/*
		// Causes a crash! Normally we'd just delete this at the end if we could!
//		SaveRoot.SetObject(UNDEFINED_ID, None);
		*/
		SaveRoot.SetObject(UNDEFINED_ID, UndefinedObject);
	}
	`log(class'JSonObject'.static.EncodeJSon(SaveRoot),,'Save');
	return class'JSonObject'.static.EncodeJSon(SaveRoot);
}

public function AddClassCategoryMapping(ClassKeyValue NewMapping)
{

}

private final function String GetKeyFromClass(class TestClass)
{
	local int i;
	for(i = 0; i < HARDCODED_MAPPINGS_COUNT; i++)
	{
		if(ClassIsChildOf(TestClass, HardcodedClassCategoryMapping[i].Key))
		{
			return HardcodedClassCategoryMapping[i].Value;
		}
	}
	for(i = 0; i < ClassCategoryMapping.Length; i++)
	{
		if(ClassIsChildOf(TestClass, HardcodedClassCategoryMapping[i].Key))
		{
			return ClassCategoryMapping[i].Value;
		}
	}
	return UNDEFINED_ID;
}

private function InitializeSaveObjects(out JSonObject Root)
{
	local int i;
	for(i = 0; i < HARDCODED_MAPPINGS_COUNT; i++)
	{
		Root.SetObject(HardcodedClassCategoryMapping[i].Value, new class'JSonObject');
	}
	for(i = 0; i < ClassCategoryMapping.Length; i++)
	{
		Root.SetObject(ClassCategoryMapping[i].Value, new class'JSonObject');
	}
//	Root.SetObject(UNDEFINED_ID, new class'JSonObject');
}

private function SerializeSaveInfo(TowerPlayerController Player, out JSonObject JSon)
{
	local JSonObject Mods;
	Mods = new class'JSOnObject';

	PopulateModList(TowerGameReplicationInfo(Player.WorldInfo.GRI), Mods);
	JSon.SetObject("Mods", Mods);
}

private final function PopulateModList(TowerGameReplicationInfo GRI, out JSonObject JSon)
{
	local TowerModInfo Mod;
	local JSonObject ModObject;
	local int i;

	i = 0;
	for(Mod = GRI.RootMod; Mod != None; Mod = Mod.NextMod)
	{
		ModObject = new class'JSonObject';
		ModObject.SetStringValue(MOD_NAME_ID, Mod.GetSafeName(false));
		ModObject.SetIntValue(MOD_VERSION_ID, Mod.Version);
		JSon.SetObject(string(i), ModObject);
		i++;
	}
}

DefaultProperties
{
	HardcodedClassCategoryMapping(0)=(Key=class'TowerBlock', Value="Blocks")
	HardcodedClassCategoryMapping(1)=(Key=class'Tower', Value="Towers")
	HardcodedClassCategoryMapping(2)=(Key=class'TowerFactionAI', Value="Factions")
	HardcodedClassCategoryMapping(3)=(Key=class'TowerPlayerController', Value="Players")
//	HardcodedClassCategoryMapping(4)=(Key=class'TowerModInfo', Value="Mods")
}