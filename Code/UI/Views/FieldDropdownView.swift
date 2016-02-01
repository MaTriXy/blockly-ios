/*
* Copyright 2016 Google Inc. All Rights Reserved.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

/**
 View for rendering a `FieldDropdownLayout`.
 */
@objc(BKYFieldDropdownView)
public class FieldDropdownView: FieldView {
  // MARK: - Properties

  /// Layout object to render
  public var fieldDropdownLayout: FieldDropdownLayout? {
    return layout as? FieldDropdownLayout
  }

  /// The text field to render
  private var label: UILabel!

  private var button: UIButton!

  private var dropDownArrow: UIImageView!

  // MARK: - Initializers

  public required init() {
    super.init(frame: CGRectZero)

    // Add subviews
    self.dropDownArrow = UIImageView(image: FieldDropdownView.dropDownArrowImage())
    dropDownArrow.contentMode = .Center

    self.label = UILabel(frame: CGRectZero)

    self.button = UIButton(type: .Custom)
    button.addTarget(self, action: "didTapButton:", forControlEvents: .TouchUpInside)
    button.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]

    bky_addSubviews([self.label, self.button, self.dropDownArrow])
    refreshConstraints()

    sendSubviewToBack(button)
  }

  public required init?(coder aDecoder: NSCoder) {
    bky_assertionFailure("Called unsupported initializer")
    super.init(coder: aDecoder)
  }

  // MARK: - Super

  public override func internalRefreshView(forFlags flags: LayoutFlag)
  {
    guard let layout = self.layout as? FieldDropdownLayout else {
      return
    }

    if flags.intersectsWith(Layout.Flag_NeedsDisplay) {
      refreshConstraints()

      // Decorate this view
      self.layer.borderColor = UIColor.grayColor().CGColor
      self.layer.borderWidth =
        layout.workspaceLayout.viewUnitFromWorkspaceUnit(BlockLayout.sharedConfig.fieldLineWidth)
      self.layer.cornerRadius =
        layout.workspaceLayout.viewUnitFromWorkspaceUnit(BlockLayout.sharedConfig.fieldCornerRadius)

      if self.label.text != layout.fieldDropdown.selectedOption?.displayName {
        self.label.text = layout.fieldDropdown.selectedOption?.displayName
      }

      // TODO:(#335) Standardize this font
      self.label.font = UIFont.systemFontOfSize(14 * layout.workspaceLayout.scale)
    }
  }

  public override func internalPrepareForReuse() {
    self.frame = CGRectZero
    self.label.text = ""
  }

  // MARK: - Private

  private func refreshConstraints() {
    guard let layout = self.layout as? FieldDropdownLayout else {
      return
    }

    // Get separator space in UIView units
    let xPadding =
      layout.workspaceLayout.viewUnitFromWorkspaceUnit(BlockLayout.sharedConfig.inlineXPadding)
    let yPadding =
      layout.workspaceLayout.viewUnitFromWorkspaceUnit(BlockLayout.sharedConfig.inlineYPadding)

    let views = [
      "label": self.label,
      "dropDownArrow": self.dropDownArrow,
      "button": self.button,
    ]
    let metrics = ["xPadding": xPadding, "yPadding": yPadding]
    let constraints = [
      "H:|-(xPadding)-[label]-(xPadding)-[dropDownArrow]-(xPadding)-|",
      "H:|[button]|",
      "V:|-(yPadding)-[label]-(yPadding)-|",
      "V:|[dropDownArrow]|",
      "V:|[button]|",
    ]

    // Remove all current constraints
    views.forEach({ $1.removeFromSuperview()})

    bky_addSubviews(Array(views.values))

    // Add new constraints
    bky_addVisualFormatConstraints(constraints, metrics: metrics, views: views)
  }

  private dynamic func didTapButton(sender: UIButton) {
    guard let field = fieldDropdownLayout?.fieldDropdown,
      let parentBlockView = self.parentBlockView else
    {
      return
    }

    let viewController = FieldDropdownOptionsViewController()
    viewController.field = field
    viewController.delegate = self
    parentBlockView.requestToPresentPopoverViewController(viewController, fromView: self)
  }

  private class func dropDownArrowImage() -> UIImage? {
    return ImageLoader.loadImage(named: "arrow_dropdown", forClass: FieldDropdownView.self)
  }
}

// MARK: - FieldLayoutMeasurer implementation

extension FieldDropdownView: FieldLayoutMeasurer {
  public static func measureLayout(layout: FieldLayout, scale: CGFloat) -> CGSize {
    guard let fieldLayout = layout as? FieldDropdownLayout else {
      bky_assertionFailure("Cannot measure layout of type [\(layout.dynamicType.description)]. " +
        "Expected type [FieldDropdownLayout].")
      return CGSizeZero
    }

    let fieldLineWidth =
      layout.workspaceLayout.viewUnitFromWorkspaceUnit(BlockLayout.sharedConfig.fieldLineWidth)
    let xPadding =
      layout.workspaceLayout.viewUnitFromWorkspaceUnit(BlockLayout.sharedConfig.inlineXPadding)
    let yPadding =
      layout.workspaceLayout.viewUnitFromWorkspaceUnit(BlockLayout.sharedConfig.inlineYPadding)

    // Measure text size
    // TODO:(#335) Use a standardized font size that can be configurable for the project
    let measureText = (fieldLayout.fieldDropdown.selectedOption?.displayName ?? "")
    let font = UIFont.systemFontOfSize(14 * scale)
    let textSize = measureText.bky_singleLineSizeForFont(font)

    // Measure drop down arrow image size
    var imageSize = CGSizeZero
    if let image = FieldDropdownView.dropDownArrowImage() {
      imageSize = image.size
    }

    // Return size required
    return CGSizeMake(
      ceil(textSize.width + xPadding * 3 + imageSize.width + fieldLineWidth * 2),
      ceil(max(textSize.height + yPadding * 2, imageSize.height) + fieldLineWidth * 2))
  }
}

// MARK: - FieldDropdownOptionsViewControllerDelegate

extension FieldDropdownView: FieldDropdownOptionsViewControllerDelegate {
  public func fieldDropdownOptionsViewController(viewController: FieldDropdownOptionsViewController,
    didSelectOptionIndex optionIndex: Int)
  {
    guard let field = fieldDropdownLayout?.fieldDropdown else {
      return
    }

    field.selectedIndex = optionIndex
    viewController.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
}