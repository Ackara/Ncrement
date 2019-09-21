using System.Linq;
using System.Text;

namespace Acklann.Ncrement
{
    public static class Helper
    {
        public static StringBuilder AppendHeader(this StringBuilder builder, string name)
        {
            return builder
                .AppendLine($"# {name}")
                .AppendLine(string.Concat(Enumerable.Repeat('#', 50)))
                .AppendLine();
        }
    }
}