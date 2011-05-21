class TowerWeapon extends UDKWeapon
	abstract;

var class<TowerWeaponAttachment> AttachmentClass;


/**
 * Fires a projectile.
 * Spawns the projectile, but also increment the flash count for remote client effects.
 * Network: Local Player and Server
 */
simulated function Projectile ProjectileFire()
{
	local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
	local ImpactInfo	TestImpact;
	local Projectile	SpawnedProjectile;

	// tell remote clients that we fired, to trigger effects
	IncrementFlashCount();

	if( Role == ROLE_Authority )
	{
		// This is where we would start an instant trace. (what CalcWeaponFire uses)
		StartTrace = TowerEnemyPawn(Owner).GetWeaponStartTraceLocation();//Owner.Location;//Vect(0,0,0);//Instigator.GetWeaponStartTraceLocation();
		AimDir = Vector(Instigator.Rotation);//Vector(GetAdjustedAim( StartTrace ));

		// this is the location where the projectile is spawned.
		TowerEnemyPawn(Owner).WeaponAttachment.Mesh.GetSocketWorldLocationAndRotation('MussleFlashSocket', RealStartLoc);
		//RealStartLoc = GetPhysicalFireStartLoc(AimDir);
		// Instigator exists!
		if( StartTrace != RealStartLoc )
		{
			// if projectile is spawned at different location of crosshair,
			// then simulate an instant trace where crosshair is aiming at, Get hit info.
			EndTrace = StartTrace + AimDir * GetTraceRange();
			TestImpact = CalcWeaponFire( StartTrace, EndTrace );

			// Then we realign projectile aim direction to match where the crosshair did hit.
			AimDir = Normal(TestImpact.HitLocation - RealStartLoc);
		}
		// Spawn projectile
		SpawnedProjectile = Spawn(GetProjectileClass(),,, RealStartLoc);
		if( SpawnedProjectile != None && !SpawnedProjectile.bDeleteMe )
		{
			SpawnedProjectile.Init( AimDir );
		}

		// Return it up the line
		return SpawnedProjectile;
	}

	return None;
}

/**
 * Called on the LocalPlayer, Fire sends the shoot request to the server (ServerStartFire)
 * and them simulates the firing effects locally.
 * Call path: PlayerController::StartFire -> Pawn::StartFire -> InventoryManager::StartFire
 * Network: LocalPlayer
 */
simulated function StartFire(byte FireModeNum)
{
	if( Instigator == None || !Instigator.bNoWeaponFiring )
	{
		if( Role < Role_Authority )
		{
			// if we're a client, synchronize server
			ServerStartFire(FireModeNum);
		}

		// Start fire locally
		BeginFire(FireModeNum);
	}
}

function HolderDied()
{
	`log("Holder died!");
	Super.HolderDied();
}

DefaultProperties
{
	FiringStatesArray(0)=WeaponFiring

	AmmoCount=500
}