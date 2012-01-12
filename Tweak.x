#import <UIKit/UIKit2.h>
#import <QuartzCore/QuartzCore2.h>
#import <SpringBoard/SpringBoard.h>
#import <IOSurface/IOSurface.h>

@interface UIImage (IOSurface)
- (id)_initWithIOSurface:(IOSurfaceRef)surface scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;
@end

%config(generator=internal)

@interface SBBulletinListView : UIView
+ (UIImage *)linen;
- (UIImageView *)linenView;
- (UIView *)slidingView;
- (void)positionSlidingViewAtY:(CGFloat)y;
@end

%hook SBBulletinListView

static UIView *activeView;

+ (UIImage *)linen
{
	return nil;
}

- (id)initWithFrame:(CGRect)frame delegate:(id)delegate
{
	if ((self = %orig)) {
		IOSurfaceRef surface = [UIWindow createScreenIOSurface];
		UIImageOrientation imageOrientation;
		switch ([(SpringBoard *)UIApp activeInterfaceOrientation]) {
			case UIInterfaceOrientationPortrait:
			default:
				imageOrientation = UIImageOrientationUp;
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				imageOrientation = UIImageOrientationDown;
				break;
			case UIInterfaceOrientationLandscapeLeft:
				imageOrientation = UIImageOrientationRight;
				break;
			case UIInterfaceOrientationLandscapeRight:
				imageOrientation = UIImageOrientationLeft;
				break;
		}
		UIImage *image = [[UIImage alloc] _initWithIOSurface:surface scale:[UIScreen mainScreen].scale orientation:imageOrientation];
		CFRelease(surface);
		if (!activeView)
			activeView = [[UIImageView alloc] initWithImage:image];
		static NSArray *filters;
		if (!filters) {
			CAFilter *filter = [CAFilter filterWithType:@"gaussianBlur"];
			[filter setValue:[NSNumber numberWithFloat:5.0f] forKey:@"inputRadius"];
			filters = [[NSArray alloc] initWithObjects:filter, nil];
		}
		CALayer *layer = activeView.layer;
		layer.filters = filters;
		layer.shouldRasterize = YES;
		activeView.alpha = 0.0f;
		[self insertSubview:activeView atIndex:0];
		[self linenView].backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
	}
	return self;
}


- (void)dealloc
{
	[activeView release];
	activeView = nil;
	%orig;
}

- (void)positionSlidingViewAtY:(CGFloat)y
{
	CGFloat height = self.bounds.size.height;
	activeView.alpha = height ? (y / height) : 1.0f;
	%orig;
}

%end
