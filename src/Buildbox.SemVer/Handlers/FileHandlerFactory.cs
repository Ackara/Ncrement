using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

namespace Acklann.Buildbox.SemVer.Handlers
{
    public class FileHandlerFactory
    {
        public FileHandlerFactory()
        {
            _fileHandlers = new Dictionary<string, Type>();
            var fileHandlerTypes = from t in Assembly.GetAssembly(typeof(IFileHandler)).GetTypes()
                                   where t.IsAbstract == false && t.IsInterface == false && typeof(IFileHandler).IsAssignableFrom(t)
                                   select t;

            foreach (var type in fileHandlerTypes) { _fileHandlers.Add(type.Name, type); }
        }

        public IFileHandler Create(string name)
        {
            try
            {
                return (IFileHandler)Activator.CreateInstance(_fileHandlers[name]);
            }
            catch (KeyNotFoundException)
            {
                return new NullFileHandler();
            }
        }

        public IEnumerable<Type> GetFileHandlerTypes()
        {
            return _fileHandlers.Values;
        }

        #region Private Members

        private IDictionary<string, Type> _fileHandlers;

        #endregion Private Members
    }
}