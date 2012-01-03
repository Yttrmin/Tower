class TowerGameReplicationInfo extends GameReplicationInfo
	dependson(TowerMusicManager);

var protectedwrite bool bRoundInProgress;

// RENAME ME
var int MaxEnemyCount;

var bool bModsLoaded;
var TowerModInfo RootMod;
var repnotify byte Round;

var Vector GridOrigin;

var TowerPlayerReplicationInfo ServerTPRI;

// For clients.
/** For whatever reason beyond my control, RootMod is replicated several times. Let's stop loading it. */
var private bool bRootModReplicated;

replication
{
	if(bNetDirty)
		bRoundInProgress, Round;
	if(bNetInitial)
		ServerTPRI, GridOrigin;
}

simulated event PreBeginPlay()
{
	Super.PreBeginPlay();
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	`log("TGRI PBP");
}

simulated event ReplicatedEvent(name VarName)
{
	Super.ReplicatedEvent(VarName);
	if(VarName == 'Round')
	{
		TowerPlayerController(GetALocalPlayerController()).UpdateRoundNumber(Round);
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