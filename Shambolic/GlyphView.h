//
//  GlyphView.h
//  Created for Shaman
//
//  Layer-backed UIView rendering a text glyph as a CAShapeLayer, with fill and stroke controls.
//  This view automatically handles coordinate system flipping, so glyphs are rendered upright
//  in all UIKit and SwiftUI contexts.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 GlyphView is a UIView subclass that renders a single text glyph using CoreText and CoreGraphics.
 The glyph is displayed as a scalable vector outline, rendered by a backing CAShapeLayer.
 
 - Supports arbitrary Unicode glyphs and any installed font.
 - Fill color, stroke color, and stroke width can be customized.
 - The view automatically handles coordinate system flipping, so the glyph
   always appears upright in UIKit or SwiftUI regardless of the parent view/layer.
 
 Use this view from UIKit or from SwiftUI (e.g., via UIViewRepresentable) to display
 resizable and stylable piece symbols or other icons.
 */
@interface GlyphView : UIView

/// The character or symbol to render as a glyph. (e.g. @"♞", @"A")
@property (nonatomic, copy) NSString *glyph;

/// The name of the font to use (e.g. "Apple Symbols", "Helvetica", etc.)
@property (nonatomic, copy) NSString *fontName;

/// The font size (in points) used to generate the glyph outline. The result will be scaled to fit the view's bounds.
@property (nonatomic, assign) CGFloat fontSize;

/// The fill color applied to the glyph's shape.
@property (nonatomic, strong) UIColor *fillColor;

/// The stroke color applied to the glyph's outline.
@property (nonatomic, strong) UIColor *strokeColor;

/// The width (in points) of the glyph's outline stroke.
@property (nonatomic, assign) CGFloat strokeWidth;

/**
 Initializes a GlyphView to fit the given frame.

 @param frame The frame rectangle for the view, measured in points.
 @return An initialized view object.
 */
- (instancetype)initWithFrame:(CGRect)frame;

/**
 Initializes a GlyphView from a coder (for use in Interface Builder or decoding).
 */
- (nullable instancetype)initWithCoder:(NSCoder *)coder;

@end

NS_ASSUME_NONNULL_END
