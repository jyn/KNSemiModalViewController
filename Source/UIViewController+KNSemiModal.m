//
//  KNSemiModalViewController.m
//  KNSemiModalViewController
//
//  Created by Kent Nguyen on 2/5/12.
//  Copyright (c) 2012 Kent Nguyen. All rights reserved.
//

#import "UIViewController+KNSemiModal.h"
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define kSemiModalDefaultPresentedOpacity 0.5
#define kSemiModalDefaultShadowState YES

@interface UIViewController (KNSemiModalInternal)
-(UIView*)parentTarget;
-(CAAnimationGroup*)animationGroupForward:(BOOL)_forward withDuration:(CGFloat)duration;
@end

@implementation UIViewController (KNSemiModalInternal)

-(UIView*)parentTarget {
  // To make it work with UINav & UITabbar as well
  UIViewController * target = self;
  while (target.parentViewController != nil) {
    target = target.parentViewController;
  }
  return target.view;
}

-(CAAnimationGroup*)animationGroupForward:(BOOL)_forward withDuration:(CGFloat)duration {
  // Create animation keys, forwards and backwards
  CATransform3D t1 = CATransform3DIdentity;
  t1.m34 = 1.0/-900;
  t1 = CATransform3DScale(t1, 0.95, 0.95, 1);
  t1 = CATransform3DRotate(t1, 15.0f*M_PI/180.0f, 1, 0, 0);

  CATransform3D t2 = CATransform3DIdentity;
  t2.m34 = t1.m34;
  t2 = CATransform3DTranslate(t2, 0, [self parentTarget].frame.size.height*-0.08, 0);
  t2 = CATransform3DScale(t2, 0.8, 0.8, 1);

  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
  animation.toValue = [NSValue valueWithCATransform3D:t1];
  animation.duration = duration/2;
  animation.fillMode = kCAFillModeForwards;
  animation.removedOnCompletion = NO;
  [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

  CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"transform"];
  animation2.toValue = [NSValue valueWithCATransform3D:(_forward?t2:CATransform3DIdentity)];
  animation2.beginTime = animation.duration;
  animation2.duration = animation.duration;
  animation2.fillMode = kCAFillModeForwards;
  animation2.removedOnCompletion = NO;

  CAAnimationGroup *group = [CAAnimationGroup animation];
  group.fillMode = kCAFillModeForwards;
  group.removedOnCompletion = NO;
  [group setDuration:animation.duration*2];
  [group setAnimations:[NSArray arrayWithObjects:animation,animation2, nil]];
  return group;
}
@end

@implementation UIViewController (KNSemiModal)

static char PARENT_VIEW_PRESENTED_OPACITY;

-(CGFloat)parentViewPresentedOpacity {
  NSNumber *_parentViewPresentedOpacity = objc_getAssociatedObject(self, &PARENT_VIEW_PRESENTED_OPACITY);
  CGFloat result = kSemiModalDefaultPresentedOpacity;
  if (_parentViewPresentedOpacity != nil) {
    result = [_parentViewPresentedOpacity floatValue];
  }
  return result;
}

-(void)setParentViewPresentedOpacity:(CGFloat)opacity {
  NSNumber *_parentViewPresentedOpacity = [NSNumber numberWithFloat:opacity];
  objc_setAssociatedObject(self, &PARENT_VIEW_PRESENTED_OPACITY, _parentViewPresentedOpacity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static char SHADOW_PATH;

-(UIBezierPath*)shadowPathForView:(UIView*)view {
  UIBezierPath *path = objc_getAssociatedObject(self, &SHADOW_PATH);
  if (path == nil) {
    path = [UIBezierPath bezierPathWithRect:view.bounds];
  }
  return path;
}

-(void)setOverrideShadowPath:(UIBezierPath*)path {
  objc_setAssociatedObject(self, &SHADOW_PATH, path, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static char AUTO_SHADOW_ON;

-(void)setAutoShadowOn:(BOOL)isAutoShadowOn
{
  NSNumber *_autoShadowOn = [NSNumber numberWithBool:isAutoShadowOn];
  objc_setAssociatedObject(self, &AUTO_SHADOW_ON, _autoShadowOn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(BOOL)isAutoShadowOn
{
  BOOL result = kSemiModalDefaultShadowState;
  NSNumber *_autoShadowOn = objc_getAssociatedObject(self, &AUTO_SHADOW_ON);
  if (_autoShadowOn != nil) {
    result = [_autoShadowOn boolValue];
  }
  return result;
}

static char ANIMATION_DURATION;

-(void)setOverrideAnimationDuration:(CGFloat)duration
{
  NSNumber *_animationDuration = [NSNumber numberWithFloat:duration];
  objc_setAssociatedObject(self, &ANIMATION_DURATION, _animationDuration, OBJC_ASSOCIATION_RETAIN_NONATOMIC);  
}

-(CGFloat)animationDuration
{
  CGFloat result = kSemiModalAnimationDuration;
  NSNumber *_animationDuration = objc_getAssociatedObject(self, &ANIMATION_DURATION);
  if (_animationDuration != nil) {
    result = [_animationDuration floatValue];
  }
  return result;  
}

-(void)presentSemiViewController:(UIViewController*)vc {
  [self presentSemiView:vc.view];
}

-(void)presentSemiView:(UIView*)view {
  // Determine target
  UIView * target = [self parentTarget];
  
  if (![target.subviews containsObject:view]) {
    CGFloat animationDuration = self.animationDuration;
    
    // Calulate all frames
    CGRect sf = view.frame;
    CGRect vf = target.frame;
    CGRect f  = CGRectMake(0, vf.size.height-sf.size.height, vf.size.width, sf.size.height);
    CGRect of = CGRectMake(0, 0, vf.size.width, vf.size.height-sf.size.height);

    // Add semi overlay
    UIView * overlay = [[UIView alloc] initWithFrame:target.bounds];
    overlay.backgroundColor = [UIColor blackColor];
    
    // Take screenshot and scale
    UIGraphicsBeginImageContextWithOptions(target.bounds.size, YES, [[UIScreen mainScreen] scale]);
    [target.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIImageView * ss = [[UIImageView alloc] initWithImage:image];
    [overlay addSubview:ss];
    [target addSubview:overlay];

    // Dismiss button
    // Don't use UITapGestureRecognizer to avoid complex handling
    UIButton * dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [dismissButton addTarget:self action:@selector(dismissSemiModalView) forControlEvents:UIControlEventTouchUpInside];
    dismissButton.backgroundColor = [UIColor clearColor];
    dismissButton.frame = of;
    [overlay addSubview:dismissButton];

    // Begin overlay animation
    [ss.layer addAnimation:[self animationGroupForward:YES withDuration:animationDuration] forKey:@"pushedBackAnimation"];
    [UIView animateWithDuration:animationDuration animations:^{
      ss.alpha = self.parentViewPresentedOpacity; //0.5;
    }];

    // Present view animated
    view.frame = CGRectMake(0, vf.size.height, vf.size.width, sf.size.height);
    [target addSubview:view];
    if (self.isAutoShadowOn) {
      view.layer.shadowColor = [[UIColor blackColor] CGColor];
      view.layer.shadowOffset = CGSizeMake(0, -2);
      view.layer.shadowRadius = 5.0;
      view.layer.shadowOpacity = 0.8;
      view.layer.shouldRasterize = YES;
      view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
      UIBezierPath *path = [self shadowPathForView:view]; //[UIBezierPath bezierPathWithRect:view.bounds];
      view.layer.shadowPath = path.CGPath;
    }

    [UIView animateWithDuration:animationDuration animations:^{
      view.frame = f;
    } completion:^(BOOL finished) {
      if(finished){
        [[NSNotificationCenter defaultCenter] postNotificationName:kSemiModalDidShowNotification
                                                            object:self];
      }
    }];
  }
}

-(void)dismissSemiModalView {
  CGFloat animationDuration = self.animationDuration;
  UIView * target = [self parentTarget];
  UIView * modal = [target.subviews objectAtIndex:target.subviews.count-1];
  UIView * overlay = [target.subviews objectAtIndex:target.subviews.count-2];
  [UIView animateWithDuration:animationDuration animations:^{
    modal.frame = CGRectMake(0, target.frame.size.height, modal.frame.size.width, modal.frame.size.height);
  } completion:^(BOOL finished) {
    [overlay removeFromSuperview];
    [modal removeFromSuperview];
  }];

  // Begin overlay animation
  UIImageView * ss = (UIImageView*)[overlay.subviews objectAtIndex:0];
  [ss.layer addAnimation:[self animationGroupForward:NO withDuration:animationDuration] forKey:@"bringForwardAnimation"];
  [UIView animateWithDuration:animationDuration animations:^{
    ss.alpha = 1;
  } completion:^(BOOL finished) {
    if(finished){
      [[NSNotificationCenter defaultCenter] postNotificationName:kSemiModalDidHideNotification
                                                          object:self];
    }
  }];
}

- (void)resizeSemiView:(CGSize)newSize {
  CGFloat animationDuration = self.animationDuration;
  UIView * target = [self parentTarget];
  UIView * modal = [target.subviews objectAtIndex:target.subviews.count-1];
  CGRect mf = modal.frame;
  mf.size.width = newSize.width;
  mf.size.height = newSize.height;
  mf.origin.y = target.frame.size.height - mf.size.height;
  UIView * overlay = [target.subviews objectAtIndex:target.subviews.count-2];
  UIButton * button = [[overlay subviews] objectAtIndex:1];
  CGRect bf = button.frame;
  bf.size.height = overlay.frame.size.height - newSize.height;
  [UIView animateWithDuration:animationDuration animations:^{
    modal.frame = mf;
    button.frame = bf;
  } completion:^(BOOL finished) {
    if(finished){
      [[NSNotificationCenter defaultCenter] postNotificationName:kSemiModalWasResizedNotification
                                                          object:self];
    }
  }];
}

@end

#pragma mark - 

// Convenient category method to find actual ViewController that contains a view
// Adapted from: http://stackoverflow.com/questions/1340434/get-to-uiviewcontroller-from-uiview-on-iphone

@implementation UIView (FindUIViewController)
- (UIViewController *) containingViewController {
  UIView * target = self.superview ? self.superview : self;
  return (UIViewController *)[target traverseResponderChainForUIViewController];
}

- (id) traverseResponderChainForUIViewController {
  id nextResponder = [self nextResponder];
  BOOL isViewController = [nextResponder isKindOfClass:[UIViewController class]];
  BOOL isTabBarController = [nextResponder isKindOfClass:[UITabBarController class]];
  if (isViewController && !isTabBarController) {
    return nextResponder;
  } else if(isTabBarController){
    UITabBarController *tabBarController = nextResponder;
    return [tabBarController selectedViewController];
  } else if ([nextResponder isKindOfClass:[UIView class]]) {
    return [nextResponder traverseResponderChainForUIViewController];
  } else {
    return nil;
  }
}

@end