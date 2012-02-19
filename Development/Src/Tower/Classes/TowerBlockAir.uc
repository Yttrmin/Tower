/**
TowerBlockAir

A special block with no physical presence in the world that matters but a GridLocation.
It exists on all non-occupied spots of a TowerBlock, and solely exists for A* searches.
It's also the only block that only exists on the server (as there's no AI on clients).
*/
class TowerBlockAir extends TowerBlock;

event AdoptedChild()
{
	UpdateGridLocation();
}

simulated function Vector GetLocation()
{
	if(OwnerPRI.Tower != None)
	{
		return class'Tower'.static.GridLocationToVector(GridLocation);
	}
	else
	{
		return Vect(0,0,0);
	}
}

simulated function IVector GetGridLocation()
{
	return class'Tower'.static.VectorToGridLocation(Location);
}

DefaultProperties
{
	/*
	Begin Object Class=StaticMeshComponent Name=DebugMesh
		StaticMesh=StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_AutoAdjust'
	End Object
	Components.Add(DebugMesh)
	*/

	DisplayName=""
	bTickIsDisabled=true
	bCollideActors=false
	bCollideWorld=false
	Components.Remove(MyLightEnvironment)
	LightEnvironment=None
	CollisionComponent=None
	bAddToBuildList=false
	RemoteRole=ROLE_None
	bProjTarget=false
	BaseCost=1
}