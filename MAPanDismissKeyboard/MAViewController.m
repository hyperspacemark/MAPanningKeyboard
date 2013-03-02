//
//  MAViewController.m
//  MAPanDismissKeyboard
//
//  Created by Mark Adams on 2/22/13.
//  Copyright (c) 2013 Mark Adams. All rights reserved.
//

#import "MAViewController.h"
#import "UIApplication+KeyboardWindow.h"

@interface MAViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (assign, nonatomic) CGRect keyboardFrame;
@property (strong, nonatomic) UIImageView *keyboardImageView;
@property (assign, nonatomic) CGPoint panStartPoint;
@property (strong, nonatomic) UIResponder *formerFirstResponder;
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation MAViewController

#pragma mark - Getters

- (UIImageView *)keyboardImageView
{
    if (!_keyboardImageView)
    {
        _keyboardImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _keyboardImageView.contentMode = UIViewContentModeBottom;
    }

    return _keyboardImageView;
}

- (UIPanGestureRecognizer *)panGestureRecognizer
{
    if (!_panGestureRecognizer)
    {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        _panGestureRecognizer.delegate = self;
    }
    
    return _panGestureRecognizer;
}

#pragma mark - Object Lifecycle

- (void)dealloc
{
    [self stopObservingKeyboardNotifications];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.scrollView.layer.borderColor = [UIColor blueColor].CGColor;
    self.scrollView.layer.borderWidth = 1.0f;
    [self.view addSubview:self.keyboardImageView];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    [self startObservingKeyboardNotifications];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.textField becomeFirstResponder];
    self.formerFirstResponder = self.textField;
}

#pragma mark - Keyboard Image

- (UIImage *)createKeyboardImage
{
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);

    UIWindow *keyboardWindow = [[UIApplication sharedApplication] keyboardWindow];
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

- (void)prepareKeyboardImage
{
    self.keyboardImageView.image = [self createKeyboardImage];
    self.keyboardImageView.frame = self.keyboardFrame;
}

- (void)translateKeyboardImageViewToY:(CGFloat)newY
{
    CGRect frame = self.keyboardImageView.frame;
    frame.origin.y = newY;
    self.keyboardImageView.frame = frame;
}

#pragma mark Animating the Keyboard Image

- (void)animateKeyboardGivenVelocity:(CGPoint)velocity
{
    if (velocity.y > 0.0f)
        [self animateKeyboardOffscreen];
    else
        [self animateKeyboardOnscreen];
}

- (void)animateKeyboardOffscreen
{
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect frame = self.keyboardImageView.frame;
        frame.origin.y = CGRectGetMaxY(self.view.window.frame);
        self.keyboardImageView.frame = frame;
    } completion:^(BOOL finished) {
        self.panGestureRecognizer.enabled = NO;
    }];
}

- (void)animateKeyboardOnscreen
{
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect frame = self.keyboardImageView.frame;
        frame.origin.y = CGRectGetMinY(self.keyboardFrame);
        self.keyboardImageView.frame = frame;
    } completion:^(BOOL finished) {
        [self showKeyboardWithoutAnimation];
    }];
}

#pragma mark - Pan Gesture Recognition

- (void)pan:(UIPanGestureRecognizer *)gesture
{
    CGFloat newY = self.panStartPoint.y + [gesture translationInView:self.view.window].y;
    newY = [self clampedYOrigin:newY];
    BOOL panIsAtMinimum = (newY == CGRectGetMinY(self.keyboardFrame));
    
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
            self.panStartPoint = [gesture locationInView:self.view.window];
            [self prepareKeyboardImage];
            break;
            
        case UIGestureRecognizerStateChanged:
            if (panIsAtMinimum) [self dismissKeyboardWithoutAnimation];
            [self translateKeyboardImageViewToY:newY];
            break;

        case UIGestureRecognizerStateEnded:
            if (panIsAtMinimum) [self showKeyboardWithoutAnimation];
            [self animateKeyboardGivenVelocity:[gesture velocityInView:self.view]];
            break;
        default:
            break;
    }
}

#pragma mark Pan Gesture Helpers

- (CGFloat)clampedYOrigin:(CGFloat)yOrigin
{
    CGFloat minY = CGRectGetMinY(self.keyboardFrame);
    CGFloat maxY = CGRectGetHeight(self.view.window.frame);

    if (yOrigin < minY)
        return minY;
    else if (yOrigin > maxY)
        return maxY;
    else
        return yOrigin;
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Managing the scroll view

- (void)resizeScrollViewInResponseToKeyboardNotification:(NSNotification *)notification
{
    CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    endFrame = [self.view convertRect:endFrame fromView:self.view.window];

    CGRect scrollViewFrame = self.scrollView.frame;
    scrollViewFrame.size.height = CGRectGetMinY(endFrame);
    self.scrollView.frame = scrollViewFrame;
}

#pragma mark - Managing the keyboard

- (void)showKeyboardWithoutAnimation
{
    [UIView animateWithDuration:0 delay:0 options:UIViewAnimationOptionOverrideInheritedDuration animations:^{
        [self.formerFirstResponder becomeFirstResponder];
    } completion:nil];
}

- (void)dismissKeyboardWithoutAnimation
{
    [UIView animateWithDuration:0 delay:0 options:UIViewAnimationOptionOverrideInheritedDuration animations:^{
        [self.view endEditing:YES];
    } completion:nil];
}

#pragma mark - Handling keyboard notifications

- (void)startObservingKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibilityDidChange:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibilityDidChange:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)stopObservingKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

- (void)keyboardVisibilityDidChange:(NSNotification *)notification
{
    [self resizeScrollViewInResponseToKeyboardNotification:notification];
  
    if ([[notification name] isEqualToString:UIKeyboardDidShowNotification])
    {
        CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        self.keyboardFrame = [self.view.window convertRect:endFrame toView:nil];
        self.panGestureRecognizer.enabled = YES;
    }
}

@end
