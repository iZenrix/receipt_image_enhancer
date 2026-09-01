#include "image_io.h"

#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <vector>

namespace rie {
namespace {

uint16_t read_u16(const uint8_t* p, bool little) {
  if (little) {
    return static_cast<uint16_t>(p[0] | (p[1] << 8));
  }
  return static_cast<uint16_t>((p[0] << 8) | p[1]);
}

uint32_t read_u32(const uint8_t* p, bool little) {
  if (little) {
    return static_cast<uint32_t>(p[0] | (p[1] << 8) | (p[2] << 16) |
                                (p[3] << 24));
  }
  return static_cast<uint32_t>((p[0] << 24) | (p[1] << 16) | (p[2] << 8) |
                              p[3]);
}

rie_status finalizeDecoded(cv::Mat decoded,
                           int orientation,
                           DecodedImage* out,
                           std::string* error) {
  if (decoded.empty()) {
    if (error != nullptr) {
      *error = "decode produced empty image";
    }
    return RIE_DECODE_FAILED;
  }
  if (decoded.cols < kMinImageDimension || decoded.rows < kMinImageDimension) {
    if (error != nullptr) {
      *error = "image dimensions too small";
    }
    return RIE_INVALID_ARGUMENT;
  }
  if (decoded.cols > kAbsMaxDecodeDimension ||
      decoded.rows > kAbsMaxDecodeDimension) {
    if (error != nullptr) {
      *error = "image dimensions too large";
    }
    return RIE_OUT_OF_MEMORY;
  }

  cv::Mat bgr = ensureBgr(decoded);
  out->bgr = applyExifOrientation(bgr, orientation);
  out->exif_orientation = orientation;
  if (out->bgr.empty()) {
    if (error != nullptr) {
      *error = "orientation normalize failed";
    }
    return RIE_PROCESSING_FAILED;
  }
  return RIE_OK;
}

}  // namespace

cv::Mat ensureBgr(const cv::Mat& image) {
  if (image.empty()) {
    return {};
  }
  if (image.channels() == 3) {
    return image;
  }
  if (image.channels() == 4) {
    cv::Mat bgr;
    cv::cvtColor(image, bgr, cv::COLOR_BGRA2BGR);
    return bgr;
  }
  if (image.channels() == 1) {
    cv::Mat bgr;
    cv::cvtColor(image, bgr, cv::COLOR_GRAY2BGR);
    return bgr;
  }
  return {};
}

cv::Mat applyExifOrientation(const cv::Mat& image, int orientation) {
  if (image.empty() || orientation <= 1 || orientation > 8) {
    return image;
  }
  cv::Mat result;
  switch (orientation) {
    case 2:  // mirror horizontal
      cv::flip(image, result, 1);
      break;
    case 3:  // rotate 180
      cv::rotate(image, result, cv::ROTATE_180);
      break;
    case 4:  // mirror vertical
      cv::flip(image, result, 0);
      break;
    case 5:  // mirror horizontal + rotate 270 CW
      cv::transpose(image, result);
      break;
    case 6:  // rotate 90 CW
      cv::rotate(image, result, cv::ROTATE_90_CLOCKWISE);
      break;
    case 7:  // mirror horizontal + rotate 90 CW
      cv::transpose(image, result);
      cv::flip(result, result, 1);
      break;
    case 8:  // rotate 270 CW
      cv::rotate(image, result, cv::ROTATE_90_COUNTERCLOCKWISE);
      break;
    default:
      result = image;
      break;
  }
  return result;
}

int readJpegExifOrientation(const uint8_t* data, size_t length) {
  if (data == nullptr || length < 4 || data[0] != 0xFF || data[1] != 0xD8) {
    return 1;
  }
  size_t i = 2;
  while (i + 4 < length) {
    if (data[i] != 0xFF) {
      ++i;
      continue;
    }
    const uint8_t marker = data[i + 1];
    if (marker == 0xD9 || marker == 0xDA) {
      break;
    }
    if (i + 4 >= length) {
      break;
    }
    const uint16_t seg_len = static_cast<uint16_t>((data[i + 2] << 8) | data[i + 3]);
    if (seg_len < 2 || i + 2 + seg_len > length) {
      break;
    }
    if (marker == 0xE1) {
      const uint8_t* seg = data + i + 4;
      const size_t seg_payload = static_cast<size_t>(seg_len) - 2;
      if (seg_payload >= 14 && std::memcmp(seg, "Exif\0\0", 6) == 0) {
        const uint8_t* tiff = seg + 6;
        const size_t tiff_len = seg_payload - 6;
        if (tiff_len < 8) {
          return 1;
        }
        const bool little = tiff[0] == 'I' && tiff[1] == 'I';
        const bool big = tiff[0] == 'M' && tiff[1] == 'M';
        if (!little && !big) {
          return 1;
        }
        const uint32_t ifd_offset = read_u32(tiff + 4, little);
        if (ifd_offset + 2 > tiff_len) {
          return 1;
        }
        const uint16_t entries = read_u16(tiff + ifd_offset, little);
        for (uint16_t e = 0; e < entries; ++e) {
          const size_t entry = ifd_offset + 2 + static_cast<size_t>(e) * 12;
          if (entry + 12 > tiff_len) {
            break;
          }
          const uint16_t tag = read_u16(tiff + entry, little);
          if (tag == 0x0112) {
            const uint16_t type = read_u16(tiff + entry + 2, little);
            if (type == 3) {
              return static_cast<int>(read_u16(tiff + entry + 8, little));
            }
          }
        }
      }
      break;
    }
    i += 2 + seg_len;
  }
  return 1;
}

rie_status decodeBytes(const uint8_t* data,
                       size_t length,
                       DecodedImage* out,
                       std::string* error) {
  if (out == nullptr) {
    if (error != nullptr) {
      *error = "decode output is null";
    }
    return RIE_INVALID_ARGUMENT;
  }
  if (data == nullptr || length == 0) {
    if (error != nullptr) {
      *error = "empty input buffer";
    }
    return RIE_INVALID_ARGUMENT;
  }
  if (!looksLikeSupportedImage(data, length)) {
    if (error != nullptr) {
      *error = "unsupported image format";
    }
    return RIE_UNSUPPORTED_FORMAT;
  }

  const int orientation = readJpegExifOrientation(data, length);
  std::vector<uint8_t> buffer(data, data + length);
  cv::Mat decoded = cv::imdecode(buffer, cv::IMREAD_COLOR);
  return finalizeDecoded(decoded, orientation, out, error);
}

rie_status decodeFile(const std::string& path,
                      DecodedImage* out,
                      std::string* error) {
  if (path.empty()) {
    if (error != nullptr) {
      *error = "input path is empty";
    }
    return RIE_INVALID_ARGUMENT;
  }
  std::ifstream input(path, std::ios::binary);
  if (!input) {
    if (error != nullptr) {
      *error = "input file not found";
    }
    return RIE_FILE_NOT_FOUND;
  }
  input.seekg(0, std::ios::end);
  const std::streamoff size = input.tellg();
  if (size <= 0) {
    if (error != nullptr) {
      *error = "input file is empty";
    }
    return RIE_DECODE_FAILED;
  }
  input.seekg(0, std::ios::beg);
  std::vector<uint8_t> bytes(static_cast<size_t>(size));
  input.read(reinterpret_cast<char*>(bytes.data()), size);
  if (!input) {
    if (error != nullptr) {
      *error = "failed reading input file";
    }
    return RIE_DECODE_FAILED;
  }
  return decodeBytes(bytes.data(), bytes.size(), out, error);
}

rie_status encodeImage(const cv::Mat& image,
                       const ValidatedOptions& options,
                       std::vector<uint8_t>* out_bytes,
                       std::string* error) {
  if (out_bytes == nullptr) {
    if (error != nullptr) {
      *error = "encode output is null";
    }
    return RIE_INVALID_ARGUMENT;
  }
  if (image.empty()) {
    if (error != nullptr) {
      *error = "cannot encode empty image";
    }
    return RIE_ENCODE_FAILED;
  }

  std::vector<int> params;
  std::string ext = ".jpg";
  if (options.output_format == RIE_OUTPUT_PNG) {
    ext = ".png";
    params = {cv::IMWRITE_PNG_COMPRESSION, 3};
  } else {
    params = {cv::IMWRITE_JPEG_QUALITY, options.jpeg_quality};
  }

  if (!cv::imencode(ext, image, *out_bytes, params) || out_bytes->empty()) {
    if (error != nullptr) {
      *error = "encode failed";
    }
    return RIE_ENCODE_FAILED;
  }
  return RIE_OK;
}

rie_status encodeImageToFile(const cv::Mat& image,
                             const std::string& path,
                             const ValidatedOptions& options,
                             std::string* error) {
  std::vector<uint8_t> bytes;
  const rie_status status = encodeImage(image, options, &bytes, error);
  if (status != RIE_OK) {
    return status;
  }
  std::ofstream output(path, std::ios::binary);
  if (!output) {
    if (error != nullptr) {
      *error = "cannot open output path";
    }
    return RIE_ENCODE_FAILED;
  }
  output.write(reinterpret_cast<const char*>(bytes.data()),
               static_cast<std::streamsize>(bytes.size()));
  if (!output) {
    if (error != nullptr) {
      *error = "failed writing output file";
    }
    return RIE_ENCODE_FAILED;
  }
  return RIE_OK;
}

}  // namespace rie
