class TowerCrowdAgent extends GameCrowdAgentSkeletal;

var protected TowerWeapon Weapon;
var protectedwrite TowerWeaponAttachment WeaponAttachment;
var protectedwrite const name WeaponSocket;

var protected repnotify GameCrowdDestination ReplicatedCurrentDestination;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	InitializeWeapon();
	WeaponAttachmentChanged();

//	Weapon.StartFire(0);
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
	local int i;
	Weapon = Spawn(class'TowerWeapon_Rifle', self);
//	Weapon.Instigator = Self;
	Weapon.Activate();
//	UTWeapon(Weapon).AttachWeaponTo(SkeletalMeshComponent);
//	Weapon.GotoState('Active');
//	for(i = 0; i < 1000; i++)
//		Weapon.FireAmmunition();
}

simulated event SetCurrentDestination(GameCrowdDestination NewDestination)
{
	if ( NewDestination != CurrentDestination )
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
	if ( CurrentDestination.bFleeDestination && !IsPanicked() )
	{
		SetPanic(None, TRUE);
	}
}

simulated function WeaponAttachmentChanged()
{
	if(WeaponAttachment == None)
	{
		WeaponAttachment = Spawn(class'TowerWeaponAttachment_Rifle', self);

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
	Health=20
	bProjTarget=true

	WeaponSocket=WeaponPoint
	
	Begin Object Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'UTExampleCrowd.Mesh.SK_Crowd_Robot'
		AnimTreeTemplate=AnimTree'UTExampleCrowd.AnimTree.AT_CH_Crowd'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
		Translation=(Z=-42.0)
		TickGroup=TG_DuringAsyncWork
		PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics''
	End Object
	
	RotateToTargetSpeed=60000.0
	FollowPathStrength=600.0
	MaxWalkingSpeed=200.0

	bUpdateSimulatedPosition=false
	bReplicateMovement=false
	RemoteRole=Role_SimulatedProxy
}