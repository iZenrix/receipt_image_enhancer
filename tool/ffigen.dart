import 'dart:io';

Future<void> main() async {
  final result = await Process.run(
    'dart',
    ['run', 'ffigen', '--config', 'ffigen.yaml'],
    workingDirectory: Directory.current.path,
    runInShell: true,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}
