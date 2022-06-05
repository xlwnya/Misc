using System;
using System.IO;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Xlwnya.Misc.Camera.Scripts
{
    public class SaveRenderTexture : MonoBehaviour
    {
        public enum SaveFormat
        {
            EXR,
            PNG,
            JPG,
            TGA
        }
    
        public RenderTexture targetRT;
        public SaveFormat saveFormat;
        public TextureFormat saveTextureFormat = TextureFormat.RGBAFloat;
        public bool saveLinear = true;
        public bool exrOutputAsFloat = true;
    }

#if UNITY_EDITOR
    [CustomEditor(typeof(SaveRenderTexture))]
    public class SaveRenderTextureEditor : UnityEditor.Editor
    {
        public override void OnInspectorGUI()
        {
            var self = (SaveRenderTexture)target;
            
            serializedObject.Update();

            bool execSaveRT = false;
            if (self.targetRT) execSaveRT = GUILayout.Button("Save RenderTexture");

            DrawDefaultInspector();
            
            if (execSaveRT) SaveRT();
            
            serializedObject.ApplyModifiedProperties();
        }

        private void SaveRT()
        {
            var self = (SaveRenderTexture)target;

            string ext = self.saveFormat.ToString().ToLower();
            string path = EditorUtility.SaveFilePanelInProject("Save RenderTexture", "texture", ext, "");
            if (path.Length > 0)
            {
                Texture2D tex = GetRTPixels(self.targetRT, self.saveTextureFormat, self.saveLinear);
                byte[] data;
                switch (self.saveFormat)
                {
                    case SaveRenderTexture.SaveFormat.EXR:
                        Texture2D.EXRFlags flags = Texture2D.EXRFlags.CompressZIP;
                        if (self.exrOutputAsFloat) flags &= Texture2D.EXRFlags.OutputAsFloat;
                        data = tex.EncodeToEXR(flags);
                        break;
                    
                    case SaveRenderTexture.SaveFormat.PNG:
                        data = tex.EncodeToPNG();
                        break;
                    
                    case SaveRenderTexture.SaveFormat.JPG:
                        data = tex.EncodeToJPG();
                        break;
                    
                    case SaveRenderTexture.SaveFormat.TGA:
                        data = tex.EncodeToTGA();
                        break;
                    default:
                        throw new Exception("unknown SaveFormat.");
                }
                File.WriteAllBytes(path, data);
                AssetDatabase.ImportAsset(path);
            }
        }
        
        // https://docs.unity3d.com/jp/current/ScriptReference/RenderTexture-active.html
        static private Texture2D GetRTPixels(RenderTexture rt, TextureFormat saveFormat, bool linear)
        {
            // Remember currently active render texture
            RenderTexture currentActiveRT = RenderTexture.active;

            // Set the supplied RenderTexture as the active one
            RenderTexture.active = rt;

            // Create a new Texture2D and read the RenderTexture image into it
            Texture2D tex = new Texture2D(rt.width, rt.height, saveFormat, false, linear);
            tex.ReadPixels(new Rect(0, 0, tex.width, tex.height), 0, 0);

            // Restorie previously active render texture
            RenderTexture.active = currentActiveRT;
            return tex;
        }
    }
#endif
}