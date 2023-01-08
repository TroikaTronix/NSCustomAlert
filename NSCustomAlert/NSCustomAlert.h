// --------------------------------------------------------------------------------
//	NSCustomAlertProtocol
// --------------------------------------------------------------------------------
//
// MIT License
//
// Copyright (c) 2020 Mark Coniglio/TroikaTronix
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is//
// urnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// A replacement for NSAlert that ensuress the ability to display long strings
// of text, overcoming this limitation for Big Sur's new vertically oriented
// alert dialogs.

#ifndef _H_NSCustomAlert
#define _H_NSCustomAlert

#import <AppKit/AppKit.h>
#import <AppKit/NSAlert.h>

#import "NSCustomAlertProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSCustomAlert : NSObject {
 @private

  NSWindow *_docWindow;  // parent window for sheets
  NSWindow *_panel;      // alert panel
  BOOL _layoutDone;      // true once layout is done
  BOOL _showsHelp;       // set to true if the caller desires the help button
  BOOL _showsSuppressionButton;  // set to YES if the caller desires the
                                 // suprresion

  // ALERT TEXT
  NSTextField *_messageField;  // text field for the main message
  NSTextField *_infoField;     // text field for additional information

  // SuppressION BUTTON
  NSButton *_suppressionButton;  // surpression button -- not yet implemented

  // HELP BUTTON
  NSButton *_helpButton;  // help button -- not yet implemented
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 101300
  NSHelpAnchorName _helpAnchor;  // help anchor -- not yet implemented
#endif

  // ACCESSORY VIEW
  id _accessoryView;  // accessary view -- not yet implemented

  // ALERT ICON
  NSImage *_icon;
  NSImageView *_imageView;  // image view that displays icon

  // ALERT BUTTONS
  NSMutableArray *_buttons;  // array of buttons added to the alert

  // DELEGATE
  id _delegate;  // alert delegate
}

/* Given an NSError, create an NSAlert that can be used to present the error to
 * the user. The error's localized description, recovery suggestion, and
 * recovery options will be used to set the alert's message text, informative
 * text, and button titles, respectively.
 */
+ (NSCustomAlert *)alertWithError:(NSError *)error;

+ (id<NSCustomAlertProtocol>)createAlertForMessageText:(NSString *)msgText
                                              infoText:(NSString *)infoText;

@property(copy) NSString *messageText;
@property(copy) NSString *informativeText;

/* customize the icon.  By default uses the image named NSApplicationIcon.
 */
@property(null_resettable, strong) NSImage *icon;

/* customize the buttons in the alert panel.  Buttons are added from right to
 * left (for left to right languages).
 */
- (NSButton *)addButtonWithTitle:(NSString *)title;
/* get the buttons, where the rightmost button is at index 0.
 */
#if MAC_OS_X_VERSION_MAX_ALLOWED < 101100
@property(readonly, copy) NSArray *buttons;
#else
@property(readonly, copy) NSArray<NSButton *> *buttons;
#endif

/* In order to customize a return value for a button:
   setTag:(NSInteger)tag;	setting a tag on a button will cause that tag to
   be the button's return value

   Note that we reserve the use of the tag for this purpose.  We also reserve
   the use of the target and the action.

   By default, the first button has a key equivalent of return which implies a
   pulsing default button, the button named "Cancel", if any, has a key
   equivalent of escape, and the button named "Don't Save", if any, has a key
   equivalent of cmd-d.  The following methods can be used to customize key
   equivalents: setKeyEquivalent:(NSString *)charCode:
   setKeyEquivalentModifierMask:(NSUInt)mask;
*/

/* -setShowsHelp:YES adds a help button to the alert panel. When the help button
 * is pressed, the delegate is first consulted.  If the delegate does not
 * implement alertShowHelp: or returns NO, then -[NSHelpManager
 * openHelpAnchor:inBook:] is called with a nil book and the anchor specified by
 * -setHelpAnchor:, if any.  An exception will be raised if the delegate returns
 * NO and there is no help anchor set.
 */
@property BOOL showsHelp;

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 101300
@property(nullable, copy) NSHelpAnchorName helpAnchor;
#endif

@property NSAlertStyle alertStyle;

/* The delegate of the receiver, currently only allows for custom help behavior
   of the alert. For apps linked against 10.12, this property has zeroing weak
   memory semantics. When linked against an older SDK this back to having
   `retain` semantics, matching legacy behavior.
 */
#if MAC_OS_X_VERSION_MAX_ALLOWED < 101100
@property(assign) id<NSAlertDelegate> delegate;
#else
@property(nullable, weak) id<NSAlertDelegate> delegate;
#endif

/* -setShowsSuppressionButton: indicates whether or not the alert should contain
 * a suppression checkbox.  The default is NO.  This checkbox is typically used
 * to give the user an option to not show this alert again.  If shown, the
 * suppression button will have a default localized title similar to @"Do not
 * show this message again".  You can customize this title using [[alert
 * suppressionButton] setTitle:].  When the alert is dismissed, you can get the
 * state of the suppression button, using [[alert suppressionButton] state] and
 * store the result in user defaults, for example.  This setting can then be
 * checked before showing the alert again.  By default, the suppression button
 * is positioned below the informative text, and above the accessory view (if
 * any) and the alert buttons, and left-aligned with the informative text.
 * However do not count on the placement of this button, since it might be moved
 * if the alert panel user interface is changed in the future. If you need a
 * checkbox for purposes other than suppression text, it is recommended you
 * create your own using an accessory view.
 */
@property BOOL showsSuppressionButton;

/* -suppressionButton returns a suppression button which may be customized,
 * including the title and the initial state.  You can also use this method to
 * get the state of the button after the alert is dismissed, which may be stored
 * in user defaults and checked before showing the alert again.  In order to
 * show the suppression button in the alert panel, you must call
 * -setShowsSuppressionButton:YES.
 */
@property(nullable, readonly, strong) NSButton *suppressionButton;

/* -setAccessoryView: sets the accessory view displayed in the alert panel.  By
 * default, the accessory view is positioned below the informative text and the
 * suppression button (if any) and above the alert buttons, left-aligned with
 * the informative text.  If you want to customize the location of the accessory
 * view, you must first call -layout.  See the discussion of -layout for more
 * information.
 */
@property(nullable, strong) NSView *accessoryView;

/* -layout can be used to indicate that the alert panel should do immediate
 * layout, overriding the default behavior of laying out lazily just before
 * showing panel.  You should only call this method if you want to do your own
 * custom layout after it returns.  You should call this method only after you
 * have finished with NSCustomAlert customization, including setting message and
 * informative text, and adding buttons and an accessory view if needed.  You
 * can make layout changes after this method returns, in particular to adjust
 * the frame of an accessory view.  Note that the standard layout of the alert
 * may change in the future, so layout customization should be done with
 * caution.
 */
- (void)layout;

/* Run the alert as an application-modal panel and return the result.
 */
- (NSModalResponse)runModal;

/* Begins a sheet on the doc window using NSWindow's sheet API.
   If the alert has an alertStyle of NSAlertStyleCritical, it will be shown as a
   "critical" sheet; it will otherwise be presented as a normal sheet.
 */
- (void)beginSheetModalForWindow:(NSWindow *)parentWindow
               completionHandler:
                   (void (^__nullable)(NSModalResponse returnCode))handler;

/* return the application-modal panel or the document-modal sheet corresponding
 * to this alert.
 */
@property(readonly, strong) NSWindow *window;

@end

NS_ASSUME_NONNULL_END

#endif  // #ifndef _H_NSCustomAlert
