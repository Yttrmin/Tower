class TowerWeapon_Rifle extends TowerWeapon;

simulated function Projectile ProjectileFire()
{
	return Super.ProjectileFire();
}

simulated state Active
{
	simulated event BeginState( Name PreviousStateName )
	{
		Super.BeginState(PreviousStateName);
		StartFire(1);
	}

	/** Override BeginFire so that it will enter the firing state right away. */
	simulated function BeginFire(byte FireModeNum)
	{
		if( !bDeleteMe /*&& Instigator != None*/ )
		{
			Global.BeginFire(FireModeNum);
			// in the active state, fire right away if we have the ammunition
			if( /*PendingFire(FireModeNum) && */HasAmmo(FireModeNum) )
			{
				SendToFiringState(FireModeNum);
			}
		}
	}
}

simulated state WeaponFiring
{
	simulated event BeginState( Name PreviousStateName )
	{
		Super.BeginState(PreviousStateName);
	}
}

DefaultProperties
{
	AttachmentClass=class'Tower.TowerWeaponAttachment_Rifle'

	FireInterval(0)=1
	Spread(0)=10.0
	WeaponFireTypes(0)=EWFT_InstantHit
//	WeaponProjectiles(0)=class'UTGame.UTProj_LinkPlasma'

	WeaponFireTypes(1)=EWFT_InstantHit
	InstantHitDamage(1)=20
	InstantHitMomentum(1)=100
	InstantHitDamageTypes(1)=class'TowerDmgType_Rifle'
	InstantHitDamageTypes(0)=class'TowerDmgType_Rifle'
//	bAlwaysRelevant=true
}