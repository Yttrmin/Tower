class TowerMusicManager extends Info
	config(Tower);

enum MusicType
{
	MT_None
};

enum MusicEvent
{
	ME_None,
	ME_StartBuilding,
	ME_StartRound,
	ME_EndRound
};

/** Owner of this MusicManager */
var TowerPlayerController PlayerOwner;
var globalconfig bool bEnable;
/** Maximum volume for music audiocomponents (max value for VolumeMultiplier). */
var globalconfig float MusicVolume;
/** Path to a TowerMusicList. It will be DynamicLoadObject()'d upon initializing a TowerMusicManager. */
var globalconfig string MusicListPath;
var globalconfig bool bAllowMusicFromMods;
/** Only music in the OverrideMusic array of a TowerMusicList will be played. */
var globalconfig bool bUseOverrideMusic;
/** If FALSE, a new OverrideMusic song will be picked when a MusicEvent is received.
If TRUE, new songs will only be picked when the previous one finishes.
No effect is bUseOverrideMusic == false. */
var globalconfig bool bIgnoreMusicEventsWhenOverride;

var AudioComponent CurrentSong;
var TowerMusicList CurrentMusicList;

function Initialize()
{
	CurrentMusicList = TowerMusicList(DynamicLoadObject(MusicListPath, class'TowerMusicList', false));
}

reliable client event OnMusicEvent(MusicEvent Event)
{
	switch(Event)
	{
	case ME_StartBuilding:
		PlayMusic(CurrentMusicList.BuildMusic[0]);
		break;
	case ME_StartRound:
		PlayMusic(CurrentMusicList.RoundMusic[0]);
		break;
	}
}

function PlayOverrideMusic(int Index)
{
	if(Index < CurrentMusicList.OverrideMusic.Length)
	{
		PlayMusic(CurrentMusicList.OverrideMusic[Index]);
	}
}

private function PlayMusic(SoundCue SoundCue)
{
	if(bEnable)
	{
		StopMusic();
		CurrentSong.SoundCue = SoundCue;
		CurrentSong.Play();
	}
}

function StopMusic()
{
	if(CurrentSong.IsPlaying())
	{
		CurrentSong.Stop();
	}
}

DefaultProperties
{
	Begin Object Class=AudioComponent Name=Music
		
	End Object
	CurrentSong=Music
}