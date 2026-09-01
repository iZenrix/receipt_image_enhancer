#include "geometry.h"

#include <algorithm>
#include <cmath>
#include <numeric>

namespace rie {
namespace {

double cross(const cv::Point2f& o,
             const cv::Point2f& a,
             const cv::Point2f& b) {
  return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
}

}  // namespace

std::vector<cv::Point2f> OrderedCorners::asVector() const {
  return {top_left, top_right, bottom_right, bottom_left};
}

OrderedCorners orderCorners(const std::vector<cv::Point2f>& corners) {
  OrderedCorners ordered{};
  if (corners.size() != 4) {
    return ordered;
  }

  std::vector<cv::Point2f> pts = corners;
  std::sort(pts.begin(), pts.end(), [](const cv::Point2f& a, const cv::Point2f& b) {
    if (a.y == b.y) {
      return a.x < b.x;
    }
    return a.y < b.y;
  });

  cv::Point2f top_a = pts[0];
  cv::Point2f top_b = pts[1];
  cv::Point2f bottom_a = pts[2];
  cv::Point2f bottom_b = pts[3];

  if (top_a.x <= top_b.x) {
    ordered.top_left = top_a;
    ordered.top_right = top_b;
  } else {
    ordered.top_left = top_b;
    ordered.top_right = top_a;
  }

  if (bottom_a.x <= bottom_b.x) {
    ordered.bottom_left = bottom_a;
    ordered.bottom_right = bottom_b;
  } else {
    ordered.bottom_left = bottom_b;
    ordered.bottom_right = bottom_a;
  }

  // Fallback for heavily rotated quads: use sum/diff heuristics.
  const double area =
      std::abs(cross(ordered.top_left, ordered.top_right, ordered.bottom_right)) +
      std::abs(cross(ordered.top_left, ordered.bottom_right, ordered.bottom_left));
  if (area < 1.0) {
    auto sum = [](const cv::Point2f& p) { return p.x + p.y; };
    auto diff = [](const cv::Point2f& p) { return p.x - p.y; };
    auto by_sum = pts;
    std::sort(by_sum.begin(), by_sum.end(),
              [&](const cv::Point2f& a, const cv::Point2f& b) {
                return sum(a) < sum(b);
              });
    ordered.top_left = by_sum.front();
    ordered.bottom_right = by_sum.back();
    auto by_diff = pts;
    std::sort(by_diff.begin(), by_diff.end(),
              [&](const cv::Point2f& a, const cv::Point2f& b) {
                return diff(a) < diff(b);
              });
    ordered.bottom_left = by_diff.front();
    ordered.top_right = by_diff.back();
  }

  return ordered;
}

double edgeLength(const cv::Point2f& a, const cv::Point2f& b) {
  const double dx = static_cast<double>(a.x) - static_cast<double>(b.x);
  const double dy = static_cast<double>(a.y) - static_cast<double>(b.y);
  return std::sqrt(dx * dx + dy * dy);
}

double quadrilateralArea(const OrderedCorners& corners) {
  const auto pts = corners.asVector();
  double area = 0.0;
  for (size_t i = 0; i < pts.size(); ++i) {
    const cv::Point2f& p0 = pts[i];
    const cv::Point2f& p1 = pts[(i + 1) % pts.size()];
    area += static_cast<double>(p0.x) * static_cast<double>(p1.y) -
            static_cast<double>(p1.x) * static_cast<double>(p0.y);
  }
  return std::abs(area) * 0.5;
}

bool isDegenerateQuadrilateral(const OrderedCorners& corners,
                               double min_area,
                               double min_edge) {
  if (quadrilateralArea(corners) < min_area) {
    return true;
  }
  const double edges[] = {
      edgeLength(corners.top_left, corners.top_right),
      edgeLength(corners.top_right, corners.bottom_right),
      edgeLength(corners.bottom_right, corners.bottom_left),
      edgeLength(corners.bottom_left, corners.top_left),
  };
  for (double e : edges) {
    if (e < min_edge) {
      return true;
    }
  }
  return false;
}

cv::Size computeWarpSize(const OrderedCorners& corners, int max_dimension) {
  const double width_top = edgeLength(corners.top_left, corners.top_right);
  const double width_bottom =
      edgeLength(corners.bottom_left, corners.bottom_right);
  const double height_left = edgeLength(corners.top_left, corners.bottom_left);
  const double height_right =
      edgeLength(corners.top_right, corners.bottom_right);

  int width = static_cast<int>(std::round(std::max(width_top, width_bottom)));
  int height =
      static_cast<int>(std::round(std::max(height_left, height_right)));
  width = std::max(width, 32);
  height = std::max(height, 32);

  const int long_edge = std::max(width, height);
  if (max_dimension > 0 && long_edge > max_dimension) {
    const double scale =
        static_cast<double>(max_dimension) / static_cast<double>(long_edge);
    width = std::max(32, static_cast<int>(std::round(width * scale)));
    height = std::max(32, static_cast<int>(std::round(height * scale)));
  }
  return cv::Size(width, height);
}

}  // namespace rie
