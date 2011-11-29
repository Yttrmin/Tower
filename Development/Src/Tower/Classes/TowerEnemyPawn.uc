/**
TowerEnemyPawn

Class of infantry units sent in by enemies.
*/
class TowerEnemyPawn extends TowerPawn
	config(Tower)
	implements(TowerTargetable);

var() editinline TowerPurchasableComponent PurchasableComponent;
var(InGame) editconst TowerDamageTrackerComponent DamageTracker;
var(InGame) deprecated editconst TowerFaction OwnerFaction;
var(InGame) deprecated editconst byte TeamIndex;
var	AnimNodeAimOffset		AimNode;

var const globalconfig bool bRagdollOnDeath;
var const globalconfig float RagdollLifespan;

var protectedwrite TowerWeaponAttachment WeaponAttachment;

replication
{
	if(bNetInitial)
		TeamIndex;
}

event Initialize(TowerFormationAI Squad, TowerEnemyPawn PreviousSquadMember)
{
//	Super.PostBeginPlay();
	/*
	Controller = Spawn(ControllerClass);
	Controller.Possess(self, false);*/
	SpawnDefaultController();
	TowerEnemyController(Controller).Squad = Squad;
	Weapon = Spawn(class'Tower.TowerWeapon_Rifle', self);
	Weapon.Activate();
	WeaponAttachment = Spawn(TowerWeapon(Weapon).AttachmentClass, self);
	WeaponAttachment.AttachTo(Self);
	// Non-archetypes don't need this, let it get garbage collected.
	PurchasableComponent = None;
	if(PreviousSquadMember != None)
	{
		TowerEnemyController(PreviousSquadMember.Controller).NextSquadMember = TowerEnemyController(Controller);
	}
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	// This is indeed called.
	AimNode = AnimNodeAimOffset( mesh.FindAnimNode('AimNode') );
	AimNode.SetActiveProfileByName('SinglePistol');
}

simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	Canvas.SetDrawColor(255,255,255);
	Canvas.SetPos(0,0);
	Canvas.SetPos(0,50);
	Canvas.DrawText("Targetable:"@Self, false);

	Canvas.SetPos(0,65);
	Canvas.DrawText("State:"@GetStateName());

	Canvas.SetPos(0,80);
	Canvas.DrawText("Health:"@Health);

	Canvas.SetPos(Canvas.SizeX-150, 50);
	Canvas.DrawText("Squad:"@TowerEnemyController(Controller).Squad);
}

/**
AI Interface for combat
**/
function bool BotFire(bool bFinished)
{
	StartFire(0);
	return true;
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local int ActualDamage;
	//@TODO - Cap damage for damage tracking.
//	`log(Self@"InstigatedBy:"@InstigatedBy@"DamageCauser:"@DamageCauser);
	// Let everyone modify the damage as they please, and then cap it if it's still over.
	ActualDamage = Health;
	Super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	ActualDamage -= Max(Health, 0);

	DamageTracker.OnTakeDamage(ActualDamage, InstigatedBy, DamageType, DamageCauser);
//	ScriptTrace();
}

function bool DoJump(bool bUpdating)
{
	return Super.DoJump(bUpdating);
}

function bool OnSameFaction(TowerEnemyPawn Other)
{
	return Other.ScriptGetTeamNum() == ScriptGetTeamNum();
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local bool Value;
//	`log(Self@"died. He owned"@Weapon);
	Value = Super.Died(Killer, DamageType, HitLocation);
	GetOwningFaction().OnTargetableDeath(Self, None, None);
//	Destroy();
	if(bRagdollOnDeath)
	{
		Ragdoll();
		// Set the actor to automatically destroy in ten seconds. 
		LifeSpan = RagdollLifeSpan;
	}
	else
	{
		Destroy();
	}
	if(Weapon != None)
	{
		Weapon.Destroy();
	}
	return Value;
}

function Ragdoll()
{
	Mesh.MinDistFactorForKinematicUpdate = 0.0;
	Mesh.ForceSkelUpdate();
	Mesh.SetTickGroup(TG_PostAsyncWork);
	CollisionComponent = Mesh;
	CylinderComponent.SetActorCollision(false, false);
	Mesh.SetActorCollision(true, false);
	Mesh.SetTraceBlocking(true, true);
	SetPawnRBChannels(true);
	SetPhysics(PHYS_RigidBody);
	Mesh.PhysicsWeight = 1.f;

	if (Mesh.bNotUpdatingKinematicDueToDistance)
	{
		Mesh.UpdateRBBonesFromSpaceBases(true, true);
	}

	Mesh.PhysicsAssetInstance.SetAllBodiesFixed(false);
	Mesh.bUpdateKinematicBonesFromAnimation = false;
	Mesh.WakeRigidBody();

	// Set the actor to automatically destroy in ten seconds.
	LifeSpan = 10.f;
}

function UnRagdoll()
{
	Mesh.MinDistFactorForKinematicUpdate = Mesh.default.MinDistFactorForKinematicUpdate;
	SetPawnRBChannels(false);
	Mesh.ForceSkelUpdate();
	Mesh.SetTickGroup(Mesh.default.TickGroup);
	CollisionComponent = default.CollisionComponent;
	CylinderComponent.SetActorCollision(true, true);
	Mesh.SetActorCollision(true, false);
	Mesh.SetTraceBlocking(true, true);
	SetPhysics(PHYS_Falling);
	Mesh.PhysicsWeight = Mesh.default.PhysicsWeight;

	if (Mesh.bNotUpdatingKinematicDueToDistance)
	{
		Mesh.UpdateRBBonesFromSpaceBases(true, true);
	}

	Mesh.PhysicsAssetInstance.SetAllBodiesFixed(true);
	Mesh.bUpdateKinematicBonesFromAnimation = Mesh.default.bUpdateKinematicBonesFromAnimation;
	Mesh.SetRBLinearVelocity(Vect(0,0,0), false);
	Mesh.ScriptRigidBodyCollisionThreshold = Mesh.default.ScriptRigidBodyCollisionThreshold;
	Mesh.SetNotifyRigidBodyCollision(Mesh.default.bNotifyRigidBodyCollision);
//	Mesh.WakeRigidBody();
}

simulated function SetPawnRBChannels(bool bRagdollMode)
{
	Mesh.SetRBChannel((bRagdollMode) ? RBCC_Pawn : RBCC_Untitled3);
	Mesh.SetRBCollidesWithChannel(RBCC_Default, bRagdollMode);
	Mesh.SetRBCollidesWithChannel(RBCC_Pawn, bRagdollMode);
	Mesh.SetRBCollidesWithChannel(RBCC_Vehicle, bRagdollMode);
	Mesh.SetRBCollidesWithChannel(RBCC_Untitled3, !bRagdollMode);
	Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume, bRagdollMode);
}

static function TowerTargetable CreateTargetable(TowerTargetable TargetableArchetype, out Vector SpawnLocation,
	TowerFaction NewOwningFaction)
{
	local TowerEnemyPawn Pawn;
	Pawn = NewOwningFaction.Spawn(class'TowerEnemyPawn',NewOwningFaction,,
		SpawnLocation,,TowerEnemyPawn(TargetableArchetype), true);
	return Pawn;
}

static function TowerPurchasableComponent GetPurchasableComponent(TowerTargetable Archetype)
{
	return TowerEnemyPawn(Archetype).PurchasableComponent;
}

function TowerDamageTrackerComponent GetDamageTracker()
{
	return DamageTracker;
}

simulated event byte ScriptGetTeamNum()
{
	return GetOwningFaction().TeamIndex;
}

/* epic ===============================================
* ::StopsProjectile()
*
* returns true if Projectiles should call ProcessTouch() when they touch this actor
*/
simulated function bool StopsProjectile(Projectile P)
{
	return !OnSameFaction(TowerEnemyPawn(P.Instigator)) && (bProjTarget || bBlockActors);
}

function bool IsProjectile()
{
	return FALSE;
}

function bool IsVehicle()
{
	return FALSE;
}

function bool IsInfantry()
{
	return TRUE;
}

static function int GetCost(TowerTargetable SelfArchetype)
{
	return TowerEnemyPawn(SelfArchetype).PurchasableComponent.Cost;
}

function SpawnDefaultController()
{
	if ( Controller != None )
	{
		`log("SpawnDefaultController" @ Self @ ", Controller != None" @ Controller );
		return;
	}

	if ( ControllerClass != None )
	{
		`log(Owner@"SD");
		Controller = Spawn(ControllerClass, Owner);
	}

	if ( Controller != None )
	{
		Controller.Possess( Self, false );
	}
}

function OnAssignController(SeqAct_AssignController inAction)
{

	if ( inAction.ControllerClass != None )
	{
		if ( Controller != None )
		{
			DetachFromController( true );
		}

		Controller = Spawn(inAction.ControllerClass, Owner);
		Controller.Possess( Self, false );

		// Set class as the default one if pawn is restarted.
		if ( Controller.IsA('AIController') )
		{
			ControllerClass = class<AIController>(Controller.Class);
		}
	}
	else
	{
		`warn("Assign controller w/o a class specified!");
	}
}

//@TODO - Combine interface and component instead?
function TowerFaction GetOwningFaction()
{
	return TowerFaction(Controller.Owner);
}

DefaultProperties
{
	Begin Object Class=TowerDamageTrackerComponent Name=DamageTrackerComponent

	End Object
	Components.Add(DamageTrackerComponent)
	DamageTracker=DamageTrackerComponent

	bCanJump=true
	bJumpCapable=true
	JumpZ = 1680
	ControllerClass=class'Tower.TowerEnemyController'
}