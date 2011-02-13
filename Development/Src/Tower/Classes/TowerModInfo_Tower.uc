class TowerModInfo_Tower extends TowerModInfo;

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
	ModBlockInfo.Add((DisplayName="Test Debug Block",BaseClass=class'TowerBlockDebug',BlockMesh=StaticMesh'TowerBlocks.DebugBlock',BlockMaterial=Material'EngineMaterials.DefaultMaterial'))
}