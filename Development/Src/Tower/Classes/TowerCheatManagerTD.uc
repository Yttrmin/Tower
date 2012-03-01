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
		Block.UpdateLocation();
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

`if(`isdefined(DEBUG))
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
`endif

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

exec function DebugTestJSON()
{
	local JSONObject JSON, Root, RootBlock;
	Root = new class'JSonObject';
	RootBlock = new class'JSonObject';
	JSON = new class'JSonObject';

	JSON = new class'JsonObject';
	JSON.SetStringValue("accesstoken", "01010101");
	JSON.SetIntValue("level", 5);
	JSON.SetIntValue("currentXP", 123123);
	JSON.SetIntValue("nextLevelXP", 125000);
	JSON.SetIntValue("statHealth", 84);
	/*JSON.SetIntValue("statShield", 15);
	JSON.SetIntValue("statDamage", 18);
	JSON.SetIntValue("statMagic", 60);
	JSON.SetIntValue("avaiableStatPoints", 5);
	JSON.SetIntValue("rebalanceStatsCount", 3);
	JSON.SetIntValue("currentBloodline", 2);
	JSON.SetIntValue("currentPlaythrough", 1);
	JSON.SetIntValue("godKingLevel", 99);
	JSON.SetIntValue("currentGold", 45000);*/
	Root.SetObject("Header", JSON);

	JSON = new class'JsonObject';
	JSON.SetIntValue("statDamage", 18);
	JSON.SetIntValue("statMagic", 60);
	JSON.SetIntValue("avaiableStatPoints", 5);
	RootBlock.SetObject("0", JSON);

	JSON = new class'JsonObject';
	JSON.SetIntValue("statDamage", 425);
	JSON.SetIntValue("statMagic", 60231);
	JSON.SetIntValue("avaiableStatPoints", 125);
	RootBlock.SetObject("1", JSON);

	JSON = new class'JsonObject';
	JSON.SetIntValue("statDamage", 421);
	JSON.SetIntValue("statMagic", 86);
	JSON.SetIntValue("avaiableStatPoints", 321);
	RootBlock.SetObject("2", JSON);

	JSON = new class'JsonObject';
	JSON.SetIntValue("statDamage", 48696);
	JSON.SetIntValue("statMagic", 123);
	JSON.SetIntValue("avaiableStatPoints", 1358574);
	RootBlock.SetObject("3", JSON);

	Root.SetObject("Blocks", RootBlock);
	`log(class'JSonObject'.static.EncodeJson(Root));



	Root = new class'JSonObject';
	RootBlock = new class'JSonObject';
	JSON = new class'JSonObject';

	JSON.SetStringValue("accesstoken", "01010101");
	JSON.SetIntValue("level", 5);
	JSON.SetIntValue("currentXP", 123123);
	JSON.SetIntValue("nextLevelXP", 125000);
	JSON.SetIntValue("statHealth", 84);
	/*JSON.SetIntValue("statShield", 15);
	JSON.SetIntValue("statDamage", 18);
	JSON.SetIntValue("statMagic", 60);
	JSON.SetIntValue("avaiableStatPoints", 5);
	JSON.SetIntValue("rebalanceStatsCount", 3);
	JSON.SetIntValue("currentBloodline", 2);
	JSON.SetIntValue("currentPlaythrough", 1);
	JSON.SetIntValue("godKingLevel", 99);
	JSON.SetIntValue("currentGold", 45000);*/
		Root.ObjectArray[Root.ObjectArray.length] = JSON;

	JSON = new class'JsonObject';
		JSON.SetIntValue("statDamage", 18);
		JSON.SetIntValue("statMagic", 60);
		JSON.SetIntValue("avaiableStatPoints", 5);
		RootBlock.ObjectArray[Root.ObjectArray.length] = JSON;

	JSON = new class'JsonObject';
	JSON.SetIntValue("statDamage", 425);
	JSON.SetIntValue("statMagic", 60231);
	JSON.SetIntValue("avaiableStatPoints", 125);
		RootBlock.ObjectArray[Root.ObjectArray.length] = JSON;

	JSON = new class'JsonObject';
	JSON.SetIntValue("statDamage", 421);
	JSON.SetIntValue("statMagic", 86);
	JSON.SetIntValue("avaiableStatPoints", 321);
		RootBlock.ObjectArray[Root.ObjectArray.length] = JSON;

	JSON = new class'JsonObject';
	JSON.SetIntValue("statDamage", 48696);
	JSON.SetIntValue("statMagic", 123);
	JSON.SetIntValue("avaiableStatPoints", 1358574);
		RootBlock.ObjectArray[Root.ObjectArray.length] = JSON;

	Root.ObjectArray[Root.ObjectArray.Length] = RootBlock;
	/*`log(class'JSonObject'.static.EncodeJson(Root));*/ // Crashes.
}

exec function TestBugReport()
{
	local SaveSystemJSON SS;
	local HttpRequestInterface R;
	local string Query;

	SS = new class'SaveSystemJSON';
	Query = "JSON="$SS.SaveGame("TEST", Outer);
//	Query="fname=NAME&age=AGE";
	R = class'HttpFactory'.static.CreateRequest();
	R.SetRequestCompleteDelegate(OnRequestComplete);
	R.SetURL(class'SaveSystemJSON'.const.SITE_URL);
	R.SetVerb("POST");
	R.SetContent(ConvertToByteArray(Query));
	R.SetHeader("Host", "www.cubedefense.com");
	R.SetHeader("User-Agent", "Cube Defense");
	
	
	R.SetHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
	R.SetHeader("Accept-Language", "en-us,en;q=0.5");
//	R.SetHeader("Accept-Charset", "*");
	R.SetHeader("Accept-Encoding", "gzip, deflate");
	R.SetHeader("DNT", "1");
	R.SetHeader("Connection", "keep-alive");
//	R.SetHeader("Cookie", "__qca=P0-866094574-1304235263718; optimizelyEndUserId=oeu1304368225184r0.0014794187385734903; optimizelyBuckets=%7B%7D; __utma=182971897.2125256563.1314042924.1328305185.1328317302.75; __utmz=182971897.1326062946.55.11.utmcsr=bootstrap.cubedefense.com|utmccn=(referral)|utmcmd=referral|utmcct=/; __utmc=182971897");
	R.SetHeader("Content-Type", "application/x-www-form-urlencoded");
//	`log("?JSON"@R.GetURLParameter("JSON"));
	R.ProcessRequest();
}

exec function TestLoadJSON()
{
	local JSOnObject J;
	J = class'JSonObject'.static.DecodeJSON("{\"Blocks\":{\"INTERNAL_COUNT\":4,\"0\":{\"M\":0,\"B\":1,\"G_X\":0,\"G_Y\":0,\"G_Z\":1,\"P_X\":0,\"P_Y\":0,\"P_Z\":-1,\"S\":\"Stable\"},\"1\":{\"M\":0,\"B\":1,\"G_X\":0,\"G_Y\":0,\"G_Z\":2,\"P_X\":0,\"P_Y\":0,\"P_Z\":-1,\"S\":\"Stable\"},\"2\":{\"M\":0,\"B\":1,\"G_X\":0,\"G_Y\":0,\"G_Z\":3,\"P_X\":0,\"P_Y\":0,\"P_Z\":-1,\"S\":\"Stable\"},\"3\":{\"M\":0,\"B\":1,\"G_X\":0,\"G_Y\":0,\"G_Z\":4,\"P_X\":0,\"P_Y\":0,\"P_Z\":-1,\"S\":\"Stable\"}},\"Towers\":{\"INTERNAL_COUNT\":1,\"0\":{\"B\":99999,\"F\":0,\"N\":\"MAKE_SURE_I_GET_SET\"}},\"Factions\":{\"INTERNAL_COUNT\":1,\"0\":{\"B\":0,\"F\":1,\"A\":\"TowerMod.AStarFaction\"}},\"Players\":{\"INTERNAL_COUNT\":1,\"0\":{\"L_X\":1470.8695,\"L_Y\":1504.3987,\"L_Z\":2146.3967,\"R_P\":61297,\"R_Y\":-23266,\"R_R\":0}},\"Header\":{\"Mods\":{\"0\":{\"SafeName\":\"TowerMod\",\"Version\":1},\"1\":{\"SafeName\":\"TestMod\",\"Version\":1}}}}");
	`log(J.GetObject("Blocks"));
	`log(J.GetObject("Blocks").GetObject("2"));
	`log(J.GetObject("Blocks").GetObject("2").GetStringValue("S"));
	`log(class'JSOnObject'.static.EncodeJSON(J));
}

private function array<byte> ConvertToByteArray(out String String)
{
	local int i;
	local array<Byte> OutArray;
	for(i = 0; i < Len(String); i++)
	{
		OutArray[i] = Asc(Mid(String, i, 1));
	}
	return OutArray;
}

function OnRequestComplete(HttpResponseInterface Response, bool bSucceeded)
{
	local array<String> Headers;
	local String Header;

	`log("Got response!!!!!!! Succeeded="@bSucceeded);
	`log("URL="@Response.GetURL());
	// if we didn't succeed, we can't really trust the payload, so you should always really check this.
	if (bSucceeded)
	{
		Headers = Response.GetHeaders();
		foreach Headers(Header)
		{
			`log("Header:"@Header);
		}
		// GetContentAsString will make a copy of the payload to add the NULL terminator,
		// then copy it again to convert it to TCHAR, so this could be fairly inefficient.
		// This call also assumes the payload is UTF8 right now, as truly determining the encoding
		// is content-type dependent.
		// You also can't trust the content-length as you don't always get one. You should instead
		// always trust the length of the content payload you receive.
		`log("Payload:"@Response.GetContentAsString());
	}
}

exec function ExecClassIsChildOf()
{
	local TowerBlockStructural T;
	`log("Testing TowerBlockStructural.");
	`log("Is TowerBlockStructural SavableDynamic:"@ClassIsChildOf(class'TowerBlockStructural', class'SavableDynamic'));
	`log("Is TowerBlockStructural SavableStatic:"@ClassIsChildOf(class'TowerBlockStructural', class'SavableStatic'));
	`log("Is TowerBlockStructural SavableDynamic:"@ClassIsChildOf(class'SavableDynamic', class'TowerBlockStructural'));
	`log("Is TowerBlockStructural SavableStatic:"@ClassIsChildOf(class'SavableStatic', class'TowerBlockStructural'));
	foreach DynamicActors(class'TowerBlockStructural', T)
	{
		`log("Is TowerBlockStructural SavableDynamic:"@T.IsA('SavableDynamic'));
		`log("Is TowerBlockStructural SavableStatic:"@T.IsA('SavableStatic'));
		`log("Is TowerBlockStructural SavableDynamic:"@class'TowerBlockStructural'.IsA('SavableDynamic'));
		`log("Is TowerBlockStructural SavableStatic:"@class'TowerBlockStructural'.IsA('SavableStatic'));
		return;
	}
}

exec function DebugTestIsTouchingGround(optional int IterationCount)
{
	local float Time;
	local bool RecurResult, IterResult;
	local float RecurSum, IterSum;

	local Vector WorldOrigin, WorldDir;
	local Rotator PlayerDir;
	local Vector HitLocation, HitNormal;
	local Actor LookingAt;
	local TowerBlockStructural LookingBlock;
	local int i;
	GetPlayerViewPoint(WorldOrigin, PlayerDir);
	WorldDir = Vector(PlayerDir);
	LookingAt = Trace(HitLocation, HitNormal, (WorldOrigin+WorldDir)+WorldDir*10000,
		(WorldOrigin+WorldDir), TRUE);
	LookingBlock = TowerBlockStructural(LookingAt);
	
	if(LookingBlock != None)
	{
		IterResult = LookingBlock.IsTouchingGroundIterative(true);
		RecurResult = false;//LookingBlock.IsTouchingGroundRecursive(true);
		for(i = 0; i < IterationCount; i++)
		{
			Clock(Time);
//			LookingBlock.IsTouchingGroundRecursive(true);
			UnClock(Time);
			RecurSum += Time;
			Time = 0;

			Clock(Time);
			LookingBlock.IsTouchingGroundIterative(true);
			UnClock(Time);
			IterSum += Time;
			Time = 0;
		}
		`log("IsTouchingGroundRecursive() no longer implemented. Results invalid.");
		`log("Recursive Result:"@RecurResult@"      "@"Iterative Result:"@IterResult,,'ITG');
		`log("Did"@IterationCount@"iterations over"@GetBlockCountInChain(LookingBlock)@"children. Avg Recursive Time:"
			@RecurSum/IterationCount@"Avg Iteration Time:"@IterSum/IterationCount,,'ITG');
	}
	else
	{
		`log("Not a block.",,'ITG');
	}
}

function int GetBlockCountInChain(TowerBlockStructural Start)
{
	local TowerBlockStructural Block;
	local int ReturnInt;
	ReturnInt = 0;
	foreach Start.BasedActors(class'TowerBlockStructural', Block)
	{
		ReturnInt++;
		ReturnInt += GetBlockCountInChain(Block);
	}
	return ReturnInt;
}

exec function DebugTestRandom()
{
	local int i;
	for(i = 0; i < 10; i++)
	{
		`log(Rand(100));
	}
}

exec function DebugTestHash()
{
	local IVector Start, Finish;
	local byte bHitExtent;
	local array<int> Hashes;
	local int Hash;
	local int Collisions;
	Start = IVect(10,10,10);
	Finish = IVect(-10,-10,0);
	while(class'TowerGameUberTest'.static.DebugDecrementIVector(Start, Finish, bHitExtent))
	{
		Hash = Hash5(Start);
//		`log(Hash);
		if(Hashes.Find(Hash) != INDEX_NONE)
		{
			Collisions++;
//			`log(`IVectStr(Start)@"collision!");
		}
		Hashes.AddItem(Hash);
	}
	`log(Collisions@"collisions out of a possible 449.");
}

function int Hash1(IVector A)
{
	return A.X + A.Y + A.Z;
}

function int Hash2(IVector A)
{
	local int Result;
	Result += Result ^ (A.X << 13);
	Result += Result ^ (A.X >> 17);
	Result += Result ^ (A.X << 5);

	Result += Result ^ (A.Y << 13);
	Result += Result ^ (A.Y >> 17);
	Result += Result ^ (A.Y << 5);

	Result += Result ^ (A.Z << 13);
	Result += Result ^ (A.Z >> 17);
	Result += Result ^ (A.Z << 5);

	return Result;
}

function int Hash3(IVector A)
{
	return Rand(MaxInt);
}

function int Hash4(IVector A)
{
	return 0;
}

function int Hash5(IVector A)
{
	return (A.X * 2654435761 % 2**32) + (A.Y * 2654435761 % 2**32) + (A.Z * 2654435761 % 2**32);
}

exec function DebugBitFlags()
{
	`log(AStar.PR_Air); // 2
	`log(AStar.PR_Ground); // 1
	`log(AStar.PR_GroundAndAir); // 3
	`log(AStar.PR_Air | AStar.PR_Ground); // 3
	`log((AStar.PR_Air | AStar.PR_Ground) == AStar.PR_GroundAndAir); // true
	`log((AStar.PR_GroundAndAir & AStar.PR_Ground) == AStar.PR_Ground); // true
	`log((AStar.PR_GroundAndAir & AStar.PR_Air) == AStar.PR_Air); // true
	`log((AStar.PR_BlocksAndModules & AStar.PR_Modules) == AStar.PR_Modules); // true
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
	
	Outer.AStar.Step();
	
	
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