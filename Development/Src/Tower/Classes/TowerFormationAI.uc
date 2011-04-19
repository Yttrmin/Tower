class TowerFormationAI extends UDKSquadAI;

var TowerEnemyController SquadLeader;

function Initialized()
{
	local TowerEnemyController Controller;
	SquadLeader.GotoState('Leading');
	for(Controller = SquadLeader.NextSquadMember; Controller != None; Controller = Controller.NextSquadMember)
	{
		Controller.GotoState('Following');
	}
}