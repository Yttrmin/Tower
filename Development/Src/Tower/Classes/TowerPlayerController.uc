class TowerPlayerController extends GamePlayerController
	config(Tower);

var TowerSaveSystem SaveSystem;
var TowerMusicManager MusicManager;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	SaveSystem = new class'Tower.TowerSaveSystem';
	MusicManager = Spawn(class'Tower.TowerMusicManager');
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
Adding TowerModules:
(Note: TMRI = TowerModuleReplicationInfo, TPRI = TowerPlayerReplicationInfo, TPC = TowerPlayerController)
(Note: TPRI is used for sending client/server functions as it'd be impossible for all clients to do such with one TMRI.)

Server: 
AddPlaceable() (Called from TowerHUD. Determines whether or not Placeable needs to use tickets. In this case, yes.)
-> GenerateAddTicket() 
-> ServerSendAddTicket() (Yes, the server creates and sends AddTickets to itself. Keeps consistency.)
-> TowerGame::AddPlaceable() (Leads to TowerPlaceable::CreatePlaceable(), creates and initializes component.)
-> TPRI::ServerAddModule() (Updates TMRI's InfoPacket so that clients know to update.)

Client:
AddPlaceable() (Called from TowerHUD. Determines whether or not Placeable needs to use tickets. In this case, yes.)
-> GenerateAddTicket() 
-> ServerSendAddTicket()
... Client is done here. If the server allows it, the TMRI's InfoPacket will be updated.
XTMRI::ReplicatedEvent() (Called when InfoPacket is updated, in this case because the server accepted our addition.
X-> HandleNewInfoPacket()
X-> QueryModuleInfo() (Client finds the server has 1 more module than itself, requests info about it so it can create it.)
X... Client is done here until the server (hopefully) responds shortly.
X-> TPRI::ReceiveModuleInfo()
X-> TMRI::AddModule() (Creates identical module based on info and updates its Count and Checksum data.)


Removing TowerModules:

Server:
RemovePlaceable() (Called from TowerHUD. Determines whether or not to use RemoveModule(). In this case, yes.)
-> RemoveModule() (Creates a RemoveTicket for the next function (Modules can't be replicated).)
-> ServerSendRemoveTicket() (Yep, server sends a RemoveTicket to itself. This should probably come AFTER the rest to make sure valid.)
-> TPRI::ServerRemoveModule() (Removes Module from game and updates InfoPacket in TMRI.)
-> TPC::ServerRemovePlaceable() (Starts the chain of RemovePlaceables to actually remove Module from game.)
-> TowerGame::RemovePlaceable()

Client:
RemovePlaceable() (Called from TowerHUD. Determines whether or not to use RemoveModule(). In this case, yes.)
-> RemoveModule() (Creates a RemoveTicket for the next function (Modules can't be replicated).)
-> ServerSendRemoveTicket() 
... Client is done here. Server will update TMRI's InfoPacket if it's allowed.
TMRI::ReplicatedEvent()
-> HandleNewInfoPacket()
-> RemoveModule() (Removes the module and updates its Count and Checksum data.)


Updating TowerModules:


*/

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

exec function RemoveAllBlocks()
{
	ServerRemoveAllBlocks();
}

//@TODO - Can't this just directly call a reliable server function in its Tower?
exec function SetTowerName(string NewName)
{
	ServerSetTowerName(NewName);
}

exec function SaveGame(string FileName)
{
	//@TODO - Move verification stuff to TowerSaveSystem or DLL since people definitely won't get that
	// stuff publically.
	if(FileName == "")
	{
		return;
	}
	SaveSystem.SaveGame(FileName, false, self);
}

exec function LoadGame(string FileName, bool bTowerOnly)
{
	//@TODO - Move verification stuff to TowerSaveSystem or DLL since people definitely won't get that
	// stuff publically.
	if(FileName == "")
	{
		return;
	}
	SaveSystem.LoadGame(FileName, bTowerOnly, self);
}

exec function TestStaticSaveLoadGame(String FileName)
{
	class'TowerSaveSystem'.static.TestStaticSave(FileName, self);
	class'TowerSaveSystem'.static.LoadStaticSave(FileName, self);
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

function AddBlock(TowerBlock BlockArchetype, TowerBlock Parent, out IVector GridLocation)
{
	local int ModIndex, ModBlockIndex;
	ConvertBlockToIndexes(BlockArchetype, ModIndex, ModBlockIndex);
	ServerAddBlock(ModIndex, ModBlockIndex, Parent, GridLocation);
	//TowerGame(WorldInfo.Game).AddPlaceable(GetTower(), Placeable, Parent, GridLocation);
}

reliable server function ServerAddBlock(int ModIndex, int ModBlockIndex, TowerBlock Parent, IVector GridLocation)
{
	TowerGame(WorldInfo.Game).AddBlock(GetTower(), ConvertIndexesToBlock(ModIndex, ModBlockIndex), Parent, GridLocation);
}

simulated final function ConvertBlockToIndexes(TowerBlock BlockArchetype, out int ModIndex, out int ModBlockIndex)
{
	local TowerModInfo Mod;
	for(Mod = TowerGameReplicationInfo(WorldInfo.GRI).RootMod; Mod != None; Mod = Mod.NextMod)
	{
		ModBlockIndex = Mod.ModBlocks.find(BlockArchetype);
		if(ModBlockIndex != -1)
		{
			return;
		}
		ModIndex++;
	}
}

function TowerBlock ConvertIndexesToBlock(out int ModIndex, out int ModBlockIndex)
{
	local TowerModInfo Mod;
	Mod = TowerGameReplicationInfo(WorldInfo.GRI).RootMod;
	while(ModIndex > 0)
	{
		Mod = Mod.NextMod;
		ModIndex--;
	}
	return Mod.ModBlocks[ModBlockIndex];
}

/** Called from TowerHUD::OnMouseClick if a valid TowerPlaceable is selected for removal. */
simulated function RemoveBlock(TowerBlock Block)
{
	`log("RemovePlaceable:"@Block);
//	Placeable.RemoveSelf();
	//@TODO - Stupid parenting causing no collions means we have to do crap like this.

	ServerRemoveBlock(Block);
}

reliable server function ServerRemoveBlock(TowerBlock Block)
{
	`log("ServerRemovePlaceable:"@Block);
	TowerGame(WorldInfo.Game).RemoveBlock(GetTower(), Block);
}

reliable server function ServerRemoveAllBlocks()
{
	//@TODO - Make work.
	GetTower().NodeTree.RemoveNode(GetTower().NodeTree.GetRootNode());
}

reliable server function ServerSetTowerName(string NewName)
{
	TowerGame(WorldInfo.Game).SetTowerName(GetTower(), NewName);
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