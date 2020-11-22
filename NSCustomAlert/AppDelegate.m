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


#define USE_REAL_NSALERT		1

-(IBAction)showCustomAlertShort:(id)senderId
{
	NSString* messageText = @"This is a shorter error talking about something that went wrong. ";
	
	NSString* informativeText = @"This is the informative text that will be longer but not so long as to trigger the custom alert.";
	
	[self showCustomAlertForText:messageText infoText:informativeText];
}

-(IBAction)showCustomBelowEdgeCase:(id)senderId
{
	NSString* messageText = @"This is a shorter error talking about something that went wrong. We will keep extending to the edge case.";
	
	NSString* informativeText = @"This is the informative text that will be longer but not so long as to trigger the custom alert. Let's add some more text to see what's how far we can go before we cross the threshold into the next line.";
	
	[self showCustomAlertForText:messageText infoText:informativeText];
}

-(IBAction)showCustomAboveEdgeCase:(id)senderId
{
	NSString* messageText = @"This is a shorter error talking about something that went wrong. We will keep extending it until it reaches the edge case.";
	
	NSString* informativeText = @"This is the informative text that will be longer but not so long as to trigger the custom alert. Let's add some more text to see what's how far we can go before we cross the threshold into the next line, which is here.";

	[self showCustomAlertForText:messageText infoText:informativeText];
}

-(IBAction)showCustomAlertLong:(id)senderId
{
	NSString* messageText = @"This is a really long error talking about something that went wrong with the system and requires a really long explanation. This sentence extends the length of the message by a few words.";
	
	NSString* informativeText = @"This is the informative text that will go on and on and on and on and on and on et. The quick brown fox jumped over the lazy dog and then catapulted himself into the outer reaches of the universe. Now he is stardust, and will expand outward until the end of time. What happens if we make this even longer? Will it push the main text so far up that we can't read it?";
	
	[self showCustomAlertForText:messageText infoText:informativeText];
}

-(void) showCustomAlertForText:(NSString*)inMsgText infoText:(NSString*)inInfoText
{
	id<NSAlertProtocol> alertp = [NSCustomAlert createAlertForText:inMsgText infoText:inInfoText];

	alertp.messageText = inMsgText;
	alertp.informativeText = inInfoText;
	alertp.alertStyle = NSAlertStyleCritical;
	// alertp.showsSuppressionButton = YES;
	// alertp.suppressionButton.title = @"Custom Supression Button";
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
