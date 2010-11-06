class TowerGameReplicationInfo extends UTGameReplicationInfo;

var byte Phase;
var byte Round;

var int EnemyCount;
var int MaxEnemyCount;

replication
{
	if(bNetDirty)
		Phase, Round, EnemyCount, MaxEnemyCount;
}