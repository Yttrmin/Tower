class PathInfo extends Object;

var privatewrite int PathID;
var privatewrite TowerBlock Start, Finish;
var TowerAIObjective ObjectiveRoot;

var int Iteration;
var PriorityQueue OpenList;
var array<TowerBlock> ClosedList;

public static final function PathInfo CreateNewPathInfo(const int NewPathID, const TowerBlock NewStart,
	const TowerBlock NewFinish)
{
	local PathInfo Path;
	Path = new class'PathInfo';

	Path.PathID = NewPathID;
	Path.Start = NewStart;
	Path.Finish = NewFinish;
	Path.OpenList = new class'PriorityQueue';

	return Path;
}