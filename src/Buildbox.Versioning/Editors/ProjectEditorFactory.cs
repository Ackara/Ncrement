using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

namespace Acklann.Buildbox.Versioning.Editors
{
    public class ProjectEditorFactory
    {
        public ProjectEditorFactory()
        {
            var assemblyTypes = from t in GetType().GetTypeInfo().Assembly.ExportedTypes
                                let ti = t.GetTypeInfo()
                                where
                                    ti.IsInterface == false
                                    && ti.IsAbstract == false
                                    && ti.Name != nameof(NullProjectEditor)
                                    && typeof(IProjectEditor).GetTypeInfo().IsAssignableFrom(ti)
                                select t;

            _editorTypes = new Dictionary<string, Type>();
            foreach (var type in assemblyTypes)
            {
                _editorTypes.Add(type.Name, type);
            }
        }

        public IProjectEditor[] GetProjectEditors()
        {
            int index = 0;
            var editors = new IProjectEditor[_editorTypes.Count];
            foreach (var type in _editorTypes.Values)
            {
                editors[index] = (IProjectEditor)Activator.CreateInstance(type);
                index++;
            }
            return editors;
        }

        public IProjectEditor CreateInstance(string typeName)
        {
            if (_editorTypes.ContainsKey(typeName))
            {
                return (IProjectEditor)Activator.CreateInstance(_editorTypes[typeName]);
            }
            else return new NullProjectEditor();
        }

        #region private Members

        private readonly IDictionary<string, Type> _editorTypes;

        #endregion private Members
    }
}