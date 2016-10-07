// CMPE297-6 HW2
// CUDA version Rabin-Karp

#include<stdio.h>
#include<iostream>


/*ADD CODE HERE: Implement the parallel version of the sequential Rabin-Karp*/
__global__ void 
findIfExistsCu(char* input, int input_length, char* pattern, int pattern_length, int patHash, int* result, unsigned long long* runtime)
{
    unsigned long long start_time = clock64();
    int loc_in_input = threadIdx.x; 
    int input_hash,i;
    for(input_hash=0,i=loc_in_input;i<pattern_length+loc_in_input;i++) {
        input_hash=((input_hash << 8) + input[i]) % 997;
    } 
    int j;
    bool match = true;
    if (input_hash == patHash) {
        for(j=loc_in_input;j<loc_in_input+pattern_length;j++) {
           //printf("Thread %d [%d] pattern char %c input char %c\n",threadIdx.x,j,pattern[j-loc_in_input],input[j]);
           match &= (pattern[j-loc_in_input] == input[j]);
        }
        result[loc_in_input]= match?1:0;
    }
	unsigned long long stop_time = clock64();
    runtime[loc_in_input] = (unsigned long long)(stop_time-start_time);
}

int main()
{
	// host variables
	char input[] = "HEABAL"; 	/*Sample Input*/
	char pattern[] = "AB"; 		/*Sample Pattern*/
	int patHash = 0; 			/*hash for the pattern*/
	int* result; 				/*Result array*/
	int* runtime; 				/*Exection cycles*/
	int pattern_length = 2;		/*Pattern Length*/
	int input_length = 6; 		/*Input Length*/

	// device variables
	char* d_input;
	char* d_pattern;
	int* d_result;
	unsigned long long* d_runtime;

	// measure the execution time by using clock() api in the kernel as we did in Lab3
	int runtime_size = input_length-pattern_length+1;

	result = (int *) malloc((input_length-pattern_length+1)*sizeof(int));
	runtime = (int *) malloc(runtime_size);
	memset(runtime,0,input_length-pattern_length+1);
    cudaMalloc((void **)&d_runtime,input_length-pattern_length+1);
	/*Calculate the hash of the pattern*/
	for (int i = 0; i < pattern_length; i++)
    {
        patHash = (patHash * 256 + pattern[i]) % 997;
    }

	/*ADD CODE HERE: Allocate memory on the GPU and copy or set the appropriate values from the HOST*/
    
    // Error code to check return values for CUDA calls
    cudaError_t err = cudaSuccess;
	
    err = cudaMalloc((void **)&d_input,input_length);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to allocated input (error code %s)!\n",cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaMalloc((void **)&d_pattern,pattern_length);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to allocated input (error code %s)!\n",cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaMalloc((void **)&d_result,(input_length-pattern_length+1)*sizeof(int));
    if (err != cudaSuccess) {
        fprintf(stderr,"Failer to allocate result (error code %s)!\n",cudaGetErrorString(err));
    }

    err = cudaMemcpy(d_pattern,pattern,pattern_length,cudaMemcpyHostToDevice);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to copy pattern (error code %s)!\n",cudaGetErrorString(err));
    }

    err = cudaMemcpy(d_input,input,input_length,cudaMemcpyHostToDevice);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to copy input (error code %s)!\n",cudaGetErrorString(err));
    }

	/*ADD CODE HERE: Launch the kernel and pass the arguments*/
    int blocks = 1;
    int threads = input_length-pattern_length+1;
	findIfExistsCu<<<blocks,threads>>>(d_input,input_length,d_pattern,pattern_length,patHash,d_result,d_runtime);

    err = cudaGetLastError();
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to launch kernel (error code %s)!\n",cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaMemcpy(result,d_result,(input_length-pattern_length+1)*sizeof(int),cudaMemcpyDeviceToHost);
    if (err != cudaSuccess) {
        fprintf(stderr,"Failed to copy result (error code %s)!\n",cudaGetErrorString(err)); 
        exit(EXIT_FAILURE);
    }	
    cudaThreadSynchronize();	
	/*ADD CODE HERE: Copy the execution times from the GPU memory to HOST Code*/		


    cudaMemcpy(runtime, d_runtime, runtime_size, cudaMemcpyDeviceToHost);
    cudaThreadSynchronize();

    unsigned long long elapsed_time = 0;
    for(int i = 0; i < input_length-pattern_length+1; i++)
        if(elapsed_time < runtime[i])
            elapsed_time = runtime[i];

	printf("Total cycles: %d \n", (int)elapsed_time);

    printf("Searching for a single pattern in a single string\n");
    printf("Print at which position the pattern was found\n");
    printf("Input string = %s\n",input);
    printf("pattern=%s\n",pattern);
    for (int i = 0;i < input_length-pattern_length+1;i++) {
        printf("Pos:%d Result: %d\n",i,result[i]);
    }	
	/*ADD CODE HERE: COPY the result and print the result as in the HW description*/
	
	return 0;
}

