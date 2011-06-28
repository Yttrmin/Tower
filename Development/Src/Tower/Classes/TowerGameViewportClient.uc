class TowerGameViewportClient extends GameViewportClient;

const CURRENT_VERSION = "0.1.0";
const CURRENT_REVISION = 80;

/**
 * Displays the transition screen.
 * @param Canvas - The canvas to use for rendering.
 */
function DrawTransition(Canvas Canvas)
{
	switch(Outer.TransitionType)
	{
		case TT_Loading:
			DrawTransitionMessage(Canvas,LoadingMessage);
			break;
		case TT_Saving:
			DrawTransitionMessage(Canvas,SavingMessage);
			break;
		case TT_Connecting:
			DrawTransitionMessage(Canvas,ConnectingMessage);
			break;
		case TT_Precaching:
			DrawTransitionMessage(Canvas,PrecachingMessage);
			break;
		case TT_Paused:
			DrawTransitionMessage(Canvas,PausedMessage);
			break;
	}
}