#include <iostream>
#include <cstdlib>
#include <stdio.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

__global__ void addVectors(const int *a, const int *b, int *c, const int &size)
{
    int i = blockDim.x * blockIdx.x + threadIdx.x;
    c[i] = a[i] + b[i];
    printf("hello from gpu");
};

int main()
{
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

    cudaMalloc(&dev_a, sizeof(int) * size);
    cudaMalloc(&dev_b, sizeof(int) * size);
    cudaMalloc(&dev_c, sizeof(int) * size);

    cudaMemcpy(dev_a, a, sizeof(int) * size, cudaMemcpyHostToDevice);
    cudaMemcpy(dev_b, b, sizeof(int) * size, cudaMemcpyHostToDevice);

    int blockCount = 1;
    int blockSize = size;
    addVectors<<<4, size / 4>>>(dev_a, dev_b, dev_c, size);

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