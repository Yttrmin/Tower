class TowerModuleReplicationInfo extends ReplicationInfo;

struct ModuleInfo
{
	var Vector GridLocation;
	var int ModIndex, ModPlaceableIndex;
	var TowerBlock Parent;
	var int ID;
};

struct InfoPacket
{
	var int Count;
	var int Checksum;
};

var array<TowerModule> Modules;

var repnotify InfoPacket Packet;
var TowerPlayerReplicationInfo PlayerOwner;

var int OldCount;
var int OldChecksum;

var int NextModuleID;

replication
{
	if(bNetDirty)
		Packet;
}

simulated function ClientInitialize(TowerPlayerReplicationInfo TPRI)
{
	PlayerOwner = TPRI;
	HandleNewInfoPacket();
}

simulated function AddModule(TowerModule Module)
{
	Modules.AddItem(Module);
	OldCount = Packet.Count;
	OldChecksum = Packet.Checksum;
	NextModuleID++;
}

simulated event ReplicatedEvent(name VarName)
{
	Super.ReplicatedEvent(VarName);
	if(VarName == 'Packet')
	{
		`log("TMRI: New InfoPakcet received!");
		if(PlayerOwner != None)
		{
			HandleNewInfoPacket();
		}
	}
}

simulated function HandleNewInfoPacket()
{
	local int i, ChangedID;
	local TowerModule Module;
	if(Packet.Count > OldCount && Packet.Checksum > OldChecksum)
	{
		// Module added.
		`log("TMRI: Detected module added.");
		for(i = Packet.Count - OldCount; i > 0; i--)
		{
			`log("Querying for module"@OldCount+i);
			PlayerOwner.QueryModuleInfo(OldCount + i);
		}
	}
	else if(Packet.Count < OldCount && Packet.Checksum < OldChecksum)
	{
		ChangedID = OldChecksum - Packet.Checksum;
		foreach Modules(Module)
		{
			if(Module.ID == ChangedID)
			{

			}
		}
		`log("TMRI: Detected module removed.");
		// Module removed.
	}
	else if(Packet.Count == OldCount && Packet.Checksum > OldChecksum)
	{
		`log("TMRI: Detected module replaced. Hopefully shouldn't really happen?");
		// Module removed but another added before replicated.
	}
}

simulated function bool ModuleExist(out int ID)
{
	return false;
}

DefaultProperties
{
	NextModuleID = 1
}