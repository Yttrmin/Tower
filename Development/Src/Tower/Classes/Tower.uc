/** 
Tower

Represents a player's tower.
*/
class Tower extends TowerFaction
	config(Tower)
	dependson(TowerBlock);

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
var const config bool bDebugDrawHierarchy, bDebugDrawHierarchyOnlyVisible, bDebugDrawHierarchyIncludeAir;
var const Color RegularColor, OrphanColor, OrphanRootColor;

replication
{
	if(bNetDirty)
		TowerName, OwnerPRI;
	if(bNetInitial)
		Root;
}

//@TODO - Take all needed vars here.
event Initialize()
{
	if(bDebugDrawHierarchy)
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
	out const Vector SpawnLocation, out IVector GridLocation, optional bool bAddAir=true)
{
	local TowerBlock NewBlock;
	local IVector ParentDir;
	if((Parent != None && !Parent.IsA('TowerBlockModule') && Parent.IsInState('Stable')) 
		|| BlockArchetype.class == class'TowerBlockRoot' || TowerGame(WorldInfo.Game).bPendingLoad)
	{
		NewBlock = Spawn(BlockArchetype.class, ((Parent!=None) ? Parent : None) ,, SpawnLocation,,BlockArchetype);
		if(Parent != None)
		{
			NewBlock.SetBase(Parent);
			if(NewBlock.class != class'TowerBlockAir')
			{
				if(TowerBlockStructural(NewBlock) != None)
				{
					// Why do only TBS get this?
					// Because they don't replicate actor stuff IDIOT.
					TowerBlockStructural(NewBlock).ReplicatedBase = Parent;
				}
				else
				{
					NewBlock.bUpdateRotation = true;
				}
				NewBlock.CalculateBlockRotation();
			}
			ParentDir = FromVect(Normal(Parent.Location - NewBlock.Location));
		}
		NewBlock.Initialize(GridLocation, ParentDir, OwnerPRI);
		if(bAddAir && NewBlock.class != class'TowerBlockAir')
		{
			CreateSurroundingAir(NewBlock);
		}
	}
	
	//@TODO - Tell AI about this?
	return NewBlock;
}

function bool RemoveBlock(TowerBlock Block)
{
	local TowerBlock IteratorBlock;
	local TowerBlockAir ITeratorAir;
	local array<TowerBlockAir> ToDelete;
	local array<TowerBlock> ToIterate;
	foreach Block.BasedActors(class'TowerBlock', IteratorBlock)
	{
		if(IteratorBlock.class != class'TowerBlockAir')
		{
			if(IteratorBlock.IsA('TowerBlockModule'))
			{
				//@BUG (?) - The module will Destroy() itself. That's fine in a foreach since the array isn't actually
				// being modified, right?
				IteratorBlock.OrphanedParent();
				continue;
			}
			ToIterate.AddItem(IteratorBlock);
			//@README DON'T DO THIS YOU IDIOT, FINDNEWPARENT CHANGES BASES, AND WE'RE IN A BASEDACTORS() ITERATOR. THINK.
			//FindNewParent(IteratorBlock, Block, true);
		}
		else
		{
			ToDelete.AddItem(TowerBlockAir(IteratorBlock));
		}
	}
	foreach ToIterate(IteratorBlock)
	{
		FindNewParent(IteratorBlock, Block, true);
	}
	foreach ToDelete(IteratorAir)
	{
		IteratorAir.Destroy();
	}
	Block.Destroy();
	return true;
}

function DestroyOccupiedAir(TowerBlock BlockToDestroyAirs, TowerBlock BlockToTestIfOccupying)
{
	local TowerBlockAir AirBlock;
	foreach BlockToDestroyAirs.BasedActors(class'TowerBlockAir', Airblock)
	{
		if(AirBlock.GridLocation == BlockToTestIfOccupying.GridLocation)
		{
			AirBlock.Destroy();
		}
	}
}

function CreateSurroundingAir(TowerBlock Block)
{
	local Vector AirSpawnLocation;
	local IVector AirGridLocation;
	local TowerBlock IteratorBlock;
	local array<IVector> EmptyDirections;
	EmptyDirections[0] = IVect(1,0,0);
	EmptyDirections[1] = IVect(-1,0,0);

	EmptyDirections[2] = IVect(0,1,0);
	EmptyDirections[3] = IVect(0,-1,0);

	EmptyDirections[4] = IVect(0,0,1);
	if(Block.GridLocation.Z != 0)
	{
		EmptyDirections[5] = IVect(0,0,-1);
	}
	foreach Block.CollidingActors(class'TowerBlock', IteratorBlock, 136,, true)
	{
		if(Block != IteratorBlock)
		{
			DestroyOccupiedAir(IteratorBlock, Block);
			EmptyDirections.RemoveItem(GetBlockDirection(Block, IteratorBlock));
		}
	}
	`assert(EmptyDirections.Length <= 5);
	while(EmptyDirections.Length > 0)
	{
		AirGridLocation = Block.GridLocation + EmptyDirections[0];
		AirSpawnLocation = Block.Location + ToVect(EmptyDirections[0] * 256);
		AddBlock(TowerGame(WorldInfo.Game).AirArchetype, Block, AirSpawnLocation,
			AirGridLocation);
		EmptyDirections.Remove(0, 1);
	}
}

function IVector GetBlockDirection(TowerBlock Origin, TowerBlock Other)
{
	local IVector Difference;
	Difference = INormal(Other.GridLocation - Origin.GridLocation);
//	Difference.X = (Abs(Origin.GridLocation.X) - Abs(Other.GridLocation.X));
//	Difference.Y = (Abs(Origin.GridLocation.Y) - Abs(Other.GridLocation.Y));
//	Difference.Z = (Abs(Other.GridLocation.Z) - Abs(Origin.GridLocation.Z));
	return Difference;
}

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerBlock BlockKiller);

function TowerBlock GetBlockFromLocationAndDirection(const out IVector GridLocation, const out IVector ParentDirection)
{
	local Actor Block;
	local IVector StartGridLocation;
	local Vector StartLocation, EndLocation, HitNormal, HitLocation;
	StartGridLocation = GridLocation + ParentDirection;
	StartLocation = TowerGame(WorldInfo.Game).GridLocationToVector(StartGridLocation);
	// The origin of blocks is on their bottom, so bump it up a bit so we're not on the edge.
	StartLocation.Z += 128;
	EndLocation.X = StartLocation.X + 10;
	EndLocation.Y = StartLocation.Y + 10;
	EndLocation.Z = StartLocation.Z + 10;
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
	foreach Node.CollidingActors(class'TowerBlock', Block, 130, , true,,HitInfo)
	{
//		`log("Found Potential Parent:"@Block@HitInfo.HitComponent@HitInfo.HitComponent.class);
		if(OldParent != Block && TraceNodeToRoot(Block, OldParent) && Node != Block && !HitInfo.HitComponent.isA('TowerModule'))
		{
			Node.SetBase(Block);
			Node.SetOwner(Block);
			TowerBlockStructural(Node).ReplicatedBase = Block;
			Node.AdoptedParent();
//			`log("And it's good!");
			return TRUE;
		}
	}
	if(bChildrenFindParent)
	{
//		`log("Having children look for supported parents...");
		foreach Node.BasedActors(class'TowerBlock', Block)
		{
			// We don't want air or modules looking for parents.
			if(Block.IsA('TowerBlockStructural'))
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
	return Block.IsBasedOn(Root) && !Block.IsBasedOn(InvalidBase);
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

function DrawDebugRelationship(out Canvas Canvas, TowerBlock CurrentBlock, Color DrawColor)
{
	local TowerBlock Block;
	local Vector Begin, End;
	Begin = Canvas.Project(CurrentBlock.Location);
	foreach CurrentBlock.BasedActors(class'TowerBlock', Block)
	{
		if(bDebugDrawHierarchyOnlyVisible)
		{
			if(Block.Rendered() || (bDebugDrawHierarchyIncludeAir && Block.class == class'TowerBlockAir' 
				&& TowerBlock(Block.Base).Rendered()))
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
			if(Block.class != class'TowerBlockAir' || bDebugDrawHierarchyIncludeAir)
			{
				End = Canvas.Project(Block.Location);
				Canvas.Draw2DLine(Begin.X, Begin.Y, End.X, End.Y, DrawColor);
			}
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
			Block.TakeDamage(99999, None, Vect(0,0,0), Vect(0,0,0), class'DmgType_Telefragged');
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
		out const Vector SpawnLocation, out IVector GridLocation, optional bool bAddAir=true)
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