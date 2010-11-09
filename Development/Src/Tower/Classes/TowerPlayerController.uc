class TowerPlayerController extends UTPlayerController;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
//	TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower = Spawn(class'Tower');
}

exec function AddBlock(class<TowerBlock> BlockClass, int XBlock, int YBlock, int ZBlock)
{
	ServerAddBlock(class'TowerBlockDebug', XBlock, YBlock, ZBlock);
}

exec function SetTowerName(string NewName)
{
	ServerSetTowerName(NewName);
}

reliable server function ServerAddBlock(class<TowerBlock> BlockClass, int XBlock, int YBlock, int ZBlock)
{
	TowerGame(WorldInfo.Game).AddBlock(GetTower(), BlockClass, XBlock, YBlock, ZBlock);
}

reliable server function ServerSetTowerName(string NewName)
{
	TowerGame(WorldInfo.Game).SetTowerName(GetTower(), NewName);
}

function Tower GetTower()
{
	return TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower;
}

state Master extends Spectating
{

}

DefaultProperties
{
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.LightIcons.Light_Point_Stationary_Statics'
		Scale=1  // we are using 128x128 textures so we need to scale them down
		HiddenGame=False
		AlwaysLoadOnClient=True
		AlwaysLoadOnServer=True
	End Object
	Components.add(Sprite)
}