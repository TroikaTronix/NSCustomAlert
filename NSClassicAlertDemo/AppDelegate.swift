// Originally developed in ObjC by (c) 2020 and onwards Mark Coniglio/TroikaTronix.
// Swiftified by (c) 2021 and onwards Shiki Suen (MIT-NTL License).
// ====================
// This code is released under the MIT license (SPDX-License-Identifier: MIT)

import Cocoa
import NSClassicAlert

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet var window: NSWindow!

  @IBAction func showAlert(_: Any) {
    let messageText = """
      This is a really long error talking about something that went wrong \
      with the system and requires a really long explanation. This sentence \
      extends the length of the message by a few words.
      """

    let informativeText = """
      This is the informative text that will go on and on and on and on and \
      on and on et. The quick brown fox jumped over the lazy dog and then \
      catapulted himself into the outer reaches of the universe. Now he is \
      stardust, and will expand outward until the end of time. What happens \
      if we make this even longer? Will it push the main text so far up that \
      we can't read it?
      """

    showCustomAlert(forText: messageText, infoText: informativeText)
  }

  func applicationDidFinishLaunching(_: Notification) {
    // Insert code here to initialize your application
  }

  func applicationWillTerminate(_: Notification) {
    // Insert code here to tear down your application
  }

  func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
    true
  }
}

extension AppDelegate {
  func showCustomAlert(
    forText inMsgText: String,
    infoText inInfoText: String
  ) {
    let alertp = NSClassicAlert.createAlert(message: inMsgText, info: inInfoText)
    alertp?.messageText = inMsgText
    alertp?.informativeText = inInfoText
    alertp?.alertStyle = .critical

    // uncomment this if you want to provide a custom icon to the alert
    // alertp?.icon = .init(named: NSImage.computerName)!

    // uncomment this if you want to show the suppression button
    // alertp?.showsSuppressionButton = true

    // ucomment this if you want to give the suppression button a custom name
    // alertp?.suppressionButton.title = "Custom Suppression Button"

    // NOTE: this technique does work with Big Sur's dialog to widen them... but
    // then the buttons are still arranged vertically, which doesn't look so nice.
    // alertp?.accessoryView = .init(frame: .init(x: 0, y: 0, width: 500, height: 0))

    // adding buttons works the same as it does with the real NSAlert

    alertp?.addButton(withTitle: "OK")
    alertp?.addButton(withTitle: "Cancel")
    alertp?.addButton(withTitle: "Show Options...")

    alertp?.beginSheetModal(
      for: window
    ) { response in
      print("Response = \(response)\n")
    }
  }
}
