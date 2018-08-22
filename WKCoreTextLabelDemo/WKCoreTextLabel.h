//
//  WKCoreTextLabel.h
//  QingYouProject
//
//  Created by mac on 2018/8/21.
//  Copyright © 2018年 ccyouge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WKCoreTextImageRun;

@interface WKCoreTextLabel : UIView

@property (nonatomic, strong) NSString        *text;
@property (nonatomic, strong) UIColor         *textColor;
@property (nonatomic, strong) UIFont          *font;
@property (nonatomic, assign) NSInteger       lineSpace;
@property (nonatomic, assign) NSTextAlignment textAlignment;

- (void)wk_addTapWithTextRange:(NSRange)textRange normalColor:(UIColor *)normalColor highlightColor:(UIColor *)highlightColor handler:(void(^)(NSString *text))handler;

- (WKCoreTextImageRun *)wk_appendImage:(UIImage *)image size:(CGSize)size atIndex:(NSUInteger)index handler:(void(^)(UIImage *image))handler;

- (void)wk_removeImageRun:(WKCoreTextImageRun *)imageRun;

@end
