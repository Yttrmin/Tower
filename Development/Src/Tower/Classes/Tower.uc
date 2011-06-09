/** 
Tower

Represents a player's tower, which a player can only have one of. Tower's are essentially containers for TowerBlocks.
*/
class Tower extends TowerFaction
	dependson(TowerBlock);

var TowerTree NodeTree;
var TowerBlockRoot Root;

/** Array of existing blocks ONLY used to ease debugging purposes. This should never be used for any
non-debug in-game things ever!*/
var() private array<TowerBlock> DebugBlocks;

var() string TowerName;
var() repnotify TowerPlayerReplicationInfo OwnerPRI;

replication
{
	if(bNetDirty)
		TowerName, OwnerPRI;
	if(bNetInitial)
		Root;
}

simulated event ReplicatedEvent(name VarName)
{
	Super.ReplicatedEvent(VarName);
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	AddTree();
}

reliable server function AddTree()
{
	NodeTree = new class'TowerTree';
}

function TowerBlock AddBlock(TowerBlock BlockArchetype, TowerBlock Parent,
	out Vector SpawnLocation, out IVector GridLocation)
{
	local TowerBlock NewBlock;
	NewBlock = BlockArchetype.AttachBlock(BlockArchetype, Parent, NodeTree, SpawnLocation, GridLocation, OwnerPRI);
	CreateSurroundingAir(NewBlock);
	// Tell AI about this?
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
		Block.AttachBlock(TowerGame(WorldInfo.Game).AirArchetype, Block, NodeTree, 
			AirSpawnLocation, AirGridLocation, OwnerPRI);
		EmptyDirections.Remove(0, 1);
	}
}

function IVector GetBlockDirection(TowerBlock Origin, TowerBlock Other)
{
	local IVector Difference;
	Difference.X = (Abs(Origin.GridLocation.X) - Abs(Other.GridLocation.X));
	Difference.Y = (Abs(Origin.GridLocation.Y) - Abs(Other.GridLocation.Y));
	Difference.Z = (Abs(Origin.GridLocation.Z) - Abs(Other.GridLocation.Z));
	return Difference;
}

event OnTargetableDeath(TowerTargetable Targetable, TowerTargetable TargetableKiller, TowerBlock BlockKiller)
{
}

function bool RemoveBlock(TowerBlock Block)
{
	Block.RemoveBlock(Block, NodeTree);
	return true;
//	NodeTree.RemoveNode(Placeable);
}

function TowerBlock GetBlockFromLocationAndDirection(out IVector GridLocation, out IVector ParentDirection)
{
	local Actor Block;
	local Vector StartLocation, EndLocation, HitNormal, HitLocation, VectorGridLocation;
	VectorGridLocation = ToVect(GridLocation);
	StartLocation = TowerGame(WorldInfo.Game).GridLocationToVector(VectorGridLocation);
	// The origin of blocks is on their bottom, so bump it up a bit so we're not on the edge.
	StartLocation.Z += 128;
	EndLocation.X = StartLocation.X + (ParentDirection.X * 512);
	EndLocation.Y = StartLocation.Y + (ParentDirection.Y * 512);
	EndLocation.Z = StartLocation.Z + (ParentDirection.Z * 512);
	//StartLocation.X += abs(ParentDirection.X * 128);
	//StartLocation.Y += abs(ParentDirection.Y * 128);
	//StartLocation.Z += abs(ParentDirection.Z * 128);
//	`log("Tracing From:"@StartLocation@"To:"@EndLocation@"ParentDirection:"@ParentDirection);
	Block = NodeTree.Root.Trace(HitLocation, HitNormal, EndLocation, StartLocation, TRUE);
//	`log(Block);
	return TowerBlock(Block);
}

function bool CheckForParent(TowerBlock Block)
{
	if(Block.GetParent() != None)
	{
		// You already have a parent.
		return true;
	}
	return NodeTree.FindNewParent(Block);
}

function CheckBlockSupport()
{
	// Toggling between PHYS_None and PHYS_RigidBody is not a solution at all, the physics simulation keeps going.
}

function FindBlock()
{

}

DefaultProperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	bStatic=False
	bNoDelete=False
}