#include "Header.h"

//#define Benchmark
#define CUDAVSOPENCV



int main(int argc, char** argv) {
    int size, rank;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    int realsize = size;
    //MPI_Barrier(MPI_COMM_WORLD);
    int root = 0;
    cv::Mat blanksliceemboss;
    cv::Mat sendslice;
    cv::Mat blankslicegrey;
    cv::Mat blanksliceU1grey;
    //Infos about processor name rank and count
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(processor_name, &name_len);
    printf("Hello from processor %s, rank %d out of %d processors\n", processor_name, rank, size);
    int rowstep=0;
    int colstep=0;
    int fullnewcol = 0;
    int fullnewrow = 0;

#ifdef Benchmark
    typedef std::chrono::high_resolution_clock Clock;
    std::ofstream outputFile;
    double t1, t2, t3, t4, t5, t6, t7=0;
    std::string filename = "benchmark.csv";//+ std::to_string(size) 
    outputFile.open(filename,std::ofstream::app);
    if (rank == root) {
        outputFile << "Time before Scatter" << "," << "Begin Grayscale" << "," << "End Grayscale" << "," << "Begin Emboss" << "," << "End Emboss" << "," << "Finishing Time" << "," << "Rank" << std::endl;
    }
    //for (int times = 0; times <= 10; times++) {

        t1 = MPI_Wtime();


#endif // Benchmark

        if (rank == root) {
            //Pfadangaben unterscheiden sich bei Linux und Windows Extra define für Linux erstellen falls es Probleme gibt. Dürfte aber nicht der Fall sein da OpenCv die Linux Syntax unterstützt

            std::cout << argv[1] << std::endl;
            std::string path(argv[1]);
            cv::Mat image = cv::imread(path, cv::IMREAD_COLOR||cv::IMREAD_UNCHANGED);
            cv::Mat fourchannelimage;

            //Wenn das Bild keine Daten hat beende das Programm
            if (!image.data) { return -1; }
#ifdef CUDAVSOPENCV

            std::ofstream oFile;
            double t10, t11, t12, t13;
            std::string filename = "CUDAVSMPI.csv";//+ std::to_string(size) 
            oFile.open(filename, std::ofstream::app);
            cv::cvtColor(image, fourchannelimage, cv::COLOR_RGB2RGBA, 4);
            cv::Mat greyMat;
            cv::Mat graymat = cv::Mat(image.rows,image.cols, CV_8UC4);
            t10 = MPI_Wtime();
            convert(fourchannelimage, graymat, true);
            t11 = MPI_Wtime();
            t12 = MPI_Wtime();
            cv::cvtColor(image, greyMat, cv::COLOR_BGRA2GRAY);
            t13 = MPI_Wtime();
            oFile << "Grayscale CUDA" << ","   << "Grayscale Opencv" << std::endl;
            oFile << t11 - t10 << ","
                << t13 - t12 << ","
                << std::endl;
            oFile.close();
            //cv::namedWindow("Display window", cv::WINDOW_AUTOSIZE);// Create a window for display.
            //std::vector<int> compression_params;
            //compression_params.push_back(cv::IMWRITE_PNG_COMPRESSION);
            //compression_params.push_back(9);
            ////imwrite("gray.png", blankslicegrey, compression_params);
            //imshow("Display window", graymat);                   // Show our image inside it.
            //cv::waitKey(0);

#endif

            //Bildgröße aufrunden da die Teile alle gleich groß sein müssen. Spätere Substraktion notwendig. Teilung durch die Anzahl der Prozesse
            //Values durch size
            int newcol = std::ceil(((double)image.cols / (size)));
            int newrow = std::ceil(((double)image.rows / (size)));
            fullnewcol = newcol * size;
            fullnewrow = newrow * size;
            //Größenvektor für das Bild Initialisieren             
            //INITIALISIERE NEUE Größen EINMAL GRAUWERT 1 BYTE und 3 BYTE 
            blankslicegrey =    cv::Mat(fullnewrow, fullnewcol, CV_8UC4);
            blanksliceemboss =  cv::Mat(fullnewrow, fullnewcol, CV_8UC4);
            sendslice =         cv::Mat(fullnewrow, fullnewcol, CV_8UC4);
            blanksliceU1grey =  cv::Mat(fullnewrow, fullnewcol, CV_8UC1);
            //std::cout << "NEWROW: " << newrow << "NEWCOL" << newcol << "" << std::endl;
            //Kopiere Bild auf neue Größe
            //std::cout << "REIHEN IMAGE" << image.rows << " " << image.cols << "blankslice" << blanksliceemboss.rows << blanksliceemboss.cols << std::endl;
            cv::cvtColor(image, fourchannelimage, cv::COLOR_RGB2RGBA, 4);
            fourchannelimage.copyTo(sendslice(cv::Rect(0, 0, fourchannelimage.cols, fourchannelimage.rows)));            
            rowstep = newrow;
            colstep = newcol;

            fourchannelimage.release();
            image.release();
        }

        //VERTEILEN DER PARAMETER WITH BROADCAST TO ALL PROCESSES    
        MPI_Bcast(&rowstep, 1, MPI_INT, root, MPI_COMM_WORLD);
        MPI_Bcast(&colstep, 1, MPI_INT, root, MPI_COMM_WORLD);
        MPI_Bcast(&fullnewcol, 1, MPI_INT, root, MPI_COMM_WORLD);
        MPI_Bcast(&fullnewrow, 1, MPI_INT, root, MPI_COMM_WORLD);
#ifdef Benchmark
        MPI_Bcast(&t1, sizeof(t1), MPI_BYTE, root, MPI_COMM_WORLD);
#endif 


        //std::cout << "GEHT BIS HIER!";
        cv::Mat mat = cv::Mat(fullnewcol, rowstep, CV_8UC4);
        cv::Mat matsingle = cv::Mat(fullnewcol, rowstep, CV_8UC1);

#ifdef Benchmark

        t2 = MPI_Wtime();
        //std::cout << "Time start scatter" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t2 - t1).count() << std::endl;
#endif



            MPI_Scatter(sendslice.data,
                fullnewrow * colstep * 4,
                MPI_BYTE,
                mat.data,
                fullnewrow * colstep * 4,
                MPI_BYTE,
                root,
                MPI_COMM_WORLD);
        

        
        


#ifdef Benchmark
        t3 = MPI_Wtime();
        //std::cout << "Time start grayscale" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t3 - t1).count() << std::endl;
#endif
        //GRAYSCALE
        cv::Mat gray = cv::Mat(fullnewcol, rowstep, CV_8UC4);
        convert(mat, gray, 0);


#ifdef Benchmark
        t4 = MPI_Wtime();        //std::cout << "Time end grayscale" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t3 - t1).count() << std::endl;
#endif
        //Hier soll das Grayscale Bild eingesammelt werdedn
        
        MPI_Gather(gray.data,
            fullnewrow * colstep * 4,
            MPI_BYTE,
            blankslicegrey.data,
            fullnewrow * colstep * 4,
            MPI_BYTE,
            root,
            MPI_COMM_WORLD);

        cv::Mat graysingle = cv::Mat(fullnewcol, rowstep, CV_8UC1);
        convert(mat, graysingle, 2);

        MPI_Gather(graysingle.data,
            fullnewrow * colstep * 1,
            MPI_BYTE,
            blanksliceU1grey.data,
            rowstep * colstep * 1,
            MPI_BYTE,
            root,
            MPI_COMM_WORLD);

#ifdef Benchmark
        t5 = MPI_Wtime();
        //std::cout << "Time till greyscale sendt & Emboss starts" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t4 - t1).count() << std::endl;
#endif

        //std::cout << "rennt" << std::endl;
        //TODO EMBOSS REMOVE NEXT LINE AFTER THIS
        cv::Mat emboss = cv::Mat(fullnewcol, rowstep, CV_8UC4);
        convert(mat, emboss, 1);
        //std::cout << emboss << std::endl;
#ifdef Benchmark
        t6 = MPI_Wtime();
        //std::cout << "Emboss ended start Gather" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t5 - t1).count() << std::endl;
#endif

        MPI_Gather(emboss.data,
            fullnewrow * colstep * 4,
            MPI_BYTE,
            blanksliceemboss.data,
            fullnewrow * colstep * 4,
            MPI_BYTE,
            root,
            MPI_COMM_WORLD);

        

        //std::cout << "rennt2" << std::endl;
#ifdef Benchmark
        t7 = MPI_Wtime();
        //std::cout << "Gathered" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t6 - t1).count() << std::endl;
#endif
        //Maybe Remove ?! ONLY FOR DEBUG CAUSES
#ifndef Benchmark
        if (rank == root) {
            std::cout << "greyslice ROWS:" << blankslicegrey.rows << "    greyslice COLS:" << blankslicegrey.cols << "ehm" << std::endl;
            std::cout << "OUTROWS        :" << gray.rows << "    OUTCOLS: " << gray.cols << std::endl;
            cv::namedWindow("Display window", cv::WINDOW_AUTOSIZE);// Create a window for display.
            std::vector<int> compression_params;
            compression_params.push_back(cv::IMWRITE_PNG_COMPRESSION);
            compression_params.push_back(9);
            imwrite("gray.png", blankslicegrey, compression_params);
            imshow("Display window", blanksliceU1grey);                   // Show our image inside it.
            cv::waitKey(0);
        }
#endif // !Benchmark




        mat.release();
        gray.release();
        emboss.release();
        graysingle.release();
#ifdef Benchmark
        //Write Nanosecs here :D



        if (rank == root) {

            outputFile << t2 - t1 << ","
                       << t3 - t1 << ","
                       << t4 - t1 << ","
                       << t5 - t1 << ","
                       << t6 - t1 << ","
                       << t7 - t1 << ","
                << size
                << std::endl;


        }

    
    outputFile.close();
#endif // DEBUG    

    MPI_Finalize();

    blanksliceemboss.release();
    blankslicegrey.release();
    sendslice.release();
    std::cout << "Finished" << std::endl;
    return 0;



}