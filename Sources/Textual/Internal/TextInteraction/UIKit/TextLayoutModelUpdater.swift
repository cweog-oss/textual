#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
  import SwiftUI

  // MARK: - Overview
  //
  // `TextLayoutModelUpdater` pushes the live text layout collection into the
  // `TextSelectionModel` on every SwiftUI update.
  //
  // The model previously captured the layout via `onChange(of:)` inside an
  // `overlayPreferenceValue` + `GeometryReader` closure. That closure's view identity is
  // unstable, so `onChange` can miss updates — leaving the model holding an intermediate
  // layout (for example the one published while an inline image was still loading) even
  // though the live layout, and the rendered text, have already settled. Link/tag
  // hit-testing then uses stale geometry.
  //
  // `updateUIView` runs on every graph update the representable participates in, and the
  // existential collection can't be Equatable-diffed away, so this reliably re-applies the
  // current layout. `TextSelectionModel.setLayoutCollection` guards against redundant work.
  struct TextLayoutModelUpdater: UIViewRepresentable {
    let model: TextSelectionModel
    let coordinator: TextSelectionCoordinator?
    let layoutCollection: any TextLayoutCollection

    func makeUIView(context: Context) -> UIView {
      let view = UIView()
      view.isUserInteractionEnabled = false
      return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
      model.setCoordinator(coordinator)
      model.setLayoutCollection(layoutCollection)
    }
  }
#endif
