//
//  Tokenizer.swift
//  Chess
//
//  Created by Steve Wart on 2025-07-03.
//

import Foundation

enum TokenType {
  // Single-character tokens.
  case
  LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE,
  COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR,

  // One or two character tokens.
  BANG, BANG_EQUAL,
  EQUAL, EQUAL_EQUAL,
  GREATER, GREATER_EQUAL,
  LESS, LESS_EQUAL,

  // Literals.
  IDENTIFIER, STRING, NUMBER,

  // Keywords.
  AND, CLASS, ELSE, FALSE, FUN, FOR, IF, NIL, OR,
  PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE,

  EOF
}

struct Token {
  let type: TokenType
  let lexeme: String
  let literal: Any?
  let line: Int
  
  func toString() -> String {
    let literalValue = literal ?? "nil"
    return "\(type) \(lexeme) \(literalValue)"
  }
}

class Tokenizer {
  let source: String
  var tokens = [Token]()
  var start = 0
  var current = 0
  var line = 1
  
  let keywords: [String: TokenType] = [
    "and"    : .AND,
    "class"  : .CLASS,
    "else"   : .ELSE,
    "false"  : .FALSE,
    "for"    : .FOR,
    "fun"    : .FUN,
    "if"     : .IF,
    "nil"    : .NIL,
    "or"     : .OR,
    "print"  : .PRINT,
    "return" : .RETURN,
    "super"  : .SUPER,
    "this"   : .THIS,
    "true"   : .TRUE,
    "var"    : .VAR,
    "while"  : .WHILE,
  ]
  
  init(source: String) {
    self.source = source
  }
  
  func scanTokens() -> [Token] {
    while !isAtEnd() {
      // we are at the beginning of the next lexeme
      start = current
      scanToken()
    }
    tokens.append(Token(type: .EOF, lexeme: "", literal: nil, line: line))
    return tokens
  }
  
  private func isAtEnd() -> Bool {
    return current >= source.count
  }
  
  func scanToken() {
    let c = advance()
    switch c {
    case "(" : addToken(.LEFT_PAREN)
    case ")" : addToken(.RIGHT_PAREN)
    case "{" : addToken(.LEFT_BRACE)
    case "}" : addToken(.RIGHT_BRACE)
    case "," : addToken(.COMMA)
    case "." : addToken(.DOT)
    case "-" : addToken(.MINUS)
    case "+" : addToken(.PLUS)
    case ";" : addToken(.SEMICOLON)
    case "*" : addToken(.STAR)
    case "!":
      addToken(match("=") ? .BANG_EQUAL : .BANG)
    case "=" :
      addToken(match("=") ? .EQUAL_EQUAL : .EQUAL)
    case "<" :
      addToken(match("=") ? .LESS_EQUAL : .LESS)
    case ">" :
      addToken(match("=") ? .GREATER_EQUAL : .GREATER)
    case "/" :
      if match("/") {
        // a comment goes until the end of the line
        while peek() != "\n" && !isAtEnd() {
          _ = advance()
        }
      }
      else {
        addToken(.SLASH)
      }
    case " ", "\r", "\t" :
      // Ignore whitespace.
      break
    case "\n" :
      line += 1
      break
    case "\"" :
      string()
    default:
      if isDigit(c) {
        number()
      }
      else if isAlpha(c) {
        identifier()
      }
      else {
        ChessEngine.error(line: line, message: "Unexpected character.")
      }
    }
  }
  
  private func advance() -> Character {
    let result = source[source.index(source.startIndex, offsetBy: current)]
    current += 1
    return result
  }
  
  private func addToken(_ type: TokenType) {
    addToken(type:type, literal:nil)
  }
  
  private func addToken(type: TokenType, literal: Any?) {
    let startIndex = source.index(source.startIndex, offsetBy: start)
    let endIndex = source.index(source.startIndex, offsetBy: current)
    let text = source[startIndex ..< endIndex]
    let token = Token(type: type, lexeme: String(text), literal: literal, line: line)
    tokens.append(token)
  }
  
  private func match(_ expected: Character) -> Bool {
    if isAtEnd() {
      return false
    }
    if source[source.index(source.startIndex, offsetBy: current)] != expected {
      return false
    }
    current += 1
    return true
  }
  
  private func peek() -> Character {
    if isAtEnd() {
      return "\0"
    }
    return source[source.index(source.startIndex, offsetBy: current)]
  }
  
  private func peekNext() -> Character {
    if current + 1 >= source.count {
      return "\0"
    }
    return source[source.index(source.startIndex, offsetBy: current + 1)]
  }
  
  private func string() {
    while peek() != "\"" && !isAtEnd() {
      if peek() == "\n" {
        line += 1
      }
      _ = advance()
    }
    
    if isAtEnd() {
      ChessEngine.error(line: line, message: "Unterminated string.")
      return
    }
    
    // the closing "
    _ = advance()
    
    // Trim the surrounding quotes
    let startIndex = source.index(source.startIndex, offsetBy: 1)
    let endIndex = source.index(source.startIndex, offsetBy: current - 1)
    let value = source[startIndex..<endIndex]
    addToken(type: .STRING, literal: value)
  }
  
  private func identifier() {
    while isAlphaNumeric(peek()) {
      _ = advance()
    }
    
    let startIndex = source.index(source.startIndex, offsetBy: start)
    let endIndex = source.index(source.startIndex, offsetBy: current)
    let text = String(source[startIndex ..< endIndex])
    let type = keywords[text] ?? .IDENTIFIER
    addToken(type)
  }

  private func isDigit(_ c: Character) -> Bool {
    return c >= "0" && c <= "9"
  }
  
  private func isAlpha(_ c: Character) -> Bool {
    return (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || c == "_"
  }
  
  private func isAlphaNumeric(_ c: Character) -> Bool {
    return isAlpha(c) || isDigit(c)
  }
  
  private func number() {
    while isDigit(peek()) {
      _ = advance()
    }
    
    // Look for a fractional part
    if peek() == "." && isDigit(peekNext()) {
      // consume the "."
      _ = advance()
      
      while isDigit(peek()) {
        _ = advance()
      }
    }
    let startIndex = source.index(source.startIndex, offsetBy: start)
    let endIndex = source.index(source.startIndex, offsetBy: current)
    let text = String(source[startIndex ..< endIndex])
    let numberValue = Double(String(text))
    addToken(type: .NUMBER, literal: numberValue)
  }
  
}
