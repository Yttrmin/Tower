class TowerHUD extends HUD
	dependson(TowerModule);

var TowerHUDMoviePlayer HUDMovie;
var TowerBlock LastHighlightedBlock;

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
}

event OnMouseClick(int Button)
{
	local Vector2D Mouse;
	local TowerBlock Block;
	local Vector HitNormal, FinalGridLocation;
	// Left mouse button.
	if(HUDMovie.bInMenu)
	{
		return;
	}
	if(Button == 0)
	{
		HUDMovie.PlaceablesList.onMousePress();
		HUDMovie.GetMouseCoordinates(Mouse, true);
		TraceForBlock(Mouse, Block, HitNormal);
		if(Block != None)
		{
			FinalGridLocation = Block.GridLocation + HitNormal;
			FinalGridLocation.X = Round(FinalGridLocation.X);
			FinalGridLocation.Y = Round(FinalGridLocation.Y);
			FinalGridLocation.Z = Round(FinalGridLocation.Z);
			TowerPlayerController(PlayerOwner).AddPlaceable(Placeable, Block, FinalGridLocation);
		}
	}
	// Right mouse button.
	else if(Button == 1)
	{
		HUDMovie.GetMouseCoordinates(Mouse, true);
		TraceForBlock(Mouse, Block, HitNormal);
		//@TODO - Ask to make sure they want to remove the block.
		TowerPlayerController(PlayerOwner).RemovePlaceable(Block);
	}
}

function SetupPlaceablesList()
{
	//@TODO - Order list.
	local TowerPlaceable IteratedPlaceable;
	local int i;
	foreach TowerGameReplicationInfo(WorldInfo.GRI).Placeables(IteratedPlaceable, i)
	{
		if(TowerBlock(IteratedPlaceable) != None)
			HUDMovie.PlaceableStrings.AddItem(TowerBlock(IteratedPlaceable).DisplayName);
		else if(TowerModule(IteratedPlaceable) != None)
			HUDMovie.PlaceableStrings.AddItem(TowerModule(IteratedPlaceable).DisplayName);
		HUDMovie.PlaceableIndex.AddItem(i);
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

/** Only time where Canvas is valid. */
event PostRender()
{
	local Vector HitNormal;
	local Vector2D Mouse;
	local TowerBlock Block, IterateBlock;
	Super.PostRender();
	HUDMovie.GetMouseCoordinates(Mouse, false);
	TraceForBlock(Mouse, Block, HitNormal);
	if(TowerPlayerController(PlayerOwner).GetTower() != None &&
		TowerPlayerController(PlayerOwner).GetTower().NodeTree != None &&
		TowerPlayerController(PlayerOwner).GetTower().NodeTree.bDebugDrawHierarchy)
	{
		TowerPlayerController(PlayerOwner).GetTower().NodeTree.
		DrawDebugRelationship(Canvas, TowerPlayerController(PlayerOwner).GetTower().NodeTree.Root);
		foreach TowerPlayerController(PlayerOwner).GetTower().NodeTree.OrphanNodeRoots(IterateBlock)
		{
			TowerPlayerController(PlayerOwner).GetTower().NodeTree.
			DrawDebugRelationship(Canvas, IterateBlock);
		}
	}
	if((LastHighlightedBlock != Block && LastHighlightedBlock != None) || HUDMovie.bInMenu)
	{
		LastHighlightedBlock.UnHighlight();
	}
	if(Block != None && !HUDMovie.bInMenu)
	{
		Block.Highlight();
		LastHighlightedBlock = Block;
	}
}

/** TraceForPlaceable? */
function TraceForBlock(out Vector2D Mouse, out TowerBlock Block, out Vector HitNormal)
{
	local Vector WorldOrigin, WorldDir;
	local Vector HitLocation;
	if(Canvas != None)
	{
//		HUDMovie.GetMouseCoordinates(Mouse, false);
		Canvas.DeProject(Mouse, WorldOrigin, WorldDir);
	}
	else
	{
//		HUDMovie.GetMouseCoordinates(Mouse, true);
		LocalPlayer(PlayerOwner.Player).DeProject(Mouse, WorldOrigin, WorldDir);
	}
	Block = TowerBlock(Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000,
		(WorldOrigin+WorldDir), TRUE));
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