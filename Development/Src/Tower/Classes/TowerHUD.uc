class TowerHUD extends HUD
	dependson(TowerModule);

var TowerHUDMoviePlayer HUDMovie;
var TowerBlock LastHighlightedBlock;

/** If not None, this class of block will be added when a block is clicked. */
var deprecated BlockInfo PlaceableBlock;
/** If not None, this class of module will be added when a block is clicked. */
var deprecated ModuleInfo PlaceableModule;

var TowerPlaceable Placeable;

event PreBeginPlay()
{
	Super.PreBeginPlay();
	HUDMovie = new class'TowerHUDMoviePlayer';
	HUDMovie.HUD = self;
	HUDMovie.Init();
	HUDMovie.MoveCursor();
	HUDMovie.LockMouseToCenter(true);
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
			`assert((PlaceableBlock.BaseClass != None) ^^ (PlaceableModule.BaseClass != None));
		//	TowerPlayerController(PlayerOwner).AddPlaceable(Placeable, Block, FinalGridLocation);
			
			if(PlaceableBlock.BaseClass != None)
			{
				TowerPlayerController(PlayerOwner).AddBlock(Block, PlaceableBlock, FinalGridLocation);
			}
			else if(PlaceableModule.BaseClass != None)
			{
//				TowerPlayerController(PlayerOwner).AddModule(
			}
			
		}
	}
	// Right mouse button.
	else if(Button == 1)
	{
		HUDMovie.GetMouseCoordinates(Mouse, true);
		TraceForBlock(Mouse, Block, HitNormal);
		//@TODO - Ask to make sure they want to remove the block.
		TowerPlayerController(PlayerOwner).RemoveBlock(Block);
	}
}

function SetupPlaceablesList()
{
	//@TODO - Order list.
	local TowerModInfo Mod;
	local TowerPlaceable Placeable;
	local int i, TotalIndex;
	`log("SETUPPLACEADLVEOLLIST");
	foreach TowerGameReplicationInfo(WorldInfo.GRI).Placeables(Placeable, i)
	{
		if(TowerBlock(Placeable) != None)
			HUDMovie.PlaceableStrings.AddItem(TowerBlock(Placeable).DisplayName);
		else if(TowerModule(Placeable) != None)
			HUDMovie.PlaceableStrings.AddItem(TowerModule(Placeable).DisplayName);
		HUDMovie.PlaceableIndex.AddItem(i);
	}
	HUDMovie.SetVariableStringArray("_root.Placeables", 0, HUDMovie.PlaceableStrings);
	HUDMovie.OnBuildListChange(1);
	`log("SETUP THINGY");
}

function TestTowerPlaceable(TowerBlock Block)
{
	local TowerPlaceable P;
	P = TowerPlaceable(Block);
	// This correctly identifies the class! And you can cast blocks and such to TowerPlaceable just fine!
	`log("TTP"@P@P.class);
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

function SetPlaceablesList(array<BlockInfo> Blocks)
{
	local array<String> PlaceableNames;
	local BlockInfo Block;
	foreach Blocks(Block)
	{
		PlaceableNames.AddItem(Block.DisplayName);
	}
	`log("Adding PlaceablesList!"@PlaceableNames.Length@Blocks.Length);
	HUDMovie.SetVariableStringArray("_root.Placeables", 0, PlaceableNames);
	HUDMovie.OnBuildListChange(1);
}

function SetPlaceable(TowerPlaceable Placeable)
{
	Self.Placeable = Placeable;
}

function SetPlaceableBlock(BlockInfo Block)
{
	PlaceableBlock = Block;
	PlaceableModule.BaseClass = None;
}

function SetPlaceableModule(ModuleInfo Info)
{
	PlaceableBlock.BaseClass = None;
	PlaceableModule = Info;
}

function ExpandBuildMenu()
{
	Focus();
	ProcessMouseMovement();
	HUDMovie.ExpandBuildMenu();
	HUDMovie.SetExternalTexture("HUDPreview", TextureRenderTarget2D'TowerMisc.HUDPreview');
}

function CollapseBuildMenu()
{
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
	if(LastHighlightedBlock != Block && LastHighlightedBlock != None)
	{
		LastHighlightedBlock.UnHighlight();
	}
	if(Block != None)
	{
		Block.Highlight();
		LastHighlightedBlock = Block;
	}
}

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