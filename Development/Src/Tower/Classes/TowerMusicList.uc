/**
TowerMusicList

Holds SoundCues that represent the music to be played throughout the game for certain events.
Keep in mind instances of this class ONLY exist as archetypes, so no non-static functions!
*/
class TowerMusicList extends Object
	AutoExpandCategories(TowerMusicList)
	placeable;

var() array<SoundCue> OverrideMusic;
var() array<SoundCue> BuildMusic;
var() array<SoundCue> RoundMusic;

