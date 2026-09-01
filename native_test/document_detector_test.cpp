#include "../src/pipeline/document_detector.h"
#include "../src/pipeline/enhancer.h"

#include <opencv2/imgproc.hpp>

#include <cstdlib>
#include <iostream>

namespace {

void expectTrue(bool condition, const char* message) {
  if (!condition) {
    std::cerr << "FAIL: " << message << std::endl;
    std::exit(1);
  }
}

cv::Mat makeReceiptLike() {
  cv::Mat image(800, 600, CV_8UC3, cv::Scalar(40, 40, 40));
  std::vector<cv::Point> pts = {
      {120, 80},
      {480, 100},
      {500, 720},
      {90, 700},
  };
  cv::fillConvexPoly(image, pts, cv::Scalar(235, 235, 230));
  for (int y = 140; y < 680; y += 28) {
    cv::line(image, {150, y}, {450, y}, cv::Scalar(70, 70, 70), 2);
  }
  return image;
}

}  // namespace

int main() {
  const cv::Mat image = makeReceiptLike();
  const rie::DetectionCandidate detection =
      rie::detectDocumentOnWorkingCopy(image, 1280, 0.50);
  expectTrue(detection.confidence >= 0.0, "confidence range low");
  expectTrue(detection.confidence <= 1.0, "confidence range high");

  const cv::Mat blank(400, 400, CV_8UC3, cv::Scalar(180, 180, 180));
  const rie::DetectionCandidate none =
      rie::detectDocumentOnWorkingCopy(blank);
  expectTrue(!none.found, "blank should not detect");

  std::cout << "document_detector_test OK confidence=" << detection.confidence
            << "\n";
  return 0;
}
