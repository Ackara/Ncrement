using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text.RegularExpressions;

namespace Acklann.Ncrement
{
    public static class Git
    {
        public static string GetWorkingDirectory(string filePath)
        {
            if (!File.Exists(filePath)) throw new FileNotFoundException($"Could not find file at '{filePath}'.");

            string folder = filePath;

            do
            {
                folder = Path.GetDirectoryName(folder);
            } while (folder != null && Directory.Exists(Path.Combine(folder, ".git")) == false);

            return folder;
        }

        public static bool Stage(string filePath)
        {
            return Stage(filePath, GetWorkingDirectory(filePath));
        }

        public static bool Stage(string filePath, string repositoryPath)
        {
            if (!File.Exists(filePath)) throw new FileNotFoundException($"Could not find file at '{filePath}'.");

            return Invoke(repositoryPath, $"add \"{filePath}\"");
        }

        public static bool StageAll(string repositoryPath)
        {
            return Invoke(repositoryPath, "add --all");
        }

        public static bool Commit(string repositoryPath, string message)
        {
            if (string.IsNullOrEmpty(message)) throw new ArgumentNullException(nameof(message));

            return Invoke(repositoryPath, "commit -m \"{message}\"");
        }

        public static string GetCurrentBranchName(string repositoryPath)
        {
            Invoke(repositoryPath, "branch", out string output);
            Match match = Regex.Match(output, @"^\*\s(?<branch>.+)$", RegexOptions.Multiline);

            return match.Success ? match.Groups["branch"]?.Value.Trim() : null;
        }

        public static bool Invoke(string repositoryPath, string command)
        {
            return Invoke(repositoryPath, command, out string _);
        }

        public static void AddGitTokens(this IDictionary<string, string> map, string repositoryPath)
        {
            if (!Directory.Exists(repositoryPath)) throw new DirectoryNotFoundException($"Could not find directory at '{repositoryPath}'.");

            map["git-branch"] = GetCurrentBranchName(repositoryPath);
        }

        public static bool Invoke(string repositoryPath, string command, out string output)
        {
            var info = new ProcessStartInfo("git")
            {
                Arguments = command,

                CreateNoWindow = true,
                UseShellExecute = false,
                RedirectStandardError = true,
                RedirectStandardOutput = true,
                WorkingDirectory = repositoryPath,
            };

            using (var git = new Process() { StartInfo = info })
            {
                git.Start();
                git.WaitForExit();

                if (git.ExitCode == 0)
                {
                    output = git.StandardOutput.ReadToEnd();
                }
                else
                {
                    output = git.StandardError.ReadToEnd();
                    System.Diagnostics.Debug.WriteLine(output);
                }

                return git.ExitCode == 0;
            }
        }
    }
}