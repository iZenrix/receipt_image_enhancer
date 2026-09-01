#include "pipeline.h"

#include "enhancer.h"
#include "perspective_corrector.h"

#include "../receipt_image_enhancer.h"

namespace rie {

rie_status runDetectPipeline(const cv::Mat& input_bgr,
                             DetectionCandidate* out,
                             std::string* error) {
  if (out == nullptr) {
    if (error != nullptr) {
      *error = "detection output is null";
    }
    return RIE_INVALID_ARGUMENT;
  }
  if (input_bgr.empty()) {
    if (error != nullptr) {
      *error = "empty image for detection";
    }
    return RIE_INVALID_ARGUMENT;
  }
  *out = detectDocumentOnWorkingCopy(input_bgr);
  return RIE_OK;
}

rie_status runEnhancePipeline(const cv::Mat& input_bgr,
                              const ValidatedOptions& options,
                              PipelineResult* out,
                              std::string* error) {
  if (out == nullptr) {
    if (error != nullptr) {
      *error = "pipeline output is null";
    }
    return RIE_INVALID_ARGUMENT;
  }
  if (input_bgr.empty()) {
    if (error != nullptr) {
      *error = "empty image for enhancement";
    }
    return RIE_INVALID_ARGUMENT;
  }

  PipelineResult result;
  cv::Mat working = input_bgr;

  if (options.auto_crop) {
    DetectionCandidate detection = detectDocumentOnWorkingCopy(working);
    result.detection_confidence = detection.confidence;
    result.document_detected = detection.found;
    if (detection.confidence > 0.0 && !detection.found) {
      result.warning_flags |= RIE_WARN_LOW_DOCUMENT_CONFIDENCE;
    }
    if (!detection.found) {
      result.warning_flags |= RIE_WARN_DOCUMENT_NOT_DETECTED;
    } else {
      if (options.correct_perspective) {
        cv::Mat corrected =
            perspectiveCorrect(working, detection.corners,
                               options.max_output_dimension);
        if (!corrected.empty()) {
          working = corrected;
          result.crop_applied = true;
        } else {
          result.warning_flags |= RIE_WARN_DOCUMENT_NOT_DETECTED;
          result.document_detected = false;
        }
      } else {
        cv::Mat cropped = boundingCrop(working, detection.corners);
        if (!cropped.empty()) {
          working = cropped;
          result.crop_applied = true;
        }
      }
    }
  }

  bool downscaled = false;
  working =
      resizeToMaxDimension(working, options.max_output_dimension, &downscaled);
  if (downscaled) {
    result.warning_flags |= RIE_WARN_INPUT_DOWNSCALED;
  }

  result.image = applyPreset(working, options.preset);
  if (result.image.empty()) {
    if (error != nullptr) {
      *error = "enhancement produced empty image";
    }
    return RIE_PROCESSING_FAILED;
  }

  *out = std::move(result);
  return RIE_OK;
}

}  // namespace rie
