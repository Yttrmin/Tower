class TowerPlayerInput extends PlayerInput within TowerPlayerController;

`define debugexec `if(`isdefined(debug)) exec `else `define debugconfig `endif

delegate OnMouseMove(float DeltaX, float DeltaY);

/** I predict this'll be painfully slow. If you use it definitely store the result! */
exec function name GetKeyFromCommand(string Command, optional bool bLog=false)
{
	local KeyBind Bind;
	foreach Bindings(Bind)
	{
		if(Bind.Command == Command)
		{
			`log(Bind.Name,bLog);
			return Bind.Name;
		}
	}
	return '';
}

// Postprocess the player's input.
event PlayerInput( float DeltaTime )
{
	//@NOTE - aMouseX and aMouseY are updated even with Scaleform.
	// Process mouse input before this, please.
	if(aMouseX != 0 || aMouseY != 0)
	{
		OnMouseMove(aMouseX, aMouseY);
	}
	Super.PlayerInput(DeltaTime);
}

/** Opens the specified map, and sends along the current mod list so you can properly
connect to Tower servers! */
exec function TowerOpen(string MapName)
{
	/*
	local String Mods;
	local int i;
	local String ModName;
	Mods = "?Mods=";
	foreach class'TowerGame'.default.ModPackages(
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
	*/
}