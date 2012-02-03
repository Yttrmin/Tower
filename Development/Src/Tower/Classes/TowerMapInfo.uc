class TowerMapInfo extends MapInfo;

struct PreviewArea
{
	/** The SceneCaptureActor used to render blocks to a texture when previewing them in the HUD. */
	var() const SceneCaptureActor PreviewSceneCaptureActor;
	var() const array<PointLightToggleable> PreviewLights;
	var() const DynamicSMActor PreviewBlockStatic;
	var() const SkeletalMeshActor PreviewBlockSkeletal;
	var Actor LastActivePreviewBlock;
};

const PREVIEW_AREA_COUNT = 4;

/** Notifies TowerBlockRoot when enemies and projectiles touch this. This will be the absolute
maximum range of all modules, so this should probably take up most of the level. */
var() const Volume RadarVolume;

/** Used to generate the previews you see navigating through the build menu. There needs to be one for each split-scren
player. */
var() privatewrite PreviewArea PreviewAreas[PREVIEW_AREA_COUNT];

var() const int XBlocks;
var() const int YBlocks;
var() const int ZBlocks;

var bool bRootBlockSet;

// Move me to TowerGame thanks.
var() const editconst int BlockWidth;
var() const editconst int BlockHeight;

final function Initialize()
{
	local int i;
	local PointLightToggleable Light;
	for(i = 0; i < PREVIEW_AREA_COUNT; i++)
	{
		PreviewAreas[i].PreviewSceneCaptureActor.SceneCapture.SetEnabled(false);
		PreviewAreas[i].PreviewBlockStatic.LightEnvironment.SetEnabled(false);
		PreviewAreas[i].PreviewBlockSkeletal.LightEnvironment.SetEnabled(false);
		PreviewAreas[i].PreviewBlockStatic.SetHidden(true);
		PreviewAreas[i].PreviewBlockSkeletal.SetHidden(true);
		foreach PreviewAreas[i].PreviewLights(Light)
		{
			Light.LightComponent.SetEnabled(false);
		}
	}
}

final function TogglePreviewState(bool bEnable, int ControllerID)
{

}

function ActivateHUDPreview(int ControllerID)
{
	local PointLightToggleable Light;
	PreviewAreas[ControllerID].LastActivePreviewBlock.SetHidden(false);
	PreviewAreas[ControllerID].PreviewSceneCaptureActor.SceneCapture.SetEnabled(true);
	foreach PreviewAreas[ControllerID].PreviewLights(Light)
	{
		Light.LightComponent.SetEnabled(true);
	}
}

function DeactivateHUDPreview(int ControllerID)
{
	local PointLightToggleable Light;
	PreviewAreas[ControllerID].PreviewSceneCaptureActor.SceneCapture.SetEnabled(FALSE);
	PreviewAreas[ControllerID].PreviewBlockStatic.SetHidden(true);
	PreviewAreas[ControllerID].PreviewBlockSkeletal.SetHidden(true);
	foreach PreviewAreas[ControllerID].PreviewLights(Light)
	{
		Light.LightComponent.SetEnabled(false);
	}
}

/** Setup the PreviewBlock to match the TowerBlock passed in.
Called from TowerHUDMoviePlayer::OnBuildListChange().
Block is a TowerBlock archetype. */
simulated function SetPreview(int ControllerID, TowerBlock Block)
{
//	PreviewBlock.StaticMeshComponent.SetStaticMesh(Placeable.GetPlaceableStaticMesh());
//	PreviewBlock.StaticMeshComponent.SetMaterial(0, Placeable.GetPlaceableMaterial(0));
//	Placeable.AttachBlock(None);
	if(StaticMeshComponent(Block.MeshComponent) != None)
	{
		PreviewAreas[ControllerID].PreviewBlockSkeletal.SetHidden(true);
		PreviewAreas[ControllerID].PreviewBlockStatic.SetHidden(false);
		PreviewAreas[ControllerID].PreviewBlockStatic.StaticMeshComponent.SetTranslation(Vect(0,0,0));
		PreviewAreas[ControllerID].PreviewBlockStatic.StaticMeshComponent.SetStaticMesh(StaticMeshComponent(Block.MeshComponent).StaticMesh);
		PreviewAreas[ControllerID].PreviewBlockStatic.StaticMeshComponent.SetMaterial(0, Block.MeshComponent.GetMaterial(0));
		PreviewAreas[ControllerID].LastActivePreviewBlock = PreviewAreas[ControllerID].PreviewBlockStatic;
	}
	else if(SkeletalMeshComponent(Block.MeshComponent) != None)
	{
		PreviewAreas[ControllerID].PreviewBlockStatic.SetHidden(true);
		PreviewAreas[ControllerID].PreviewBlockSkeletal.SetHidden(false);
		PreviewAreas[ControllerID].PreviewBlockSkeletal.SkeletalMeshComponent.SetTranslation(Vect(0,0,0));
		PreviewAreas[ControllerID].PreviewBlockSkeletal.SkeletalMeshComponent.SetSkeletalMesh(SkeletalMeshComponent(Block.MeshComponent).SkeletalMesh);
		PreviewAreas[ControllerID].PreviewBlockSkeletal.SkeletalMeshComponent.SetMaterial(0, Block.MeshComponent.GetMaterial(0));
		PreviewAreas[ControllerID].LastActivePreviewBlock = PreviewAreas[ControllerID].PreviewBlockSkeletal;
	}
	else
	{
		`warn(Block@"using unsupported MeshComponent subclass. Can't SetPreview().");
	}
}

final function VerifyPreviewAreas()
{
	local int i;
	for(i = 0; i < 4; i++)
	{
		if(PreviewAreas[i].PreviewSceneCaptureActor.SceneCapture.bEnabled)
		{
			`log("Preview Area #"$i$":"@"PreviewSceneCaptureActor is enabled! Disable it by default for performance reasons!");
		}
	}
}

DefaultProperties
{
	// 256 probably best, could fit several people in.
	BlockWidth = 256
	BlockHeight = 256
}