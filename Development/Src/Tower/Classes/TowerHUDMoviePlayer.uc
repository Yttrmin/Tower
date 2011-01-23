/**
* TowerHUDMoviePlayer
*
* The UnrealScript side of the Flash HUD SWF.
* This will not work in the iOS build for obvious reasons!
*/
class TowerHUDMoviePlayer extends GFxMoviePlayer;

var TowerHUD HUD;

/** Called by ActionScript along with the X and Y coordinates of the mouse.
Keep in mind this is the coordinates in the Flash movie, it won't match the game immediately unless it's at the same resolution!
Really need to check out his this acts at different resolutions and aspect ratios! */
event OnMouseClick(float X, float Y)
{
	local TowerBlock Block;
	local Vector HitNormal;
	TraceForBlock(X, Y, Block, HitNormal);
	if(Block != None)
	{
		HUD.BlockClicked(Block, HitNormal);
	}
}

//@TODO: Move as much of these functions out of Flash and into UnrealScript as possible.
// You can alter all the same things on the scene that Flash does from UnrealScript, so there's
// no reason for this huge function chain. It's also much more convenient to 

function LockMouseToCenter(bool bMakeInvisible)
{
	ActionScriptVoid("LockMouseToCenter");
}

function LockMouseToCurrentLocation(bool bMakeInvisible)
{
	ActionScriptVoid("LockMouseToCurrentLocation");
}

function UnlockMouse(bool bMakeVisible)
{
	ActionScriptVoid("UnlockMouse");
}

function SetRoundNumber(coerce String Round)
{
	SetVariableString("_root.Round.text", Round);
}

function SetRoundTime(float NewTime)
{
	ActionScriptVoid("SetRoundTime");
}

function TraceForBlock(out float X, out float Y, out TowerBlock Block, out Vector HitNormal)
{
	local Vector2D Mouse;
	local Vector WorldOrigin, WorldDir;
	local Vector HitLocation;
	X *= HUD.RatioX;
	Y *= HUD.RatioY;
	Mouse.X = X/HUD.SizeX;
	Mouse.Y = Y/HUD.SizeY;
	// DeProjection is done through LocalPlayer, else we'd have to wait for PostRender and then it just gets
	// messy to do it. This is allegedly slower than Canvas' deprojection, but hopefully not by much!
	LocalPlayer(HUD.PlayerOwner.Player).DeProject(Mouse, WorldOrigin, WorldDir);
	Block = TowerBlock(HUD.Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000, (WorldOrigin+WorldDir), TRUE));
}

DefaultProperties
{
	MovieInfo=SwfMovie'TowerHUD.HUD'
	bAutoPlay=TRUE
	bPauseGameWhileActive=FALSE
	//bCaptureInput=TRUE
	bAllowFocus=TRUE
	bIgnoreMouseInput=FALSE
}

