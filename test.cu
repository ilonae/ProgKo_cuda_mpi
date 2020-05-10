#include "cuda_runtime.h"
#include "device_launch_parameters.h"

int *dev_a;
int *dev_b;
int *dev_c;

cudaMalloc(&dev_a, sizeof(int) * size);
cudaMalloc(&dev_b, sizeof(int) * size);
cudaMalloc(&dev_c, sizeof(int) * size);

cudaMemcpy(dev_a, a, sizeof(int) * size, cudaMemcpyHostToDevice);
cudaMemcpy(dev_b, b, sizeof(int) * size, cudaMemcpyHostToDevice);

__global__ void addVectors(const int *a, const int *b, int *c, const int &size)
{
    int i = threadIdx.x;
    c[i] = a[i] + b[i];
}

int blockCount = 1;
int blockSize = size;
addVectors<<<blockCount, blockSize>>>(dev_a, dev_b, dev_c, size);

cudaMemcpy(c, dev_c, sizeof(int) * size, cudaMemcpyDeviceToHost);

cudaFree(&dev_a);
cudaFree(&dev_b);
cudaFree(&dev_c);
cudaDeviceReset();