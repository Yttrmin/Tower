/**
TowerFactionAIStar

A TowerFactionAI that uses data from the Hivemind to do an A* search and find the best route to the root.
Infantry can only climb one block high at once! Keep this in mind!

Some cases I'd like to see work:
1) Root with tons on blocks on its own Z level but none above it. AI will trace through air blocks for the cheapest
path to Root.

--P----------- <-
R| | | | | | |  P


--
*/
class TowerFactionAIAStar extends TowerFactionAI
	config(Tower);

var TowerAStarComponent AStarComponent;
var array<TowerAIObjective> Paths;
var TowerBlock DebugStart, DebugFinish;
var bool bDrewPath;
var bool bDrawNames;

/** After every IterationsPerTick amount of iterations, save the state of the search and continue next tick. */
var config bool bDeferSearching;
/** Enables the ability to step through a search. Overrides IterationsPerTick and bDeferSearching! */
var config bool bStepSearch;
/** Draws debug information on the HUD about our current step. */
var config bool bDrawStepInfo;
/** How many iterations to do before deferring to the next tick. */
var config int IterationsPerTick;
//=============================================================================
// Deferred search variables.
/** Are we currently deferring to next tick? */
var private bool bDeferred;
/** Is the search done but we're deferring anyways? Used so the final step is of the finished path. */
var private bool bDeferredDone;
/** To step or not. Used when step searching. */
var private bool bStep;
/** A copy of the OpenList and ClosedList before deferring. */
var private array<TowerBlock> DeferredOpenList, DeferredClosedList;
/** Reference to the best block before deferring. */
var private TowerBlock StepBestBlock;
/** Used to represent the different nodes when stepping. */
var private array<TowerAIObjective> StepMarkers;

var private int DesiredPath;


event PostBeginPlay()
{
	Super.PostBeginPlay();
	AStarComponent.Initialize(OnPathGenerated, bDeferSearching, IterationsPerTick, bStepSearch, bDrawStepInfo);
	/*
	IterationsPerTick = Clamp(IterationsPerTick, 0, MaxInt);
	if(bStepSearch)
	{
		bDeferSearching = true;
		IterationsPerTick = 1;
	}
	AStarComponent.bStepSearch = bStepSearch;
	AStarComponent.bDeferSearching = bDeferSearching;
	AStarComponent.IterationsPerTick = IterationsPertick;
	AStarComponent.bDrawStepInfo = bDrawStepInfo;
	AStarComponent.AddOnPathGeneratedDelegate(OnPathGenerated);
	*/
}

// Called when all human players have lost.
event OnGameOver()
{
	local TowerEnemyController Controller;
	foreach WorldInfo.AllControllers(class'TowerEnemyController', Controller)
	{
		if(Controller.Owner == Self)
		{
			Controller.GotoState('Celebrating');
		}
	}
}

auto state Inactive
{
	event RoundStarted(const int AwardedBudget)
	{
		Super.RoundStarted(AwardedBudget);
		Start();
	}
}

final function Step()
{
	AStarComponent.Step();
}

function Start()
{
	`log("Starting"@self);
	DesiredPath = AStarComponent.GeneratePath(GetStartingBlock(), Hivemind.RootBlock.Target);
}

final function GenerateObjectives()
{

}

event OnPathGenerated(const bool bSuccessful, const int PathID, TowerAIObjective Root)
{
	`warn(self@"ONPATHGENERATED CALLED OUTSIDE ACTIVE");
}

state Active
{
	event Think()
	{
		
	}

	event OnPathGenerated(const bool bSuccessful, const int PathID, TowerAIObjective Root)
	{
		`log("Path generated! GO GO GO!");
		SpawnFormation(0, SpawnPoints[0], AStarComponent.Paths[0]);
	}

	event RoundEnded()
	{
		AStarComponent.Clear();
		Super.RoundEnded();
	}
}

final function TowerBlockAir GetStartingBlock()
{
	local TowerBlock HitActor;
	local TowerBlockAir Start;
	local Vector HitLocation, HitNormal;
	local IVector DesiredGridLocation;
	HitActor = TowerBlock(Trace(HitLocation, HitNormal, Hivemind.RootBlock.Target.Location, 
		GetFactionLocationDirection()*8192, true));
	DesiredGridLocation = HitActor.GridLocation + GetFactionLocationDirection();
	foreach HitActor.BasedActors(class'TowerBlockAir', Start)
	{
		if(Start.GridLocation == DesiredGridLocation)
		{
			return Start;
		}
	}
	`warn("!!!!!!!!!!"@Self$"::GetStartingBlock() couldn't find a TowerBlockAir in a direction from HitActor!!!!!!!");
	return None;
}

final function DebugDrawNames(Canvas Canvas)
{
	local TowerBlock Block;
	local Vector BeginPoint;
	foreach DynamicActors(class'TowerBlock', Block)
	{
		BeginPoint = Canvas.Project(Block.Location+Vect(16,16,16));
		Canvas.SetPos(BeginPoint.X, BeginPoint.Y);
		Canvas.DrawText(Block.name);
	}
}

simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	AStarComponent.PostRenderFor(PC, Canvas, CameraPosition, CameraDir);
	if(!AStarComponent.bStepSearch || !AStarComponent.bDeferred)
	{
		Super.PostRenderFor(PC, Canvas, CameraPosition, CameraDir);
	}
	//@TODO - Move me somewhere appropriate.
	if(bDrawNames)
	{
		DebugDrawNames(Canvas);
	}
	
}

final function Vector GetFactionLocationDirection()
{
	switch(Faction)
	{
	case FL_PosX:
		return Vect(1,0,0);
	case FL_NegX:
		return Vect(-1,0,0);
	case FL_PosY:
		return Vect(0,1,0);
	case FL_NegY:
		return Vect(0,-1,0);
	default:
		`warn(Self@"has a FactionLocation unsupported for AIs!:"@Faction);
		return Vect(0,0,0);
	}
}

DefaultProperties
{
	Begin Object Class=TowerAStarComponent Name=AStar
	End Object
	Components.Add(AStar)
	AStarComponent=AStar


	bDebug=true
	bDrewPath=false
}