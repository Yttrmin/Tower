class TowerGameReplicationInfo extends GameReplicationInfo;

var byte Phase;
var repnotify byte Round;

var bool bRoundInProgress;

var int EnemyCount;
var int MaxEnemyCount;

var repnotify float ReplicatedTime;

replication
{
	if(bNetDirty)
		Phase, Round, EnemyCount, MaxEnemyCount, ReplicatedTime;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
}

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == 'Round')
	{
		UpdateRoundCount();
	}
	else if(VarName == 'ReplicatedTime')
	{
		SetGameTimer();
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

/** Called whenever ReplicatedTime is replicated. */
simulated event SetGameTimer()
{
	TowerHUD(GetPlayerController().myHUD).HUDMovie.SetRoundTime(ReplicatedTime);
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