using System;
using System.Text;
using System.Text.RegularExpressions;
#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;

namespace Xlwnya.Misc.Avatar.Scripts
{
    public class BoneAutoRename : MonoBehaviour
    {
        public string removePrefix = "";
        public string removeSuffix = "";
        public string addPrefix = "";
        public string addSuffix = "";
    
#if UNITY_EDITOR
        [CustomEditor(inspectedType: typeof(BoneAutoRename))]
        public class BoneAutoRenameEditor : Editor
        {
            public override void OnInspectorGUI()
            {
                BoneAutoRename self = target as BoneAutoRename;
                if (self is null) return;

                base.OnInspectorGUI();

                bool execRename = GUILayout.Button("Rename");
                if (execRename)
                {
                    ExecRenameTree(self, self.gameObject.transform);
                    EditorUtility.SetDirty(self);
                }
            }

            private bool ExecRenameTree(BoneAutoRename self, Transform targetTree)
            {
                bool modified = false;
                for (int i = 0; i < targetTree.childCount; i++)
                {
                    var child = targetTree.GetChild(i);
                    bool mod = ExecRenameTree(self, child);
                    modified = modified || mod;
                }
            
                bool renamed = ExecRename(self, targetTree);
                modified = modified || renamed;
                return modified;
            }

            public enum LeftRight {
                None,
                Left,
                Right,
            }

            public enum Armature
            {
                None,
                Armature,
                Hips,
                Spine,
                Chest,
                Neck,
                Head,
                Shoulder,
                UpperArm,
                LowerArm,
                UpperLeg,
                LowerLeg,
                Foot,
                Toe,
                Hand,
                Index,
                Little,
                Middle,
                Ring,
                Thumb,
            }

            public enum Finger
            {
                None,
                Proximal,
                Intermediate,
                Distal,
            }
        
            private bool ExecRename(BoneAutoRename self, Transform targetTransform)
            {
                var origName = targetTransform.name;
                var nm = origName;
                // removePrefix除去
                if (self.removePrefix.Length > 0 && nm.StartsWith(self.removePrefix))
                {
                    nm = new Regex($"^#{Regex.Escape(self.removePrefix)}").Replace(nm, "");
                }
                // removeSuffix除去
                if (self.removeSuffix.Length > 0 && nm.EndsWith(self.removeSuffix))
                {
                    nm = new Regex($"#{Regex.Escape(self.removeSuffix)}$").Replace(nm, "");
                }
                // addPrefix一旦除去
                if (self.addPrefix.Length > 0 && nm.StartsWith(self.addPrefix))
                {
                    nm = new Regex($"^#{Regex.Escape(self.addPrefix)}").Replace(nm, "");
                }
                // addSuffix一旦除去
                if (self.addSuffix.Length > 0 && nm.EndsWith(self.addSuffix))
                {
                    nm = new Regex($"#{Regex.Escape(self.addSuffix)}$").Replace(nm, "");
                }

                var nameModifyPrefixSuffix = $"{self.addPrefix}{nm}{self.addSuffix}";

                // _end
                bool hasEnd = nm.EndsWith("[_\\.]end$", StringComparison.OrdinalIgnoreCase);
                nm = Regex.Replace(nm, "[_\\.]end$", "", RegexOptions.IgnoreCase);
            
                // 余分な "_"、" ", "." 削除
                nm = Regex.Replace(nm, "[_ \\.]", "");

                // Left/Right
                LeftRight lr = LeftRight.None;
                if (nm.StartsWith("Left", StringComparison.OrdinalIgnoreCase)) lr = LeftRight.Left;
                if (nm.StartsWith("Right", StringComparison.OrdinalIgnoreCase)) lr = LeftRight.Right;
                if (nm.EndsWith("L")) lr = LeftRight.Left;
                if (nm.EndsWith("R")) lr = LeftRight.Right;
                nm = Regex.Replace(nm, "^(Left|Right)", "", RegexOptions.IgnoreCase);
                nm = Regex.Replace(nm, "[LR]$", "", RegexOptions.IgnoreCase);

                // 以降小文字
                nm = nm.ToLower();

                // Armature判別
                Armature armature = Armature.None;
                foreach (Armature ar in Enum.GetValues(typeof(Armature)))
                {
                    if (Armature.None == ar) continue;

                    if (Armature.Toe == ar)
                    {
                        // ToeだけToeBase/ToeBase_endとToesがあるので別処理
                        if (Regex.Match(nm, "^Toe(s|Base)?", RegexOptions.IgnoreCase).Success)
                        {
                            armature = ar;
                            nm = Regex.Replace(nm, $"^^Toe(s|Base)?", "", RegexOptions.IgnoreCase);
                            break;
                        }
                    }
                    else
                    {
                        var armatureString = ar.ToString();
                        if (nm.StartsWith(armatureString, StringComparison.OrdinalIgnoreCase))
                        {
                            armature = ar;
                            nm = Regex.Replace(nm, $"^{Regex.Escape(armatureString)}", "", RegexOptions.IgnoreCase);
                            break;
                        }
                    }
                }

                // 指判別
                Finger finger = Finger.None;
                foreach (Finger e in Enum.GetValues(typeof(Finger)))
                {
                    if (Finger.None == e) continue;
                
                    var fingerString = e.ToString();
                    if (nm.StartsWith(fingerString, StringComparison.OrdinalIgnoreCase))
                    {
                        finger = e;
                        nm = Regex.Replace(nm, $"^{Regex.Escape(fingerString)}", "", RegexOptions.IgnoreCase);
                        break;
                    }
                }

                string newName = null;
                if (Armature.None != armature && nm.Length <= 0)
                {
                    // Armature
                    var newNameBuilder = new StringBuilder();
                    newNameBuilder.Append(self.addPrefix);
                    if (LeftRight.None != lr) newNameBuilder.Append(lr.ToString());
                    if (Armature.None != armature)
                    {
                        if (Armature.Toe == armature)
                        {
                            newNameBuilder.Append("ToeBase");
                        } else {
                            newNameBuilder.Append(armature.ToString());
                        }
                    }
                    if (Finger.None != finger) newNameBuilder.Append(finger.ToString());
                    if (hasEnd) newNameBuilder.Append("_end");
                    newNameBuilder.Append(self.addSuffix);
                    newName = newNameBuilder.ToString();
                    targetTransform.name = newName;
                    UnityEngine.Debug.Log($"Rename: {origName} -> {newName}");
                    return true;
                } else if (origName != nameModifyPrefixSuffix)
                {
                    newName = nameModifyPrefixSuffix;
                    targetTransform.name = newName;
                    UnityEngine.Debug.Log($"Rename(modify prefix/suffix): {origName} -> {newName}");
                    return true;
                }

                return false;
            }
        }
#endif
    }
}

