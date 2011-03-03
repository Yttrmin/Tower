class GFxScrollingList extends GFxClikWidget;

var TowerHUDMoviePlayer HUDMovie;
var int RolledOverIndex;
var bool bMousedOnPreviousFrame;

var const array<ASValue> EmptyArguments;

/** Called by TowerHUDMoviePlayer whenever the mouse moves onto us. */
event MousedOn()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
	if(GetRendererIndex() != RolledOverIndex)
	{
		onRollOut();
		onRollOver();
	}
	bMousedOnPreviousFrame = TRUE;
}

/** Called by TowerHUDMoviePlayer whenever the mouse moves off of us. */
event MousedOff()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
	onRollOut();
	bMousedOnPreviousFrame = FALSE;
}

/** Called by us if the mouse is on a different index than RolledOverIndex.
Tells the ItemRenderer at RolledOverIndex that the mouse rolled out. */
event onRollOut()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
	GetRendererAt(RolledOverIndex).Invoke("handleMouseRollOut", EmptyArguments);
}

/** Called by us if the mouse is on a different index than RolledOverIndex.
Tells the ItemRenderer at GetRendererIndex() that the mouse rolled over it.
Sets RolledOverIndex to GetRendererIndex(). */
event onRollOver()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
	GetRendererAt(GetRendererIndex()).Invoke("handleMouseRollOver", EmptyArguments);
	RolledOverIndex = GetRendererIndex();
}

/** Called by TowerHUD when the mouse is clicked down. 
Tells the ItemRenderer at RolledOverIndex that the mouse pressed it down. */
event onMousePress()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
	GetRendererAt(RolledOverIndex).Invoke("handleMousePress", EmptyArguments);
}

/** Called by TowerHUD when the mouse is released. 
Tells the ItemRenderer at RolledOverIndex that the mouse pressed on it has been released. */
event onMouseRelease()
{
	if(!HUDMovie.bInMenu)
	{
		return;
	}
	GetRendererAt(RolledOverIndex).Invoke("handleMouseRelease", EmptyArguments);
}

event onMouseReleaseOutside();

event onDragOver();

event onDragOut();

//@TODO - Not hardcode this.
function int GetRowHeight()
{
	return 20;
}

//@TODO - Not hardcode this.
function int GetRendererIndex()
{
	return (FCeil((122 - (110 + 122 - HudMovie.MouseY))/GetRowHeight())-1) + GetFloat("_scrollPosition");
}

function bool HitTest(float X, float Y, optional bool bShapeFlag=false)
{
	local array<ASValue> Arguments;
	local ASValue Arg, ReturnBool;
	Arg.Type = AS_Number;
	Arg.n = X;
	Arguments.AddItem(Arg);
	Arg.n = Y;
	Arguments.AddItem(Arg);

	ReturnBool = Invoke("hitTest", Arguments);
	return ReturnBool.b;
}

function GFxObject GetRendererAt(float Index)
{
	return ActionScriptObject("getRendererAt");
}