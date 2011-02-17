class TowerHUD extends HUD
	dependson(TowerModule);

enum HUDMode
{
	HM_Add,
	HM_Remove
};

var TowerHUDMoviePlayer HUDMovie;
var deprecated HUDMode Mode;
var TowerBlock LastHighlightedBlock;

/** If not None, this class of block will be added when a block is clicked. */
var BlockInfo PlaceableBlock;
/** If not None, this class of module will be added when a block is clicked. */
var ModuleInfo PlaceableModule;

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
		SetPlaceablesList(TowerPlayerReplicationInfo(TowerPlayerController(PlayerOwner).PlayerReplicationInfo).PlaceableBlocks);
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
		HUDMovie.GetMouseCoordinates(Mouse, true);
		TraceForBlock(Mouse, Block, HitNormal);
		if(Block != None)
		{
			FinalGridLocation = Block.GridLocation + HitNormal;
			`assert((PlaceableBlock.BaseClass != None) ^^ (PlaceableModule.BaseClass != None));
			if(PlaceableBlock.BaseClass != None)
			{
				//@TODO - Make AddBlock use BlockInfo.
				TowerPlayerController(PlayerOwner).AddBlock(Block, PlaceableBlock, Round(FinalGridLocation.X), 
				Round(FinalGridLocation.Y), Round(FinalGridLocation.Z));
			}
			else if(PlaceableModule.BaseClass != None)
			{

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

/** Called from OnMouseClick(). ClickNormal can be used to determine which side of a block was clicked. */
event BlockClicked(TowerBlock Block, Vector ClickNormal)
{
	local Vector FinalGridLocation;
	switch(Mode)
	{
	case HM_Add:
		FinalGridLocation = Block.GridLocation + ClickNormal;
		TowerPlayerController(PlayerOwner).AddBlock(Block, PlaceableBlock, Round(FinalGridLocation.X), 
			Round(FinalGridLocation.Y), Round(FinalGridLocation.Z));
		break;
	case HM_Remove:
		TowerPlayerController(PlayerOwner).RemoveBlock(Block);
		break;
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
	ScriptTrace();
	`log("Adding PlaceablesList!"@PlaceableNames.Length@Blocks.Length);
	HUDMovie.SetVariableStringArray("_root.Placeables", 0, PlaceableNames);
}

function SetPlaceableBlock(BlockInfo Block)
{
	PlaceableBlock = Block;
//	PlaceableModule = None;
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
	Mode=HM_Add
//	PlaceableBlock=class'TowerBlockDebug'
//	PlaceableModule=None
}