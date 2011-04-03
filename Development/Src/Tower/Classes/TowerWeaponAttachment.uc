class TowerWeaponAttachment extends Actor
	abstract;

var protectedwrite SkeletalMeshComponent Mesh;

/**
 * Called on a client, this function Attaches the WeaponAttachment
 * to the Mesh.
 */
simulated function AttachTo(Actor OwnerPawn)
{
	local TowerCrowdAgent OwnerAgent;
	local TowerPawn OwnerTowerPawn;
	if(TowerCrowdAgent(OwnerPawn) != None)
	{
		OwnerAgent = TowerCrowdAgent(OwnerPawn);
		OwnerAgent.SkeletalMeshComponent.AttachComponentToSocket(Mesh, OwnerAgent.WeaponSocket);
	}
	else if(TowerPawn(OwnerPawn) != None)
	{
		OwnerTowerPawn = TowerPawn(OwnerPawn);
//		OwnerTowerPawn.SkeletalMeshComponent.AttachComponentToSocket(Mesh, O
	}
}

DefaultProperties
{
	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
		bOwnerNoSee=true
		bOnlyOwnerSee=false
		CollideActors=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		MaxDrawDistance=4000
		bForceRefPose=1
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=FALSE
//		Animations=MeshSequenceA
		CastShadow=true
		bCastDynamicShadow=true
		MotionBlurScale=0.0
		bAllowAmbientOcclusion=false
		bPerBoneMotionBlur=true
	End Object
	Mesh=SkeletalMeshComponent0

	TickGroup=TG_DuringAsyncWork
	NetUpdateFrequency=10
	RemoteRole=ROLE_None
	bReplicateInstigator=true
}