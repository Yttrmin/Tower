interface SavableStatic 
	dependson(SaveSystemJSON);

/** Called when saving a game. Returns a string representation of a JSON object, or an empty string to not save this. */
public event String OnStaticSave(SaveType SaveType);

/** Called when loading a game. This function is intended for bStatic objects. */
public event OnStaticLoad(JSONObject Data);