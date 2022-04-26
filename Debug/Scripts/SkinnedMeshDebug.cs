using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Xlwnya.Misc.Debug.Scripts
{
    public class SkinnedMeshDebug : MonoBehaviour
    {
        public SkinnedMeshRenderer target;
        public Mesh targetMesh;
        public int verticesCount;
        public int subMeshCount;
        public uint[] subMeshSize;
        public Transform[] bones;

#if UNITY_EDITOR
        [CustomEditor(inspectedType: typeof(SkinnedMeshDebug))]
        public class SkinnedMeshDebuEditor : Editor
        {
            public override void OnInspectorGUI()
            {
                SkinnedMeshDebug self = target as SkinnedMeshDebug;
                if (self is null) return;
                
                SkinnedMeshRenderer targetRenderer = self.target;
                if (targetRenderer is null)
                {
                    self.target = self.gameObject.GetComponent<SkinnedMeshRenderer>();
                }
                
                if (!(targetRenderer is null))
                {
                    self.bones = targetRenderer.bones;
                    self.targetMesh = targetRenderer.sharedMesh;
                    if (!(self.targetMesh is null))
                    {
                        var x =self.targetMesh.bindposes;
                        var y = self.targetMesh.boneWeights;
                        self.subMeshCount = self.targetMesh.subMeshCount;
                        if (self.subMeshSize is null || self.subMeshSize.Length != self.subMeshCount)
                        {
                            self.subMeshSize = new uint[self.subMeshCount];
                        }

                        self.verticesCount = self.targetMesh.vertices.Length;
                        for (int i = 0; i < self.subMeshCount; i++)
                        {
                            self.subMeshSize[i] = self.targetMesh.GetIndexCount(i) / 3;
                        }
                    }
                }
                
                base.OnInspectorGUI();
            }
        }
#endif
    }
}