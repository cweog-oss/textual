import SwiftUI

// MARK: - Overview
//
// `TextAttachmentInteraction` enables tap detection on inline attachment runs.
//
// When `attachmentTapAction` is installed in the environment, this modifier becomes the
// outermost tap handler (applied after `TextLinkInteraction` in `TextFragment`). Its
// `Color.clear.contentShape(.rect)` overlay sits on top in z-order, so it wins UIKit
// hit-testing for the entire text fragment. It therefore takes over link dispatch too,
// forwarding URL runs to `openURL` — keeping link behaviour intact while adding
// attachment tap support.
//
// When no `attachmentTapAction` is installed this modifier is a no-op, leaving
// `TextLinkInteraction` as the sole tap handler.

struct TextAttachmentInteraction: ViewModifier {
  @Environment(\.attachmentTapAction) private var attachmentTapAction
  @Environment(\.openURL) private var openURL

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_LINKS
      if attachmentTapAction != nil {
        content
          .overlayPreferenceValue(Text.LayoutKey.self) { value in
            if let anchoredLayout = value.first {
              GeometryReader { geometry in
                Color.clear
                  .contentShape(.rect)
                  .gesture(
                    tap(
                      origin: geometry[anchoredLayout.origin],
                      layout: anchoredLayout.layout
                    )
                  )
              }
            }
          }
      } else {
        content
      }
    #else
      content
    #endif
  }

  #if TEXTUAL_ENABLE_LINKS
    private func tap(origin: CGPoint, layout: Text.Layout) -> some Gesture {
      SpatialTapGesture()
        .onEnded { value in
          let localPoint = CGPoint(
            x: value.location.x - origin.x,
            y: value.location.y - origin.y
          )
          let runs = layout.flatMap(\.self)
          guard let run = runs.first(where: { $0.typographicBounds.rect.contains(localPoint) })
          else { return }

          if let attachment = run.attachment {
            attachmentTapAction?(attachment, value.location)
          } else if let url = run.url {
            openURL(url)
          }
        }
    }
  #endif
}

enum AttachmentTapActionKey: EnvironmentKey {
  static var defaultValue: ((AnyAttachment, CGPoint) -> Void)? { nil }
}

extension EnvironmentValues {
  var attachmentTapAction: ((AnyAttachment, CGPoint) -> Void)? {
    get { self[AttachmentTapActionKey.self] }
    set { self[AttachmentTapActionKey.self] = newValue }
  }
}
