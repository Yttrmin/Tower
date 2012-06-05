/**
SaveSystemJSON

New save system that makes use of JSON instead of hardcoded structs.
*/

/**
JSON Notes:

Ignore JSonObject::ObjectArray!!! Length is not updated when adding objects or anything!
*/
//@TODO - Please comment.
class SaveSystemJSON extends Object;

/***/
const SITE_URL = "http://www.cubedefense.com/BugReport.php";
/**  */
const HARDCODED_MAPPINGS_COUNT = 4;
/** BasicSave/LoadObject parameter. Used to abort loading old saves. */
const SAVE_FILE_VERSION = 1;
const SAVE_FILE_EXTENSION = ".bin";
const SAVE_FILE_PATH = "../../UDKGame/Saves/";


const MOD_NAME_ID = "SafeName";
const MOD_VERSION_ID = "Version";
const TAG_ID = "";
const COUNT_ID = "INTERNAL_COUNT";
const UNDEFINED_ID = "UNDEFINED_ASSIGN_A_MAPPING_USING_AddClassCategoryMapping()!";

enum SaveType
{
	ST_NULL,
	/** The "standard" save. Saves to a file on the computer. Only happens during CoolDowns. */
	ST_ToDisk,
	ST_ToObject,
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
	/** If TRUE, uses SavableDynamic. If FALSE, uses SavableStatic. */
//	var bool bDynamic;
};

struct GlobalSaveInfo
{
	var array<IntKeyValue> VirtualToRealModIndex;
	var string MapName;
	var class<TowerGameBase> GameInfoClass;
};

//var SaveType Type;
/** Holds the encoded JSON string that's then saved/loaded through BasicSave/LoadObject(). */
var string SaveData;
// Hardcoded for order?
/** Holds essential, order-dependent mappings. */
var transient ClassKeyValue HardcodedClassCategoryMapping[HARDCODED_MAPPINGS_COUNT];
/** Holds mappings supplied by ModInfos. Order is */
var transient array<ClassKeyValue> ClassCategoryMapping;

//@TODO - Type?
/** Returns the save data, an encoded JSON string. */
public function string SaveGame(string FileName, TowerPlayerController Player)
{
	/** Iterator variable. */
	local Actor Actor;
	/** Iterator variable. */
	local SavableDynamic SavableDynamic;
	local JSonObject SaveObject;
	/** The "container" of the whole save. */
	local JSonObject SaveRoot;
	local JSonObject SaveInfo;
	/** Special subcontainer. Holds data for classes with a Savable interface but no mapping.
	Mostly just for debugging, so you can plainly see what's not mapped properly. */
	local JSonObject UndefinedObject;
//	local JSONObject DynamicRoot, StaticRoot;

	local String Key;
	local int Count;
	/** Iterator variable. */
	local JSonObject Obj;

	SaveRoot = new class'JSonObject';
//	DynamicRoot = new class'JSONObject';
//	StaticRoot = new class'JSONObject';

	// Preps SaveRoot to hold the entire save. Creates hardcoded and regular mappings.
	InitializeSaveObjects(SaveRoot);

	UndefinedObject = new class'JSonObject';
	UndefinedObject.SetIntValue(COUNT_ID, 0);
	SaveInfo = new class'JSonObject';

	SaveHeader(Player, SaveInfo);
	SaveRoot.SetObject("Header", SaveInfo);
	// Iterates through all Actors to check for SavableDynamic ones and save them.
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
				`log(Actor@"has an undefined class-key mapping!",,'SaveError');
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

	foreach Player.AllActors(class'Actor', Actor, class'SavableStatic')
	{
		//@TODO - Functionize me.
		SaveObject = SavableStatic(Actor).OnStaticSave(ST_NULL);
		// Check afterwards so Actors get a chance to set/modify their tag.
		if(Actor.Tag == '')
		{
			`log(Actor@"is SavableStatic yet has no tag! Ignoring!",,'SaveError');
			continue;
		}
		if(SaveObject != None)
		{
			Key = GetKeyFromClass(Actor.class);
			if(Key == UNDEFINED_ID)
			{
				`log(Actor@"has an undefined class-key mapping!",,'SaveError');
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
		SaveRoot.SetObject(UNDEFINED_ID, None);
		*/
		SaveRoot.SetObject(UNDEFINED_ID, UndefinedObject);
	}
	`log(class'JSonObject'.static.EncodeJSon(SaveRoot),,'Save');
	return class'JSonObject'.static.EncodeJSon(SaveRoot);
}

public function bool LoadGame(string FileName, TowerGameBase Game)
{
	local string RealFileName;
	local JSONObject Data;
	RealFileName = GetFilePath(FileName);
	if(!class'Engine'.static.BasicLoadObject(self, RealFileName, true, SAVE_FILE_VERSION))
	{
		`warn("Failed to load file at"@RealFileName);
		return false;
	}
	Data = class'JSONObject'.static.DecodeJSON(SaveData);
	if(Data == None)
	{
		`warn("Failed to convert SaveData to JSONObject!");
		return false;
	}
	InternalLoad(Data);
	Game.OnLoadGame(Data);
	class'WorldInfo'.static.GetWorldInfo().ForceGarbageCollection(true);
	return true;
}

/** Tries to load any SavableStatic objects that weren't loaded by the initial LoadGame().
Used for TowerPlayerControllers, which are SavableStatic yet don't all exist at load time. */
public function RetryLoadStatic(optional class<Actor> TargetClass)
{

}

private function InternalLoad(out JSonObject Data)
{
	local JSonObject Obj, SubObj, Header;
	local ClassKeyValue KV;
	local GlobalSaveInfo SaveInfo;
	local string Tag;
	local SavableStatic StaticActor;
	local int i, Count;
	local bool bStatic;
	local TowerGameBase Game;
	Game = TowerGameBase(class'WorldInfo'.static.GetWorldInfo().Game);
	Header = Data.GetObject("Header");
	`assert(Header != None);

	LoadHeader(SaveInfo, Header);

	for(i = 0; i < HARDCODED_MAPPINGS_COUNT; i++)
	{
		Obj = Data.GetObject(HardcodedClassCategoryMapping[i].Value);
		Count = Obj.GetIntValue(COUNT_ID);
	}
	foreach ClassCategoryMapping(KV)
	{
		Obj = Data.GetObject(KV.Value);
		Count = Obj.GetIntValue(COUNT_ID);
		bStatic = KV.Key == class'SavableStatic';
		for(i = 0; i < Count; i++)
		{
			SubObj = Obj.GetObject(string(i));
			if(bStatic)
			{
				// We have to find the specific instance.
				Tag = Obj.GetStringValue(TAG_ID);
				StaticActor = GetActorByTag(Tag);
				if(StaticActor == None)
				{
					continue;
				}
				StaticActor.OnStaticLoad(SubObj);
			}
			else
			{
				// It's a SavableDynamic. Call the static class function.
				SavableDynamic(KV.Key).OnLoad(SubObj, Game, SaveInfo);
			}
		}
	}
}

private function SavableStatic GetActorByTag(const out string Tag)
{
	return None;
}

//@TODO - Removed? We need some way to distinguish.
public function byte GetSavedPlayerCount(){}

private function InternalSave(out SaveType Type)
{
	`assert(Type != ST_NULL);
	switch(Type)
	{
	case ST_ToDisk:
//		class'Engine'.static.BasicSaveObject()
		break;
	}
}

//@TODO - Implement.
public function bool AddClassKeyMapping(class<Actor> NewClass, const String Key, class<Interface> SaveInterfaceClass)
{
	if(SaveInterfaceClass != class'SavableDynamic' && SaveInterfaceClass != class'SavableStatic')
	{
		`warn("Failed to add Class-Key:"@NewClass$"-"$Key$";"@SaveInterfaceClass@"is not a valid save interface class!"@
			"Try SavableDynamic or SavableStatic!");
		return false;
	}
	//@TODO - Prevent adding Tower classes?
	return true;
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

/** Prepares Root as the container for the entire save.
Gives it a JSonObject subcontainer for every class we'll be saving instances of. */
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

/** Stores the Mod list and some essential WorldInfo data. Saved as the Header. */
private function SaveHeader(TowerPlayerController Player, out JSonObject JSon)
{
	local JSonObject Mods, World;
	local WorldInfo WorldInfo;

	WorldInfo = Player.WorldInfo;
	Mods = new class'JSOnObject';
	World = new class'JSONObject';

	PopulateModList(TowerGameReplicationInfo(WorldInfo.GRI), Mods);
	JSon.SetObject("Mods", Mods);

	World.SetStringValue("Map", WorldInfo.GetMapName(true));
	World.SetStringValue("GameInfo", WorldInfo.Game.class.GetPackageName()$"."$WorldInfo.Game.Class);
	JSon.SetObject("WorldInfo", World);
}

private function LoadHeader(out GlobalSaveInfo SaveInfo, out JSonObject JSon)
{
	local TowerModInfo Mod;
	local WorldInfo WorldInfo;
	local array<IntKeyValue> VirtualToRealMod;
	local IntKeyValue IndexMapping;
	local String ModSafeName;
	local int i, u;
	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	`assert(JSon.GetObject("Mods") != None);

	for(i = 0; i < JSon.GetObject("Mods").GetIntValue(COUNT_ID); i++)
	{
		ModSafeName = JSon.GetObject("Mods").GetObject(string(i)).GetStringValue(MOD_NAME_ID);
		u = 0;
		for(Mod = TowerGameReplicationInfo(WorldInfo.GRI).RootMod; true/*Mod != None*/; Mod = Mod.NextMod)
		{
			//@TODO - If the mod doesn't exist anymore we have a problem.
			`assert(Mod != None);
			if(Mod.GetSafeName(false) == ModSafeName)
			{
				break;
			}
			u++;
		}

		IndexMapping.Key = i; // "Virtual", saved mod index.
		IndexMapping.Value = u; // "Real", the current index of the mod this run.
		VirtualToRealMod.AddItem(IndexMapping);
	}

	SaveInfo.VirtualToRealModIndex = VirtualToRealMod;
	SaveInfo.MapName = JSon.GetStringValue("Map");
	SaveInfo.GameInfoClass = class<TowerGameBase>(DynamicLoadObject(JSon.GetStringValue("GameInfo"), class'class', false));
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

/** Returns complete path (directory, filename, extension) to the file. Presumes its in the Saves folder. */
private final function String GetFilePath(out const String FileName)
{
	return SAVE_FILE_PATH$FileName$SAVE_FILE_EXTENSION;
}

DefaultProperties
{
	HardcodedClassCategoryMapping(1)=(Key=class'TowerBlock', Value="Blocks")
	HardcodedClassCategoryMapping(0)=(Key=class'Tower', Value="Towers")
	HardcodedClassCategoryMapping(2)=(Key=class'TowerFactionAI', Value="Factions")
	HardcodedClassCategoryMapping(3)=(Key=class'TowerPlayerController', Value="Players")
//	HardcodedClassCategoryMapping(4)=(Key=class'TowerModInfo', Value="Mods")
}