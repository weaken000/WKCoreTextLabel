//
//  WKCoreTextLabel.m
//  QingYouProject
//
//  Created by mac on 2018/8/21.
//  Copyright © 2018年 ccyouge. All rights reserved.
//

#import "WKCoreTextLabel.h"
#import <CoreText/CoreText.h>

@interface WKCoreTextImageRun: NSObject
@property (nonatomic, assign) NSUInteger textIndex;
@property (nonatomic, strong) UIImage    *image;
@property (nonatomic, assign) CGSize     imageSize;
@property (nonatomic, assign) CGRect     imageRunRect;
@property (nonatomic, copy  ) void (^ imageRunTapper)(UIImage *);
- (instancetype)initImage:(UIImage *)image imageSize:(CGSize)imageSize textIndex:(NSUInteger)textIndex;
@end
@interface WKCoreTextRun: NSObject
@property (nonatomic, assign) NSRange textRange;
@property (nonatomic, assign) NSRange fakeRange;
@property (nonatomic, strong) UIColor *normalColor;
@property (nonatomic, strong) UIColor *highlightColor;
@property (nonatomic, assign) BOOL isHighlight;
@property (nonatomic, copy  ) void (^ textRunTapper)(NSString *);
@end

@implementation WKCoreTextImageRun
- (instancetype)initImage:(UIImage *)image imageSize:(CGSize)imageSize textIndex:(NSUInteger)textIndex {
    if (!image || CGSizeEqualToSize(CGSizeZero, imageSize)) {
        return nil;
    }
    if (self == [super init]) {
        _image = image;
        _imageSize = imageSize;
        _textIndex = textIndex;
    }
    return self;
}
@end

@implementation WKCoreTextRun
@end

//
@implementation WKCoreTextLabel {
    NSMutableArray<WKCoreTextImageRun *> *_imageArr;
    NSMutableArray<WKCoreTextRun *>      *_textArr;
    NSMutableAttributedString            *_attributeStr;
    CTFrameRef _ctFrame;
}

#pragma mark - life circle
- (instancetype)initWithFrame:(CGRect)frame {
    if (self == [super initWithFrame:frame]) {
        _lineSpace = 0.0;
        _textColor = [UIColor blackColor];
        _font = [UIFont systemFontOfSize:14];
        _textAlignment = NSTextAlignmentLeft;
        _text = @"";
    }
    return self;
}

- (void)drawRect:(CGRect)rect {

    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    NSMutableAttributedString *attributeStr = [self setupAttributeString];
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributeStr);

    CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
    CGContextTranslateCTM(ctx, 0, rect.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    [[UIColor whiteColor] set];
    CGContextFillRect(ctx, rect);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    NSInteger length = attributeStr.length;
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, length), path, NULL);
    CTFrameDraw(frame, ctx);
    
    //绘制图片
    if (_imageArr.count > 0) {
        [self drawImageContext:ctx ctFrame:frame];
    }
    
    CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
    CGContextTranslateCTM(ctx, 0, rect.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    
    _ctFrame = frame;
    CFRelease(path);
    CFRelease(frameSetter);
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!_textArr.count && !_imageArr.count) return;
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [self systemPointFromScreenPoint:[touch locationInView:self]];
    WKCoreTextImageRun *imageRun = [self touchInImage:location];
    if (imageRun) {
        if (imageRun.imageRunTapper) {
            imageRun.imageRunTapper(imageRun.image);
        }
        return;
    }
    [self touchInString:location];
}

- (void)drawImageContext:(CGContextRef)ctx ctFrame:(CTFrameRef)ctFrame {
    NSArray *lines = (NSArray *)CTFrameGetLines(ctFrame);
    NSInteger lineCount = lines.count;
    CGPoint origins[lineCount];
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), origins);
    for (int i = 0; i < lineCount; i++) {
        CTLineRef line = (__bridge CTLineRef)lines[i];
        NSArray *runs = (NSArray *)CTLineGetGlyphRuns(line);
        for (int j = 0; j < runs.count; j++) {
            CTRunRef run = (__bridge CTRunRef)runs[j];
            NSDictionary *attributes = (NSDictionary *)CTRunGetAttributes(run);
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[attributes valueForKey:(id)kCTRunDelegateAttributeName];
            if (delegate == NULL) {
                continue;
            }
            WKCoreTextImageRun *imageRun = (__bridge WKCoreTextImageRun *)CTRunDelegateGetRefCon(delegate);
            CGPoint origin = origins[i];
            CGFloat ascent, descent;
            CGRect boundsRun;
            boundsRun.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
            boundsRun.size.height = ascent + descent;
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
            boundsRun.origin.x = origin.x + xOffset;
            boundsRun.origin.y = origin.y - descent;
            CGPathRef path = CTFrameGetPath(ctFrame);
            CGRect colRect = CGPathGetBoundingBox(path);
            CGRect imageBounds = CGRectOffset(boundsRun, colRect.origin.x, colRect.origin.y);
            CGContextDrawImage(ctx, imageBounds, imageRun.image.CGImage);
            imageRun.imageRunRect = imageBounds;
        }
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    NSAttributedString *attStr = [self setupAttributeString];
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attStr);
    CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, attStr.length), NULL, size, NULL);
    CFRelease(frameSetter);
    CGRect frame = self.frame;
    frame.size = suggestSize;
    self.frame = frame;
    return suggestSize;
}

- (void)sizeToFit {
    NSAttributedString *attStr = [self setupAttributeString];
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attStr);
    CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, attStr.length), NULL, CGSizeMake(self.frame.size.width, MAXFLOAT), NULL);
    CFRelease(frameSetter);
    CGRect frame = self.frame;
    frame.size = suggestSize;
    self.frame = frame;
}

#pragma mark - public
- (void)wk_addTapWithTextRange:(NSRange)textRange normalColor:(UIColor *)normalColor highlightColor:(UIColor *)highlightColor handler:(void (^)(NSString *))handler {
    if (textRange.location >= _text.length - 1 || textRange.length == 0)  return;
    if (textRange.location + textRange.length > _text.length) {
        textRange = NSMakeRange(textRange.location, _text.length - textRange.location);
    }
    if (!_textArr) {
        _textArr = [NSMutableArray array];
    }
    WKCoreTextRun *textRun = [WKCoreTextRun new];
    textRun.textRange      = textRange;
    textRun.normalColor    = normalColor;
    textRun.highlightColor = highlightColor;
    textRun.textRunTapper  = [handler copy];
    [_textArr addObject:textRun];
    [self setNeedsDisplay];
}

- (WKCoreTextImageRun *)wk_appendImage:(UIImage *)image size:(CGSize)size atIndex:(NSUInteger)index handler:(void (^)(UIImage *))handler {
    if (!_imageArr) {
        _imageArr = [NSMutableArray array];
    }
    WKCoreTextImageRun *imageRun = [[WKCoreTextImageRun alloc] initImage:image imageSize:size textIndex:index];
    if (imageRun) {
        imageRun.imageRunTapper = [handler copy];
        [_imageArr addObject:imageRun];
        [self setNeedsDisplay];
    }
    return imageRun;
}
- (void)wk_removeImageRun:(WKCoreTextImageRun *)imageRun {
    imageRun.imageRunTapper = nil;
    [_imageArr removeObject:imageRun];
    imageRun = nil;
    [self setNeedsDisplay];
}

#pragma mark - setter
- (void)setText:(NSString *)text {
    if ([_text isEqualToString:text]) return;
    _text = text;
    [self setNeedsDisplay];
}
- (void)setLineSpace:(NSInteger)lineSpace {
    if (_lineSpace == lineSpace) return;
    _lineSpace = lineSpace;
    [self setNeedsDisplay];
}
- (void)setFont:(UIFont *)font {
    if ([_font.fontName isEqualToString:font.fontName] && _font.pointSize == font.pointSize) {
        return;
    }
    _font = font;
    [self setNeedsDisplay];
}
- (void)setTextColor:(UIColor *)textColor {
    if (_textColor == textColor) return;
    _textColor = textColor;
    [self setNeedsDisplay];
}
- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    if (_textAlignment == textAlignment) return;
    _textAlignment = textAlignment;
    [self setNeedsDisplay];
}


#pragma mark - config
- (NSMutableAttributedString *)setupAttributeString {
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:_text];
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.lineSpacing = _lineSpace;
    para.alignment = _textAlignment;
    para.lineBreakMode = NSLineBreakByWordWrapping;
    [attributeStr setAttributes:@{NSForegroundColorAttributeName: _textColor,
                                  NSFontAttributeName: _font,
                                  NSParagraphStyleAttributeName: para}
                          range:NSMakeRange(0, attributeStr.length)];
    
    for (WKCoreTextRun *textRun in _textArr) {
        UIColor *color = textRun.isHighlight ? textRun.highlightColor : textRun.normalColor;
        [attributeStr setAttributes:@{NSForegroundColorAttributeName: color,
                                      NSFontAttributeName: _font,
                                      NSParagraphStyleAttributeName: para}
                              range:textRun.textRange];
        
        NSInteger addLoc = 0;
        NSInteger addLen = 0;
        for (WKCoreTextImageRun *imageRun in _imageArr) {
            if (imageRun.textIndex >= textRun.textRange.location && imageRun.textIndex < textRun.textRange.location + textRun.textRange.length) {
                addLen += 1;
                continue;
            }
            if (imageRun.textIndex < textRun.textRange.location) {
                addLoc += 1;
            }
        }
        textRun.fakeRange = NSMakeRange(textRun.textRange.location + addLoc, textRun.textRange.length + addLen);
    }
    
    _attributeStr = [attributeStr mutableCopy];
    
    //设置图片代理
    for (WKCoreTextImageRun *imageRun in _imageArr) {
        CTRunDelegateCallbacks callBacks;
        memset(&callBacks, 0, sizeof(CTRunDelegateCallbacks));
        callBacks.version    = kCTRunDelegateVersion1;
        callBacks.getAscent  = ascentCallBacks;
        callBacks.getDescent = descentCallBacks;
        callBacks.getWidth   = widthCallBacks;
        CTRunDelegateRef delegate = CTRunDelegateCreate(&callBacks, (__bridge void *)imageRun);
        unichar placeHolder = 0xFFFC;
        NSString *placeHolderStr = [NSString stringWithCharacters:&placeHolder length:1];
        NSMutableAttributedString *placeHolderAttrStr = [[NSMutableAttributedString alloc] initWithString:placeHolderStr];
        CFAttributedStringSetAttribute((CFMutableAttributedStringRef)placeHolderAttrStr, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
        CFRelease(delegate);
        if (imageRun.textIndex >= attributeStr.length) {
            [attributeStr insertAttributedString:placeHolderAttrStr atIndex:attributeStr.length - 1];
        } else {
            [attributeStr insertAttributedString:placeHolderAttrStr atIndex:imageRun.textIndex];
        }
    }
    return attributeStr;
}

- (CGPoint)systemPointFromScreenPoint:(CGPoint)origin {
    return CGPointMake(origin.x, self.bounds.size.height - origin.y);
}
- (WKCoreTextImageRun *)touchInImage:(CGPoint)point {
    for (WKCoreTextImageRun *imageRun in _imageArr) {
        if (CGRectContainsPoint(imageRun.imageRunRect, point)) {
            return imageRun;
        }
    }
    return nil;
}
- (void)touchInString:(CGPoint)point {
    if (_ctFrame == NULL || !_textArr.count) return;
    
    NSArray *lines = (NSArray *)CTFrameGetLines(_ctFrame);
    NSInteger lineCount = lines.count;
    CGPoint origins[lineCount];
    CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, 0), origins);
    for (int i = 0; i < lines.count; i++) {
        if (origins[i].y > point.y) continue;
        
        //找到对应行
        CTLineRef line = (__bridge CTLineRef)lines[i];
        CFRange lineRange = CTLineGetStringRange(line);
        //遍历该行的每个字符，判断位置
        for (int j = 0; j < lineRange.length; j++) {
            CGFloat offsetLX = CTLineGetOffsetForStringIndex(line, lineRange.location + j, NULL);
            CGFloat offsetRX = CTLineGetOffsetForStringIndex(line, lineRange.location + j + 1, NULL);
            if (offsetLX <= point.x && point.x <= offsetRX) {
                NSLog(@"点击了第%d行，第%d个字符", i + 1, j + 1);
                NSUInteger charIndex = lineRange.location + j;
                for (WKCoreTextRun *textRun in _textArr) {
                    if (charIndex >= textRun.fakeRange.location && charIndex < textRun.fakeRange.location + textRun.fakeRange.length) {
                        NSLog(@"找到了具体的range--%@", NSStringFromRange(textRun.textRange));
                        if (!textRun.isHighlight) {
                            if (textRun.textRunTapper) {
                                NSString *str = [_attributeStr attributedSubstringFromRange:textRun.textRange].string;
                                textRun.textRunTapper(str);
                            }
                            textRun.isHighlight = YES;
                            [self setNeedsDisplay];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                textRun.isHighlight = NO;
                                [self setNeedsDisplay];
                            });
                           
                        }
                        break;
                    }
                }
                break;
            }
        }
        break;
    }
}

#pragma mark - callBack
static CGFloat ascentCallBacks(void *ref) {
    WKCoreTextImageRun *imageRun = (__bridge WKCoreTextImageRun *)(ref);
    return imageRun.imageSize.height;
}
static CGFloat descentCallBacks(void *ref) {
    return 0;
}
static CGFloat widthCallBacks(void *ref) {
    WKCoreTextImageRun *imageRun = (__bridge WKCoreTextImageRun *)(ref);
    return imageRun.imageSize.width;
}

- (void)dealloc {
    NSLog(@"%@--dealloc", [self class]);
}

@end
