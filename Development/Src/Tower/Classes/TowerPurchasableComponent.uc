class TowerPurchasableComponent extends ActorComponent
	HideCategories(Object)
	EditInlineNew;

var() const privatewrite int BaseCost<UIMin=1.0|ClampMin=1.0|DisplayName="Cost">;
var privatewrite int CostMultiplier;
var privatewrite int Cost;
var privatewrite int SellPrice;

final function CalculateCost(const int Multiplier)
{
	//@TODO - Get from GameInfo?
	CostMultiplier = Multiplier;
	Cost = CostMultiplier * BaseCost;
}

final function int GetCost(const int Multiplier)
{
	return Cost;
}

final function int GetSellPrice()
{

}

DefaultProperties
{
	BaseCost = 1
	Cost = -99999
}