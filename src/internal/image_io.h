#ifndef RIE_INTERNAL_IMAGE_IO_H_
#define RIE_INTERNAL_IMAGE_IO_H_

#include "receipt_image_enhancer.h"
#include "validation.h"

#include <opencv2/core.hpp>
#include <string>
#include <vector>

namespace rie {

struct DecodedImage {
  cv::Mat bgr;
  int exif_orientation = 1;
};

rie_status decodeFile(const std::string& path,
                      DecodedImage* out,
                      std::string* error);

rie_status decodeBytes(const uint8_t* data,
                       size_t length,
                       DecodedImage* out,
                       std::string* error);

rie_status encodeImage(const cv::Mat& image,
                       const ValidatedOptions& options,
                       std::vector<uint8_t>* out_bytes,
                       std::string* error);

rie_status encodeImageToFile(const cv::Mat& image,
                             const std::string& path,
                             const ValidatedOptions& options,
                             std::string* error);

cv::Mat applyExifOrientation(const cv::Mat& image, int orientation);

int readJpegExifOrientation(const uint8_t* data, size_t length);

cv::Mat ensureBgr(const cv::Mat& image);

}  // namespace rie

#endif  // RIE_INTERNAL_IMAGE_IO_H_
