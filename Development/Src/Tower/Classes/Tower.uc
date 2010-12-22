/** 
Tower

Represents a player's tower, which a player can only have one of. Tower's are essentially containers for TowerBlocks.
*/
class Tower extends Actor;

var TowerBlock Blocks[100];
var string TowerName;

replication
{
	if(bNetDirty)
		TowerName, Blocks;
}

function AddBlock(class<TowerBlock> BlockClass, int XBlock, int YBlock, int ZBlock)
{
	
}

DefaultProperties
{
	RemoteRole=ROLE_SimulatedProxy
}