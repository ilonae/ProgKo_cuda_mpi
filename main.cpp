#include "Header.h"
#define windows
//Benchmark aktivieren deaktivieren
//#define Benchmark




int main(int argc, char** argv) {
    int size, rank;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Barrier(MPI_COMM_WORLD);
    int root = 0;
    cv::Mat blanksliceemboss;
    cv::Mat sendslice;
    cv::Mat blankslicegrey;
    //Infos about processor name rank and count
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(processor_name, &name_len);
    printf("Hello from processor %s, rank %d out of %d processors\n", processor_name, rank, size);
    int rowstep;
    int colstep;    
    int fullnewcol = 0;
    int fullnewrow = 0;

#ifdef Benchmark
    typedef std::chrono::high_resolution_clock Clock;
    std::ofstream outputFile;
    
    std::string filename = "benchmark"+ std::to_string(rank)+".csv";
    outputFile.open(filename);
    outputFile << "Time before Scatter" << "," << "Begin Grayscale" <<","<< "End Grayscale"<<"," << "Begin Emboss" <<","<< "End Emboss"<<"," << "Finishing Time"<<"," << "Rank" << std::endl;

    for (int times = 0; times <= 100; times++) {

        auto t1 = Clock::now();


#endif // Benchmark

        if (rank == root) {
            //Pfadangaben unterscheiden sich bei Linux und Windows Extra define für Linux erstellen falls es Probleme gibt. Dürfte aber nicht der Fall sein da OpenCv die Linux Syntax unterstützt
#ifdef windows
            std::string path("C:/Bilder/img.jpg");
            cv::Mat image = cv::imread(path, cv::IMREAD_COLOR);
            cv::Mat fourchannelimage;
#endif
            //Wenn das Bild keine Daten hat beende das Programm
            if (!image.data) { return -1; }
            //Bildgröße aufrunden da die Teile alle gleich groß sein müssen. Spätere Substraktion notwendig. Teilung durch die Anzahl der Prozesse
            //Values durch size
            int newcol = std::ceil(((double)image.cols / (size)));
            int newrow = std::ceil(((double)image.rows / (size)));
            fullnewcol = newcol * size;
            fullnewrow = newrow * size;
            //Größenvektor für das Bild Initialisieren             
            //INITIALISIERE NEUE Größen EINMAL GRAUWERT 1 BYTE und 3 BYTE 
            blankslicegrey = cv::Mat::zeros(fullnewrow, fullnewcol, CV_8UC4);
            blanksliceemboss = cv::Mat::zeros(fullnewrow, fullnewcol, CV_8UC4);
            sendslice = cv::Mat::zeros(fullnewrow, fullnewcol, CV_8UC4);
            //std::cout << "NEWROW: " << newrow << "NEWCOL" << newcol << "" << std::endl;
            //Kopiere Bild auf neue Größe
            std::cout << "REIHEN IMAGE" << image.rows << " " << image.cols << "blankslice" << blanksliceemboss.rows << blanksliceemboss.cols << std::endl;
            cv::cvtColor(image, fourchannelimage, cv::COLOR_RGB2RGBA, 4);
            fourchannelimage.copyTo(sendslice(cv::Rect(0, 0, fourchannelimage.cols, fourchannelimage.rows)));
            std::cout << "sendslice ROWS:" << sendslice.rows << "    BLANKSLICE COLS:" << sendslice.cols << "ehm" << std::endl;
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


        std::cout << "GEHT BIS HIER!";
        cv::Mat mat = cv::Mat(fullnewcol, rowstep, CV_8UC4);
#ifdef Benchmark

        auto t2 = Clock::now();
        std::cout << "Time start scatter" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t2 - t1).count() << std::endl;
#endif
        MPI_Scatter(sendslice.data,
            fullnewrow * colstep * 4,
            MPI_BYTE,
            mat.data,
            fullnewrow * colstep * 4,
            MPI_BYTE,
            root,
            MPI_COMM_WORLD);

        cv::Mat gray(fullnewcol,rowstep,CV_8UC4);
        cv::Mat emboss(fullnewcol, rowstep, CV_8UC4);


#ifdef Benchmark
        auto t3 = Clock::now();
        std::cout << "Time start grayscale" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t3 - t1).count() << std::endl;
#endif
    //GRAYSCALE
   
        convert(mat, gray, true);


#ifdef Benchmark
        auto t4 = Clock::now();
        std::cout << "Time end grayscale" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t3 - t1).count() << std::endl;
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


#ifdef Benchmark
        auto t5 = Clock::now();
        std::cout << "Time till greyscale sendt & Emboss starts" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t4 - t1).count() << std::endl;
#endif

        std::cout << "rennt" << std::endl;
        //TODO EMBOSS REMOVE NEXT LINE AFTER THIS
        
        convert(mat, emboss, false);
        //std::cout << emboss << std::endl;
#ifdef Benchmark
        auto t6 = Clock::now();
        std::cout << "Emboss ended start Gather" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t5 - t1).count() << std::endl;
#endif

        MPI_Gather(emboss.data,
            fullnewrow * colstep * 4,
            MPI_BYTE,
            blanksliceemboss.data,
            fullnewrow * colstep * 4,
            MPI_BYTE,
            root,
            MPI_COMM_WORLD);
        std::cout << "rennt2" << std::endl;
#ifdef Benchmark
        auto t7 = Clock::now();
        std::cout << "Gathered" << rank << "in Nanosekunden" << std::chrono::duration_cast<std::chrono::nanoseconds>(t6 - t1).count() << std::endl;
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
            //imwrite("alpha.png", blanksliceemboss, compression_params);
            imshow("Display window", blanksliceemboss);                   // Show our image inside it.
            cv::waitKey(0);
        }
#endif // !Benchmark




        mat.release();
        gray.release();
        emboss.release();
#ifdef Benchmark
        //Write Nanosecs here :D

        

        if (rank == root) {

            outputFile << std::chrono::duration_cast<std::chrono::nanoseconds>(t2 - t1).count() << ","
                << std::chrono::duration_cast<std::chrono::nanoseconds>(t3 - t1).count() << ","
                << std::chrono::duration_cast<std::chrono::nanoseconds>(t4 - t1).count() << ","
                << std::chrono::duration_cast<std::chrono::nanoseconds>(t5 - t1).count() << ","
                << std::chrono::duration_cast<std::chrono::nanoseconds>(t6 - t1).count() << ","
                << std::chrono::duration_cast<std::chrono::nanoseconds>(t7 - t1).count() << ","
                << rank
                << std::endl;


        }
        else {

            outputFile << std::chrono::duration_cast<std::chrono::nanoseconds>(t2 - t1).count() << ","
                << std::chrono::duration_cast<std::chrono::nanoseconds>(t3 - t1).count() << ","
                << std::chrono::duration_cast<std::chrono::nanoseconds>(t4 - t1).count() << ","
                << std::chrono::duration_cast<std::chrono::nanoseconds>(t5 - t1).count() << ","
                << std::chrono::duration_cast<std::chrono::nanoseconds>(t6 - t1).count() << ","
                //<< std::chrono::duration_cast<std::chrono::nanoseconds>(t7 - t1).count() << ","
                << std::endl;


        }
    }
    outputFile.close();
#endif // DEBUG    
    MPI_Finalize();
    //TODO HIER BILD wieder in Ursprüngliche Größe umwandeln :)

    //TODO SPEICHER LEEREN KEIN GARBAGE COLLECTOR IN C++
    blanksliceemboss.release();
    blankslicegrey.release();
    sendslice.release();

    return 0;
	
	

} 
