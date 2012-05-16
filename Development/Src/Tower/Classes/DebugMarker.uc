class DebugMarker extends DynamicSMActor_Spawnable;

`define SCALE 2

DefaultProperties
{
	//StaticMesh'NodeBuddies.NodeBuddy_PerchUp'
	//StaticMesh'NodeBuddies.NodeBuddy_PerchClimb'
	Begin Object Class=StaticMeshComponent Name=NegX
		StaticMesh=StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_SwatLeft'
		Translation=(X=-150)
		Rotation=(Yaw=32768)
	End Object
	Components.Add(NegX)
	Begin Object Class=StaticMeshComponent Name=PosX
		StaticMesh=StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_SwatRight'
		Translation=(X=150)
		Rotation=(Yaw=32768)
	End Object
	Components.Add(PosX)
	Begin Object Class=StaticMeshComponent Name=NegZ
		StaticMesh=StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_SwatLeft'
		Translation=(Z=150)
		Rotation=(Pitch=16384)
	End Object
	Components.Add(NegZ)
	Begin Object Class=StaticMeshComponent Name=PosZ
		StaticMesh=StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_SwatRight'
		Translation=(Z=-150)
		Rotation=(Pitch=16384)
	End Object
	Components.Add(PosZ)
	Begin Object Class=StaticMeshComponent Name=NegY
		StaticMesh=StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_SwatLeft'
		Translation=(Y=150)
		Rotation=(Yaw=16384)
	End Object
	Components.Add(NegY)
	Begin Object Class=StaticMeshComponent Name=PosY
		StaticMesh=StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_SwatRight'
		Translation=(Y=-150)
		Rotation=(Yaw=16384)
	End Object
	Components.Add(PosY)

	DrawScale3D=(X=`SCALE,Y=`SCALE,Z=`SCALE)
	Physics=PHYS_Rotating
	RotationRate=(Yaw=32768)
	bCollideActors=false
	LifeSpan=5
}