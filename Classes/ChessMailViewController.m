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
#import "ChessConstants.h"

@interface ChessMailViewController(Private)
- (float)boardWidth;
- (float)cellWidth;
- (float)playerWidth;
- (CGPoint)boardIndexForLayerLocation:(CGPoint)screenLoc;
- (CGPoint)centerPointOfCellForBoardIndex:(CGPoint)boardPoint;
@end

@implementation ChessMailViewController
@synthesize playerLayers, history, redoList;

#pragma mark Actions

-(void)newGame {
    
    if (!board) {
        board = [[ChessBoard alloc] init];
    }
    board.userAgent = self;
    [board initializeNewBoard];
    self.history = [NSMutableArray array];
    self.redoList = [NSMutableArray array];
}

#pragma mark ChessUserAgent protocol

-(void)gameReset {
    
    // disable animations for game reset
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    for (ChessPieceLayer *playerLayer in [playerLayers allValues]) {
        if (playerLayer.superlayer) {
            [playerLayer removeFromSuperlayer];
        }
    }
    
    [CATransaction commit];
}

#pragma mark Private

- (void)selectPlayer:(ChessPieceLayer *)playerLayer {
    if (selectedPlayer)
    {
        selectedPlayer.shadowColor = [UIColor blackColor].CGColor;
        [selectedPlayer needsDisplay];
        selectedPlayer.zPosition -= 1;
    }
    selectedPlayer = playerLayer;
    
    if (selectedPlayer)
    {
        selectedPlayer.shadowColor = [UIColor whiteColor].CGColor;
        [selectedPlayer needsDisplay];
        selectedPlayer.zPosition += 1;
    }
}

- (ChessPieceLayer *)playerLayerAtTouchPoint:(CGPoint)touchPoint {
    
    for (ChessPieceLayer *candidate in [playerLayers allValues]) {
        if ((candidate != selectedPlayer) && [candidate hitTest:touchPoint]) {
            return candidate;
        }
    }
    return nil;
}

//
// only support single touch for now
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *theTouch = [touches anyObject];
    if (nil == theTouch)
        return;

    // 1. de-select selected piece, if any
    [self selectPlayer:nil];
    
    // TODO: check if event over a player's own piece
    
    CGPoint touchPoint = [theTouch locationInView:theTouch.view];
    touchPoint = [boardLayer convertPoint:touchPoint fromLayer:theTouch.view.layer];
    boardIndexForSelectedPlayer = [self boardIndexForLayerLocation:touchPoint];
    ChessPieceLayer *candidate = [self playerLayerAtTouchPoint:touchPoint];
    [self selectPlayer:candidate];
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
    }
    // 1. move selected piece to current touch position
    // 2. is current touch position a valid move destination?
    // 2a. yes -> is move destination already highlighted?
    // 2ai. yes -> ignore
    // 2aii. no -> highlight move destination
    // 2b. no -> clear any selected move destination
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *theTouch = [touches anyObject];
    if (nil == theTouch)
        return;
    
    if (selectedPlayer) {
        CGPoint touchPoint = [theTouch locationInView:theTouch.view];
        touchPoint = [boardLayer convertPoint:touchPoint fromLayer:theTouch.view.layer];
        
        CGPoint boardIndex = [self boardIndexForLayerLocation:touchPoint];
        
        BOOL moveIsValid = YES;
        
        // TODO: game logic
        moveIsValid = (nil == [self playerLayerAtTouchPoint:touchPoint]);
       
        // if the move is not valid, animate the piece back to its original position
        if (!moveIsValid)
        {
            boardIndex = boardIndexForSelectedPlayer;
            NSLog(@"invalid move: returning player to (%3.0f, %3.0f)", boardIndex.x, boardIndex.y);
        }
        // animate the player to the center point of the destination cell
        CGPoint centerPoint = [self centerPointOfCellForBoardIndex:boardIndex];
        selectedPlayer.position = centerPoint;
        
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
    return 0.85 * fmin(self.view.bounds.size.width, self.view.bounds.size.height);
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
    [boardLayer setPosition:(CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2))];
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
// board coordinates are i,j in [0-7, 0-7]
//
- (CGPoint)boardIndexForLayerLocation:(CGPoint)screenLoc {
    
    float i = 0;
    float j = 0;
    
    if (screenLoc.x > boardLayer.bounds.size.width) {
        i = BOARD_GRID_COUNT - 1;        
    }
    else if (screenLoc.x <= 0) {
        i = 0;
    }
    else {
        i = trunc((screenLoc.x / boardLayer.bounds.size.width) * BOARD_GRID_COUNT);
    }
    
    if (screenLoc.y > boardLayer.bounds.size.height) {
        j = BOARD_GRID_COUNT - 1;        
    }
    else if (screenLoc.y <= 0) {
        j = 0;
    }
    else {
        j = trunc((screenLoc.y / boardLayer.bounds.size.height) * BOARD_GRID_COUNT);
    }
    
    CGPoint result = CGPointMake(i, j);
    
    NSLog(@"Converted (%3.1f, %3.1f) to (%3.1f, %3.1f)", screenLoc.x, screenLoc.y, i, j);
    
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
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // needed because the class actually needs to be sent a message to invoke initialization
    [[ChessConstants class] initialize];
    
    // initial setup for checkers, with 3 player rows. chess = 2
    numPlayerRows = 3;
    
    [self addBoardLayer];
    [self addPlayerLayers];
    
    // debugging
    if (shouldShowTextLayers)
    {
        [self addTextLayers];
    }
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
    self.playerLayers = nil;
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
