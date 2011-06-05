class TowerFaction extends TeamInfo
	abstract;

var int Budget;

var() protectedwrite const name FactionName;

var() editconst FactionLocation Faction;

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerBlock BlockKiller);