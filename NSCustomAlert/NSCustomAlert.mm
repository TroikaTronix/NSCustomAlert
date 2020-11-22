// --------------------------------------------------------------------------------
//	NSAlertProtocol
// --------------------------------------------------------------------------------
//
// (c) 2020 Mark F. Coniglio - all rights reserved
//
// A replacement for NSAlert that ensuress the ability to display long strings of
// text, overcoming this limitation for Big Sur's new vertically oriented alert
// dialogs.
//
// Our measurements show that Big Sur alert boxes offer a space of 220 x 145 pixels
// for the main message and informational message combined, including 15 pixel
// gap between the two.
//
// So the strategy to decide which alert to use requires measuring both the
// the height main message text and the informationaional text within a 220px
// frame. If their combined height + 15px > 220, then we show our custom dialog
// box. Otherwise we show the our custom alert modeled on the alert boxes in
// macOS Catalina and prior.

#include "NSCustomAlert.h"

//
// (c) 2020 Mark F. Coniglio - all rights reserved

@implementation NSCustomAlert

@synthesize messageText;
@synthesize informativeText;
@synthesize icon = _icon;
@synthesize buttons;
@synthesize showsHelp;
@synthesize helpAnchor;
@synthesize alertStyle;
@synthesize delegate;
@synthesize showsSuppressionButton;
@synthesize suppressionButton;
@synthesize accessoryView;

+ (NSCustomAlert *)alertWithError:(NSError *)error
{
	NSCustomAlert* alert = [[NSCustomAlert alloc] init];
	return alert;
}

+ (id<NSAlertProtocol>) createAlertForText:(NSString*) msgText infoText:(NSString*) infoText
{

	id<NSAlertProtocol> alert = NULL;
	
	const CGFloat textWidth = 145.0f; // whatever your desired width is
	const CGFloat maxHeightForBigSurDialog = 220.0f; // whatever your desired width is

	CGFloat totalHeight = 0.0f;

	if (msgText != NULL) {
		NSAttributedString* attrMsgText = [NSCustomAlert createStyledText:msgText fontSize:13 makeBold:YES];;
		CGRect rect = [attrMsgText boundingRectWithSize:CGSizeMake(textWidth, 10000) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
		totalHeight += rect.size.height;
	}

	if (infoText != NULL) {
		
		NSAttributedString* attrInfoText = [NSCustomAlert createStyledText:infoText fontSize:11 makeBold:NO];;
		CGRect rect = [attrInfoText boundingRectWithSize:CGSizeMake(textWidth, 10000) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
		totalHeight += rect.size.height;
		totalHeight += 15.0;
	}

	if (totalHeight > maxHeightForBigSurDialog) {
		alert = (id<NSAlertProtocol>) [[NSCustomAlert alloc] init];
	} else {
		alert = (id<NSAlertProtocol>) [[NSAlert alloc] init];
	}
	
	return alert;
}

// --------------------------------------------------------------------------------
// init
// --------------------------------------------------------------------------------
// init the NSCustomoAlert object, create it's button array and it's window

- (id) init
{
	self = [super init];
	if (self != NULL) {
		_buttons = [[NSMutableArray alloc] init];
		_panel = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100)
			styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskDocModalWindow
			backing:NSBackingStoreBuffered
			defer:YES];
		
		if (@available(macOS 10.14, *)) {
			
			NSView* view = [_panel contentView];
			
			NSVisualEffectView* effect = [[[NSVisualEffectView alloc] init] autorelease];
			[effect setFrame:[view frame]];
			
			effect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
			effect.state = NSVisualEffectStateActive;
			effect.material = NSVisualEffectMaterialWindowBackground;
			effect.wantsLayer = true;
			effect.layer.cornerRadius = 15.0;
			effect.layer.masksToBounds = true;
			
			[_panel setOpaque:NO];
			_panel.backgroundColor = [NSColor clearColor];
			_panel.contentView = effect;
			_panel.titlebarAppearsTransparent = YES;
			// _panel.titleVisibility = NSWindowTitleHidden;

		}
	}
	return self;
}

// --------------------------------------------------------------------------------
// dealloc
// --------------------------------------------------------------------------------
// Release all resources. See 'releaseAll' for notes about this code being designed
// for non-ARC memory management.

- (void) dealloc
{
	[self releaseAll];
	[super dealloc];
}

// --------------------------------------------------------------------------------
// resizeImage
// --------------------------------------------------------------------------------
// resize an image to the specified size

+ (NSImage*) resizeImage:(NSImage*)sourceImage size:(NSSize)size
{
	NSRect targetFrame = NSMakeRect(0, 0, size.width, size.height);
	NSImage* targetImage = nil;
	NSImageRep *sourceImageRep = [sourceImage bestRepresentationForRect:targetFrame context:nil  hints:nil];

	targetImage = [[[NSImage alloc] initWithSize:size] autorelease];

	[targetImage lockFocus];
	[sourceImageRep drawInRect: targetFrame];
	[targetImage unlockFocus];

	return targetImage;
}

// --------------------------------------------------------------------------------
// alertIconFromImage
// --------------------------------------------------------------------------------
// This method generates an 64x64 pixel NSImage to use as an icon in the alert.
//
// The base image is either the application's icon (if icon has not been set) or
// the icon image provided by setting the icon member or calling setIcon.
//
// For alert styles of NSAlertStyleWarning or NSAlertStyleInformational, the image
// returned will be the base image described above.
//
// For an alert style of NSAlertStyleCritical, the image returned will be the
// caution icon "badged" by the base icon drawn at a smaller size of 32 x 32.
//
// This duplicates the icon display for NSAlert under macOS Mojave.
//
- (NSImage*) alertIconFromImage:(NSImage*)inSourceIcon
{
	NSImage* outIcon = [[[NSImage alloc] initWithSize:NSMakeSize(64, 64)] autorelease];

	NSImage* sourceIcon = inSourceIcon;
	if (inSourceIcon == NULL) {
		sourceIcon = [NSImage imageNamed:NSImageNameApplicationIcon];
	}
	
	switch (alertStyle) {
	
	case NSAlertStyleWarning:
		[outIcon lockFocus];
		[sourceIcon drawInRect:NSMakeRect(0, 0, 64, 64)];
		[outIcon unlockFocus];
		break;
		
	case NSAlertStyleInformational:
		[outIcon lockFocus];
		[sourceIcon drawInRect:NSMakeRect(0, 0, 64, 64)];
		[outIcon unlockFocus];
		break;
		
	case NSAlertStyleCritical:
		{
			NSImage* caution = [NSImage imageNamed:NSImageNameCaution];
			[caution setSize:NSMakeSize(64, 64)];
			NSSize cautionImageSize = [caution size];
			
			sourceIcon = [NSCustomAlert resizeImage:sourceIcon size:NSMakeSize(32,32)];
			NSSize sourceIconSize = [sourceIcon size];
			
			[outIcon lockFocus];
			[caution drawInRect:NSMakeRect(0, 0, cautionImageSize.width, cautionImageSize.height)];
			[sourceIcon drawInRect:NSMakeRect(cautionImageSize.width-sourceIconSize.width, 0, sourceIconSize.width, sourceIconSize.height)];
			[outIcon unlockFocus];
		}
		break;
	}
	
	return outIcon;
}

// --------------------------------------------------------------------------------
// icon
// --------------------------------------------------------------------------------
// return the icon that will be drawn by the alert. If the icon property has not
// been set, or setIcon called with a valid icon image, then this property will
// return the app icon (informational or warning alerts) or the warning icon
// "badged" with the application icon.

- (NSImage*) icon
{
	if (_icon == NULL) {
		return [self alertIconFromImage:NULL];
	} else {
		return _icon;
	}
}

// --------------------------------------------------------------------------------
// setIcon
// --------------------------------------------------------------------------------
// sets the icon used when displaying this alert. Note that if you do not set the
// icon explicitiy, then the application icon will be used.

- (void) setIcon:(NSImage*)inIcon
{
	if (_icon != NULL) {
		[_icon release];
		_icon = NULL;
	}
	
	_icon = inIcon;
	
	if (_icon != NULL) {
		[_icon retain];
		[_icon setSize:NSMakeSize(64, 64)];
	}
}

// --------------------------------------------------------------------------------
// return the alert's window
// --------------------------------------------------------------------------------
- (NSWindow*) window
{
	return _panel;
}


// --------------------------------------------------------------------------------
// expandButtonSize
// --------------------------------------------------------------------------------
// Expand the button's width by inExpandHorz and then ensure the button is has a
// minimum widht of inMinWidth
- (void) expandButtonSize:(NSButton*)btn expandHorz:(CGFloat)inExpandHorz minWidth:(CGFloat)inMinWidth
{
	NSRect frame = [btn frame];
	frame.size.width += inExpandHorz * 2.0f;
	if (frame.size.width < inMinWidth) {
		frame.size.width = inMinWidth;
	}
	[btn setFrame:frame];
}

// --------------------------------------------------------------------------------
// addButtonWithTitle
// --------------------------------------------------------------------------------
// Add a button to the alert

- (NSButton *)addButtonWithTitle:(NSString *)title
{
	NSRect frame = NSMakeRect(0, 0, 40, 30);
    NSButton* btn = [[[NSButton alloc] initWithFrame:frame] autorelease];
	[btn setTitle:title];

    [btn setTarget:self];
    [btn setAction:@selector(buttonPressed:)];
	
    // [btn setButtonType:NSMomentaryLightButton];
    [btn setBezelStyle:NSRoundedBezelStyle];

    [btn sizeToFit];
	
    [self expandButtonSize:btn expandHorz:10.0f minWidth:75.0f];
	
	[_buttons addObject:btn];
	
//	if (@available(macOS 10.14, *)) {
//		[[btn cell] setBackgroundColor:[NSColor redColor]];
//	}
	
	[[_panel contentView] addSubview:btn];
	
	return btn;
}

// --------------------------------------------------------------------------------
// buttonPressed
// --------------------------------------------------------------------------------
// Handle a button click in the alert. When this method is executed, either
// endSheet or stopModalWithCode is called to store the users response and exit
// the alert. The alert's window is also hidden

- (void) buttonPressed:(id)sender
{
	NSModalResponse response = 0;
	
	NSUInteger buttonCount = [_buttons count];
	for (NSUInteger i=0; i<buttonCount; i++) {
		NSButton* btn = [_buttons objectAtIndex:i];
		if (sender == btn) {
			response = i+1;
			break;
		}
	}
	
	if (_docWindow != NULL) {
		[_docWindow endSheet:_panel returnCode:response];
	} else {
		[NSApp stopModalWithCode:response];
	}
	
	[_panel orderOut:NULL];
}

// --------------------------------------------------------------------------------
// createTextField
// --------------------------------------------------------------------------------
// Create a static text field for the main messaged and informational text using
// the specified NSAttributedSring

+ (NSTextField*) createTextField:(NSAttributedString*)inString
{
	NSTextField* tf = [[NSTextField alloc] init];
	[tf setDrawsBackground:NO];
	[tf setBordered:NO];
	[tf setBezeled:NO];
	[tf setEditable:NO];
	[tf setSelectable:YES];
	[tf setAttributedStringValue:inString];
	return tf;
}

+ (NSButton*) createSupressionButton
{
	NSRect frame;
	frame.size.width = frame.size.height = 18;
	NSButton *chkbox = [[NSButton alloc] initWithFrame:frame];
	[chkbox setButtonType:NSSwitchButton];
	[chkbox setTitle:@"Do not show this message again"];
	return chkbox;
}

// --------------------------------------------------------------------------------
// suppressionButton
// --------------------------------------------------------------------------------
// return the alert's suppression button.

- (NSButton*) suppressionButton
{
	if (_suppressionButton == NULL) {
		_suppressionButton = [NSCustomAlert createSupressionButton];
	}
	return _suppressionButton;
}

// --------------------------------------------------------------------------------
// createStyledText
// --------------------------------------------------------------------------------
// Create the styled text used to draw the alert's main message and informational
// message. The caller can specify the point size and whether or not the text will
// be bold.

+ (NSAttributedString*) createStyledText:(NSString*) inString fontSize:(CGFloat)inFontSize makeBold:(BOOL)inMakeBold
{
	NSMutableAttributedString* str = [[[NSMutableAttributedString alloc] initWithString:inString] autorelease];
	NSUInteger strLen = [str length];

	// SET WRAPPING PARAGRAPH STYLE
	NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	paraStyle.lineBreakMode = NSLineBreakByWordWrapping;
	paraStyle.lineHeightMultiple = 0.85;

	// SET FONT, FONT SIZE, BOLD OR NORMAL
	NSFont* font = NULL;
	if (inMakeBold) {
		font = [NSFont fontWithName:@"Helvetica Neue Bold" size:inFontSize];
	} else {
		font = [NSFont fontWithName:@"Helvetica Neue" size:inFontSize];
	}
	
	NSDictionary *attr = @{
		NSFontAttributeName: font,
		NSParagraphStyleAttributeName: paraStyle
	};
	
	[str setAttributes:attr range:NSMakeRange(0, strLen)];
	
	return str;
}

// --------------------------------------------------------------------------------
// layout
// --------------------------------------------------------------------------------
// Lay out all the elements of the dialog, dynamically resizing them based on the
// size of the text they contain

- (void)layout
{
	const CGFloat kFrameIconLeftMargin = 20.0;
	const CGFloat kFrameLeftMargin = 100.0;
	const CGFloat kFrameRightMargin = 20.0;
	const CGFloat kFrameTopMargin = 15.0;
	const CGFloat kFrameBottomMargin = 15.0;
	const CGFloat kInterButtonMargin = 0.0;
	const CGFloat kDefaultTextWidth = 345.0;
	const CGFloat kInterTextSpacing = 10.0;

	// --------------------------------------------------
	// ACCUMULATE BUTTON WIDTHS AND MEASURE HEIGHT
	// --------------------------------------------------
	
	// CALCULATE BUTTON WIDTHS AND MAXIMUM HEIGHT
	CGFloat totalButtonWidth = 0.0;
	CGFloat maxButtonHeight = 0.0;
	NSUInteger buttonCount = [_buttons count];
	
	if (buttonCount == 0) {
		[self addButtonWithTitle:@"OK"];
		buttonCount = [_buttons count];
	}
	
	for (NSUInteger i=0; i<buttonCount; i++) {
		NSButton* btn = [_buttons objectAtIndex:i];
		NSRect btnFrame = [btn frame];
		totalButtonWidth += btnFrame.size.width;
		if (btnFrame.size.height > maxButtonHeight) {
			maxButtonHeight = btnFrame.size.height;
		}
	}
	
	// total button width including the inter-button margin
	CGFloat totalButtonWidthWithInterButtonMargins = totalButtonWidth + (buttonCount-1) * kInterButtonMargin;
	
	// text width will be the larger of the kDefaultTextWidth and the window
	// width calculated just above
	CGFloat textWidth = (kDefaultTextWidth > totalButtonWidthWithInterButtonMargins) ? kDefaultTextWidth : totalButtonWidthWithInterButtonMargins;
	
	// total window width based on the total width needed for the buttons
	CGFloat tempWindowWidth = textWidth + (kFrameLeftMargin + kFrameRightMargin);
	
	// --------------------------------------------------
	// MAIN MESSAGE TEXT FIELD
	// --------------------------------------------------
	
	// PREPARE MESSAGE FIELD
	NSRect msgFrame = NSZeroRect;
	if (true) {
	
		_messageField = [NSCustomAlert createTextField:[NSCustomAlert createStyledText:messageText fontSize:13 makeBold:YES]];
		[_messageField setFrame:NSMakeRect(0, 0, textWidth, 10)];
		[[_panel contentView] addSubview:_messageField];
		
		NSRect frame = [_messageField frame];
		frame.size.height = CGFLOAT_MAX;
		frame.size.height = [_messageField.cell cellSizeForBounds: frame].height;
		[_messageField setFrame:frame];
		
		msgFrame = [_messageField frame];
	}
	
	// --------------------------------------------------
	// ADDITIONAL INFO TEXT FIELD
	// --------------------------------------------------
	
	// PREPARE ADDTIONAL INFORMATION TEXT FIELD
	NSRect infoFrame = NSZeroRect;
	if (informativeText != NULL) {
		_infoField = [NSCustomAlert createTextField:[NSCustomAlert createStyledText:informativeText fontSize:11 makeBold:NO]];
		[_infoField setFrame:NSMakeRect(0, 0, textWidth, 10)];

		NSRect frame = [_infoField frame];
		frame.size.height = CGFLOAT_MAX;
		frame.size.height = [_infoField.cell cellSizeForBounds: frame].height;
		[_infoField setFrame:frame];

		[[_panel contentView] addSubview:_infoField];
		infoFrame = [_infoField frame];
	}
	
	// --------------------------------------------------
	// SUPRESSION BUTTON
	// --------------------------------------------------
	
	NSRect suppressionButtonFrame = NSZeroRect;
	if (showsSuppressionButton) {
		if (_suppressionButton == NULL) {
			_suppressionButton = [NSCustomAlert createSupressionButton];
		}
		[_suppressionButton sizeToFit];
		suppressionButtonFrame = [_suppressionButton frame];
		[[_panel contentView] addSubview:_suppressionButton];
	}
	
	// --------------------------------------------------
	// SIZE ALERT WINDOW
	// --------------------------------------------------

	// final window width will be based on max button or text width
	CGFloat windowWidth = tempWindowWidth;
	
	// now that we have the message text sized, and we know the
	// max button height, we can calculated the height of the window
	CGFloat windowHeight = (kFrameTopMargin + kFrameBottomMargin)
		+ msgFrame.size.height
		+ kInterTextSpacing
		+ maxButtonHeight;
	
	// if we have information text, then increase the height to
	// include room for that text field
	if (_infoField != NULL) {
		windowHeight += infoFrame.size.height + kInterTextSpacing;
	}
	
	// if we have information text, then increase the height to
	// include room for that text field
	if (_suppressionButton != NULL) {
		windowHeight += suppressionButtonFrame.size.height + kInterTextSpacing;
	}
	
	// RESIZE WINDOW TO ACCOMODATE ALL CONTROLS
	[_panel setContentSize:NSMakeSize(windowWidth, windowHeight)];
	
	// --------------------------------------------------
	// PLACE BUTTONS
	// --------------------------------------------------

	// SPECIAL CASE FOR THREE BUTTONS
	// if we have three buttons, we will arrange the first
	// two flush right, and then arrange the third button
	// flush left.
	NSUInteger maxButtonsBottomRight = buttonCount;
	if (buttonCount == 3) {
		maxButtonsBottomRight = 2;
	}
	
	// ARRANGE BUTTONS ALONG THE BOTTOM
	CGFloat btnTop = kFrameBottomMargin;
	CGFloat btnLeft = windowWidth - kFrameRightMargin;
	NSButton* firstButton = [_buttons objectAtIndex:0];
	NSEdgeInsets insets = [firstButton alignmentRectInsets];
	btnLeft += insets.right;
	btnTop -= insets.bottom;
	
	for (NSUInteger i=0; i<maxButtonsBottomRight; i++) {
		NSButton* btn = [_buttons objectAtIndex:i];
		NSRect btnFrame = [btn frame];
		btnFrame.origin.y = btnTop;
		btnLeft -= btnFrame.size.width;
		btnFrame.origin.x = btnLeft;
		btnLeft -= kInterButtonMargin;
		[btn setFrame:btnFrame];
	}

	// SPECIAL CASE: ARRANGE THIRD BUTTON FLUSH LEFT
	if (buttonCount == 3) {
		NSButton* btn = [_buttons objectAtIndex:2];
		NSEdgeInsets insets = [btn alignmentRectInsets];
		NSRect btnFrame = [btn frame];
		btnFrame.origin.y = btnTop;
		btnFrame.origin.x = kFrameLeftMargin - insets.left;
		[btn setFrame:btnFrame];
	}

	// calculate top of first text box
	CGFloat textTop = btnTop + maxButtonHeight + kInterTextSpacing;
	
	// --------------------------------------------------
	// PLACE SUPRESSION BUTTON IF PRESENT
	// --------------------------------------------------
	
	if (_suppressionButton != NULL) {
		suppressionButtonFrame.origin.y = textTop;
		suppressionButtonFrame.origin.x = kFrameLeftMargin;
		[_suppressionButton setFrame:suppressionButtonFrame];
		textTop += suppressionButtonFrame.size.height + kInterTextSpacing;
	}
	
	// --------------------------------------------------
	// PLACE TEXT
	// --------------------------------------------------
	
	// if we have an info field, put it into place
	if (_infoField != NULL) {
		infoFrame.origin.y = textTop;
		infoFrame.origin.x = kFrameLeftMargin;
		[_infoField setFrame:infoFrame];
		textTop += infoFrame.size.height + kInterTextSpacing;
	}
	
	// put the main message into place
	msgFrame.origin.y = textTop;
	msgFrame.origin.x = kFrameLeftMargin;
	[_messageField setFrame:msgFrame];
	textTop += msgFrame.size.height + kInterTextSpacing;

	// --------------------------------------------------
	// PLACE ICON
	// --------------------------------------------------
	
	// CREATE ICON IMAGE AND SIZE TO 64x64
	NSImage* sourceIcon = [self alertIconFromImage:_icon];
	NSSize imageSize = [sourceIcon size];
	
	// CREATE IMAGE VIEW FOR ICON
	_imageView = [[NSImageView imageViewWithImage:sourceIcon] retain];
	[[_panel contentView] addSubview:_imageView];
	CGFloat top = windowHeight - (kFrameTopMargin + imageSize.height);
	[_imageView setFrame:NSMakeRect(kFrameIconLeftMargin, top, imageSize.width, imageSize.height)];


	// clear any key equivalent
	if (buttonCount >= 1) {
		[[_buttons objectAtIndex:0] setKeyEquivalent:@""];
	}
	if (buttonCount >= 2) {
		[[_buttons objectAtIndex:1] setKeyEquivalent:@""];
	}
	
	// set key equivalents
	if (buttonCount >= 1) {
		[[_buttons objectAtIndex:0] setKeyEquivalent:@"\r"];
	}
	if (buttonCount >= 2) {
		[[_buttons objectAtIndex:1] setKeyEquivalent:@"\033"];
	}
}

// --------------------------------------------------------------------------------
// releaseAll
// --------------------------------------------------------------------------------
// IMPORTANT: NSCustomAlert was created for a non-ARC project, which means that the
// memory management (retain/release) is handled explicitly. You will need to
// modify this function for non-ARC projects.

- (void) releaseAll
{
	messageText = nil;
	informativeText = nil;
	
	// RELEASE MESSAGE FIELD
	if (_messageField != NULL) {
		[_messageField removeFromSuperview];
		[_messageField release];
		_messageField = NULL;
	}
	
	// RELEASE ADDITIONAL INFORMATION FIELD
	if (_infoField != NULL) {
		[_infoField removeFromSuperview];
		[_infoField release];
		_infoField = NULL;
	}

	// RELEASE IMAGE VIEW
	if (_imageView != NULL) {
		[_imageView removeFromSuperview];
		[_imageView release];
		_imageView = NULL;
	}

	if (_suppressionButton != NULL) {
		[_suppressionButton removeFromSuperview];
	}
	suppressionButton = nil;

	delegate = nil;
	accessoryView = nil;
	
	if (_helpButton != NULL) {
		[_helpButton removeFromSuperview];
		[_helpButton release];
		_helpButton = nil;
	}

	if (_buttons != NULL) {
		[_buttons release];
		_buttons = NULL;
	}
	
	if (_panel != NULL) {
		[_panel release];
		_panel = NULL;
	}
	
}

// --------------------------------------------------------------------------------
// runModal
// --------------------------------------------------------------------------------
// Show the alert as an application modal dialog

- (NSModalResponse)runModal
{
	[self layout];
	return [NSApp runModalForWindow:_panel];
}

// --------------------------------------------------------------------------------
// beginSheetModalForWindow:completionHandler
// --------------------------------------------------------------------------------
// Show the alert as a sheet attached to the specified parent window

- (void)beginSheetModalForWindow:(NSWindow *)parentWindow completionHandler:(void (^ __nullable)(NSModalResponse returnCode))handler
{
	[self layout];
	_docWindow = parentWindow;
	[parentWindow beginSheet:_panel completionHandler:handler];
}

@end
