/*
 * Copyright (C) 2007,2008   Alex Shulgin
 *
 * This file is part of png++ the C++ wrapper for libpng.  PNG++ is free
 * software; the exact copying conditions are as follows:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. The name of the author may not be used to endorse or promote products
 * derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
 * NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#include <iostream>
#include <ostream>

#include <png.hpp>

void
print_usage()
{
    std::cerr << "usage: read_write_gray_packed 1|2|4 INFILE OUTFILE"
              << std::endl;
}

template< class pixel >
void
test_image(char const* infile, char const* outfile)
{
    png::image< pixel > image(infile, png::require_color_space< pixel >());
    image.write(outfile);
}

int
main(int argc, char* argv[])
try
{
    if (argc != 4)
    {
        print_usage();
        return EXIT_FAILURE;
    }
    char const* bits = argv[1];
    char const* infile = argv[2];
    char const* outfile = argv[3];

    if (strcmp(bits, "1") == 0)
    {
        test_image< png::gray_pixel_1 >(infile, outfile);
    }
    else if (strcmp(bits, "2") == 0)
    {
        test_image< png::gray_pixel_2 >(infile, outfile);
    }
    else if (strcmp(bits, "4") == 0)
    {
        test_image< png::gray_pixel_4 >(infile, outfile);
    }
    else
    {
        print_usage();
        return EXIT_FAILURE;
    }
}
catch (std::exception const& error)
{
    std::cerr << "read_write_gray_packed: " << error.what() << std::endl;
    return EXIT_FAILURE;
}
