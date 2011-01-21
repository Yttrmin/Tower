class TowerGameReplicationInfo extends GameReplicationInfo;

var byte Phase;
var byte Round;

var bool bRoundInProgress;

var int EnemyCount;
var int MaxEnemyCount;

var repnotify float ReplicatedTime;
var float Time;

replication
{
	if(bNetDirty)
		Phase, Round, EnemyCount, MaxEnemyCount, ReplicatedTime;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	RequestUpdatedTime();
}

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == 'Round')
	{
		`log("ROUND REPLICATED!!!!!~~~~~~~~~~~~~~~~~~~~~~");
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

reliable server function RequestUpdatedTime()
{
	ReplicatedTime = Time;
}

/** Called whenever ReplicatedTime is replicated. */
simulated event SetGameTimer()
{
	//@TODO - What if this is called more than once? Overwrites the timer?
	SetTimer(ReplicatedTime, false, 'GameTimerExpired');
	Time = ReplicatedTime;
}

simulated function float GetRemainingTime()
{
	return GetTimerRate('GameTimerExpired') - GetTimerCount('GameTimerExpired');
}

event GameTimerExpired()
{

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