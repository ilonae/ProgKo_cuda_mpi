#include <iostream>
#include <fstream>
#include "png.h"
//...


using namespace std;
FILE *f;
static png_structp png_ptr;
static png_infop info_ptr;
void readpng_version_info()
{
    fprintf(stderr, "   Compiled with libpng %s; using libpng %s.\n",
      PNG_LIBPNG_VER_STRING, png_libpng_ver);
    fprintf(stderr, "   Compiled with zlib %s; using zlib %s.\n",
      ZLIB_VERSION, zlib_version);
}

int readpng_init(FILE *infile, int *pWidth, int *pHeight){
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
int main (int argc, char **argv){
readpng_version_info();
ofstream myfile;
myfile.open("../example/1.dice_micro.png");
int* pwidth;
int* pheight;
readpng_init(f,pwidth,pheight);
}
