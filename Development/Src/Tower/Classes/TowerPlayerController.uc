class TowerPlayerController extends GamePlayerController
	config(Tower);

/** Color used to highlight blocks when mousing over it. Setting this to black disables it. */
var config LinearColor HighlightColor;
/** How much to mutliply HighlightColor by, so it actually glows. Setting this to 0 disables it. */
var config byte HighlightFactor;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	HighlightColor.R *= HighlightFactor;
	HighlightColor.G *= HighlightFactor;
	HighlightColor.B *= HighlightFactor;
}

/** Called on button press, toggles between locked movement with full HUD interaction, and full movement but no interaction. */
exec function ToggleHUDFocus()
{
	
}

exec function AddBlock(int XBlock, int YBlock, int ZBlock)
{
	ServerAddBlock(class'TowerBlockDebug', XBlock, YBlock, ZBlock);
}

exec function RemoveBlock(int XBlock, int YBlock, int ZBlock)
{
	ServerRemoveBlock(XBlock, YBlock, ZBlock);
}

exec function RemoveAllBlocks()
{
	ServerRemoveAllBlocks();
}

exec function SetTowerName(string NewName)
{
	ServerSetTowerName(NewName);
}

reliable server function ServerAddBlock(class<TowerBlock> BlockClass, int XBlock, int YBlock, int ZBlock)
{
	TowerGame(WorldInfo.Game).AddBlock(GetTower(), BlockClass, XBlock, YBlock, ZBlock);
}

reliable server function ServerRemoveBlock(int XBlock, int YBlock, int ZBlock)
{
	TowerGame(WorldInfo.Game).RemoveBlock(GetTower(), XBlock, YBlock, ZBlock);
}

reliable server function ServerRemoveAllBlocks()
{
	local TowerBlock Block;
	foreach GetTower().Blocks(Block)
	{
		Block.Destroy();
	}
}

reliable server function ServerSetTowerName(string NewName)
{
	TowerGame(WorldInfo.Game).SetTowerName(GetTower(), NewName);
}

function Tower GetTower()
{
	return TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower;
}

//@FIXME
state Master extends Spectating
{

}

DefaultProperties
{

}