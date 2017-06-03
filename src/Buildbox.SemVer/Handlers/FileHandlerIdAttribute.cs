using System;

namespace Acklann.Buildbox.SemVer.Handlers
{
    [AttributeUsage(AttributeTargets.Class, AllowMultiple = false, Inherited = false)]
    public sealed class FileHandlerIdAttribute : Attribute
    {
        public FileHandlerIdAttribute(string id)
        {
            Id = id;
        }

        public readonly string Id;
    }
}