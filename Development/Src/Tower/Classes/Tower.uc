/** 
Tower

Represents a player's tower.
*/
class Tower extends TowerFaction
	config(Tower)
	dependson(TowerBlock);

/** Save IDs. */
const TOWER_NAME_ID = "N";
const PLAYER_NUMBER_ID = "P";

`if(`isdefined(debug)) 
	`define simulateddebug simulated 
	`else 
	`define simulateddebug 
`endif

var privatewrite TowerBlockRoot Root;

/** Array of existing blocks ONLY used to ease debugging purposes. This should never be used for any
non-debug in-game things ever! */
var(InGame) editconst private array<TowerBlock> DebugBlocks;

var(InGame) editconst string TowerName;
var(InGame) editconst TowerPlayerReplicationInfo OwnerPRI;

var array<TowerBlockStructural> OrphanRoots;
var const config bool bDebugDrawHierarchy, bDebugDrawHierarchyOnlyVisible;
var const Color RegularColor, OrphanColor, OrphanRootColor;

replication
{
	if(bNetDirty)
		TowerName, OwnerPRI;
	if(bNetInitial)
		Root;
}

//@TODO - Take all needed vars here.
simulated event Initialize()
{
	if(bDebugDrawHierarchy && WorldInfo.NetMode != NM_DedicatedServer)
	{
		TowerPlayerController(GetALocalPlayerController()).myHUD.AddPostRenderedActor(Self);
	}
}

final function SetRootBlock(TowerBlockRoot RootBlock)
{
	Root = RootBlock;
	`assert(Root != None);
}

//@TODO - We really only need one of the locations. Probably Grid.
function TowerBlock AddBlock(TowerBlock BlockArchetype, TowerBlock Parent, 
	out IVector GridLocation)
{
	local TowerBlock NewBlock;
	local IVector ParentDir;
	local Vector SpawnLocation;
	
	SpawnLocation = GridLocationToVector(GridLocation);
	// Done in GridLocationToVector.
//	SpawnLocation.Z += 128;
	NewBlock = Spawn(BlockArchetype.class, ((Parent!=None) ? Parent : None) ,, SpawnLocation,,BlockArchetype);
	if(Parent != None)
	{
		NewBlock.SetBase(Parent);
		NewBlock.ReplicatedBase = Parent;
		NewBlock.CalculateBlockRotation();
		ParentDir = FromVect(Normal(Parent.Location - NewBlock.Location));
	}
	NewBlock.Initialize(GridLocation, ParentDir, OwnerPRI);
	
	//@TODO - Tell AI about this?
	return NewBlock;
}

function bool RemoveBlock(TowerBlock Block)
{
	local TowerBlock IteratorBlock;
	local TowerBlockStructural DroppingBlock;
	local array<TowerBlock> ToIterate;
	foreach Block.BasedActors(class'TowerBlock', IteratorBlock)
	{
		ToIterate.AddItem(IteratorBlock);
	}
	foreach ToIterate(IteratorBlock)
	{
		if(TowerBlockModule(IteratorBlock) != None)
		{
			IteratorBlock.OrphanedParent();
		}
		else
		{
			if(!FindNewParent(IteratorBlock, Block, true))
			{
				if(Block.IsInState('UnstableParent'))
				{
					DroppingBlock = TowerBlockStructural(Block);
				}
				else if(Block.IsInState('Unstable'))
				{
					DroppingBlock = TowerBlockStructural(Block.GetBaseMost());
				}
				`log(DroppingBlock);
				`assert(DroppingBlock != None || Block.IsInState('Stable'));
				if(DroppingBlock != None)
				{
					if(DroppingBlock.IsTimerActive('DroppedSpace'))
					{
						IteratorBlock.SetTimer(DroppingBlock.GetRemainingTimeForTimer('DroppedSpace'), 
							false, 'DroppedSpaceInitial');
					}
					else
					{
						// DroppedSpaceInitial is active.
						IteratorBlock.SetTimer(DroppingBlock.GetRemainingTimeForTimer('DroppedSpaceInitial'),
							false, 'DroppedSpaceInitial');
					}
				}
			}
		}
	}
	Block.Destroy();
	return true;
}

function IVector GetBlockDirection(TowerBlock Origin, TowerBlock Other)
{
	local IVector Difference;
	Difference = INormal(Other.GridLocation - Origin.GridLocation);
	return Difference;
}

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerBlock BlockKiller);

function TowerBlock GetBlockFromLocationAndDirection(const out IVector GridLocation, const out IVector ParentDirection)
{
	local Actor Block;
	local IVector StartGridLocation;
	local Vector StartLocation, EndLocation, HitNormal, HitLocation;
	StartGridLocation = GridLocation + ParentDirection;
	StartLocation = GridLocationToVector(StartGridLocation);
	// Done in GridLocationToVector.
	// The origin of blocks is on their bottom, so bump it up a bit so we're not on the edge.
	//StartLocation.Z += 128;
	EndLocation.X = StartLocation.X + 10;
	EndLocation.Y = StartLocation.Y + 10;
	EndLocation.Z = StartLocation.Z + 10;
	//@TODO - Why trace?
	Block = Trace(HitLocation, HitNormal, EndLocation, StartLocation, TRUE);
	return TowerBlock(Block);
}

function bool CheckForParent(TowerBlock Block)
{
	if(Block.GetParent() != None)
	{
		// You already have a parent.
		return true;
	}
	return FindNewParent(Block);
}

/** Tries to find any nodes physically adjacent to the given one. If TRUE, bChildrenFindParent will
have all this nodes' children (and their children and so forth) perform a FindNewParent as well. */
final function bool FindNewParent(TowerBlock Node, optional TowerBlock OldParent=None,
	optional bool bChildrenFindParent=false, optional bool bChild=false)
{
	local TowerBlock Block;
	local TraceHitInfo HitInfo;
//	`log(Node@"Finding parent for node. Current parent:"@Node.Base);
	if(!bChild)
	{
		Node.SetBase(None); // Redundant with the last SetBase?
	}
	// If we make it 128 then the slightest inaccuracy causes this to miss a potential parent.
	foreach Node.CollidingActors(class'TowerBlock', Block, 132, , true,,HitInfo)
	{
//		`log(Node@"Found Potential Parent:"@Block@HitInfo.HitComponent@HitInfo.HitComponent.class);
//		`log(OldParent != Block @ TraceNodeToRoot(Block, OldParent) @ Node != Block);
		if(TowerBlockModule(Block) != None)
		{
			//@TODO - Destroy block? Module? Check direction first.
			continue;
		}
		else if(OldParent != Block && TraceNodeToRoot(Block, OldParent) && Node != Block)
		{
			Node.SetBase(Block);
			Node.SetOwner(Block);
			TowerBlockStructural(Node).ReplicatedBase = Block;
			Node.AdoptedParent();
			`log(Node@"And it's good!"@Block);
			return TRUE;
		}
	}
	if(bChildrenFindParent)
	{
//		`log("Having children look for supported parents...");
		foreach Node.BasedActors(class'TowerBlock', Block)
		{
			// We don't want air or modules looking for parents.
			if(TowerBlockStructural(Block) != None)
			{
				//@TODO - Make me iterative instead of recursive!
				if(FindNewParent(Block, OldParent, bChildrenFindParent, true) && !bChild)
				{
					FindNewParent(Node, OldParent, false);
				}
			}
		}
	}
	if(!bChild && Node.Base == None && OldParent != None)
	{
//		`log("No parents available,"@Node@"is an orphan. Handle this.");
		// True orphan.
		Node.SetBase(None);
		TowerBlockStructural(Node).ReplicatedBase = None;
		Node.OrphanedParent();
	}
	return false;
}

/** Returns TRUE if there is a path to the root through parents, otherwise FALSE. */
private final function bool TraceNodeToRoot(TowerBlock Block, optional TowerBlock InvalidBase)
{
	// IBO and GBM both clocked out at 0.0250 ms. Virtually identical.
	return Block.GetBaseMost().Class == class'TowerBlockRoot' && !Block.IsBasedOn(InvalidBase);
}

simulated static final function Vector GridLocationToVector(out const IVector GridLocation)
{
	local Vector NewBlockLocation;
	local Vector GridOrigin;
	// This could be made completely static.
	GridOrigin = TowerGameReplicationInfo(class'WorldInfo'.static.GetWorldInfo().GRI).GridOrigin;
	//@FIXME: Block dimensions. Constant? At least have a constant, traceable part?
	NewBlockLocation.X = (GridLocation.X * 256)+GridOrigin.X;
	NewBlockLocation.Y = (GridLocation.Y * 256)+GridOrigin.Y;
	NewBlockLocation.Z = (GridLocation.Z * 256)+GridOrigin.Z;
	// Pivot point in middle, bump it up.
	NewBlockLocation.Z += 128;
	return NewBlockLocation;
}

simulated static final function IVector VectorToGridLocation(out const Vector RealLocation)
{
	local Vector GridOrigin;
	GridOrigin = TowerGameReplicationInfo(class'WorldInfo'.static.GetWorldInfo().GRI).GridOrigin;
	return IVect(Round(RealLocation.X-GridOrigin.X)/256, Round(RealLocation.Y-GridOrigin.Y)/256, 
		Round(RealLocation.Z-GridOrigin.Z)/256);
}

simulated final function ReCalculateAllBlockLocations()
{
	local array<TowerBlockStructural> Blocks;
	local array<Actor> BlockBases;
	local TowerBlockStructural StructBlock;
	local int i;

	foreach DynamicActors(class'TowerBlockStructural', StructBlock)
	{
		Blocks.AddItem(StructBlock);
		BlockBases.AddItem(StructBlock.Base);
		StructBlock.UpdateLocation(false);
	}

	foreach Blocks(StructBlock, i)
	{
		StructBlock.SetBase(BlockBases[i]);
	}
	return;
}

simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	local TowerBlockStructural OrphanRoot;
	DrawDebugRelationship(Canvas, Root, RegularColor);
	foreach OrphanRoots(OrphanRoot)
	{
		DrawDebugRelationship(Canvas, OrphanRoot, OrphanRootColor);
	}
}

simulated function DrawDebugRelationship(out Canvas Canvas, TowerBlock CurrentBlock, Color DrawColor)
{
	/*
	local array<TowerBlock> BlockStack;
	local TowerBlock ItrBlock;

	`Push(BlockStack, None);

	while(CurrentBlock != None)
	{
		if(CurrentBlock.Base != None)
		{
			CurrentBlock.DrawDebugLine(CurrentBlock.Location, CurrentBlock.Base.Location, DrawColor.R, DrawColor.G,
				DrawColor.B);
		}
		foreach CurrentBlock.BasedActors(class'TowerBlock', ItrBlock)
		{
			`Push(BlockStack, ItrBlock);
		}
		CurrentBlock = `Pop(BlockStack);
	}
	`assert(BlockStack.Length == 0); 
	*/
	
	local TowerBlock Block;
	local Vector Begin, End;
	Begin = Canvas.Project(CurrentBlock.Location);
	foreach CurrentBlock.BasedActors(class'TowerBlock', Block)
	{
		if(bDebugDrawHierarchyOnlyVisible)
		{
			if(Block.Rendered())
			{
				End = Canvas.Project(Block.Location);
				Canvas.Draw2DLine(Begin.X, Begin.Y, End.X, End.Y, DrawColor);
				if(DrawColor == OrphanRootColor)
				{
					DrawColor = OrphanColor;
				}
			}
		}
		else
		{
			End = Canvas.Project(Block.Location);
			Canvas.Draw2DLine(Begin.X, Begin.Y, End.X, End.Y, DrawColor);
		}
		DrawDebugRelationship(Canvas, Block, DrawColor);
	}
}

function DestroyAllBlocks()
{
	local TowerBlockStructural Block;
	// Either this or BasedActors.
	foreach DynamicActors(class'TowerBlockStructural', Block)
	{
		if(Block.OwnerPRI.Tower == Self)
		{
			Block.TakeDamage(MAXINT, None, Vect(0,0,0), Vect(0,0,0), class'DmgType_Telefragged');
		}
	}
}

event Disabled()
{
	DestroyAllBlocks();
	GotoState('Inactive');
	ClientDisabled();
}

event Enabled()
{
	SetInitialState();
	ClientEnabled();
}

reliable client event ClientDisabled()
{
	GotoState('Inactive');
}

reliable client event ClientEnabled()
{
	SetInitialState();
}

/** State for towers who have had their root blocks destroyed. */
simulated state Inactive
{
	`if(`isdefined(final_release))
	ignores AddBlock, RemoveBlock, PostRenderFor, OnTargetableDeath;
	`else
	function TowerBlock AddBlock(TowerBlock BlockArchetype, TowerBlock Parent, 
		out IVector GridLocation)
	{
		`warn("AddBlock called during Inactive! How could this happen?!");
		return None;
	}

	function bool RemoveBlock(TowerBlock Block)
	{
		`warn("RemoveBlock called during Inactive! How could this happen?!");
		return false;
	}
	`endif
Begin:
	TowerPlayerController(GetALocalPlayerController()).myHUD.RemovePostRenderedActor(Self);
}

/********************************
Save/Loading
********************************/

/** Called when saving a game. Returns a JSON object, or None to not save this. */
public event JSonObject OnSave(const SaveType SaveType)
{
	local JSonObject JSON;
	JSON = Super.OnSave(SaveType);
	if(JSON == None)
	{
		JSON = new class'JSonObject';
	}
	if (JSON == None)
	{
		`warn(self@"Could not save!");
		return None;
	}

	JSON.SetStringValue(TOWER_NAME_ID, TowerName);
//	JSON.SetStringValue

	return JSON;
}

/** Called when loading a game. This function is intended for dynamic objects, who should create a new object and load
this data into it. */
public static event OnLoad(JSONObject Data, out const GlobalSaveInfo SaveInfo)
{
//	TowerName = Data.GetStringValue(TOWER_NAME_ID, TowerName);
}

DefaultProperties
{
	RegularColor={(R=255)}
	OrphanColor={(B=255)}
	OrphanRootColor={(G=255)}
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	bStatic=False
	bNoDelete=False
}