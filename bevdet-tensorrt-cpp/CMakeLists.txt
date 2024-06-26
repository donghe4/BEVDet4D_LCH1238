# SPDX-FileCopyrightText: Copyright (c) 2021 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.1.0)
project(demo LANGUAGES CXX CUDA)

find_package(CUDA REQUIRED)
find_package(yaml-cpp REQUIRED)
find_package(Eigen3 REQUIRED)


if(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL  "aarch64")
  set(CMAKE_C_COMPILER /usr/bin/aarch64-linux-gnu-gcc)
  set(CMAKE_CXX_COMPILER /usr/bin/aarch64-linux-gnu-g++)
  set(CUDA_INSTALL_TARGET_DIR targets/aarch64-linux)
elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "x86_64")
  set(CMAKE_C_COMPILER /usr/bin/gcc)
  set(CMAKE_CXX_COMPILER /usr/bin/g++)
  set(CUDA_INSTALL_TARGET_DIR targets/x86_64-linux)
endif()

set(CUDA_TOOLKIT_ROOT_DIR /usr/local/cuda)
set(CUDA_INCLUDE_DIRS ${CUDA_TOOLKIT_ROOT_DIR}/${CUDA_INSTALL_TARGET_DIR}/include)

set(CMAKE_BUILD_TYPE "RELEASE")

set(CMAKE_CXX_FLAGS_RELEASE "-Wno-deprecated-declarations -O2")

add_compile_options(-W)
add_compile_options(-std=c++11)

# set( SMS 30 32 35 37 50 52 53 60 61 62 70 72 75 86 87)
# foreach(sm ${SMS})
	# set(GENCODE ${GENCODE} -gencode arch=compute_${sm},code=sm_${sm})
# endforeach()
# set(HIGHEST_SM 87)
# set(GENCODE ${GENCODE} -gencode arch=compute_${HIGHEST_SM},code=compute_${HIGHEST_SM})

# set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS}
#   -ccbin ${CMAKE_CXX_COMPILER}"
# )
set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} -std=c++11 -O0 -Xcompiler -fPIC -g -w -gencode=arch=compute_86,code=sm_86")



if(${CMAKE_BUILD_TYPE} STREQUAL "DEBUG")
  message("Using Debug Mode")
  set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS} -g -G --ptxas-options=-v)
endif()


if(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL  "aarch64")       # orin
  set(TENSORRT_INCLUDE_DIRS /usr/include/aarch64-linux-gnu/)
  set(TENSORRT_LIBRARY_DIRS /usr/lib/aarch64-linux-gnu/)
elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "x86_64")
  set(TENSORRT_INCLUDE_DIRS /root/TensorRT-8.5.2.2/include)  # your tensorrt path
  set(TENSORRT_LIBRARY_DIRS /root/TensorRT-8.5.2.2/lib)
endif()


set(CUDA_LIB_DIRS ${CUDA_TOOLKIT_ROOT_DIR}/${CUDA_INSTALL_TARGET_DIR}/lib)
find_library(NVJPEG_LIBRARY nvjpeg ${CUDA_LIB_DIRS})
if(NVJPEG_LIBRARY)
  add_definitions(-D__HAVE_NVJPEG__)
  link_libraries(${NVJPEG_LIBRARY})
  message(STATUS ${NVJPEG_LIBRARY})
endif()


include_directories(
  ${CUDA_INCLUDE_DIRS}
  ${TENSORRT_INCLUDE_DIRS}
  ${YAML_CPP_INCLUDE_DIRS}
  ${PROJECT_SOURCE_DIR}/include
  ${EIGEN3_INCLUDE_DIRS}
)

link_directories(
	${TENSORRT_LIBRARY_DIRS}
)

cuda_add_executable(bevdemo 
    demo_bevdet.cpp 
    src/bevdet.cpp 
    src/preprocess.cu 
    src/iou3d_nms.cu
    src/postprocess.cu
    src/data.cpp
    src/cpu_jpegdecoder.cpp
    src/nvjpegdecoder.cpp

    src/preprocess_plugin.cu
    src/bevpool_plugin.cu
    src/alignbev_plugin.cu
    src/gatherbev_plugin.cu
)

target_link_libraries(bevdemo 
    yaml-cpp 
    libnvinfer.so
    libjpeg.so
)


cuda_add_executable(export 
  tools/export_engine.cu
  src/preprocess_plugin.cu
  src/bevpool_plugin.cu
  src/alignbev_plugin.cu
  src/gatherbev_plugin.cu
)

target_link_libraries(export 
  libnvinfer.so
  libnvonnxparser.so
  libz.so
)

# cuda_add_library(preprocess_plugin SHARED src/preprocess_plugin.cu)
# cuda_add_library(bevpool_plugin SHARED src/bevpool_plugin.cu)
# cuda_add_library(alignbev_plugin SHARED src/alignbev_plugin.cu)
# cuda_add_library(gatherbev_plugin SHARED src/gatherbev_plugin.cu)