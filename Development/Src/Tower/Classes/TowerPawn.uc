class TowerPawn extends Pawn
	abstract
	placeable;

/** Name of the socket to attach TowerWeaponAttachments to. */
var() protectedwrite const name WeaponSocket;

DefaultProperties
{
	WeaponSocket=WeaponPoint

	Begin Object Name=CollisionCylinder
		CollisionHeight=+44.000000
    End Object

	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
		ForcedLodModel=4
	End Object

	Components.Add(SkeletalMeshComponent0)
	Mesh=SkeletalMeshComponent0
}