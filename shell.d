module shell;

import std.stdio;
import std.array;
import std.algorithm;

import unix;
import syntax;

class ProcessCallException : object.Exception {
  this(string msg) {
    super(msg);
  }
}

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

  @property string[] path() {
    return this["PATH"].split(":");
  }
  
  string opIndex(string k) {
    return vars[k];
  }

  void opIndexAssign(string v, string k) {
    vars[k] = v;
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
      runProcessCallExpr(pcexpr);
    } else {
      writeln("Syntax error");
    }
  }

  void runProcessCallExpr(ProcessCallExpr expr) {
    try {
      execProgram(expr.prog, expr.args.dup);
    } catch (ProcessCallException e) {
      writeln(e);
    }
  }
  
  byte execProgram(string prog, string[] args) {
    string progName = lookupExecutable(prog);
    Pid pid = fork();
    if (pid < 0) {
      writeln("Error forking");
      return -1;
    } else if (pid == 0) {
      sysExec(progName, [prog] ~ args, env.stringArray());
      writeln("Error execing");
      _exit(-1);
      assert(0);
    } else {
      return exitStatus(pid);
    }
  }

  string lookupExecutable(string prog) {
    if (prog.canFind('/')) {
      if (isExecutable(prog)) {
        return prog;
      } else {
        throw new ProcessCallException("Not allowed");
      }
    } else {
      string[] path = env.path;
      foreach (string folder; path) {
        string progName = folder ~ "/" ~ prog;
        if (isExecutable(progName)) {
          return progName;
        }
      }
      throw new ProcessCallException("Not found");
    }
  }
}