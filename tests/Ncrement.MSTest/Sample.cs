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

		public static FileInfo GetManifestJSON() => GetFile(@"manifest.json");
		public static FileInfo GetEmptyExtensionVSIXMANIFEST() => GetFile(@"projects\empty_extension.vsixmanifest");
		public static FileInfo GetEmptyNetframeworkCSPROJ() => GetFile(@"projects\empty_netframework.csproj");
		public static FileInfo GetEmptyNetstandardCSPROJ() => GetFile(@"projects\empty_netstandard.csproj");
		public static FileInfo GetExtensionVSIXMANIFEST() => GetFile(@"projects\extension.vsixmanifest");
		public static FileInfo GetNetframeworkCSPROJ() => GetFile(@"projects\netframework.csproj");
		public static FileInfo GetNetstandardCSPROJ() => GetFile(@"projects\netstandard.csproj");

		public struct File
		{
			public const string ManifestJSON = @"manifest.json";
			public const string EmptyExtensionVSIXMANIFEST = @"projects\empty_extension.vsixmanifest";
			public const string EmptyNetframeworkCSPROJ = @"projects\empty_netframework.csproj";
			public const string EmptyNetstandardCSPROJ = @"projects\empty_netstandard.csproj";
			public const string ExtensionVSIXMANIFEST = @"projects\extension.vsixmanifest";
			public const string NetframeworkCSPROJ = @"projects\netframework.csproj";
			public const string NetstandardCSPROJ = @"projects\netstandard.csproj";
		}
	}	
}
