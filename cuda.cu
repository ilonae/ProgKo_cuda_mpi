#include "Header.h"

//https://github.com/evlasblom/cuda-opencv-examples/blob/master/src/bgrtogray.cu
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#define PNG_DEBUG 3
#include <png.h>

int x, y;

int width, height;
png_byte color_type;
png_byte bit_depth;

png_structp png_ptr;
png_structp output_ptr;
png_infop info_ptr;
int number_of_passes;
png_bytep * row_pointers;


void abort_(const char * s, ...)
{
        va_list args;
        va_start(args, s);
        vfprintf(stderr, s, args);
        fprintf(stderr, "\n");
        va_end(args);
        abort();
}

__global__ void grayscale_kernel(unsigned char* output, int width, int height, png_bytep* row_pointers) {
        const int x = blockIdx.x * blockDim.x + threadIdx.x;
        const int y = blockIdx.y * blockDim.y + threadIdx.y;
        
        if ((x < width) && (y < height)){
            png_bytep row = row_pointers[y];
            /* png_bytep px = &(row[x * 3]);
            png_byte old[3 * sizeof(png_byte)];
            memcpy(old, px, sizeof(old));
            px[0] = 255 - old[0];
            px[1] = 255 - old[1];
            px[2] = 255 - old[2]; */
            output[x] = 1;
            output[y] = 1;
            printf("hello from gpu");  
        }  
}


void write_png_file(char* file_name){
        /* create file */
        FILE *fp = fopen(file_name, "wb");
        if (!fp)
                abort_("[write_png_file] File %s could not be opened for writing", file_name);

        /* initialize stuff */
        png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

        if (!png_ptr)
                abort_("[write_png_file] png_create_write_struct failed");

        info_ptr = png_create_info_struct(png_ptr);
        if (!info_ptr)
                abort_("[write_png_file] png_create_info_struct failed");

        if (setjmp(png_jmpbuf(png_ptr)))
                abort_("[write_png_file] Error during init_io");

        png_init_io(png_ptr, fp);


        /* write header */
        if (setjmp(png_jmpbuf(png_ptr)))
                abort_("[write_png_file] Error during writing header");

        png_set_IHDR(png_ptr, info_ptr, width, height,
                     bit_depth, color_type, PNG_INTERLACE_NONE,
                     PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

        png_write_info(png_ptr, info_ptr);


        /* write bytes */
        if (setjmp(png_jmpbuf(png_ptr)))
                abort_("[write_png_file] Error during writing bytes");

        png_write_image(png_ptr, row_pointers);


        /* end write */
        if (setjmp(png_jmpbuf(png_ptr)))
                abort_("[write_png_file] Error during end of write");

        png_write_end(png_ptr, NULL);

        /* cleanup heap allocation */
        for (y=0; y<height; y++)
                free(row_pointers[y]);
        free(row_pointers);

        fclose(fp);
}



/* 

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
} */

void readpng_version_info()
{
    fprintf(stderr, "   Compiled with libpng %s; using libpng %s.\n",
      PNG_LIBPNG_VER_STRING, png_libpng_ver);
    fprintf(stderr, "   Compiled with zlib %s; using zlib %s.\n",
      ZLIB_VERSION, zlib_version);
}

void read_png_file(char* file_name){
        char header[8];

        FILE *fp = fopen(file_name, "rb");
        if (!fp)
                abort_("[read_png_file] File %s could not be opened for reading", file_name);
        fread(header, 1, 8, fp);

        /* initialize stuff */
        png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

        if (!png_ptr)
                abort_("[read_png_file] png_create_read_struct failed");

        info_ptr = png_create_info_struct(png_ptr);
        if (!info_ptr)
                abort_("[read_png_file] png_create_info_struct failed");

        if (setjmp(png_jmpbuf(png_ptr)))
                abort_("[read_png_file] Error during init_io");

        png_init_io(png_ptr, fp);
        png_set_sig_bytes(png_ptr, 8);

        png_read_info(png_ptr, info_ptr);

        width = png_get_image_width(png_ptr, info_ptr);
        height = png_get_image_height(png_ptr, info_ptr);
        color_type = png_get_color_type(png_ptr, info_ptr);
        bit_depth = png_get_bit_depth(png_ptr, info_ptr);

        number_of_passes = png_set_interlace_handling(png_ptr);
        png_read_update_info(png_ptr, info_ptr);


        /* read file */
        if (setjmp(png_jmpbuf(png_ptr)))
                abort_("[read_png_file] Error during read_image");

        row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * height);
        for (y=0; y<height; y++)
                row_pointers[y] = (png_byte*) malloc(png_get_rowbytes(png_ptr,info_ptr));

        png_read_image(png_ptr, row_pointers);
        std::cout << "File read.";

        fclose(fp);
}

void process_file(void)
{
        if (png_get_color_type(png_ptr, info_ptr) != PNG_COLOR_TYPE_RGB)
                abort_("[process_file] input file is PNG_COLOR_TYPE_RGBA but must be PNG_COLOR_TYPE_RGB "
                       "(lacks the alpha channel)");

        if (png_get_color_type(png_ptr, info_ptr) != PNG_COLOR_TYPE_RGB)
                abort_("[process_file] color_type of input file must be PNG_COLOR_TYPE_RGB (%d) (is %d)",
                       PNG_COLOR_TYPE_RGB, png_get_color_type(png_ptr, info_ptr));

        int colorBytes =  width * height * 3;


        unsigned char* d_input, * d_output;
        int grayBytes = colorBytes;
        bool flag= true;
        cudaError_t status;
        output_ptr = png_ptr;
    
        // Allocate device memory
        SAFE_CALL(cudaMalloc<unsigned char>(&d_input, colorBytes), "CUDA Malloc Failed");
        SAFE_CALL(cudaMalloc<unsigned char>(&d_output, grayBytes), "CUDA Malloc Failed");    
        // Copy data from OpenCV input image to device memory
        SAFE_CALL(cudaMemcpy(d_input, png_ptr, colorBytes, cudaMemcpyHostToDevice), "CUDA Memcpy Host To Device Failed");
    
        // Threads per Block
        const dim3 block(32, 32);
    
        // Calculate grid size to cover the whole image
        const dim3 grid((width + block.x - 1) / block.x, (height + block.y - 1) / block.y);

         // Launch the color conversion kernel
        if(flag ==true){
            grayscale_kernel<<<grid, block>>>(d_output, width, height, row_pointers);
            std::cout << "File converted.";
            }
        status = cudaGetLastError();
        if (status != cudaSuccess)
        {
            std::cerr << "Error with the kernel!" << std::endl;
        }

        

            // Synchronize to check for any kernel launch errors
        SAFE_CALL(cudaDeviceSynchronize(), "Kernel Launch Failed");

        // Copy back data from destination device meory to OpenCV output image
        SAFE_CALL(cudaMemcpy(output_ptr, d_output, grayBytes, cudaMemcpyDeviceToHost), "CUDA Memcpy Host To Device Failed");

        // Free the device memory
        SAFE_CALL(cudaFree(d_input), "CUDA Free Failed");
        SAFE_CALL(cudaFree(d_output), "CUDA Free Failed");
        SAFE_CALL(cudaDeviceReset(), "Reset Failed");
    
}
 
    
int main(int argc, char **argv)
{
    readpng_version_info();
    read_png_file(argv[1]);
    process_file();
    write_png_file(argv[2]);
    return 0;
}
