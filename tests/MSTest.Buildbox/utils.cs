using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace MSTest.Buildbox
{
	[TestClass]
	public class ApprovalTestsCleaner
	{
		[AssemblyInitialize]
		public static void Cleanup(TestContext context) => ApprovalTests.Maintenance.ApprovalMaintenance.CleanUpAbandonedFiles();
	}

	public static class TestFile
	{
		public const string MANIFEST = @"semver\manifest.json";
		public const string MIXED_MANIFEST = @"semver\mixed_manifest.json";
		public const string NETSTANDARD = @"semver\netstandard.csproj";
		public const string DOTNET_PROJECT = @"semver\dotnet_project\dotnet_project.csproj";
		public const string ASSEMBLYINFO = @"semver\dotnet_project\Properties\AssemblyInfo.cs";
	}

	public static class DataFile
	{
			}
}
