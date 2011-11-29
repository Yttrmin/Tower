/**
TowerAttackComponent

Base class of components that determine how TowerModuleGuns attack something, such as shooting projectiles or
using traces.
*/
class TowerAttackComponent extends ActorComponent within TowerModuleGun
	EditInlineNew
	HideCategories(Object)
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
	DT_Fastest,
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
var() protected const int TargetsPerFire<EditCondition=bLimitSimultaneousTargets|ClampMin=0|UIMin=0>;
/**
Tells the component how to pick a target to attack.

DT_Fastest - Tells the component to just return the "first" target(s) in range. Whatever counts as "first" is up to it, 
but it'll likely be the quickest to determine.
If TargetsPerFire > 1, will still return unique targets.

DT_Closest - Tells the component to pick the closest target(s) in range.

DT_Farthest - Tells the component to pick the farthest target(s) in range.

DT_Random - Tells the component to truly pick a random target(s) in range, unlike DT_First.

DT_Custom - Tells the component to pick target(s) using its own special way. Official AttackComponents don't use this.
*/
var() private DesiredTarget TargetPickingLogic<EditCondition=bLimitSimultaneousTargets>;
var() protected const instanced ParticleSystemComponent ParticleSystem;
/** What parameters should this component pass to the ParticleSystem? */
var() private const ParticleSystemParameters ParticleParameters;
/** Name of the socket where any firing (tracing for hitscan, spawning projectile, etc.) starts. */
var() protected const name StartFireSocketName;
/** Used so often we might as well just make it an instance variable.
Should be emptied after every attack. */
var private array<TowerTargetable> Targets;
var private EmitterSpawnable Emitter;
//var() const LocationAdjustment TargetLocationAdjustment<bShowOnlyWhenTrue=ParticleParameters.bPassTargetLocation>;

event Initialize()
{
	/*local Vector SpawnLocation;
	local Rotator SpawnRotation;
	SkeletalMeshComponent(MeshComponent).GetSocketWorldLocationAndRotation(StartFireSocketName, SpawnLocation, SpawnRotation);
	
	Emitter = Spawn(class'EmitterSpawnable', Outer,, SpawnLocation, SpawnRotation,, true);
	Emitter.SetTemplate(ParticleSystem.Template);
	Emitter.SetBase(Outer);
	Emitter.ParticleSystemComponent.ActivateSystem();
	*/
	SkeletalMeshComponent(MeshComponent).AttachComponentToSocket(ParticleSystem, StartFireSocketName);
}

event ModuleDestroyed();

function StartAttack()
{
	ParticleSystem.ActivateSystem();
	BeginAttack();
	SetTimer(CoolDownTime, true, nameof(BeginAttack), self);
}

protected function BeginAttack()
{
	local TowerTargetable Targetable;
	AcquireTargets();
	foreach Targets(Targetable)
	{
		Attack(Targetable);
	}
}

function StopAttack()
{
	ClearTimer(NameOf(BeginAttack), self);
	ParticleSystem.DeActivateSystem();
}

private final function AcquireTargets()
{
	Targets.Remove(0, Targets.Length);
	if(!bLimitSimultaneousTargets)
	{
		AddTargetables();
	}
	else
	{
		switch(TargetPickingLogic)
		{
		case DT_Fastest:
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
//	`log(Self@"ATTACK       Owner:"@Owner);
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