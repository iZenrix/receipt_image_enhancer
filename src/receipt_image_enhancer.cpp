#include "receipt_image_enhancer.h"

#include "internal/image_io.h"
#include "internal/validation.h"
#include "pipeline/pipeline.h"

#include <chrono>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <string>
#include <vector>

namespace {

char* duplicateError(const std::string& message) {
  if (message.empty()) {
    return nullptr;
  }
  char* copy = static_cast<char*>(std::malloc(message.size() + 1));
  if (copy == nullptr) {
    return nullptr;
  }
  std::memcpy(copy, message.c_str(), message.size() + 1);
  return copy;
}

void setError(char** error_message, const std::string& message) {
  if (error_message == nullptr) {
    return;
  }
  *error_message = duplicateError(message);
}

void fillResult(const rie::PipelineResult& pipeline,
                int64_t elapsed_us,
                rie_result_v1* result) {
  if (result == nullptr) {
    return;
  }
  result->width = pipeline.image.cols;
  result->height = pipeline.image.rows;
  result->document_detected = pipeline.document_detected ? 1 : 0;
  result->crop_applied = pipeline.crop_applied ? 1 : 0;
  result->detection_confidence = pipeline.detection_confidence;
  result->processing_time_us = elapsed_us;
  result->warning_flags = pipeline.warning_flags;
}

rie_status enhanceMat(const cv::Mat& input,
                      const rie_options_v1* options,
                      cv::Mat* output_image,
                      rie_result_v1* result,
                      char** error_message) {
  const auto started = std::chrono::steady_clock::now();
  rie::ValidatedOptions validated;
  std::string error;
  const rie_status option_status =
      rie::validateOptions(options, &validated, &error);
  if (option_status != RIE_OK) {
    setError(error_message, error);
    return option_status;
  }

  rie::PipelineResult pipeline;
  const rie_status pipeline_status =
      rie::runEnhancePipeline(input, validated, &pipeline, &error);
  if (pipeline_status != RIE_OK) {
    setError(error_message, error);
    return pipeline_status;
  }

  const auto ended = std::chrono::steady_clock::now();
  const auto elapsed_us =
      std::chrono::duration_cast<std::chrono::microseconds>(ended - started)
          .count();
  fillResult(pipeline, elapsed_us, result);
  *output_image = pipeline.image;
  return RIE_OK;
}

}  // namespace

extern "C" {

uint32_t rie_abi_version(void) {
  return RIE_ABI_VERSION;
}

int32_t rie_enhance_file(const char* input_path,
                         const char* output_path,
                         const rie_options_v1* options,
                         rie_result_v1* result,
                         char** error_message) {
  try {
    if (error_message != nullptr) {
      *error_message = nullptr;
    }
    if (input_path == nullptr || output_path == nullptr || result == nullptr) {
      setError(error_message, "null argument");
      return RIE_INVALID_ARGUMENT;
    }
    if (std::strcmp(input_path, output_path) == 0) {
      setError(error_message, "output path must differ from input path");
      return RIE_INVALID_ARGUMENT;
    }

    rie::DecodedImage decoded;
    std::string error;
    const rie_status decode_status =
        rie::decodeFile(input_path, &decoded, &error);
    if (decode_status != RIE_OK) {
      setError(error_message, error);
      return decode_status;
    }

    cv::Mat enhanced;
    const rie_status status =
        enhanceMat(decoded.bgr, options, &enhanced, result, error_message);
    if (status != RIE_OK) {
      return status;
    }

    rie::ValidatedOptions validated;
    const rie_status option_status =
        rie::validateOptions(options, &validated, &error);
    if (option_status != RIE_OK) {
      setError(error_message, error);
      return option_status;
    }

    const rie_status encode_status =
        rie::encodeImageToFile(enhanced, output_path, validated, &error);
    if (encode_status != RIE_OK) {
      setError(error_message, error);
      return encode_status;
    }
    return RIE_OK;
  } catch (const std::bad_alloc&) {
    setError(error_message, "out of memory");
    return RIE_OUT_OF_MEMORY;
  } catch (const std::exception& ex) {
    setError(error_message, ex.what());
    return RIE_PROCESSING_FAILED;
  } catch (...) {
    setError(error_message, "unknown native failure");
    return RIE_PROCESSING_FAILED;
  }
}

int32_t rie_enhance_bytes(const uint8_t* input_data,
                          size_t input_length,
                          const rie_options_v1* options,
                          uint8_t** output_data,
                          size_t* output_length,
                          rie_result_v1* result,
                          char** error_message) {
  try {
    if (error_message != nullptr) {
      *error_message = nullptr;
    }
    if (output_data != nullptr) {
      *output_data = nullptr;
    }
    if (output_length != nullptr) {
      *output_length = 0;
    }
    if (input_data == nullptr || output_data == nullptr ||
        output_length == nullptr || result == nullptr) {
      setError(error_message, "null argument");
      return RIE_INVALID_ARGUMENT;
    }

    rie::DecodedImage decoded;
    std::string error;
    const rie_status decode_status =
        rie::decodeBytes(input_data, input_length, &decoded, &error);
    if (decode_status != RIE_OK) {
      setError(error_message, error);
      return decode_status;
    }

    cv::Mat enhanced;
    const rie_status status =
        enhanceMat(decoded.bgr, options, &enhanced, result, error_message);
    if (status != RIE_OK) {
      return status;
    }

    rie::ValidatedOptions validated;
    const rie_status option_status =
        rie::validateOptions(options, &validated, &error);
    if (option_status != RIE_OK) {
      setError(error_message, error);
      return option_status;
    }

    std::vector<uint8_t> encoded;
    const rie_status encode_status =
        rie::encodeImage(enhanced, validated, &encoded, &error);
    if (encode_status != RIE_OK) {
      setError(error_message, error);
      return encode_status;
    }

    uint8_t* buffer = static_cast<uint8_t*>(std::malloc(encoded.size()));
    if (buffer == nullptr) {
      setError(error_message, "out of memory");
      return RIE_OUT_OF_MEMORY;
    }
    std::memcpy(buffer, encoded.data(), encoded.size());
    *output_data = buffer;
    *output_length = encoded.size();
    return RIE_OK;
  } catch (const std::bad_alloc&) {
    setError(error_message, "out of memory");
    return RIE_OUT_OF_MEMORY;
  } catch (const std::exception& ex) {
    setError(error_message, ex.what());
    return RIE_PROCESSING_FAILED;
  } catch (...) {
    setError(error_message, "unknown native failure");
    return RIE_PROCESSING_FAILED;
  }
}

int32_t rie_detect_document_file(const char* input_path,
                                 rie_detection_result_v1* result,
                                 char** error_message) {
  try {
    if (error_message != nullptr) {
      *error_message = nullptr;
    }
    if (input_path == nullptr || result == nullptr) {
      setError(error_message, "null argument");
      return RIE_INVALID_ARGUMENT;
    }
    std::memset(result, 0, sizeof(*result));

    rie::DecodedImage decoded;
    std::string error;
    const rie_status decode_status =
        rie::decodeFile(input_path, &decoded, &error);
    if (decode_status != RIE_OK) {
      setError(error_message, error);
      return decode_status;
    }

    rie::DetectionCandidate detection;
    const rie_status detect_status =
        rie::runDetectPipeline(decoded.bgr, &detection, &error);
    if (detect_status != RIE_OK) {
      setError(error_message, error);
      return detect_status;
    }

    result->detected = detection.found ? 1 : 0;
    result->confidence = detection.confidence;
    result->image_width = decoded.bgr.cols;
    result->image_height = decoded.bgr.rows;
    result->top_left = {detection.corners.top_left.x,
                        detection.corners.top_left.y};
    result->top_right = {detection.corners.top_right.x,
                         detection.corners.top_right.y};
    result->bottom_right = {detection.corners.bottom_right.x,
                            detection.corners.bottom_right.y};
    result->bottom_left = {detection.corners.bottom_left.x,
                           detection.corners.bottom_left.y};
    return RIE_OK;
  } catch (const std::bad_alloc&) {
    setError(error_message, "out of memory");
    return RIE_OUT_OF_MEMORY;
  } catch (const std::exception& ex) {
    setError(error_message, ex.what());
    return RIE_PROCESSING_FAILED;
  } catch (...) {
    setError(error_message, "unknown native failure");
    return RIE_PROCESSING_FAILED;
  }
}

void rie_free_buffer(void* ptr) {
  std::free(ptr);
}

}  // extern "C"
