class TowerMapInfo extends MapInfo;

var() const Volume RadarVolume;

var() const int XBlocks;
var() const int YBlocks;
var() const int ZBlocks;

// Move me to TowerGame thanks.
var() const editconst int BlockWidth;
var() const editconst int BlockHeight;

DefaultProperties
{
	// 256 probably best, could fit several people in.
	BlockWidth = 256
	BlockHeight = 256
}