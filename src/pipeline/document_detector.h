#ifndef RIE_PIPELINE_DOCUMENT_DETECTOR_H_
#define RIE_PIPELINE_DOCUMENT_DETECTOR_H_

#include "../internal/geometry.h"

#include <opencv2/core.hpp>

namespace rie {

struct DetectionCandidate {
  bool found = false;
  double confidence = 0.0;
  OrderedCorners corners{};
};

DetectionCandidate detectDocument(const cv::Mat& bgr,
                                  double confidence_threshold = 0.65);

DetectionCandidate detectDocumentOnWorkingCopy(const cv::Mat& bgr,
                                               int working_long_edge = 1280,
                                               double confidence_threshold = 0.65);

}  // namespace rie

#endif  // RIE_PIPELINE_DOCUMENT_DETECTOR_H_
