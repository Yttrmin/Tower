/**
TowerAttackComponent

Base class of components that determine how TowerModuleGuns attack something, such as shooting projectiles or
using traces.
*/
class TowerAttackComponent extends ActorComponent within TowerModuleGun
	EditInlineNew
	abstract;

struct ParticleSystemParameters
{
	var() bool bPassFireLocation;
	var() bool bPassTargetLocation;
};

enum LocationAdjustment
{
	LA_Origin,
	LA_Bottom,
	LA_Middle,
	LA_Top
};

enum DesiredTarget
{
	/** Tells the component to just return the "first" target(s) in range. Whatever counts as "first" is up to it, 
	but it'll likely be the quickest to determine.
	If TargetsPerFire > 1, will still return unique targets. */
	DT_First,
	/** Tells the component to pick the closest target(s) in range. */
	DT_Closest,
	/** Tells the component to pick the farthest target(s) in range. */
	DT_Farthest,
	/** Tells the component to truly pick a random target(s) in range, unlike DT_First. */
	DT_Random,
	/** Tells the component to pick targets using its own special way. Official AttackComponents don't use this. */
	DT_Custom
};

/** If FALSE, all targetables in the range of this module can be shot at in a single firing.
If TRUE, TargetsPerFire specifies how many targets can be shot in a single firing. Picking*/
var() protected const bool bLimitSimultaneousTargets;
/** The number of targetables that can be shot in a single firing. */
var() protected const int TargetsPerFire<EditCondition=bLimitSimultaneousTargets>;
var() protected const instanced ParticleSystemComponent ParticleSystem;
/** What parameters should this component pass to the ParticleSystem? */
var() private const ParticleSystemParameters ParticleParameters;
/**
Tells the component how to pick a target to attack.

DT_First - Tells the component to just return the "first" target(s) in range. Whatever counts as "first" is up to it, 
but it'll likely be the quickest to determine.
If TargetsPerFire > 1, will still return unique targets.

DT_Closest - Tells the component to pick the closest target(s) in range.

DT_Farthest - Tells the component to pick the farthest target(s) in range.

DT_Random - Tells the component to truly pick a random target(s) in range, unlike DT_First.

DT_Custom - Tells the component to pick target(s) using its own special way. Official AttackComponents don't use this.
*/
var() private DesiredTarget PickingTargetLogic<EditCondition=bLimitSimultaneousTargets>;
/** Name of the socket where any firing (tracing for hitscan, spawning projectile, etc.) starts. */
var() protected const name StartFireSocketName;
/** Used so often we might as well just make it an instance variable.
Should be emptied after every attack. */
var private array<TowerTargetable> Targets;
//var() const LocationAdjustment TargetLocationAdjustment<bShowOnlyWhenTrue=ParticleParameters.bPassTargetLocation>;

event Initialize();

event ModuleDestroyed();

function StartAttack()
{
	local TowerTargetable Targetable;
	AcquireTargets();
	foreach Targets(Targetable)
	{
		Attack(Targetable);
	}
}

private final function AcquireTargets()
{
	if(!bLimitSimultaneousTargets)
	{
		AddTargetables();
	}
	else
	{
		switch(PickingTargetLogic)
		{
		case DT_First:
			AddTargetables(TargetsPerFire);
			break;
		case DT_Closest:
			GetTargetsByDistance(true, TargetsPerFire);
			break;
		case DT_Farthest:
			GetTargetsByDistance(false, TargetsPerFire);
			break;
		case DT_Random:
			GetTargetsRandomly(TargetsPerFire);
			break;
		case DT_Custom:
			CustomAcquireTargets(TargetsPerFire);
			break;
		}
	}
}

private final function AddTargetables(optional int Max=MaxInt)
{
	RangeComponent.GetAllTargetables(Targets, Max);
}

private final function GetTargetsByDistance(bool bClosestFirst, optional int Max=MaxInt)
{
	RangeComponent.GetAllTargetables(Targets);
	if(bClosestFirst)
	{
		Targets.Sort(SortByClosest);
	}
	else
	{
		Targets.Sort(SortByFarthest);
	}
	if(Targets.Length > Max)
	{
		Targets.Remove(Max, Targets.Length-Max);
	}
}

private final function GetTargetsRandomly(optional int Max=MaxInt);

protected function CustomAcquireTargets(optional int Max=MaxInt);

private final function int SortByClosest(TowerTargetable A, TowerTargetable B)
{
	return VSizeSq(Actor(A).Location - Location) <= VSizeSq(Actor(B).Location - Location) ? 1 : -1;
}

private final function int SortByFarthest(TowerTargetable A, TowerTargetable B)
{
	return VSizeSq(Actor(A).Location - Location) <= VSizeSq(Actor(B).Location - Location) ? -1 : 1;
}

protected function Attack(TowerTargetable Targetable)
{
	SetupParticleParameters();
}

private final function SetupParticleParameters()
{

}

protected function Vector GetAimDirection(TowerTargetable Target)
{
	local Vector SocketLocation;
	local Rotator SocketRotation;
	`assert(SkeletalMeshComponent(MeshComponent).
		GetSocketWorldLocationAndRotation(StartFireSocketName, SocketLocation, SocketRotation));
	return Normal(Actor(Target).Location - SocketLocation);
}

DefaultProperties
{
	bLimitSimultaneousTargets=true
	TargetsPerFire=1
}