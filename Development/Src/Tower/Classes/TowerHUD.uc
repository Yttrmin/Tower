class TowerHUD extends HUD;

var TowerHUDMoviePlayer HUDMovie;
var TowerPlaceable LastHighlightedBlock;

var private TowerPlaceable Placeable;

event PreBeginPlay()
{
	Super.PreBeginPlay();
	TowerMapInfo(WorldInfo.GetMapInfo()).DeactivateHUDPreview();
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
	local TowerBlock IterateBlock;
	local TowerPlaceable TracedPlaceable;
	local Tower Tower;

	TraceForBlock(TracedPlaceable, HitNormal);
	Tower = TowerPlayerController(PlayerOwner).GetTower();
	if(Tower != None && Tower.NodeTree != None && Tower.NodeTree.bDebugDrawHierarchy)
	{
		Tower.NodeTree.
		DrawDebugRelationship(Canvas, Tower.NodeTree.Root);
		foreach Tower.NodeTree.OrphanNodeRoots(IterateBlock)
		{
			Tower.NodeTree.
			DrawDebugRelationship(Canvas, IterateBlock);
		}
	}
	if(LastHighlightedBlock != None && (LastHighlightedBlock != TracedPlaceable || HUDMovie.bInMenu))
	{
		LastHighlightedBlock.UnHighlight();
	}
	if(TracedPlaceable != None && !HUDMovie.bInMenu)
	{
		TracedPlaceable.Highlight();
		LastHighlightedBlock = TracedPlaceable;
	}
	
	PlayerOwner.GetPlayerViewpoint(ViewPoint, ViewRotation);
	for(i = 0; i < PostRenderedActors.Length; i++)
	{
		PostRenderedActors[i].NativePostRenderFor(PlayerOwner, Canvas, ViewPoint, Vector(ViewRotation));
	}
}

event OnMouseClick(int Button)
{
	local TowerPlaceable TracedPlaceable;
	local Vector HitNormal;
	local IVector FinalGridLocation;
	// Left mouse button.
	if(Button == 0)
	{
		if(HUDMovie.bInMenu)
		{
			HUDMovie.PlaceablesList.onMousePress();
		}
		else
		{
			TraceForBlock(TracedPlaceable, HitNormal);
			if(TracedPlaceable != None)
			{
				FinalGridLocation = TracedPlaceable.GetGridLocation() + HitNormal;
//				FinalGridLocation.X = Round(FinalGridLocation.X);
//				FinalGridLocation.Y = Round(FinalGridLocation.Y);
//				FinalGridLocation.Z = Round(FinalGridLocation.Z);
//				`log("FinalGridLocation:"@FinalGridLocation@"From:"@TracedPlaceable.GetGridLocation());
				TowerPlayerController(PlayerOwner).AddPlaceable(Placeable, TowerBlock(TracedPlaceable), FinalGridLocation);
			}
		}
	}
	// Right mouse button.
	else if(Button == 1)
	{
		TraceForBlock(TracedPlaceable, HitNormal);
		//@TODO - Ask to make sure they want to remove the block?
		// Don't let the player remove the root block.
		if(TracedPlaceable != None && TowerBlockRoot(TracedPlaceable) == None)
		{
			TowerPlayerController(PlayerOwner).RemovePlaceable(TracedPlaceable);
		}
	}
}

function SetupPlaceablesList()
{
	//@TODO - Order list.
	local TowerPlaceable IteratedPlaceable;
	local int i;
	foreach TowerGameReplicationInfo(WorldInfo.GRI).Placeables(IteratedPlaceable, i)
	{
		if(TowerBlock(IteratedPlaceable).bAddToPlaceablesList)
		{
			HUDMovie.PlaceableStrings.AddItem(TowerBlock(IteratedPlaceable).DisplayName);
			HUDMovie.PlaceableIndex.AddItem(i);
		}
	}
	HUDMovie.SetVariableStringArray("_root.Placeables", 0, HUDMovie.PlaceableStrings);
	HUDMovie.OnBuildListChange(1);
}

event OnMouseRelease(int Button)
{
	if(Button == 0)
	{
		HUDMovie.PlaceablesList.onMouseRelease();
	}
}

event Focus()
{
//	HUDMovie.SetMovieCanReceiveFocus(TRUE);
	//@TODO - This should really just ignore Q instead.
	TowerPlayerController(Owner).bIgnoreLookInput = 1;
//	HUDMovie.AddCaptureKey('MouseX');
//	HUDMovie.AddCaptureKey('MouseY');
	HUDMovie.SetMovieCanReceiveInput(TRUE);
}

event UnFocus()
{
//	HUDMovie.ClearCaptureKeys();
	TowerPlayerController(Owner).bIgnoreLookInput = 0;
	HUDMovie.SetMovieCanReceiveInput(FALSE);
}

function Place()
{

}

/** Sets the TowerPlaceable that the game will attempt to place when the user clicks on a block. */
function SetPlaceable(TowerPlaceable NewPlaceable)
{
	Self.Placeable = NewPlaceable;
}

function ExpandBuildMenu()
{
	TowerMapInfo(WorldInfo.GetMapInfo()).ActivateHUDPreview();
	Focus();
	ProcessMouseMovement();
	HUDMovie.ExpandBuildMenu();
	HUDMovie.SetExternalTexture("HUDPreview", TextureRenderTarget2D'TowerMisc.HUDPreview');
}

function CollapseBuildMenu()
{
	TowerMapInfo(WorldInfo.GetMapInfo()).DeactivateHUDPreview();
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

/** TraceForPlaceable? */
function TraceForBlock(out TowerPlaceable Block, out Vector HitNormal)
{
	local Vector WorldOrigin, WorldDir;
	local Rotator PlayerDir;
	local Vector HitLocation;
	local TraceHitInfo HitInfo;
	PlayerOwner.GetPlayerViewPoint(WorldOrigin, PlayerDir);
	WorldDir = Vector(PlayerDir);
	/*`log(Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000,
		(WorldOrigin+WorldDir), TRUE,, HitInfo)@HitLocation);*/
	Block = TowerBlock(Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000,
		(WorldOrigin+WorldDir), TRUE,, HitInfo));
//	DrawDebugLine((WorldOrigin+WorldDir), HitLocation, 255, 0, 0, true);
	if(TowerPlaceable(HitInfo.HitComponent) != None)
	{
		Block = HitInfo.HitComponent;
	}
}

exec function DebugFlushLines()
{
	FlushPersistentDebugLines();
}

function TowerPlayerReplicationInfo GetTPRI()
{
	return TowerPlayerReplicationInfo(TowerPlayerController(Owner).PlayerReplicationInfo);
}

DefaultProperties
{
//	PlaceableBlock=class'TowerBlockDebug'
//	PlaceableModule=None
}