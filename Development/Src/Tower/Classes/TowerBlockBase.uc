class TowerBlockBase extends Actor
	abstract;

var() const editinline MeshComponent MeshComponent;
var() const editconst DynamicLightEnvironmentComponent LightEnvironment;

/** Used to replicate mesh to clients */
var repnotify transient StaticMesh ReplicatedStaticMesh;
var repnotify transient SkeletalMesh ReplicatedSkeletalMesh;
/** used to replicate the materials in indices 0 and 1 */
var repnotify MaterialInterface ReplicatedMaterial0, ReplicatedMaterial1;
/** used to replicate StaticMeshComponent.bForceStaticDecals */
var repnotify bool bForceStaticDecals;

/** Extra component properties to replicate */
var repnotify vector ReplicatedMeshTranslation;
var repnotify rotator ReplicatedMeshRotation;
var repnotify vector ReplicatedMeshScale3D;

/** If a Pawn can be 'based' on this KActor. If not, they will 'bounce' off when they try to. */
var() bool	bPawnCanBaseOn;
/** Pawn can base on this KActor if it is asleep -- Pawn will disable KActor physics while based */
var() bool	bSafeBaseIfAsleep;

replication
{
	if(bNetDirty)
		ReplicatedStaticMesh, ReplicatedSkeletalMesh, ReplicatedMaterial0, ReplicatedMaterial1, 
		ReplicatedMeshTranslation, ReplicatedMeshRotation, ReplicatedMeshScale3D, bForceStaticDecals;
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	if(MeshComponent != none)
	{
		if(StaticMeshComponent(MeshComponent) != None)
		{
			ReplicatedStaticMesh = StaticMeshComponent(MeshComponent).StaticMesh;
			bForceStaticDecals = StaticMeshComponent(MeshComponent).bForceStaticDecals;
		}
		else if(SkeletalMeshComponent(MeshComponent) != None)
		{
			ReplicatedSkeletalMesh = SkeletalMeshComponent(MeshComponent).SkeletalMesh;
		}
		else if(ApexComponentBase(MeshComponent) != None)
		{
			`log(Self@"a"@Class@"of"@ObjectArchetype@"has a MeshComponent of class"@MeshComponent.class@
				", a subclass of ApexComponentBase. ApexComponentBase-derived MeshComponents are not yet supported."@
				"The program will now exit, you should fix this.");
			`assert(false);
			ConsoleCommand("exit");
		}
	}
}

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == NameOf(ReplicatedStaticMesh))
	{
		if (ReplicatedStaticMesh != StaticMeshComponent(MeshComponent).StaticMesh)
		{
			// Enable the light environment if it is not already
			LightEnvironment.bCastShadows = false;
			LightEnvironment.SetEnabled(TRUE);

			StaticMeshComponent(MeshComponent).SetStaticMesh(ReplicatedStaticMesh);
		}
	}
	else if(VarName == NameOf(ReplicatedSkeletalMesh))
	{
		if(ReplicatedSkeletalMesh != SkeletalMeshComponent(MeshComponent).SkeletalMesh)
		{
			// Enable the light environment if it is not already
			LightEnvironment.bCastShadows = false;
			LightEnvironment.SetEnabled(TRUE);

			SkeletalMeshComponent(MeshComponent).SetSkeletalMesh(ReplicatedSkeletalMesh);
		}
	}
	else if (VarName == nameof(ReplicatedMaterial0))
	{
		MeshComponent.SetMaterial(0, ReplicatedMaterial0);
	}
	else if (VarName == nameof(ReplicatedMaterial1))
	{
		MeshComponent.SetMaterial(1, ReplicatedMaterial1);
	}
	else if (VarName == NameOf(ReplicatedMeshTranslation))
	{
		MeshComponent.SetTranslation(ReplicatedMeshTranslation);
	}
	else if (VarName == NameOf(ReplicatedMeshRotation))
	{
		MeshComponent.SetRotation(ReplicatedMeshRotation);
	}
	else if (VarName == NameOf(ReplicatedMeshScale3D))
	{
		MeshComponent.SetScale3D(ReplicatedMeshScale3D / 100.0); // remove compensation for replication rounding
	}
	else if (VarName == nameof(bForceStaticDecals))
	{
		StaticMeshComponent(MeshComponent).SetForceStaticDecals(bForceStaticDecals);
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

function OnSetMesh(SeqAct_SetMesh Action)
{
	local bool bForce;
	if(Action.MeshType == MeshType_StaticMesh)
	{
		bForce = Action.bIsAllowedToMove == StaticMeshComponent(MeshComponent).bForceStaticDecals 
			|| Action.bAllowDecalsToReattach;

		if((Action.NewStaticMesh != None) &&
			(Action.NewStaticMesh != StaticMeshComponent(MeshComponent).StaticMesh || bForce))
		{
			// Enable the light environment if it is not already
			LightEnvironment.bCastShadows = false;
			LightEnvironment.SetEnabled(TRUE);
			// force decals on this mesh to be treated as movable or not (if False then decals will use fastpath)
			bForceStaticDecals = !Action.bIsAllowedToMove;
			StaticMeshComponent(MeshComponent).SetForceStaticDecals(bForceStaticDecals);
			// Don't allow decals to reattach since we are changing the static mesh
			MeshComponent.bAllowDecalAutomaticReAttach = Action.bAllowDecalsToReattach;
			StaticMeshComponent(MeshComponent).SetStaticMesh( Action.NewStaticMesh, Action.bAllowDecalsToReattach );
			StaticMeshComponent(MeshComponent).bAllowDecalAutomaticReAttach = true;
			ReplicatedStaticMesh = Action.NewStaticMesh;
			ForceNetRelevant();
		}
	}
	else if(Action.MeshType == MeshType_SkeletalMesh)
	{
		bForce = Action.bIsAllowedToMove == Action.bAllowDecalsToReattach;

		if((Action.NewSkeletalMesh != None) &&
			(Action.NewSkeletalMesh != SkeletalMeshComponent(MeshComponent).SkeletalMesh || bForce))
		{
			// Enable the light environment if it is not already
			LightEnvironment.bCastShadows = false;
			LightEnvironment.SetEnabled(TRUE);
			// Don't allow decals to reattach since we are changing the static mesh
			MeshComponent.bAllowDecalAutomaticReAttach = Action.bAllowDecalsToReattach;
			SkeletalMeshComponent(MeshComponent).SetSkeletalMesh( Action.NewSkeletalMesh, Action.bAllowDecalsToReattach );
			MeshComponent.bAllowDecalAutomaticReAttach = true;
			ReplicatedSkeletalMesh = Action.NewSkeletalMesh;
			ForceNetRelevant();
		}
	}
}

function OnSetMaterial(SeqAct_SetMaterial Action)
{
	MeshComponent.SetMaterial( Action.MaterialIndex, Action.NewMaterial );
	if (Action.MaterialIndex == 0)
	{
		ReplicatedMaterial0 = Action.NewMaterial;
		ForceNetRelevant();
	}
	else if (Action.MaterialIndex == 1)
	{
		ReplicatedMaterial1 = Action.NewMaterial;
		ForceNetRelevant();
	}
}

function SetStaticMesh(StaticMesh NewMesh, optional vector NewTranslation, optional rotator NewRotation, optional vector NewScale3D)
{
	StaticMeshComponent(MeshComponent).SetStaticMesh(NewMesh);
	MeshComponent.SetTranslation(NewTranslation);
	MeshComponent.SetRotation(NewRotation);
	if (!IsZero(NewScale3D))
	{
		MeshComponent.SetScale3D(NewScale3D);
		ReplicatedMeshScale3D = NewScale3D * 100.0; // avoid rounding in replication code
	}
	ReplicatedStaticMesh = NewMesh;
	ReplicatedMeshTranslation = NewTranslation;
	ReplicatedMeshRotation = NewRotation;
	ForceNetRelevant();
}

function SetSkeletalMesh(SkeletalMesh NewMesh, optional vector NewTranslation, optional rotator NewRotation, optional vector NewScale3D)
{

}

function SetMesh(MeshComponent CompWithNewMesh, optional vector NewTranslation, optional rotator NewRotation, optional vector NewScale3D)
{
	if(StaticMeshComponent(CompWithNewMesh) != None)
	{
		SetStaticMesh(StaticMeshComponent(CompWithNewMesh).StaticMesh, NewTranslation, NewRotation, NewScale3D);
	}
	else if(SkeletalMeshComponent(CompWithNewMesh) != None)
	{
		SetSkeletalMesh(SkeletalMeshComponent(CompWithNewMesh).SkeletalMesh, NewTranslation, NewRotation, NewScale3D);
	}
	else
	{
		`warn("Unsupported MeshComponent subclass given to"@Self$"::SetMesh()");
	}
}

/**
 *	Query to see if this DynamicSMActor can base the given Pawn
 */
simulated function bool CanBasePawn( Pawn P )
{
	// Can base pawn if...
	//		Pawns can be based always OR
	//		Pawns can be based if physics is not awake
	if( bPawnCanBaseOn ||
			(bSafeBaseIfAsleep &&
			 MeshComponent != None &&
			!MeshComponent.RigidBodyIsAwake()) )
	{
		return TRUE;
	}

	return FALSE;
}

/**
 * This will turn "off" the light environment so it will no longer update.
 * This is useful for having a Timer call this once something has come to a stop and doesn't need 100% correct lighting.
 **/
simulated final function SetLightEnvironmentToNotBeDynamic()
{
	if( LightEnvironment != none )
	{
		LightEnvironment.bDynamic = FALSE;
	}
}

DefaultProperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=TRUE
	End Object
	LightEnvironment=MyLightEnvironment
	Components.Add(MyLightEnvironment)

	/*
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
	    BlockRigidBody=false
		LightEnvironment=MyLightEnvironment
		bUsePrecomputedShadows=FALSE
	End Object
	CollisionComponent=StaticMeshComponent0
	StaticMeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)
	*/

	bEdShouldSnap=true
	bWorldGeometry=false
	bGameRelevant=true
	RemoteRole=ROLE_SimulatedProxy
	bPathColliding=true

	// DynamicSMActor do not have collision as a default.  Having collision on them
	// can be very slow (e.g. matinees where the matinee is controlling where
	// the actors move and then they are trying to collide also!)
	// The overall idea is that it is really easy to see when something doesn't
	// collide correct and rectify it.  On the other hand, it is hard to see
	// something testing collision when it should not be while you wonder where
	// your framerate went.

	bCollideActors=true
	bPawnCanBaseOn=true

	// Automatically shadow parent to whatever this actor is attached to by default
	bShadowParented=true
}
