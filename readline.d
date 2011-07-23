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

string readLine(string prompt) {
  char* cprompt = cstringFromString(prompt);
  char* cs = readline(cprompt);
  free(cprompt);
  try {
    string s = stringFromCString(cs);
    free(cs);
    return s;
  } catch (CConvException e) {
    throw new EOFLineException();
  }
}
