class TowerPawn extends Pawn
	abstract
	placeable;

var() protectedwrite const name WeaponSocket;

DefaultProperties
{
	WeaponSocket=WeaponPoint

	Begin Object Name=CollisionCylinder
		CollisionHeight=+44.000000
    End Object

	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
	End Object
	Components.Add(SkeletalMeshComponent0)
	Mesh=SkeletalMeshComponent0
}