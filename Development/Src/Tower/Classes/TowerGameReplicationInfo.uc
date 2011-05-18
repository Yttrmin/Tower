class TowerGameReplicationInfo extends GameReplicationInfo;

var byte Phase;
var repnotify byte Round;

var protectedwrite bool bRoundInProgress;

var int MaxEnemyCount;

var array<TowerPlaceable> Placeables;

var bool bModsLoaded;
var repnotify int ModCount;
var repnotify TowerModInfo RootMod;

var TowerPlayerReplicationInfo ServerTPRI;

replication
{
	if(bNetDirty)
		Phase, Round, MaxEnemyCount;
	if(bNetInitial)
		ModCount, RootMod, ServerTPRI;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	AreModsLoaded();
}

simulated event ReplicatedEvent(name VarName)
{
	Super.ReplicatedEvent(VarName);
	if(VarName == 'Round')
	{
		UpdateRoundCount();
	}
	else if(VarName == 'ModCount')
	{
		`log("MOD COUNT REPLICATED:"@ModCount);
	}
	else if(VarName == 'RootMod')
	{
		`log("RootMod replicated!");
		AreModsLoaded();
	}
}

simulated function bool AreModsLoaded()
{
	local int Count;
	local TowerModInfo Mod;
	`log("AREMODSLOADED");
	if(bModsLoaded)
	{
		return true;
	}
	if(ModCount != 0)
	{
		for(Mod = RootMod; Mod != None; Mod = Mod.NextMod)
		{
			if(!Mod.bLoaded)
			{
				LoadMod(Mod);
			}
			Count++;
		}
		`assert(Count <= ModCount);
		if(Count == ModCount)
		{
			// All mods received!
			bModsLoaded = TRUE;
			`log("ALL MODS REPLICATED!");
			ConstructPlaceablesList();
			return TRUE;
		}
		else
		{
			// Haven't received all the mods yet.
			`log("NOT ALL MODS REPLICATED!");
			return FALSE;
		}
	}
	else
	{
		// ModCount hasn't been replicated yet.
		`log("MODCOUNT NOT REPLICATED!");
		return FALSE;
	}
}

simulated function LoadMod(TowerModInfo Mod)
{
	local TowerPlaceable Placeable;
	foreach Mod.ModPlaceables(Placeable)
	{
		Placeables.AddItem(Placeable);
	}
	Mod.bLoaded = TRUE;
}

simulated function ConstructPlaceablesList()
{
	local TowerPlayerController PC;
	`log("Constructing placeables list!");
	foreach LocalPlayerControllers(class'TowerPlayerController', PC)
	{
		`log("FOUND A PLAYER TRING THING");
		TowerHUD(PC.myHUD).SetupPlaceablesList();
	}
}

simulated function UpdateRoundCount()
{
	TowerHUD(GetPlayerController().myHUD).HUDMovie.SetRoundNumber(Round);
}

simulated function TowerPlayerController GetPlayerController()
{
	//@TODO - Doesn't handle split screen.
	local TowerPlayerController PC;
	foreach LocalPlayerControllers(class'TowerPlayerController',PC)
	{
		return PC;
	}
}

/** Called by TowerGame when cool-down period ends. */
event NextRound()
{
	bRoundInProgress = TRUE;
	Round++;
	UpdateRoundCount();
	// Completely arbitrary at the moment.
	MaxEnemyCount = Round*20;
}

event EndRound()
{
	bRoundInProgress = FALSE;
}