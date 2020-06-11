#include "Header.h"

//https://github.com/evlasblom/cuda-opencv-examples/blob/master/src/bgrtogray.cu



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


__global__ void emboss_kernel(unsigned char* input, unsigned char* output, int width, int height, int colorWidthStep, int grayWidthStep) {

    const int x = blockIdx.x * blockDim.x + threadIdx.x;
    const int y = blockIdx.y * blockDim.y + threadIdx.y;
    const int xminus = blockIdx.x * blockDim.x + (threadIdx.x-1);
    const int yminus = blockIdx.y * blockDim.y + (threadIdx.y-1);
                                    
    if ((x < width) && (y < height)&&(xminus>0)&&(yminus>0))
    {
        //Loc base Image
        const int color_tid = y * colorWidthStep + (4 * x);
        // 100 *4 + 4 *100
        //     40 + 40
        //Loc in Grayscale
        const int emboss_tid = (yminus * colorWidthStep) + (4 * xminus);
        //99*4+4*99
        // 36+36

        //
        //
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
    
int main(int argc, char **argv)
{

    for (int i = 0; i < argc; ++i) 
    std::cout << argv[i] << "\n";
    
    FILE* in=(FILE*)argv[1];
    FILE* out=(FILE*)argv[2];
    bool once=true;

    readpng_init(in);
    return 0;

    /* int pw=200;
    int ph=200;

    int colorwidthstep=10;
    int grayWidthStep=10;

   
    dim3 gridSize(16);
    dim3 blockSize(8, 8);
    
    grayscale_kernel<<<gridSize, blockSize>>>(inp, out,pw,ph,colorwidthstep, grayWidthStep); */
}
    
int readpng_init(FILE *infile){
    unsigned char sig[8];
  
      fread(sig, 1, 8, infile);
      if (!png_check_sig(sig, 8))
          return 1;   /* bad signature */
  
  png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL,
        NULL);
      if (!png_ptr)
          return 4;   /* out of memory */
    
      info_ptr = png_create_info_struct(png_ptr);
      if (!info_ptr) {
          png_destroy_read_struct(&png_ptr, NULL, NULL);
          return 4;   /* out of memory */
      }
  
  if (setjmp(png_ptr->jmpbuf)) {
          png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
          return 2;
      }
  } 
    
    
    
    ////row
     //const int x = blockIdx.x * blockDim.x + threadIdx.x;
     ////column
     //const int y = blockIdx.y * blockDim.y + threadIdx.y;
     //const int color_tid = y * colorWidthStep + (4 * x);
     //
   //if ((x < width) && (y < height))
    //{
     //   int c = 0;
     //   for (int i = -1; i < 2; i++) {
     //       for (int j = -1; j < 2; j++) {
     //                         
     //           kernel[c] = (x + i) * colorWidthStep + ( (x + i));
     //           //printf("KErnelvalue %d", kernel[c]);
     //           c++;                
     //       }
     //   }
     //   int filterarray[9] = { -1,0,0,0,0,0,0,0,1 };
     //   int j=0;
     //   float calc = 0;
     //   for (int i=0; i < 36;i++) {
     //       if (i % 4 == 0) {
     //           j++;
     //      }
     //      calc=calc+ filterarray[j] * input[kernel[i]];
     //      
     //      printf("calc %d \n", kernel[c]);
     //   }
     //   output[color_tid] = static_cast<unsigned char>(calc);
     //   output[color_tid + 1] = static_cast<unsigned char>(calc);
     //   output[color_tid + 2] = static_cast<unsigned char>(calc);
     //   const unsigned char alpha = input[color_tid + 3];
     //   output[color_tid + 3] = static_cast<unsigned char>(alpha);
     //
    //
    //}


//}
    


/* 
void convert(const cv::Mat& input, cv::Mat& output,bool flag) {
    // Calculate total number of bytes of input and output image
    const int colorBytes = input.step * input.rows;
    const int grayBytes = output.step * output.rows;
    
    unsigned int* d_kernel;

    unsigned char* d_input, * d_output;

    // Allocate device memory
    SAFE_CALL(cudaMalloc<unsigned char>(&d_input, colorBytes), "CUDA Malloc Failed");
    SAFE_CALL(cudaMalloc<unsigned char>(&d_output, grayBytes), "CUDA Malloc Failed");    
    // Copy data from OpenCV input image to device memory
    SAFE_CALL(cudaMemcpy(d_input, input.ptr(), colorBytes, cudaMemcpyHostToDevice), "CUDA Memcpy Host To Device Failed");

    // Threads per Block
    const dim3 block(32, 32);

    // Calculate grid size to cover the whole image
    const dim3 grid((input.cols + block.x - 1) / block.x, (input.rows + block.y - 1) / block.y);

    // Launch the color conversion kernel
    if(flag ==true){
    grayscale_kernel << <grid, block >> > (d_input, d_output, input.cols, input.rows, input.step, output.step);
    }else {    
    emboss_kernel << <grid, block >> > (d_input, d_output, input.cols, input.rows, input.step, output.step);
    }
    // Synchronize to check for any kernel launch errors
    SAFE_CALL(cudaDeviceSynchronize(), "Kernel Launch Failed");

    // Copy back data from destination device meory to OpenCV output image
    SAFE_CALL(cudaMemcpy(output.ptr(), d_output, grayBytes, cudaMemcpyDeviceToHost), "CUDA Memcpy Host To Device Failed");

    // Free the device memory
    SAFE_CALL(cudaFree(d_input), "CUDA Free Failed");
    SAFE_CALL(cudaFree(d_output), "CUDA Free Failed");
} */
