class TowerMusicManager extends Info
	config(Tower);

enum MusicType
{
	MT_None
};

/** Owner of this MusicManager */
var TowerPlayerController PlayerOwner;
/** Maximum volume for music audiocomponents (max value for VolumeMultiplier). */
var globalconfig float MusicVolume;
var globalconfig string MusicListPath;
var globalconfig bool bAllowMusicFromMods;

var AudioComponent CurrentSong;
var TowerMusicList CurrentMusicList;

function Initialize()
{
	CurrentMusicList = TowerMusicList(DynamicLoadObject(MusicListPath, class'TowerMusicList', false));
}

function PlayOverrideMusic(int Index)
{
	if(Index < CurrentMusicList.OverrideMusic.Length)
	{
		if(CurrentSong.SoundCue != None && CurrentSong.IsPlaying())
		{
			CurrentSong.Stop();
		}
		CurrentSong.SoundCue = CurrentMusicList.OverrideMusic[Index];
		CurrentSong.Play();
	}
}

function PlayMusic(out SoundCue SoundCue)
{

}

function StopMusic()
{
	if(CurrentSong.SoundCue != None)
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