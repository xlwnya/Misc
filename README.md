# Xlwnya/Misc

Unity用になんとなく作ったふぁいるをてきとうにgit管理するのにゃ。

Assets/Xlwnya/Miscに置いてるにゃ。

## Contents
* Camera: カメラに視界ジャックしてDepthとかを出力するシェーダ
  * OutputDepthForSoftShadowRel.shader: DepthをManualShadow用に出力するシェーダ※今のところ平行投影カメラのみ
  * SaveRenderTexture.cs: RenderTextureを保存
  * ShowProjection.cs: カメラの情報を表示したりマテリアルに設定したり。※今のところ平行投影カメラのみ
* Debug
  * DebugVertexColor.shader: VertexColorを表示
  * FaceOrientation.shader: 面の向きを色で表示
  * ShowTextures.shader: GrabPass, DepthTextureほかをそのまま表示
  * ShowUV.shader: UVを表示
  * ShowZ.shader: Depthを表示
  * VRDetect.shader: VRかどうか表示
  * VRDetextPass.shader: ↑ + VRのレンダリングモード(SinglePassInstancedとか)を表示
  * DumpMeshInfo.cs: Meshの情報をtext出力
  * SkinnedMeshDebug.cs: SkinnedMeshRendererの情報を表示
* LightDebug: Standardのライティングを分解して表示
  * smallSphere.asset: 小さくしたUnityのSphere
* LightTest: 各種シェーダ表示
* ManualShadow: ソフトシャドウの手動実装
* Prefabs
  * WorldDebug.prefab: ワールドデバッグ装備まとめ
* ShowNum: 数値表示
  * ShowShaderInfo.shader: シェーダのパラメータ表示(NearClip/FarClipほか)
  * RenderQueueX.mat: RenderQueueテスト
  * ShowLight0.shader: メインのライト情報を表示
* Test
  * LightShaft.shader: 裏面と表面のDepthの差で厚さを出してライトシャフトっぽくしようとしたてすと
  * TextHex.shader: 面の六角形分割と極座標てすと
  * Unlit.shader: SPS-I対応したUnlit

## License
とりあえずMIT

* 一部にUnityのbuiltin_shaders由来の物、web上の情報由来の物を含みます。

## Notices
* 2022-06-06:
  * Cameraでgeomを使用していた物を一部Quest対応のためvertのみで何とかする方式に変更。
    * MeshをQuadWithBounds.assetに変更する必要あり。
    * Depth以外もvertのみ方式に変更したい。
