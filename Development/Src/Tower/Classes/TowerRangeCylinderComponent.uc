class TowerRangeCylinderComponent extends TowerRangeComponent
	AutoExpandCategories(TowerRangeCylinderComponent);

/**  */
/** Set the Module's CollisionComponent to this to receive Touch/UnTouch events. */
var() const instanced CylinderComponent RangeArea;
var private byte TouchingEnemies;

event Initialize()
{
	Super.Initialize();
//	AttachComponent(RangeArea);
	if(SkeletalMeshComponent(MeshComponent) != None && RangeCenterSocket != 'None')
	{
		SkeletalMeshComponent(MeshComponent).AttachComponentToSocket(RangeArea, RangeCenterSocket);
	}
	else
	{
		AttachComponent(RangeArea);
		// If someone set absolute translation, unset it.
		RangeArea.SetAbsolute(false);
		RangeArea.SetTranslation(RangeCenterPoint);
	}
	if(Outer.ParentDirection.Z != 0)
	{
		RangeArea.SetCylinderSize(RangeArea.CollisionHeight*2, RangeArea.CollisionRadius/2);
	}
	RangeArea.SetActorCollision(true, false, true);
	CollisionComponent=RangeArea;
}

/** Whatever touched us is now in-range. */
event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	`log(SELF@"TOUCHED BY"@OTHER);
	if(TowerTargetable(Other) != None && (OwnerPRI.Tower.TeamIndex != TowerTargetable(Other).GetOwningFaction().TeamIndex))
	{
		TouchingEnemies++;
		OnEnterRange(TowerTargetable(Other));
	}
}

event UnTouch(Actor Other)
{
	`log(Self@"UNTOUCH:"@Other);
	if(TowerTargetable(Other) != None && (OwnerPRI.Tower.TeamIndex != TowerTargetable(Other).GetOwningFaction().TeamIndex))
	{
		TouchingEnemies--;
		Outer.OnExitRange(TowerTargetable(Other));
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

function int EnemiesInRange()
{
	return TouchingEnemies;
}

DefaultProperties
{
	Begin Object Class=CylinderComponent Name=AreaRangeComponent
		BlockZeroExtent=true
		BlockNonZeroExtent=true
		CanBlockCamera=false
		bBlockFootPlacement=false
		CollideActors=true
		BlockActors=true
	End Object
	RangeArea=AreaRangeComponent
}