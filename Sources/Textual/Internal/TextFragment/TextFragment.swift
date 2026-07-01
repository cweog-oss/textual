import SwiftUI

// MARK: - Overview
//
// TextFragment renders attributed content as SwiftUI.Text with support for inline
// attachments, links, and selection. It uses a TextBuilder to construct and cache
// Text values, minimizing rebuilds during resize by keying on attachment sizes.
//
// Attachments are represented as placeholder images tagged with AttachmentAttribute. The
// actual attachment views are rendered in an overlay using the resolved Text.Layout
// geometry. Three modifiers are applied at the fragment level:
//
// - TextSelectionBackground renders selection highlights on macOS
// - AttachmentOverlay draws attachments at their run locations with selection-aware dimming
// - TextLinkInteraction handles tap gestures on links
//
// These overlays use backgroundPreferenceValue and overlayPreferenceValue to access
// Text.Layout and render in fragment-local coordinates. Fragment-level overlays enable
// coordinate space isolation and keep scrollable regions interactive.
//
// An ancestor view must define a named coordinate space (.textContainer) for the text
// container. TextFragment uses onGeometryChange to observe the container size and rebuild
// Text when attachment sizes need to change.
//
// TextFragment is used by InlineText and StructuredText (via BlockContent) to render
// attributed content with inline attachments, links, and selection.

struct TextFragment<Content: AttributedStringProtocol>: View {
  @Environment(\.textEnvironment) private var textEnvironment
  @Environment(\.resolvedTextContainerSize) private var resolvedTextContainerSize
  @State private var textBuilder: TextBuilder?
  @State private var containerSize: CGSize?

  private let content: Content

  init(_ content: Content) {
    self.content = content
  }

  var body: some View {
    text
      .customAttribute(TextFragmentAttribute())
      .onGeometryChange(for: CGSize?.self, of: \.textContainerSize) { size in
        containerSize = size
        guard let size, let textBuilder else { return }
        textBuilder.sizeChanged(size, environment: textEnvironment)
      }
      .onChange(of: content, initial: true) { _, newValue in
        let builder = TextBuilder(newValue, environment: textEnvironment)
        // Size the freshly built text to the container immediately when the width is
        // known. Otherwise the builder lays attachments out with an `.unspecified`
        // proposal — which for images means their full intrinsic size — and publishes
        // that oversized layout before `onGeometryChange` corrects it. The selection
        // model can latch onto that transient as the last write, leaving link/tag
        // hit-testing pointing at stale geometry until a scroll forces another layout
        // pass.
        //
        // `containerSize` (this fragment's own measurement) is preferred, but it is
        // `nil` for a fragment that was just (re)created — which happens whenever an
        // inline image finishes loading and reflows the document into a different
        // block structure, giving fragments new identities. `resolvedTextContainerSize`
        // comes from an ancestor (`StructuredText`) that measures the container once,
        // so it survives those identity changes and is available on first build.
        if let size = containerSize ?? resolvedTextContainerSize {
          builder.sizeChanged(size, environment: textEnvironment)
        }
        self.textBuilder = builder
      }
      .modifier(TextSelectionBackground())
      .modifier(AttachmentOverlay(attachments: content.attachments()))
      .modifier(TextLinkInteraction())
      .modifier(TextAttachmentInteraction())
  }

  private var text: Text {
    textBuilder?.text ?? Text(verbatim: "")
  }
}

struct TextFragmentAttribute: TextAttribute {
}

extension Text.Layout {
  var isTextFragment: Bool {
    first?.first?[TextFragmentAttribute.self] != nil
  }
}

extension CoordinateSpaceProtocol where Self == NamedCoordinateSpace {
  static var textContainer: NamedCoordinateSpace {
    .named("textContainer")
  }
}

extension EnvironmentValues {
  /// The resolved size of the text container, published by an ancestor (for example
  /// ``StructuredText``) that measures it once.
  ///
  /// ``TextFragment`` uses this to size attachments on its first build when its own
  /// geometry has not been measured yet — notably for fragments that are recreated when
  /// an inline image finishes loading and reflows the document into a new block structure.
  @Entry var resolvedTextContainerSize: CGSize? = nil
}

extension GeometryProxy {
  fileprivate var textContainerSize: CGSize? {
    bounds(of: .textContainer)?.size
  }
}
