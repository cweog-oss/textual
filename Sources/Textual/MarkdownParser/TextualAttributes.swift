import SwiftUI

extension AttributeScopes {
  /// Attributes used by Textual when parsing and rendering markup.
  public struct TextualAttributes: AttributeScope {
    /// Stores an attachment value in attributed content.
    public enum AttachmentAttribute: AttributedStringKey {
      public typealias Value = AnyAttachment
      public static let name = "Textual.Attachment"
    }

    /// Stores a URL for a custom emoji placeholder.
    ///
    /// Textual uses this attribute as an intermediate representation before resolving emoji into
    /// an attachment.
    public enum EmojiURLAttribute: AttributedStringKey {
      public typealias Value = URL
      public static let name = "Textual.EmojiURL"
    }

    /// Tags a run with a caller-defined identifier that is bridged to the rendered
    /// `Text` as a `CustomTextRunAttribute`.
    ///
    /// Use this attribute when you need a `TextRenderer` to recognize specific runs in
    /// the rendered text (for example, to draw decorations around them). Set the value
    /// on an `AttributeContainer` applied to the relevant runs, then read it from
    /// `Text.Layout.Run` via `run[CustomTextRunAttribute.self]?.identifier`.
    public enum CustomRunIdentifierAttribute: AttributedStringKey {
      public typealias Value = String
      public static let name = "Textual.CustomRunIdentifier"
    }

    /// A property for accessing an attachment attribute.
    public let attachment: AttachmentAttribute

    /// A property for accessing an emoji URL attribute.
    public let emojiURL: EmojiURLAttribute

    /// A property for accessing the custom run identifier attribute.
    public let customRunIdentifier: CustomRunIdentifierAttribute

    public let foundation: AttributeScopes.FoundationAttributes
  }

  /// The Textual attribute scope.
  public var textual: TextualAttributes.Type {
    TextualAttributes.self
  }
}

extension AttributeDynamicLookup {
  /// Provides dynamic member lookup for Textual attributes.
  public subscript<T: AttributedStringKey>(
    dynamicMember keyPath: KeyPath<AttributeScopes.TextualAttributes, T>
  ) -> T {
    return self[T.self]
  }
}

/// A `TextAttribute` that mirrors an `AttributeScopes.TextualAttributes.CustomRunIdentifierAttribute`
/// value from an `AttributedString` onto the rendered `Text`.
///
/// Textual sets this attribute on runs whose `AttributedString` had a value for
/// `\.textual.customRunIdentifier`. A `TextRenderer` can read it from a
/// `Text.Layout.Run` to recognize tagged runs, for example to draw decorations
/// around them:
///
/// ```swift
/// if let identifier = run[CustomTextRunAttribute.self]?.identifier { ... }
/// ```
public struct CustomTextRunAttribute: TextAttribute {
  public let identifier: String

  public init(identifier: String) {
    self.identifier = identifier
  }
}
