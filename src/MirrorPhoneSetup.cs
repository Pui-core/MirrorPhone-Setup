using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Reflection;

namespace MirrorPhoneSetup
{
    internal static class Program
    {
        private const string SourceRepo = "Pui-core/mirrorPhone";
        private const string SourceRef = "main";
        private const string SourceResourceName = "MirrorPhoneSource.zip";
        private const string Version = "0.2.3-update-install";

        private static int Main(string[] args)
        {
            try
            {
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
                WriteStep("MirrorPhone-Setup " + Version);
                Install();
                WriteStep("Install complete.");
                Console.WriteLine("Run mirrorPhone from the desktop or Start Menu shortcut.");
                PauseIfInteractive();
                return 0;
            }
            catch (Exception error)
            {
                Console.Error.WriteLine();
                Console.Error.WriteLine("[MirrorPhone-Setup] ERROR: " + error.Message);
                PauseIfInteractive();
                return 1;
            }
        }

        private static void Install()
        {
            if (!Environment.Is64BitOperatingSystem)
            {
                throw new InvalidOperationException("mirrorPhone requires 64-bit Windows.");
            }

            var installRoot = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Programs",
                "MirrorPhone"
            );
            var markerPath = Path.Combine(installRoot, ".mirrorphone-install");
            var tempRoot = Path.Combine(Path.GetTempPath(), "MirrorPhone-Setup-" + Guid.NewGuid().ToString("N"));
            var zipPath = Path.Combine(tempRoot, "mirrorPhone.zip");

            WriteStep("Source: embedded " + SourceRepo + "@" + SourceRef);
            WriteStep("Install root: " + installRoot);
            EnsureNodeAndNpm();

            var installMode = GetInstallMode(installRoot, markerPath);

            Directory.CreateDirectory(tempRoot);

            try
            {
                WriteStep("Writing embedded mirrorPhone source...");
                WriteEmbeddedSourceZip(zipPath);

                WriteStep("Extracting source...");
                ZipFile.ExtractToDirectory(zipPath, tempRoot);

                var sourceDir = FindExtractedSourceDirectory(tempRoot);

                if (Directory.Exists(installRoot))
                {
                    WriteStep(File.Exists(markerPath)
                        ? "Updating previous MirrorPhone install..."
                        : "Existing MirrorPhone folder found. Adopting it as an update target...");
                    PrepareInstallRootForUpdate(installRoot);
                }

                WriteStep("Copying files...");
                Directory.CreateDirectory(Path.GetDirectoryName(installRoot));
                CopyDirectory(sourceDir, installRoot);

                File.WriteAllLines(markerPath, new[]
                {
                    "repo=" + SourceRepo,
                    "ref=" + SourceRef,
                    "source=embedded",
                    "mode=" + installMode,
                    "installer=" + Version,
                    "installedAt=" + DateTimeOffset.Now.ToString("o")
                });

                WriteStep("Installing npm dependencies...");
                Run("cmd.exe", "/c npm install", installRoot, GetPathWithNode());

                EnsureAirPlayEngine(installRoot);

                var launcher = Path.Combine(installRoot, "start-mirrorPhone.bat");
                if (!File.Exists(launcher))
                {
                    throw new FileNotFoundException("Launcher was not found after install.", launcher);
                }

                WriteStep("Creating shortcuts...");
                CreateShortcuts(installRoot, launcher);
            }
            finally
            {
                TryDeleteDirectory(tempRoot);
            }
        }

        private static string GetInstallMode(string installRoot, string markerPath)
        {
            if (!Directory.Exists(installRoot))
            {
                return "install";
            }

            return File.Exists(markerPath) ? "update" : "adopt-update";
        }

        private static void PrepareInstallRootForUpdate(string installRoot)
        {
            var sourceDirectories = new[] { "ios", "scripts", "src", "test" };
            var sourceFiles = new[]
            {
                ".gitignore",
                "README.md",
                "package.json",
                "package-lock.json",
                "start-mirrorPhone.bat",
                "start-mirrorPhone.ps1"
            };

            foreach (var directory in sourceDirectories)
            {
                var path = Path.Combine(installRoot, directory);
                if (Directory.Exists(path))
                {
                    Directory.Delete(path, true);
                }
            }

            foreach (var file in sourceFiles)
            {
                var path = Path.Combine(installRoot, file);
                if (File.Exists(path))
                {
                    File.Delete(path);
                }
            }
        }

        private static void EnsureAirPlayEngine(string installRoot)
        {
            var packageJson = Path.Combine(installRoot, "package.json");
            if (!File.Exists(packageJson))
            {
                return;
            }

            var packageJsonText = File.ReadAllText(packageJson);
            if (packageJsonText.IndexOf("\"setup:airplay\"", StringComparison.OrdinalIgnoreCase) < 0)
            {
                return;
            }

            WriteStep("Installing AirPlay receiver engine...");
            Run("cmd.exe", "/c npm run setup:airplay", installRoot, GetPathWithNode());
        }

        private static void WriteEmbeddedSourceZip(string zipPath)
        {
            using (var resource = Assembly.GetExecutingAssembly().GetManifestResourceStream(SourceResourceName))
            {
                if (resource == null)
                {
                    throw new InvalidOperationException("Embedded mirrorPhone source was not found: " + SourceResourceName);
                }

                using (var output = File.Create(zipPath))
                {
                    resource.CopyTo(output);
                }
            }
        }

        private static void EnsureNodeAndNpm()
        {
            if (FindCommand("node.exe") != null && FindCommand("npm.cmd") != null)
            {
                WriteStep("Node.js/npm found.");
                return;
            }

            WriteStep("Node.js/npm not found. Installing Node.js LTS with winget...");

            if (FindCommand("winget.exe") == null)
            {
                throw new InvalidOperationException(
                    "Node.js LTS is required, and winget was not found. Install Node.js LTS from https://nodejs.org/ and run this setup again."
                );
            }

            Run(
                "winget.exe",
                "install --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements",
                Environment.CurrentDirectory,
                null
            );

            if (FindCommand("node.exe") == null || FindCommand("npm.cmd") == null)
            {
                var nodeDir = GetCommonNodeDirectory();
                if (nodeDir == null)
                {
                    throw new InvalidOperationException("Node.js install finished, but node/npm were not found. Restart Windows and run this setup again.");
                }
            }

            WriteStep("Node.js/npm ready.");
        }

        private static string GetCommonNodeDirectory()
        {
            var candidates = new[]
            {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "nodejs"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "nodejs")
            };

            foreach (var candidate in candidates)
            {
                if (File.Exists(Path.Combine(candidate, "node.exe")) && File.Exists(Path.Combine(candidate, "npm.cmd")))
                {
                    return candidate;
                }
            }

            return null;
        }

        private static string GetPathWithNode()
        {
            var nodeDir = GetCommonNodeDirectory();
            if (nodeDir == null)
            {
                return null;
            }

            return nodeDir + ";" + Environment.GetEnvironmentVariable("PATH");
        }

        private static string FindCommand(string command)
        {
            var result = RunCapture("cmd.exe", "/c where " + command, Environment.CurrentDirectory);
            if (result.ExitCode != 0)
            {
                var commonNodeDir = GetCommonNodeDirectory();
                if (commonNodeDir != null)
                {
                    var candidate = Path.Combine(commonNodeDir, command);
                    if (File.Exists(candidate))
                    {
                        return candidate;
                    }
                }

                return null;
            }

            using (var reader = new StringReader(result.Output))
            {
                return reader.ReadLine();
            }
        }

        private static string FindExtractedSourceDirectory(string tempRoot)
        {
            var directories = Directory.GetDirectories(tempRoot);
            if (directories.Length == 1)
            {
                return directories[0];
            }

            foreach (var directory in Directory.GetDirectories(tempRoot))
            {
                var name = Path.GetFileName(directory);
                if (name.StartsWith("mirrorPhone-", StringComparison.OrdinalIgnoreCase) ||
                    name.StartsWith("mirrorphone-", StringComparison.OrdinalIgnoreCase))
                {
                    return directory;
                }
            }

            throw new InvalidOperationException("Could not find extracted mirrorPhone source directory.");
        }

        private static void CopyDirectory(string sourceDir, string destinationDir)
        {
            Directory.CreateDirectory(destinationDir);

            foreach (var file in Directory.GetFiles(sourceDir))
            {
                File.Copy(file, Path.Combine(destinationDir, Path.GetFileName(file)), true);
            }

            foreach (var directory in Directory.GetDirectories(sourceDir))
            {
                CopyDirectory(directory, Path.Combine(destinationDir, Path.GetFileName(directory)));
            }
        }

        private static void CreateShortcuts(string installRoot, string launcher)
        {
            var desktopLink = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),
                "mirrorPhone.lnk"
            );
            var startMenuDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.Programs),
                "mirrorPhone"
            );
            var startMenuLink = Path.Combine(startMenuDir, "mirrorPhone.lnk");
            var iconPath = Path.Combine(installRoot, "node_modules", "electron", "dist", "electron.exe");

            Directory.CreateDirectory(startMenuDir);
            CreateShortcut(desktopLink, launcher, installRoot, iconPath);
            CreateShortcut(startMenuLink, launcher, installRoot, iconPath);
        }

        private static void CreateShortcut(string linkPath, string targetPath, string workingDirectory, string iconPath)
        {
            var shellType = Type.GetTypeFromProgID("WScript.Shell");
            if (shellType == null)
            {
                throw new InvalidOperationException("WScript.Shell is not available.");
            }

            var shell = Activator.CreateInstance(shellType);
            var shortcut = shellType.InvokeMember(
                "CreateShortcut",
                BindingFlags.InvokeMethod,
                null,
                shell,
                new object[] { linkPath }
            );
            var shortcutType = shortcut.GetType();

            shortcutType.InvokeMember("TargetPath", BindingFlags.SetProperty, null, shortcut, new object[] { targetPath });
            shortcutType.InvokeMember("WorkingDirectory", BindingFlags.SetProperty, null, shortcut, new object[] { workingDirectory });

            if (File.Exists(iconPath))
            {
                shortcutType.InvokeMember("IconLocation", BindingFlags.SetProperty, null, shortcut, new object[] { iconPath });
            }

            shortcutType.InvokeMember("Save", BindingFlags.InvokeMethod, null, shortcut, null);
        }

        private static void Run(string fileName, string arguments, string workingDirectory, string pathOverride)
        {
            var result = RunCapture(fileName, arguments, workingDirectory, pathOverride);
            if (result.ExitCode != 0)
            {
                throw new InvalidOperationException(fileName + " failed with exit code " + result.ExitCode + "." + Environment.NewLine + result.Output);
            }
        }

        private static ProcessResult RunCapture(string fileName, string arguments, string workingDirectory)
        {
            return RunCapture(fileName, arguments, workingDirectory, null);
        }

        private static ProcessResult RunCapture(string fileName, string arguments, string workingDirectory, string pathOverride)
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = fileName,
                Arguments = arguments,
                WorkingDirectory = workingDirectory,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = false
            };

            if (!string.IsNullOrWhiteSpace(pathOverride))
            {
                startInfo.EnvironmentVariables["PATH"] = pathOverride;
            }

            using (var process = Process.Start(startInfo))
            {
                var output = process.StandardOutput.ReadToEnd() + process.StandardError.ReadToEnd();
                process.WaitForExit();
                Console.Write(output);
                return new ProcessResult(process.ExitCode, output);
            }
        }

        private static void TryDeleteDirectory(string path)
        {
            try
            {
                if (Directory.Exists(path))
                {
                    Directory.Delete(path, true);
                }
            }
            catch
            {
                // Temporary cleanup failure should not hide the install result.
            }
        }

        private static void WriteStep(string message)
        {
            Console.WriteLine("[MirrorPhone-Setup] " + message);
        }

        private static void PauseIfInteractive()
        {
            if (!Console.IsInputRedirected)
            {
                Console.WriteLine();
                Console.Write("Press Enter to exit...");
                Console.ReadLine();
            }
        }

        private sealed class ProcessResult
        {
            public ProcessResult(int exitCode, string output)
            {
                ExitCode = exitCode;
                Output = output;
            }

            public int ExitCode { get; private set; }
            public string Output { get; private set; }
        }
    }
}
