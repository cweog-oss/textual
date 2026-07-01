import SwiftUI

// MARK: - Overview
//
// `TextSelectionInteraction` manages the text selection model lifecycle for multiple `Text` fragments.
//
// Selection is opt-in through the `textSelection` environment value. When enabled, the modifier
// observes text layout changes via `overlayTextLayoutCollection` and creates or updates a
// `TextSelectionModel`. The model is then passed to the platform-specific implementation
// (`PlatformTextSelectionInteraction`), which presents the appropriate selection UI for macOS
// or iOS. This separation keeps model management in shared code while platform interactions
// remain independent.

struct TextSelectionInteraction: ViewModifier {
  #if TEXTUAL_ENABLE_TEXT_SELECTION
    @Environment(\.textSelection) private var textSelection
    @Environment(TextSelectionCoordinator.self) private var coordinator: TextSelectionCoordinator?

    @State private var model = TextSelectionModel()
  #endif

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      if textSelection.allowsSelection {
        content
          .overlayTextLayoutCollection { layoutCollection in
            modelUpdater(for: layoutCollection)
          }
          .modifier(PlatformTextSelectionInteraction(model: model))
      } else {
        content
      }
    #else
      content
    #endif
  }

  #if TEXTUAL_ENABLE_TEXT_SELECTION
    // Pushes the live layout collection into the model. On iOS this uses a representable
    // whose `updateUIView` runs on every graph update — reliable, unlike `onChange(of:)`
    // inside a preference/GeometryReader closure, which can miss updates and leave the
    // model holding an intermediate layout. Other platforms fall back to `onChange`.
    @ViewBuilder
    private func modelUpdater(for layoutCollection: any TextLayoutCollection) -> some View {
      #if canImport(UIKit)
        TextLayoutModelUpdater(
          model: model,
          coordinator: coordinator,
          layoutCollection: layoutCollection
        )
      #else
        Color.clear
          .onChange(of: AnyTextLayoutCollection(layoutCollection), initial: true) {
            model.setCoordinator(coordinator)
            model.setLayoutCollection(layoutCollection)
          }
      #endif
    }
  #endif
}

#if TEXTUAL_ENABLE_TEXT_SELECTION
  extension EnvironmentValues {
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @usableFromInline
    @Entry var textSelection: any TextSelectability.Type = DisabledTextSelectability.self
  }
#endif
