#include "../src/pipeline/enhancer.h"
#include "../src/receipt_image_enhancer.h"

#include <opencv2/core.hpp>

#include <cstdlib>
#include <iostream>

namespace {

void expectTrue(bool condition, const char* message) {
  if (!condition) {
    std::cerr << "FAIL: " << message << std::endl;
    std::exit(1);
  }
}

}  // namespace

int main() {
  cv::Mat color(120, 90, CV_8UC3, cv::Scalar(200, 180, 160));
  cv::randu(color, cv::Scalar(100, 100, 100), cv::Scalar(220, 220, 220));

  const cv::Mat balanced = rie::enhanceBalanced(color);
  expectTrue(balanced.channels() == 3, "balanced stays color");
  expectTrue(!balanced.empty(), "balanced non-empty");

  const cv::Mat readable = rie::enhanceReadable(color);
  expectTrue(readable.channels() == 1, "readable grayscale");

  const cv::Mat scan = rie::enhanceScan(color);
  expectTrue(scan.channels() == 1, "scan grayscale/binary");
  expectTrue(scan.type() == CV_8UC1, "scan 8-bit");

  bool downscaled = false;
  const cv::Mat large(5000, 4000, CV_8UC3, cv::Scalar(128, 128, 128));
  const cv::Mat resized = rie::resizeToMaxDimension(large, 1024, &downscaled);
  expectTrue(downscaled, "large image downscaled");
  expectTrue(std::max(resized.cols, resized.rows) == 1024, "long edge capped");

  std::cout << "enhancer_test OK\n";
  return 0;
}
