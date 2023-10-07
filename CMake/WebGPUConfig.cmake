cmake_minimum_required(VERSION 3.12)

project(WebGPU)

if (NOT DEFINED WEBGPU_GENERATED_DIR)
    set(WEBGPU_GENERATED_DIR "${CMAKE_CURRENT_LIST_DIR}/../WebGPU")
endif ()

# Detect the OS
if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    set(WEBGPU_PLATFORM "linux")
    set(WEBGPU_EXTENSIONS "a;so")
elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
    set(WEBGPU_PLATFORM "macos")
    set(WEBGPU_EXTENSIONS "a;dylib")
elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    set(WEBGPU_PLATFORM "windows")
    set(WEBGPU_EXTENSIONS "dll.lib;lib")
else ()
    message(FATAL_ERROR "Unsupported platform")
endif ()

# Detect the architecture
if (${CMAKE_SIZEOF_VOID_P} EQUAL 8)
    set(WEBGPU_ARCH "x86_64")
elseif (${CMAKE_SIZEOF_VOID_P} EQUAL 4)
    set(WEBGPU_ARCH "i686")
elseif (CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
    set(WEBGPU_ARCH "arm64")
else ()
    message(FATAL_ERROR "Unsupported architecture")
endif ()

# Detect the build type
if (${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    set(WEBGPU_BUILD_TYPE "${WEBGPU_ARCH}-debug")
else ()
    set(WEBGPU_BUILD_TYPE "${WEBGPU_ARCH}-release")
endif ()

set(WEBGPU_LIBRARY_DIR "${WEBGPU_GENERATED_DIR}/${WEBGPU_PLATFORM}/${WEBGPU_BUILD_TYPE}")
set(WEBGPU_INCLUDE_DIR "${WEBGPU_LIBRARY_DIR}/include")

find_path(WEBGPU_INCLUDE_DIR NAMES webgpu.h wgpu.h webgpu.hpp)
find_library(WEBGPU_NATIVE_STATIC NAMES wgpu_native.a wgpu_native.lib PATHS ${WEBGPU_LIBRARY_DIR})
find_library(WEBGPU_NATIVE_SHARED NAMES wgpu_native.dll wgpu_native.so wgpu_native.dylib PATHS ${WEBGPU_LIBRARY_DIR})

if ((WEBGPU_INCLUDE_DIR) AND (WEBGPU_NATIVE_STATIC OR WEBGPU_NATIVE_SHARED))
    set(WEBGPU_FOUND True)
    message(STATUS "Found WebGPU")
else ()
    set(WEBGPU_FOUND False)
    message(STATUS "WebGPU not found")
endif ()

add_library(WebGPU SHARED IMPORTED GLOBAL)
target_compile_definitions(WebGPU INTERFACE WEBGPU_BACKEND_WGPU)
if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    set(WGPU_RUNTIME_LIB "${WEBGPU_LIBRARY_DIR}/libwgpu_native.so")
    set_target_properties(
            WebGPU
            PROPERTIES
            IMPORTED_LOCATION "${WGPU_RUNTIME_LIB}"
            IMPORTED_NO_SONAME TRUE
            INTERFACE_INCLUDE_DIRECTORIES "${WEBGPU_INCLUDE_DIR}"
    )
elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
    set(WGPU_RUNTIME_LIB "${WEBGPU_LIBRARY_DIR}/libwgpu_native.dylib")
    set_target_properties(
            WebGPU
            PROPERTIES
            IMPORTED_LOCATION "${WGPU_RUNTIME_LIB}"
            INTERFACE_INCLUDE_DIRECTORIES "${WEBGPU_INCLUDE_DIR}"
    )
elseif (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    set(WGPU_RUNTIME_LIB "${WEBGPU_LIBRARY_DIR}/wgpu_native.dll")
    set_target_properties(
            WebGPU
            PROPERTIES
            IMPORTED_LOCATION "${WGPU_RUNTIME_LIB}"
            IMPORTED_IMPLIB "${WGPU_RUNTIME_LIB}.lib"
            INTERFACE_INCLUDE_DIRECTORIES "${WEBGPU_INCLUDE_DIR}"
    )
else ()
    message(FATAL_ERROR "Unsupported platform")
endif ()

message(STATUS "Using WebGPU runtime from '${WGPU_RUNTIME_LIB}'")
set(WGPU_RUNTIME_LIB ${WGPU_RUNTIME_LIB} CACHE INTERNAL "Path to the WebGPU library binary")

function(target_copy_webgpu_binaries Target)
    add_custom_command(
            TARGET ${Target} POST_BUILD
            COMMAND
            ${CMAKE_COMMAND} -E copy_if_different
            ${WGPU_RUNTIME_LIB}
            $<TARGET_FILE_DIR:${Target}>
            COMMENT
            "Copying '${WGPU_RUNTIME_LIB}' to '$<TARGET_FILE_DIR:${Target}>'..."
    )

    if (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        # Bug fix, there might be a cleaner way to do this but no INSTALL_RPATH
        # or related target properties seem to be a solution.
        set_target_properties(${Target} PROPERTIES INSTALL_RPATH "./")
        if (CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
            set(ARCH_DIR aarch64)
        else ()
            set(ARCH_DIR ${CMAKE_SYSTEM_PROCESSOR})
        endif ()
        add_custom_command(
                TARGET ${Target} POST_BUILD
                COMMAND
                ${CMAKE_INSTALL_NAME_TOOL} "-change"
                "/Users/runner/work/wgpu-native/wgpu-native/target/${ARCH_DIR}-apple-darwin/release/deps/libwgpu_native.dylib"
                "@executable_path/libwgpu_native.dylib"
                "$<TARGET_FILE:${Target}>"
                VERBATIM
        )
    endif ()
endfunction()

mark_as_advanced(WEBGPU_INCLUDE_DIR WEBGPU_NATIVE_STATIC WEBGPU_NATIVE_SHARED)
