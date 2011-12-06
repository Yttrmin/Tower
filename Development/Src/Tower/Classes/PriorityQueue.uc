/**
PriorityQueue

A specially designed priority queue for keeping TowerBlocks in sorted order from lowest to highest.
You could make this vaugely "generic" by replacing TowerBlock with Object, but then you can't support primitive types.
Since I have no intentions of using this anywhere but with A*, this is non-generic.
*/
class PriorityQueue extends Object;

var private array<TowerBlock> Heap;
var private TowerBlock SwapObj;

/** Returns a negative number, 0, or a positive number if A is <, ==, or > than B. */
//function int Compare(TowerBlock A, TowerBlock B)
`define Compare(A,B) (`A.Fitness - `B.Fitness)
/** Swaps the two elements of the array at the given indicies. */
//private final function Swap(out int A, out int B)
`define Swap(A,B) SwapObj=Heap[`A];Heap[`A] = Heap[`B];Heap[`B]=SwapObj;
/** Returns the parent of the given index! */
//private final function int GetParent(out int ChildIndex)
`define GetParent(A) (`A-1)/2
/** Fills Left and Right with Index's left and right children. */
//private final function GetChildren(const out int Index, out int Left, out int Right)
`define GetChildren(I,L,R) `L=(2*`I+1);`R=`L+1

final function Add(TowerBlock Object)
{
	Heap[Heap.Length] = Object;
	if(Heap.Length > 1)
	{
		PercolateUp(Heap.Length-1);
	}
}

final function TowerBlock Remove()
{
	local TowerBlock ToReturn;
	local int Zero, Max;
	if(Heap.Length > 0)
	{
		ToReturn = Heap[0];
		Heap[0] = none;
		if(Heap.Length > 1)
		{
			Zero = 0;
			Max = Heap.Length-1;
			`Swap(Zero, Max);
			Heap.Remove(Max, 1);
		}
		else
		{
			Heap.Remove(0, 1);
		}
		if(Heap.Length > 2)
		{
			PercolateDown(0);
		}
	}
	return ToReturn;
}

final function bool Contains(TowerBlock Object)
{
	return Heap.Find(Object) != INDEX_NONE;
}

final function AsArray(out array<TowerBlock> OutArray)
{
	OutArray = Heap;
}

private final function PercolateUp(int Index)
{
	local int Parent;
	Parent = `GetParent(Index);
	while(Parent >= 0 && `Compare(Heap[Parent], Heap[Index]) > 0)
	{
		`Swap(Parent, Index);
		Index = Parent;
		Parent = `GetParent(Index);
	}
}

private final function PercolateDown(int Index)
{
	local int LeftChild;
	local int RightChild;
	local int MinChild;
	while(true)
	{
		`GetChildren(Index, LeftChild, RightChild);
		if(LeftChild >= Heap.Length)
		{
			break;
		}
		// Using ternary operator here breaks compiler, don't do it.
		if(RightChild < Heap.Length && `Compare(Heap[LeftChild], Heap[RightChild]) > 0)
		{
			MinChild = RightChild;
		}
		else
		{
			MinChild = LeftChild;
		}
		if(`Compare(Heap[Index], Heap[MinChild]) > 0)
		{
			`Swap(Index, MinChild);
			Index = MinChild;
		}
		else
		{
			break;
		}
	}
}

final function int Length()
{
	return Heap.Length;
}

final function Dispose()
{
	Heap.Remove(0, Heap.Length);
}