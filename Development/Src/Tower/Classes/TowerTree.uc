class TowerTree extends Object
	config(Tower)
	dependson(TowerBlock)
	deprecated;

struct Chunk
{
	var TwoVectors Corners;
};

//@TODO - CONVERT ALLLLLL OF THIS RECURSION TO ITERATION!

var protectedwrite TowerBlock Root;
var array<TowerBlock> OrphanNodeRoots;

var config const bool bDebugDrawHierarchy;
var config const bool bDebugLogHierarchy;

var int NodeCount;

var private array<Chunk> Chunks;

/** Adds a node into the tree. The only time it's valid to have a None ParentNode is if there's no 
root node, in which case NewNode will become it. Returns TRUE if successfully added. */
final function bool AddNode(TowerBlock NewNode, optional TowerBlock ParentNode)
{
	if(ParentNode == None)
	{
		if(Root == None)
		{
			Root = NewNode;
			NodeCount++;
			return true;
		}
		else
		{
			`Log("Tried to add a new node with no parent when there's already a root node!"@NewNode@"at grid location:"@ToVect(NewNode.GridLocation));
			return false;
		}
	}
	NodeCount++;
	NewNode.SetBase(ParentNode);
	return true;
}

/** Removes a node from the tree. if bDeleteChildren is TRUE, all of NodeToRemove's children
will recursively get RemoveNode() called on them. */
//@TODO - Make this return a bool for success/failure?
final function RemoveNode(TowerBlock NodeToRemove, optional bool bDeleteChildren)
{
	local TowerBlock Node;
	local array<TowerBlock> BasedBlocks;
	/** Only TowerBlocks which have absolutely no base get OrphanedParent() called on them. Therefore, make sure
	our soon-to-be-orphans have no base! */
	foreach NodeToRemove.BasedActors(class'TowerBlock', Node)
	{
		BasedBlocks.AddItem(Node);
	}
	`log("Removing node:"@NodeToRemove$"...");
	NodeToRemove.Destroy();
	foreach BasedBlocks(Node)
	{
		`log("Getting children new parents...");
		/*
		if(bDeleteChildren)
		{
			RemoveNode(Node);
		}
		*/
		`log("Finding new parent for"@Node$", current parent:"@Node.Base);
		// Find a parent for each of our children and all their children down the tree.
		FindNewParent(Node, NodeToRemove, true);
	}
	NodeCount--;
	
	`log("Done. Destroying node:"@NodeToRemove);
}

final function TowerBlock GetRandomNode()
{
	return Root;
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
//	DrawDebugPoint(Canvas, CurrentNode.Location, MakeColor(0,0,255));
	foreach CurrentNode.BasedActors(class'TowerBlock', Node)
	{
//		`log("Drawing relationship between"@CurrentNode@"and"@Node$"...");
		BeginPoint = Canvas.Project(CurrentNode.Location);
		EndPoint = Canvas.Project(Node.Location);
		Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, EndPoint.X, EndPoint.Y, MakeColor(255, 0, 0));
		DrawDebugPoint(Canvas, Node.Location, MakeColor(255,0,0));
		//	`log("Telling my children to draw their relationship too...");
		DrawDebugRelationship(Canvas, Node);
//		Root.DrawDebugPoint(Node.Location, 400, MakeLinearColor(255,0,0,0), true);
	}
}

/** Helper function for DrawDebugRelationship. Very slow and only for debugging!*/
final function DrawDebugPoint(Canvas Canvas, Vector Center, Color DrawColor)
{
	local Vector BeginPoint;
	BeginPoint = Canvas.Project(Center);
	Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, BeginPoint.X+16, BeginPoint.Y, DrawColor);
	Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, BeginPoint.X-16, BeginPoint.Y, DrawColor);
	Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, BeginPoint.X, BeginPoint.Y+16, DrawColor);
	Canvas.Draw2DLine(BeginPoint.X, BeginPoint.Y, BeginPoint.X, BeginPoint.Y-16, DrawColor);
}

final function ReParentNode(TowerBlock Node, TowerBlock NewParentNode, bool bParentChainToChildren)
{
	Node.SetBase(NewParentNode);
	`log(Node@"My new base:"@Node.Base);
}

final function TowerBlock GetRootNode()
{
	return Root;
}

/** Tries to find any nodes physically adjacent to the given one. If TRUE, bChildrenFindParent will
have all this nodes' children (and their children and so forth) perform a FindNewParent as well.
PreviousNodes is used internally by the function, do not pass a variable in! */
final function bool FindNewParent(TowerBlock Node, optional TowerBlock OldParent=None,
	optional bool bChildrenFindParent=false)
{
	local TowerBlock Block;
	local TraceHitInfo HitInfo;
//	`log(Node@"Finding parent for node. Current parent:"@Node.Base);
//	Node.SetBase(None);
//	Node.FindBase();
//	`log("FindBase says:"@Node.Base);
	foreach Node.CollidingActors(class'TowerBlock', Block, 130, , true,,HitInfo)
	{
//		`log("Found Potential Parent:"@Block@HitInfo.HitComponent@HitInfo.HitComponent.class);
		if(OldParent != Block && TraceNodeToRoot(Block, OldParent) && Node != Block && !HitInfo.HitComponent.isA('TowerModule'))
		{
			ReparentNode(Node, Block, false);
			Node.Adopted();
//			`log("And it's good!");
			return TRUE;
		}
	}
	if(bChildrenFindParent)
	{
//		`log("Having children look for supported parents...");
		foreach Node.BasedActors(class'TowerBlock', Block)
		{
			FindNewParent(Block, OldParent, bChildrenFindParent);
		}
	}
	
	
	if(Node.Base == None && OldParent != None)
	{
//		`log("No parents available,"@Node@"is an orphan. Handle this.");
		// True orphan.
		OrphanNodeRoots.AddItem(Node);
		Node.OrphanedParent();
	}
	return false;
}

/** Recursive function that returns TRUE if there is a path to the root through parents, otherwise FALSE. 
OrphanParent is the node telling this node to trace for root. Since we know OrphanParent is an
we can immediately say its not a path to root if its someone's parent down the line. */
// This is surprisingly the most expensive function here!
private final function bool TraceNodeToRoot(TowerBlock Node, optional TowerBlock InvalidBase)
{
	// IBO and GBM both clocked out at 0.0250 ms. Virtually identical.
	return Node.IsBasedOn(Root) && !Node.IsBasedOn(InvalidBase);
}