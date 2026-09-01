#ifndef RIE_INTERNAL_GEOMETRY_H_
#define RIE_INTERNAL_GEOMETRY_H_

#include <opencv2/core.hpp>
#include <vector>

namespace rie {

struct OrderedCorners {
  cv::Point2f top_left;
  cv::Point2f top_right;
  cv::Point2f bottom_right;
  cv::Point2f bottom_left;

  std::vector<cv::Point2f> asVector() const;
};

OrderedCorners orderCorners(const std::vector<cv::Point2f>& corners);

double quadrilateralArea(const OrderedCorners& corners);

double edgeLength(const cv::Point2f& a, const cv::Point2f& b);

bool isDegenerateQuadrilateral(const OrderedCorners& corners,
                               double min_area,
                               double min_edge);

cv::Size computeWarpSize(const OrderedCorners& corners, int max_dimension);

}  // namespace rie

#endif  // RIE_INTERNAL_GEOMETRY_H_
