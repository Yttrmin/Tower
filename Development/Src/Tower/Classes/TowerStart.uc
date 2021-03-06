class TowerStart extends NavigationPoint
	placeable
	ClassGroup(Tower);

// Which player has their Tower placed on this spot. Must be numbered 1-4.
var() const byte PlayerNumber<ClampMin=1|ClampMax=4|UIMin=1|UIMax=4>;

DefaultProperties
{
	Begin Object Class=SpriteComponent Name=GameSprite
		Sprite=Texture2D'EditorResources.S_NavP'
		HiddenGame=false
		HiddenEditor=false
	End Object
	Components.Add(GameSprite)
}