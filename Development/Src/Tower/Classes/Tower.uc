/** 
Tower

Represents a player's tower, which a player can only have one of. Tower's are essentially containers for TowerBlocks.
*/
class Tower extends Actor;

// Unordered array of TowerBlocks.
var array<TowerBlock> Blocks;
var string TowerName;
var TowerPlayerReplicationInfo OwnerPRI;

replication
{
	if(bNetDirty)
		TowerName, OwnerPRI;
}

function AddBlock(class<TowerBlock> BlockClass, Vector SpawnLocation, int XBlock, int YBlock, 
	int ZBlock, optional bool bRootBlock = false)
{
	local TowerBlock Block;
	local Vector GridLocation;
	GridLocation.X = XBlock;
	GridLocation.Y = YBlock;
	GridLocation.Z = ZBlock;
	Block = Spawn(BlockClass, self,, SpawnLocation);
	Block.Initialize(GridLocation, OwnerPRI, bRootBlock);
//	Block.Tower = self;
	Blocks.AddItem(Block);
}

function bool RemoveBlock(int BlockIndex)
{
	Blocks[BlockIndex].Destroy();
	Blocks.Remove(BlockIndex, 1);
	return true;
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