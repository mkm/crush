module syntax;

import std.array;

immutable class ProcessCall {
  string prog;
  string[] args;

  this(immutable string prog, immutable string[] args) {
    this.prog = prog;
    this.args = args;
  }
}

immutable class Expr {
  
}

class ProcessCallExpr : Expr {
  string command;

  this(immutable string command) {
    this.command = command;
  }
}

class ScriptExpr : Expr {
  Expr content;

  this(Expr content) {
    this.content = content;
  }
}

class SequenceExpr : Expr {
  Expr[] sequence;

  this(immutable Expr[] sequence) {
    this.sequence = sequence;
  }
}

class StringLiteralExpr : Expr {
  string value;

  this(string value) {
    this.value = value;
  }
}

class AssignmentExpr : Expr {
  string name;
  Expr expr;

  this(immutable string name, immutable Expr expr) {
    this.name = name;
    this.expr = expr;
  }
}

class VariableExpr : Expr {
  string name;

  this(immutable string name) {
    this.name = name;
  }
}

ProcessCall parseLine(string source) {
  LineParser parser = new LineParser(source);
  return parser.parse();
}

ScriptExpr parseScript(string source) {
  ScriptParser parser = new ScriptParser(source);
  return parser.parse();
}

class ParseException : object.Exception {
  this(string msg) {
    super(msg);
  }
}

mixin template Parser(T) {
  private immutable(T)[] source;
  private int pos;
  
  bool eos() {
    return pos >= source.length;
  }
  
  immutable(T) current() {
    if (eos()) {
      throw new ParseException("End of source");
    } else {
      return source[pos];
    }
  }
  
  void advance() {
    pos += 1;
  }

  void end() {
    if (!eos()) {
      throw new ParseException("Expected end of source");
    }
  }
}

private class LineParser {
  mixin Parser!(immutable(char));
  
  this(string source) {
    this.source = source;
    this.pos = 0;
  }

  ProcessCall parse() {
    immutable string[] words = source.split(" ").idup;
    if (words.length == 0) {
      throw new ParseException("No words in command");
    }
    return new ProcessCall(words[0], words[1 .. $]);
  }
}

private class ScriptParser {
  mixin Parser!(Token);
  
  this(string source) {
    this.source = lex(source);
    this.pos = 0;
  }

  ScriptExpr parse() {
    return script();
  }
  
  ScriptExpr script() {
    ScriptExpr expr = new ScriptExpr(sequence());
    end();
    return expr;
  }

  SequenceExpr sequence() {
    return new SequenceExpr(many(&stmt));
  }

  Expr stmt() {
    Expr expr = expr();
    semicolon();
    return expr;
  }

  Expr expr() {
    return either([cast(Expr delegate())preserving(cast(Expr delegate())&assignment), cast(Expr delegate())&stringLiteral, cast(Expr delegate())&processCall, cast(Expr delegate())&variable]);
  }

  ProcessCallExpr processCall() {
    atsign();
    return new ProcessCallExpr(stringLiteral().value);
  }

  AssignmentExpr assignment() {
    string name = word();
    equal();
    Expr expr = expr();
    return new AssignmentExpr(name, expr);
  }

  VariableExpr variable() {
    string name = word();
    return new VariableExpr(name);
  }
  
  StringLiteralExpr stringLiteral() {
    if (auto token = cast(StringLiteralToken)current()) {
      advance();
      return new StringLiteralExpr(token.value);
    } else {
      throw new ParseException("Expected string literal");
    }
  }
  
  string word() {
    if (auto token = cast(WordToken)current()) {
      advance();
      return token.value;
    } else {
      throw new ParseException("Expected word");
    }
  }

  void semicolon() {
    if (cast(SemicolonToken)current()) {
      advance();
    } else {
      throw new ParseException("Expected semicoloon");
    }
  }

  void atsign() {
    if (cast(AtsignToken)current()) {
      advance();
    } else {
      throw new ParseException("Expected atsign");
    }
  }

  void equal() {
    if (cast(EqualToken)current()) {
      advance();
    } else {
      throw new ParseException("Expected equal");
    }
  }

  Expr either(Expr delegate()[] ps) {
    if (ps.length == 0) {
      throw new ParseException("Alternatives exhausted");
    } else {
      try {
        return ps[0]();
      } catch (ParseException e) {
        return either(ps[1 .. $]);
      }
    }
  }

  Expr delegate() preserving(Expr delegate() p) {
    return delegate() {
      int oldPos = pos;
      try {
        return p();
      } catch (ParseException e) {
        pos = oldPos;
        throw e;
      }
    };
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
}

immutable class Token {

};

class AtsignToken : Token {

}

class SemicolonToken : Token {

}

class EqualToken : Token {
  
}

class WordToken : Token {
  string value;

  this(string value) {
    this.value = value;
  }
}

class StringLiteralToken : Token {
  string value;

  this(string value) {
    this.value = value;
  }
}

immutable(Token)[] lex(string source) {
  Lexer lexer = new Lexer(source);
  return lexer.lex();
}

private class Lexer {
  mixin Parser!(immutable(char));
  
  private Token[] tokens;

  this(string source) {
    this.source = source;
    this.pos = 0;
    this.tokens = [];
  }

  immutable(Token)[] lex() {
    while (!eos()) {
      char c = current();
      if (isAlpha(c)) {
        word();
      } else if (c == '@') {
        tokens ~= [new AtsignToken()];
        advance();
      } else if (c == ';') {
        tokens ~= [new SemicolonToken()];
        advance();
      } else if (c == '=') {
        tokens ~= [new EqualToken()];
        advance();
      } else if (c == '"') {
        stringLiteral();
      } else if (isWhite(c)) {
        advance();
      } else {
        throw new ParseException("Unknown character");
      }
    }
    return cast(immutable(Token)[])tokens;
  }

  void word() {
    char c;
    string s;
    do {
      s ~= [current()];
      advance();
      c = current();
    } while (isAlpha(c));
    tokens ~= [new WordToken(s)];
  }

  void stringLiteral() {
    char c;
    string s;
    advance(); // Skip start quote
    c = current();
    while (c != '"') {
      s ~= [c];
      advance();
      c = current();
    }
    advance(); // Skip end quote
    tokens ~= [new StringLiteralToken(s)];
  }
  
  bool isAlpha(char c) {
    return ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || c == '_';
  }

  bool isWhite(char c) {
    return c == ' ' || c == '\n' || c == '\t';
  }
}
