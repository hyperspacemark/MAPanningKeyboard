//
//  MAViewController.m
//  MAPanDismissKeyboard
//
//  Created by Mark Adams on 2/22/13.
//  Copyright (c) 2013 Mark Adams. All rights reserved.
//

#import "MAViewController.h"
#import "UIScreen+KeyboardImage.h"

@interface MAViewController ()

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
    if (!_panGestureRecognizer) _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
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

- (void)prepareKeyboardImage
{
    self.keyboardImageView.image = [[UIScreen mainScreen] keyboardImage];
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
    if ([[notification name] isEqualToString:UIKeyboardDidShowNotification])
    {
        CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        self.keyboardFrame = [self.view.window convertRect:endFrame toView:nil];
        self.panGestureRecognizer.enabled = YES;
    }
}

@end
