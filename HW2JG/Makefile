.SUFFIXES:  .cpp .cu .o
CUDA_HOME := /usr/local/cuda
INC	:= -I$(CUDA_HOME)/include -I.
LIB	:= -L$(CUDA_HOME)/lib -lcudart
CC	:= nvcc
DEP	:=  
ifeq ($(def), )
DEF := 
else
DEF := -D$(def)
endif

NVCCFLAGS	:= -lineinfo -arch=sm_53 --ptxas-options=-v -g 

all:	rabinkarp_single rabinkarp_multiple

rabinkarp_single:	cmpe297_hw2_rabin_karp.o $(DEP)
	$(CC) $(INC) $(NVCCFLAGS) -o rabinkarp_single cmpe297_hw2_rabin_karp.o $(LIB)

rabinkarp_multiple:	cmpe297_hw2_rabin_karp_multiple.o $(DEP)
	$(CC) $(INC) $(NVCCFLAGS) -o rabinkarp_multiple cmpe297_hw2_rabin_karp_multiple.o $(LIB)

.cpp.o:
	$(CC) $(INC) $(NVCCFLAGS) $(DEF) -c $< -o $@ 

.cu.o:
	$(CC) $(INC) $(NVCCFLAGS) $(DEF) -c $< -o $@
	

clean:
	rm -f *.o matrixMul_*


