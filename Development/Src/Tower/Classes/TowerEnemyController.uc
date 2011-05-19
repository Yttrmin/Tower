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
	SetTimer(1, true, 'CheckFiring');
//	`log("Trying to path to Squad.SquadObjective!"@Squad.SquadObjective);
	Pawn.SetPhysics(PHYS_Walking);
	if(NavigationHandle.ActorReachable(Squad.SquadObjective))
	{
//		`log("Moving straight towards it!");
		MoveToward(Squad.SquadObjective, GetSquadObjective().GetTargetActor(), 512);
//		Pawn.Acceleration = Vect(0,0,0);
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
	goto 'Begin';
};

// Other squad members' state.
state Following
{
Begin:
	SetTimer(1, true, 'CheckFiring');
	Pawn.SetPhysics(PHYS_Walking);
	MoveToward(Marker, GetSquadObjective().GetTargetActor());
	goto 'Begin';
};

function PawnDied(Pawn inPawn)
{
	if(TowerFormationAI(Squad).SquadLeader == self && NextSquadMember != None)
	{
		if(NextSquadMember != None)
		{
			TransferLeadership(NextSquadMember);
		}
	}
	else
	{
		Squad.Destroy();
		DebugCheckForOrphans();
	}
	if(Marker != None)
	{
		// Do we want to keep markers in case we allow units to join formation?
		Marker.Destroy();
		RemoveFromSquadList();
	}
	Super.PawnDied(inPawn);
}

//@DEBUG - Checks every TowerEnemyController to see if it has a squad. If not, we messed up somewhere!
function DebugCheckForOrphans()
{
	local TowerEnemyController Controller;
	foreach WorldInfo.AllControllers(class'TowerEnemyController', Controller)
	{
		if(Controller.Squad == None && !Controller.bDeleteMe && Controller.Pawn.Health > 0)
		{
			`log("Controller has no squad! Squad:"@Controller.Squad@"bDeleteMe:"@Controller.bDeleteMe@"Health:"@Controller.Pawn.Health);
		}
	}
}

function TransferLeadership(TowerEnemyController NewLeader)
{
	local TowerEnemyController Member;
	NewLeader.StopLatentExecution();
	NewLeader.Marker.Destroy();
	NewLeader.RemoveFromSquadList();
	TowerFormationAI(Squad).SquadLeader = NewLeader;
	for(Member = NewLeader.NextSquadMember; Member != None; Member = Member.NextSquadMember)
	{
		Member.Marker.SetBase(NewLeader.Pawn);
	}
	NewLeader.GotoState('Leading');
}

/** Removes self from the NextSquadMember linked list. */
function RemoveFromSquadList()
{
	local TowerEnemyController Controller;
	local bool bDone;
	for(Controller = TowerFormationAI(Squad).SquadLeader; !bDone && Controller != None; Controller = Controller.NextSquadMember)
	{
		if(Controller.NextSquadMember == self)
		{
			Controller.NextSquadMember = NextSquadMember;
			bDone = true;
		}
	}
}

event CheckFiring()
{
	Pawn.BotFire(false);
}

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

final function TowerAIObjective GetSquadObjective()
{
	return TowerAIObjective(Squad.SquadObjective);
}

function SetSquad(TowerFormationAI NewSquad)
{
	Squad = NewSquad;
}