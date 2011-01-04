class TowerPlayerController extends UTPlayerController;

/** Called on button press, toggles between locked movement with full HUD interaction, and full movement but no interaction. */
exec function ToggleHUDFocus()
{

}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
//	TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower = Spawn(class'Tower');
}

exec function AddBlock(int XBlock, int YBlock, int ZBlock)
{
	`log(XBlock@YBlock@ZBlock);
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