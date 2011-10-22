class TowerRangeCylinderComponent extends TowerRangeComponent;

/** Set the Module's CollisionComponent to this to receive Touch/UnTouch events. */
var() const instanced CylinderComponent RangeArea;

event Initialize()
{
	Super.Initialize();
	CollisionComponent=RangeArea;
}

/** Whatever touched us is now in-range. */
event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	if(TowerTargetable(Other) != None && (OwnerPRI.Tower.TeamIndex != TowerFaction(Other.Owner).TeamIndex))
	{
		OnEnterRange(TowerTargetable(Other));
	}
}

function GetAllTargetables(out array<TowerTargetable> Targetables, optional int Max=MaxInt)
{
	local Actor Actor;
	foreach TouchingActors(class'Actor', Actor)
	{
		if(TowerTargetable(Actor) != None)
		{
			Targetables.AddItem(Actor);
			if(Targetables.Length >= Max)
			{
				return;
			}
		}
	}
}

DefaultProperties
{
	Begin Object Class=CylinderComponent Name=AreaRangeComponent
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		CanBlockCamera=false
		bBlockFootPlacement=false
	End Object
	RangeArea=AreaRangeComponent
}