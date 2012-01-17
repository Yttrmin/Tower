class TowerRangeComponent extends ActorComponent within TowerBlockModule
	EditInlineNew
	HideCategories(Object)
	abstract;

/** 
Only used if MeshComponent is a SkeletalMeshComponent.

	The socket to "center" the range around. How the actual range components use this is up to them. Some ways its used:
RangeGlobalComponent - Ignored.
RangeCylinderComponent - Uses the socket as the center of the cylinder.
RangeStaticMeshComponent - ?
 */
var(Range) const Name RangeCenterSocketName;
/**
Only used if MeshComponent is NOT a SkeletalMeshComponent.

	The translation to "center" the range around. Translation is done in model space, so the center will always be
in the same location relative to the mesh. How the actual range components use this is up to them. Some ways its used:
RangeGlobalComponent - Ignored.
RangeCylinderComponent - Uses the translation as the center of the cylinder.
RangeStaticMeshComponent - ?
*/
var(Range) const Vector RangeCenterTranslationFromMesh;

event Initialize();

event ModuleDestroyed();

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal );

event UnTouch(Actor Other);

function TowerTargetable GetATargetable();

function GetAllTargetables(out array<TowerTargetable> Targetables, optional int Max=MaxInt);

function int EnemiesInRange();