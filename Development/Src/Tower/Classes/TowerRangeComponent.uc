class TowerRangeComponent extends ActorComponent within TowerBlockModule
	EditInlineNew
	abstract;

event Initialize();

event ModuleDestroyed();

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal );

function TowerTargetable GetATargetable();

function GetAllTargetables(out array<TowerTargetable> Targetables, optional int Max=MaxInt);