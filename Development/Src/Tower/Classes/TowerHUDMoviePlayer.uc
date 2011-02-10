/**
* TowerHUDMoviePlayer
*
* The UnrealScript side of the Flash HUD SWF.
* This will work in the iOS build starting with the March UDK version.
*/
class TowerHUDMoviePlayer extends GFxMoviePlayer;

var TowerHUD HUD;

/** Takes Vector2D and fills it with current mouse coordinates.
If bRelativeToViewport is TRUE, the Mouse values are between 0 and 1. If FALSE, the Mouse values
are the coordinates in pixels. */
function GetMouseCoordinates(out Vector2D Mouse, bool bRelativeToViewport)
{
	Mouse.X = GetVariableNumber("_root.MouseCursor._x") * HUD.RatioX;
	Mouse.Y = GetVariableNumber("_root.MouseCursor._y") * HUD.RatioY;
	if(bRelativeToViewport)
	{
		Mouse.X /= HUD.SizeX;
		Mouse.Y /= HUD.SizeY;
	}
}

//@TODO: Move as much of these functions out of Flash and into UnrealScript as possible.
// You can alter all the same things on the scene that Flash does from UnrealScript, so there's
// no reason for this huge function chain. It's also much more convenient to edit UnrealScript.

function ExpandBuildMenu()
{
	GetVariableObject("_root.BuildMenu").GotoAndStopI(2);
}

function CollapseBuildMenu()
{
	GetVariableObject("_root.BuildMenu").GotoAndStopI(1);
}

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

DefaultProperties
{
	MovieInfo=SwfMovie'TowerHUD.HUD'
	bAutoPlay=TRUE
	bPauseGameWhileActive=FALSE
	//bCaptureInput=TRUE
	bAllowFocus=TRUE
	bIgnoreMouseInput=FALSE
}

