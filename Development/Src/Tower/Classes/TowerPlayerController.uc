class TowerPlayerController extends GamePlayerController
	dependson(TowerSaveSystem)
	config(Tower);

var TowerSaveSystem SaveSystem;
var byte PreviewAreaIndex;
`if(`isdefined(DEBUG))
var TowerEnemyController PossessedPawnController;
`endif

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SaveSystem = new class'Tower.TowerSaveSystem';
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

/**
//@LOOKATME - Too much hassle. I can't think of a simple way to associate a TowerPlayerController
with its PRI, so this might conflict with split-screen.
state PlayerInactive extends PlayerFlying
{
	ignores AddBlock, RemoveBlock;
}
*/

exec function StartFire(optional byte FireModeNum)
{
	TowerHUD(myHUD).OnMouseClick(FireModeNum);
}

exec function StopFire(optional byte FireModeNum)
{
	TowerHUD(myHUD).OnMouseRelease(FireModeNum);
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

exec function QuickSave();

exec function QuickLoad();

exec function SaveGame(string FileName)
{
	if(TowerGameReplicationInfo(WorldInfo.GRI).bRoundInProgress)
	{
		`log("Trying to save while the round is in progress! This isn't allowed!");
	}
	SaveSystem.SaveGame(FileName, false, self);
}

exec function LoadGame(string FileName/*, bool bTowerOnly*/)
{
	if(SaveSystem.CheckSaveExist(FileName))
	{
		ConsoleCommand("open"@WorldInfo.GetMapName(true)$"?LoadGame="$FileName);
	}
	else
	{
		`log("Save file:"@"'"$FileName$"'"@"does not exist.",,'Loading');
	}
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
				NewBlock.SetStaticMesh(StaticMesh'TowerBlocks.DebugBlock');
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
	if(WorldInfo.Game.GameReplicationInfo.Teams[Index] != None)
	{
		if(ViewTarget != None)
		{
			myHUD.RemovePostRenderedActor(ViewTarget);
		}
		if(!bRetainViewTarget)
		{
			SetViewTarget(WorldInfo.Game.GameReplicationInfo.Teams[Index]);
		}
		myHUD.AddPostRenderedActor(WorldInfo.Game.GameReplicationInfo.Teams[Index]);
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

/** Logs what you're looking at. */
exec function DebugLookingAt(optional bool bPrintBases)
{
	local Vector WorldOrigin, WorldDir;
	local Rotator PlayerDir;
	local Vector HitLocation, HitNormal;
	local Actor LookingAt;
	local Actor BaseIterator;
	local TowerBlockStructural LookingBlock;
	local int i;
	GetPlayerViewPoint(WorldOrigin, PlayerDir);
	WorldDir = Vector(PlayerDir);
	LookingAt = Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000,
		(WorldOrigin+WorldDir), TRUE);
	LookingBlock = TowerBlockStructural(LookingAt);
	if(LookingAt != None && LookingBlock == None)
	{
		`log(LookingAt,,'LookingAt');
	}
	else if(LookingBlock != None)
	{
		`log(LookingBlock$":"@"S:"@LookingBlock.GetStateName()@"B:"@LookingBlock.Base@"GL:"
			@"("$LookingBlock.GridLocation.X$","@LookingBlock.GridLocation.Y$","@LookingBlock.GridLocation.Z$")"@"L:"
			@LookingBlock.Location@"L!:"@GetTower().GridLocationToVector(LookingBlock.GridLocation),,'LookingAt');
	}
	if(bPrintBases && LookingAt != None)
	{
		i = 0;
		foreach LookingAt.BasedActors(class'Actor', BaseIterator)
		{
			`log("Base#"$i$":"@BaseIterator,,'LookingAt');
			i++;
		}
	}
}

exec function DebugListBlocksAt(IVector GridLocation)
{
	local TowerBlock Block;
	local array<TowerBlock> Blocks;
	foreach DynamicActors(class'TowerBlock', Block)
	{
		if(Block.GridLocation == GridLocation)
		{
			Blocks.AddItem(Block);
		}
	}
	`log("=============================================================================");
	foreach Blocks(Block)
	{
		`log(Block);
	}
	`log("=============================================================================");
}

exec function DebugTestRenderTime()
{
	`log(GetTower().Root.LastRenderTime@WorldInfo.TimeSeconds@GetTower().Root.LastRenderTime==WorldInfo.TimeSeconds);
}

exec function DebugListSaveGames()
{
	local SaveInfo Info;
	foreach SaveSystem.Saves(Info)
	{
		`log(Info.FileName@Info.bVisible);
	}
}

exec function DebugTryClientSideHierarchyDrawing()
{
	GetTower().Initialize();
}

exec function DebugReCalculateBlockRotations()
{
	local TowerBlockStructural Block;
	foreach DynamicActors(class'TowerBlockStructural', Block)
	{
		Block.CalculateBlockRotation();
	}
}

exec function DebugReCalculateBlockLocations()
{
	local TowerBlockStructural Block;
	foreach DynamicActors(class'TowerBlockStructural', Block)
	{
		Block.SetGridLocation(true, false);
	}
	foreach DynamicActors(class'TowerBlockStructural', Block)
	{
		`log(Block@"FinalLocation:"@Block.Location@"FinalRLocation:"@Block.RelativeLocation);
	}
}

function Tower DebugGetNotMyTower()
{
	local Tower Tower;
	foreach DynamicActors(class'Tower', Tower)
	{
		if(Tower.Name == 'Tower_0')
		{
			`log("Returning"@Tower);
			return Tower;
		}
	}
	`warn("No other towers?");
	return None;
}

exec function DebugKillRootBlock()
{
	GetTower().Root.TakeDamage(99999, Self, Vect(0,0,0), Vect(0,0,0), class'DmgType_Telefragged');
}

/** Similar to TowerGame::DebugUberBlockTest(), although less extensive since clients don't have as much info. */
exec function DebugUberBlockTestPLAYER()
{

}

exec function WhereIs(int X, int Y, int Z)
{
	local Vector SpawnLocation;
	local IVector V;
	V =	IVect(X,Y,Z);
	SpawnLocation = GetTower().GridLocationToVector(V);
	Spawn(class'TowerDebugMarker',,,SpawnLocation);
}

exec function DrawAt(int X, int Y, int Z)
{
	local Vector Vect;
	Vect.X = X;
	Vect.Y = Y;
	Vect.Z = Z;
	DrawDebugSphere(Vect, 32, 64, 255, 0, 0, true); 
}

exec function DebugAllBlocksPlaceable(bool bNewAllBlocksPlaceable)
{

}

exec function DebugPossess()
{
	local TowerEnemyPawn IteratorPawn;
	foreach WorldInfo.AllPawns(class'TowerEnemyPawn', IteratorPawn)
	{
		PossessedPawnController = TowerEnemyController(IteratorPawn.Controller);
		Possess(IteratorPawn, false);
		PossessedPawnController.PushState('PawnTaken');
		myHUD.AddPostRenderedActor(self);
		return;
	}
}

exec function DebugStopMovie()
{
	class'Engine'.static.StopMovie(true);
}
`endif

exec function OpenBugReportWindow()
{

}

function AddBlock(TowerBlock BlockArchetype, TowerBlock Parent, out IVector GridLocation)
{
	if(!GetTPRI().Tower.IsInState('Inactive'))
	{
		ServerAddBlock(BlockArchetype, Parent, GridLocation);
	}
	//TowerGame(WorldInfo.Game).AddPlaceable(GetTower(), Placeable, Parent, GridLocation);
}

reliable server function ServerAddBlock(TowerBlock BlockArchetype, TowerBlock Parent, IVector GridLocation)
{
	if(GetTower().HasBudget(BlockArchetype.PurchasableComponent.Cost))
	{
		if(TowerGame(WorldInfo.Game).AddBlock(GetTower(), BlockArchetype, Parent, GridLocation) != None)
		{
			GetTower().ConsumeBudget(BlockArchetype.PurchasableComponent.Cost);
		}
		else
		{
			`log("Failed to add block of Archetype:"@BlockArchetype@"Parent:"@Parent@"GridLocation:"@GridLocation.X@GridLocation.Y@GridLocation.Z,,'Error');
		}
	}
}

/** Called from TowerHUD::OnMouseClick if a valid TowerPlaceable is selected for removal. */
function RemoveBlock(TowerBlock Block)
{
	if(!GetTPRI().Tower.IsInState('Inactive'))
	{
		ServerRemoveBlock(Block);
	}
}

reliable server function ServerRemoveBlock(TowerBlock Block)
{
	TowerGame(WorldInfo.Game).RemoveBlock(GetTower(), Block);
}

reliable server function ServerSetTowerName(string NewName)
{
	TowerGame(WorldInfo.Game).SetTowerName(GetTower(), NewName);
}

reliable client event WaitFor(float Seconds)
{
	IgnoreMoveInput(true);
	IgnoreLookInput(true);
	`log("Server suggests waiting for"@Seconds@"seconds. Will do.",,'CDNet');
	SetTimer(Seconds, false, NameOf(DoneWaiting));
}

private event DoneWaiting()
{
	local PlayerReplicationInfo PRI;
	if(HaveEssentialsReplicated())
	{
		`log("Done waiting, asking server for mods.",,'CDNet');
		WorldInfo.MyFractureManager.Destroy();
		foreach WorldInfo.GRI.PRIArray(PRI)
		{
			TowerPlayerReplicationInfo(PRI).Tower.Initialize();
		}
//		DebugReCalculateBlockLocations();
		GetTPRI().Tower.ReCalculateAllBlockLocations();
		RequestModList();
	}
	else
	{
		`log("Certain items still not replicated. Waiting another second.");
		SetTimer(1.0, false, NameOf(DoneWaiting));
	}
}

/**  */
private function bool HaveEssentialsReplicated()
{
	// Remember to pack the quickest checks first, as everything after the first FALSE won't get called.
	return WorldInfo.GRI != None && TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower != None
		&& AllBlockBasesReplicated() && AllBlockGridLocationsReplicated();
}

private function bool AllBlockBasesReplicated()
{
	return true;
}

private function bool AllBlockGridLocationsReplicated()
{
	return true;
}

//@NOTE - If there's concern about people reducing the wait time, have the server do a timestamp check.
reliable server function RequestModList()
{
	`log("Client done waiting, passing along ModList.",,'CDNet');
	LoadMods(TowerGameBase(WorldInfo.Game).RootMod.GetList(false));
}

reliable client event LoadMods(string ModList)
{
	`log("Received ModList!"@ModList,,'CDNet');
	TowerGameReplicationInfo(WorldInfo.GRI).RootMod = class'TowerGameBase'.static.LoadMods(ModList, true);
	`assert(TowerGameReplicationInfo(WorldInfo.GRI).RootMod != None);
	TowerHUD(myHUD).SetupBuildList();

	ResetPlayerMovementInput();
	class'Engine'.static.StopMovie(true);
}

function UpdateRoundNumber(byte NewRound)
{
	TowerHUD(myHUD).HUDMovie.SetRoundNumber(NewRound);
}

function Tower GetTower()
{
	return TowerPlayerReplicationInfo(PlayerReplicationInfo).Tower;
}

function TowerPlayerReplicationInfo GetTPRI()
{
	return TowerPlayerReplicationInfo(PlayerReplicationInfo);
}

simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	Canvas.SetDrawColor(255,255,255);
	Canvas.SetPos(0,430);
	Canvas.DrawText("Pawn:"@Pawn);
	Canvas.SetPos(0,440);
	Canvas.DrawText("Health:"@Pawn.Health);
	Canvas.SetPos(0,450);
	`if(`isdefined(DEBUG))
		Canvas.DrawText("PawnFactionOwner:"@PossessedPawnController.Owner);
	`endif
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