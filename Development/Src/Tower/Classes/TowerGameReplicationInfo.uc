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

// For clients.
/** For whatever reason beyond my control, RootMod is replicated several times. Let's stop loading it. */
var private bool bRootModReplicated;

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
		}
		// We always assume TowerMod exists or will exist, so a ModCount of 0 means the value wasn't replicated yet!
		if(!bModsLoaded)
		{
			if(ModCount == 0)
			{
				PushState('WaitForModCount');
			}
			// Watch out in case RootMod is replicated after another mod (very possible).
			if(RootMod != None && RootMod.GetModCount() == ModCount)
			{
				`log("All mods are loaded!");
				bModsLoaded = true;
				ConstructBuildList();
				class'Engine'.static.StopMovie(true);
			}
		}
	}
}

simulated state WaitForModCount
{
Begin:
	`log("WAITFORMODCOUNT");
	if(ModCount == 0)
	{
		`log("LOOP AGAIN");
		goto 'Begin';
	}
	OnModReplicated(None);
	PopState();
}

/**private*/ simulated function LoadMod(TowerModInfo Mod)
{
	local TowerBlock Block;
	if(!Mod.bLoaded)
	{
		foreach Mod.ModBlocks(Block)
		{
			Blocks.AddItem(Block);
		}
		Mod.bLoaded = true;
		`log("Loaded Mod:"@Mod@Mod.AuthorName@Mod.Contact@Mod.Website@Mod.Description@Mod.MajorVersion$"."$Mod.MinorVersion);
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