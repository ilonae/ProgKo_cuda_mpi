#include "Header.h"
#define Benchmark


__global__ void grayscale_kernel(unsigned char* input, unsigned char* output, int width, int height, int colorWidthStep, int grayWidthStep) {
    {
        const int x = blockIdx.x * blockDim.x + threadIdx.x;
        const int y = blockIdx.y * blockDim.y + threadIdx.y;
        if ((x < width) && (y < height))
        {
            //Loc base Image
            const int color_tid = y * colorWidthStep + (4 * x);

            //Loc in Grayscale
            const int gray_tid = y * colorWidthStep + (4 * x);

            const unsigned char blue = input[color_tid];
            const unsigned char green = input[color_tid + 1];
            const unsigned char red = input[color_tid + 2];
            const unsigned char alpha = input[color_tid + 3];
            const float gray = red * 0.21f + green * 0.72 + blue * 0.07f;

            output[gray_tid] = static_cast<unsigned char>(gray);
            output[gray_tid+1] = static_cast<unsigned char>(gray);
            output[gray_tid+2] = static_cast<unsigned char>(gray);
            output[gray_tid+3] = static_cast<unsigned char>(alpha);
        }
    }

}

__global__ void grayscale_kernel_single(unsigned char* input, unsigned char* output, int width, int height, int colorWidthStep, int grayWidthStep) {
    {
        const int x = blockIdx.x * blockDim.x + threadIdx.x;
        const int y = blockIdx.y * blockDim.y + threadIdx.y;
        if ((x < width) && (y < height))
        {
            //Loc base Image
            const int color_tid = y * colorWidthStep + (4 * x);

            //Loc in Grayscale
            const int gray_tid = y * grayWidthStep +  x;

            const unsigned char blue = input[color_tid];
            const unsigned char green = input[color_tid + 1];
            const unsigned char red = input[color_tid + 2];
            const unsigned char alpha = input[color_tid + 3];
            const float gray = red * 0.21f + green * 0.72 + blue * 0.07f;

            output[gray_tid] = static_cast<unsigned char>(gray);
        }
    }

}



__global__ void emboss_kernel(unsigned char* input, unsigned char* output, int width, int height, int colorWidthStep, int grayWidthStep) {

    bool once=true;
    const int x = blockIdx.x * blockDim.x + threadIdx.x;
    const int y = blockIdx.y * blockDim.y + threadIdx.y;
    const int xminus = blockIdx.x * blockDim.x + (threadIdx.x);
    const int yminus = blockIdx.y * blockDim.y + (threadIdx.y);
                                    
    if ((x < width) && (y < height))
    {
        const int color_tid = y * colorWidthStep + (4 * x);
        int emboss_tid=0;
        //Loc base Image
        if ((xminus > 1) && (yminus > 1)) {
            emboss_tid = (yminus)*colorWidthStep + 4 * (xminus - 1);

        }
        else {
            emboss_tid  = color_tid;
        }
        
        
        const float RGB[3]{ input[color_tid] * 1.0f, input[color_tid + 1] * 1.0f, input[color_tid + 2] * 1.0f };

        const float RGBdiff[3]{ input[emboss_tid] * 1.0f, input[emboss_tid + 1] * 1.0f, input[emboss_tid + 2] * 1.0f };
            
        
        const float diffs[3]{ RGB[0] - RGBdiff[0], RGB[1] - RGBdiff[1], RGB[2] - RGBdiff[2] };


        float diff = diffs[0];
        if (abs(diffs[1])>abs(diff)) { diff = diffs[1]; }
        if (abs(diffs[2]) > abs(diff)) { diff = diffs[2]; }

        float gray = 128 + diff;
        if (gray > 255) { gray = 255; }
        if (gray < 0) { gray = 0; }
        output[color_tid] = static_cast<unsigned char>(gray);
        output[color_tid + 1] = static_cast<unsigned char>(gray);
        output[color_tid + 2] = static_cast<unsigned char>(gray);
        const unsigned char alpha = input[color_tid + 3];
        output[color_tid + 3] = static_cast<unsigned char>(alpha);
    }
}
    
    

void convert(const cv::Mat& input, cv::Mat& output,int flag) {
    // Calculate total number of bytes of input and output image
    const int colorBytes = input.step * input.rows;
    const int grayBytes = output.step * output.rows;
    std::cout << "colorBytes" << colorBytes << "grayBytes" << grayBytes << "Flag=" << flag<<" outputwidthstep"<<output.step<<std::endl;
    unsigned int* d_kernel;

    unsigned char* d_input, * d_output;


    std::ofstream oFile;
    double t1, t2, t3, t4,t5,t6,t7,t8,t9;
    std::string filename = "CUDAreservation.csv";//+ std::to_string(size) 
    oFile.open(filename, std::ofstream::app);

  

    

    
    t1 = MPI_Wtime();
    // Allocate device memory
    SAFE_CALL(cudaMalloc<unsigned char>(&d_input, colorBytes), "CUDA Malloc Failed");
    t2 = MPI_Wtime();
    SAFE_CALL(cudaMalloc<unsigned char>(&d_output, grayBytes), "CUDA Malloc Failed");    
    // Copy data from OpenCV input image to device memory
    t3 = MPI_Wtime();
    SAFE_CALL(cudaMemcpy(d_input, input.ptr(), colorBytes, cudaMemcpyHostToDevice), "CUDA Memcpy Host To Device Failed");
    t4 = MPI_Wtime();
    // Threads per Block
    const dim3 block(32, 32);

    // Calculate grid size to cover the whole image
    const dim3 grid((input.cols + block.x - 1) / block.x, (input.rows + block.y - 1) / block.y);
    t5 = MPI_Wtime();
    // Launch the color conversion kernel
    if(flag == 0){

        
    grayscale_kernel << <grid, block >> > (d_input, d_output, input.cols, input.rows, input.step, output.step);

        
    }else if(flag == 1) {    
        
    emboss_kernel << <grid, block >> > (d_input, d_output, input.cols, input.rows, input.step, output.step);

    } else if(flag ==2){

    grayscale_kernel_single << <grid, block >> > (d_input, d_output, input.cols, input.rows, input.step, output.step);   

    }
    else {
        std::cout << " Wrong Choice"<<std::endl;
    }
    t6 = MPI_Wtime();
    // Synchronize to check for any kernel launch errors
    SAFE_CALL(cudaDeviceSynchronize(), "Kernel Launch Failed");
    t7 = MPI_Wtime();
    // Copy back data from destination device meory to OpenCV output image
    SAFE_CALL(cudaMemcpy(output.ptr(), d_output, grayBytes, cudaMemcpyDeviceToHost), "CUDA Memcpy Host To Device Failed");
    t8 = MPI_Wtime();
    // Free the device memory
    SAFE_CALL(cudaFree(d_input), "CUDA Free Failed");
    SAFE_CALL(cudaFree(d_output), "CUDA Free Failed");
    t9 = MPI_Wtime();
    
    oFile << "Alloc Color Storage" << "," << "Alloc gray Storage"<<","<<"Data2GDDR"<<","<<"Grayscale Kerneltime"<<","<<"Data2Img"<<","<<"All" << std::endl;
    oFile << t2 - t1 << ","
          << t3 - t2   << ","
          << t4 - t3      << ","
          << t6 - t5     << ","
          << t8 - t7     << ","
          << t9 - t1 
        << std::endl;
    oFile.close();


}
