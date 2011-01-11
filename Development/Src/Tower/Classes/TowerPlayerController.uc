class TowerPlayerController extends GamePlayerController
	config(Tower);

var TowerSaveSystem SaveSystem;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
}

exec function SetHighlightColor(LinearColor NewColor)
{
	TowerPlayerReplicationInfo(PlayerReplicationInfo).SetHighlightColor(NewColor);
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

exec function SaveGame(string FileName, bool bTowerOnly)
{
	if(FileName == "")
	{
		return;
	}
	SaveSystem.SaveGame(FileName, bTowerOnly, self);
}

exec function LoadGame(string FileName, bool bTowerOnly)
{
	if(FileName == "")
	{
		return;
	}
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

event k2override Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	Super.Touch(Other, OtherComp, HitLocation, HitNormal);
	`log("TOUCH");
}

DefaultProperties
{
	CollisionType=COLLIDE_BlockAll
	bCollideActors=true
	bCollideWorld=true
	bBlockActors=true
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0034.000000
		CollisionHeight=+0078.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
}