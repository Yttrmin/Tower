class TowerCrowdAgent extends GameCrowdAgentSkeletal
	implements(TowerTargetable)
	HideCategories(Physics,Debug);

//var() array<class<TowerWeapon> > AvailableWeapons;

var protected TowerWeapon Weapon;
var protectedwrite TowerWeaponAttachment WeaponAttachment;
var() protectedwrite const name WeaponSocket;
/** If TRUE, this agent will check every 0.5 seconds if it's in TowerMapInfo's RadarVolume, and notify the Root block when it occurs.
If FALSE, this agent will notify the Root block that it's in range upon spawning, regardless of if it actually is. 
If you're sure this agent will always be spawned in the RadarVolume (or don't care if it's detected outside it), this should be FALSE. 
bNotifyInRange must be TRUE for this to have any effect. */
var() protected const bool bCheckInRange;
/** If FALSE, this agent will never automatically notify the root block if it's in range, it must be done through script if at all. */
var() protected const bool bNotifyInRange;
var() protected const int Cost<ClampMin=1>;

var protected repnotify GameCrowdDestination ReplicatedCurrentDestination;
//@TODO - Combine interface and component instead?
var() editconst protected TowerFaction OwningFaction;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	InitializeWeapon();
	WeaponAttachmentChanged();
	
	if(bNotifyInRange)
	{
		if(Role == Role_Authority)
		{
			if(bCheckInRange)
			{
				if(!CheckInRange())
				{
					SetTimer(0.5, true, 'CheckInRange');
				}
			}
			else
			{
				NotifyInRange();
			}
		}
	}
//	Weapon.StartFire(0);
}

event Initialize(TowerFormationAI Squad, TowerEnemyPawn PreviousSquadMember);

function TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	if ( Health > 0 )
	{
		Health -= DamageAmount;

		if(Health <= 0)
		{
			Die(DamageAmount, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
		}
		else
		{
			if ( CurrentBehavior == None )
			{	
				// Agent is still alive and there is no current behavior, start a take damage behavior
				PickBehaviorFrom(TakeDamageBehaviors);
			}
		}
	}
}

event Die(int DamageAmount, out vector HitLocation, out vector Momentum, 
	class<DamageType> DamageType, optional out TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	`log(Self@"died! Cause:"@DamageCauser@DamageType);
	Health = -1;
	SetCollision(FALSE, FALSE, FALSE); // Turn off all collision when dead.
	PlayDeath(normal(Momentum) * DamageType.default.KDamageImpulse + Vect(0,0,1)*DamageType.default.KDeathUpKick);

	OwningFaction.OnTargetableDeath(Self, TowerTargetable(DamageCauser), TowerPlaceable(DamageCauser));
}

function bool CheckInRange()
{
	if(TowerMapInfo(WorldInfo.GetMapInfo()).RadarVolume.Encompasses(self))
	{
		NotifyInRange();
		ClearTimer('CheckInRange');
		return true;
	}
	else
	{
		return false;
	}
}

function NotifyInRange()
{
	// TowerCrowdAgent's can't Touch(), so we have to call the function manually.
	TowerPlayerReplicationInfo(TowerGameReplicationInfo(WorldInfo.GRI).PRIArray[0]).Tower.Root.
		Touch(Self, SkeletalMeshComponent, Location, Vect(0,0,0));
}

static function TowerTargetable CreateTargetable(TowerTargetable TargetableArchetype, out Vector SpawnLocation,
	TowerFaction NewOwningFaction)
{
	local TowerCrowdAgent Agent;
	Agent = NewOwningFaction.Spawn(class'TowerCrowdAgent',,,SpawnLocation,,TowerCrowdAgent(TargetableArchetype));
	Agent.OwningFaction = NewOwningFaction;
	return Agent;
}

function TowerFaction GetOwningFaction()
{
	return OwningFaction;
}

static function int GetCost(TowerTargetable SelfArchetype)
{
	return TowerCrowdAgent(SelfArchetype).Cost;
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

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == 'ReplicatedCurrentDestination')
	{
		SetCurrentDestination(ReplicatedCurrentDestination);
	}
	Super.ReplicatedEvent(VarName);
}

function InitializeWeapon()
{
	Weapon = Spawn(class'TowerWeapon_Rifle', self);
	Weapon.Activate();
}

simulated event SetCurrentDestination(GameCrowdDestination NewDestination)
{
	if( NewDestination != CurrentDestination )
	{
		if ( CurrentBehavior != None )
		{
			CurrentBehavior.ChangingDestination(NewDestination);
		}
		CurrentDestination = NewDestination;
		ReplicatedCurrentDestination = CurrentDestination;
		CurrentDestination.IncrementCustomerCount(self);
		
		ReachThreshold = CurrentDestination.bSoftPerimeter ? 0.5 + 0.5*FRand() : 1.0;
	}
}

simulated function WeaponAttachmentChanged()
{
	if(WeaponAttachment == None)
	{
		WeaponAttachment = Spawn(Weapon.AttachmentClass, self);

		if(WeaponAttachment != None)
		{
			WeaponAttachment.AttachTo(Self);
		}
	}
}

simulated event Destroyed()
{
	if(Weapon != None)
	{
		Weapon.Destroy();
	}
	Super.Destroyed();
}

DefaultProperties
{
	Cost=1

	Health=20
	bProjTarget=true

	WeaponSocket=WeaponPoint
	bNotifyInRange=true
	bCheckInRange=false
	
	Begin Object Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'UTExampleCrowd.Mesh.SK_Crowd_Robot'
		AnimTreeTemplate=AnimTree'UTExampleCrowd.AnimTree.AT_CH_Crowd'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
		Translation=(Z=-42.0)
		TickGroup=TG_DuringAsyncWork
		PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics''
	End Object
	
	RotateToTargetSpeed=60000.0
	MaxWalkingSpeed=200.0

	bUpdateSimulatedPosition=false
	bReplicateMovement=false
	RemoteRole=Role_SimulatedProxy
}