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
  * returns true if should pass trace through this hitactor
  */
simulated static function bool PassThrough(Actor HitActor, Actor SelfActor)
{
	return (!HitActor.bBlockActors && HitActor.ScriptGetTeamNum() != SelfActor.Instigator.ScriptGetTeamNum() && 
		(HitActor.IsA('Trigger') || HitActor.IsA('TriggerVolume')))
		|| HitActor.IsA('InteractiveFoliageActor');
}

/**
 * Performs an 'Instant Hit' shot.
 * Also, sets up replication for remote clients,
 * and processes all the impacts to deal proper damage and play effects.
 *
 * Network: Local Player and Server
 */

simulated function InstantFire()
{
	local vector			StartTrace, EndTrace;
	local Array<ImpactInfo>	ImpactList;
	local int				Idx;
	local ImpactInfo		RealImpact;

	// define range to use for CalcWeaponFire()
	StartTrace = Instigator.GetWeaponStartTraceLocation();
	EndTrace = StartTrace + vector(GetAdjustedAim(StartTrace)) * GetTraceRange();

	// Perform shot
	RealImpact = CalcWeaponFire(StartTrace, EndTrace, ImpactList);

	if (Role == ROLE_Authority)
	{
/*		FlushPersistentDebugLines();
		DrawDebugSphere( StartTrace, 10, 10, 0, 255, 0 );
		DrawDebugSphere( EndTrace, 10, 10, 255, 0, 0 );
		DrawDebugSphere( RealImpact.HitLocation, 10, 10, 0, 0, 255 );
		`log( self@GetFuncName()@Instigator@RealImpact.HitLocation@RealImpact.HitActor );*/

		// Set flash location to trigger client side effects.
		// if HitActor == None, then HitLocation represents the end of the trace (maxrange)
		// Remote clients perform another trace to retrieve the remaining Hit Information (HitActor, HitNormal, HitInfo...)
		// Here, The final impact is replicated. More complex bullet physics (bounce, penetration...)
		// would probably have to run a full simulation on remote clients.
		SetFlashLocation(RealImpact.HitLocation);
	}
	`log(Self.Instigator@"shot"@RealImpact.HitActor);
	// Process all Instant Hits on local player and server (gives damage, spawns any effects).
	for (Idx = 0; Idx < ImpactList.Length; Idx++)
	{
		ProcessInstantHit(CurrentFireMode, ImpactList[Idx]);
	}
}

/**
 * CalcWeaponFire: Simulate an instant hit shot.
 * This doesn't deal any damage nor trigger any effect. It just simulates a shot and returns
 * the hit information, to be post-processed later.
 *
 * ImpactList returns a list of ImpactInfo containing all listed impacts during the simulation.
 * CalcWeaponFire however returns one impact (return variable) being the first geometry impact
 * straight, with no direction change. If you were to do refraction, reflection, bullet penetration
 * or something like that, this would return exactly when the crosshair sees:
 * The first 'real geometry' impact, skipping invisible triggers and volumes.
 *
 * @param	StartTrace	world location to start trace from
 * @param	EndTrace	world location to end trace at
 * @param	Extent		extent of trace performed
 * @output	ImpactList	list of all impacts that occured during simulation
 * @return	first 'real geometry' impact that occured.
 *
 * @note if an impact didn't occur, and impact is still returned, with its HitLocation being the EndTrace value.
 */
simulated function ImpactInfo CalcWeaponFire(vector StartTrace, vector EndTrace, optional out array<ImpactInfo> ImpactList, optional vector Extent)
{
	local vector			HitLocation, HitNormal, Dir;
	local Actor				HitActor;
	local TraceHitInfo		HitInfo;
	local ImpactInfo		CurrentImpact;
	local PortalTeleporter	Portal;
	local float				HitDist;
	local bool				bOldBlockActors, bOldCollideActors;

	// Perform trace to retrieve hit info
	HitActor = GetTraceOwner().Trace(HitLocation, HitNormal, EndTrace, StartTrace, TRUE, Extent, HitInfo, TRACEFLAG_Bullet);

	// If we didn't hit anything, then set the HitLocation as being the EndTrace location
	if( HitActor == None )
	{
		HitLocation	= EndTrace;
	}

	// Convert Trace Information to ImpactInfo type.
	CurrentImpact.HitActor		= HitActor;
	CurrentImpact.HitLocation	= HitLocation;
	CurrentImpact.HitNormal		= HitNormal;
	CurrentImpact.RayDir		= Normal(EndTrace-StartTrace);
	CurrentImpact.StartTrace	= StartTrace;
	CurrentImpact.HitInfo		= HitInfo;

	// Add this hit to the ImpactList
	ImpactList[ImpactList.Length] = CurrentImpact;

	// check to see if we've hit a trigger.
	// In this case, we want to add this actor to the list so we can give it damage, and then continue tracing through.
	if( HitActor != None )
	{
		if (PassThrough(HitActor, Self))
		{
			// disable collision temporarily for the actor we can pass-through
			HitActor.bProjTarget = false;
			bOldCollideActors = HitActor.bCollideActors;
			bOldBlockActors = HitActor.bBlockActors;
			if (HitActor.IsA('Pawn'))
			{
				// For pawns, we need to disable bCollideActors as well
				HitActor.SetCollision(false, false);

				// recurse another trace
				CalcWeaponFire(HitLocation, EndTrace, ImpactList, Extent);
			}
			else
			{
				if( bOldBlockActors )
				{
					HitActor.SetCollision(bOldCollideActors, false);
				}
				// recurse another trace and override CurrentImpact
				CurrentImpact = CalcWeaponFire(HitLocation, EndTrace, ImpactList, Extent);
			}

			// and reenable collision for the trigger
			HitActor.bProjTarget = true;
			HitActor.SetCollision(bOldCollideActors, bOldBlockActors);
		}
		else
		{
			// if we hit a PortalTeleporter, recurse through
			Portal = PortalTeleporter(HitActor);
			if( Portal != None && Portal.SisterPortal != None )
			{
				Dir = EndTrace - StartTrace;
				HitDist = VSize(HitLocation - StartTrace);
				// calculate new start and end points on the other side of the portal
				StartTrace = Portal.TransformHitLocation(HitLocation);
				EndTrace = StartTrace + Portal.TransformVectorDir(Normal(Dir) * (VSize(Dir) - HitDist));
				//@note: intentionally ignoring return value so our hit of the portal is used for effects
				//@todo: need to figure out how to replicate that there should be effects on the other side as well
				CalcWeaponFire(StartTrace, EndTrace, ImpactList, Extent);
			}
		}
	}

	return CurrentImpact;
}

/**
 * Processes a successful 'Instant Hit' trace and eventually spawns any effects.
 * Network: LocalPlayer and Server
 * @param FiringMode: index of firing mode being used
 * @param Impact: hit information
 * @param NumHits (opt): number of hits to apply using this impact
 * 			this is useful for handling multiple nearby impacts of multihit weapons (e.g. shotguns)
 *			without having to execute the entire damage code path for each one
 *			an omitted or <= 0 value indicates a single hit
 */
simulated function ProcessInstantHit(byte FiringMode, ImpactInfo Impact, optional int NumHits)
{
	local int TotalDamage;
	local KActorFromStatic NewKActor;
	local StaticMeshComponent HitStaticMesh;

	if (Impact.HitActor != None)
	{
		// default damage model is just hits * base damage
		NumHits = Max(NumHits, 1);
		TotalDamage = InstantHitDamage[CurrentFireMode] * NumHits;

		if ( Impact.HitActor.bWorldGeometry )
		{
			HitStaticMesh = StaticMeshComponent(Impact.HitInfo.HitComponent);
			if ( (HitStaticMesh != None) && HitStaticMesh.CanBecomeDynamic() )
			{
				NewKActor = class'KActorFromStatic'.Static.MakeDynamic(HitStaticMesh);
				if ( NewKActor != None )
				{
					Impact.HitActor = NewKActor;
				}
			}
		}
		Impact.HitActor.TakeDamage( TotalDamage, Instigator.Controller,
						Impact.HitLocation, InstantHitMomentum[FiringMode] * Impact.RayDir,
						InstantHitDamageTypes[FiringMode], Impact.HitInfo, self );
	}
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