#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
  import SwiftUI

  // MARK: - Overview
  //
  // `UIKitTextInteractionOverlay` bridges the shared `TextSelectionModel` into a `UIView`.
  //
  // The overlay reads exclusion rectangles for hit-testing. This allows embedded scrollable regions (like
  // code blocks) to receive touch events while the parent handles text selection. The view hosts
  // a `UITextInteraction` configured for selection and implements the `UITextInput` surface that
  // UIKit uses for selection behavior.

  struct UIKitTextInteractionOverlay: UIViewRepresentable {
    private let model: TextSelectionModel
    private let overflowFrames: [CGRect]
    private let attachmentTapAction: ((AnyAttachment, CGPoint) -> Void)?

    init(
      model: TextSelectionModel,
      overflowFrames: [CGRect],
      attachmentTapAction: ((AnyAttachment, CGPoint) -> Void)?
    ) {
      self.model = model
      self.overflowFrames = overflowFrames
      self.attachmentTapAction = attachmentTapAction
    }

    func makeUIView(context: Context) -> UITextInteractionView {
      UITextInteractionView(
        model: model,
        exclusionRects: overflowFrames,
        openURL: context.environment.openURL,
        attachmentTapAction: attachmentTapAction
      )
    }

    func updateUIView(_ uiView: UITextInteractionView, context: Context) {
      uiView.model = model
      uiView.exclusionRects = overflowFrames
      uiView.openURL = context.environment.openURL
      uiView.attachmentTapAction = attachmentTapAction
    }
  }
#endif
