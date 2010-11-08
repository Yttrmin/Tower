/**
TowerForeignVolume

A volume that specifies where factions can spawn projectiles, units, etc.
*/
class TowerForeignVolume extends Volume
	dependson(TowerGame);

var() Factions Faction;
var() int XSize, YSize;