module shell;

import std.stdio;

import unix;
import syntax;

class Environment {
  private string[string] vars;

  private this(string[string] vars) {
    this.vars = vars;
  }

  string[] stringArray() {
    string[] x;
    foreach (string k, string v; vars) {
      x ~= (k ~ "=" ~ v);
    }
    return x;
  }
  
  static Environment standardEnvironment() {
    return new Environment(retrieveEnviron());
  }
}

class Shell {
  private Environment env;

  this(Environment env) {
    this.env = env;
  }
  
  void runCommand(string cmd) {
    Expr expr = parseLine(cmd);
    if (auto pcexpr = cast(ProcessCallExpr)expr) {
      execProgram(pcexpr.prog, pcexpr.args.dup);
    } else {
      writeln("Syntax error");
    }
  }

  byte execProgram(string prog, string[] args) {
    Pid pid = fork();
    if (pid < 0) {
      writeln("Error forking");
      return -1;
    } else if (pid == 0) {
      sysExec(prog, [prog] ~ args, env.stringArray());
      writeln("Error execing");
      _exit(-1);
      return -1;
    } else {
      return exitStatus(pid);
    }
  }
}