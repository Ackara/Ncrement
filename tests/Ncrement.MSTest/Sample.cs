using System;
using System.IO;
using System.Linq;

namespace Acklann.Ncrement
{
	internal static partial class Sample
	{
		public const string FOLDER_NAME = "samples";

		public static string DirectoryName => Path.Combine(AppDomain.CurrentDomain.BaseDirectory, FOLDER_NAME);
		
		public static FileInfo GetFile(string fileName, string directory = null)
        {
            fileName = Path.GetFileName(fileName);
            string searchPattern = $"*{Path.GetExtension(fileName)}";

            string targetDirectory = directory?? Path.Combine(AppDomain.CurrentDomain.BaseDirectory, FOLDER_NAME);
            return new DirectoryInfo(targetDirectory).EnumerateFiles(searchPattern, SearchOption.AllDirectories)
                .First(x => x.Name.Equals(fileName, StringComparison.CurrentCultureIgnoreCase));
        }

		public static FileInfo GetEmptyNetstandardCSPROJ() => GetFile(@"projects\empty_netstandard.csproj");
		public static FileInfo GetNetstandardCSPROJ() => GetFile(@"projects\netstandard.csproj");

		public struct File
		{
			public const string EmptyNetstandardCSPROJ = @"projects\empty_netstandard.csproj";
			public const string NetstandardCSPROJ = @"projects\netstandard.csproj";
		}
	}	
}
