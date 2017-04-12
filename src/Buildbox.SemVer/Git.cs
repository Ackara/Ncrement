using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;

namespace Ackara.Buildbox.SemVer
{
    public class Git
    {
        public Git() : this("")
        {
        }

        public Git(string pathToRepository)
        {
            _repository = pathToRepository;
        }

        public static bool TryGetSystemGitExe(out string gitEXE)
        {
            string installationDir = (
                from path in Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.Process).Split(';')
                where path.EndsWith(@"Git\cmd")
                select path).FirstOrDefault();

            gitEXE = Path.Combine((installationDir ?? ""), "git.exe");
            return File.Exists(gitEXE);
        }

        public static bool GitRepositoryExist(string path)
        {
            return Directory.Exists(path);
        }

        public static bool FindGitRepository(out DirectoryInfo directory)
        {
            string repo;
            directory = null;

            if (foundGitRepoIn(Environment.CurrentDirectory, out repo))
            {
                directory = new DirectoryInfo(repo);
                return true;
            }
            else if (foundGitRepoIn(Assembly.GetExecutingAssembly().Location, out repo))
            {
                directory = new DirectoryInfo(repo);
                return true;
            }
            else return false;

            bool foundGitRepoIn(string path, out string result)
            {
                bool noMatchFound = true;
                if (!string.IsNullOrEmpty(path))
                    do
                    {
                        string git = Path.Combine(path, ".git");
                        noMatchFound = (Directory.Exists(git) == false);
                        if (noMatchFound) path = Path.GetDirectoryName(path);
                    } while (noMatchFound);

                result = path;
                return !noMatchFound;
            }
        }

        public static string Execute(string command, string repository)
        {
            string git, output = null, error = null;
            if (TryGetSystemGitExe(out git) && Directory.Exists(repository))
            {
                var args = new ProcessStartInfo()
                {
                    FileName = git,
                    Arguments = command,
                    WorkingDirectory = repository,

                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardError = true,
                    RedirectStandardOutput = true,
                };

                using (var proc = new Process() { StartInfo = args })
                {
                    proc.Start();
                    proc.WaitForExit((int)new TimeSpan(0, 0, 30).TotalMilliseconds);

                    output = proc.StandardOutput.ReadToEnd().Trim();
                    error = proc.StandardError.ReadToEnd().Trim();
                    Debug.WriteLine(error);
                }
            }
            return string.IsNullOrWhiteSpace(output) ? error : output;
        }

        public void CreateTag(string name)
        {
            Execute($"tag \"{name}\"", _repository);
        }

        public string GetCurrentBranch()
        {
            string output = Execute("branch", _repository);
            var match = Regex.Match(output, @"\*\s+(?<branch>\w+)");

            if (match.Success)
                return match.Groups["branch"].Value;
            else
                return string.Empty;
        }

        public void Add()
        {
            Execute("add .", _repository);
        }

        public void Add(params string[] fullPaths)
        {
            foreach (var path in fullPaths)
            {
                string relativePath = path.Remove(0, _repository.Length).TrimStart('\\');
                Execute($"add {relativePath}", _repository);
            }
        }

        public void Commit(string message)
        {
            message = Regex.Replace(message, "\"", "\\\"");
            Execute($"commit \"-m{message}\"", _repository);
        }

        #region Private Members

        private readonly string _repository;

        #endregion Private Members
    }
}