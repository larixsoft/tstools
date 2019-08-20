cmake_minimum_required(VERSION 3.5)
project(tstools LANGUAGES C CXX)

# Get the latest abbreviated commit hash of the working branch
execute_process(
    COMMAND git log -1 --format=%h -- ${CMAKE_CURRENT_SOURCE_DIR}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_COMMIT_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

set (PRODUCT_VERSION_MAJOR 2)
set (PRODUCT_VERSION_MINOR 0)
set (PRODUCT_VERSION_PATCH 1)
set (PRODUCT_VERSION_BUILD ${GIT_COMMIT_HASH})
set (PRODUCT_VERSION_STR ${PRODUCT_VERSION_MAJOR}.${PRODUCT_VERSION_MINOR}.${PRODUCT_VERSION_PATCH}.${PRODUCT_VERSION_BUILD})

# Global settings
set(GLOBAL_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)
set(CMAKE_INSTALL_PREFIX ${PROJECT_BINARY_DIR}/install)
set(BUILD_ROOT ${CMAKE_CURRENT_SOURCE_DIR})

# Sets global output directory for single configuration
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${GLOBAL_OUTPUT_PATH})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${GLOBAL_OUTPUT_PATH})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${GLOBAL_OUTPUT_PATH})

# Sets global output directory for sub-configurations (msvc, mingw)
foreach(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
    string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${GLOBAL_OUTPUT_PATH})
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${GLOBAL_OUTPUT_PATH})
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${GLOBAL_OUTPUT_PATH})
endforeach(OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES)

# get the timestamps for build info
string(TIMESTAMP CURRENT_YEAR %Y)
string(TIMESTAMP PRODUCT_BUILD_TIME %Y-%m-%d,%H:%M:%S)

# predefine the product information
set(PRODUCT_COMPANY_NAME      "Cenozech Inc.")
set(PRODUCT_LEGAL_COPYRIGHT   "Copyright 2008-${CURRENT_YEAR} Cenozech Inc.")
set(PRODUCT_PRODUCT_NAME      "StreamPro")
set(PRODUCT_PRODUCT_VERSION   ${PRODUCT_VERSION_STRING})


# Get the latest abbreviated commit hash of the working branch
execute_process(
    COMMAND git log -1 --format=%h -- ${CMAKE_CURRENT_SOURCE_DIR}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_COMMIT_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)


# use C++11 syntax
set (CMAKE_CXX_STANDARD 11)

# get the build info
if($ENV{build_platform})
   set(BUILD_PLATFORM   "build platform, Win32 or x64" CACHE STRING $ENV{build_platform})
else()
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(BUILD_PLATFORM "x64" CACHE STRING "build platform: win32 or x64")
    else()
        set(BUILD_PLATFORM "win32" CACHE STRING "build platform: win32 or x64")
    endif()
endif()

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()
message(STATUS "Build platform is ${BUILD_PLATFORM}")
message(STATUS "CMAKE_BUILD_TYPE is ${CMAKE_BUILD_TYPE}")

string(TOLOWER ${BUILD_PLATFORM} BUILD_PLATFORM_LOWER)
string(TOLOWER ${CMAKE_BUILD_TYPE} BUILD_TYPE_LOWER)

if( (${BUILD_PLATFORM_LOWER} STREQUAL win32) OR (CMAKE_SIZEOF_VOID_P EQUAL 4) )
    set(SYSTEM_PLATFORM_BITS "32 bit")
else()
    set(SYSTEM_PLATFORM_BITS "64 bit")
endif()

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/src/version.h.in
    ${CMAKE_BINARY_DIR}/version.h
)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
include_directories(${CMAKE_BINARY_DIR})

# collect all source files
set(LIB_SRC_FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/accessunit.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/avs.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ac3.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/adts.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/bitdata.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/es.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/filter.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/fmtx.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/h222.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/h262.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/audio.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/l2audio.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/misc.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/nalunit.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ps.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/pes.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/pidint.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/printing.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/reverse.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ts.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/tsplay_innards.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/tswrite.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/pcap.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ethernet.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ipv4.c
)

add_definitions(-DTSTOOLS_VERSION=${PRODUCT_VERSION_STR})


#find_package(PkgConfig)
#pkg_check_modules(GST REQUIRED gstreamer-1.0>=1.4
#                               gstreamer-sdp-1.0>=1.4
#                               gstreamer-video-1.0>=1.4
#                               gstreamer-app-1.0>=1.4)
#
#message(STATUS "GST_FOUND = ${GST_FOUND}")
#message(STATUS "GST_LIBRARIES = ${GST_LIBRARIES}")
#message(STATUS "GST_LIBRARY_DIRS = ${GST_LIBRARY_DIRS}")
#message(STATUS "GST_LDFLAGS = ${GST_LDFLAGS}")
#message(STATUS "GST_LDFLAGS_OTHER = ${GST_LDFLAGS_OTHER}")
#message(STATUS "GST_INCLUDE_DIRS = ${GST_INCLUDE_DIRS}")
#message(STATUS "GST_CFLAGS = ${GST_CFLAGS}")
#message(STATUS "GST_CFLAGS_OTHER = ${GST_CFLAGS_OTHER}")

add_library(utils SHARED ${LIB_SRC_FILES})

add_executable(esfilter src/esfilter.c)
target_link_libraries(esfilter utils)

add_executable(ts2es src/ts2es.c)
target_link_libraries(ts2es utils)

add_executable(es2ts src/es2ts.c)
target_link_libraries(es2ts utils)

add_executable(esdots src/esdots.c)
target_link_libraries(esdots utils)

add_executable(esmerge src/esmerge.c)
target_link_libraries(esmerge utils)

add_executable(esreport src/esreport.c)
target_link_libraries(esreport utils)

add_executable(esreverse src/esreverse.c)
target_link_libraries(esreverse utils)

add_executable(ps2ts src/ps2ts.c)
target_link_libraries(ps2ts utils)

add_executable(psreport src/psreport.c)
target_link_libraries(psreport utils)

add_executable(psdots src/psdots.c)
target_link_libraries(psdots utils)

add_executable(stream_type src/stream_type.c)
target_link_libraries(stream_type utils)

add_executable(tsdvbsub src/tsdvbsub.c)
target_link_libraries(tsdvbsub utils)

add_executable(tsinfo src/tsinfo.c)
target_link_libraries(tsinfo utils)

add_executable(tsreport src/tsreport.c)
target_link_libraries(tsreport utils)

add_executable(tsplay src/tsplay.c)
target_link_libraries(tsplay utils)

add_executable(tsserve src/tsserve.c)
target_link_libraries(tsserve utils)

add_executable(ts_packet_insert src/ts_packet_insert.c)
target_link_libraries(ts_packet_insert utils)

add_executable(m2ts2ts src/m2ts2ts.c)
target_link_libraries(m2ts2ts utils)

add_executable(pcapreport src/pcapreport.c)
target_link_libraries(pcapreport utils)

add_executable(tsfilter src/tsfilter.c)
target_link_libraries(tsfilter utils)

add_executable(rtp2264 src/rtp2264.c)
target_link_libraries(rtp2264 utils)
