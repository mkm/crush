module syntax;

immutable class Expr {
  
}

class ProcessCallExpr : Expr {
  string prog;
  string[] args;

  this(immutable string prog, immutable string[] args) {
    this.prog = prog;
    this.args = args;
  }
}

Expr parseLine(string source) {
  Parser parser = new Parser(source);
  return parser.line();
}

class ParseException : object.Exception {
  this(string msg) {
    super(msg);
  }
}

private class Parser {
  private string source;
  private int pos;
  
  this(string source) {
    this.source = source;
    this.pos = 0;
  }
  
  Expr line() {
    immutable string prog = token();
    immutable string[] args = many(&entity);
    return new ProcessCallExpr(prog, args);
  }

  string entity() {
    int pos = this.pos;
    try {
      return quotedToken();
    } catch (ParseException e) {
      this.pos = pos;
      return token();
    }
  }
  
  string token() {
    many(&ws);
    string s = many1(&stdch);
    many(&ws);
    return s;
  }

  string quotedToken() {
    many(&ws);
    quote();
    string s = many(&nonquote);
    quote();
    many(&ws);
    return s;
  }

  char ws() {
    return ch(delegate(char c) { return c == '\n' || c == '\t' || c == ' '; });
  }

  char stdch() {
    return ch(delegate(char c) { return c > ' ' && c != '"'; });
  }

  char quote() {
    return ch(delegate(char c) { return c == '"'; });
  }

  char nonquote() {
    return ch(delegate(char c) { return c != '"'; });
  }

  char ch(bool delegate(char) pred) {
    char c = current();
    if (pred(c)) {
      advance();
      return c;
    } else {
      throw new ParseException("Unexpected character");
    }
  }
  
  immutable(T[]) many(T)(T delegate() p) {
    T[] a = new T[0];
    try {
      while (true) {
        T x = p();
        a ~= [x];
      }
    } catch (ParseException e) {
      return cast(immutable)a;
    }
  }

  immutable(T[]) many1(T)(T delegate() p) {
    T x = p();
    immutable T[] xs = many(p);
    return x ~ xs;
  }

  char current() {
    if (pos < source.length) {
      return source[pos];
    } else {
      throw  new ParseException("End of source");
    }
  }

  void advance() {
    pos += 1;
  }
}

