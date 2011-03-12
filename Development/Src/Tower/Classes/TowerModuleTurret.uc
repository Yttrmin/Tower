class TowerModuleTurret extends TowerModule
	placeable;

var StaticMeshComponent StaticMeshComponent;
//var SkeletalMeshComponent SkeletalMeshComponent;

DefaultProperties
{
	/*
	Begin Object Class=SkeletalMeshComponent Name=TurretMesh
	End Object
	*/
	Begin Object Class=StaticMeshComponent Name=TurretMesh
	End Object
	StaticMeshComponent=TurretMesh
}