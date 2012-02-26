class PathInfo extends Object within TowerAStarComponent
	dependson(TowerAStarComponent);

var privatewrite int PathID;
var privatewrite TowerBlock Start, Finish;
var privatewrite SearchResult Result;
var TowerAIObjective ObjectiveRoot;

var int Iteration;
var PriorityQueue OpenList;
var array<TowerBlock> ClosedList;

var privatewrite int PathRules;

public static final function PathInfo CreateNewPathInfo(const int NewPathID, const TowerBlock NewStart,
	const TowerBlock NewFinish, const out int NewPathRules, const TowerAStarComponent AStar)
{
	local PathInfo Path;
	Path = new(AStar) class'PathInfo';

	Path.PathID = NewPathID;
	Path.Start = NewStart;
	Path.Finish = NewFinish;
	Path.OpenList = new class'PriorityQueue';
	Path.PathRules = NewPathRules;

	return Path;
}

public function DebugDrawPath()
{
	local TowerAIObjective O;

	for(O = ObjectiveRoot.NextObjective; O.Target != Finish; O = O.NextObjective)
	{
		O.DrawDebugBox(O.Location, Vect(80, 80, 80), 255, 0, 255, false);
		O.DrawDebugString(Vect(0,0,32), O.Type, O, , 0.01);
	}
}