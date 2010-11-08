class TowerPlayerController extends UTPlayerController;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
//	TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower = Spawn(class'Tower');
}

exec function TestClass(class AClass)
{
	`log(AClass);
	`log(class'GameEngine'.static.GetOnlineSubsystem());
	OnlineSUbsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ReadOnlineAvatar(
		PlayerReplicationInfo.UniqueId, OnReadOnlineAvatarComplete);
}

/**
 * Notifies the interested party that the avatar read has completed
 *
 * @param PlayerNetId Id of the Player whose avatar this is.
 * @param Avatar the avatar texture. None on error or no avatar available.
 */
function OnReadOnlineAvatarComplete(const UniqueNetId PlayerNetId, Texture2D Avatar)
{
	`log(PlayerNetId.UID.A);
	`log(PlayerNetId.UID.B);
	`log(Avatar);
	`log(Avatar.SizeX);
	`log(Avatar.SizeY);
	`log(Avatar.Format);
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
	ServerAddBlock(TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower, XBlock, YBlock, ZBlock);
	ServerSetTowerName(TowerName);
}

reliable server function ServerAddBlock(Tower Tower, int XBlock, int YBlock, int ZBlock)
{
	Tower.Spawn(class'TowerBlockDebug', Tower, , Vect(0,0,0), Rot(0,0,0));
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