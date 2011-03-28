class TowerCrowdAgent extends GameCrowdAgentSkeletal;

var private Weapon Weapon;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	InitializeWeapon();
}

function InitializeWeapon()
{
	Weapon = Spawn(class'UTWeap_ShockRifle');
}

DefaultProperties
{
	Health=20
	bProjTarget=true
	
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

	bUpdateSimulatedPosition=true
//	bReplicateMovement=true
	RemoteRole=Role_SimulatedProxy
}