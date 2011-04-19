class TowerPawn extends Pawn
	abstract
	placeable;

var() protectedwrite const name WeaponSocket;

DefaultProperties
{
	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
	End Object
	Components.Add(SkeletalMeshComponent0)
	Mesh=SkeletalMeshComponent0
}