#include "png.h"

void readpng_version_info()
{
    fprintf(stderr, "   Compiled with libpng %s; using libpng\n",
            PNG_LIBPNG_VER_STRING);
}

int main()
{
    readpng_version_info();
}
