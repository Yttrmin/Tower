class TowerFaction extends TeamInfo
	abstract;

var() protectedwrite const name FactionName;

var() editconst FactionLocation Faction;

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerPlaceable PlaceableKiller);