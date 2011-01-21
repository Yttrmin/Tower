/**
TowerFactionAI

Controls the various factions, deciding on what troops and such to spawn, as well as where and when.
Each faction gets its own AI. Exist server-side only.
*/
class TowerFactionAI extends Actor
	dependson(TowerGame)
	abstract;
/** Note anytime "Troops" is used it includes missiles and such, not just infantry. */

var TowerFactionInfo FactionInfo;

/** Strategy the AI uses during the current round. */ 
enum Strategies
{
	/** Default, used when not at war with anyone and thus not fighting. */
	S_None,
	S_Spam_Projectile
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

event RoundStarted(const int AwardedBudget)
{
	TroopBudget = AwardedBudget;
	bCanFight = True;
}

event Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);
}

event Think()
{

}

/** Called directly after the round is declared over, before cool-down period. */
event RoundEnded()
{
	bCanFight = False;
}

DefaultProperties
{
	Strategy=S_Spam_Projectile
	RemoteRole=ROLE_None
	Begin Object Class=TowerFactionInfo Name=FactionInfo0
	End Object
	Components.Add(FactionInfo0)
	FactionInfo=FactionInfo0
}