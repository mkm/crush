module repl;

import std.stdio;

import readline;
import shell;

void replMain() {
  Shell sh = new Shell(Environment.standardEnvironment());
  try {
    while (true) {
      string s;
      s = readLine();
      if (s != "") {
        sh.runCommand(s);
      }
    }
  } catch (EOFLineException e) {
    writeln("");
  }
}