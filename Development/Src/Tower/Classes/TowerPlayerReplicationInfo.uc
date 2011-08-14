class TowerPlayerReplicationInfo extends PlayerReplicationInfo
	config(Tower);

struct ModOption
{
	var String ModName;
	var bool bEnabled;
	var bool bRunForServer;
};

var repnotify Tower Tower;
/** Color used to highlight blocks when mousing over it. Setting this to black disables it. */
var protectedwrite globalconfig LinearColor HighlightColor;
/** How much to mutliply HighlightColor by, so it actually glows. Setting this to 0 disables it.
Setting this to 1 means no bloom assuming HighlightColor has no colors over 1.*/
var protectedwrite globalconfig byte HighlightFactor;

/** When TRUE, TPRI needs to iterate through ALL blocks and calculate their rotations.
Done to avoid a race condition between Tower and TowerBlocks being replicated. */
var bool bBlocksNeedRotation;

/** If TRUE, ModLoaded() in TowerModInfo contains an array of mod names, if FALSE, it contains an
empty array.*/
var protected globalconfig bool bShareModNamesWithMods;
var protected globalconfig bool bDebugMods;

replication
{
	if(bNetInitial)
		Tower, HighlightColor;
}

simulated event ReplicatedEvent(Name VarName)
{
	if(VarName == 'Tower' && bBlocksNeedRotation)
	{
		`log("Tower replicated and updating block rotations");
//		UpdateAllBlockRotations();
	}
	Super.ReplicatedEvent(VarName);
}

simulated function UpdateAllBlockRotations()
{
	local TowerBlockStructural Block;
	foreach DynamicActors(class'TowerBlockStructural', Block)
	{
		Tower.CalculateBlockRotation(Block);
	}
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SetHighlightColor(HighlightColor);
}

reliable server function SetHighlightColor(LinearColor NewColor)
{
	NewColor.R *= HighlightFactor;
	NewColor.G *= HighlightFactor;
	NewColor.B *= HighlightFactor;
	HighlightColor = NewColor;
}

simulated function TowerPlayerController GetPlayerController()
{
	//@TODO - Doesn't handle split screen.
	local TowerPlayerController PC;
	foreach LocalPlayerControllers(class'TowerPlayerController',PC)
	{
		return PC;
	}
}

DefaultProperties
{
	bSkipActorPropertyReplication=False
}