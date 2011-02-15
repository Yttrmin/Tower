class TowerModInfo_Tower extends TowerModInfo;

/*
Material'ASC_Floor.BSP.Materials.M_ASC_Floor_BSP_Tile01'
Material'UN_Floors.BSP.Materials.M_Floors_BlendModulation_Master_02'
Material'HU_Deck.SM.Materials.M_HU_Deck_SM_Fwindow_Glassbroken_Mat'
Material'UN_Liquid.SM.Materials.M_UN_Liquid_SM_NanoBlack_03_Master'
*/

DefaultProperties
{
	ModName="Tower"
	AuthorName="James Baltos"
	Contact="none :("
	Description="Primary ModInfo for Tower!"
	Version="0.1"
	ModBlocks.Add(class'TowerBlockRoot')
	ModBlocks.Add(class'TowerBlockDebug')
	ModBlockInfo.Add((DisplayName="Debug Block",BaseClass=class'TowerBlockDebug',BlockMesh=StaticMesh'TowerBlocks.DebugBlock',BlockMaterial=Material'TowerBlocks.DebugBlockMaterial'))
//	ModBlockInfo.Add((DisplayName="Debug Block (Default Material)",BaseClass=class'TowerBlockDebug',BlockMesh=StaticMesh'TowerBlocks.DebugBlock',BlockMaterial=Material'EngineMaterials.DefaultMaterial'))
	ModBlockInfo.Add((DisplayName="Debug Block (Floor Material)",BaseClass=class'TowerBlockDebug',BlockMesh=StaticMesh'TowerBlocks.DebugBlock',BlockMaterial=Material'ASC_Floor.BSP.Materials.M_ASC_Floor_BSP_Tile01'))
	ModBlockInfo.Add((DisplayName="Debug Block (Other Floor Material)",BaseClass=class'TowerBlockDebug',BlockMesh=StaticMesh'TowerBlocks.DebugBlock',BlockMaterial=Material'UN_Floors.BSP.Materials.M_Floors_BlendModulation_Master_02'))
	ModBlockInfo.Add((DisplayName="Debug Block (Glass Material)",BaseClass=class'TowerBlockDebug',BlockMesh=StaticMesh'TowerBlocks.DebugBlock',BlockMaterial=Material'HU_Deck.SM.Materials.M_HU_Deck_SM_Fwindow_Glassbroken_Mat'))
	ModBlockInfo.Add((DisplayName="Debug Block (Liquid Material)",BaseClass=class'TowerBlockDebug',BlockMesh=StaticMesh'TowerBlocks.DebugBlock',BlockMaterial=Material'UN_Liquid.SM.Materials.M_UN_Liquid_SM_NanoBlack_03_Master'))
}