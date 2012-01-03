class TowerPlayerPawn extends TowerPawn;

var Vector ShoveNormal;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
}

event Bump( Actor Other, PrimitiveComponent OtherComp, vector HitNormal )
{
	//@TODO - Don't let players go inside blocks!
	`log("BUMPED:"@Other);
	if(TowerBlock(Other) == None)
	{
		HitNormal = Normal(Other.Location - Location);
		HitNormal.Z = 0.05 + Min(1, HitNormal.Z * 2);
		ShoveNormal = HitNormal;
		Shove(HitNormal);
	}
	Super.Bump(Other, OtherComp, HitNormal);
}

function Shove(out Vector HitNormal)
{
	PushState('Shoved');	
}

state Shoved
{
	ignores Shove;
	event PushedState()
	{
		SetTimer(0.25);
	}

	event Tick(float DeltaTime)
	{
		Velocity = -ShoveNormal*1000;
		Acceleration = -ShoveNormal*1000;
		Super.Tick(DeltaTIme);
	}

	event Timer()
	{
		Popstate();
	}
};

DefaultProperties
{
	bBlockActors=true
	bProjTarget=false
//	bCollideActors=false

	Begin Object Name=CollisionCylinder
		BlockZeroExtent=false
	End Object

	Begin Object Class=StaticMeshComponent Name=PlayerMesh
		StaticMesh=StaticMesh'EditorMeshes.MatineeCam_SM'
		bOwnerNoSee=true
	End Object
	Components.Add(PlayerMesh)

	AirSpeed = 600;

	RemoteRole=ROLE_SimulatedProxy
}