using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace MSTest.Buildbox
{
    [TestClass]
    public class ApprovalTestsCleaner
    {
        [AssemblyCleanup]
        public static void Cleanup()
        {
            ApprovalTests.Maintenance.ApprovalMaintenance.CleanUpAbandonedFiles();
        }
    }
}