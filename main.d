module main;

import std.stdio;
import std.getopt;

import repl;
import cconv;
import shell;

int main(string[] args) {
  getopt(args);
  args = args[1 .. $];
  if (args.length >= 1) {
    runBatch(args[0], args[1 .. $]);
  } else {
    replMain();
  }
  return 0;
}

void runBatch(string filename, string[] args) {
  Shell sh = new Shell(Environment.standardEnvironment());
  sh.runFile(filename, args);
}
