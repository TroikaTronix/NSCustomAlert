# NSCustomAlert
A custom NSAlert class that gracefully handles alerts with long message or informational texts in Big Sur.

## Background

In macOS Big Sur, the appearance of NSAlert dialogs changed: the box is vertically oriented, there is less space for text, and the the message and informational text is centered horizontally. If the message or informational text is too long, the text will be clipped within the alert and will no longer be fully readable.

The NSCustomAlert class implements a direct replacement for NSAlert that imitates the appearance of alerts shown in macOS Catalina and earlie

## Implementation

If you sijmply wish to revert back to the previous alert style in all cases, replace all references to NSAlert with NSCustomAlert instead. NSCustomAlert offers nearly all the same methods as NSAlert (see To Do, below for omissions), so adopting this class only requires changing NSAlert allocations to use NSCustomAlert instead.

Furthermore, the global createAlertForMessageText:infoText method dynamically creates either an NSAlert (when the message and info text is short enough) or an NSCustomAlert if the text is too long to fit into Big Sur's smaller alert window. In this case, you will want to change variables of the type NSAlert* to id<NSAlertProtocol>, as defined in NSCustomAlertProtocol.h. This protocol defines all the methods shared by NSAlert and NSCustomAlert, allowing you to work with either NSAlert or NSCustomAlert regardless of which was created by calling createAlertForMessageText:infoText.

## Test Cases

To test NSCustomAlert, simply choose one of the Show Alert items from the file menu.

Under Big Sur, the "Short" and "Below Edge Case" versions should always show the normal, Big Sur dialog. The "Above Edge Case" and "Long" versions will generate an NSCustomAlert that mirrors the appearance of the alerts in macOS Catalina and before.

Under earlier versions of macOS, a normal NSAlert will always be used.

## To Do

The help button and accessory view features have not yet been implemented because I didn't need them. If you impelement these, please feel free to issue a pull request.
