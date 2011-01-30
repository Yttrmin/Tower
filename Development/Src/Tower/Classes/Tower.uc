/** 
Tower

Represents a player's tower, which a player can only have one of. Tower's are essentially containers for TowerBlocks.
*/
class Tower extends Actor;

var protectedwrite TowerTree NodeTree;

/** Array of existing blocks ONLY used to ease debugging purposes. This should never be used for any
non-debug in-game things ever!*/
var() private array<TowerBlock> DebugBlocks;

var() string TowerName;
var() TowerPlayerReplicationInfo OwnerPRI;

replication
{
	if(bNetDirty)
		TowerName, OwnerPRI;
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	NodeTree = new class'TowerTree';
}

function TowerBlock AddBlock(class<TowerBlock> BlockClass, TowerBlock ParentBlock, 
	Vector SpawnLocation, int XBlock, int YBlock, int ZBlock, optional bool bRootBlock = false)
{
	local TowerBlock Block;
	local Vector GridLocation;
	GridLocation.X = XBlock;
	GridLocation.Y = YBlock;
	GridLocation.Z = ZBlock;
	Block = Spawn(BlockClass, self,, SpawnLocation);
	Block.Initialize(GridLocation, OwnerPRI, bRootBlock);
	NodeTree.AddNode(Block, ParentBlock);
	//@DEBUG
	if(OwnerPRI.Tower.NodeTree.bDebugDrawHierarchy)
	{
		DebugBlocks.AddItem(Block);
		DrawDebugString(Vect(-128,-128,0), Block.Name, Block);
	}
	return Block;
	//@DEBUG
	/**
//	Block.Tower = self;
	Blocks.AddItem(Block);
	*/
}

function bool RemoveBlock(TowerBlock Block)
{
	local TowerBlock IterateBlock;
	DebugBlocks.RemoveItem(Block);
	NodeTree.RemoveNode(Block);
	//@DEBUG
	FlushDebugStrings();
	foreach DebugBlocks(IterateBlock)
	{
		DrawDebugString(Vect(-128,-128,0), IterateBlock.Name, IterateBlock);
	}
	//@DEBUG
	return true;
}

function bool CheckForParent(TowerBlock Block)
{
	if(Block.PreviousNode != None)
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
	bAlwaysRelevant = true;
	RemoteRole=ROLE_SimulatedProxy
}