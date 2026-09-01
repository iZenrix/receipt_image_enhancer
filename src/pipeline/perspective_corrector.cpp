#include "perspective_corrector.h"

#include <opencv2/imgproc.hpp>

#include <algorithm>
#include <cmath>

namespace rie {

cv::Mat perspectiveCorrect(const cv::Mat& image,
                           const OrderedCorners& corners,
                           int max_dimension) {
  if (image.empty()) {
    return {};
  }
  const cv::Size out_size = computeWarpSize(corners, max_dimension);
  if (out_size.width <= 0 || out_size.height <= 0) {
    return {};
  }

  const std::vector<cv::Point2f> src = corners.asVector();
  const std::vector<cv::Point2f> dst = {
      {0.f, 0.f},
      {static_cast<float>(out_size.width - 1), 0.f},
      {static_cast<float>(out_size.width - 1),
       static_cast<float>(out_size.height - 1)},
      {0.f, static_cast<float>(out_size.height - 1)},
  };
  const cv::Mat transform = cv::getPerspectiveTransform(src, dst);
  cv::Mat warped;
  cv::warpPerspective(image, warped, transform, out_size, cv::INTER_LINEAR,
                      cv::BORDER_REPLICATE);
  return warped;
}

cv::Mat boundingCrop(const cv::Mat& image, const OrderedCorners& corners) {
  if (image.empty()) {
    return {};
  }
  const auto pts = corners.asVector();
  float min_x = pts[0].x;
  float max_x = pts[0].x;
  float min_y = pts[0].y;
  float max_y = pts[0].y;
  for (const auto& p : pts) {
    min_x = std::min(min_x, p.x);
    max_x = std::max(max_x, p.x);
    min_y = std::min(min_y, p.y);
    max_y = std::max(max_y, p.y);
  }
  const int x = std::max(0, static_cast<int>(std::floor(min_x)));
  const int y = std::max(0, static_cast<int>(std::floor(min_y)));
  const int w =
      std::min(image.cols - x, static_cast<int>(std::ceil(max_x - min_x)));
  const int h =
      std::min(image.rows - y, static_cast<int>(std::ceil(max_y - min_y)));
  if (w < 16 || h < 16) {
    return image.clone();
  }
  return image(cv::Rect(x, y, w, h)).clone();
}

}  // namespace rie
