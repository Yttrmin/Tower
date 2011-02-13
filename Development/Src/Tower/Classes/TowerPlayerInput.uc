class TowerPlayerInput extends PlayerInput;

/** I predict this'll be painfully slow. If you use it definitely store the result! */
function name GetKeyFromCommand(string Command)
{
	local KeyBind Bind;
	foreach Bindings(Bind)
	{
		if(Bind.Command == Command)
		{
			return Bind.Name;
		}
	}
	return '';
}

/** Opens the specified map, and sends along the current mod list so you can properly
connect to Tower servers! */
exec function OpenEx(string MapName)
{
	local String Mods;
	local int i;
	local TowerModInfo Mod;
	Mods = "?Mods=";
	foreach TowerPlayerReplicationInfo(TowerPlayerController(Owner).PlayerReplicationInfo).Mods(Mod, i)
	{
		if(i > 0)
		{
			Mods $= ";";
		}
		Mods $= Mod.ModName$"|"$Mod.Version;
	}
	MapName $= Mods;
	ConsoleCommand(MapName);
}