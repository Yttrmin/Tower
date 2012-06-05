class TowerFaction extends TeamInfo
	implements(SavableDynamic)
	dependson(TowerGameBase)
	abstract;

const BUDGET_ID = "B";
const FACTION_LOCATION_ID = "F";

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

function RewardBudget(int Amount)
{
	Budget += Amount;
}

state GameOver
{

}

/********************************
Save/Loading
********************************/

/** Called when saving a game. Returns a JSON object, or None to not save this. */
public event JSonObject OnSave(const SaveType SaveType)
{
	local JSonObject JSON;
	JSON = new class'JSonObject';
	if (JSON == None)
	{
		`warn(self@"Could not save!");
		return None;
	}

	JSON.SetIntValue(BUDGET_ID, Budget);
	JSON.SetIntValue(FACTION_LOCATION_ID, int(Faction));

	return JSON;
}

/** Called when loading a game. This function is intended for dynamic objects, who should create a new object and load
this data into it. */
public static event OnLoad(JSONObject Data, TowerGameBase GameInfo, out const GlobalSaveInfo SaveInfo){}