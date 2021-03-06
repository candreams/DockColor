#import <UIKit/UIKit.h>
#define PREFSFILENAME "com.inasser.dockcolor"

#define kDefaultWhiteColor [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f]

BOOL enabled;
UIColor *color;
float BGalpha;
UIView *bGView;
UIView *viewToAdd;
%hook SBDockView

-(void)layoutSubviews {
    %orig;
    if (enabled == YES) {
        
        bGView = MSHookIvar<UIView *>(self, "_backgroundView");
        bGView.alpha = BGalpha / 20.0;
        
         viewToAdd = [[UIView alloc] initWithFrame:bGView.frame];
         viewToAdd.backgroundColor = color;
        
         [bGView addSubview:viewToAdd];
}
}

%end

static UIColor* parseColorFromPreferences(NSString* string) {
    NSArray *prefsarray = [string componentsSeparatedByString: @":"];
    NSString *hexString = [prefsarray objectAtIndex:0];
    double alpha = [[prefsarray objectAtIndex:1] doubleValue];
    
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [[UIColor alloc] initWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}
static void reloadPrefs() {
  
   CFPreferencesAppSynchronize(CFSTR(PREFSFILENAME));
   enabled =  !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFSFILENAME)) ? YES : [(id)CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFSFILENAME))) boolValue];
    color =!CFPreferencesCopyAppValue(CFSTR("kColor"), CFSTR(PREFSFILENAME)) ? kDefaultWhiteColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("kColor"), CFSTR(PREFSFILENAME)));
BGalpha = !CFPreferencesCopyAppValue(CFSTR("alpha"), CFSTR(PREFSFILENAME)) ? 1 : [(id)CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("alpha"), CFSTR(PREFSFILENAME))) floatValue];
    if (enabled == YES) {
        viewToAdd.backgroundColor = color;
         bGView.alpha = BGalpha / 20.0;
    }
    if (enabled == NO) {
        viewToAdd.backgroundColor = [UIColor clearColor];
        bGView.alpha = 1.0;
    }
}

%ctor {
    reloadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)reloadPrefs,
                                    CFSTR("com.inasser.dockcolor/prefschanged"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
   
}