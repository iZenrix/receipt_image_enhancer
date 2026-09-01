#ifndef RIE_PIPELINE_PIPELINE_H_
#define RIE_PIPELINE_PIPELINE_H_

#include "../internal/validation.h"
#include "document_detector.h"

#include <opencv2/core.hpp>
#include <string>
#include <vector>

namespace rie {

struct PipelineResult {
  cv::Mat image;
  bool document_detected = false;
  bool crop_applied = false;
  double detection_confidence = 0.0;
  int warning_flags = 0;
};

rie_status runEnhancePipeline(const cv::Mat& input_bgr,
                              const ValidatedOptions& options,
                              PipelineResult* out,
                              std::string* error);

rie_status runDetectPipeline(const cv::Mat& input_bgr,
                             DetectionCandidate* out,
                             std::string* error);

}  // namespace rie

#endif  // RIE_PIPELINE_PIPELINE_H_
