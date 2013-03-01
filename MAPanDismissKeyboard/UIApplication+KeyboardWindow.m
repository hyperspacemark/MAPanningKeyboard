//
//  UIApplication+KeyboardWindow.m
//  MAPanDismissKeyboard
//
//  Created by Mark Adams on 3/1/13.
//  Copyright (c) 2013 Mark Adams. All rights reserved.
//

#import "UIApplication+KeyboardWindow.h"

@implementation UIApplication (KeyboardWindow)

- (UIWindow *)keyboardWindow
{
  UIWindow *keyboard = nil;

  for (UIWindow *window in self.windows)
  {
    if ([[window description] hasPrefix:@"<UITextEffectsWin"])
    {
      keyboard = window;
      break;
    }
  }

  return keyboard;
}

@end
