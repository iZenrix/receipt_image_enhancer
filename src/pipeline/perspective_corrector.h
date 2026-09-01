#ifndef RIE_PIPELINE_PERSPECTIVE_CORRECTOR_H_
#define RIE_PIPELINE_PERSPECTIVE_CORRECTOR_H_

#include "../internal/geometry.h"

#include <opencv2/core.hpp>

namespace rie {

cv::Mat perspectiveCorrect(const cv::Mat& image,
                           const OrderedCorners& corners,
                           int max_dimension);

cv::Mat boundingCrop(const cv::Mat& image, const OrderedCorners& corners);

}  // namespace rie

#endif  // RIE_PIPELINE_PERSPECTIVE_CORRECTOR_H_
