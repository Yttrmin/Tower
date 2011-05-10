class TowerEnemyController extends UDKBot;

/** Marker that indicates this unit's location in the formation. Centered around the leader.
Leader does not have a marker. */
var TowerFormationMarker Marker;
var TowerEnemyController NextSquadMember;

var Vector NextMoveLocation;

auto state Idle
{

};

// Squad leader's state.
state Leading
{
Begin:
	`log("Trying to path to Squad.SquadObjective!"@Squad.SquadObjective);
	Pawn.SetPhysics(PHYS_Walking);
	if(NavigationHandle.ActorReachable(Squad.SquadObjective))
	{
		`log("Moving straight towards it!");
		MoveToward(Squad.SquadObjective, Squad.SquadObjective);
	}
	else if(GeneratePathTo(Squad.SquadObjective, 500))
	{
		`log("Trying to generate a path!");
		NavigationHandle.SetFinalDestination(Squad.SquadObjective.Location);
		NavigationHandle.DrawPathCache(,true);

		if(NavigationHandle.GetNextMoveLocation(NextMoveLocation, Pawn.GetCollisionRadius()))
		{
			`log("Moving to NextMoveLocation!");
			MoveTo(NextMoveLocation, Squad.SquadObjective);
		}
	}
	else
	{
		`log(Self@"can't path at all! Idling!");
		GotoState('Idle');
	}
};

// Other squad members' state.
state Following
{
Begin:
	MoveToward(Marker, Squad.SquadObjective);
	goto 'Begin';
};

event bool GeneratePathTo(Actor Goal, optional float WithinDistance, optional bool bAllowPartialPath)
{
	if(NavigationHandle == None)
	{
		return FALSE;
	}
   
//	AddBasePathConstraints(false);
   
	class'NavMeshPath_Toward'.static.TowardGoal( NavigationHandle, Goal );
	class'NavMeshGoal_At'.static.AtActor( NavigationHandle, Goal, WithinDistance, bAllowPartialPath );
	return NavigationHandle.FindPath();
}

function SetSquad(TowerFormationAI NewSquad)
{
	Squad = NewSquad;
}