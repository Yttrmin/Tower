class TowerFaction extends TeamInfo
	abstract;

var(InGame) editconst int Budget;
var() protectedwrite const name FactionName;
var(InGame) editconst FactionLocation Faction;

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerBlock BlockKiller);

// Called when all human players have lost.
event OnGameOver();

// Called when skipping a round. All subclasses should implement this properly.
event GoInActive();

function bool HasBudget(int Amount)
{
	return Amount < Budget;
}

function ConsumeBudget(int Amount)
{
	Budget = Max(0, Budget - Amount);
}

state GameOver
{

}