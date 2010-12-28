class TowerGameReplicationInfo extends UTGameReplicationInfo;

var byte Phase;
var byte Round;

var bool bRoundInProgress;

var int EnemyCount;
var int MaxEnemyCount;

replication
{
	if(bNetDirty)
		Phase, Round, EnemyCount, MaxEnemyCount;
}

/** Called by TowerGame when cool-down period ends. */
event NextRound()
{
	bRoundInProgress = TRUE;
	Round++;
	// Completely arbitrary at the moment.
	MaxEnemyCount = Round*20;
}

event EndRound()
{
	bRoundInProgress = FALSE;
}