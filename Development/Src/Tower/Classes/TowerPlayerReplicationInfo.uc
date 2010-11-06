class TowerPlayerReplicationInfo extends UTPlayerReplicationInfo;

var Tower Tower;

replication
{
	if(bNetDirty)
		Tower;
}

/** Utility for seeing if this PRI is for a locally controller player. */
simulated function bool IsLocalPlayerPRI()
{
	local PlayerController PC;
	local LocalPlayer LP;

	PC = PlayerController(Owner);
	if(PC != None)
	{
		LP = LocalPlayer(PC.Player);
		return (LP != None);
	}

	return FALSE;
}

reliable simulated client function ShowMidGameMenu(bool bInitial)
{
	if ( !AttemptMidGameMenu() )
	{
		SetTimer(0.2,true,'AttemptMidGameMenu');
	}
}

simulated function bool AttemptMidGameMenu()
{
	local UTPlayerController PlayerOwner;
	local UTGameReplicationInfo GRI;

	PlayerOwner = UTPlayerController(Owner);

	if ( PlayerOwner != none )
	{
		GRI = UTGameReplicationInfo(WorldInfo.GRI);
		if (GRI != none)
		{
			GRI.ShowMidGameMenu(PlayerOwner,'ScoreTab',true);
			ClearTimer('AttemptMidGameMenu');
			return true;
		}
	}

	return false;
}

DefaultProperties
{
	bSkipActorPropertyReplication=False
}