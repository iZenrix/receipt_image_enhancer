#ifndef RIE_INTERNAL_VALIDATION_H_
#define RIE_INTERNAL_VALIDATION_H_

#include "receipt_image_enhancer.h"

#include <string>

namespace rie {

struct ValidatedOptions {
  rie_preset preset = RIE_PRESET_BALANCED;
  bool auto_crop = true;
  bool correct_perspective = true;
  int max_output_dimension = 4096;
  rie_output_format output_format = RIE_OUTPUT_JPEG;
  int jpeg_quality = 92;
};

rie_status validateOptions(const rie_options_v1* options,
                           ValidatedOptions* out,
                           std::string* error);

bool looksLikeSupportedImage(const uint8_t* data, size_t length);

constexpr int kMinMaxOutputDimension = 1024;
constexpr int kMaxMaxOutputDimension = 6000;
constexpr int kAbsMaxDecodeDimension = 12000;
constexpr int kMinImageDimension = 16;

}  // namespace rie

#endif  // RIE_INTERNAL_VALIDATION_H_
