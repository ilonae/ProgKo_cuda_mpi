#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <opencv2/opencv.hpp>
#include <stdio.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <iostream>
#include <chrono>
#include <fstream>
#include "mpi.h"
#include<cuda.h>
#ifdef __CUDACC__
#define CUDA_CALLABLE_MEMBER __host__ __device__
#else
#define CUDA_CALLABLE_MEMBER
#endif 

static inline void _safe_cuda_call(cudaError err, const char* msg, const char* file_name, const int line_number) {
    if (err != cudaSuccess) {
        fprintf(stderr, "%s\n\nFile: %s\n\nLine Number: %d\n\nReason: %s\n", msg, file_name, line_number, cudaGetErrorString(err));
        std::cin.get();
        exit(EXIT_FAILURE);
    }
}

/// Safe call macro.
#define SAFE_CALL(call,msg) _safe_cuda_call((call),(msg),__FILE__,__LINE__)

void convert(const cv::Mat& input, cv::Mat& output, int flag);
//extern void convert_to_gray(const cv::Mat& input, cv::Mat& output) {}