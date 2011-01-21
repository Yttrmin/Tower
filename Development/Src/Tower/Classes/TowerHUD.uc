class TowerHUD extends HUD;

enum HUDMode
{
	HM_Add,
	HM_Remove
};

var TowerHUDMoviePlayer HUDMovie;
var HUDMode Mode;
var TowerBlock LastHighlightedBlock;

event Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);
//	HUDMovie.SetTimeRemaining(TowerGameReplicationInfo(WorldInfo.GRI).GetRemainingTime());
}

event PreBeginPlay()
{
	super.PreBeginPlay();
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

/** Called by Flash side of HUD. ClickNormal can be used to determine which side of a block was clicked. */
event BlockClicked(TowerBlock Block, Vector ClickNormal)
{
	local Vector FinalGridLocation;
	switch(Mode)
	{
	case HM_Add:
		FinalGridLocation = Block.GridLocation + ClickNormal;
		TowerPlayerController(PlayerOwner).AddBlock(Round(FinalGridLocation.X), 
			Round(FinalGridLocation.Y), Round(FinalGridLocation.Z));
		break;
	case HM_Remove:
		TowerPlayerController(PlayerOwner).RemoveBlock(Block.GridLocation.X, 
			Block.GridLocation.Y, Block.GridLocation.Z);
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
	local TowerBlock Block;
	Super.PostRender();
	TraceForBlock(HudMovie.GetVariableNumber("_root.MouseCursor._x"),
		HudMovie.GetVariableNumber("_root.MouseCursor._y"), Block);
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

/** Only call this from inside PostRender, or else Canvas won't be valid. */
function TraceForBlock(float X, float Y, out TowerBlock Block)
{
	local Vector2D Mouse;
	local Vector WorldOrigin, WorldDir;
	local Vector HitLocation, HitNormal;
	X *= RatioX;
	Y *= RatioY;
	Mouse.X = X;
	Mouse.Y = Y;
	Canvas.DeProject(Mouse, WorldOrigin, WorldDir);
	Block = TowerBlock(Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000, (WorldOrigin+WorldDir), TRUE));
}

DefaultProperties
{
	Mode=HM_Add
}