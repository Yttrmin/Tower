/**
TowerForeignVolume

A volume that specifies where factions can spawn projectiles, units, etc.
*/
class TowerForeignVolume extends Volume
	placeable
	deprecated
	dependson(TowerGame);

var() Factions Faction;
var() int XSize, YSize;