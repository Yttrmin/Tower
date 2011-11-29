class TowerDamageTrackerComponent extends ActorComponent;

struct FactionDamage
{
	var TowerFaction Faction;
	var int Damage;
};

struct FactionReward
{
	var TowerFaction Faction;
	var int Reward;
};

var private array<FactionDamage> Damage;

function OnTakeDamage(int CappedDamageAmount, Controller EventInstigator, class<DamageType> DamageType, 
	optional Actor DamageCauser)
{
	//@TODO - Throw away friendly fire? Other AI factions?
	local TowerFaction Faction;
	local FactionDamage NewEntry;
	local int Index;
	`assert(CappedDamageAmount >= 0);
	//@TODO - How do we get Faction from either Controller or DamageCauser?
	if(TowerBlock(DamageCauser) != None)
	{
		Faction = TowerFaction(TowerBlock(DamageCauser).OwnerPRI.Team);
	}
	if(Faction == None)
	{
		return;
	}
	Index = Damage.Find('Faction', Faction);
	if(Index == INDEX_NONE)
	{
		NewEntry.Faction = Faction;
		NewEntry.Damage = CappedDamageAmount;
		Damage.AddItem(NewEntry);
	}
	else
	{
		Damage[Index].Damage += CappedDamageAmount;
	}
}

function RewardFactions()
{
	local FactionReward Reward;
	local array<FactionReward> Rewards;
	GetRewards(Rewards);
	foreach Rewards(Reward)
	{
		`log("Rewarding"@Reward.Faction@Reward.Reward);
		Reward.Faction.RewardBudget(Reward.Reward);
	}
}

function GetRewards(out array<FactionReward> Rewards)
{
	local FactionReward RewardIterator;
	local FactionDamage DamageIterator;
	local int Sum;
	local int BudgetReward;
	Sum = GetTotalHealth();
	BudgetReward = TowerTargetable(Owner).GetPurchasableComponent(TowerTargetable(Owner).ObjectArchetype).Cost;
	foreach Damage(DamageIterator)
	{
		RewardIterator.Faction = DamageIterator.Faction;
		RewardIterator.Reward = Round((DamageIterator.Damage / Sum) * BudgetReward);
		Rewards.AddItem(RewardIterator);
	}
}

private final function int GetTotalHealth()
{
	local int Sum;
	local byte i;
	for(i = 0; i < Damage.Length; i++)
	{
		// This is why capping is important!
		Sum += Damage[i].Damage;
	}
	return Sum;
}

//@TODO - If this were to be used for Blocks, need to say add a TowerPurchasable interface and use that instead.
private final function TowerPurchasableComponent GetOwnerPurchasableComponent()
{
	return TowerTargetable(Owner).GetPurchasableComponent(TowerTargetable(Owner));
}