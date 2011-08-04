class TowerPlayerController extends GamePlayerController
	config(Tower);

var TowerSaveSystem SaveSystem;
var TowerMusicManager MusicManager;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SaveSystem = new class'Tower.TowerSaveSystem';
	MusicManager = Spawn(class'Tower.TowerMusicManager');
	MusicManager.Initialize();
//	SaveSystem.TestInt = 123456;
//	SaveSystem.TransTestInt = 345678;
//	class'Engine'.static.BasicSaveObject(SaveSystem, "SaveGame.bin", true, 1);
//	class'Engine'.static.BasicLoadObject(SaveSystem, "SaveGame.bin", true, 1);
//	`log(SaveSystem.TestInt);
//	`log(SaveSystem.TransTestInt);
}

function InitPlayerReplicationInfo()
{
	Super.InitPlayerReplicationInfo();
	if(Role == Role_Authority && TowerGameReplicationInfo(WorldInfo.GRI).ServerTPRI == None)
	{
		TowerGameReplicationInfo(WorldInfo.GRI).ServerTPRI = TowerPlayerReplicationInfo(PlayerReplicationInfo);
	}
}

state DebugEnemySpectating
{

}

state PlayerFlying
{
	/*function ProcessMove( float DeltaTime, vector newAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		if( (Pawn != None) && (Pawn.Acceleration != newAccel) )
		{
			Pawn.Acceleration = newAccel;
		}
	}*/

	function MoveAutonomous(float DeltaTime, byte CompressedFlags, vector newAccel, rotator DeltaRot)
	{
		local EDoubleClickDir DoubleClickMove;

		if ( (Pawn != None) && Pawn.bHardAttach )
			return;

		DoubleClickMove = SavedMoveClass.static.SetFlags(CompressedFlags, self);
		HandleWalking();

		if ( bCheatFlying && (Pawn.Acceleration == vect(0,0,0)) )
			Pawn.Velocity = vect(0,0,0);

		ProcessMove(DeltaTime, newAccel, DoubleClickMove, DeltaRot);

		if ( Pawn != None )
		{
			Pawn.AutonomousPhysics(DeltaTime);
		}
		else
		{
			AutonomousPhysics(DeltaTime);
		}
		bDoubleJump = false;
		//`log("Role "$Role$" moveauto time "$100 * DeltaTime$" ("$WorldInfo.TimeDilation$")");
	}

	function PlayerMove(float DeltaTime)
	{
		Super.PlayerMove(DeltaTime);
		/*
		local vector X,Y,Z;

		GetAxes(Rotation,X,Y,Z);

		Pawn.Acceleration = PlayerInput.aForward*X + PlayerInput.aStrafe*Y + PlayerInput.aUp*vect(0,0,1);;
		Pawn.Acceleration = Pawn.AccelRate * Normal(Pawn.Acceleration);

		if ( bCheatFlying && (Pawn.Acceleration == vect(0,0,0)) )
			Pawn.Velocity = vect(0,0,0);
		// Update rotation.
		UpdateRotation( DeltaTime );

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
		*/
	}
}

exec function ClickDown(int ButtonID)
{
	TowerHUD(myHUD).OnMouseClick(ButtonID);
}

/** Called when mouse button is released. */
exec function ClickUp(int ButtonID)
{
	TowerHUD(myHUD).OnMouseRelease(ButtonID);
}

exec function ToggleBuildMenu(bool Toggle)
{
//	`log("TOGGLEBUILDMENU:"@Toggle);
	if(Toggle)
	{
		TowerHUD(MyHUD).ExpandBuildMenu();
	}
	else
	{
		TowerHUD(MyHUD).CollapseBuildMenu();
	}
}

exec function SetHighlightColor(LinearColor NewColor)
{
	TowerPlayerReplicationInfo(PlayerReplicationInfo).SetHighlightColor(NewColor);
}

//@TODO - Can't this just directly call a reliable server function in its Tower?
exec function SetTowerName(string NewName)
{
	ServerSetTowerName(NewName);
}

exec function bool SaveGame(string FileName)
{
	//@TODO - Move verification stuff to TowerSaveSystem or DLL since people definitely won't get that
	// stuff publically.
	if(TowerGameReplicationInfo(WorldInfo.GRI).bRoundInProgress)
	{
		`log("Trying to save while the round is in progress! This isn't allowed!");
		return false;
	}
	else if(FileName == "")
	{
		return false;
	}
	SaveSystem.SaveGame(FileName, false, self);
	return true;
}

exec function LoadGame(string FileName, bool bTowerOnly)
{
	//@TODO - Move verification stuff to TowerSaveSystem or DLL since people definitely won't get that
	// stuff publically.
	if(FileName == "")
	{
		return;
	}
	ConsoleCommand("open"@WorldInfo.GetMapName(true)$"?LoadGame="$FileName);
//	SaveSystem.LoadGame(FileName, bTowerOnly, self);
}

`if(`isdefined(DEBUG))
// Only thing that really matters is lighting! (hopefully!)
//@TODO - But what about when blocks are falling?!
/** Creates a bunch of blocks and modules (as components) to test how many MeshComponents we can handle! */
exec function DebugTestManyBlocks(bool bAsComponents, optional bool bUseAAMesh)
{
	local int i, u;
	local Vector NewTranslation;
	local StaticMeshComponent NewComponent;
	local TowerBlock Parent;
	local TowerBlockStructural NewBlock;
	// Module: StaticMesh'TowerModules.DebugAA'
	// ModuleSKel: SkeletalMesh'TowerMod.DebugAAMessiah_DebugAA2'
	Parent = GetTower().Root;

	for(u = 0; u < 5; u++)
	{
		NewTranslation = Vect(0, 0, 0);
		for(i = 0; i < 100; i++)
		{
			/*
			if(u == 0)
				NewTranslation.X = 256*i;
			else if(u == 1)
				NewTranslation.X = -256*i;
			else if(u == 2)
				NewTranslation.Y = 256*i;
			else if(u == 3)
				NewTranslation.Y = -256*i;
			else if(u == 4)
				NewTranslation.Z = 256*i;
			*/
			if(bAsComponents)
			{
				NewComponent = new class'StaticMeshComponent';
				if(bUseAAMesh)
					NewComponent.SetStaticMesh(StaticMesh'TowerBlocks.DebugBlock');
				else
					NewComponent.SetStaticMesh(StaticMesh'TowerBlocks.DebugBlock');
				NewComponent.SetTranslation(NewTranslation);
				Parent.AttachComponent(NewComponent);
			}
			else
			{
				NewBlock = Parent.Spawn(class'Tower.TowerBlockStructural',,,NewTranslation,,,false);
				`log("Spawned NewBlock?:"@NewBlock);
				NewBlock.StaticMeshComponent.SetStaticMesh(StaticMesh'TowerBlocks.DebugBlock');
			}
		}
	}
}

//@DEBUG
// 
exec function DebugMarkerUnitDistance()
{
	local TowerFormationAI Formation;
	local TowerEnemyController Unit;
	foreach DynamicActors(class'TowerFormationAI', Formation)
	{
		for(Unit = Formation.SquadLeader.NextSquadMember; Unit != None; Unit = Unit.NextSquadMember)
		{
			`log("Formation:"$Formation@"Unit:"$Unit@"is"@VSize(Unit.Location - Unit.Marker.Location)@"units away from its marker.");
		}
	}
}

//@DEBUG
exec function DebugKillAllLeaders()
{
	local TowerFormationAI Formation;
	foreach DynamicActors(class'TowerFormationAI', Formation)
	{
		Formation.SquadLeader.Pawn.Died(None, class'DmgType_Telefragged', Vect(0,0,0));
	}
}

//@DEBUG
exec function DebugPrintBindings()
{
	local KeyBind Bind;
	foreach PlayerInput.Bindings(Bind)
	{
		`log("Name:"@Bind.Name@"Command:"@Bind.Command);
	}
}

//@DEBUG - Logs key associated with command. A test of TowerPlayerInput::GetKeyFromCommand().
exec function DebugGetKeyFromCommand(string Command)
{
	Command = Repl(Command, "$", "|");
	`log("Key:"@String(TowerPlayerInput(PlayerInput).GetKeyFromCommand(Command)));
}

exec function DebugSpawnAir(int Amount)
{
	local int i;
	for(i = 0; i < Amount; i++)
	{
		Spawn(class'TowerBlockAir',,,,,,true);
	}
}

exec function DebugTestIterators()
{
	local TowerBlock IteratorBlock;
	`log("=================================================");
	foreach OverlappingActors(class'TowerBlock', IteratorBlock, 1024, Vect(0,0,128), false)
	{
		`log(IteratorBlock@"iterated!");
	}
	`log("=================================================");
}

exec function DebugTestReplicateArchetype()
{
	ServerTestReplicateArchetype(TowerGameReplicationInfo(WorldInfo.GRI).RootMod.ModBlocks[0]);
}

static exec function DebugTestBlockBases()
{
	local TowerBlock IteratorBasedBlock;
	local TowerBlock IteratorBlock;
	foreach class'WorldInfo'.static.GetWorldInfo().DynamicActors(class'TowerBlock', IteratorBlock)
	{
		if(IteratorBlock.class != Class'TowerBlockAir')
		{
			`log("=====================================================================");
			`log(IteratorBlock@"bases:");
			foreach IteratorBlock.BasedActors(class'TowerBlock', IteratorBasedBlock)
			{
				`log(IteratorBasedBlock@""@IteratorBasedBlock.GridLocation.X@IteratorBasedBlock.GridLocation.Y@IteratorBasedBlock.GridLocation.Z);
			}
		}
	}
}

reliable server function ServerTestReplicateArchetype(TowerBlock Block)
{
	`log("STRA:"@Block@Block.class@Block.ObjectArchetype);
}

/**  */
exec function DebugSpectateTargetable(optional bool bRetainViewTarget=false)
{
	local Vector WorldOrigin, WorldDir;
	local Rotator PlayerDir;
	local Vector HitLocation, HitNormal;
	local TowerTargetable Targetable;
	GetPlayerViewPoint(WorldOrigin, PlayerDir);
	WorldDir = Vector(PlayerDir);
	Targetable = Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000,
		(WorldOrigin+WorldDir), TRUE);
	if(Actor(Targetable) != None)
	{
		if(ViewTarget != None)
		{
			myHUD.RemovePostRenderedActor(ViewTarget);
		}
		if(!bRetainViewTarget)
		{
			SetViewTarget(Actor(Targetable));
		}
		myHUD.AddPostRenderedActor(Actor(Targetable));
	}
}

exec function DebugSpectateFactionAI(int Index, optional bool bRetainViewTarget=false)
{
	if(TowerGame(WorldInfo.Game).Factions[Index] != None)
	{
		if(ViewTarget != None)
		{
			myHUD.RemovePostRenderedActor(ViewTarget);
		}
		if(!bRetainViewTarget)
		{
			SetViewTarget(TowerGame(WorldInfo.Game).Factions[Index]);
		}
		myHUD.AddPostRenderedActor(TowerGame(WorldInfo.Game).Factions[Index]);
	}
}

exec function DebugUnSpectate()
{
	if(ViewTarget != None)
	{
		myHUD.RemovePostRenderedActor(ViewTarget);
	}
	SetViewTarget(None);
}

/** Plays the music at the given index */
exec function DebugPlayMusic(int Index)
{
	MusicManager.PlayOverrideMusic(Index);
}

exec function DebugStopMusic()
{
	MusicManager.StopMusic();
}

/** Lists all music in the MusicManager's MusicList as well as the currently playing song. */
exec function DebugListMusic()
{
	local SoundCue Cue;
	local int i;
	`log("=================================================");
	`log("Override Music. Count:"@MusicManager.CurrentMusicList.OverrideMusic.Length);
	foreach MusicManager.CurrentMusicList.OverrideMusic(Cue, i)
	{
		`log(i$"):"@Cue.Name@Cue.Duration@"Seconds");
	}
	`log("-------------------------------------------------");
	if(MusicManager.CurrentSong.SoundCue != None)
	{
		`log("Currently playing:"@MusicManager.CurrentSong.SoundCue.Name@MusicManager.CurrentSong.PlaybackTime$"/"$MusicManager.CurrentSong.SoundCue.Duration@"Seconds");
	}
	else
	{
		`log("Currently playing: Nothing");
	}
	`log("=================================================");
}

/** Logs what you're looking at. */
exec function DebugLookingAt()
{
	local Vector WorldOrigin, WorldDir;
	local Rotator PlayerDir;
	local Vector HitLocation, HitNormal;
	local Actor LookingAt;
	GetPlayerViewPoint(WorldOrigin, PlayerDir);
	WorldDir = Vector(PlayerDir);
	LookingAt = Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000,
		(WorldOrigin+WorldDir), TRUE);
	`log(LookingAt,,'LookingAt');
}
`endif

function AddBlock(TowerBlock BlockArchetype, TowerBlock Parent, out IVector GridLocation)
{
	ServerAddBlock(BlockArchetype, Parent, GridLocation);
	//TowerGame(WorldInfo.Game).AddPlaceable(GetTower(), Placeable, Parent, GridLocation);
}

reliable server function ServerAddBlock(TowerBlock BlockArchetype, TowerBlock Parent, IVector GridLocation)
{
	if(GetTower().HasBudget(BlockArchetype.Cost))
	{
		GetTower().ConsumeBudget(BlockArchetype.Cost);
		TowerGame(WorldInfo.Game).AddBlock(GetTower(), BlockArchetype, Parent, GridLocation);	
	}
}

/** Called from TowerHUD::OnMouseClick if a valid TowerPlaceable is selected for removal. */
simulated function RemoveBlock(TowerBlock Block)
{
	ServerRemoveBlock(Block);
}

reliable server function ServerRemoveBlock(TowerBlock Block)
{
	TowerGame(WorldInfo.Game).RemoveBlock(GetTower(), Block);
}

reliable server function ServerSetTowerName(string NewName)
{
	TowerGame(WorldInfo.Game).SetTowerName(GetTower(), NewName);
}

simulated function UpdateRoundNumber(byte NewRound)
{
	TowerHUD(myHUD).HUDMovie.SetRoundNumber(NewRound);
}

/** TowerMusicManager doesn't exist on servers, so forward me to the MusicManager, thanks! */
reliable client function OnMusicEvent(MusicEvent Event)
{
	MusicManager.OnMusicEvent(Event);
}

function Tower GetTower()
{
	return TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower;
}

function TowerPlayerReplicationInfo GetTPRI()
{
	return TowerPlayerReplicationInfo(PlayerReplicationInfo);
}

DefaultProperties
{
	bCheatFlying=true

	InputClass=class'Tower.TowerPlayerInput'
	CollisionType=COLLIDE_BlockAllButWeapons
	bCollideActors=true
	bCollideWorld=true
	bBlockActors=true
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0034.000000
		CollisionHeight=+0078.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
		bDrawNonColliding=true
	End Object
	CollisionComponent=CollisionCylinder
}