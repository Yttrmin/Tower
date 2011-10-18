class TowerRangeCylinderComponent extends TowerRangeComponent;

/** Set the Module's CollisionComponent to this to receive Touch/UnTouch events. */
var() const CylinderComponent RangeArea;

DefaultProperties
{
	Begin Object Class=CylinderComponent Name=AreaRangeComponent
	End Object
	RangeArea=AreaRangeComponent
}