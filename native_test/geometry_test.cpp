#include "../src/internal/geometry.h"

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <vector>

namespace {

void expectTrue(bool condition, const char* message) {
  if (!condition) {
    std::cerr << "FAIL: " << message << std::endl;
    std::exit(1);
  }
}

}  // namespace

int main() {
  using rie::orderCorners;
  using rie::OrderedCorners;

  {
    std::vector<cv::Point2f> pts = {
        {10, 10}, {100, 12}, {98, 200}, {8, 190},
    };
    OrderedCorners ordered = orderCorners(pts);
    expectTrue(ordered.top_left.x < ordered.top_right.x, "top order");
    expectTrue(ordered.bottom_left.x < ordered.bottom_right.x, "bottom order");
    expectTrue(ordered.top_left.y < ordered.bottom_left.y, "vertical order");
  }

  {
    std::vector<cv::Point2f> landscape = {
        {5, 40}, {300, 30}, {310, 120}, {10, 130},
    };
    OrderedCorners ordered = orderCorners(landscape);
    expectTrue(rie::quadrilateralArea(ordered) > 1000.0, "landscape area");
  }

  {
    OrderedCorners corners{
        {0, 0},
        {100, 0},
        {100, 200},
        {0, 200},
    };
    const cv::Size size = rie::computeWarpSize(corners, 4096);
    expectTrue(size.width == 100, "warp width");
    expectTrue(size.height == 200, "warp height");
  }

  std::cout << "geometry_test OK\n";
  return 0;
}
