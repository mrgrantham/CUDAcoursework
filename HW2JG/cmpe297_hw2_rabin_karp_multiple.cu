// CMPE297-6 HW2
// CUDA version Rabin-Karp

#include<stdio.h>
#include<iostream>

#define NUM_PATTERN 4
#define PATTERN_MAX_LENGTH 15
/*ADD CODE HERE: Implement the parallel version of the sequential Rabin-Karp*/
__global__ void 
findIfExistsCu(char* input, int input_length, char* pattern, int *pattern_length, int *patHash, char* result, unsigned long long* runtime)
{
    //printf("Starting kernal thread %d block %d with pattern start %d\n",threadIdx.x,blockIdx.x,pattern_length[threadIdx.x]);
    
    unsigned long long start_time = clock64();
    int loc_in_input = threadIdx.x;
    int pattern_num = blockIdx.x; 
    int input_hash,i;

    //printf("input section: ");
    for(input_hash=0,i=loc_in_input;i<pattern_length[pattern_num]+loc_in_input;i++) {
        //printf("%c",input[i]);
        input_hash=((input_hash << 8) + input[i]) % 997;
    }
    //printf("\n");
    int j;
    bool match = true;
    __syncthreads();
    if (input_hash == patHash[pattern_num]) {
        int pattern_start_index = 0;
        for(int pat=0;pat < blockIdx.x;pat++) {
            pattern_start_index += pattern_length[pat];
        } 
        for(j=loc_in_input;j<loc_in_input+pattern_length[pattern_num];j++) {
           //printf("Block %d Thread %d [%d] pattern char %c input char %c\n",blockIdx.x,threadIdx.x,j,pattern[j-loc_in_input],input[j]);
           match &= (pattern[pattern_start_index+(j-loc_in_input)] == input[j]);
        }
        result[pattern_num] |= match?1:0;
    }

    if(result[pattern_num]){
        //printf("***pattern found in kernel at [%d]\n",pattern_num);
    }else {
       //////////////// printf("nothing here\n");
    }
	unsigned long long stop_time = clock64();
    runtime[(input_length*pattern_num)+loc_in_input] = (unsigned long long)(stop_time-start_time);
}

int main()
{
	// host variables
	char input[] = "Searching for multiple patterns in the input sequence."; 	/*Sample Input*/
	const char *pattern[NUM_PATTERN] = {"multiple","s i","ddd","seq"}; 		/*Sample Pattern*/
    char *patternflat;
    int patHash[NUM_PATTERN]; 			/*hash for the pattern*/
	char* result; 				/*Result array*/
	int pattern_length[NUM_PATTERN];		/*Pattern Length*/
	int input_length = strlen(input); 		/*Input Length*/
	// device variables
	char* d_input;
	char* d_pattern;
	char* d_result;
    int * d_pattern_length;
    int * d_patHash;
    
    int patternflat_length=0;
	/*Calculate the hash of the pattern*/
    for(int pl = 0; pl < NUM_PATTERN;pl++) {
        pattern_length[pl]=strlen(pattern[pl]);
        patternflat_length += pattern_length[pl];
    }
    patternflat = (char*)malloc(patternflat_length * sizeof(char));
    int flatindex = 0;
    for(int p = 0;p < NUM_PATTERN;p++) {
        //printf("strlen for \"%s\" is %d\n",pattern[p],pattern_length[p]);	
        memcpy(patternflat+flatindex,pattern[p],pattern_length[p]);
        flatindex += pattern_length[p];
        for (int i = 0; i < pattern_length[p]; i++)
        {
            patHash[p] = (patHash[p] * 256 + pattern[p][i]) % 997;
        }
   
    }
    //printf("\ndone calculating hash\n");
	// measure the execution time by using clock() api in the kernel as we did in Lab3
	int runtime_size = input_length*NUM_PATTERN*sizeof(unsigned long long);

    // Error code to check return values for CUDA calls
    cudaError_t err = cudaSuccess;
	
    unsigned long long* d_runtime;
	result = (char *) malloc((NUM_PATTERN)*sizeof(char));
    memset(result,0,NUM_PATTERN*sizeof(char));
	unsigned long long* runtime = (unsigned long long *) malloc(runtime_size);
	memset(runtime,0,runtime_size);
    err = cudaMalloc((void **)&d_runtime,runtime_size);
    
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to allocated d_runtime (error code %s)!\n",cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    
	/*ADD CODE HERE: Allocate memory on the GPU and copy or set the appropriate values from the HOST*/
    
	
    err = cudaMalloc((void **)&d_input,input_length);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to allocated input (error code %s)!\n",cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaMalloc((void **)&d_pattern,flatindex*sizeof(char));
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to allocated input (error code %s)!\n",cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaMalloc((void **)&d_pattern_length,NUM_PATTERN*sizeof(int));
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to allocated pattern_length[] (error code %s)!\n",cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    
    err = cudaMalloc((void **)&d_patHash,NUM_PATTERN*sizeof(int));
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to allocated patHash[] (error code %s)!\n",cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaMalloc((void **)&d_result,(NUM_PATTERN)*sizeof(char));
    if (err != cudaSuccess) {
        fprintf(stderr,"Failer to allocate result (error code %s)!\n",cudaGetErrorString(err));
    }
    err = cudaMemcpy(d_result,result,NUM_PATTERN*sizeof(char),cudaMemcpyHostToDevice);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to copy result (error code %s)!\n",cudaGetErrorString(err));
    }
    
    err = cudaMemcpy(d_pattern,patternflat,flatindex*sizeof(char),cudaMemcpyHostToDevice);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to copy pattern (error code %s)!\n",cudaGetErrorString(err));
    }

    err = cudaMemcpy(d_pattern_length,pattern_length,NUM_PATTERN*sizeof(int),cudaMemcpyHostToDevice);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to copy pattern_length[] (error code %s)!\n",cudaGetErrorString(err));
    }
    
    err = cudaMemcpy(d_patHash,patHash,NUM_PATTERN*sizeof(int),cudaMemcpyHostToDevice);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to copy payHash[] (error code %s)!\n",cudaGetErrorString(err));
    }

    err = cudaMemcpy(d_input,input,input_length,cudaMemcpyHostToDevice);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to copy input (error code %s)!\n",cudaGetErrorString(err));
    }

	/*ADD CODE HERE: Launch the kernel and pass the arguments*/
    int blocks = NUM_PATTERN;
    int threads = input_length;
	findIfExistsCu<<<blocks,threads>>>(d_input,input_length,d_pattern,d_pattern_length,d_patHash,d_result,d_runtime);
    err = cudaGetLastError();
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to launch kernel (error code %s)!\n",cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaMemcpy(result,d_result,NUM_PATTERN*sizeof(char),cudaMemcpyDeviceToHost);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to copy back result (error code %s)!\n",cudaGetErrorString(err)); 
        exit(EXIT_FAILURE);
    }	
    cudaThreadSynchronize();	
	/*ADD CODE HERE: Copy the execution times from the GPU memory to HOST Code*/		


    cudaMemcpy(runtime, d_runtime, runtime_size, cudaMemcpyDeviceToHost);
    cudaThreadSynchronize();

    unsigned long long elapsed_time = 0;
    for(int i = 0; i < input_length*NUM_PATTERN; i++)
        if(elapsed_time < runtime[i])
            elapsed_time = runtime[i];

	printf("\nTotal cycles: %d \n", (int)elapsed_time);

    printf("Searching for multiple patterns in the input sequence\n");
    printf("Input string = %s\n",input);
    for (int i = 0;i < NUM_PATTERN;i++) {
        printf("Pattern: \"%s\" %s\n",pattern[i],result[i]?"was found":"was not found");
    }	
	/*ADD CODE HERE: COPY the result and print the result as in the HW description*/
	
	return 0;
}

