class TowerMapInfo extends MapInfo;

struct PreviewArea
{
	var() const SceneCaptureActor BuildPreviewSceneCaptureActor;
	var() const array<PointLightToggleable> PreviewLights;
	var() const DynamicSMActor PreviewBlock;
};

/** Notifies TowerBlockRoot when enemies and projectiles touch this. This will be the absolute
maximum range of all modules, so this should probably take up most of the level. */
var() const Volume RadarVolume;
//@TODO - Deprecate.
/** The SceneCaptureActor used to render blocks to a texture when previewing them in the HUD. */
var() /*deprecated*/ const SceneCaptureActor BuildPreviewSceneCaptureActor;
var() /*deprecated*/ const array<PointLightToggleable> PreviewLights;
var() /*deprecated*/ const DynamicSMActor PreviewBlock;

/** Used to generate the previews you see navigating through the build menu. There needs to be one for each split-scren
player. */
var PreviewArea PreviewAreas[4];

var() const int XBlocks;
var() const int YBlocks;
var() const int ZBlocks;

var bool bRootBlockSet;

// Move me to TowerGame thanks.
var() const editconst int BlockWidth;
var() const editconst int BlockHeight;

function ActivateHUDPreview()
{
	local PointLightToggleable Light;
	PreviewBlock.SetHidden(FALSE);
	BuildPreviewSceneCaptureActor.SceneCapture.SetEnabled(TRUE);
	foreach PreviewLights(Light)
	{
		Light.LightComponent.SetEnabled(TRUE);
	}
}

function DeactivateHUDPreview()
{
	local PointLightToggleable Light;
	BuildPreviewSceneCaptureActor.SceneCapture.SetEnabled(FALSE);
	PreviewBlock.SetHidden(TRUE);
	foreach PreviewLights(Light)
	{
		Light.LightComponent.SetEnabled(FALSE);
	}
}

/** Setup the PreviewBlock to match the TowerBlock passed in.
Called from TowerHUDMoviePlayer::OnBuildListChange().
Block is a TowerBlock archetype. */
simulated function SetPreview(TowerBlock Block)
{
//	PreviewBlock.StaticMeshComponent.SetStaticMesh(Placeable.GetPlaceableStaticMesh());
//	PreviewBlock.StaticMeshComponent.SetMaterial(0, Placeable.GetPlaceableMaterial(0));
//	Placeable.AttachBlock(None);
	PreviewBlock.StaticMeshComponent.SetTranslation(Vect(0,0,0));
	PreviewBlock.StaticMeshComponent.SetStaticMesh(Block.StaticMeshComponent.StaticMesh);
	PreviewBlock.StaticMeshComponent.SetMaterial(0, Block.StaticMeshComponent.GetMaterial(0));
}

DefaultProperties
{
	// 256 probably best, could fit several people in.
	BlockWidth = 256
	BlockHeight = 256
}