## Shader/Material
* geomで視界ジャックしているけどQuadをvertで動かした方が多分良い
* OutputDepthRel.shaderはvert方式に変更。MeshはQuadWithBoundsに変更する必要あり。
* Normal, MotionVectorはSPS-I対応忘れてる。TODO: これもvert方式に変更する。
* geomで視界ジャックしているシェーダはsinglePoint.asset、vert方式のシェーダはQuadWithBounds.assetをMeshとして使用する。
* Boundsを広くする必要がある場合はSkinnedMeshRendererなどで指定してしまうと良い。
## Scripts
* ShowProjection.cs: CameraのworldToCameraMatrix他を表示して他のマテリアルに設定する。今のところ平行投影のカメラしか対応してない気がする。
* SaveRenderTexture.cs: RenderTextureの内容をそのままファイルに保存する。RenderTextureの形式と指定した形式と出力ファイルの形式がうまく合ってないとエラーになる。
