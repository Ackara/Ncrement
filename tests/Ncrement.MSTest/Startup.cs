using Microsoft.VisualStudio.TestTools.UnitTesting;

[assembly: Acklann.Diffa.ApprovedFolder("approved-results")]
[assembly: Acklann.Diffa.Reporters.Reporter(typeof(Acklann.Diffa.Reporters.DiffReporter))]

namespace Acklann.Ncrement
{
    [TestClass]
    public class Startup
    {
    }
}