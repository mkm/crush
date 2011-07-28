module shell;

import std.stdio;
import std.array;
import std.algorithm;
import std.file;

import unix;
import syntax;

class ProcessCallException : object.Exception {
  this(string msg) {
    super(msg);
  }
}

class Path {
  private immutable string[] components;
  private immutable bool absolute;
  private immutable int backtraces;
  
  this(string pathString) {
    this(pathString.split("/"));
  }

  this(const(string)[] components) {
    string[] selfComponents;
    bool selfAbsolute = false;
    int selfBacktraces = 0;
    if (components.length >= 1 && components[0] == "") {
      selfAbsolute = true;
      components = components[1 .. $];
    }
    foreach (string component; components) {
      if (component == "..") {
        if (selfComponents.length >= 1) {
          selfComponents = selfComponents[0 .. $ - 1];
        } else if (!selfAbsolute) {
          selfBacktraces += 1;
        }
      } else if (component != "" && component != ".") {
        selfComponents ~= component;
      }
    }
    this(cast(immutable)selfComponents, selfAbsolute, selfBacktraces);
  }

  private this(immutable string[] components, bool absolute, int backtraces) {
    this.components = components;
    this.absolute = absolute;
    this.backtraces = backtraces;
  }

  Path opBinary(string op)(Path other) if (op == "~") {
    return Path.combine(this, other);
  }

  string toString() {
    string result;
    if (absolute) {
      result = "/";
    }
    if (components.length >= 1) {
      result ~= components[0];
      foreach (string component; components[1 .. $]) {
        result ~= "/" ~ component;
      }
    }
    return result;
  }
  
  static Path combine(Path a, Path b) {
    if (b.absolute) {
      return b;
    } else {
      immutable(string)[] x = a.components;
      immutable(string)[] y = b.components;
      int backtraces = a.backtraces;
      for (int i = 0; i < b.backtraces; i++) {
        if (x.length >= 1) {
          x = x[0 .. $ - 1];
        } else {
          backtraces += 1;
        }
      }
      return new Path(cast(immutable)x ~ cast(immutable)y, a.absolute, backtraces);
    }
  }
}

class Environment {
  private string[string] vars;
  private Path _cwd;

  private this(string[string] vars) {
    this.vars = vars;
    this._cwd = new Path(currentWorkingDir());
  }

  string[] toStringArray() {
    string[] x;
    foreach (string k, string v; vars) {
      x ~= (k ~ "=" ~ v);
    }
    return x;
  }

  @property string[] execPath() {
    return get("PATH", "").split(":");
  }

  @property Path cwd() {
    return _cwd;
  }

  @property Path home() {
    return new Path(get("HOME", "/"));
  }
  
  void changeWorkDir(Path path) {
    _cwd = _cwd ~ path;
  }
  
  string opIndex(string k) {
    return vars[k];
  }

  string get(string k, lazy string def) {
    return vars.get(k, def);
  }

  void opIndexAssign(string v, string k) {
    vars[k] = v;
  }
  
  static Environment standardEnvironment() {
    return new Environment(retrieveEnviron());
  }
}

interface Value {
  StringValue toStringValue();
}

class StringValue : Value {
  immutable string value;

  this(immutable string value) {
    this.value = value;
  }

  StringValue toStringValue() {
    return this;
  }
}

class NullValue : Value {
  StringValue toStringValue() {
    return new StringValue("null");
  }
}

class Shell {
  private Environment env;
  private BuiltinAction[string] builtins;
  private Value[string] vars;

  this(Environment env) {
    this.env = env;
    builtins["cd"] = new ChangeDirAction();
  }
  
  void runCommand(string cmd) {
    runExpr(new ProcessCallExpr(cmd));
  }

  void runFile(string filename, string[] args) {
    string content = readText(filename);
    Expr expr = parseScript(content);
    runExpr(expr);
  }

  void executeRunCommands(string rcfilename) {
    try {
      runFile(env.home.toString() ~ "/" ~ rcfilename, []);
    } catch (FileException e) {
      
    }
  }

  Value runExpr(Expr expr) {
    if (auto x = cast(ProcessCallExpr)expr) {
      return runProcessCallExpr(x);
    } else if (auto x = cast(SequenceExpr)expr) {
      return runSequenceExpr(x);
    } else if (auto x = cast(ScriptExpr)expr) {
      return runScriptExpr(x);
    } else if (auto x = cast(StringLiteralExpr)expr) {
      return new StringValue(x.value);
    } else {
      writeln("Unknown expression");
      return new NullValue();
    }
  }
  
  Value runProcessCallExpr(ProcessCallExpr expr) {
    ProcessCall call = parseLine(expr.command);
    try {
      Action action = lookupAction(call.prog);
      action.act(this, ([call.prog] ~ call.args).dup);
    } catch (ProcessCallException e) {
      writeln(e);
    }
    return new NullValue();
  }

  Value runSequenceExpr(SequenceExpr expr) {
    Value value = new NullValue();
    foreach (x; expr.sequence) {
      value = runExpr(x);
    }
    return value;
  }
  
  Value runScriptExpr(ScriptExpr expr) {
    return runExpr(expr.content);
  }
  
  byte execProgram(string prog, string[] args) {
    Pid pid = fork();
    if (pid < 0) {
      writeln("Error forking");
      return -1;
    } else if (pid == 0) {
      changeWorkingDir(env.cwd.toString());
      sysExec(prog, args, env.toStringArray());
      writeln("Error execing");
      _exit(-1);
      assert(0);
    } else {
      return exitStatus(pid);
    }
  }

  Action lookupAction(string prog) {
    if (prog in builtins) {
      return builtins[prog];
    } else if (prog.canFind('/')) {
      if (isExecutable(prog)) {
        return new ProcessCallAction(prog);
      } else {
        throw new ProcessCallException("Not allowed");
      }
    } else {
      string[] execPath = env.execPath;
      foreach (string folder; execPath) {
        string progName = folder ~ "/" ~ prog;
        if (isExecutable(progName)) {
          return new ProcessCallAction(progName);
        }
      }
      throw new ProcessCallException("Not found");
    }
  }

  @property string prompt() {
    string promptSpec = vars.get("_prompt", new StringValue("%$ ")).toStringValue().value;
    string prompt = "";
    foreach (char c; promptSpec) {
      if (c == '%') {
        prompt ~= env.cwd.toString();
      } else {
        prompt ~= [c];
      }
    }
    return prompt;
  }
}

interface Action {
  void act(Shell, string[]);
}

class ProcessCallAction : Action {
  private string prog;

  this(string prog) {
    this.prog = prog;
  }

  void act(Shell sh, string[] args) {
    sh.execProgram(prog, args);
  }
}

interface BuiltinAction : Action {
  
}

class ChangeDirAction : BuiltinAction {
  void act(Shell sh, string[] args) {
    if (args.length < 2) {
      args.length = 2;
      args[1] = ".";
    }
    sh.env.changeWorkDir(new Path(args[1]));
  }
}
