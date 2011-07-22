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
    immutable string[] args = many(&token);
    return new ProcessCallExpr(prog, args);
  }

  string token() {
    many(&ws);
    string s = many1(&nonws);
    many(&ws);
    return s;
  }

  char ws() {
    char c = current();
    if (c == '\n' || c == '\t' || c == ' ') {
      advance();
      return c;
    } else {
      throw new ParseException("Expected whitespace");
    }
  }

  char nonws() {
    char c = current();
    if (c != '\n' && c != '\n' && c != ' ') {
      advance();
      return c;
    } else {
      throw new ParseException("Expected non-whitespace");
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

