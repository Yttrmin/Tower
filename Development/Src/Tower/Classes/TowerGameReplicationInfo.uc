class TowerGameReplicationInfo extends GameReplicationInfo;

var byte Phase;
var repnotify byte Round;

var protectedwrite bool bRoundInProgress;


// RENAME ME
var int MaxEnemyCount;

var array<TowerBlock> Blocks;

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
		OnModReplicated(RootMod);
	}
}

/** Called when a TowerModInfo's NextMod was replicated. */
simulated function OnModReplicated(TowerModInfo Mod)
{
	if(Role < ROLE_Authority)
	{
		if(Mod != None)
		{
			Loadmod(Mod);
			`log(Mod.ModName@"loaded and ready!");
		}
		// We always assume TowerMod exists or will exist, so a ModCount of 0 means the value wasn't replicated yet!
		if(!bModsLoaded && ModCount > 0)
		{
			// Watch out in case RootMod is replicated after another mod (very possible).
			if(RootMod != None && RootMod.GetModCount() == ModCount)
			{
				`log("All mods are loaded!");
				bModsLoaded = true;
				ConstructBuildList();
			}
		}
	}
}

simulated function LoadMod(TowerModInfo Mod)
{
	local TowerBlock Block;
	foreach Mod.ModBlocks(Block)
	{
		Blocks.AddItem(Block);
	}
}

simulated function ConstructBuildList()
{
	local TowerPlayerController PC;
	`log("Constructing build list!");
	foreach LocalPlayerControllers(class'TowerPlayerController', PC)
	{
		TowerHUD(PC.myHUD).SetupBuildList();
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