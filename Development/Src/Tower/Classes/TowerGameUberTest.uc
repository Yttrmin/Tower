/** Checks parts of the gamestate to see it matches the rules. Very brute-force. Slow and has potential to crash if 
there are lots of blocks. */
class TowerGameUberTest extends Actor;

var TowerGame Game;
var int i, TotalErrorCount, LocalErrorCount, Iteration;
var float Duration;
// NEVER MODIFY THIS, USED INTERNALLY BY DebugDecrementIVector!
var byte bHitExtent;
var IVector Extent, NegativeExtent;
var IVector TestGridLocation;
var TowerBlock Block;
// Faster than DynamicActors.
var array<TowerBlock> AllBlocks;
var array<TowerBlock> OccupyingSpace;
// X, Y, Z.
var TowerBlock PosMost[3], NegMost[3];

function Start(TowerGame TowerGame)
{
	Game = TowerGame;
	GotoState('UberTest');
}

function DebugStartRecursionTest()
{
	GotoState('RecursionTest');
}

state RecursionTest
{
Begin:
	while(true)
	{
		if(!bool(i%125000))
		{
			`log(i,,'Iteration');
			Sleep(0);
		}
		i++;
		Goto 'Begin';
	}
}

/*
if(!bool(Iteration%125000)){Sleep(0);}
Iteration++;
*/

state UberTest
{
Begin:
	`log("=============================================================================",,'UberTest');
	`log("Starting DebugUberBlockTest! Calculating extent...",,'UberTest');
	Clock(Duration);
	`log("=============================================================================",,'UberTest');
	for(i = 0; i < 3; i++)
	{
		if(!bool(Iteration%125000)){Sleep(0);}
		Iteration++;
		PosMost[i] = TowerPlayerController(GetALocalPlayerController()).GetTower().Root;
		NegMost[i] = TowerPlayerController(GetALocalPlayerController()).GetTower().Root;
	}
	Sleep(0);
	foreach DynamicActors(class'TowerBlock', Block)
	{
		AllBlocks.AddItem(Block);
		// Check if it's the farthest on any positive axis.
		if(Block.GridLocation.X > PosMost[0].GridLocation.X)
		{
			PosMost[0] = Block;
		}
		if(Block.GridLocation.Y > PosMost[1].GridLocation.Y)
		{
			PosMost[1] = Block;
		}
		if(Block.GridLocation.Z > PosMost[2].GridLocation.Z)
		{
			PosMost[2] = Block;
		}

		// Check if it's the farthest on any negative axis.
		if(Block.GridLocation.X < NegMost[0].GridLocation.X)
		{
			NegMost[0] = Block;
		}
		if(Block.GridLocation.Y < NegMost[1].GridLocation.Y)
		{
			NegMost[1] = Block;
		}
		if(Block.GridLocation.Z < NegMost[2].GridLocation.Z)
		{
			NegMost[2] = Block;
		}
	}
	//===================================================
	// Calculate extent.
	if(Abs(PosMost[0].GridLocation.X) > Abs(NegMost[0].GridLocation.X))
	{
		Extent.X = PosMost[0].GridLocation.X;
	}
	else if(Abs(PosMost[0].GridLocation.X) < Abs(NegMost[0].GridLocation.X))
	{
		Extent.X = NegMost[0].GridLocation.X;
	}
	else
	{
		Extent.X = NegMost[0].GridLocation.X;
	}

	if(Abs(PosMost[1].GridLocation.Y) > Abs(NegMost[1].GridLocation.Y))
	{
		Extent.Y = PosMost[1].GridLocation.Y;
	}
	else if(Abs(PosMost[1].GridLocation.Y) < Abs(NegMost[1].GridLocation.Y))
	{
		Extent.Y = NegMost[1].GridLocation.Y;
	}
	else
	{
		Extent.Y = NegMost[1].GridLocation.Y;
	}

	if(Abs(PosMost[2].GridLocation.Z) > Abs(NegMost[2].GridLocation.Z))
	{
		Extent.Z = PosMost[2].GridLocation.Z;
	}
	else if(Abs(PosMost[2].GridLocation.Z) < Abs(NegMost[2].GridLocation.Z))
	{
		Extent.Z = NegMost[2].GridLocation.Z;
	}
	else
	{
		Extent.Z = NegMost[2].GridLocation.Z;
	}
	NegativeExtent = -Extent;
	i = (Abs(Extent.X)*2+1) * (Abs(Extent.Y)*2+1) * (Abs(Extent.Z)*2+1);
	`log("Extent is:"@Extent.X$","@Extent.Y$","@Extent.Z,,'UberTest');
	i = 0;
	//===================================================
	// COMMENCE CHECKING
	TestGridLocation = Extent;
	`log("-----------------------------------------------------------------------------",,'UberTest');
	`log("Testing multiple blocks in same location...",,'UberTest');
	Goto 'MultipleBlockTest';
MultipleBlockTest:
	OccupyingSpace.Remove(0, OccupyingSpace.Length);
//		`log("("$TestGridLocation.X$","@TestGridLocation.Y$","@TestGridLocation.Z$")");
	foreach AllBlocks(Block)
	{
		if(Block.GridLocation == TestGridLocation)
		{
			OccupyingSpace.AddItem(Block);
		}
	}
	if(OccupyingSpace.Length > 1)
	{
		LocalErrorCount++;
		`log(OccupyingSpace.Length@"blocks occupying"@"("$TestGridLocation.X$","@TestGridLocation.Y$","@TestGridLocation.Z$")!:",,'Error');
		foreach OccupyingSpace(Block)
		{
			`log("     "$Block,,'Error');
		}
	}
	if(!bool(Iteration%1000)){Sleep(0);}
	Iteration++;
	if(!DebugDecrementIVector(TestGridLocation, NegativeExtent, bHitExtent))
	{
		Goto 'PostMultipleBlockTest';
	}
	else
	{
		Goto 'MultipleBlockTest';
	}
PostMultipleBlockTest:
	if(LocalErrorCount == 0)
	{
		`log("...OK!",,'UberTest');
	}
	TotalErrorCount += LocalErrorCount;
	LocalErrorCount = 0;
	`log("-----------------------------------------------------------------------------",,'UberTest');
	`log("-----------------------------------------------------------------------------",,'UberTest');
	`log("Testing blocks with no parents, yet not in UnstableParent (exclude TowerBlockRoots)...",,'UberTest');
	Goto 'NoParentBlockTest';
NoParentBlockTest:
	Sleep(0);
	foreach AllBlocks(Block)
	{
		if(Block.Base == None && !Block.IsInState('UnstableParent') && !Block.IsA('TowerBlockRoot'))
		{
			LocalErrorCount++;
			`log(Block@"at"@"("$Block.GridLocation.X$","@Block.GridLocation.Y$","@Block.GridLocation.Z$") fails!",,'Error');
		}
	}
	if(LocalErrorCount == 0)
	{
		`log("...OK!",,'UberTest');
	}
	TotalErrorCount += LocalErrorCount;
	LocalErrorCount = 0;
	`log("-----------------------------------------------------------------------------",,'UberTest');
	Goto 'Done';
Done:
	`log("=============================================================================",,'UberTest');
	UnClock(Duration);
	`log("DebugUberBlockTest over! Errors:"@TotalErrorCount@"Test Duration:"@Duration@"ms!",,'UberTest');
	`log("=============================================================================",,'UberTest');
	Destroy();
}

/** Moves ToDecrement closer to its opposite extent. Returns TRUE if it can still be decremented, or FALSE if its equal
to its opposite extent (and thus has traversed its whole extent). NEVER MODIFY bHitExtent, IT'S USED INTERNALLY!
Easier to describe with example:

ToDecrement = (1, -1, 1), Extent = (1, -1, 1)
1. (1, -1, 0) - ALL RETURN TRUE.
2. (1, -1, -1)

3. (1, 0, 1)
4. (1, 0, 0)
5. (1, 0, -1)

6. (1, 1, 1)
7. (1, 1, 0)
8. (1, 1, -1)

9. (0, -1, 1)
...
?. (-1, 1, 0)
?. (-1, 1, -1) - RETURNS FALSE. */
public final function bool DebugDecrementIVector(out IVector ToDecrement, out const IVector AreaExtent, out byte bHitAreaExtent)
{
	if(bHitAreaExtent == 1)
	{
		return false;
	}
	// We absolutely need to decrement Z (or anything). But what if its 0?
	ToDecrement.Z < AreaExtent.Z ? ToDecrement.Z++ : ToDecrement.Z--;
	// If Z has reached its opposite AreaExtent, (MAYBE(?)) roll it back to the original and carry-over to Y.
	if(-AreaExtent.Z < AreaExtent.Z ? ToDecrement.Z > AreaExtent.Z : ToDecrement.Z < AreaExtent.Z)
	{
		// Decrement/increment Y however so it gets closer to -AreaExtent.Y.
		// If AreaExtent.Y is 0, we can't do anything with it so go to X.
		if(AreaExtent.Y != 0)
		{
			-AreaExtent.Y < AreaExtent.Y ? ToDecrement.Y++ : ToDecrement.Y--;
			// Since AreaExtent.Y is non-zero, we can roll Z over and carry over to Y.
			ToDecrement.Z = -AreaExtent.Z;
		}
		else if(AreaExtent.X != 0)
		{
			ToDecrement.X < AreaExtent.X ? ToDecrement.X++ : ToDecrement.X--;
			// Since AreaExtent.X is non-zero, we can roll Z over and carry over to X.
			ToDecrement.Z = -AreaExtent.Z;
		}
		else
		{
			// Can't change anything! Guess we're done!
			return true;
		}
	}
	if(-AreaExtent.Y < AreaExtent.Y ? ToDecrement.Y > AreaExtent.Y : ToDecrement.Y < AreaExtent.Y)
	{
		// Decrement/increment X however so it gets closer to -AreaExtent.X.
		// If AreaExtent.Y is 0, we can't do anything with it so go to X.
		if(AreaExtent.X != 0)
		{
			ToDecrement.X < AreaExtent.X ? ToDecrement.X++ : ToDecrement.X--;
			// Since AreaExtent.Y is non-zero, we can roll Y over and carry over to X.
			ToDecrement.Y = -AreaExtent.Y;
		}
		else
		{
			// Can't change anything! Guess we're done!
			return false;
		}
	}
	if(ToDecrement.X == AreaExtent.X)
	{
		// Uhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh.
		// Well X can't roll over right?
		// Because if it did then you'd like... Reset ToDecrement I guess...?
		// So do nothing?
	}
	if(ToDecrement == AreaExtent)
	{
		bHitAreaExtent = 1;
	}
	return true;
	/*
	else if(ToDecrement.Y == -AreaExtent.Y)
	{
		ToDecrement.Y = AreaExtent.Y;
//		ToDecrement.X--;
	}*/
}