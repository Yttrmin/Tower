class TowerHUD extends HUD;

var TowerHUDMoviePlayer HUDMovie;
var TowerBlock LastHighlightedBlock;

var private TowerBlock PlaceBlock;

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
	local TowerBlock TracedBlock;
	local Tower Tower;

	TraceForBlock(TracedBlock, HitNormal);
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
	if(LastHighlightedBlock != None && (LastHighlightedBlock != TracedBlock || HUDMovie.bInMenu))
	{
		LastHighlightedBlock.UnHighlight();
	}
	if(TracedBlock != None && !HUDMovie.bInMenu)
	{
		TracedBlock.Highlight();
		LastHighlightedBlock = TracedBlock;
	}
	
	PlayerOwner.GetPlayerViewpoint(ViewPoint, ViewRotation);
	for(i = 0; i < PostRenderedActors.Length; i++)
	{
		PostRenderedActors[i].NativePostRenderFor(PlayerOwner, Canvas, ViewPoint, Vector(ViewRotation));
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
			HUDMovie.PlaceablesList.onMousePress();
		}
		else
		{
			TraceForBlock(TracedBlock, HitNormal);
			if(TracedBlock != None)
			{
				FinalGridLocation = TracedBlock.GetGridLocation() + HitNormal;
//				FinalGridLocation.X = Round(FinalGridLocation.X);
//				FinalGridLocation.Y = Round(FinalGridLocation.Y);
//				FinalGridLocation.Z = Round(FinalGridLocation.Z);
//				`log("FinalGridLocation:"@FinalGridLocation@"From:"@TracedPlaceable.GetGridLocation());
				TowerPlayerController(PlayerOwner).AddPlaceable(PlaceBlock, TracedBlock, FinalGridLocation);
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
			TowerPlayerController(PlayerOwner).RemovePlaceable(TracedBlock);
		}
	}
}

function SetupPlaceablesList()
{
	//@TODO - Order list.
	local TowerBlock IteratedBlock;
	local int i;
	foreach TowerGameReplicationInfo(WorldInfo.GRI).Blocks(IteratedBlock, i)
	{
		if(IteratedBlock.bAddToPlaceablesList)
		{
			HUDMovie.PlaceableStrings.AddItem(IteratedBlock.DisplayName);
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

/** Sets the TowerBlock that the game will attempt to place when the user clicks on a block. */
function SetPlaceBlock(TowerBlock NewBlock)
{
	Self.PlaceBlock = NewBlock;
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

DefaultProperties
{
//	PlaceableBlock=class'TowerBlockDebug'
//	PlaceableModule=None
}