class TowerCheatManagerTD extends TowerCheatManager;

var TowerGame Game;

function InitCheatManager()
{
	Super.InitCheatManager();
	if(Outer.WorldInfo.Game != None)
	{
		Game = TowerGame(Outer.WorldInfo.Game);
	}
}

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
	GetTower().Root.TakeDamage(99999, Outer, Vect(0,0,0), Vect(0,0,0), class'DmgType_Telefragged');
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
		Outer.myHUD.AddPostRenderedActor(Outer);
		return;
	}
}

exec function DebugStopMovie()
{
	class'Engine'.static.StopMovie(true);
}

exec function DebugIVectSq(int X1, int Y1, int Z1, int X2, int Y2, int Z2)
{
	local IVector A, B;
	local Vector AV, BV;
	A = IVect(X1, Y1, Z1);
	B = IVect(X2, Y2, Z2);
	AV.X = X1; AV.Y = Y1; AV.Z = Z1;
	BV.X = X2; BV.Y = Y2; AV.Z = Z2;
	`log("I:"@ISizeSq(A - B));
	`log("V:"@VSizeSq(AV - BV));
}

/***********************************************

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Requires TowerPlayerController.


Requires TowerGame.

vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

************************************************/

exec function DebugGetFactionLocation(Vector Point)
{
	`log(GetEnum(Enum'FactionLocation', Game.GetPointFactionLocation(Point)));
}

exec function DebugKillAllTargetables()
{
	local Actor Targetable;
	foreach DynamicActors(class'Actor', Targetable, class'TowerTargetable')
	{
		Targetable.TakeDamage(999999, None, Vect(0,0,0), Vect(0,0,0), class'DmgType_Telefragged');
	}
//	GotoState('CoolDown');
}

exec function DebugListSpawnPoints()
{
	local TowerSpawnPoint Point;
	local array<TowerSpawnPoint> PosX, NegX, PosY, NegY;
	foreach WorldInfo.AllNavigationPoints(class'TowerSpawnPoint', Point)
	{
		switch(Point.Faction)
		{
		case FL_PosX:
			PosX.AddItem(Point);
			break;
		case FL_PosY:
			PosY.AddItem(Point);
			break;
		case FL_NegX:
			NegX.AddItem(Point);
			break;
		case FL_NegY:
			NegY.AddItem(Point);
			break;
		default:
			`log(Point@"has no assigned faction!"@Point.Location);
			break;
		}
	}
	`log("=============================================================================");
	`log("FL_PosX Points:");
	foreach PosX(Point)
	{
		`log(Point@Point.Location);
	}
	`log("-----------------------------------------------------------------------------");
	`log("FL_PosY Points:");
	foreach PosY(Point)
	{
		`log(Point@Point.Location);
	}
	`log("-----------------------------------------------------------------------------");
	`log("FL_NegX Points:");
	foreach NegX(Point)
	{
		`log(Point@Point.Location);
	}
	`log("-----------------------------------------------------------------------------");
	`log("FL_NegY Points:");
	foreach NegY(Point)
	{
		`log(Point@Point.Location);
	}
	`log("=============================================================================");
}

exec function DebugKillAllRootBlocks()
{
	local TowerPlayerController Controller;
	foreach WorldInfo.AllControllers(class'TowerPlayerController', Controller)
	{
		Controller.GetTower().Root.TakeDamage(99999, Controller, Vect(0,0,0), Vect(0,0,0), class'DmgType_Telefragged');
	}
}

exec function DebugForceGarbageCollection(optional bool bFullPurge)
{
	WorldInfo.ForceGarbageCollection(bFullPurge);
}

exec function DebugRecursionStateTest()
{
	Game.Spawn(class'TowerGameUberTest').DebugStartRecursionTest();
}

exec function DebugUberBlockTest()
{
	Game.Spawn(class'TowerGameUberTest').Start(Game);
}

exec function DebugStep()
{
	local TeamInfo Faction;
	foreach Game.GameReplicationInfo.Teams(Faction)
	{
		if(TowerFactionAIAStar(Faction) != None)
		{
			TowerFactionAIAStar(Faction).Step();
		}
	}
}

/** STEAM */

final function OnReadFriends(bool bWasSuccessful)
{
	local array<OnlineFriend> Friends;
	local array<UniqueNetID> ToSpam;
	local OnlineFriend Friend;
	`log(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).GetFriendsList(0, Friends));
	//EOnlineFriendState always offline? Only refers to Cube Defense games? bIsOnline accurate.
	foreach Friends(Friend)
	{
		`log(Friend.NickName@Friend.FriendState@Friend.UniqueID.UID.A@Friend.UniqueID.UID.B@Friend.bIsOnline@Friend.bHasVoiceSupport);
		if(Friend.NickName == "TestBot 300")
		{
			/** Nope. Opens up their steam community page in the overlay. */
//			OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).RemoveFriend(0,Friend.UniqueID);
		}
		else if(Friend.NickName == "{Dic6} Galactic Pretty Boy")
		{
			ToSpam.AddItem(Friend.UniqueId);
			`log(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).SendGameInviteToFriends(0,ToSpam,"MYKE DID YOU GET THIS!?"));
		}
	}
}

final function OnReadFriendsForAvatars(bool bWasSuccessful)
{
	local array<OnlineFriend> Friends;
	local OnlineFriend Friend;
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).GetFriendsList(0, Friends);
	foreach Friends(Friend)
	{
		if(Friend.NickName != "[Lurking] KNAPKINATOR")
		OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ReadOnlineAvatar(Friend.UniqueID, 184, OnReadAvatar);
	}
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ReadOnlineAvatar(LocalPlayer(GetALocalPlayerController().Player).GetUniqueNetID(), 184, OnReadAvatar);
}

final function OnReadAvatar(const UniqueNetId PlayerNetId, Texture2D Avatar)
{
	local TowerBlockStructural Block;
	foreach DynamicActors(class'TowerBlockStructural', Block)
	{
		if(bool(Rand(2)))
		{
			Block.MaterialInstance.SetTextureParameterValue('BlockTexture', Avatar);
		}
	}
}


/** Steam is smart and won't just let you screw up people's stuff.
SendMessageToFriend() just opens the steam overlay with a chat window to whoever. */
final function AskMyke(out OnlineFriend Myke)
{
	local int i;
	for(i = 0; i < 5; i++)
	{
		`log(Myke.NickName@OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).
			SendMessageToFriend(0, Myke.UniqueID, "BEEP BOOP MYKE DID YOU GET THIS?!?!?!"));
	}
}
exec function DebugSteamUnlockAchievement(int AchievementID)
{
	`log(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).UnlockAchievement(0,AchievementID));
}

exec function DebugSteamShowAchievementsUI()
{
	`log(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ShowAchievementsUI(0));
}

exec function DebugSteamResetAchievements()
{
	`log(OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ResetStats(true));
}

exec function DebugSteamListFriends()
{
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).AddReadFriendsCompleteDelegate(0, OnReadFriends);
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ReadFriendsList(0, 0);
}

exec function DebugSteamAddAvatars()
{
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).AddReadFriendsCompleteDelegate(0, OnReadFriendsForAvatars);
	OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ReadFriendsList(0, 0);
}

/** /STEAM */

exec function DebugJump()
{
	local TowerEnemyPawn TempPawn;
	foreach WorldInfo.AllPawns(class'TowerEnemyPawn', TempPawn)
	{
		TempPawn.DoJump(false);
	}
}

exec function DebugAITaunt()
{
	local TowerEnemyPawn TempPawn;
	foreach WorldInfo.AllPawns(class'TowerEnemyPawn', TempPawn)
	{
		TowerEnemyController(TempPawn.Controller).GotoState('Celebrating');
	}
}

exec function DebugDestructiblesToRigidBody()
{
	local ApexDestructibleActor Actor;
	foreach AllActors(class'ApexDestructibleActor', Actor)
	{
		`log("PHYS_RigidBody'ing"@Actor$"!");
		//Actor.TakeDamage(MaxInt, None, Actor.Location, Vect(0,0,0), class'DmgType_Telefragged');
		Actor.SetPhysics(PHYS_RigidBody);
		//Actor.StaticDestructibleComponent.WakeRigidBody();
	}
}

exec function DebugSpawnDestructible()
{
	Spawn(class'ApexDestructibleActorSpawnable',,, vect(0,0,1024),, ApexDestructibleActor(DynamicLoadObject("TestDestructible.DebugDestructibleSpawnableArchetype", class'ApexDestructibleActorSpawnable'))).SetPhysics(PHYS_RigidBody);
}

exec function DebugTestPriorityQueue(optional int Amount=100)
{
	local array<TowerBlockStructural> BlockArray, PriorityArray, SortedArray;
	local PriorityQueue Queue;
	local int i;
	local String LogString;
	local float Time;
	Queue = new class'PriorityQueue';
	for(i = 0; i < Amount; i++)
	{
		BlockArray.AddItem(Spawn(class'TowerBlockStructural'));
		BlockArray[BlockArray.length-1].Fitness = i;
	}
	for(i = 0; i < Amount; i++)
	{
		Swap(i, Rand(Amount), BlockArray);
	}
	LogString = "Initial:";
	for(i = 0; i < Amount; i++)
	{
		LogString @= BlockArray[i].Fitness$",";
	}
	`log(LogString,,'PriQueTest');
	for(i = 0; i < Amount; i++)
	{
		Queue.Add(BlockArray[i]);
	}
	Clock(Time);
	LogString = "";
	for(i = 0; i < Amount; i++)
	{
		PriorityArray.AddItem(TowerBlockStructural(Queue.Remove()));
	}
	for(i = 0; i < Amount; i++)
	{
		LogString @= PriorityArray[i].Fitness$",";
	}
	UnClock(Time);
	LogString = "ResultPriorityQueue"@Time@"seconds:"@LogString;
	Time = 0;
	`log(LogString,,'PriQueTest');
	Clock(Time);
	for(i = 0; i < Amount; i++)
	{
		SortedArray[i] = GetBestBlock(BlockArray);
		BlocKArray.RemoveItem(SortedArray[i]);
	}
	UnClock(Time);
	LogString = "ResultOldWay:"@Time@"seconds:";
	for(i = 0; i < Amount; i++)
	{
		LogString @= SortedArray[i].Fitness$",";
	}
	`log(LogString,,'PriQueTest');
}

final function TowerBlockStructural GetBestBlock(out array<TowerBlockStructural> OpenList)
{
	local TowerBlockStructural BestBlock, IteratorBlock;
	foreach OpenList(IteratorBlock)
	{
//		`log("Checking for best:"@IteratorBlock@IteratorBlock.Fitness,,'AStar');
		if(BestBlock == None)
		{
			BestBlock = IteratorBlock;
		}
		else if(IteratorBlock.Fitness < BestBlock.FitNess)
		{
			BestBlock = IteratorBlock;
		}
	}
	return BestBlock;
}

final function Swap(int A, int B, out array<TowerBlockStructural> C)
{
	local TowerBlockStructural D;
	D = C[A];
	C[A] = C[B];
	C[B] = D;
}

final function int PriorityComparator(Object A, Object B)
{
	return TowerBlockStructural(A).Fitness - TowerBlockStructural(B).Fitness;
}

exec function ActivateHUDPreview(int ControllerID)
{
	TowerMapInfo(WorldInfo.GetMapInfo()).ActivateHUDPreview(ControllerID);
}

exec function TestRTHUD(bool bUseRenderTargetTexture)
{
	local GFxMoviePlayer Movie;
	Movie = new class'GFxMoviePlayer';
	Movie.MovieInfo = SwfMovie'TestRTHUD.RTHUD';
	Movie.bAutoPlay = true;
	Movie.Init();
	if(bUseRenderTargetTexture)
	{
		Movie.SetExternalTexture("MyRenderTarget", TextureRenderTarget2D'TestRTHUD.RenderTargetTexture');
	}
	else
	{
		Movie.SetExternalTexture("MyRenderTarget", Texture2D'TestRTHUD.DefaultDiffuse');
	}
}