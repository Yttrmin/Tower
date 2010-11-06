class TowerGame extends UTGame;

enum Factions
{
	FA_Player
};

event PostBeginPlay()
{
	Super.PostBeginPlay();
}

event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local PlayerController NewPlayer;
	NewPlayer = super.Login(Portal, Options, UniqueID, ErrorMessage);
	//TowerPlayerController(NewPlayer).GotoState('Master');
	return NewPlayer;
}

function RestartPlayer(Controller aPlayer)
{
	`log("RESTARTED");
	`log(aPlayer.GetStateName());
	ScriptTrace();
	// aPlayer default state is PlayerWaiting
	// self default state is PendingMatch
	TowerPlayerController(aPlayer).GotoState('Master');
}

function AddInitialBots()
{
	local int AddCount;
	return;
	// add any bots immediately
	while (NeedPlayers() && AddBot() != None && AddCount < 16)
	{
		AddCount++;
	}
}

DefaultProperties
{
	MaxPlayersAllowed = 4
	PlayerControllerClass=class'Tower.TowerPlayerController'
	PlayerReplicationInfoClass=class'Tower.TowerPlayerReplicationInfo'
	GameReplicationInfoClass=class'Tower.TowerGameReplicationInfo'
	DefaultPawnClass=class'Tower.TowerPawn'
	bAutoNumBots = False
	DesiredPlayerCount = 1
}