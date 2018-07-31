// test convolution
// compile with
//		nvcc -I.. -DCUDA_BLOCK_SIZE=192 -Wno-deprecated-gpu-targets -D__TYPE__=float -std=c++11 -O2 -o build/test_argmin test_argmin.cu
// 


#include <stdio.h>
#include <assert.h>
#include <cuda.h>
#include <vector>
#include <ctime>
#include <algorithm>

#include "core/formulas/constants.h"
#include "core/formulas/maths.h"
#include "core/formulas/kernels.h"
#include "core/formulas/norms.h"
#include "core/formulas/factorize.h"

#include "core/GpuConv1D.cu"
#include "core/GpuConv2D.cu"
#include "core/CpuConv.cpp"

using namespace keops;

__TYPE__ floatrand() {
    return ((__TYPE__) std::rand())/RAND_MAX-.5;    // random value between -.5 and .5
}

template < class V > void fillrandom(V& v) {
    generate(v.begin(), v.end(), floatrand);    // fills vector with random values
}

#define DIMPOINT 3
#define DIMVECT 1

int main() {

    // symbolic expression of the function : linear combination of 4 gaussians
    using C = _P<0,1>;
    using X = _X<1,DIMPOINT>;
    using Y = _Y<2,DIMPOINT>;
    using B = _Y<3,DIMVECT>;
    
    using F = GaussKernel<C,X,Y,B>;

    std::cout << std::endl << "Function F : " << std::endl;
    std::cout << PrintFormula<F>();
    std::cout << std::endl << std::endl;

    using FUNCONVF = ArgMinReduction<F>;

    // now we test ------------------------------------------------------------------------------

    int Nx=10000, Ny=10000;

    std::cout << "Testing ArgMin reduction, Nx=" << Nx << ", Ny=" << Ny << std::endl;
        
    std::vector<__TYPE__> vf(Nx*FUNCONVF::DIM);    fillrandom(vf); __TYPE__ *f = vf.data();
    std::vector<__TYPE__> vx(Nx*DIMPOINT);    fillrandom(vx); __TYPE__ *x = vx.data();
    std::vector<__TYPE__> vy(Ny*DIMPOINT);    fillrandom(vy); __TYPE__ *y = vy.data();
    std::vector<__TYPE__> vb(Ny*DIMVECT); fillrandom(vb); __TYPE__ *b = vb.data();

    std::vector<__TYPE__> rescpu(Nx*FUNCONVF::DIM);

    __TYPE__ oos2[1] = {.5};

    clock_t begin, end;

    begin = clock();
    FUNCONVF::Eval<CpuConv>(Nx, Ny, f, oos2, x, y, b);
    end = clock();
    std::cout << "time for CPU computation : " << double(end - begin) / CLOCKS_PER_SEC << std::endl;

    rescpu = vf;

    // display values
    std::cout << "rescpu = ";
    for(int i=0; i<5; i++)
        std::cout << rescpu[i] << " ";
    std::cout << "..." << std::endl << std::endl;

    FUNCONVF::Eval<GpuConv1D_FromHost>(Nx, Ny, f, oos2, x, y, b);	// first dummy call to Gpu

    begin = clock();
    FUNCONVF::Eval<GpuConv1D_FromHost>(Nx, Ny, f, oos2, x, y, b);
    end = clock();
    std::cout << "time for GPU computation (1D scheme) : " << double(end - begin) / CLOCKS_PER_SEC << std::endl;

    std::vector<__TYPE__> resgpu1(Nx*FUNCONVF::DIM);
    resgpu1 = vf;

    // display values
    std::cout << "resgpu1 = ";
    for(int i=0; i<5; i++)
        std::cout << resgpu1[i] << " ";
    std::cout << "..." << std::endl << std::endl;
    
    begin = clock();
    FUNCONVF::Eval<GpuConv2D_FromHost>(Nx, Ny, f, oos2, x, y, b);
    end = clock();
    std::cout << "time for GPU computation (2D scheme) : " << double(end - begin) / CLOCKS_PER_SEC << std::endl;

    std::vector<__TYPE__> resgpu2(Nx*FUNCONVF::DIM);
    resgpu2 = vf;

    // display values
    std::cout << "resgpu2 = ";
    for(int i=0; i<5; i++)
        std::cout << resgpu2[i] << " ";
    std::cout << "..." << std::endl << std::endl;
    
}


