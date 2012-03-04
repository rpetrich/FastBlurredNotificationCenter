#import <UIKit/UIKit2.h>
#import <QuartzCore/QuartzCore2.h>
#import <SpringBoard/SpringBoard.h>
#import <IOSurface/IOSurface.h>
#import <CaptainHook/CaptainHook.h>

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
static BOOL blurredOrientationIsPortrait;

+ (UIImage *)linen
{
	return nil;
}

- (id)initWithFrame:(CGRect)frame delegate:(id)delegate
{
	if ([[%c(SBAwayController) sharedAwayController] isLocked])
		return %orig;
	if ((self = %orig)) {
		if (!activeView) {
			IOSurfaceRef surface = [UIWindow createScreenIOSurface];
			UIImageOrientation imageOrientation;
			switch ([(SpringBoard *)UIApp activeInterfaceOrientation]) {
				case UIInterfaceOrientationPortrait:
				default:
					imageOrientation = UIImageOrientationUp;
					blurredOrientationIsPortrait = YES;
					break;
				case UIInterfaceOrientationPortraitUpsideDown:
					imageOrientation = UIImageOrientationDown;
					blurredOrientationIsPortrait = YES;
					break;
				case UIInterfaceOrientationLandscapeLeft:
					imageOrientation = UIImageOrientationRight;
					blurredOrientationIsPortrait = NO;
					break;
				case UIInterfaceOrientationLandscapeRight:
					imageOrientation = UIImageOrientationLeft;
					blurredOrientationIsPortrait = NO;
					break;
			}
			UIImage *image = [[UIImage alloc] _initWithIOSurface:surface scale:[UIScreen mainScreen].scale orientation:imageOrientation];
			CFRelease(surface);
			activeView = [[UIImageView alloc] initWithImage:image];
			[image release];
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
			activeView.userInteractionEnabled = YES;
		}
		[self insertSubview:activeView atIndex:0];
		[self linenView].backgroundColor = [UIColor colorWithWhite:0.0f alpha:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 0.0f : 0.50f];
	}
	return self;
}


- (void)dealloc
{
	[activeView release];
	activeView = nil;
	%orig;
}

- (void)layoutForOrientation:(UIInterfaceOrientation)orientation
{
	activeView.alpha = blurredOrientationIsPortrait == UIInterfaceOrientationIsPortrait(orientation);
	%orig;
}

- (void)positionSlidingViewAtY:(CGFloat)y
{
	CGFloat height = [self linenView].frame.size.height;
	UIInterfaceOrientation orientation = CHIvar(self, _orientation, UIInterfaceOrientation);
	CGFloat uncurvedAlpha = (blurredOrientationIsPortrait == UIInterfaceOrientationIsPortrait(orientation)) ? (height ? (y / height) : 1.0f) : 0.0f;
	CGFloat value = 1.0f - uncurvedAlpha;
	activeView.alpha = 1.0f - (value * value);
	%orig;
}

%end
