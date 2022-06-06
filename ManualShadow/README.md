# 分散シャドウマップ手動実装(VSM, Variance Shadow Maps)
* "HLSL シェーダーの魔導書 シェーディングの基礎からレイトレーシングまで" https://www.amazon.co.jp/dp/B09371QYXS/ のChapter 11：シャドウイングの内容を元に実装されています。
* VSMに必要な深度&深度^2をガウスぼかししたシャドウマップの作成/撮影はCamera/Shaders/OutputDepthForSoftShadowRel.shaderで出来ます。(平行投影以外のカメラの場合は動作するか不明)
* シャドウマップを撮影したカメラ情報のマテリアルへのコピーはCamera/Scripts/ShowProjection.csで出来ます。(同じく平行投影以外では不明)
* RenderTextureの場合R16G16_SFLOAT, 画像の場合BC6H(PC)orASTC HDR 4x4(Android)などのHDRの浮動小数点テクスチャである必要があります。
* 追加で影がベイクされてるケースはどうなるか不明です。

## Shaders
* ManualShadowDebug.shader: デバッグ用の影表示シェーダ(Unlit)
* StandardManualShadow.shader: Standardな影表示surfaceシェーダ
* TerrainDiffuseManualShadow.shader: "Nature/Terrain/Diffuse"のシェーダに影表示を追加したシェーダ
* cginc/CustomTerrainSplatmapCommon.cginc: TerrainシェーダでworldPosを使用するためにUnityのTerrainSplatmapCommon.cgincを改変したもの
