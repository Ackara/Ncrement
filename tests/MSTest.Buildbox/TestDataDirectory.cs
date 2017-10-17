using System;
using System.IO;
using System.Linq;

namespace MSTest.Buildbox
{
    public partial class TestDataDirectory
    {
        public const string FOLDER_NAME = "TestData";

        public static string FullPath
        {
            get { return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, FOLDER_NAME); }
        }

        public static FileInfo GetFile(string fileName)
        {
            fileName = Path.GetFileName(fileName);
            string searchPattern = $"*{Path.GetExtension(fileName)}";

            string appDirectory = Path.Combine(AppDomain.CurrentDomain.BaseDirectory);
            return new DirectoryInfo(appDirectory).GetFiles(searchPattern, SearchOption.AllDirectories)
                .First(x => x.Name.Equals(fileName, StringComparison.CurrentCultureIgnoreCase));
        }

        public static string GetFileContent(string fileName)
        {
            return File.ReadAllText(GetFile(fileName).FullName);
        }
    }
}