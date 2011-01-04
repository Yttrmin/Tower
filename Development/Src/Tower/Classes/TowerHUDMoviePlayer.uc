class TowerHUDMoviePlayer extends GFxMoviePlayer;

var TowerHUD HUD;

/** Called by ActionScript along with the X and Y coordinates of the mouse.
Keep in mind this is the coordinates in the Flash movie, it won't match the game immediately unless it's at the same resolution!
Really need to check out his this acts at different resolutions and aspect ratios! */
event OnMouseClick(float X, float Y)
{
	local TowerBlock Block;
	local Vector HitLocation, HitNormal;
	local Vector WorldOrigin, WorldDir;
	local Vector2D Mouse;
	X *= HUD.RatioX;
	Y *= HUD.RatioY;
	// Mouse coordinates actually accurate below here.
	//`log("Mouse click at"@"("$X$","@Y$").");
	// DeProjection is down through LocalPlayer, else we'd have to wait for PostRender and then it just gets
	// messy to do it. This is allegedly slower than Canvas' deprojection, but hopefully not by much!
	Mouse.X = X/HUD.SizeX;
	Mouse.Y = Y/HUD.SizeY;
	LocalPlayer(HUD.PlayerOwner.Player).DeProject(Mouse, WorldOrigin, WorldDir);
	Block = TowerBlock(HUD.Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000, (WorldOrigin+WorldDir), TRUE));
	if(Block != None)
	{
		HUD.BlockClicked(Block, HitNormal);
	}
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

