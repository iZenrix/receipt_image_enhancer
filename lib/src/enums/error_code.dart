/// Typed error codes for predictable failure modes.
enum ReceiptImageEnhancerErrorCode {
  /// Caller provided invalid options or arguments.
  invalidArgument,

  /// Input path does not exist.
  fileNotFound,

  /// Image container/format is not supported in v1.
  unsupportedFormat,

  /// Bytes could not be decoded as an image.
  decodeFailed,

  /// Enhanced image could not be encoded/written.
  encodeFailed,

  /// Native library missing, unloadable, or ABI mismatch.
  nativeLibraryUnavailable,

  /// Native allocation or image size exceeded safe limits.
  outOfMemory,

  /// Generic processing failure after validation/decode succeeded.
  processingFailed,
}
