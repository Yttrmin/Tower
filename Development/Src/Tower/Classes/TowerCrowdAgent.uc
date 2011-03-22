class TowerCrowdAgent extends UTGameCrowdAgent;

var private Weapon Weapon;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	InitializeWeapon();
}

function InitializeWeapon()
{
	Weapon = Spawn(class'UTWeap_ShockRifle');
}

DefaultProperties
{
	bUpdateSimulatedPosition=true
//	bReplicateMovement=true
	RemoteRole=Role_SimulatedProxy
}