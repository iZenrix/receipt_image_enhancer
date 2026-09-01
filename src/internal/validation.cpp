#include "validation.h"

#include <cstring>

namespace rie {

rie_status validateOptions(const rie_options_v1* options,
                           ValidatedOptions* out,
                           std::string* error) {
  if (out == nullptr) {
    if (error != nullptr) {
      *error = "options output is null";
    }
    return RIE_INVALID_ARGUMENT;
  }

  *out = ValidatedOptions{};
  if (options == nullptr) {
    return RIE_OK;
  }

  if (options->struct_size < sizeof(rie_options_v1) ||
      options->abi_version != RIE_ABI_VERSION) {
    if (error != nullptr) {
      *error = "options ABI mismatch";
    }
    return RIE_NATIVE_LIBRARY_UNAVAILABLE;
  }

  if (options->preset < RIE_PRESET_BALANCED ||
      options->preset > RIE_PRESET_SCAN) {
    if (error != nullptr) {
      *error = "invalid preset";
    }
    return RIE_INVALID_ARGUMENT;
  }
  out->preset = static_cast<rie_preset>(options->preset);
  out->auto_crop = options->auto_crop != 0;
  out->correct_perspective = options->correct_perspective != 0;

  if (options->max_output_dimension < kMinMaxOutputDimension ||
      options->max_output_dimension > kMaxMaxOutputDimension) {
    if (error != nullptr) {
      *error = "max_output_dimension out of range (1024-6000)";
    }
    return RIE_INVALID_ARGUMENT;
  }
  out->max_output_dimension = options->max_output_dimension;

  if (options->output_format != RIE_OUTPUT_JPEG &&
      options->output_format != RIE_OUTPUT_PNG) {
    if (error != nullptr) {
      *error = "invalid output format";
    }
    return RIE_INVALID_ARGUMENT;
  }
  out->output_format = static_cast<rie_output_format>(options->output_format);

  if (options->jpeg_quality < 1 || options->jpeg_quality > 100) {
    if (error != nullptr) {
      *error = "jpeg_quality out of range (1-100)";
    }
    return RIE_INVALID_ARGUMENT;
  }
  out->jpeg_quality = options->jpeg_quality;
  return RIE_OK;
}

bool looksLikeSupportedImage(const uint8_t* data, size_t length) {
  if (data == nullptr || length < 8) {
    return false;
  }
  // JPEG
  if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
    return true;
  }
  // PNG
  static const uint8_t kPng[] = {0x89, 0x50, 0x4E, 0x47,
                                 0x0D, 0x0A, 0x1A, 0x0A};
  if (std::memcmp(data, kPng, 8) == 0) {
    return true;
  }
  // WebP (RIFF....WEBP)
  if (length >= 12 && std::memcmp(data, "RIFF", 4) == 0 &&
      std::memcmp(data + 8, "WEBP", 4) == 0) {
    return true;
  }
  return false;
}

}  // namespace rie
