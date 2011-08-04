class TowerGameReplicationInfo extends GameReplicationInfo
	dependson(TowerMusicManager);

var protectedwrite bool bRoundInProgress;

// RENAME ME
var int MaxEnemyCount;

var array<TowerBlock> Blocks;

var bool bModsLoaded;
var repnotify int ModCount;
var repnotify TowerModInfo RootMod;
var repnotify MusicEvent MusicEvent;
var repnotify byte Round;

var TowerPlayerReplicationInfo ServerTPRI;

replication
{
	if(bNetDirty)
		bRoundInProgress, MusicEvent, Round;
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
	if(VarName == 'MusicEvent')
	{
		TowerPlayerController(GetALocalPlayerController()).OnMusicEvent(MusicEvent);
	}
	else if(VarName == 'Round')
	{
		TowerPlayerController(GetALocalPlayerController()).UpdateRoundNumber(Round);
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

function CheckRoundInProgress()
{
	bRoundInProgress = TowerGame(WorldInfo.Game).IsRoundInProgress();
}