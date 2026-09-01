/// Non-fatal conditions observed during enhancement.
enum ReceiptEnhanceWarning {
  /// Document corners were not found; full-frame enhancement was used.
  documentNotDetected,

  /// A candidate was found but confidence was below the crop threshold.
  lowDocumentConfidence,

  /// Input was resized to respect [ReceiptEnhanceOptions.maxOutputDimension].
  inputDownscaled,
}
