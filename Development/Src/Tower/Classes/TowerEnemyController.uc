class TowerEnemyController extends UDKBot;

/** Marker that indicates this unit's location in the formation. Centered around the leader.
Leader does not have a marker. */
var TowerFormationMarker Marker;
var TowerEnemyController NextSquadMember;

// Squad leader's state.
state Leading
{
Begin:

};

// Other squad members' state.
state Following
{

};

function SetSquad(TowerFormationAI NewSquad)
{
	Squad = NewSquad;
}