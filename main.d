module main;

import std.stdio;
import std.getopt;

import repl;
import cconv;
import shell;

int main(string[] args) {
  getopt(args);
  args = args[1 .. $];
  Shell sh = new Shell(Environment.standardEnvironment());
  sh.executeRunCommands(".crushrc");
  if (args.length >= 1) {
    runBatch(sh, args[0], args[1 .. $]);
  } else {
    replMain(sh);
  }
  return 0;
}

void runBatch(Shell sh, string filename, string[] args) {
  sh.runFile(filename, args);
}
