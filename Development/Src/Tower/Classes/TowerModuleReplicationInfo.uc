class TowerModuleReplicationInfo extends ReplicationInfo;

struct ModuleInfo
{
	var byte TranslationX, TranslationY, TranslationZ;
	var int ID;
};

struct InfoPacket
{
	var int Count;
	var int Checksum;
};

var array<TowerModule> Modules;

var repnotify InfoPacket Packet;
var TowerPlayerController PlayerOwner;

var int OldCount;
var int OldChecksum;

replication
{
	if(bNetDirty)
		Packet;
}

simulated event ReplicatedEvent(name VarName)
{
	Super.ReplicatedEvent(VarName);
	if(VarName == 'Packet')
	{
		`log("TMRI: New InfoPakcet received!");
		HandleNewInfoPacket();
	}
}

simulated function HandleNewInfoPacket()
{
	if(Packet.Count > OldCount && Packet.Checksum > OldChecksum)
	{
		// Module added.
		`log("TMRI: Detected module added.");
	}
	else if(Packet.Count < OldCount && Packet.Checksum < OldChecksum)
	{
		// Module removed.
	}
	else if(Packet.Count == OldCount && Packet.Checksum > OldChecksum)
	{
		// Module removed but another added before replicated.
	}
}

reliable server function QueryModuleInfo(int ModuleID)
{

}

reliable client function ReceiveModuleInfo(ModuleInfo Info)
{
	if(ModuleExist(Info.ID))
	{
		// Modify module.
	}
	else
	{
		// Spawn module
	}
}

simulated function bool ModuleExist(out int ID)
{
	return false;
}