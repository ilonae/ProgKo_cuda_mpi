#include <iostream>
#include <cstdlib>
#include <stdio.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

__global__ void addVectors(const int *a, const int *b, int *c, const int &size)
{
    int i = blockIdx.x * blockDim.x * blockDim.y +
            blockDim.x * threadIdx.y +
            threadIdx.x;
    c[i] = a[i] + b[i];
    printf("hello from gpu");
};

int main()
{
    cudaError_t status;
    const int size = 1024;
    int *a = new int[size];
    int *b = new int[size];
    int *c = new int[size];

    for (int i = 0; i < size; i++)
    {
        a[i] = 1;
        b[i] = 2;
    }

    int *dev_a;
    int *dev_b;
    int *dev_c;
    int deviceCount;
    cudaGetDeviceCount(&deviceCount);
    for (int device = 0; device < deviceCount; ++device)
        {
            cudaDeviceProp deviceProp;
            cudaGetDeviceProperties(&deviceProp, device);
            std::cout << "Device '" << deviceProp.name << "' (" << device << ") has compute capability " << deviceProp.major << "." << deviceProp.minor << " and " << deviceProp.totalGlobalMem << " Bytes of available memory" << std::endl;
        }

    cudaMalloc(&dev_a, sizeof(int) * size);
    status = cudaMalloc(&dev_a, sizeof(float) * size);
    if (status != cudaSuccess)
    {
        std::cerr << "Error with memory allocation!" << std::endl;
        return status;
    }
    cudaMalloc(&dev_b, sizeof(int) * size);
    cudaMalloc(&dev_c, sizeof(int) * size);

    status = cudaMemcpy(dev_a, a, sizeof(float) * size, cudaMemcpyHostToDevice);
    if (status != cudaSuccess)
    {
        std::cerr << "Error with data copying!" << std::endl;
        return status;
    }
    cudaMemcpy(dev_b, b, sizeof(int) * size, cudaMemcpyHostToDevice);
    dim3 gridSize(16);
    dim3 blockSize(8, 8);
    addVectors<<<gridSize, blockSize>>>(dev_a, dev_b, dev_c, size);
    status = cudaGetLastError();
    if (status != cudaSuccess)
    {
        std::cerr << "Error with the kernel!" << std::endl;
        return status;
    }

    cudaMemcpy(c, dev_c, sizeof(int) * size, cudaMemcpyDeviceToHost);
    cudaDeviceSynchronize();

    cudaFree(&dev_a);
    cudaFree(&dev_b);
    cudaFree(&dev_c);
    cudaDeviceReset();

    float avg = 0;
    for (int i = 0; i < size; i++)
        avg += c[i];
    avg /= size;
    std::cout << "Average is: " << avg << ", should be: 3.0" << std::endl;
    delete[] a;
    delete[] b;
    delete[] c;
    return 0;
}