//
//  TMPopView.m
//  TMPopView
//
//  Created by wangpeng on 2018/11/1.
//  Copyright © 2018 mrstock. All rights reserved.
//

#import "TMPopView.h"

#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height

@interface TMPopView () <UIGestureRecognizerDelegate>

/**
 *  背景图
 */
@property (nonatomic, strong) UIView *backgroundView;
/**
 *  用来放自定义视图的View
 */
@property (nonatomic, strong) UIView *contentView;
/**
 *  自定义视图
 */
@property (nonatomic, strong) UIView *customView;
/**
 *  样式
 */
@property (nonatomic, assign) TMAnimationPopStyle style;

@end

@implementation TMPopView

- (instancetype)initWithCustomView:(UIView *)customView style:(TMAnimationPopStyle)style {
    
    if (!customView) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        
        _style = style;
        _duration = -0.1f;
        _bgAlpha = 0.5;
        _isClickBgDismiss = YES;
        
        self.frame = CGRectMake(0, 0, kWidth, kHeight);
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.backgroundColor = [UIColor blackColor];
        [self addSubview:self.backgroundView];
        
        self.contentView = [[UIView alloc] initWithFrame:self.bounds];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.contentView];
        
        _customView = customView;
        _customView.center = self.contentView.center;
        [self.contentView addSubview:_customView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBGLayer:)];
        tapGesture.delegate = self;
        [_contentView addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)tapBGLayer:(UITapGestureRecognizer *)tap
{
    if (self.isClickBgDismiss) {
        [self dismiss];
    }
}

#pragma mark UIGestureRecognizer Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint location = [touch locationInView:_contentView];
    location = [_customView.layer convertPoint:location fromLayer:_contentView.layer];
    return ![_customView.layer containsPoint:location];
}

- (void)pop {
    
    [[[UIApplication sharedApplication] keyWindow] addSubview:self];
    
    NSTimeInterval defaultDuration = [self getPopDefaultDurationWithStyle:self.style];
    NSTimeInterval duration = (self.duration > 0.0f) ? self.duration : defaultDuration;
    
    if (_style == TMAnimationPopStyleNO) {
        self.alpha = 0.0;
        self.backgroundView.alpha = 0.0;
        [UIView animateWithDuration:duration animations:^{
            self.alpha = 1.0;
            self.backgroundView.alpha = self.bgAlpha;
        }];
    } else {
        self.backgroundView.alpha = 0.0;
        [UIView animateWithDuration:duration animations:^{
            self.backgroundView.alpha = self.bgAlpha;
        }];
        [self hanlePopAnimationWithDuration:duration];
    }
    
}

- (void)hanlePopAnimationWithDuration:(NSTimeInterval)duration {
    switch (self.style) {
        case TMAnimationPopStyleScale:
        {
            [self animationWithLayer:self.contentView.layer duration:duration values:@[@0.0,@1.2,@1.0]];
        }
            break;
        case TMAnimationPopStyleShakeFromTop:
        case TMAnimationPopStyleShakeFromRight:
        case TMAnimationPopStyleShakeFromBottom:
        case TMAnimationPopStyleShakeFromLeft:
        {
            CGPoint startPoint = self.contentView.layer.position;
            if (self.style == TMAnimationPopStyleShakeFromTop) {
                self.contentView.layer.position = CGPointMake(startPoint.x, -startPoint.y);
            } else if (self.style == TMAnimationPopStyleShakeFromBottom) {
                self.contentView.layer.position = CGPointMake(startPoint.x, (kHeight + startPoint.y));
            } else if (self.style == TMAnimationPopStyleShakeFromLeft) {
                self.contentView.layer.position = CGPointMake(-startPoint.x, startPoint.y);
            } else if (self.style == TMAnimationPopStyleShakeFromRight) {
                self.contentView.layer.position = CGPointMake((kWidth + startPoint.x), startPoint.y);
            }
            [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.contentView.layer.position = startPoint;
            } completion:nil];
        }
            break;
            
        default:
            break;
    }
}

- (void)animationWithLayer:(CALayer *)layer duration:(NSTimeInterval)duration values:(NSArray *)values {
    CAKeyframeAnimation *kfAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    kfAnimation.duration = duration;
    kfAnimation.removedOnCompletion = NO;
    kfAnimation.fillMode = kCAFillModeForwards;
    
    NSMutableArray *valueArr = [NSMutableArray arrayWithCapacity:values.count];
    for (NSUInteger i = 0; i < values.count; i ++) {
        CGFloat valueScale = [values[i] floatValue];
       [valueArr addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(valueScale, valueScale, valueScale)]];
    }
    
    kfAnimation.values = valueArr;
    kfAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    [layer addAnimation:kfAnimation forKey:nil];
}

- (void)dismiss {
    
    NSTimeInterval duration = [self getPopDefaultDurationWithStyle:self.style];
    
    if (self.style == TMAnimationPopStyleNO) {
        [UIView animateWithDuration:duration animations:^{
            self.alpha = 0.0;
            self.backgroundView.alpha = 0.0;
        }];
    } else {
        [UIView animateWithDuration:duration animations:^{
            self.backgroundView.alpha = 0.0;
        }];
        [self hanleDismissAnimationDuration:duration];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeFromSuperview];
    });
}

- (void)hanleDismissAnimationDuration:(NSTimeInterval)duration {

    switch (self.style) {
        case TMAnimationPopStyleScale:
        {
            [self animationWithLayer:self.contentView.layer duration:duration values:@[@1.0,@0.66,@0.33,@0.01]];
        }
            break;
        case TMAnimationPopStyleShakeFromTop:
        case TMAnimationPopStyleShakeFromBottom:
        case TMAnimationPopStyleShakeFromLeft:
        case TMAnimationPopStyleShakeFromRight:
        {
            CGPoint startPoint = self.contentView.layer.position;
            CGPoint endPoint = self.contentView.layer.position;
            if (self.style == TMAnimationPopStyleShakeFromTop) {
                endPoint = CGPointMake(startPoint.x, -startPoint.y);
            } else if (self.style == TMAnimationPopStyleShakeFromBottom) {
                endPoint = CGPointMake(startPoint.x, (kHeight + startPoint.y));
            } else if (self.style == TMAnimationPopStyleShakeFromLeft) {
                endPoint = CGPointMake(-startPoint.x, startPoint.y);
            } else if (self.style == TMAnimationPopStyleShakeFromRight) {
                endPoint = CGPointMake((kWidth + startPoint.x), startPoint.y);
            }
            [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.contentView.layer.position = endPoint;
            } completion:nil];
        }
            break;
            
        default:
            break;
    }
}

- (NSTimeInterval)getPopDefaultDurationWithStyle:(TMAnimationPopStyle)style {
    if (style == TMAnimationPopStyleNO) {
        return 0.2f;
    } else if (style == TMAnimationPopStyleScale) {
        return 0.3f;
    } else {
        return 0.8f;
    }
}

@end
