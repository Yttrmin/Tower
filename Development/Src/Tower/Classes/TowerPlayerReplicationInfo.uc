class TowerPlayerReplicationInfo extends PlayerReplicationInfo
	config(Tower);

var Tower Tower;
/** Color used to highlight blocks when mousing over it. Setting this to black disables it. */
var config LinearColor HighlightColor;
/** How much to mutliply HighlightColor by, so it actually glows. Setting this to 0 disables it.
Setting this to 1 means no bloom assuming HighlightColor has no colors over 1.*/
var config byte HighlightFactor;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SetHighlightColor(HighlightColor);
	RequestUpdatedTime();
}

reliable server function SetHighlightColor(LinearColor NewColor)
{
	NewColor.R *= HighlightFactor;
	NewColor.G *= HighlightFactor;
	NewColor.B *= HighlightFactor;
	HighlightColor = NewColor;
}

reliable server function RequestUpdatedTime()
{
	TowerGameReplicationInfo(WorldInfo.GRI).ReplicatedTime = 
		TowerGame(WorldInfo.Game).GetRemainingTime();
	`log("UPDATED TIME! NEW VALUE:"@TowerGameReplicationInfo(WorldInfo.GRI).ReplicatedTime);
}

replication
{
	if(bNetDirty)
		Tower, HighlightColor;
}

DefaultProperties
{
	bSkipActorPropertyReplication=False
}