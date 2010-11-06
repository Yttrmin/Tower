class TowerPlayerController extends UTPlayerController;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
//	TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower = Spawn(class'Tower');
}

exec function CreateTower(string TowerName, int XBlock, int YBlock, int ZBlock)
{
	ServerCreateTower(TowerName, XBlock, YBlock, ZBlock);
}

exec function AddBlock(int XBlock, int YBlock, int ZBlock, optional int BlockID=0)
{
	`log("ADDED");
}

exec function SetTowerName(string NewName)
{
	ServerSetTowerName(NewName);
}

exec function CLerp(float A, float B, float Alpha)
{
	`log(Lerp(A, B, Alpha));
}

reliable server function ServerCreateTower(string TowerName, int XBlock, int YBlock, int ZBlock)
{
	TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower = Spawn(class'Tower');
	ServerSetTowerName(TowerName);
}

reliable server function ServerSetTowerName(string NewName)
{
	GetTower().TowerName = NewName;
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