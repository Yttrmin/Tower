class TowerEnemyController extends UDKBot;

/** Marker that indicates this unit's location in the formation. Centered around the leader.
Leader does not have a marker. */
var TowerFormationMarker Marker;
var TowerEnemyController NextSquadMember;

var Vector NextMoveLocation;
var Vector JumpVector; 

auto state Idle
{
Begin:
//	SetTickIsDisabled(true);
//	Pawn.SetTickIsDisabled(true);
};

function Rotator GetAdjustedAimFor( Weapon W, vector StartFireLoc )
{
	return Rotator(Normal(GetSquadObjective().Location - Pawn.Location));
}

final function Vector GetAimPoint(Actor Block)
{
	local Vector HitLocation, HitNormal, TraceEnd, Temp;
	TraceEnd = Block.Location;
	DrawDebugLine(Pawn.GetWeaponStartTraceLocation(), TraceEnd, 255, 0, 0, true);
	if(Pawn.Trace(HitLocation, HitNormal, TraceEnd, Pawn.GetWeaponStartTraceLocation()) == Block)
	{
//		`log(Self@"aiming for center!");
		return HitLocation;
	}
	// Bounds are slightly off of 128. Like 129.014~.
	TraceEnd += Vect(0,0,128);
	DrawDebugLine(Pawn.GetWeaponStartTraceLocation(), TraceEnd, 0, 255, 0, true);
	if(Pawn.Trace(HitLocation, HitNormal, TraceEnd, Pawn.GetWeaponStartTraceLocation()) == Block)
	{
//		`log(Self@"aiming for top-center!");
		return HitLocation;
	}
	Temp = Normal(Block.Location - Pawn.Location);
	Temp.Z = TraceEnd.Z;
	Temp *= 128;
	TraceEnd +=  Temp;
	DrawDebugLine(Pawn.GetWeaponStartTraceLocation(), TraceEnd, 0, 0, 255, true);
	if(Pawn.Trace(HitLocation, HitNormal, TraceEnd, Pawn.GetWeaponStartTraceLocation()) == Block)
	{
//		`log(Self@"aiming for top-away!");
		return HitLocation;
	}
	return Vect(0,0,0);
}

// Squad leader's state.
state Leading
{
	event EndState(Name NextStateName)
	{
		EndCheckFireTimer();
	}
Begin:
//	BeginCheckFireTimer();
//	`log(Self@"Trying to path to Squad.SquadObjective!"@Squad.SquadObjective,,'SLeader');
	Pawn.SetPhysics(PHYS_Walking);
	if(NavigationHandle.ActorReachable(Squad.SquadObjective))
	{
		`log("Moving straight towards it!"@GetSquadObjective().CompletionRadius-30@GetSquadObjective().GetGoalPoint());
		MoveTo(GetSquadObjective().GetGoalPoint(), GetSquadObjective().GetTargetActor(), GetSquadObjective().CompletionRadius-30);
//		Pawn.Acceleration = Vect(0,0,0);
	}
	else if(GeneratePathTo(GetSquadObjective(), GetSquadObjective().CompletionRadius))
	{
//		`log(Self@"Trying to generate a path!",,'SLeader');
		NavigationHandle.SetFinalDestination(Squad.SquadObjective.Location);
		NavigationHandle.DrawPathCache(,true);

		if(NavigationHandle.GetNextMoveLocation(NextMoveLocation, Pawn.GetCollisionRadius()))
		{
//			`log(Self@"Moving to NextMoveLocation!",,'SLeader');
			MoveTo(NextMoveLocation, Squad.SquadObjective);
		}
	}
	else
	{
		`log("Moving straight towards it IDLEs!"@GetSquadObjective().CompletionRadius-30);
		MoveTo(GetSquadObjective().GetGoalPoint(), GetSquadObjective().GetTargetActor(), GetSquadObjective().CompletionRadius-30);
//		`log(Self@"can't path at all! Idling!",,'SLeader');
//		GotoState('Idle');
	}
	`log(VSizeSq(GetSquadObjective().GetGoalPoint() - Pawn.Location)@"vs"@GetSquadObjective().CompletionRadius**2);
	if(VSizeSq(GetSquadObjective().GetGoalPoint() - Pawn.Location) <= GetSquadObjective().CompletionRadius**2)
	{
		`log(Self@"Close enough, do something!",,'SLeader');
		goto 'UpdateObjective';
	}
	goto 'Begin';
AtObjective:
UpdateObjective:
	if(GetSquadObjective().Completed(Squad))
	{
		switch(GetSquadObjective().Type)
		{
		case OT_ClimbUp:
			goto 'ToClimbUp';
		case OT_GoTo:
			goto 'ToGoTo';
		case OT_Destroy:
			goto 'ToDestroy';
		default:
			GotoState('Idle');
		}
	}
	else
	{
		GotoState('Idle');
	}
ToClimbUp:
	PushState('ClimbBlock', 'Begin');
	`log("JUMPED?!");
	goto 'Begin';
ToGoTo:
	goto 'Begin';
ToDestroy:
	BeginCheckFireTimer();
};

state ClimbBlock
{
Begin:
	`log(self@"climbing!");
	/*
	`log(Pawn.SuggestJumpVelocity(JumpVector, GetSquadObjective().Location, Pawn.Location, true));
	`log(JumpVector);
	if(JumpVector != Vect(0,0,0))
	{
		Pawn.Velocity = JumpVector;
		Pawn.SetPhysics(PHYS_Falling);
	}
	*/
	Pawn.DoJump(false);
	Sleep(0.75);
	PopState();
}

// Other squad members' state.
state Following
{
	//@TODO @BUG - What if going to LEader? 
	event EndState(Name NextStateName)
	{
		EndCheckFireTimer();
	}
Begin:
	BeginCheckFireTimer();
	Pawn.SetPhysics(PHYS_Walking);
	goto 'Move';
Move:
	MoveToward(Marker, GetSquadObjective().GetTargetActor());
	if(TowerFormationAI(Squad).SquadLeader.IsInState('Idle'))
	{
		GotoState('Idle');
	}
	goto 'Move';
};

//@TODO - Look at UTBot's celebration.
// Player lost, celebrate!
state Celebrating
{
Begin:
	AnimNodeSlot(Pawn.Mesh.FindAnimNode('FullBodySlot')).PlayCustomAnim('Taunt_FB_Pelvic_Thrust_A', 1.0, 0.2, 0.2, FALSE, TRUE);
	Sleep(3);
	goto 'Begin';
};

function BeginCheckFireTimer()
{
	SetTimer(1 + (Rand(-1) + Rand(1)), true, NameOf(CheckFiring));
}

function EndCheckFireTimer()
{
	ClearTimer('CheckFiring');
}

function PawnDied(Pawn inPawn)
{
	if(TowerFormationAI(Squad).SquadLeader == self)
	{
		if(NextSquadMember != None)
		{
			TransferLeadership(NextSquadMember);
		}
		else
		{
			Squad.Destroy();
			DebugCheckForOrphans();
		}
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
			`warn("Controller has no squad! Squad:"@Controller.Squad@"bDeleteMe:"@Controller.bDeleteMe@"Health:"@Controller.Pawn.Health);
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

final event bool GeneratePathTo(Actor Goal, optional float WithinDistance, optional bool bAllowPartialPath)
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

DefaultProperties
{
	
}