using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace Acklann.Buildbox.SemVer.Editors
{
    public sealed class DotNetProjectEditor : IProjectEditor
    {
        public FileInfo[] FindProjectFile(string solutionDirectory)
        {
            IEnumerable<FileInfo> assemblyFiles = from path in Directory.GetFiles(solutionDirectory, "*.csproj", SearchOption.AllDirectories)
                                                  let assemblyInfo = Path.Combine(Path.GetDirectoryName(path), "Properties", "AssemblyInfo.cs")
                                                  where File.Exists(assemblyInfo)
                                                  select new FileInfo(assemblyInfo);

            return assemblyFiles.ToArray();
        }

        public void Update(Manifest manifest, params FileInfo[] assemblyInfoFiles)
        {
            foreach (var file in assemblyInfoFiles.Where(x => x?.Exists ?? false))
            {
                string contents = File.ReadAllText(file.FullName);
                foreach (var arg in new(string Property, string Value)[] {
                    ( "Company", $"\"{manifest.Owner}\"" ),
                    ( "Description", $"\"{manifest.Description}\"" ),
                    ( "Copyright", $"\"{manifest.Copyright}\"" ),
                    ( "InformationalVersion", $"\"{manifest.Version}\"" ),
                    ( "FileVersion", $"\"{manifest.Version}\"" ),
                    ( "Version", $"\"{manifest.Version}\"" )})
                    if (!string.IsNullOrEmpty(arg.Value))
                    {
                        MatchCollection searchResults = new Regex(string.Format(@"Assembly{0}\s*\(\s*(?<value>.*)\s*\)", arg.Property)).Matches(contents);
                        if (searchResults.Count == 0)
                        {
                            contents = string.Concat(contents, Environment.NewLine, $"[assembly: Assembly{arg.Property}({arg.Value})]");
                        }
                        else foreach (Match match in searchResults)
                            {
                                Group v = match.Groups["value"];
                                contents = contents.Remove(v.Index, v.Length);
                                contents = contents.Insert(v.Index, arg.Value);
                            }
                    }

                File.WriteAllText(file.FullName, contents);
            }
        }
    }
}