//
//  ChessMailViewController.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-15.
//  Copyright Steven Wart 2010. All rights reserved.
//

#import "ChessMailViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "ChessBoard.h"
#import "ChessPlayer.h"
#import "ChessPieceLayer.h"
#import "SquareLayer.h"
#import "ChessConstants.h"
#import "ChessPlayerAI.h"
#import "ChessMove.h"
#import "ChessMoveList.h"

@interface ChessMailViewController(Private)
- (float)boardWidth;
- (float)cellWidth;
- (float)playerWidth;
- (int)squareIndexForLayerLocation:(CGPoint)screenLoc;
- (CGPoint)centerPointOfCellForBoardIndex:(CGPoint)boardPoint;
@end

@implementation ChessMailViewController
@synthesize history, redoList, board;

#pragma mark initialize

#define NUM_ROWS 10
#define NUM_COLS 10

static char cellChars[NUM_COLS][NUM_ROWS] = {
    {' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', ' '},
    {'1', 'B', 'W', 'B', 'W', 'B', 'W', 'B', 'W', ' '},
    {'2', 'W', 'B', 'W', 'B', 'W', 'B', 'W', 'B', ' '},
    {'3', 'B', 'W', 'B', 'W', 'B', 'W', 'B', 'W', ' '},
    {'4', 'W', 'B', 'W', 'B', 'W', 'B', 'W', 'B', ' '},
    {'5', 'B', 'W', 'B', 'W', 'B', 'W', 'B', 'W', ' '},
    {'6', 'W', 'B', 'W', 'B', 'W', 'B', 'W', 'B', ' '},
    {'7', 'B', 'W', 'B', 'W', 'B', 'W', 'B', 'W', ' '},
    {'8', 'W', 'B', 'W', 'B', 'W', 'B', 'W', 'B', ' '},
    {' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', ' '}
};

-(void)addSquares {
    
    CGColorRef white = [UIColor whiteColor].CGColor;
    CGColorRef black = [UIColor lightGrayColor].CGColor;
    
    squares = [NSMutableArray arrayWithCapacity:64];
    [squares retain];
    
    int index = 0;
    
    for (int i=0; i<NUM_ROWS; i++) {
        for (int j=0; j<NUM_COLS; j++) {
            
            char sq = cellChars[j][i];
            
            SquareLayer *square = [self newSquare];
            CGFloat w = [self cellWidth];
            square.bounds = CGRectMake(0, 0, w, w);
            
            if ((sq == 'W') || (sq == 'B')) {
                
                square.backgroundColor = ('W' == sq) ? white : black;
                square.borderColor = [UIColor redColor].CGColor;
                
                square.squarePosition = index;
                [squares addObject:square];
                square.name = [NSString stringWithFormat:@"%c%c",'a' + (index & 7), '1' + (index >> 3)];
                float x = index % 8;
                float y = index / 8;
                CGPoint loc = [self centerPointOfCellForBoardIndex:(CGPointMake(x, y))];
                square.position = loc;
                // NSLog(@"adding square %d named %@ at position (%3.1f, %3.1f)", index, square.name, loc.x, loc.y);
                index++;

                
                // TODO: add delegate to square layer for dragging and dropping
            }
            else {  // decoration
                
                square.backgroundColor = [UIColor clearColor].CGColor;
                
                if (sq != ' ') {
                    
                    CATextLayer *label = [CATextLayer layer];
                    label.string = [NSString stringWithFormat:@"%c", sq];
                    label.bounds = square.bounds;
                    [square addSublayer:label];
                }
            }
            
            square.zPosition = -1;
            [boardLayer addSublayer:square];
        }
    }
}

static NSString *imageNames[12] = {
    @"whitePawnImage.png",
    @"whiteKnightImage.png",
    @"whiteBishopImage.png",
    @"whiteRookImage.png",
    @"whiteQueenImage.png",
    @"whiteKingImage.png",
    
    @"blackPawnImage.png",
    @"blackKnightImage.png",
    @"blackBishopImage.png",
    @"blackRookImage.png",
    @"blackQueenImage.png",
    @"blackKingImage.png"    
};

-(ChessPieceLayer *)newPiece:(int)piece white:(BOOL)isWhite {
    
    int index = isWhite ? piece - 1 : piece + 5;
    
    ChessPieceLayer *m = [[ChessPieceLayer alloc] init];
    UIImage *image = [UIImage imageNamed:(imageNames[index])];
    m.contents = (id)image.CGImage;
    m.isWhite = isWhite;
    m.piece = piece;
    CGFloat w = [self cellWidth];
    m.bounds = CGRectMake(0,0, w, w);
    m.shadowColor = [UIColor blackColor].CGColor;
    
    [boardLayer addSublayer:m];
    
    return m;
}

-(SquareLayer *)newSquare {
    
    SquareLayer *newSquare = [SquareLayer layer];
    return newSquare;
}

#pragma mark ChessUserAgent protocol

-(void)gameReset {
    
    // disable animations for game reset
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    /*
    for (ChessPieceLayer *playerLayer in [playerLayers allValues]) {
        if (playerLayer.superlayer) {
            [playerLayer removeFromSuperlayer];
        }
    }
    */
    
    for (SquareLayer *square in squares) {
        square.pieceLayer = nil;
        square.borderWidth = 0;
    }
    
    [CATransaction commit];
}

-(void)addedPiece:(int)piece at:(int)square white:(BOOL)isWhite {
    
    ChessPieceLayer *m = [self newPiece:piece white:isWhite];
    m.chessBoard = self;
    SquareLayer *s = [squares objectAtIndex:square];
    m.position = s.position;
    s.pieceLayer = m;
}

-(void)completedMove:(ChessMove *)move white:(BOOL)aBool {
    
    if (!board)
        return;
    
    [history addObject:move];
    [self validateGamePosition];
}

-(void)movedPiece:(int)piece from:(int)sourceSquare to:(int)destSquare {
    
    SquareLayer *sourceSquareLayer = [squares objectAtIndex:sourceSquare];
    ChessPieceLayer *sourceLayer = sourceSquareLayer.pieceLayer;
    SquareLayer *destSquareLayer = [squares objectAtIndex:destSquare];
    
    sourceLayer.position = destSquareLayer.position;
    destSquareLayer.pieceLayer = sourceLayer;
}

-(void)removedPiece:(int)piece at:(int)square {
    
    SquareLayer *squareLayer = [squares objectAtIndex:square];
    squareLayer.pieceLayer = nil;
}

-(void)replacedPiece:(int)oldPiece with:(int)newPiece at:(int)square white:(BOOL)isWhitePlayer {
    
    [self removedPiece:oldPiece at:square];
    [self addedPiece:newPiece at:square white:isWhitePlayer];
}

//
// result == 0   : white lost
// result == 0.5 : draw
// result == 1   : white won
//
-(void)finishedGame:(BOOL)result {
    
    self.board = nil;
}

-(void)undoMove:(ChessMove *)move white:(BOOL)isWhitePlayer {
    
    if (!board)
        return;
    
    [redoList addObject:move];
    [self validateGamePosition];
}

//
// this method does nothing but validate what you see (on the screen) is what you get (from the board)
//
-(void)validateGamePosition {
    
    for (int i=0; i<63; i++) {
        
        int piece = 0;
        NSNumber *isWhite = nil;
        
        SquareLayer *square = [squares objectAtIndex:i];
        
        if (square.pieceLayer) {
            
            piece = square.squarePosition;
            isWhite = [NSNumber numberWithBool:square.pieceLayer.isWhite];
        }
        
        int p = [board.whitePlayer pieceAt:i];
        
        if ([board.whitePlayer castlingRookSquare] == i) {
            p = kRook;
        }
        
        if (isWhite && (YES == [isWhite boolValue])) {
            if (p != piece) {
                NSLog(@"white broken: user agent piece (%d) does not match game model piece (%d)", piece, p);
                return;
            }
        }
        else if (!p) {
            NSLog(@"white broken: game model does not have piece at (%d)", i);
            return;
        }
        
        p = [board.blackPlayer pieceAt:i];
        
        if ([board.blackPlayer castlingRookSquare] == i) {
            p = kRook;
        }
        
        if (isWhite && (NO == [isWhite boolValue])) {
            if (p != piece) {
                NSLog(@"black broken: user agent piece (%d) does not match game model piece (%d)", piece, p);
                return;
            }
            else if (!p) {
                NSLog(@"black broken: game model does not have piece at (%d)", i);
                return;
            }
        }
    }
}

#pragma mark playing

-(IBAction)autoPlay {
    
    autoPlay = !autoPlay;
    if (autoPlay) {
        [self thinkAndMove];
    }
}

//
// hint
//
-(IBAction)findBestMove {
    
    if ([board.searchAgent isThinking]) {
        return;
    }
    
    ChessMove *move = [board.searchAgent think];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Suggested move"
                                                    message:[move description]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(IBAction)newGame {
    
    if (!board) {
        ChessBoard *newBoard = [[ChessBoard alloc] init];
        self.board = newBoard;
        [newBoard release];
    }
    board.userAgent = self;
    [board initializeNewBoard];
    self.history = [NSMutableArray array];
    self.redoList = [NSMutableArray array];
}


-(void)movePieceFrom:(int)sourceSquare to:(int)destSquare {
    
    if (!board)
        return;
    
    if ([board.searchAgent isThinking])
        return;
    
    [board movePieceFrom:sourceSquare to:destSquare];
    [board.searchAgent startThinking];
}

//
// redo the last undone move
//
-(IBAction)redoMove {
    
    if (0 == [redoList count])
        return;
    
    ChessMove *move = [redoList lastObject];
    [redoList removeLastObject];
    
    [board nextMove:move];
}

//
// play
//
-(IBAction)thinkAndMove {
    
    if ([board.searchAgent isThinking])
        return;
    
    [board.searchAgent startThinking];
    
}  

//
// undo the last move
//
-(IBAction)undoMove {
    
    if (!board)
        return;
    
    if (0 == [history count])
        return;
    
    ChessMove *move = [history lastObject];
    [history removeLastObject];
    
    [board undoMove:move];
}


#pragma mark Private

- (void)selectPlayer:(ChessPieceLayer *)playerLayer {
    if (selectedPlayer)
    {
        selectedPlayer.shadowOpacity = 0.0;
        selectedPlayer.zPosition -= 1;
        [selectedPlayer needsDisplay];
    }
    selectedPlayer = playerLayer;
    
    if (selectedPlayer)
    {
        selectedPlayer.shadowOpacity = 1.0;
        selectedPlayer.zPosition += 1;
        [selectedPlayer needsDisplay];
    }
}

- (ChessPieceLayer *)playerLayerAtTouchPoint:(CGPoint)touchPoint {
    
    for (SquareLayer *squareLayer in squares) {
        
        ChessPieceLayer *candidate = squareLayer.pieceLayer;
        
        if ((candidate != selectedPlayer) && [candidate hitTest:touchPoint]) {
            return candidate;
        }
    }
    return nil;
}

#pragma mark user feedback

-(void)showMovesAt:(int)square {
    
    if (!board)
        return;
    
    if ([board.searchAgent isThinking])
        return;
    
    for (int i=0; i<63; i++) {
        SquareLayer *squareLayer = [squares objectAtIndex:i];
        squareLayer.borderWidth = 0;
    }
    
    NSArray *list = [board.activePlayer findValidMovesAt:square];
    
    if (0 == [list count])
        return;
    
    SquareLayer *thisLayer = [squares objectAtIndex:square];
    thisLayer.borderWidth = 1.0;
    
    for (ChessMove *move in list) {
        SquareLayer *destLayer = [squares objectAtIndex:move.destinationSquare];
        destLayer.borderWidth = 1.0;
    }
}

-(void)showMovesFrom:(SquareLayer *)squareLayer {
    
    [self showMovesAt:squareLayer.squarePosition];
}

-(void)enteredSquare:(SquareLayer *)squareLayer {
    // TODO: wantsDroppedMorph
}

#pragma mark UITouch events

//
// only support single touch for now
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *theTouch = [touches anyObject];
    if (nil == theTouch)
        return;

    // 1. de-select selected piece, if any
    [self selectPlayer:nil];
    
    CGPoint touchPoint = [theTouch locationInView:theTouch.view];
    touchPoint = [boardLayer convertPoint:touchPoint fromLayer:theTouch.view.layer];
    selectionIndex = [self squareIndexForLayerLocation:touchPoint];
    SquareLayer *squareLayer = [squares objectAtIndex:selectionIndex];
    ChessPieceLayer *candidate = squareLayer.pieceLayer;
    [self selectPlayer:candidate];
    [self showMovesFrom:squareLayer];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *theTouch = [touches anyObject];
    if (nil == theTouch)
        return;
    
    if (selectedPlayer) {
        CGPoint touchPoint = [theTouch locationInView:theTouch.view];
        touchPoint = [boardLayer convertPoint:touchPoint fromLayer:theTouch.view.layer];
        
        // disable animations for tracking the movement of pieces
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        selectedPlayer.position = touchPoint;
        [CATransaction commit];
        
        int squareIndex = [self squareIndexForLayerLocation:touchPoint];
        SquareLayer *squareBelow = [squares objectAtIndex:squareIndex];
        
        [self enteredSquare:squareBelow];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *theTouch = [touches anyObject];
    if (nil == theTouch)
        return;
    
    if (selectedPlayer) {
        CGPoint touchPoint = [theTouch locationInView:theTouch.view];
        touchPoint = [boardLayer convertPoint:touchPoint fromLayer:theTouch.view.layer];
        
        int destIndex = [self squareIndexForLayerLocation:touchPoint];
        
        BOOL moveIsValid = YES;
        
        // TODO: game logic
        moveIsValid = (nil == [self playerLayerAtTouchPoint:touchPoint]);
       
        // if the move is not valid, animate the piece back to its original position
        if (!moveIsValid)
        {
            destIndex = selectionIndex;
            NSLog(@"invalid move: returning player to %d", destIndex);
        }
        // animate the player to the center point of the destination cell
        SquareLayer *destinationCell = [squares objectAtIndex:destIndex];
        selectedPlayer.position = destinationCell.position;
        
        // clear the selection
        [self selectPlayer:nil];
    }
}

// reposition the board in the center of the screen
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration {
    [boardLayer setPosition:(CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2))];
}

// set the bounds to fit the screen (some percentage of the minimum boundary)
- (float)boardWidth {
    return 0.85 * fmin(self.view.frame.size.width, self.view.frame.size.height);
}

- (float)cellWidth {
    return [self boardWidth] / BOARD_GRID_COUNT * 1.0f;    
}

- (float)playerWidth {
    return 0.85f * [self cellWidth];
}

//
// Add the layer representing the chessboard
//
- (void)addBoardLayer {
    boardLayer = [CALayer layer];
    
    // load the contents from a local resource
    CGImageRef image = [UIImage imageNamed:@"checkerboard.png"].CGImage;
    boardLayer.contents = (id)image;
    
    float width = [self boardWidth];
    CGRect bounds = CGRectMake(0, 0, width, width);
    boardLayer.bounds = bounds;
    
    // position the board in the center of the screen
    [boardLayer setPosition:(CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2))];
    [self.view.layer addSublayer:boardLayer];    
}

//
// Load the players list, if there is a saved game in progress or from the defaults
//
- (NSArray *)loadSavedPlayers {
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"players.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:@"players" ofType:@"plist"];
    }
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSArray *playerArray = (NSArray *)[NSPropertyListSerialization
                                          propertyListFromData:plistXML
                                          mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                          format:&format
                                          errorDescription:&errorDesc];
    if (!playerArray) {
        NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
    }
    
    return playerArray;
}

//
// Convert the board layer coordinates to a 0-origin index in board coordinates
// board coordinates are [0..63]
//
- (int)squareIndexForLayerLocation:(CGPoint)screenLoc {
    
    float i = 0;
    float j = 0;
    
    if (screenLoc.x > boardLayer.frame.size.width) {
        i = BOARD_GRID_COUNT - 1;        
    }
    else if (screenLoc.x <= 0) {
        i = 0;
    }
    else {
        i = trunc((screenLoc.x / boardLayer.frame.size.width) * BOARD_GRID_COUNT);
    }
    
    if (screenLoc.y > boardLayer.frame.size.height) {
        j = BOARD_GRID_COUNT - 1;        
    }
    else if (screenLoc.y <= 0) {
        j = 0;
    }
    else {
        j = trunc((screenLoc.y / boardLayer.frame.size.height) * BOARD_GRID_COUNT);
    }
    
    int result = j * BOARD_GRID_COUNT + i;
    
    NSLog(@"Converted (%3.1f, %3.1f) to (%3.1f, %3.1f) = %d", screenLoc.x, screenLoc.y, i, j, result);
    
    return result;
}

//
// return the x,y coordinates of the center of the cell in board coordinates
// board coordinates are i,j in [0-7, 0-7]
//
- (CGPoint)centerPointOfCellForBoardIndex:(CGPoint)boardPoint {
    
    float cellWidth = [self cellWidth];
    float x = cellWidth / 2.0 + boardPoint.x * cellWidth;
    float y = cellWidth / 2.0 + boardPoint.y * cellWidth;
    
    return CGPointMake(x, y);
}

- (void)addTextLayers {
    
    CGRect bounds = CGRectMake(0, 0, [self cellWidth], [self cellWidth]);
    
    for (int j=0; j < BOARD_GRID_COUNT; j++) {
        for (int i=0; i < BOARD_GRID_COUNT; i++) {
            CATextLayer *textLayer = [CATextLayer layer];
            NSString *layerString = [NSString stringWithFormat:@"(%d, %d)", i, j];
            textLayer.string = layerString;
            CGPoint pos = [self centerPointOfCellForBoardIndex:CGPointMake(i,j)];
            textLayer.position = pos;
            textLayer.alignmentMode = kCAAlignmentCenter;
            textLayer.bounds = bounds;
            textLayer.fontSize = 18.0f;
            NSLog(@"Adding text layer [%@] at (%3.0f, %3.0f)", layerString, pos.x, pos.y);
            [boardLayer addSublayer:textLayer];
        }
    }
}

//
// Add the layers representing the players
//
- (void)addPlayerLayers {
    /*
    NSArray *plistArray = [self loadSavedPlayers];
    if (!plistArray) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Startup failed" message:@"Could not find saved game data"
                                                       delegate:nil cancelButtonTitle:@"Whatever" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    
    numPlayers = [plistArray count];
    float playerWidth = [self playerWidth];
    
    NSMutableDictionary *newPlayers = [NSMutableDictionary dictionaryWithCapacity:numPlayers];

    for (NSDictionary *playerDict in plistArray) {
        NSString *filename = (NSString *)[playerDict valueForKey:@"filename"];
        NSNumber *xloc = (NSNumber *)[playerDict valueForKey:@"x"];
        NSNumber *yloc = (NSNumber *)[playerDict valueForKey:@"y"];
        CALayer *playerLayer = [CALayer layer];
        CGImageRef image = [UIImage imageNamed:filename].CGImage;
        playerLayer.contents = (id)image;
        playerLayer.bounds = CGRectMake(0, 0, playerWidth, playerWidth);
        playerLayer.position = [self centerPointOfCellForBoardIndex:(CGPointMake([xloc floatValue], [yloc floatValue]))];
        playerLayer.shadowOpacity = 1.0;
        // shadowpath for players assumes circular pieces
        playerLayer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:playerLayer.bounds].CGPath;

        NSString *playerName = (NSString *)[playerDict valueForKey:@"name"];
        [newPlayers setObject:playerLayer forKey:playerName];
        [boardLayer addSublayer:playerLayer];
    }
    
    self.playerLayers = newPlayers;
     */
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    animateMove = NO;
    autoPlay = NO;
    
    // needed because the class actually needs to be sent a message to invoke initialization
    [[ChessConstants class] initialize];
    
    // initial setup for checkers, with 3 player rows. chess = 2
    numPlayerRows = 3;
    
    [self addBoardLayer];
//    [self addPlayerLayers];
    
    [self addSquares];
    
    // debugging
    if (shouldShowTextLayers)
    {
        [self addTextLayers];
    }
    
    [self newGame];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// we don't retain board layer, so we don't need to release it
    boardLayer = nil;
//    self.playerLayers = nil;
}


- (void)dealloc {
    [super dealloc];
    if (board) {
        [board release];
    }
    self.redoList = nil;
    self.history = nil;
}

@end
