class TowerStart extends NavigationPoint
	placeable
	ClassGroup(Tower);

// Which player has their Tower placed on this spot. Must be numbered 1-4.
var() const byte PlayerNumber<ClampMin=1|ClampMax=4|UIMin=1|UIMax=4>;