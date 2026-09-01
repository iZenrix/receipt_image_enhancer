#ifndef RIE_PIPELINE_ENHANCER_H_
#define RIE_PIPELINE_ENHANCER_H_

#include "../internal/validation.h"

#include <opencv2/core.hpp>

namespace rie {

cv::Mat enhanceBalanced(const cv::Mat& bgr);
cv::Mat enhanceReadable(const cv::Mat& bgr);
cv::Mat enhanceScan(const cv::Mat& bgr);

cv::Mat applyPreset(const cv::Mat& bgr, rie_preset preset);

cv::Mat resizeToMaxDimension(const cv::Mat& image, int max_dimension, bool* downscaled);

}  // namespace rie

#endif  // RIE_PIPELINE_ENHANCER_H_
