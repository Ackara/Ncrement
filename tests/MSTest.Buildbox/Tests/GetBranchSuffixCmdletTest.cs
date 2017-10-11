using Acklann.Buildbox.SemVer.Cmdlets;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;
using System.Linq;

namespace MSTest.Buildbox.Tests
{
    [TestClass]
    public class GetBranchSuffixCmdletTest
    {
        [TestMethod]
        public void Invoke_should_return_alpha_when_the_branch_to_suffix_map_contains_an_asterick()
        {
            // Arrange
            var sut = new GetBranchSuffixCmdlet();

            // Act
            sut.BranchName = "random";
            var result1 = sut.Invoke<string>().ToArray()[0];

            // Assert
            result1.ShouldBe("alpha");
        }
    }
}