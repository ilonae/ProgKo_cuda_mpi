#include <iostream>
#include <cstdlib>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

int *dev_a;
int *dev_b;
int *dev_c;
cudaMalloc(&dev_a, sizeof(int) * size);
cudaMalloc(&dev_b, sizeof(int) * size);
cudaMalloc(&dev_c, sizeof(int) * size);