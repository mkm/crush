module cconv;

import std.c.stdlib;

class CConvException : object.Exception {
  this() {
    super("Could not convert stuff.");
  }
}

char* cstringFromString(string s) {
  char* cs = cast(char*)malloc(s.length + 1);
  int i;
  for (i = 0; i < s.length; i++) {
    cs[i] = s[i];
  }
  cs[i] = '\0';
  return cs;
}

string stringFromCString(const char* cs) {
  if (cs == null) {
    throw new CConvException();
  }
  string s;
  for (int i = 0; cs[i] != '\0'; i++) {
    s ~= [cs[i]];
  }  
  return s;
}

T* carrayFromArray(T)(T[] a) {
  T* ca = cast(T*)malloc((a.length + 1) * T.sizeof);
  int i;
  for (i = 0; i < a.length; i++) {
    ca[i] = a[i];
  }
  ca[i] = T.init;
  return ca;
}

T[] arrayFromCArray(T)(T* ca) {
  if (ca == null) {
    throw new CConvException();
  }
  T[] a;
  for (int i = 0; ca[i] != T.init; i++) {
    a ~= [ca[i]];
  }
  return a;
}
