interface SavableDynamic
	dependson(SaveSystemJSON);

/** Called when saving a game. Returns a string representation of a JSON object, or an empty string to not save this. */
public event String OnSave(SaveType SaveType);

/** Called when loading a game. This function is intended for dynamic objects, who should create a new object and load
this data into it. */
public static event OnLoad(JSONObject Data, out const SaveInfo SaveInfo);