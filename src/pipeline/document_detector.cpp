#include "document_detector.h"

#include <opencv2/imgproc.hpp>

#include <algorithm>
#include <cmath>
#include <vector>

namespace rie {
namespace {

cv::Mat makeWorkingCopy(const cv::Mat& bgr, int working_long_edge, double* scale) {
  const int long_edge = std::max(bgr.cols, bgr.rows);
  if (long_edge <= working_long_edge) {
    *scale = 1.0;
    return bgr;
  }
  *scale = static_cast<double>(working_long_edge) / static_cast<double>(long_edge);
  cv::Mat resized;
  cv::resize(bgr, resized, cv::Size(), *scale, *scale, cv::INTER_AREA);
  return resized;
}

double scoreCandidate(const OrderedCorners& corners,
                      const cv::Size& image_size,
                      const cv::Mat& edges) {
  const double image_area =
      static_cast<double>(image_size.width) * static_cast<double>(image_size.height);
  if (image_area <= 0.0) {
    return 0.0;
  }
  const double area = quadrilateralArea(corners);
  const double area_ratio = area / image_area;
  if (area_ratio < 0.08 || area_ratio > 0.98) {
    return 0.0;
  }
  if (isDegenerateQuadrilateral(corners, image_area * 0.05, 12.0)) {
    return 0.0;
  }

  // Edge support: sample points along each side and count edge pixels.
  const auto pts = corners.asVector();
  int samples = 0;
  int hits = 0;
  for (size_t i = 0; i < pts.size(); ++i) {
    const cv::Point2f& a = pts[i];
    const cv::Point2f& b = pts[(i + 1) % pts.size()];
    for (int s = 0; s < 20; ++s) {
      const double t = (s + 0.5) / 20.0;
      const int x = static_cast<int>(std::round(a.x + (b.x - a.x) * t));
      const int y = static_cast<int>(std::round(a.y + (b.y - a.y) * t));
      if (x < 0 || y < 0 || x >= edges.cols || y >= edges.rows) {
        continue;
      }
      ++samples;
      if (edges.at<uint8_t>(y, x) > 0) {
        ++hits;
      }
    }
  }
  const double edge_score =
      samples > 0 ? static_cast<double>(hits) / static_cast<double>(samples) : 0.0;

  // Prefer receipt-like aspect without being A4-strict.
  const double width =
      std::max(edgeLength(corners.top_left, corners.top_right),
               edgeLength(corners.bottom_left, corners.bottom_right));
  const double height =
      std::max(edgeLength(corners.top_left, corners.bottom_left),
               edgeLength(corners.top_right, corners.bottom_right));
  const double aspect = width > 0.0 ? height / width : 0.0;
  double aspect_score = 1.0;
  if (aspect < 0.2 || aspect > 8.0) {
    aspect_score = 0.2;
  } else if (aspect < 0.5 || aspect > 4.5) {
    aspect_score = 0.7;
  }

  const double area_score = std::min(1.0, area_ratio / 0.55);
  const double confidence =
      std::clamp(0.45 * area_score + 0.40 * edge_score + 0.15 * aspect_score,
                 0.0, 1.0);
  return confidence;
}

}  // namespace

DetectionCandidate detectDocument(const cv::Mat& bgr,
                                  double confidence_threshold) {
  DetectionCandidate best;
  if (bgr.empty()) {
    return best;
  }

  cv::Mat gray;
  cv::cvtColor(bgr, gray, cv::COLOR_BGR2GRAY);
  cv::GaussianBlur(gray, gray, cv::Size(5, 5), 0);
  cv::Mat edges;
  cv::Canny(gray, edges, 50, 150);
  cv::dilate(edges, edges, cv::Mat(), cv::Point(-1, -1), 1);

  std::vector<std::vector<cv::Point>> contours;
  cv::findContours(edges, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
  std::sort(contours.begin(), contours.end(),
            [](const std::vector<cv::Point>& a, const std::vector<cv::Point>& b) {
              return cv::contourArea(a) > cv::contourArea(b);
            });

  const size_t limit = std::min<size_t>(contours.size(), 30);
  for (size_t i = 0; i < limit; ++i) {
    std::vector<cv::Point> approx;
    const double peri = cv::arcLength(contours[i], true);
    cv::approxPolyDP(contours[i], approx, 0.02 * peri, true);
    if (approx.size() != 4 || !cv::isContourConvex(approx)) {
      continue;
    }
    std::vector<cv::Point2f> pts;
    pts.reserve(4);
    for (const auto& p : approx) {
      pts.emplace_back(static_cast<float>(p.x), static_cast<float>(p.y));
    }
    OrderedCorners ordered = orderCorners(pts);
    const double confidence =
        scoreCandidate(ordered, bgr.size(), edges);
    if (confidence > best.confidence) {
      best.found = confidence >= confidence_threshold;
      best.confidence = confidence;
      best.corners = ordered;
    }
  }

  if (best.confidence > 0.0 && best.confidence < confidence_threshold) {
    best.found = false;
  }
  return best;
}

DetectionCandidate detectDocumentOnWorkingCopy(const cv::Mat& bgr,
                                               int working_long_edge,
                                               double confidence_threshold) {
  double scale = 1.0;
  const cv::Mat working = makeWorkingCopy(bgr, working_long_edge, &scale);
  DetectionCandidate candidate =
      detectDocument(working, confidence_threshold);
  if (candidate.confidence <= 0.0) {
    return candidate;
  }
  if (scale != 1.0) {
    const float inv = static_cast<float>(1.0 / scale);
    candidate.corners.top_left *= inv;
    candidate.corners.top_right *= inv;
    candidate.corners.bottom_right *= inv;
    candidate.corners.bottom_left *= inv;
  }
  return candidate;
}

}  // namespace rie
