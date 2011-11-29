class TowerRangeComponent extends ActorComponent within TowerBlockModule
	EditInlineNew
	HideCategories(Object)
	abstract;

event Initialize();

event ModuleDestroyed();

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal );

event UnTouch(Actor Other);

function TowerTargetable GetATargetable();

function GetAllTargetables(out array<TowerTargetable> Targetables, optional int Max=MaxInt);

function int EnemiesInRange();