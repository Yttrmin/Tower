/** 
Tower

Represents a player's tower.
*/
class Tower extends TowerFaction
	dependson(TowerBlock);

var privatewrite TowerBlockRoot Root;

/** Array of existing blocks ONLY used to ease debugging purposes. This should never be used for any
non-debug in-game things ever! */
var(InGame) editconst private array<TowerBlock> DebugBlocks;

var(InGame) editconst string TowerName;
var(InGame) editconst TowerPlayerReplicationInfo OwnerPRI;

replication
{
	if(bNetDirty)
		TowerName, OwnerPRI;
	if(bNetInitial)
		Root;
}

final function SetRootBlock(TowerBlockRoot RootBlock)
{
	Root = RootBlock;
	`assert(Root != None);
}

//@TODO - We really only need one of the locations. Probably Grid.
function TowerBlock AddBlock(TowerBlock BlockArchetype, TowerBlock Parent,
	out Vector SpawnLocation, out IVector GridLocation, optional bool bAddAir=true)
{
	local TowerBlock NewBlock;
	local IVector ParentDir;
	local rotator NewRotation;
	if(Parent != None && Parent.IsInState('Stable') || BlockArchetype.class == class'TowerBlockRoot')
	{
		NewBlock = Spawn(BlockArchetype.class, ((Parent!=None) ? Parent : None) ,, SpawnLocation,,BlockArchetype);
		if(Parent != None)
		{
			`log(NewBlock@"spawning with parent"@Parent@"in state"@GetStateName());
			ParentDir = FromVect(Normal(Parent.Location - SpawnLocation));
			if(ParentDir.Z == 0)
			{
				NewRotation.Pitch = ParentDir.X * (90 * DegToUnrRot);
				NewRotation.Roll = ParentDir.Y * (-90 * DegToUnrRot);
				NewRotation.Yaw = ParentDir.Z * (-90 * DegToUnrRot);
			}
			else if(ParentDir.Z == -1)
			{
	//			NewRotation.Roll = -180 * DegToUnrRot;
			}
			else if(ParentDir.Z == 1)
			{
				NewRotation.Roll = 180 * DegToUnrRot;
			}
			else
			{
				NewRotation = NewBlock.Rotation;
			}
			NewBlock.SetBase(Parent);
			NewBlock.SetRelativeRotation(NewRotation);
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

function DestroyOccupiedAir(TowerBlock Block, TowerBlock NewBlock)
{
	local TowerBlockAir AirBlock;
	foreach Block.BasedActors(class'TowerBlockAir', Airblock)
	{
		if(AirBlock.GridLocation == NewBlock.GridLocation)
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
	while(EmptyDirections.Length > 0)
	{
		AirGridLocation = Block.GridLocation + EmptyDirections[0];
		AirSpawnLocation = Block.Location + ToVect(EmptyDirections[0] * 256);
		AddBlock(TowerGame(WorldInfo.Game).AirArchetype, Block, AirSpawnLocation,
			AirGridLocation);
		EmptyDirections.Remove(0, 1);
	}
}

//@BUG - Sticking a block +Y of another results in an air at -Y (WRONG) and no air at +Y (ALSO WRONG).
function IVector GetBlockDirection(TowerBlock Origin, TowerBlock Other)
{
	local IVector Difference;
	Difference.X = (Abs(Origin.GridLocation.X) - Abs(Other.GridLocation.X));
	Difference.Y = (Abs(Origin.GridLocation.Y) - Abs(Other.GridLocation.Y));
	Difference.Z = (Abs(Other.GridLocation.Z) - Abs(Origin.GridLocation.Z));
	return Difference;
}

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerBlock BlockKiller);

function bool RemoveBlock(TowerBlock Block)
{
	local TowerBlock IteratorBlock;
	local TowerBlockAir ITeratorAir;
	local array<TowerBlockAir> ToDelete;
	foreach Block.BasedActors(class'TowerBlock', IteratorBlock)
	{
		`log(IteratorBlock);
		if(IteratorBlock.class != class'TowerBlockAir')
		{
			FindNewParent(IteratorBlock, Block, true);
		}
		else
		{
			ToDelete.AddItem(TowerBlockAir(IteratorBlock));
		}
	}
	foreach ToDelete(IteratorAir)
	{
		IteratorAir.Destroy();
	}
	Block.Destroy();
	return true;
}

function TowerBlock GetBlockFromLocationAndDirection(const out IVector GridLocation, const out IVector ParentDirection)
{
	local Actor Block;
	local Vector StartLocation, EndLocation, HitNormal, HitLocation, VectorGridLocation;
	VectorGridLocation = ToVect(GridLocation) + ToVect(ParentDirection);
	StartLocation = TowerGame(WorldInfo.Game).GridLocationToVector(VectorGridLocation);
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
	`log(Node@"Finding parent for node. Current parent:"@Node.Base);
	if(!bChild)
	{
		Node.SetBase(None); // Why.
	}
	foreach Node.CollidingActors(class'TowerBlock', Block, 130, , true,,HitInfo)
	{
		`log("Found Potential Parent:"@Block@HitInfo.HitComponent@HitInfo.HitComponent.class);
		if(OldParent != Block && TraceNodeToRoot(Block, OldParent) && Node != Block && !HitInfo.HitComponent.isA('TowerModule'))
		{
			Node.SetBase(Block);
			Node.AdoptedParent();
			`log("And it's good!");
			return TRUE;
		}
	}
	if(bChildrenFindParent)
	{
		`log("Having children look for supported parents...");
		foreach Node.BasedActors(class'TowerBlock', Block)
		{
			// We don't want air or modules looking for parents.
			if(Block.IsA('TowerBlockStructural'))
			{
				//@TODO - Make me iterative instead of recursive!
				FindNewParent(Block, OldParent, bChildrenFindParent, true);
			}
		}
	}
	if(!bChild && Node.Base == None && OldParent != None)
	{
		`log("No parents available,"@Node@"is an orphan. Handle this.");
		// True orphan.
		Node.SetBase(None); // Why.
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

DefaultProperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	bStatic=False
	bNoDelete=False
}