class TowerHUD extends HUD;

enum HUDMode
{
	HM_Add,
	HM_Remove
};

var TowerHUDMoviePlayer HUDMovie;
var HUDMode Mode;
var TowerBlock LastHighlightedBlock;

event PreBeginPlay()
{
	Super.PreBeginPlay();
	HUDMovie = new class'TowerHUDMoviePlayer';
	HUDMovie.HUD = self;
	HUDMovie.Init();
	HudMovie.LockMouseToCenter(false);
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	HUDMovie.SetRoundNumber(TowerGameReplicationInfo(WorldInfo.GRI).Round);
}

event OnMouseClick(int Button)
{
	local Vector2D Mouse;
	local TowerBlock Block;
	local Vector HitNormal;
	if(Button == 0)
	{
		HUDMovie.GetMouseCoordinates(Mouse, true);
		TraceForBlock(Mouse, Block, HitNormal);
		if(Block != None)
		{
			BlockClicked(Block, HitNormal);
		}
	}
}

/** Called by Flash side of HUD. ClickNormal can be used to determine which side of a block was clicked. */
event BlockClicked(TowerBlock Block, Vector ClickNormal)
{
	local Vector FinalGridLocation;
	switch(Mode)
	{
	case HM_Add:
		FinalGridLocation = Block.GridLocation + ClickNormal;
		TowerPlayerController(PlayerOwner).AddBlock(Block, Round(FinalGridLocation.X), 
			Round(FinalGridLocation.Y), Round(FinalGridLocation.Z));
		break;
	case HM_Remove:
		TowerPlayerController(PlayerOwner).RemoveBlock(Block);
		break;
	}
}

event Focus()
{
	HUDMovie.SetMovieCanReceiveInput(TRUE);
}

event UnFocus()
{
	HUDMovie.SetMovieCanReceiveInput(FALSE);
}

/** Only time where Canvas is valid. */
event PostRender()
{
	local Vector HitNormal;
	local Vector2D Mouse;
	local TowerBlock Block;
	Super.PostRender();
	HUDMovie.GetMouseCoordinates(Mouse, false);
	TraceForBlock(Mouse, Block, HitNormal);
	TowerPlayerController(PlayerOwner).GetTower().NodeTree.
		DrawDebugRelationship(Canvas, TowerPlayerController(PlayerOwner).GetTower().NodeTree.Root);
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

DefaultProperties
{
	Mode=HM_Add
}