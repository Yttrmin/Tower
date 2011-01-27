class TowerTree extends Object
	dependson(TowerBlock);

var protectedwrite TowerBlock Root;
var private array<TowerBlock> OrphanNodeRoots;

final function RemoveNode(TowerBlock NodeToRemove, optional bool bDeleteChildren)
{
	// Try to find parent for children, if not, they fall onto another one.
	local TowerBlock Node;
	local array<TowerBlock> RemovedNodeChildren;
	RemovedNodeChildren = NodeToRemove.NextNodes;
	`log("Removing node:"@NodeToRemove$"...");
	NodeToRemove.PreviousNode.NextNodes.RemoveItem(NodeToRemove);
	// If we don't destroy the node before finding parents for its children, they'll end up tracing
	// into their to-be-destroyed parent, adding themselves back to their parent, getting told to
	// find a new parent, and so forth, an infinite loop.
	NodeToRemove.Destroy();
	foreach RemovedNodeChildren(Node)
	{
		Node.PreviousNode = None;
		`log("Getting children new parents...");
		if(bDeleteChildren)
		{
			RemoveNode(Node);
		}
		else
		{
			`log("Finding new parent for"@Node$"...");
			// This should iterate through the children's children as well perhaps? Is it possible
			// for a child further down the chain to potentially have an available parent?
			FindNewParent(Node, true);
		}
	}
	`log("Done. Destroying node:"@NodeToRemove);
	`log("Logging hierarchy...");
	DebugLogHierarchy(Root);
}

/** Called from TowerHUD, recursively draws lines and points, illustrating the hierarchy.
This is very slow and purely for debugging!*/
final function DrawDebugRelationship(out Canvas Canvas, TowerBlock CurrentNode)
{
	local Vector BeginPoint, EndPoint;
	local TowerBlock Node;
	// Don't know why this could be None, but who cares its a debug function, just return.
	if(Canvas == None)
	{
		return;
	}
//	`log("I am"@CurrentNode@"and I'm drawing the lines and squares to my children");
//	DrawDebugSquare(Canvas, CurrentNode.Location, MakeColor(0,0,255));
	foreach CurrentNode.NextNodes(Node)
	{
//		`log("Drawing relationship between"@CurrentNode@"and"@Node$"...");
		BeginPoint = Canvas.Project(CurrentNode.Location);
		EndPoint = Canvas.Project(Node.Location);
		Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, EndPoint.X, EndPoint.Y, MakeColor(255, 0, 0));
		DrawDebugSquare(Canvas, Node.Location, MakeColor(255,0,0));
		if(Node.NextNodes.Length > 0)
		{
		//	`log("Telling my children to draw their relationship too...");
			DrawDebugRelationship(Canvas, Node);
		}
//		Root.DrawDebugPoint(Node.Location, 400, MakeLinearColor(255,0,0,0), true);
	}
}

/** Helper function for DrawDebugRelationship. Very slow and only for debugging!*/
final function DrawDebugSquare(Canvas Canvas, Vector Center, Color DrawColor)
{
	local Vector BeginPoint;
	BeginPoint = Canvas.Project(Center);
	Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, BeginPoint.X+16, BeginPoint.Y, DrawColor);
	Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, BeginPoint.X-16, BeginPoint.Y, DrawColor);
	Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, BeginPoint.X, BeginPoint.Y+16, DrawColor);
	Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, BeginPoint.X, BeginPoint.Y-16, DrawColor);
}

final function DebugLogHierarchy(TowerBlock StartingNode)
{
	local TowerBlock Node;
	local String LogString;
	LogString = StartingNode@"has"@StartingNode.NextNodes.length@"children:";
	foreach StartingNode.NextNodes(Node)
	{
		LogString @= Node;
	}
	`log(LogString);
	foreach StartingNode.NextNodes(Node)
	{
		DebugLogHierarchy(Node);
	}
}

final function bool AddNode(TowerBlock NewNode, optional TowerBlock ParentNode)
{
	if(ParentNode == None)
	{
		if(Root == None)
		{
			Root = NewNode;
			return true;
		}
		else
		{
			`Log("Tried to add a new node with no parent when there's already a root node!"@NewNode@"at grid location:"@NewNode.GridLocation);
			return false;
		}
	}
	ParentNode.NextNodes.AddItem(NewNode);
	NewNode.PreviousNode = ParentNode;
	return true;
}

final function ReParentNode(TowerBlock Node, TowerBlock NewParentNode, bool bParentChainToChildren)
{
	local int i;
	local array<TowerBlock> ParentChain;
	local TowerBlock Block;
	if(bParentChainToChildren)
	{
		Block = Node;
		// Fill the array with all parent nodes.
		ParentChain.AddItem(Node);
		while(Block.PreviousNode != None)
		{
			ParentChain.AddItem(Block.PreviousNode);
			Block = Block.PreviousNode;
		}
		for(i = 1; i < ParentChain.length; i++)
		{
			ParentChain[i].NextNodes.RemoveItem(ParentChain[i-1]);
			// The last node has no children, and this would cause an out-of-bounds access.
			if(i > ParentChain.length-2)
			{
				ParentChain[i].NextNodes.AddItem(ParentChain[i+1]);
			}
			// This is now the bottom-most part of this branch, make sure it has no children.
			if(i == ParentChain.length-1)
			{
				ParentChain[i].NextNodes.Remove(0, ParentChain[i].NextNodes.Length);
			}
			else
			{
				ParentChain[i].NextNodes.Remove(0, ParentChain[i].NextNodes.Length);
			}
			ParentChain[i].PreviousNode = ParentChain[i-1];
		}
		for(i = 0; i < ParentChain.length-1; i++)
		{
			ParentChain[i].NextNodes.AddItem(ParentChain[i+1]);
		}
	}
	NewParentNode.NextNodes.AddItem(Node);
	Node.PreviousNode = NewParentNode;
}

final function TowerBlock GetRootNode()
{
	return Root;
}

//HasSupport

/** Tries to find any nodes physically adjacent to the given one. If TRUE, bChildrenFindParent will
have all this nodes' children (and their children and so forth) perform a FindNewParent as well.
PreviousNodes is used internally by the function, do not pass a variable in! */
final function bool FindNewParent(TowerBlock Node, optional bool bChildrenFindParent, 
	optional out array<TowerBlock> PreviousNodes)
{
	local TowerBlock Block;
	local array<TowerBlock> SupportNodes;
	`log(Node@"Finding parent for node.");
	GetFullSupport(Node, SupportNodes);
	`log("Node has"@SupportNodes.length@"potential blocks for support:");
	//@DELETEME
	foreach SupportNodes(Block)
	{
		`log(Block);
	}
	foreach SupportNodes(Block)
	{
		// Our previous parent can still exist which we know must be an orphan, so skip it.
		if(Node.PreviousNode != Block && TraceNodeToRoot(Block, Node))
		{
			`log("Found path to root, parenting with node.");
			ReParentNode(Node, Block, true);
			return true;
		}
		else
		{
			`log("Could not find path to root.");
		}
	}
	if(bChildrenFindParent)
	{
		`log("Having children look for supported parents...");
		foreach Node.NextNodes(Block)
		{
			FindNewParent(Block, bChildrenFindParent, PreviousNodes);
		}
	}
	`log("No parents available,"@Node@"is an orphan. Handle this.");
	return false;
}

/** Recursive function that returns TRUE if there is a path to the root through parents, otherwise FALSE. 
OrphanParent is the node telling this node to trace for root. Since we know OrphanParent is an
we can immediately say its not a path to root if its someone's parent down the line.. */
final function bool TraceNodeToRoot(TowerBlock Node, out TowerBlock OrphanParent)
{
	`log("Tracing to root. I'm"@Node$", my parent is"@Node.PreviousNode);
	if(Node.PreviousNode == OrphanParent)
	{
		`log("I know my parent is an orphan, no path to root.");
		return false;
	}
	else if(Node.PreviousNode.bRootBlock || Node.bRootBlock)
	{
		return true;
	}
	// Not root and has no parent, won't get us to root.
	else if(Node.PreviousNode == None)
	{
		return false;
	}
	else
	{
		return TraceNodeToRoot(Node.PreviousNode, OrphanParent);
	}
	
}

/** Populates given array with all nodes that can possibly support it. */
final function GetFullSupport(TowerBlock NodeToCheck, out array<TowerBlock> SupportNodes)
{
	local Vector HitLocation, HitNormal;
	local Vector TraceEnd;
	local TowerBlock HitBlock;

	TraceEnd = NodeToCheck.Location;
	TraceEnd.X += 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

	TraceEnd = NodeToCheck.Location;
	TraceEnd.X -= 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

	TraceEnd = NodeToCheck.Location;
	TraceEnd.Y += 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

	TraceEnd = NodeToCheck.Location;
	TraceEnd.Y -= 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

	TraceEnd = NodeToCheck.Location;
	TraceEnd.Z += 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

	TraceEnd = NodeToCheck.Location;
	TraceEnd.Z -= 256;
	HitBlock = TowerBlock(NodeToCheck.Trace(HitLocation, HitNormal, TraceEnd, NodeToCheck.Location, true));
	if(HitBlock != None)
	{
		SupportNodes.AddItem(HitBlock);
	}

}