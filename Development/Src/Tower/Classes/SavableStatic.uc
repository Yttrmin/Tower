interface SavableStatic 
	dependson(SaveSystemJSON);

/** Called when saving a game. Returns a JSON object, or None to not save this. */
public event JSonObject OnStaticSave(const SaveType SaveType);

/** Called when loading a game. */
public event OnStaticLoad(out const JSONObject Data/*, out const GlobalSaveInfo SaveInfo*/);