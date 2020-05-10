#include <iostream>
#include <cstdlib>
#include <stdio.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

__global__ void addVectors(const int *a, const int *b, int *c, const int &size)
{
    for (int i = 0; i < size; i++)
    {
        c[i] = a[i] + b[i];
    }
}

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

    addVectors<<<1, 1>>>(a, b, c, size);

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