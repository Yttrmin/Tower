class TowerHUD extends HUD;

enum HUDMode
{
	HM_Add
};

//@DELETEME
var Vector2D EndPoint;
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

event BlockClicked(TowerBlock Block)
{

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
	local Vector EndOrigin, EndDir;
	Super.PostRender();
	//@DELETEME
	if(EndPoint != Vect2D(0,0))
	{
		Canvas.DeProject(EndPoint, EndOrigin, EndDir);
		`log("Point:"@EndPoint.X@EndPoint.Y@"Origin:"@EndOrigin@"Direction:"@EndDir);
		DrawDebugLine(EndOrigin+EndDir, (EndOrigin+EndDir)+EndDir*10000, 255, 0, 0, TRUE);
		EndPoint = Vect2D(0,0);
	}
}

DefaultProperties
{
	Mode=HM_Add
}