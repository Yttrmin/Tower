class TowerModuleAreaGun extends TowerBlockModule
	deprecated;

var() const CylinderComponent RangeArea;

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal );

event UnTouch( Actor Other );

DefaultProperties
{
	Begin Object Class=CylinderComponent Name=AreaRangeComponent
	End Object
	RangeArea=AreaRangeComponent
	Components.Add(AreaRangeComponent)
	CollisionComponent=AreaRangeComponent
}