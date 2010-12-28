/**
TowerFactionAI

Controls the various factions, deciding on what troops and such to spawn, as well as where and when.
Each faction gets its own AI. Exist server-side only.
*/
class TowerFactionAI extends Actor
	dependson(TowerGame)
	abstract;
/** Note anytime "Troops" is used it includes missiles and such, not just infantry. */

/** Strategy the AI uses during the current round. */ 
enum Strategies
{
	/** Default, used when not at war with anyone and thus not fighting. */
	S_None
};

var() Strategies Strategy;

/** Array of all factions that this faction is at war with. If not in this array, peace is assumed. */
var() array<Factions> AtWar;

// Have each type of troop have a specific cost?
/** Amount of troops remaining that can be spawned. 
The AI is free to spend the budget as it sees fit.*/
var() int TroopBudget;

/** Whether or not the AI is willing to spawn troops in other faction's borders. */
var() bool bInfringeBorders;

/** FALSE during cool-down between rounds, disallowing the AI from spawning troops. */
var bool bCanFight;

event RoundStarted(int AwardedBudget)
{
	TroopBudget = AwardedBudget;
	bCanFight = True;
}

event RoundEnded()
{
	bCanFight = False;
}

DefaultProperties
{
	Strategy=S_None
	RemoteRole=ROLE_None
}