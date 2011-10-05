class TowerLoanComponent extends ActorComponent;

var private int InitialAmount;
var private int RoundIssued, RoundDue;

function TowerFaction IssuedTo()
{
	return TowerFaction(Owner);
}