module unix;

import std.array;
import std.c.stdlib;

import cconv;

alias int Pid;

extern (C) {
  Pid fork();
  void _exit(int);
  int execve(char*, char**, char**);
  char* get_current_dir_name();
  int chdir(const char*);

  byte exitStatus(Pid);
  int accessExecute(const char*);
  char** getEnviron();
}

Pid sysFork() {
  return fork();
}

int sysExec(string prog, string[] args, string[] env) {
  char* cprog = cstringFromString(prog);
  char*[] cargs = new char*[args.length];
  for (int i = 0; i < args.length; i++) {
    cargs[i] = cstringFromString(args[i]);
  }
  char*[] cenv = new char*[env.length];
  for (int i = 0; i < env.length; i++) {
    cenv[i] = cstringFromString(env[i]);
  }
  char** ccargs = carrayFromArray(cargs);
  char** ccenv = carrayFromArray(cenv);
  int ret = execve(cprog, ccargs, ccenv);
  for (int i = 0; i < args.length; i++) {
    free(cargs[i]);
  }
  free(ccargs);
  for (int i = 0; i < env.length; i++) {
    free(cenv[i]);
  }
  free(ccenv);
  return ret;
}

bool isExecutable(string path) {
  char* cpath = cstringFromString(path);
  int ret = accessExecute(cpath);
  free(cpath);
  return ret == 0;
}

string[string] retrieveEnviron() {
  char** environ = getEnviron();
  string[string] env;
  for (int i = 0; environ[i] != null; i++) {
    string[] varSpec = stringFromCString(environ[i]).split("=");
    if (varSpec.length == 2) {
      env[varSpec[0]] = varSpec[1];
    }
  }
  return env;
}

string currentWorkingDir() {
  char* cdir = get_current_dir_name();
  string dir = stringFromCString(cdir);
  free(cdir);
  return dir;
}

void changeWorkingDir(string dir) {
  char* cdir = cstringFromString(dir);
  chdir(cdir);
  free(cdir);
}
