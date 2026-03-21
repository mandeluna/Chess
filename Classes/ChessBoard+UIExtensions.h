//
//  ChessBoard+UIExtensions.h
//  Chess
//
//  Declares Swift extension methods on ChessBoard for use in UI targets (Shaman/Shambolic).
//  The implementations are provided at runtime by ChessBoard-Parsing.swift (@objc methods)
//  in ChessEngine.framework.  Do NOT import this header from ChessEngine-Bridging-Header.h —
//  doing so creates an ambiguity when combined with @testable import ChessEngine in unit tests.
//

#import "ChessBoard.h"

@interface ChessBoard (UIExtensions)
- (nonnull NSString *)generateFEN;
@end
