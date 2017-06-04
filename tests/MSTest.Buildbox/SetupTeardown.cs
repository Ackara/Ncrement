using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace MSTest.Buildbox
{
    [TestClass]
    public class SetupTeardown
    {
        [AssemblyCleanup]
        public static void Cleanup()
        {
            ApprovalTests.Maintenance.ApprovalMaintenance.CleanUpAbandonedFiles();
        }
    }
}