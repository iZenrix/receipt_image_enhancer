#ifndef RECEIPT_IMAGE_ENHANCER_H_
#define RECEIPT_IMAGE_ENHANCER_H_

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define RIE_EXPORT __declspec(dllexport)
#else
#define RIE_EXPORT __attribute__((visibility("default")))
#endif

/** Native ABI version. Bump on incompatible struct/function changes. */
#define RIE_ABI_VERSION 1u

typedef enum {
  RIE_OK = 0,
  RIE_INVALID_ARGUMENT = 1,
  RIE_FILE_NOT_FOUND = 2,
  RIE_UNSUPPORTED_FORMAT = 3,
  RIE_DECODE_FAILED = 4,
  RIE_ENCODE_FAILED = 5,
  RIE_OUT_OF_MEMORY = 6,
  RIE_PROCESSING_FAILED = 7,
  RIE_NATIVE_LIBRARY_UNAVAILABLE = 8
} rie_status;

typedef enum {
  RIE_PRESET_BALANCED = 0,
  RIE_PRESET_READABLE = 1,
  RIE_PRESET_SCAN = 2
} rie_preset;

typedef enum {
  RIE_OUTPUT_JPEG = 0,
  RIE_OUTPUT_PNG = 1
} rie_output_format;

typedef enum {
  RIE_WARN_NONE = 0,
  RIE_WARN_DOCUMENT_NOT_DETECTED = 1,
  RIE_WARN_LOW_DOCUMENT_CONFIDENCE = 2,
  RIE_WARN_INPUT_DOWNSCALED = 4
} rie_warning_flags;

typedef struct {
  uint32_t struct_size;
  uint32_t abi_version;
  int32_t preset;
  int32_t auto_crop;
  int32_t correct_perspective;
  int32_t max_output_dimension;
  int32_t output_format;
  int32_t jpeg_quality;
} rie_options_v1;

typedef struct {
  int32_t width;
  int32_t height;
  int32_t document_detected;
  int32_t crop_applied;
  double detection_confidence;
  int64_t processing_time_us;
  int32_t warning_flags;
} rie_result_v1;

typedef struct {
  double x;
  double y;
} rie_point;

typedef struct {
  int32_t detected;
  double confidence;
  rie_point top_left;
  rie_point top_right;
  rie_point bottom_right;
  rie_point bottom_left;
  int32_t image_width;
  int32_t image_height;
} rie_detection_result_v1;

RIE_EXPORT uint32_t rie_abi_version(void);

RIE_EXPORT int32_t rie_enhance_file(const char* input_path,
                                   const char* output_path,
                                   const rie_options_v1* options,
                                   rie_result_v1* result,
                                   char** error_message);

RIE_EXPORT int32_t rie_enhance_bytes(const uint8_t* input_data,
                                    size_t input_length,
                                    const rie_options_v1* options,
                                    uint8_t** output_data,
                                    size_t* output_length,
                                    rie_result_v1* result,
                                    char** error_message);

RIE_EXPORT int32_t rie_detect_document_file(const char* input_path,
                                           rie_detection_result_v1* result,
                                           char** error_message);

RIE_EXPORT void rie_free_buffer(void* ptr);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* RECEIPT_IMAGE_ENHANCER_H_ */
