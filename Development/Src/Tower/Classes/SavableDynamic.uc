interface SavableDynamic
	dependson(SaveSystemJSON);

/** Called when saving a game. Returns a JSON object, or None to not save this. */
public event JSonObject OnSave(const SaveType SaveType);

/** Called when loading a game. This function is intended for dynamic objects. The object is Spawn()'d immediately
before the OnLoad() call and the contents of Data should be loaded into it. */
public event OnLoad(JSONObject Data, TowerGameBase GameInfo, out const GlobalSaveInfo SaveInfo);