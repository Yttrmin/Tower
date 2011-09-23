class TowerPawn extends Pawn
	abstract
	placeable;

/** Name of the socket to attach TowerWeaponAttachments to. */
var() protectedwrite const name WeaponSocket;
// Dynamic light environment component to help speed up lighting calculations for the pawn
var(Pawn) const DynamicLightEnvironmentComponent LightEnvironment;

DefaultProperties
{
	WeaponSocket=WeaponPoint

	Begin Object Name=CollisionCylinder
		CollisionHeight=+44.000000
	End Object

	// Create a light environment for the pawn
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=true
		bIsCharacterLightEnvironment=true
		bUseBooleanEnvironmentShadowing=false
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
	bCacheAnimSequenceNodes=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		CastShadow=true
		BlockRigidBody=true
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		RBChannel=RBCC_Untitled3
		RBCollideWithChannels=(Untitled3=true)
		LightEnvironment=MyLightEnvironment
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=false
		bHasPhysicsAssetInstance=true
		TickGroup=TG_PreAsyncWork
		MinDistFactorForKinematicUpdate=0.2f
		bChartDistanceFactor=true
		RBDominanceGroup=20
		Scale=1.f
		bAllowAmbientOcclusion=false
		bUseOnePassLightingOnTranslucency=true
		bPerBoneMotionBlur=true
//		ForcedLodModel=4
	End Object

	Components.Add(SkeletalMeshComponent0)
	Mesh=SkeletalMeshComponent0
}