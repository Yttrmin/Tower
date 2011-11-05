/**
GFxClikWidgetManualEvents

Base class for Clik widgets that we call events for through UnrealScript, instead of having Flash handle it.
It's intended for the SWF to have a transparent movie clip blocking real mouse input, and manipulate
the MovieClip mouse cursor directly based on input instead of just attaching it to the mouse.
*/
class GFxClikWidgetManualEvents extends GFxClikWidget
	abstract;

var TowerHUDMoviePlayer HUDMovie;
var privatewrite bool bMousedOnPreviousFrame;

event OnMouseOn()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
	bMousedOnPreviousFrame = true;
}

event OnMouseOff()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
	onRollOut();
	bMousedOnPreviousFrame = FALSE;
}

event OnRollOut()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
}

event OnRollOver()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
}

event OnMousePress()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
}

event OnMouseRelease()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
}

event OnMouseReleaseOutside()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
}

event OnDragOver()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
}

event OnDragOut()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
}

final function bool HitTest(float X, float Y/*, optional bool bShapeFlag=false*/)
{
	local array<ASValue> Arguments;
	local ASValue Arg, ReturnBool;
	Arg.Type = AS_Number;
	Arg.n = X;
	Arguments.AddItem(Arg);
	Arg.n = Y;
	Arguments.AddItem(Arg);

	// hitTest is MovieClip::hitTest, it's not Clik-specific.
	ReturnBool = Invoke("hitTest", Arguments);
	return ReturnBool.b;
}