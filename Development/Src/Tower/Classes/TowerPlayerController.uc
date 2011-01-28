class TowerPlayerController extends GamePlayerController
	config(Tower);

var TowerSaveSystem SaveSystem;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
}

exec function ClickDown(int ButtonID)
{
	`log("ClickDown:"@ButtonID);
	TowerHUD(myHUD).OnMouseClick(ButtonID);
}

/** Called when mouse button is released. */
exec function ClickUp(int ButtonID)
{

}

exec function SetHighlightColor(LinearColor NewColor)
{
	TowerPlayerReplicationInfo(PlayerReplicationInfo).SetHighlightColor(NewColor);
}

exec function AddBlock(TowerBlock ParentBlock, int XBlock, int YBlock, int ZBlock)
{
	ServerAddBlock(class'TowerBlockDebug', ParentBlock, XBlock, YBlock, ZBlock);
}

exec function RemoveBlock(TowerBlock Block)
{
	ServerRemoveBlock(Block);
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

exec function RequestUpdateTime()
{
	`log("REQUESTED TIME PLEASE ACTUALLY WORK PLEASE!"@WorldInfo.GRI);
	TowerPlayerReplicationInfo(PlayerReplicationInfo).RequestUpdatedTime();
}

/** Creates a tower to remove the base blocks of and stress test recursion and iteration. */
exec function DebugCreateStressTower()
{
	local int i;
	local TowerBlock Parent;
	// Create the column first.
	AddBlock(GetTower().NodeTree.Root, 0, 0, 1);
	for(i = 2; i < 10; i++)
	{
		AddBlock(GetTower().NodeTree.Root.NextNodes[0], 0, 0, i);
	}
}

reliable server function ServerAddBlock(class<TowerBlock> BlockClass, TowerBlock ParentBlock,
	int XBlock, int YBlock, int ZBlock)
{
	TowerGame(WorldInfo.Game).AddBlock(GetTower(), BlockClass, ParentBlock, XBlock, YBlock, ZBlock);
}

reliable server function ServerRemoveBlock(TowerBlock Block)
{
	TowerGame(WorldInfo.Game).RemoveBlock(GetTower(), Block);
}

reliable server function ServerRemoveAllBlocks()
{
	//@TODO - Make work.
	GetTower().NodeTree.RemoveNode(GetTower().NodeTree.GetRootNode());
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
	ignores StartFire, StopFire;
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