/**
TowerCrowdSpawner

Takes the place of the Kismet node usually used to handle crowd spawning.
Most of this is straight-up taken from SeqAct_GameCrowdSpawner, but has the
advantage of not being a Kismet node.
*/
class TowerCrowdSpawner extends Object
	deprecated;

/** Set by kismet action inputs - controls whether we are actively spawning agents. */
var		bool	bSpawningActive;

/** Index of next destination to pick */
var int NextDestinationIndex;

/** Cached set of spawn locations. */
var	transient array<Actor>		SpawnLocs;

/** If true, the spawner will cycle through the spawn locations instead of spawning from a randomly chosen one */
var() bool  bCycleSpawnLocs;

/** Holds the last SpawnLoc index used */
var private transient int   LastSpawnLocIndex;

/** How many agents per second will be spawned at the target actor(s).  */
var()	float	SpawnRate;

/** The maximum number of agents alive at one time. If agents are destroyed, more will spawn to meet this number. */
var()	int		SpawnNum;

/** If TRUE, agents that are totally removed (ie blown up) are respawned */
var()	bool	bRespawnDeadAgents;

/** Radius around target actor(s) to spawn agents. */
var()	float	SpawnRadius;

/** Whether we have already done the number reduction */
var		bool	bHasReducedNumberDueToSplitScreen;

/** How much to reduce number by in splitscreen */
var()	float	SplitScreenNumReduction;

/** Used by spawning code to accumulate partial spawning */
var		float	Remainder;

/** Sum of agent types + frequency modifiers */
var float AgentFrequencySum;

/** List of Archetypes of agents for pop manager to spawn when this is toggled on */
var()	GameCrowd_ListOfAgents	CrowdAgentList;

/** Archetypes of agents spawned by this crowd spawner */
var transient array<AgentArchetypeInfo>	AgentArchetypes;

/** Used to keep track of currently spawned crowd members. */
var transient array<GameCrowdAgent> SpawnedList;

/** Lighting channels to put the agents in. */
var(Lighting)	LightingChannelContainer	AgentLightingChannel;

/** Whether to enable the light environment on crowd members. */
var(Lighting)	bool						bEnableCrowdLightEnvironment;

/** Used for replicating crowd inputs to clients. */
//var		GameCrowdReplicationActor		RepActor;

/** If true, force obstacle checking for all agents from this spawner */
var() bool bForceObstacleChecking;

/** If true, force nav mesh navigation for all agents from this spawner */
var() bool bForceNavMeshPathing;

/** If true, only spawn agents if player can't see spawn point */
var() bool bOnlySpawnHidden;

/** Average time to "warm up" spawned agents before letting them sleep if not rendered */
var() float AgentWarmupTime;

/** If true, and initial spawn positiong is not in player's line of sight, and agent is not part of a group,
  * agent will try to find an starting position at a random spot between the initial spawn positing and its initial destination
  * that isn't in the player's line of sight.
  */
var() bool bWarmupPosition;

/** Whether agents from this spawner should cast shadows */
var(Lighting)   bool    bCastShadows;

//*********************************************************************************************
// TOWER-SPECIFIC VARIABLES AND FUNCTIONS GO HERE.

var array<TowerCrowdDestinationSpawnable> Destinations;

event BlockSpawned(TowerBlock Block)
{
	local TowerCrowdDestinationSpawnable NewDestination;
	NewDestination = Block.Spawn(class'TowerCrowdDestinationSpawnable');
	Destinations.AddItem(NewDestination);
	`log("Spawned a TowerCrowdDestinationSpawnable!");
}
//*********************************************************************************************

/** Called when agent is spawned - sets agent output and triggers spawned event */
event SpawnedAgent(GameCrowdAgent NewAgent)
{
	// Probably want to iterate in the future.
	local TowerCrowdDestinationSpawnable Destination;
	Destination = Destinations[0];
	NewAgent.SetCurrentDestination(Destination);
}

/** Called from C++ to actually create a new CrowdAgent actor, and initialise it */
function GameCrowdAgent SpawnAgent(Actor SpawnLoc)
{
	local GameCrowdAgent	Agent;
	local float AgentPickValue, PickSum;
	local int i, PickedInfo;
	local GameCrowdAgent AgentTemplate;
	local GameCrowdGroup NewGroup;

	// pick agent class
	if ( AgentFrequencySum == 0.0 )
	{
		`log("AgentFrequencySum is 0!");
		if ( CrowdAgentList != None )
		{
			`log("Have a valid CrowdAgentList!");
			AgentArchetypes.Length = 0;
			// get agent archetypes to use from CrowdAgentList
			for (i=0; i<CrowdAgentList.ListOfAgents.Length; i++ )
			{
				AgentArchetypes[AgentArchetypes.Length] = CrowdAgentList.ListOfAgents[i];
				`log("Added an AgentArchetype!");
			}
		}

		// make sure initialized
		for ( i=0; i<AgentArchetypes.length; i++ )
		{
			if ( GameCrowdAgent(AgentArchetypes[i].AgentArchetype) != None )
			{
				AgentFrequencySum = AgentFrequencySum + FMax(0.0,AgentArchetypes[i].FrequencyModifier);
			}
		}
	}
	AgentPickValue = AgentFrequencySum * FRand();
	PickedInfo = -1;
	for ( i=0; i<AgentArchetypes.Length; i++ )
	{
		AgentTemplate = GameCrowdAgent(AgentArchetypes[i].AgentArchetype);
		if ( AgentTemplate != None )
		{
			PickSum = PickSum + FMax(0.0,AgentArchetypes[i].FrequencyModifier);
			if ( PickSum > AgentPickValue )
			{
				PickedInfo = i;
				break;
			}
		} 
	}	

	if ( PickedInfo == -1 )
	{
		`log("No valid archetype!");
		// failed to find valid archetype
		return None;
	}

	if ( AgentArchetypes[PickedInfo].GroupMembers.Length > 0 )
	{
		NewGroup = New(None) class'GameCrowdGroup';
	}
	Agent = CreateNewAgent(SpawnLoc, AgentTemplate, NewGroup);
	`log("Spawned an Agent!"@Agent);
	// notify kismet (fills "spawned agent" output variable, and triggers "agent spawned" event)
	SpawnedAgent(Agent);
	
	// spawn other agents in group
	for ( i=0; i<AgentArchetypes[PickedInfo].GroupMembers.Length; i++ )
	{
		if ( GameCrowdAgent(AgentArchetypes[PickedInfo].GroupMembers[i]) != None )
		{
			CreateNewAgent(SpawnLoc, GameCrowdAgent(AgentArchetypes[PickedInfo].GroupMembers[i]), NewGroup);
		}
	}
	return Agent;
}

function GameCrowdAgent CreateNewAgent(Actor SpawnLoc, GameCrowdAgent AgentTemplate, GameCrowdGroup NewGroup)
{
	local GameCrowdAgent	Agent;
	local rotator	SpawnRot;
	local vector	SpawnPos;
	
	// GameCrowdSpawnInterface provides spawn location (can be line/circle/volume/etc. based)
	if ( GameCrowdSpawnInterface(SpawnLoc) != None )
	{
		GameCrowdSpawnInterface(SpawnLoc).GetSpawnPosition(None, SpawnPos, SpawnRot);
	}
	else
	{
		// Circle spawn by default
		SpawnRot = RotRand(false);
		SpawnRot.Pitch = 0;
		SpawnPos = SpawnLoc.Location + ((vect(1,0,0) * FRand() * SpawnRadius) >> SpawnRot);
	}
	
	Agent = SpawnLoc.Spawn( AgentTemplate.Class,SpawnLoc,,SpawnPos,SpawnRot,AgentTemplate);

	Agent.SetLighting(bEnableCrowdLightEnvironment, AgentLightingChannel, bCastShadows);

	if ( bForceObstacleChecking )
	{
		Agent.bCheckForObstacles = true;
	}
	
	if ( bForceNavMeshPathing )
	{
		Agent.bUseNavMeshPathing = true;
	}
	
//	Agent.InitializeAgent(SpawnLoc, AgentTemplate, NewGroup, AgentWarmUpTime*2.0*FRand(), bWarmupPosition, true);
	SpawnedList[SpawnedList.Length] = Agent;
	return Agent;
}

DefaultProperties
{
	AgentArchetypes(0)=(AgentArchetype=TowerCrowdAgent'TowerMod.TestCrowdAgent',MaxAllowed=100)
	CrowdAgentList=GameCrowd_ListOfAgents'TowerMod.CrowdAgentList'

	SpawnRadius=200
	SpawnRate=10
	SpawnNum=100
	bRespawnDeadAgents=TRUE

	SplitScreenNumReduction=0.5
	
	bOnlySpawnHidden=true
	
	AgentWarmupTime=5.0
}