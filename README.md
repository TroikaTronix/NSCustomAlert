# NSCustomAlert

A custom `NSAlert` class that gracefully handles alerts with long message or informational text in macOS Big Sur.

## Background

In macOS Big Sur, the appearance of `NSAlert` dialogs changed: the layout is vertically oriented, there is less space for text, and the message and informational text are centered horizontally. If either field is too long, the text may be clipped within the alert and no longer be fully readable.

The `NSCustomAlert` class provides a direct replacement for `NSAlert` that imitates the appearance of alerts shown in macOS Catalina and earlier.

## Use in TroikaTronix Products

This code is used TroikaTronix's products, although that source code is maintained separately. TroikaTronix released NSCustomAlert to the community because we felt it could be useful to other developers facing similar problems caused by the size limitations of the newer macOS alert design.

## Implementation

If you simply wish to revert to the previous alert style in all cases, replace references to `NSAlert` with `NSCustomAlert`. `NSCustomAlert` offers nearly all the same methods as `NSAlert` (see **To Do** below for omissions), so adopting this class generally requires changing only `NSAlert` allocations to use `NSCustomAlert` instead.

The global `createAlertForMessageText:infoText:` method dynamically creates either an `NSAlert`, when the message and informational text are short enough, or an `NSCustomAlert` when the text is too long to fit within Big Sur's smaller alert window.

When using this method, variables declared as `NSAlert *` should instead be declared as `id<NSAlertProtocol>`, as defined in `NSCustomAlertProtocol.h`. This protocol defines the methods shared by `NSAlert` and `NSCustomAlert`, allowing the same code to work with either class, regardless of which one is returned by `createAlertForMessageText:infoText:`.

## Test Cases

To test `NSCustomAlert`, choose one of the **Show Alert** items from the File menu.

Under Big Sur, the **Short** and **Below Edge Case** versions should always show the normal Big Sur dialog. The **Above Edge Case** and **Long** versions will generate an `NSCustomAlert` that mirrors the appearance of alerts in macOS Catalina and earlier.

Under earlier versions of macOS, a normal `NSAlert` will always be used.

## To Do

The help button and accessory-view features have not yet been implemented because they were not needed for the original use case. Contributions implementing these features are welcome.
