class TowerFaction extends TeamInfo
	abstract;

var(InGame) editconst int Budget;
var() protectedwrite const name FactionName;
var() editconst FactionLocation Faction;

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerBlock BlockKiller);