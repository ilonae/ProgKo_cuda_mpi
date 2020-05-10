#include <mpi.h>
int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int size;
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Finalize();
}