class TowerAIObjective extends UDKGameObjective
	dependson(TowerGame);

var TowerPlaceable Target;

function TowerShootPoint GetShootPoint(FactionLocation Faction)
{
	return None;
}

DefaultProperties
{
	bStatic=false
	bNoDelete=false
}