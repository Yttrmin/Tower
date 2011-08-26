class TowerFaction extends TeamInfo
	abstract;

var(InGame) editconst int Budget;
var() protectedwrite const name FactionName;
var(InGame) editconst FactionLocation Faction;

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerBlock BlockKiller);

function bool HasBudget(int Amount)
{
	return Amount < Budget;
}

function ConsumeBudget(int Amount)
{
	Budget = Max(0, Budget - Amount);
}