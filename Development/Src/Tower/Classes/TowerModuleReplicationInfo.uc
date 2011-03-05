class TowerModuleReplicationInfo extends ReplicationInfo
	deprecated;

struct InfoPacket
{
	var int Count;
	var int Checksum;
};

var array<TowerModule> Modules;

var repnotify InfoPacket Packet;
var TowerPlayerReplicationInfo PlayerOwner;

// Only used by clients.
var int OldCount;
var int OldChecksum;

// Only used by server.
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

/** Simple wrapper function to handle adding a Module to the array and modifying the neccessary values.
Only executed on clients. */
simulated function AddModule(TowerModule Module)
{
	Modules.AddItem(Module);
	OldCount = Packet.Count;
	OldChecksum = Packet.Checksum;
	NextModuleID++;
}

/** Simple wrapper function to handle removing a Module from the array and modifying the neccessary values.
Only executed on clients. */
simulated function RemoveModule(int Index)
{
	Modules[Index].Owner.DetachComponent(Modules[Index]);
	Modules.Remove(Index, 1);
	OldCount = Packet.Count;
	OldChecksum = Packet.Checksum;
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

/** Compares Packet to our previous Checksum and Count to determine what's changed, and makes the neccessary modifications
to synchronize ourself with the packet.
Only executed on clients. */
simulated function HandleNewInfoPacket()
{
	local int i, ChangedID;
	local TowerModule Module;
	if(Packet.Count > OldCount && Packet.Checksum > OldChecksum)
	{
		// Module added.
		`log("TMRI: Detected"@Packet.Count-OldCount@"module added.");
		for(i = Packet.Count - OldCount; i > 0; i--)
		{
			`log("Querying for module"@Packet.Checksum - OldChecksum);
			PlayerOwner.QueryModuleInfo(Packet.Checksum - OldChecksum);
		}
	}
	else if(Packet.Count < OldCount && Packet.Checksum < OldChecksum)
	{
		// Module removed.
		`log("TMRI: Detected module removed.");
		ChangedID = OldChecksum - Packet.Checksum;
		foreach Modules(Module, i)
		{
			if(Module.ID == ChangedID)
			{
				`log("Found removed module, removing!");
				RemoveModule(i);
			}
		}
	}
	else if(Packet.Count == OldCount && Packet.Checksum > OldChecksum)
	{
		// Module removed but another added before replicated.
		`log("TMRI: Detected module replaced. Hopefully shouldn't really happen?");
	}
	else if(Packet.Count == OldCount && Packet.Checksum == OldChecksum)
	{
		`log("TMRI: Replicated a Packet with identical data to our own? I think we messed up our values!");
	}
	else
	{
		`log("TMRI: Unknown packet scenario. Packet.Count:"@Packet.Count@"OldCount:"@OldCount@"Packet.Checksum:"@Packet.Checksum@
			"OldChecksum:"@OldChecksum);
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