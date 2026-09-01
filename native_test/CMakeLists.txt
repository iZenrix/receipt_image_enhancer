cmake_minimum_required(VERSION 3.16)
project(receipt_image_enhancer_native_tests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenCV REQUIRED COMPONENTS core imgproc imgcodecs)

add_library(rie_core STATIC
  ../src/internal/geometry.cpp
  ../src/internal/validation.cpp
  ../src/internal/image_io.cpp
  ../src/pipeline/document_detector.cpp
  ../src/pipeline/perspective_corrector.cpp
  ../src/pipeline/enhancer.cpp
  ../src/pipeline/pipeline.cpp
  ../src/receipt_image_enhancer.cpp
)
target_include_directories(rie_core PUBLIC
  ../src
  ../src/internal
  ../src/pipeline
  ${OpenCV_INCLUDE_DIRS}
)
target_link_libraries(rie_core PUBLIC ${OpenCV_LIBS})

enable_testing()

add_executable(document_detector_test document_detector_test.cpp)
target_link_libraries(document_detector_test PRIVATE rie_core)
add_test(NAME document_detector_test COMMAND document_detector_test)

add_executable(enhancer_test enhancer_test.cpp)
target_link_libraries(enhancer_test PRIVATE rie_core)
add_test(NAME enhancer_test COMMAND enhancer_test)

add_executable(geometry_test geometry_test.cpp)
target_link_libraries(geometry_test PRIVATE rie_core)
add_test(NAME geometry_test COMMAND geometry_test)
