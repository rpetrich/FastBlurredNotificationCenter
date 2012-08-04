#import <UIKit/UIKit2.h>
#import <QuartzCore/QuartzCore2.h>
#import <SpringBoard/SpringBoard.h>
#import <IOSurface/IOSurface.h>
#import <CaptainHook/CaptainHook.h>

#define idForKeyWithDefault(dict, key, default)	 ([(dict) objectForKey:(key)]?:(default))
#define floatForKeyWithDefault(dict, key, default)   ({ id _result = [(dict) objectForKey:(key)]; (_result)?[_result floatValue]:(default); })
#define NSIntegerForKeyWithDefault(dict, key, default) (NSInteger)({ id _result = [(dict) objectForKey:(key)]; (_result)?[_result integerValue]:(default); })
#define BOOLForKeyWithDefault(dict, key, default)    (BOOL)({ id _result = [(dict) objectForKey:(key)]; (_result)?[_result boolValue]:(default); })

#define PreferencesFilePath [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.mpow.BlurredNCplus.plist"]
#define PreferencesChangedNotification "com.mpow.BlurredNCplus.prefs"


#define GetPreference(name, type) type ## ForKeyWithDefault(prefsDict, @#name, (name))

static NSDictionary *prefsDict = nil;

static void preferenceChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[prefsDict release];
	prefsDict = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
}


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


BOOL blurred;
float red;
float blue;
float green;
float alpha;
float blur;

%hook SBBulletinListView

static UIView *activeView;
static BOOL blurredOrientationIsPortrait;

+ (UIImage *)linen
{
blurred= [[prefsDict objectForKey:@"useorigbg"]boolValue];
if (blurred==1){
return %orig;
}
	return nil;
}

- (id)initWithFrame:(CGRect)frame delegate:(id)delegate
{
red= [[prefsDict objectForKey:@"red"]floatValue]?:1.0f;
blue= [[prefsDict objectForKey:@"blue"]floatValue]?:1.0f;
green= [[prefsDict objectForKey:@"green"]floatValue]?:1.0f;
alpha= [[prefsDict objectForKey:@"alpha"]floatValue]?:1.0f;
blur= [[prefsDict objectForKey:@"blur"]floatValue]?:1.0f;

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
				CAFilter *filter = [CAFilter filterWithType:@"gaussianBlur"];
				[filter setValue:[NSNumber numberWithFloat:blur] forKey:@"inputRadius"];
				filters = [[NSArray alloc] initWithObjects:filter, nil];

			CALayer *layer = activeView.layer;
			layer.filters = filters;
			layer.shouldRasterize = YES;
			activeView.alpha = 0.0f;
			activeView.userInteractionEnabled = YES;
		}
		[self insertSubview:activeView atIndex:0];
		[self linenView].backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
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


__attribute__((constructor)) static void fis_init() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// SpringBoard only!
	if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
		return;

	prefsDict = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferenceChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);

	[pool release];
}
