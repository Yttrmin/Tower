/**
* TowerHUDMoviePlayer
*
* The UnrealScript side of the Flash HUD SWF.
* This will work in the iOS build starting with the March UDK version.
*/
class TowerHUDMoviePlayer extends GFxMoviePlayer
	config(Tower);

var TowerHUD HUD;
var float MouseX, MouseY;

var GFxScrollingList BuildList;
var array<int> BuildIndexes;

var private const bool bUseGFxBlockPreview;
var protectedwrite bool bInMenu;

const SWF_WIDTH = 1024;
const SWF_HEIGHT = 768;
const SWF_MIDDLE_X = 512;
const SWF_MIDDLE_Y = 368;

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget)
{
	if(WidgetName == 'PlaceablesList')
	{
		BuildList = GFxScrollingList(Widget);
		BuildList.HUDMovie = Self;
		return TRUE;
	}
	return FALSE;
}

/** Called from TowerHUD::DrawHUD. */
event DrawHUD(Canvas Canvas)
{
	if(!bUseGFxBlockPreview)
	{
		// 674 on a 1024x768.
		Canvas.SetPos(421, 64);
		Canvas.DrawTextureBlended(HUD.GetPreviewRenderTarget(), 640/1024, BLEND_Opaque);
	}
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
	SetBuildMenuInfo(HUD.PlaceBlock);
	if(bUseGFxBlockPreview)
	{
		SetVariableBool("_root.BuildMenu.BlockPreview._visible", true);
		//@BUG Camera output is black for some reason? Lights don't work? Works in editor except for block.
		SetExternalTexture("HUDPreview", HUD.GetPreviewRenderTarget());
	}
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

function SetKeyBindings()
{
	local TowerPlayerInput Input;
	Input = TowerPlayerInput(TowerPlayerController(HUD.Owner).PlayerInput);
	SetVariableString("_root.BuildMenu.MenuButton.BindingKey.text", String(Input.GetKeyFromCommand("ToggleBuildMenu True | OnRelease ToggleBuildMenu False")));
}

/** Called by ActionScript when the user clicks a new item in the BuildMenu's PlaceablesList. */
event OnBuildListChange(int Index)
{
	local TowerBlock BlockArchetype;
//	if(BuildIndexes[Index]TowerGameReplicationInfo(HUD.WorldInfo.GRI).Blocks
	if(Index < BuildIndexes.Length)
	{
		BlockArchetype = TowerGameReplicationInfo(HUD.WorldInfo.GRI).RootMod.FindBlockArchetypeByIndex(BuildIndexes[Index]);
		TowerMapInfo(HUD.WorldInfo.GetMapInfo()).SetPreview(LocalPlayer(HUD.PlayerOwner.Player).ControllerID, BlockArchetype);
		HUD.SetPlaceBlock(BlockArchetype);
		SetBuildMenuInfo(BlockArchetype);
	}
}

event OnMouseMove(float DeltaX, float DeltaY)
{
//	DeltaX *= HUD.RatioX;
//	DeltaY *= -HUD.RatioY;
	DeltaX /= HUD.RatioX;
	DeltaY /= -HUD.RatioY;
	MouseX = FClamp(MouseX + DeltaX, 0, SWF_WIDTH);
	MouseY = FClamp(MouseY + DeltaY, 0, SWF_HEIGHT);
	MoveCursor();
//	`log(DeltaX@DeltaY);
}

function SetBuildMenuInfo(TowerBlock BlockArchetype)
{
	SetVariableString("_root.BuildMenu.BlockName.text", BlockArchetype.DisplayName);
	SetVariableString("_root.BuildMenu.BlockDescription.text", BlockArchetype.Description);
	SetVariableString("_root.BuildMenu.BlockCost.text", "$"$BlockArchetype.PurchasableComponent.Cost);
	SetVariableString("_root.BuildMenu.BlockHealth.text", "+"$BlockArchetype.HealthMax);
}

function MoveCursor()
{
	SetVariableNumber("_root.MouseCursor._x", MouseX); 
	SetVariableNumber("_root.MouseCursor._y", MouseY);
	if(BuildList.HitTest(MouseX, MouseY))
	{
		BuildList.MousedOn();
	}
	else if(BuildList.bMousedOnPreviousFrame)
	{
		BuildList.MousedOff();
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
	MouseX = SWF_MIDDLE_X
	MouseY = SWF_MIDDLE_Y
	MovieInfo=SwfMovie'TowerHUD.HUD'
	bAutoPlay=TRUE
	bPauseGameWhileActive=FALSE
	//bCaptureInput=TRUE
	bAllowFocus=FALSE
	bIgnoreMouseInput=TRUE

	WidgetBindings(0)={(WidgetName=PlaceablesList,WidgetClass=class'Tower.GFxScrollingList')}
	// Nope, crashes too.
//	ExternalTextures(0)={(Resource="HUDPreview",Texture=TextureRenderTarget2D'TowerHUD.HUDPreview0')}
	bUseGFxBlockPreview=true
	bDisplayWithHudOff=false
	bLogUnhandedWidgetInitializations=true
	TimingMode=TM_Game
}

