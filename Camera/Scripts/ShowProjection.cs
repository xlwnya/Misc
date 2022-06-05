using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Xlwnya.Misc.Camera.Scripts
{
    [ExecuteInEditMode]
    public class ShowProjection : MonoBehaviour
    {
        public Matrix4x4 cameraMatrix;
        public Vector2 cameraSize;
        public Vector2 clipPlane;
        public float aspect;
        public float orthographicSize;

        public Material targetMaterial;
        
        private UnityEngine.Camera _cam;
        
#if UNITY_EDITOR

        // Start is called before the first frame update
        void Start()
        {
            if (!_cam) _cam = GetComponent<UnityEngine.Camera>();
        }

        private void OnEnable()
        {
            if (!_cam) _cam = GetComponent<UnityEngine.Camera>();
        }
    
        // Update is called once per frame
        void Update()
        {
            cameraMatrix = _cam.worldToCameraMatrix;
            orthographicSize = _cam.orthographicSize;
            aspect = _cam.aspect;
            cameraSize = new Vector2(orthographicSize * aspect, orthographicSize);
            clipPlane = new Vector2(_cam.nearClipPlane, _cam.farClipPlane);
        }

        private void CopyCameraProjection()
        {
            if (!_cam || !targetMaterial) return;
            if (targetMaterial.HasProperty("_CameraMatrixR0")) targetMaterial.SetVector("_CameraMatrixR0", cameraMatrix.GetRow(0));
            if (targetMaterial.HasProperty("_CameraMatrixR1")) targetMaterial.SetVector("_CameraMatrixR1", cameraMatrix.GetRow(1));
            if (targetMaterial.HasProperty("_CameraMatrixR2")) targetMaterial.SetVector("_CameraMatrixR2", cameraMatrix.GetRow(2));
            if (targetMaterial.HasProperty("_CameraMatrixR3")) targetMaterial.SetVector("_CameraMatrixR3", cameraMatrix.GetRow(3));
            if (targetMaterial.HasProperty("_CameraSize"))
            {
                targetMaterial.SetVector("_CameraSize", new Vector4(orthographicSize*_cam.aspect, orthographicSize, 1, 1));
            }
            if (targetMaterial.HasProperty("_NearClipPlane")) targetMaterial.SetFloat("_NearClipPlane", _cam.nearClipPlane);
            if (targetMaterial.HasProperty("_FarClipPlane")) targetMaterial.SetFloat("_FarClipPlane", _cam.farClipPlane);
        }

        [CustomEditor(typeof(ShowProjection))]
        public class ShowProjectionEditor : Editor
        {
            public override void OnInspectorGUI()
            {
                var self = (ShowProjection) target;
                
                serializedObject.Update();
                var iter = serializedObject.GetIterator();
                iter.NextVisible(true);
                while(iter.NextVisible(false))
                {
                    EditorGUILayout.PropertyField(iter, true);
                    if (iter.name == "cameraMatrix")
                    {
                        // 行列の内容を行単位で出力しておく
                        EditorGUILayout.Vector4Field("cameraMatrixR0", self.cameraMatrix.GetRow(0));
                        EditorGUILayout.Vector4Field("cameraMatrixR1", self.cameraMatrix.GetRow(1));
                        EditorGUILayout.Vector4Field("cameraMatrixR2", self.cameraMatrix.GetRow(2));
                        EditorGUILayout.Vector4Field("cameraMatrixR3", self.cameraMatrix.GetRow(3));
                    }
                }
                serializedObject.ApplyModifiedProperties();
                
                bool execCopy = GUILayout.Button("Copy camera data to Material");
                if (execCopy) self.CopyCameraProjection();
            }
        }
#endif
    }
}
