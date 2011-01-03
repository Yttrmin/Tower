class TowerHUDMoviePlayer extends GFxMoviePlayer;

var TowerHUD HUD;

/** Called by ActionScript along with the X and Y coordinates of the mouse.
Really need to check out his this acts at different resolutions and aspect ratios! */
event OnMouseClick(float X, float Y)
{
	//@DELETEME
	HUD.EndPoint.X = X;
	HUD.EndPoint.Y = Y;
	`log("Mouse click at"@"("$X$","@Y$").");
	// This'll have to be deprojected in PostRender.
}



DefaultProperties
{
	MovieInfo=SwfMovie'TowerHUD.HUD'
	bAutoPlay=TRUE
	bPauseGameWhileActive=FALSE
	//bCaptureInput=TRUE
	bAllowFocus=TRUE
	bIgnoreMouseInput=FALSE
}

