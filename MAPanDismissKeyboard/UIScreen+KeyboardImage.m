//
//  UIScreen+KeyboardImage.m
//  MAPanDismissKeyboard
//
//  Created by Mark Adams on 2/23/13.
//  Copyright (c) 2013 Mark Adams. All rights reserved.
//

#import "UIScreen+KeyboardImage.h"

@implementation UIScreen (KeyboardImage)

+ (UIWindow *)keyboardWindow
{
    UIWindow *keyboard = nil;

    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        if ([[window description] hasPrefix:@"<UITextEffectsWin"])
        {
            keyboard = window;
            break;
        }
    }

    return keyboard;
}

- (UIImage *)keyboardImage
{
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);

    UIWindow *keyboardWindow = [[self class] keyboardWindow];
    CGContextTranslateCTM(context, keyboardWindow.center.x, keyboardWindow.center.y);
    CGContextConcatCTM(context, keyboardWindow.transform);

    NSInteger yOffset = [UIApplication sharedApplication].statusBarHidden? 0 : -20;
    CGFloat xTranslation = -1.0f * CGRectGetWidth(keyboardWindow.bounds) * keyboardWindow.layer.anchorPoint.x;
    CGFloat yTranslation = -1.0f * CGRectGetHeight(keyboardWindow.bounds) * keyboardWindow.layer.anchorPoint.y;
    CGContextTranslateCTM(context, xTranslation, yTranslation + yOffset);

    [keyboardWindow.layer renderInContext:context];

    CGContextRestoreGState(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

@end
