class TowerHUD extends HUD;

enum HUDMode
{
	HM_Add,
	HM_Remove
};

var TowerHUDMoviePlayer HUDMovie;
var HUDMode Mode;

event PreBeginPlay()
{
	super.PreBeginPlay();
	ScriptTrace();
	HUDMovie = new class'TowerHUDMoviePlayer';
	HUDMovie.HUD = self;
	HUDMovie.Start();
}

/** Called by Flash side of HUD. ClickNormal can be used to determine which side of a block was clicked. */
event BlockClicked(TowerBlock Block, Vector ClickNormal)
{
	local Vector FinalGridLocation;
	`log("Clicked block:"@Block.Name@ClickNormal@Block.GridLocation.Z);
	`log(Block.GridLocation.Z + ClickNormal.Z);
	`log(Block.GridLocation.Z + -ClickNormal.Z);
	switch(Mode)
	{
	case HM_Add:
		// For some reason as floats this seemed a bit wonky with positioning.
		// Something's screwed up here in the 32-bit version.
		
		FinalGridLocation = Block.GridLocation+ClickNormal;
		`log(FinalGridLocation);
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

event PostRender()
{
	Super.PostRender();
}

DefaultProperties
{
	Mode=HM_Add
}