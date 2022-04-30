using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace Xlwnya.Misc.Debug.Scripts
{
    public class DumpMeshInfo : MonoBehaviour
    {
        public string outputPath = "";

        #if UNITY_EDITOR

        private void Dump()
        {
            Mesh mesh = GetComponent<MeshFilter>()?.sharedMesh;
            if (mesh is null) return;

            using (StreamWriter writer = new StreamWriter($"Assets/{outputPath}", false))
            {
                writer.WriteLine($"indexFormat:\t{mesh.indexFormat}");
                writer.WriteLine($"bounds:\t{mesh.bounds.ToString()}");
                // 頂点
                writer.WriteLine("Vertices:");
                for (int i = 0; i < mesh.vertexCount; i++)
                {
                    var buf = new StringBuilder(256);
                    buf.Append($"{i.ToString()}:\tv:{mesh.vertices[i].ToString()}");
                    if (!(mesh.normals is null) && i < mesh.normals.Length) buf.Append($"\tn:{mesh.normals[i].ToString()}");
                    if (!(mesh.tangents is null) && i < mesh.tangents.Length) buf.Append($"\tt:{mesh.tangents[i].ToString()}");
                    if (!(mesh.colors32 is null) && i < mesh.colors32.Length) buf.Append($"\tc:{mesh.colors32[i].ToString()}");
                    if (!(mesh.uv is null) && i < mesh.uv.Length) buf.Append($"\tuv:{mesh.uv[i].ToString()}");
                    if (!(mesh.uv2 is null) && i < mesh.uv2.Length) buf.Append($"\tuv2:{mesh.uv2[i].ToString()}");
                    if (!(mesh.uv3 is null) && i < mesh.uv3.Length) buf.Append($"\tuv3:{mesh.uv3[i].ToString()}");
                    if (!(mesh.uv4 is null) && i < mesh.uv4.Length) buf.Append($"\tuv4:{mesh.uv4[i].ToString()}");
                    if (!(mesh.uv5 is null) && i < mesh.uv5.Length) buf.Append($"\tuv5:{mesh.uv5[i].ToString()}");
                    if (!(mesh.uv6 is null) && i < mesh.uv6.Length) buf.Append($"\tuv6:{mesh.uv6[i].ToString()}");
                    if (!(mesh.uv7 is null) && i < mesh.uv7.Length) buf.Append($"\tuv7:{mesh.uv7[i].ToString()}");
                    if (!(mesh.uv8 is null) && i < mesh.uv8.Length) buf.Append($"\tuv8:{mesh.uv8[i].ToString()}");
                    writer.WriteLine(buf.ToString());
                }

                // メッシュ
                writer.WriteLine($"subMeshCount:\t{mesh.subMeshCount.ToString()}");
                for (int subMesh = 0; subMesh < mesh.subMeshCount; subMesh++)
                {
                    var topology = mesh.GetTopology(subMesh);
                    writer.WriteLine($"SubMesh:\t{subMesh.ToString()}\ttopology:{topology}\tbaseVertex:{mesh.GetBaseVertex(subMesh).ToString()}");
                    if (topology == MeshTopology.Triangles || topology == MeshTopology.Quads)
                    {
                        var triangles = mesh.GetTriangles(subMesh);
                        for (int tri = 0; tri < triangles.Length; tri++)
                        {
                            int triVert = triangles[tri];
                            writer.WriteLine($"{(tri/3).ToString()}-{tri.ToString()}:\tvIndex:{triVert.ToString()}\tv:{mesh.vertices[triVert].ToString()}");
                        }
                    }
                }
            }
        }

        [CustomEditor(typeof(DumpMeshInfo))]
        public class ShowMeshIndoEditor : Editor
        {
            public override void OnInspectorGUI()
            {
                base.OnInspectorGUI();
                if (GUILayout.Button("Dump Info"))
                {
                    (target as DumpMeshInfo)?.Dump();
                }
            }
        }

        #endif
    }
}
