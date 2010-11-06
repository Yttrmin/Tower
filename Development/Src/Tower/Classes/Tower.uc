class Tower extends Actor;

var TowerBlock Modules[100];
var string TowerName;

replication
{
	if(bNetDirty)
		TowerName, Modules;
}

DefaultProperties
{
	RemoteRole=ROLE_SimulatedProxy
}