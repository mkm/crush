module readline;

import std.c.stdlib;

import cconv;

extern (C) {
  char* readline(const char*);
}

class EOFLineException : object.Exception {
  this() {
    super("EOF encountered.");
  }
}

string readLine() {
  char* cs = readline("crush> ");
  try {
    string s = stringFromCString(cs);
    free(cs);
    return s;
  } catch (CConvException e) {
    throw new EOFLineException();
  }
}
