interface SavableDynamic
	dependson(SaveSystemJSON);

/** Called when saving a game. Returns a JSON object, or None to not save this. */
public event JSonObject OnSave(const SaveType SaveType);

/** Called when loading a game. This function is intended for dynamic objects, who should create a new object and load
this data into it. */
public static event OnLoad(JSONObject Data, TowerGameBase GameInfo, out const GlobalSaveInfo SaveInfo);