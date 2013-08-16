//
//  KNSemiModalViewController.h
//  KNSemiModalViewController
//
//  Created by Kent Nguyen on 2/5/12.
//  Copyright (c) 2012 Kent Nguyen. All rights reserved.
//

#define kSemiModalAnimationDuration   0.5
#define kSemiModalDidShowNotification @"kSemiModalDidShowNotification"
#define kSemiModalDidHideNotification @"kSemiModalDidHideNotification"
#define kSemiModalWasResizedNotification @"kSemiModalWasResizedNotification"
@interface UIViewController (KNSemiModal)

//  Used to set the opacity of the parent once the SemiModalView appears.
//  Defaults to 0.5.
-(CGFloat)parentViewPresentedOpacity;
-(void)setParentViewPresentedOpacity:(CGFloat)opacity;

//  Used to set a Bezier path for the shadow region. Typically, this defaults to
//  the view's bounds.
-(void)setOverrideShadowPath:(UIBezierPath*)path;

//  Used to turn off auto shadowing.
-(void)setAutoShadowOn:(BOOL)isAutoShadowOn;

//  Used to override the default animation duration of 0.5
-(void)setOverrideAnimationDuration:(CGFloat)duration;

-(void)presentSemiViewController:(UIViewController*)vc;
-(void)presentSemiView:(UIView*)vc;
-(void)dismissSemiModalView;
-(void)resizeSemiView:(CGSize)newSize;

@end

// Convenient category method to find actual ViewController that contains a view

@interface UIView (FindUIViewController)
- (UIViewController *) containingViewController;
- (id) traverseResponderChainForUIViewController;
@end