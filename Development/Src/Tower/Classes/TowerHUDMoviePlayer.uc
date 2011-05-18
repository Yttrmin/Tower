/**
* TowerHUDMoviePlayer
*
* The UnrealScript side of the Flash HUD SWF.
* This will work in the iOS build starting with the March UDK version.
*/
class TowerHUDMoviePlayer extends GFxMoviePlayer;

var TowerHUD HUD;
var float MouseX, MouseY;

var GFxScrollingList PlaceablesList;
var array<int> PlaceableIndex;
var array<string> PlaceableStrings;

var protectedwrite bool bInMenu;

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget)
{
	if(WidgetName == 'PlaceablesList')
	{
		PlaceablesList = GFxScrollingList(Widget);
		PlaceablesList.HUDMovie = Self;
		return TRUE;
	}
	return FALSE;
}

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
	bInMenu = TRUE;
	UnlockMouse(true);
	MoveCursor();
	GetVariableObject("_root.BuildMenu").GotoAndStopI(2);
}

function CollapseBuildMenu()
{
	bInMenu = FALSE;
	LockMouseToCenter(false);
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

/** Called by ActionScript when the user clicks a new item in the BuildMenu's PlaceablesList. */
event OnBuildListChange(int Index)
{
	`log("New Index:"@Index);
	TowerMapInfo(HUD.WorldInfo.GetMapInfo()).SetPreview(
		TowerGameReplicationInfo(HUD.WorldInfo.GRI).Placeables[PlaceableIndex[Index]]);
	HUD.SetPlaceable(TowerGameReplicationInfo(HUD.WorldInfo.GRI).Placeables[PlaceableIndex[Index]]);
}

event OnMouseMove(float DeltaX, float DeltaY)
{
	DeltaX *= HUD.RatioX;
	DeltaY *= -HUD.RatioY;
	MouseX = FMax(FMin(MouseX + DeltaX, 1024), 0);
	MouseY = FMax(FMin(MouseY + DeltaY, 768), 0);
	MoveCursor();
//	`log(DeltaX@DeltaY);
}

function MoveCursor()
{
	SetVariableNumber("_root.MouseCursor._x", MouseX); 
	SetVariableNumber("_root.MouseCursor._y", MouseY);
	if(PlaceablesList.HitTest(MouseX, MouseY))
	{
		PlaceablesList.MousedOn();
	}
	else if(PlaceablesList.bMousedOnPreviousFrame)
	{
		PlaceablesList.MousedOff();
	}
}

function bool HitTest(GFxObject Object, int X, int Y)
{
	local array<ASValue> Arguments;
	local ASValue Arg, ReturnBool;
	Arg.Type = AS_Number;
	Arg.n = X;
	Arguments.AddItem(Arg);
	Arg.n = Y;
	Arguments.AddItem(Arg);

	ReturnBool = Object.Invoke("hitTest", Arguments);
	return ReturnBool.b;
}

DefaultProperties
{
	MouseX = 512
	MouseY = 384
	MovieInfo=SwfMovie'TowerHUD.HUD'
	bAutoPlay=TRUE
	bPauseGameWhileActive=FALSE
	//bCaptureInput=TRUE
	bAllowFocus=TRUE
	bIgnoreMouseInput=TRUE

	WidgetBindings(0)={(WidgetName=PlaceablesList,WidgetClass=class'Tower.GFxScrollingList')}

	bDisplayWithHudOff=false
}

