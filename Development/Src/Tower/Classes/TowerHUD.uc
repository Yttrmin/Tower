class TowerHUD extends HUD;

var TowerHUDMoviePlayer HUDMovie;
var TowerBlock LastHighlightedBlock;

var privatewrite TowerBlock PlaceBlock;

event PreBeginPlay()
{
	Super.PreBeginPlay();
	TowerMapInfo(WorldInfo.GetMapInfo()).DeactivateHUDPreview(GetControllerID());
	HUDMovie = new class'TowerHUDMoviePlayer';
	HUDMovie.HUD = self;
	HUDMovie.Init();
	HUDMovie.MoveCursor();
	HUDMovie.LockMouseToCenter(FALSE);
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	if(Owner.Role == ROLE_Authority)
	{
		HUDMovie.SetRoundNumber(TowerGameReplicationInfo(WorldInfo.GRI).Round);
		// Set List
	}
	HUDMovie.SetKeyBindings();
}

/**
 * The Main Draw loop for the hud.  Gets called before any messaging.  Should be subclassed
 */
function DrawHUD()
{
	local int i;
	local vector ViewPoint;
	local rotator ViewRotation;

	local Vector HitNormal;
//	local TowerBlock IterateBlock;
	local TowerBlock TracedBlock;
//	local Tower Tower;

	TraceForBlock(TracedBlock, HitNormal);
	if(LastHighlightedBlock != None && (LastHighlightedBlock != TracedBlock || HUDMovie.bInMenu))
	{
		LastHighlightedBlock.UnHighlight();
		LastHighlightedBlock = None;
	}
	if(TracedBlock != None && !HUDMovie.bInMenu)
	{
		TracedBlock.Highlight();
		LastHighlightedBlock = TracedBlock;
	}
	
	PlayerOwner.GetPlayerViewpoint(ViewPoint, ViewRotation);
	for(i = 0; i < PostRenderedActors.Length; i++)
	{
		if(PostRenderedActors[i] != None)
		{
			PostRenderedActors[i].PostRenderFor(PlayerOwner, Canvas, ViewPoint, Vector(ViewRotation));
		}
	}
	if(HUDMovie.bInMenu)
	{
		HUDMovie.DrawHUD(Canvas);
	}
}

event OnMouseClick(int Button)
{
	local TowerBlock TracedBlock;
	local Vector HitNormal;
	local IVector FinalGridLocation;
	// Left mouse button.
	if(Button == 0)
	{
		if(HUDMovie.bInMenu)
		{
			HUDMovie.BuildList.onMousePress();
		}
		else
		{
			TraceForBlock(TracedBlock, HitNormal);
			if(TracedBlock != None)
			{
				FinalGridLocation = TracedBlock.GridLocation + HitNormal;
				TowerPlayerController(PlayerOwner).AddBlock(PlaceBlock, TracedBlock, FinalGridLocation);
			}
		}
	}
	// Right mouse button.
	else if(Button == 1)
	{
		TraceForBlock(TracedBlock, HitNormal);
		//@TODO - Ask to make sure they want to remove the block?
		// Don't let the player remove the root block.
		if(TracedBlock != None && TowerBlockRoot(TracedBlock) == None)
		{
			TowerPlayerController(PlayerOwner).RemoveBlock(TracedBlock);
		}
	}
}

function SetupBuildList()
{
	//@TODO - Order list.
	local array<String> BuildStrings;
	local TowerBlock IteratedBlock;
	local int i;
	foreach TowerGameReplicationInfo(WorldInfo.GRI).Blocks(IteratedBlock, i)
	{
		if(IteratedBlock.bAddToBuildList)
		{
			`assert(IteratedBlock.PurchasableComponent != None);
			BuildStrings.AddItem(IteratedBlock.DisplayName);
			HUDMovie.BuildIndexes.AddItem(i);
		}
	}
	HUDMovie.SetVariableStringArray("_root.Placeables", 0, BuildStrings);
	HUDMovie.OnBuildListChange(0);
}

event OnMouseRelease(int Button)
{
	if(Button == 0)
	{
		HUDMovie.BuildList.onMouseRelease();
	}
}

event Focus()
{
//	HUDMovie.SetMovieCanReceiveFocus(TRUE);
	//@TODO - This should really just ignore Q instead.
	PlayerOwner.bIgnoreLookInput = 1;
//	HUDMovie.AddCaptureKey('MouseX');
//	HUDMovie.AddCaptureKey('MouseY');
	HUDMovie.SetMovieCanReceiveInput(TRUE);
}

event UnFocus()
{
//	HUDMovie.ClearCaptureKeys();
	PlayerOwner.bIgnoreLookInput = 0;
	HUDMovie.SetMovieCanReceiveInput(FALSE);
}

function Place()
{

}

/** Sets the TowerBlock that the game will attempt to place when the user clicks on a block. */
function SetPlaceBlock(TowerBlock NewBlockArchetype)
{
	Self.PlaceBlock = NewBlockArchetype;
}

function ExpandBuildMenu()
{
	TowerMapInfo(WorldInfo.GetMapInfo()).ActivateHUDPreview(GetControllerID());
	Focus();
	ProcessMouseMovement();
	HUDMovie.ExpandBuildMenu();
	//@FIXME - Commented out line crashes the game, why?!
	HUDMovie.SetExternalTexture("HUDPreview", Texture2D'TowerBlocks.DirectionFaces.back'); // Doesn't crash, works fine.
//	HUDMovie.SetExternalTexture("HUDPreview", TextureRenderTarget2D'TowerHUD.HUDPreview0'); // Immediately crashes.
//	HUDMovie.SetExternalTexture("HUDPreview", GetPreviewRenderTarget());
}

function CollapseBuildMenu()
{
	TowerMapInfo(WorldInfo.GetMapInfo()).DeactivateHUDPreview(GetControllerID());
	UnFocus();
	IgnoreMouseMovement();
	HUDMovie.CollapseBuildMenu();
}

function ProcessMouseMovement()
{
	TowerPlayerInput(TowerPlayerController(Owner).PlayerInput).OnMouseMove = HUDMovie.OnMouseMove;
}

function IgnoreMouseMovement()
{
	TowerPlayerInput(TowerPlayerController(Owner).PlayerInput).OnMouseMove = None;
}

/** */
function TraceForBlock(out TowerBlock Block, out Vector HitNormal)
{
	local Vector WorldOrigin, WorldDir;
	local Rotator PlayerDir;
	local Vector HitLocation;
	PlayerOwner.GetPlayerViewPoint(WorldOrigin, PlayerDir);
	WorldDir = Vector(PlayerDir);
	/*`log(Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000,
		(WorldOrigin+WorldDir), TRUE,, HitInfo)@HitLocation);*/
	Block = TowerBlock(Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000,
		(WorldOrigin+WorldDir), TRUE));
//	DrawDebugLine((WorldOrigin+WorldDir), HitLocation, 255, 0, 0, true);
}

exec function DebugFlushLines()
{
	FlushPersistentDebugLines();
}

function TowerPlayerReplicationInfo GetTPRI()
{
	return TowerPlayerReplicationInfo(TowerPlayerController(Owner).PlayerReplicationInfo);
}

final function int GetControllerID()
{
	// PlayerOwner isn't valid in PreBeginPlay, so we fallback to typecasting Owner in that case.
	if(PlayerOwner != None)
	{
		return LocalPlayer(PlayerOwner.Player).ControllerID;
	}
	else
	{
		return LocalPlayer(TowerPlayerController(Owner).Player).ControllerID;
	}
}

final function TextureRenderTarget2D GetPreviewRenderTarget()
{
	return SceneCapture2DComponent(TowerMapInfo(WorldInfo.GetMapInfo()).PreviewAreas[GetControllerID()].PreviewSceneCaptureActor.SceneCapture).TextureTarget;
}

DefaultProperties
{
//	PlaceableBlock=class'TowerBlockDebug'
//	PlaceableModule=None
}