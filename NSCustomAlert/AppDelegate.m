//
//  AppDelegate.m
//  NSCustomAlert
//
//  Created by Mark Coniglio on 11/20/20.
//  Copyright © 2020 Mark Coniglio. All rights reserved.
//

#import "AppDelegate.h"
#import "NSCustomAlert.h"
#import "NSAlertProtocol.h"

/*
static NSString* NSAppearanceNameDarkAqua = @"NSAppearanceNameAquaDark";

static BOOL appearanceIsDark(NSAppearance * appearance)
{
    if (@available(macOS 10.14, *)) {
        NSAppearanceName basicAppearance = [appearance bestMatchFromAppearancesWithNames:@[
            NSAppearanceNameAqua,
            NSAppearanceNameDarkAqua
        ]];
        return [basicAppearance isEqualToString:NSAppearanceNameDarkAqua];
    } else {
        return NO;
    }
}
*/

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	if (@available(macOS 10.14, *)) {
	
		// appearance mode will be nil for light mode and "Dark" for dark mode
		NSString* appearanceMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
	
		if (appearanceMode != nil && ([appearanceMode compare:@"Dark"] == NSOrderedSame)) {
			[NSApp setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
		}
	}
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}


#define USE_REAL_NSALERT		0

-(IBAction)showCustomAlert:(id)senderId
{
	#if USE_REAL_NSALERT
	NSAlert* alert = [[NSAlert alloc] init];
	#else
	NSCustomAlert* alert = [[NSCustomAlert alloc] init];
	#endif
	
	id<NSAlertProtocol> alertp = (id<NSAlertProtocol>) alert;

	alertp.messageText = @"This is a really long error talking about something that went wrong with the system and requires a really long explanation.";
	alertp.informativeText = @"This is the informative text that will go on and on and on and on and on and on et. all ad infinitum ad infinitum ad infinitum ad infinitum ad infinitum ad infinitum ad infinitum ad infinitum ad infinitum ad infinitum ad infinitum.";
	alertp.alertStyle = NSAlertStyleCritical;
	alert.showsSuppressionButton = YES;
	[alert.suppressionButton setTitle:@"Custom Supression Button"];
	alertp.icon = [NSImage imageNamed:NSImageNameComputer];
	
	[alertp addButtonWithTitle:@"OK"];
	[alertp addButtonWithTitle:@"Cancel"];
	[alertp addButtonWithTitle:@"Show Options..."];
	
	#if 1
	
		[alertp beginSheetModalForWindow:_window completionHandler:^(NSInteger response){
		[alertp release];
		NSLog(@"Response = %d\n", (int) response);
		
	}];
	
	#else
	
		NSInteger response = [alert runModal];
		NSLog(@"Response = %d\n", (int) response);
		[alert release];

	#endif
}
@end
