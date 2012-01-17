class TowerRangeStaticMeshComponent extends TowerRangeComponent
	AutoExpandCategories(TowerRangeStaticMeshComponent);

var() const name MeshCenterSocketName;
var() const instanced StaticMeshComponent RangeMesh;
var private byte TouchingEnemies;

event Initialize()
{
	Super.Initialize();
	SkeletalMeshComponent(MeshComponent).AttachComponentToSocket(RangeMesh, MeshCenterSocketName);
	CollisionComponent = RangeMesh;
	RangeMesh.SetActorCollision(true, false, true);
	RangeMesh.SetHidden(true);
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
	Begin Object Class=StaticMeshComponent Name=SMRangeComponent
		BlockZeroExtent=true
		BlockNonZeroExtent=true
		CanBlockCamera=false
		bBlockFootPlacement=false
		CollideActors=true
		BlockActors=true
	End Object
	RangeMesh=SMRangeComponent
}