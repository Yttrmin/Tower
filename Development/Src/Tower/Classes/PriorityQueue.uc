class PriorityQueue extends Object;

var private array<Object> Heap;
var private delegate<PriorityComparator> Comparator;

delegate int PriorityComparator(out Object A, out Object B);

function Initialize(delegate<PriorityComparator> ObjectComparator)
{
	Comparator = ObjectComparator;
}

function AddItem(out Object Object);

function RemoveItem(out Object Object);

function int Length()
{
	return Heap.Length;
}

function Object Peek();

function Object Pop();