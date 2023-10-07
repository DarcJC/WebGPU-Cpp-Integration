cmake_minimum_required(VERSION 3.12)

project(WebGPU)

if (NOT DEFINED WEBGPU_GENERATED_DIR)
  set(WEBGPU_GENERATED_DIR "${CMAKE_CURRENT_LIST_DIR}/../WebGPU")
endif()

# Detect the OS
if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
  set(WEBGPU_PLATFORM "linux")
  set(WEBGPU_EXTENSIONS "a;so")
elseif(${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
  set(WEBGPU_PLATFORM "macos")
  set(WEBGPU_EXTENSIONS "a;dylib")
elseif(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
  set(WEBGPU_PLATFORM "windows")
  set(WEBGPU_EXTENSIONS "dll.lib;lib")
else()
  message(FATAL_ERROR "Unsupported platform")
endif()

# Detect the architecture
if(${CMAKE_SIZEOF_VOID_P} EQUAL 8)
  set(WEBGPU_ARCH "x86_64")
elseif(${CMAKE_SIZEOF_VOID_P} EQUAL 4)
  set(WEBGPU_ARCH "i686")
else()
  message(FATAL_ERROR "Unsupported architecture")
endif()

# Detect the build type
if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
  set(WEBGPU_BUILD_TYPE "${WEBGPU_ARCH}-debug")
else()
  set(WEBGPU_BUILD_TYPE "${WEBGPU_ARCH}-release")
endif()

set(WEBGPU_LIBRARY_DIR "${WEBGPU_GENERATED_DIR}/${WEBGPU_PLATFORM}/${WEBGPU_BUILD_TYPE}")
set(WEBGPU_INCLUDE_DIR "${WEBGPU_LIBRARY_DIR}/include")

find_path(WEBGPU_INCLUDE_DIR NAMES webgpu.h wgpu.h webgpu.hpp)
find_library(WEBGPU_NATIVE_STATIC NAMES wgpu_native.a wgpu_native.lib PATHS ${WEBGPU_LIBRARY_DIR})
find_library(WEBGPU_NATIVE_SHARED NAMES wgpu_native.dll wgpu_native.so wgpu_native.dylib PATHS ${WEBGPU_LIBRARY_DIR})

if((WEBGPU_INCLUDE_DIR) AND (WEBGPU_NATIVE_STATIC OR WEBGPU_NATIVE_SHARED))
  set(WEBGPU_FOUND True)
  message(STATUS "Found WebGPU")
else()
  set(WEBGPU_FOUND False)
  message(STATUS "WebGPU not found")
endif()

mark_as_advanced(WEBGPU_INCLUDE_DIR WEBGPU_NATIVE_STATIC WEBGPU_NATIVE_SHARED)
