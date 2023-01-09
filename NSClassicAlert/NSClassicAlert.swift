// Originally developed in ObjC by (c) 2020 and onwards Mark Coniglio/TroikaTronix.
// Swiftified by (c) 2021 and onwards Shiki Suen (MIT-NTL License).
// ====================
// This code is released under the MIT license (SPDX-License-Identifier: MIT)

import Cocoa

// Note: Not like the ObjC version, this Swift variant only considers
// the compatibility with macOS 11 and later, plus that it always enables the
// classic NSAlert design. If you want the modern vertical one, use NSAlert instead.

// MARK: - Protocol

/// A replacement for NSAlert that ensuress the ability to display long strings
/// of text, overcoming this limitation for Big Sur's new vertically oriented
/// alert dialogs.
///
/// Our measurements show that Big Sur alert boxes offer a space of 220 x 145
/// pixels for the main message and informational message combined, including 15
/// pixel gap between the two.
///
/// So the strategy to decide which alert to use requires measuring both the
/// the height main message text and the informationaional text within a 220px
/// frame. If their combined height + 15px > 220, then we show our custom dialog
/// box. Otherwise we show the our custom alert modeled on the alert boxes in
/// macOS Catalina and prior.
public protocol NSClassicAlertProtocol: AnyObject {
  init(error: Error)
  var messageText: String { get set }
  var informativeText: String { get set }
  var icon: NSImage! { get set }
  @discardableResult func addButton(withTitle title: String) -> NSButton
  var buttons: [NSButton] { get }
  var showsHelp: Bool { get set }
  var helpAnchor: NSHelpManager.AnchorName? { get set }
  var alertStyle: NSAlert.Style { get set }
  var delegate: NSAlertDelegate? { get set }
  var showsSuppressionButton: Bool { get set }
  var suppressionButton: NSButton? { get }
  var accessoryView: NSView? { get set }
  func layout()
  func runModal() -> NSApplication.ModalResponse
  func beginSheetModal(for parentWindow: NSWindow, completionHandler handler: ((NSApplication.ModalResponse) -> Void)?)
  var window: NSWindow { get }
}

extension NSAlert: NSClassicAlertProtocol {}

// MARK: - NSClassicAlert

public class NSClassicAlert: NSObject, NSClassicAlertProtocol {
  public var messageText: String = ""
  public var informativeText: String = ""
  public var buttons: [NSButton] = []
  public var showsHelp = false
  public var helpAnchor: NSHelpManager.AnchorName?
  public var alertStyle: NSAlert.Style = .informational
  public var delegate: NSAlertDelegate?
  public var showsSuppressionButton = false
  public var accessoryView: NSView?

  private var iconStorage: NSImage?
  private var docWindow: NSWindow?
  private var helpButton: NSButton?
  private var imageView: NSImageView?
  private var infoField: NSTextField?
  private var layoutDone = false
  private var messageField: NSTextField?
  private var panel: NSWindow?
  private var suppressionButtonStorage: NSButton?
  public var window: NSWindow { panel ?? .init() }

  public var icon: NSImage! {
    get { iconStorage ?? alertIcon(image: nil) }
    set {
      iconStorage = newValue
      iconStorage?.size = .init(width: 64, height: 64)
    }
  }

  public var suppressionButton: NSButton? {
    get {
      if suppressionButtonStorage == nil {
        suppressionButtonStorage = Self.createSuppressionButton()
      }
      return suppressionButtonStorage ?? Self.createSuppressionButton()
    }
    set {
      suppressionButtonStorage = newValue
    }
  }

  // MARK: - Public Methods

  public required convenience init(error _: Error) {
    self.init()
  }

  public static func createAlert(
    message msgText: String,
    info infoText: String
  ) -> NSClassicAlertProtocol? {
    var alert: NSClassicAlertProtocol?
    if #unavailable(macOS 11) {
      alert = NSAlert() as NSClassicAlertProtocol
      alert?.messageText = msgText
      alert?.informativeText = infoText
      return alert
    }

    // NONSENSE BEGIN

    let textWidth: Double = 145
    // let maxHeightForBigSurDialog: Double = 220
    var totalHeight = 0.0

    if !msgText.isEmpty {
      let attrMsgText = Self.createStyledText(string: msgText, makeBold: true)
      let rect = attrMsgText.boundingRect(
        with: .init(width: textWidth, height: 10000), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil
      )
      totalHeight += rect.size.height
    }

    if !infoText.isEmpty {
      let attrInfoText = Self.createStyledText(string: infoText, fontSize: NSFont.smallSystemFontSize, makeBold: false)
      let rect = attrInfoText.boundingRect(
        with: .init(width: textWidth, height: 10000), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil
      )
      totalHeight += rect.size.height
      totalHeight += 15.0
    }
    // NONSENSE END

    alert = NSClassicAlert() as NSClassicAlertProtocol
    alert?.messageText = msgText
    alert?.informativeText = infoText
    return alert
  }

  override public init() {
    super.init()
    panel = NSWindow(
      contentRect: .init(x: 0, y: 0, width: 100, height: 100),
      styleMask: [.titled, .docModalWindow],
      backing: .buffered,
      defer: true
    )
    guard let panel = panel, let view = panel.contentView else { return }
    guard #available(macOS 10.14, *) else { return }
    let effect = NSVisualEffectView()
    effect.frame = view.frame
    effect.blendingMode = .behindWindow
    effect.state = .active
    effect.material = .windowBackground
    effect.wantsLayer = true
    effect.layer?.masksToBounds = true
    panel.isOpaque = true
    panel.backgroundColor = .windowBackgroundColor
    panel.contentView = effect
    panel.titlebarAppearsTransparent = true
  }

  internal static func createStyledText(
    string inString: String, fontSize inFontSize: Double = NSFont.systemFontSize, makeBold inMakeBold: Bool
  ) -> NSAttributedString {
    let str = NSMutableAttributedString(string: inString)
    let fntSFUI = NSFont.systemFont(ofSize: inFontSize, weight: inMakeBold ? .bold : .regular)
    let paraStyle = NSMutableParagraphStyle()
    paraStyle.lineBreakMode = .byWordWrapping
    let layoutMgr = NSLayoutManager()
    paraStyle.maximumLineHeight = layoutMgr.defaultLineHeight(for: fntSFUI)
    var attr: [NSAttributedString.Key: Any] = [.font: fntSFUI, .paragraphStyle: paraStyle]
    attr[.foregroundColor] = NSColor.controlTextColor
    str.setAttributes(attr, range: NSRange(location: 0, length: str.length))
    return str
  }

  internal static func resizeImage(source sourceImage: NSImage, size: NSSize) -> NSImage {
    let targetFrame = NSRect(x: 0, y: 0, width: size.width, height: size.height)
    guard
      let sourceImageRep: NSImageRep = sourceImage.bestRepresentation(
        for: targetFrame, context: nil, hints: nil
      )
    else {
      return sourceImage
    }
    let targetImage = NSImage(size: size)
    targetImage.lockFocus()
    sourceImageRep.draw(in: targetFrame)
    targetImage.unlockFocus()
    return targetImage
  }

  internal func alertIcon(image inSourceIcon: NSImage?) -> NSImage {
    let outIcon = NSImage(size: .init(width: 64, height: 64))
    var sourceIcon = inSourceIcon ?? NSImage(named: NSImage.applicationIconName)!
    switch alertStyle {
      case .critical:
        let caution = NSImage(named: NSImage.cautionName)!
        caution.size = .init(width: 64, height: 64)
        sourceIcon = Self.resizeImage(source: sourceIcon, size: .init(width: 32, height: 32))
        outIcon.lockFocus()
        caution.draw(in: .init(x: 0, y: 0, width: caution.size.width, height: caution.size.height))
        sourceIcon.draw(
          in: .init(
            x: caution.size.width - sourceIcon.size.width, y: 0, width: sourceIcon.size.width,
            height: sourceIcon.size.height))
        outIcon.unlockFocus()
      default:  // Already included unknown cases.
        outIcon.lockFocus()
        sourceIcon.draw(in: .init(x: 0, y: 0, width: 64, height: 64))
        outIcon.unlockFocus()
    }
    return outIcon
  }

  internal func expandButtonSize(button btn: NSButton, amount inExpandHorz: Double, minWidth inMinWidth: Double) {
    btn.frame.size.width = max(btn.frame.size.width + inExpandHorz * 2, inMinWidth)
  }

  @discardableResult public func addButton(withTitle title: String) -> NSButton {
    let frame = NSRect(x: 0, y: 0, width: 40, height: 30)
    let btn = NSButton(frame: frame)
    btn.bezelStyle = .rounded
    btn.font = .systemFont(ofSize: NSFont.systemFontSize)
    btn.target = self
    btn.action = #selector(buttonPressed(_:))
    btn.title = title
    btn.sizeToFit()
    btn.tag = buttons.count
    expandButtonSize(button: btn, amount: 10, minWidth: 75)
    buttons.append(btn)
    panel?.contentView?.addSubview(btn)
    return btn
  }

  @objc internal func buttonPressed(_ sender: NSButton) {
    guard let panel = panel else { return }
    var response = NSApplication.ModalResponse.alertFirstButtonReturn
    switch sender.tag {
      case 1: response = NSApplication.ModalResponse.alertSecondButtonReturn
      case 2: response = NSApplication.ModalResponse.alertThirdButtonReturn
      default: response = NSApplication.ModalResponse.alertFirstButtonReturn
    }
    if let docWindow = docWindow {
      docWindow.endSheet(panel, returnCode: response)
    } else {
      NSApp.stopModal(withCode: response)
    }
    panel.orderOut(nil)
  }

  internal static func createTextField(attrStr inString: NSAttributedString) -> NSTextField {
    let tf = NSTextField()
    tf.drawsBackground = false
    tf.isBordered = false
    tf.isBezeled = false
    tf.isEditable = false
    tf.isSelectable = true
    tf.allowsEditingTextAttributes = true
    tf.attributedStringValue = inString
    return tf
  }

  internal static func createSuppressionButton() -> NSButton {
    let chkbox = NSButton(frame: .init(x: 0, y: 0, width: 18, height: 18))
    chkbox.setButtonType(.switch)
    chkbox.title = NSLocalizedString("Do not show this message again", comment: "")
    chkbox.font = .systemFont(ofSize: NSFont.systemFontSize)
    return chkbox
  }

  public func layout() {
    guard let panel = panel else { return }

    let kFrameIconLeftMargin = 20.0
    let kFrameLeftMargin = 100.0
    let kFrameRightMargin = 20.0
    let kFrameTopMargin = 15.0
    let kFrameBottomMargin = 15.0
    let kInterButtonMargin = 0.0
    let kDefaultTextWidth = 345.0
    let kInterTextSpacing = 10.0

    // --------------------------------------------------
    // ACCUMULATE BUTTON WIDTHS AND MEASURE HEIGHT
    // --------------------------------------------------

    // CALCULATE BUTTON WIDTHS AND MAXIMUM HEIGHT

    var totalButtonWidth: Double = 0
    var maxButtonHeight: Double = 0

    if buttons.isEmpty {
      addButton(withTitle: NSLocalizedString("OK", comment: ""))
    }

    buttons.forEach { btn in
      totalButtonWidth += btn.frame.size.width
      if btn.frame.size.height > maxButtonHeight {
        maxButtonHeight = btn.frame.size.height
      }
    }

    // total button width including the inter-button margin
    let totalButtonWidthWithInterButtonMargins: Double =
      totalButtonWidth + Double(buttons.count - 1) * kInterButtonMargin
    // text width will be the larger of the kDefaultTextWidth and the window
    // width calculated just above
    let textWidth: Double =
      (kDefaultTextWidth > totalButtonWidthWithInterButtonMargins)
      ? kDefaultTextWidth
      : totalButtonWidthWithInterButtonMargins
    // total window width based on the total width needed for the buttons
    let tempWindowWidth: Double = textWidth + (kFrameLeftMargin + kFrameRightMargin)

    // --------------------------------------------------
    // MAIN MESSAGE TEXT FIELD
    // --------------------------------------------------

    // PREPARE MESSAGE FIELD
    var msgFrame = NSRect.zero
    msgFieldBlock: if !messageText.isEmpty {
      messageField = Self.createTextField(
        attrStr: Self.createStyledText(string: messageText, makeBold: true)
      )
      guard let messageField = messageField, let theCell = messageField.cell else { break msgFieldBlock }
      messageField.frame = .init(x: 0, y: 0, width: textWidth, height: 0)
      panel.contentView?.addSubview(messageField)

      var frame = messageField.frame
      frame.size.height = Double.infinity
      frame.size.height = theCell.cellSize(forBounds: frame).height
      messageField.frame = frame
      msgFrame = messageField.frame
    }

    // --------------------------------------------------
    // ADDITIONAL INFO TEXT FIELD
    // --------------------------------------------------

    // PREPARE ADDTIONAL INFORMATION TEXT FIELD
    var infoFrame = NSRect.zero
    infoFieldBlock: if !informativeText.isEmpty {
      infoField = Self.createTextField(
        attrStr: Self.createStyledText(
          string: informativeText, fontSize: NSFont.smallSystemFontSize, makeBold: false
        )
      )
      guard let infoField = infoField, let theCell = infoField.cell else { break infoFieldBlock }
      infoField.frame = .init(x: 0, y: 0, width: textWidth, height: 10)

      var frame = infoField.frame
      frame.size.height = Double.infinity
      frame.size.height = theCell.cellSize(forBounds: frame).height
      infoField.frame = frame
      msgFrame = infoField.frame

      panel.contentView?.addSubview(infoField)
      infoFrame = infoField.frame
    }

    // --------------------------------------------------
    // SUPPRESSION BUTTON
    // --------------------------------------------------

    var suppressionButtonFrame = NSRect.zero
    suppressionButtonBlock: if showsSuppressionButton {
      suppressionButton = suppressionButtonStorage ?? Self.createSuppressionButton()
      guard let suppressionButton = suppressionButton else { break suppressionButtonBlock }
      suppressionButton.sizeToFit()
      panel.contentView?.addSubview(suppressionButton)
      suppressionButtonFrame = suppressionButton.frame
    }

    // --------------------------------------------------
    // SIZE THE ALERT WINDOW
    // --------------------------------------------------

    // final window width will be based on max button or text width
    let windowWidth: Double = tempWindowWidth

    // now that we have the message text sized, and we know the
    // max button height, we can calculated the height of the window
    var windowHeight: Double =
      (kFrameTopMargin + kFrameBottomMargin) + msgFrame.size.height + kInterTextSpacing + maxButtonHeight

    // if we have information text, then increase the height to
    // include room for that text field
    if infoField != nil {
      windowHeight += infoFrame.size.height
    }

    // if we have information text, then increase the height to
    // include room for that text field
    if suppressionButton != nil {
      windowHeight += suppressionButtonFrame.size.height + kInterTextSpacing
    }

    // RESIZE WINDOW TO ACCOMODATE ALL CONTROLS
    panel.setContentSize(.init(width: windowWidth, height: windowHeight))

    // --------------------------------------------------
    // PLACE BUTTONS
    // --------------------------------------------------

    // SPECIAL CASE FOR THREE BUTTONS
    // if we have three buttons, we will arrange the first
    // two flush right, and then arrange the third button
    // flush left.
    let maxButtonsBottomRight = min(buttons.count, 2)

    // ARRANGE BUTTONS ALONG THE BOTTOM
    let insets: NSEdgeInsets = buttons[0].alignmentRectInsets
    let btnTop: Double = kFrameBottomMargin - insets.bottom
    var btnLeft: Double = windowWidth - kFrameRightMargin + insets.right

    loopOpsForRightButtons: for (i, btn) in buttons.enumerated() {
      if i >= maxButtonsBottomRight { break loopOpsForRightButtons }
      var btnFrame = btn.frame
      btnFrame.origin.y = btnTop
      btnLeft -= btnFrame.size.width
      btnFrame.origin.x = btnLeft
      btnLeft -= kInterButtonMargin
      btn.frame = btnFrame
    }

    // SPECIAL CASE: ARRANGE THIRD BUTTON FLUSH LEFT
    if buttons.count >= 3 {
      let btn = buttons[2]
      let insets = btn.alignmentRectInsets
      var btnFrame = btn.frame
      btnFrame.origin.y = btnTop
      btnFrame.origin.x = kFrameLeftMargin - insets.left
      btn.frame = btnFrame
    }

    // calculate top of first text box
    var textTop: Double = btnTop + maxButtonHeight + kInterTextSpacing

    // --------------------------------------------------
    // PLACE SUPPRESSION BUTTON IF PRESENT
    // --------------------------------------------------

    if let suppressionButton = suppressionButton {
      suppressionButtonFrame.origin = .init(x: kFrameLeftMargin, y: textTop)
      suppressionButton.frame = suppressionButtonFrame
      textTop += suppressionButtonFrame.size.height + kInterTextSpacing
    }

    // --------------------------------------------------
    // PLACE TEXT
    // --------------------------------------------------

    // if we have an info field, put it into place
    if let infoField = infoField {
      infoFrame.origin = .init(x: kFrameLeftMargin, y: textTop)
      infoField.frame = infoFrame
      textTop += infoFrame.size.height
    }

    // put the main message into place
    msgFrame.origin = .init(x: kFrameLeftMargin, y: textTop)
    messageField?.frame = msgFrame
    textTop += msgFrame.size.height + kInterTextSpacing

    // --------------------------------------------------
    // PLACE ICON
    // --------------------------------------------------

    // CREATE ICON IMAGE AND SIZE TO 64x64
    let sourceIcon: NSImage = alertIcon(image: iconStorage)
    let imageSize = sourceIcon.size

    // CREATE IMAGE VIEW FOR ICON
    imageView = NSImageView(image: sourceIcon)
    guard let imageView = imageView else { return }
    panel.contentView?.addSubview(imageView)
    let top = windowHeight - (kFrameTopMargin + imageSize.height)
    imageView.frame = .init(
      x: kFrameIconLeftMargin, y: top, width: imageSize.width, height: imageSize.height
    )

    // clear any key equivalent && set key equivalents

    if buttons.count >= 1 {
      buttons[0].keyEquivalent = "\r"
    }
    if buttons.count >= 2 {
      buttons[1].keyEquivalent = "\033"
    }
  }

  public func runModal() -> NSApplication.ModalResponse {
    guard let panel = panel else { return .init(0) }
    layout()
    return NSApp.runModal(for: panel)
  }

  public func beginSheetModal(
    for parentWindow: NSWindow,
    completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil
  ) {
    guard let panel = panel else { return }
    layout()
    docWindow = parentWindow
    parentWindow.beginSheet(panel, completionHandler: handler)
  }
}
