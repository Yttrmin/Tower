class TowerModuleTurret extends TowerModule
	placeable;

var StaticMeshComponent StaticMeshComponent;
//var SkeletalMeshComponent SkeletalMeshComponent;

replication
{
	if(true)
		StaticMeshComponent;
}

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