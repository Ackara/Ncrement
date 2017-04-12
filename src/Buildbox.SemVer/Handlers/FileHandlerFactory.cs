using System;
using System.Collections.Generic;
using System.Reflection;

namespace Ackara.Buildbox.SemVer.Handlers
{
    public class FileHandlerFactory
    {
        public FileHandlerFactory()
        {
            _fileHandlers = new Dictionary<string, Type>();
            foreach (var type in Assembly.GetAssembly(typeof(IFileHandler)).GetTypes())
            {
                var attribute = type.GetCustomAttribute<FileHandlerIdAttribute>();
                if (attribute != null && type.IsAbstract == false)
                {
                    _fileHandlers.Add(attribute.Id, type);
                }
            }
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

        public IEnumerable<string> GetFileHandlerIds()
        {
            return _fileHandlers.Keys;
        }

        #region Private Members

        private IDictionary<string, Type> _fileHandlers;

        #endregion Private Members
    }
}