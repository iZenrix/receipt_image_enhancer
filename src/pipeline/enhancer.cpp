#include "enhancer.h"

#include <opencv2/imgproc.hpp>

#include <algorithm>
#include <cmath>

namespace rie {
namespace {

cv::Mat toGray(const cv::Mat& bgr) {
  cv::Mat gray;
  if (bgr.channels() == 1) {
    gray = bgr;
  } else {
    cv::cvtColor(bgr, gray, cv::COLOR_BGR2GRAY);
  }
  return gray;
}

cv::Mat claheLuminance(const cv::Mat& bgr, double clip_limit) {
  cv::Mat lab;
  cv::cvtColor(bgr, lab, cv::COLOR_BGR2Lab);
  std::vector<cv::Mat> channels;
  cv::split(lab, channels);
  cv::Ptr<cv::CLAHE> clahe = cv::createCLAHE(clip_limit, cv::Size(8, 8));
  clahe->apply(channels[0], channels[0]);
  cv::merge(channels, lab);
  cv::Mat out;
  cv::cvtColor(lab, out, cv::COLOR_Lab2BGR);
  return out;
}

cv::Mat claheGray(const cv::Mat& gray, double clip_limit) {
  cv::Ptr<cv::CLAHE> clahe = cv::createCLAHE(clip_limit, cv::Size(8, 8));
  cv::Mat out;
  clahe->apply(gray, out);
  return out;
}

cv::Mat lightBilateral(const cv::Mat& image) {
  cv::Mat out;
  if (image.channels() == 1) {
    cv::bilateralFilter(image, out, 5, 40.0, 40.0);
  } else {
    cv::bilateralFilter(image, out, 5, 45.0, 45.0);
  }
  return out;
}

cv::Mat unsharp(const cv::Mat& image, double amount, double sigma) {
  cv::Mat blurred;
  cv::GaussianBlur(image, blurred, cv::Size(0, 0), sigma);
  cv::Mat out;
  cv::addWeighted(image, 1.0 + amount, blurred, -amount, 0, out);
  return out;
}

}  // namespace

cv::Mat resizeToMaxDimension(const cv::Mat& image,
                             int max_dimension,
                             bool* downscaled) {
  if (downscaled != nullptr) {
    *downscaled = false;
  }
  if (image.empty() || max_dimension <= 0) {
    return image;
  }
  const int long_edge = std::max(image.cols, image.rows);
  if (long_edge <= max_dimension) {
    return image;
  }
  const double scale =
      static_cast<double>(max_dimension) / static_cast<double>(long_edge);
  cv::Mat resized;
  cv::resize(image, resized, cv::Size(), scale, scale, cv::INTER_AREA);
  if (downscaled != nullptr) {
    *downscaled = true;
  }
  return resized;
}

cv::Mat enhanceBalanced(const cv::Mat& bgr) {
  cv::Mat lit = claheLuminance(bgr, 2.0);
  cv::Mat denoised = lightBilateral(lit);
  return unsharp(denoised, 0.35, 1.0);
}

cv::Mat enhanceReadable(const cv::Mat& bgr) {
  cv::Mat gray = toGray(bgr);
  cv::Mat lit = claheGray(gray, 2.5);
  cv::Mat denoised = lightBilateral(lit);
  return unsharp(denoised, 0.55, 1.1);
}

cv::Mat enhanceScan(const cv::Mat& bgr) {
  cv::Mat gray = toGray(bgr);
  cv::Mat lit = claheGray(gray, 2.0);
  cv::Mat blurred;
  cv::GaussianBlur(lit, blurred, cv::Size(3, 3), 0);
  cv::Mat binary;
  cv::adaptiveThreshold(blurred, binary, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C,
                        cv::THRESH_BINARY, 31, 12);
  cv::Mat kernel =
      cv::getStructuringElement(cv::MORPH_RECT, cv::Size(2, 2));
  cv::Mat cleaned;
  cv::morphologyEx(binary, cleaned, cv::MORPH_OPEN, kernel);
  return cleaned;
}

cv::Mat applyPreset(const cv::Mat& bgr, rie_preset preset) {
  switch (preset) {
    case RIE_PRESET_READABLE:
      return enhanceReadable(bgr);
    case RIE_PRESET_SCAN:
      return enhanceScan(bgr);
    case RIE_PRESET_BALANCED:
    default:
      return enhanceBalanced(bgr);
  }
}

}  // namespace rie
