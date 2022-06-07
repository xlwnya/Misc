# 分散シャドウマップ手動実装(VSM, Variance Shadow Maps)
* "HLSL シェーダーの魔導書 シェーディングの基礎からレイトレーシングまで" https://www.amazon.co.jp/dp/B09371QYXS/ のChapter 11：シャドウイングの内容を元に実装されています。
* VSMに必要な深度&深度^2をガウスぼかししたシャドウマップの作成/撮影はcolor format = DEPTH_AUTOのRenderTextureに対して撮影した後、別の平行投影カメラでCalcSoftShadowDepth.shaderを撮影すると作成できます。(Camera/Shaders/OutputDepthForSoftShadowRel.shaderでも出来ますがQuestの場合精度が低いみたいです)(平行投影以外のカメラの場合は動作するか不明)
* シャドウマップを撮影したカメラ情報のマテリアルへのコピーはCamera/Scripts/ShowProjection.csで出来ます。(同じく平行投影以外では不明)
* RenderTextureの場合R16G16_SFLOAT, 画像の場合BC6H(PC)orASTC HDR 4x4(Android)などのHDRの浮動小数点テクスチャである必要があります。
* 追加で影がベイクされてるケースはどうなるか不明です。

## Shaders
* ManualShadowDebug.shader: デバッグ用の影表示シェーダ(Unlit)
* StandardManualShadow.shader: Standardな影表示surfaceシェーダ
* CalcSoftShadowDepth.shader: color format = DEPTH_AUTO を指定して撮影したRenderTextureを元にしてVSM用のシャドウマップを出力するシェーダ

## Terrain
* Terrain/Shaders/TerrainDiffuseManualShadow.shader: "Nature/Terrain/Diffuse"のシェーダに影表示を追加したシェーダ
* Terrain/Shaders/cginc/CustomTerrainSplatmapCommon.cginc: TerrainシェーダでworldPosを使用するためにUnityのTerrainSplatmapCommon.cgincを改変したもの
