# WKCoreTextLabel

## 代码示例
添加图片点击效果
```
[label wk_appendImage:[UIImage imageNamed:@"cashier_tips.png"] size:CGSizeMake(50, 50) atIndex:8 handler:^(UIImage *image) {
NSLog(@"点击了图片");
}];
```
添加文字点击效果
```
[label wk_addTapWithTextRange:NSMakeRange(5, 5) normalColor:[UIColor yellowColor] highlightColor:[UIColor redColor] handler:^(NSString *text) {
NSLog(@"点击了文字--%@", text);
}];
```

