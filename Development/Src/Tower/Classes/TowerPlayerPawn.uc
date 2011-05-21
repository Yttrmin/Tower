class TowerPlayerPawn extends TowerPawn;

event k2override Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	//@TODO - Don't let players go inside blocks!
//	`log("PLAYER TOUCHED ======================================"@Velocity@Acceleration);
}

DefaultProperties
{
	bBlockActors=false
	bProjTarget=false
//	bCollideActors=false
/*
	Begin Object Name=CollisionCylinder
		CollideActors=true
		bAcceptsLights=false
		bAcceptsDynamicLights=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=true
		BlockRigidBody=false
		AlwaysLoadOnClient=True
		AlwaysLoadOnServer=True
		bDisableAllRigidBody=true
	End Object
	*/
}