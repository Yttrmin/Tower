class TowerPlayerReplicationInfo extends PlayerReplicationInfo;

var Tower Tower;

replication
{
	if(bNetDirty)
		Tower;
}

DefaultProperties
{
	bSkipActorPropertyReplication=False
}