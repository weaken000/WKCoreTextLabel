//
//  ViewController.m
//  WKCoreTextLabelDemo
//
//  Created by mac on 2018/8/22.
//  Copyright © 2018年 weikun. All rights reserved.
//

#import "ViewController.h"
#import "WKCoreTextLabel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    [self testCoreTextLabel];
    
}

- (void)testCoreTextLabel {
    WKCoreTextLabel *label = [[WKCoreTextLabel alloc] init];
    label.center = CGPointMake(self.view.frame.size.width * .5, self.view.frame.size.height * .5);
    [self.view addSubview:label];
    
    label.text = @"阿萨德和法律是打发按时发我让各位各位\n同本人特别而别人玩儿过玩儿个人给我阿士大夫是否打算的发送到发送到发送大V阿深V相册八方";
    [label wk_appendImage:[UIImage imageNamed:@"cashier_tips.png"] size:CGSizeMake(50, 50) atIndex:8 handler:^(UIImage *image) {
        NSLog(@"点击了图片");
    }];
    [label wk_appendImage:[UIImage imageNamed:@"cashier_tips.png"] size:CGSizeMake(20, 20) atIndex:23 handler:^(UIImage *image) {
        NSLog(@"点击了图片");
    }];
    [label wk_addTapWithTextRange:NSMakeRange(5, 5) normalColor:[UIColor yellowColor] highlightColor:[UIColor redColor] handler:^(NSString *text) {
        NSLog(@"点击了文字--%@", text);
    }];
    [label wk_addTapWithTextRange:NSMakeRange(10, 1) normalColor:[UIColor blueColor] highlightColor:[UIColor redColor] handler:^(NSString *text) {
        NSLog(@"点击了文字--%@", text);
    }];
    [label wk_addTapWithTextRange:NSMakeRange(20, 8) normalColor:[UIColor purpleColor] highlightColor:[UIColor redColor] handler:^(NSString *text) {
        NSLog(@"点击了文字--%@", text);
    }];
    
    [label sizeThatFits:CGSizeMake(100, MAXFLOAT)];
}




@end
