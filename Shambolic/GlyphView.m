//
//  GlyphView.m
//  Created for Shaman
//

#import "GlyphView.h"
#import <CoreText/CoreText.h>

@interface GlyphView ()
@property (nonatomic, strong) CAShapeLayer *glyphLayer;
@end

@implementation GlyphView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.layer.masksToBounds = YES;
        self.layer.geometryFlipped = YES;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        self.layer.masksToBounds = YES;
        self.layer.geometryFlipped = YES;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _glyph = @"?"; // Default
    _fontName = @"Apple Symbols";
    _fontSize = 60.0;
    _fillColor = UIColor.blackColor;
    _strokeColor = UIColor.clearColor;
    _strokeWidth = 0.0;
    
    _glyphLayer = [CAShapeLayer layer];
    _glyphLayer.fillColor = _fillColor.CGColor;
    _glyphLayer.strokeColor = _strokeColor.CGColor;
    _glyphLayer.lineWidth = _strokeWidth;
    [self.layer addSublayer:_glyphLayer];
    
    [self updateGlyph];
}

#pragma mark - Property Setters

- (void)setGlyph:(NSString *)glyph {
    if (![_glyph isEqualToString:glyph]) {
        _glyph = [glyph copy];
        [self updateGlyph];
    }
}

- (void)setFontName:(NSString *)fontName {
    if (![_fontName isEqualToString:fontName]) {
        _fontName = [fontName copy];
        [self updateGlyph];
    }
}

- (void)setFontSize:(CGFloat)fontSize {
    if (_fontSize != fontSize) {
        _fontSize = fontSize;
        [self updateGlyph];
    }
}

- (void)setFillColor:(UIColor *)fillColor {
    _fillColor = fillColor;
    _glyphLayer.fillColor = fillColor.CGColor;
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor = strokeColor;
    _glyphLayer.strokeColor = strokeColor.CGColor;
}

- (void)setStrokeWidth:(CGFloat)strokeWidth {
    _strokeWidth = strokeWidth;
    _glyphLayer.lineWidth = strokeWidth;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateGlyph]; // Rescale on size changes
}

#pragma mark - Glyph Path Construction

- (void)updateGlyph
{
    if (_glyph.length == 0 || _fontName.length == 0) {
        _glyphLayer.path = nil;
        return;
    }
    
    // 1. Create CTFont
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)_fontName, _fontSize, NULL);
    if (!font) {
        _glyphLayer.path = nil;
        return;
    }
    
    // 2. Map character to glyph
    UniChar chars[2] = {0};
    CFIndex glyphCount = [_glyph length];
    [_glyph getCharacters:chars range:NSMakeRange(0, MIN(2, glyphCount))];
    CGGlyph glyphs[2] = {0};
    if (!CTFontGetGlyphsForCharacters(font, chars, glyphs, 1)) {
        CFRelease(font);
        _glyphLayer.path = nil;
        return;
    }
    
    // 3. Create path for glyph
    CGPathRef glyphPath = CTFontCreatePathForGlyph(font, glyphs[0], NULL);
    if (!glyphPath) {
        CFRelease(font);
        _glyphLayer.path = nil;
        return;
    }
    
    // 4. Center and scale path into view bounds (no Y-flip needed now)
    CGRect glyphBounds = CGPathGetBoundingBox(glyphPath);
    CGRect bounds = self.bounds;
    CGFloat scale = MIN(bounds.size.width / glyphBounds.size.width,
                        bounds.size.height / glyphBounds.size.height) * 0.9; // Add margin
    if (isinf(scale) || isnan(scale)) { scale = 1.0; }
    CGAffineTransform t = CGAffineTransformIdentity;

    // Move origin to (0,0)
    t = CGAffineTransformTranslate(t, -glyphBounds.origin.x, -glyphBounds.origin.y);
    // Scale
    t = CGAffineTransformScale(t, scale, scale);
    // Center in bounds
    CGFloat dx = (bounds.size.width - glyphBounds.size.width * scale) / 2.0;
    CGFloat dy = (bounds.size.height - glyphBounds.size.height * scale) / 2.0;
    t = CGAffineTransformTranslate(t, dx / scale, dy / scale);

    CGPathRef finalPath = CGPathCreateCopyByTransformingPath(glyphPath, &t);
    _glyphLayer.path = finalPath;
    _glyphLayer.frame = self.bounds;
    
    CGPathRelease(glyphPath);
    if (finalPath) CFRelease(finalPath);
    CFRelease(font);
    
    // Update colors/width in case set after
    _glyphLayer.fillColor = _fillColor.CGColor;
    _glyphLayer.strokeColor = _strokeColor.CGColor;
    _glyphLayer.lineWidth = _strokeWidth;
}

@end
