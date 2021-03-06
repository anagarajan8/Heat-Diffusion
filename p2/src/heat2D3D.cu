//Referred Dr.Swenson's Sample code and Nvidia PDF for some code syntaxes and Excerpts. File read logic reference taken from online sources
//like geeks for geeks and cplusplus.com. 

/*
   Akshaya Nagarajan
   ECE 6122 P2
GTID: 903319262
 */

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <vector>
#include <string>
#include <fstream>
#include <sstream>


#define T_P_B 1024  //Threads per block for cuda kernel


//struct to store values from conf file

struct init_values {

	std::string dimension;
	float k;
	int timesteps, width, height, depth;
	float default_temp;
	std::vector<int> heatsource;
	std::vector<float> fixed_temp;

};

struct init_values init;


//Logic to read conf file 

void init_readconf(std::string conf)
{
	std::ifstream conf_file(conf.c_str());
	std::string line;
	std::vector<std::string> conf_vector;

	while (std::getline(conf_file, line)) {
		conf_vector.push_back(line);
	}

	std::vector<std::string> temp;
	std::vector<int> temp2;
	std::vector<float> temp3;

	for (int i = 0; i < conf_vector.size(); ++i)
	{
		if ((conf_vector[i].empty() == 0) && (conf_vector[i].find("#") != 0))
		{
			temp.push_back(conf_vector[i]);
		}

	}


	//initialize values non comma separated

	std::stringstream dim0(temp[0]);	
	dim0 >> init.dimension;
	std::stringstream dim1(temp[1]);
	dim1 >> init.k;
	std::stringstream dim2(temp[2]);
	dim2 >> init.timesteps;
	std::stringstream dim3(temp[4]);
	dim3 >> init.default_temp;

	//initialize values comma separated
	if (init.dimension == "2D")
	{
		std::stringstream dim4;
		dim4 << temp[3];
		int a;

		//First get the total grid size
		while(dim4 >> a)
		{
			if (dim4.peek() == ',')
			{
				dim4.ignore();
			}

			temp2.push_back(a);

		}

		init.width = temp2[0];
		init.height = temp2[1];

		for (int i = 5; i < temp.size(); ++i)
		{
			std::stringstream dim5;
			dim5 << temp[i];
			float b;

			//Get the heat source values
			while(dim5 >> b)
			{

				if (dim5.peek() == ',')
				{
					dim5.ignore();
				}

				temp3.push_back(b);

			}
		}


		//Put heat source values into vectors
		for (int i = 0; i < temp3.size(); ++i)
		{	

			init.heatsource.push_back(temp3[i]);

		}



		for (int i = 4; i < temp3.size(); i= i+5)
		{
			init.fixed_temp.push_back(temp3[i]);

		}

		for (int i = 4; i < init.heatsource.size(); i= i+4)
		{
			init.heatsource.erase(init.heatsource.begin() + i);
		}

	}

	else {

		std::stringstream dim4;
		dim4 << temp[3];
		int a;

		//First get the total grid size
		while(dim4 >> a)
		{
			if (dim4.peek() == ',')
			{
				dim4.ignore();
			}

			temp2.push_back(a);

		}

		init.width = temp2[0];
		init.height = temp2[1];
		init.depth = temp2[2];

		for (int i = 5; i < temp.size(); ++i)
		{
			std::stringstream dim5;
			dim5 << temp[i];
			float b;

			//Get the heat source values
			while(dim5 >> b)
			{

				if (dim5.peek() == ',')
				{
					dim5.ignore();
				}

				temp3.push_back(b);

			}
		}

		//Put heat source values into vectors
		for (int i = 0; i < temp3.size(); ++i)
		{	

			init.heatsource.push_back(temp3[i]);

		}

		for (int i = 6; i < temp3.size(); i= i+7)
		{
			init.fixed_temp.push_back(temp3[i]);

		}

		for (int i = 6; i < init.heatsource.size(); i= i+6)
		{
			init.heatsource.erase(init.heatsource.begin() + i);
		}

	}


}



//kernel function for 2D

__global__ void twodfunc(float *arraymain, float *arraytemp, float *arraybool, float k, int width, int height, int N) {

	int idx = threadIdx.x + blockIdx.x * blockDim.x; //Get thread Ids


	if (idx < N)
	{

		float top = arraymain[idx + width];
		float bottom = arraymain[idx - width];
		float left = arraymain[idx -1];
		float right = arraymain[idx +1];

		//Heat Diffusion formula for 8 corner and 1 general case in 2D
		//for 1st element
		if (idx == 0)
		{
			arraytemp[idx] = arraymain[idx] + arraybool[idx]*(k*(arraymain[idx] + top + arraymain[idx] + right - 4*arraymain[idx]));

		}

		//for last element 
		else if (idx == (width*height -1))
		{
			arraytemp[idx] = arraymain[idx] + arraybool[idx]*(k*(arraymain[idx] + bottom + arraymain[idx] + left - 4*arraymain[idx]));

		}

		//for leftcorner top
		else if ((idx + width == width*height) && (idx%width == 0))
		{
			arraytemp[idx] = arraymain[idx] + arraybool[idx]*(k*(arraymain[idx] + bottom + arraymain[idx] + right - 4*arraymain[idx]));

		}

		//for rightcorner bottom
		else if ((idx - width < 0) && (idx%width == (width-1)))
		{
			arraytemp[idx] = arraymain[idx] + arraybool[idx]*(k*(arraymain[idx] + top + arraymain[idx] + left - 4*arraymain[idx]));

		}

		//for top 
		else if (idx + width > width*height)
		{
			arraytemp[idx] = arraymain[idx] + arraybool[idx]*(k*(arraymain[idx] + bottom + left + right - 4*arraymain[idx]));

		}

		//for bottom 
		else if (idx - width < 0) 
		{
			arraytemp[idx] = arraymain[idx] + arraybool[idx]*(k*(arraymain[idx] + top + left + right - 4*arraymain[idx]));

		}

		//for left
		else if (idx%width == 0)
		{
			arraytemp[idx] = arraymain[idx] + arraybool[idx]*(k*(arraymain[idx] + top + bottom + right - 4*arraymain[idx]));

		}

		//for right
		else if (idx%width == (width-1))
		{
			arraytemp[idx] = arraymain[idx] + arraybool[idx]*(k*(arraymain[idx] + top + left + bottom - 4*arraymain[idx]));

		}


		//general cases
		else 
		{
			arraytemp[idx] = arraymain[idx] + arraybool[idx]*(k*(top + bottom + left + right - 4*arraymain[idx]));

		}

	}

}


//kernel function for 3D
__global__ void threedfunc(float *arraymain, float *arraytemp, float *arraybool, float k, int width, int height, int depth, int N) {

	int idx = threadIdx.x + blockIdx.x * blockDim.x; //Get thread Ids

	if (idx < N)
	{

		//Setting by default to its own values for corner cases

		float top = arraymain[idx];
		float bottom = arraymain[idx];
		float left = arraymain[idx];
		float right = arraymain[idx];                  
		float front = arraymain[idx]; 
		float back = arraymain[idx];



		//index computation for non corner cases (in order to avoid many loops covering the individual cases)
		int index;
		//for top
		index = idx + width*depth;

		if (index < N)
		{	

			top = arraymain[index];
		}

		//for bottom
		index = idx - width*depth;

		if (index >= 0)
		{

			bottom = arraymain[index];
		}

		//for front
		index = idx%(width*depth);
		index = index/width;

		if (index != 0)
		{

			front = arraymain[idx - width];
		}

		//for back
		if (index != (depth-1))
		{

			back = arraymain[idx + width];
		}

		//for left
		index = idx%width;

		if (index != 0)
		{

			left = arraymain[idx-1];
		}

		//for right
		if (index != width-1)
		{

			right = arraymain[idx+1];
		}

		//general formula for heat diffusion 3D with calculated indexes
		arraytemp[idx] = arraymain[idx] + arraybool[idx]*(k*(front + back + top + bottom + left + right - 6*arraymain[idx]));


	}

}



//main 

int main(int argc, char* argv[]) {

	init_readconf(argv[1]);

	//For 2D
	if (init.dimension == "2D")
	{

		char *filename = (char *)"heatOutput.csv";
		FILE *fp;
		fp = fopen(filename, "w");

		float size = (init.width*init.height) * sizeof(float);
		int N = init.width*init.height;


		float a[N], b[N], c[N];
		float *d_a, *d_b, *d_c;

		for (int i = 0; i < N; ++i)
		{	
			a[i] = init.default_temp;
			b[i] = 0;
			c[i] = 1;
		}


		//logic for conf file and array integration 2D
		int index = 0;

		for (int i = 0; i < init.heatsource.size(); i=i+4)
		{
			for (int j = init.heatsource[i+1]; j < init.heatsource[i+1]+init.heatsource[i+3]; j++)
			{


				for (int k = init.heatsource[i]; k < init.heatsource[i]+init.heatsource[i+2]; k++)
				{

					a[j*init.width + k] = init.fixed_temp[index];
					c[j*init.width + k] = 0;
				}
			}

			index++;

		}

		//initialize array for device 
		cudaMalloc((void **)&d_a, size);
		cudaMalloc((void **)&d_b, size);
		cudaMalloc((void **)&d_c, size);

		//copy to device from host
		cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice);
		cudaMemcpy(d_b, b, size, cudaMemcpyHostToDevice);
		cudaMemcpy(d_c, c, size, cudaMemcpyHostToDevice);

		float *swap;

		//Looping timesteps number of times to get the final grid
		for (int i = 0; i < init.timesteps; i++)
		{
			twodfunc<<<(N + T_P_B-1) / T_P_B, T_P_B>>>(d_a, d_b, d_c, init.k, init.width, init.height, N); //Call kernel function
			cudaDeviceSynchronize();
			swap = d_a;
			d_a = d_b;
			d_b = swap;	

		}

		//copy to host from device
		cudaMemcpy(a, d_a, size, cudaMemcpyDeviceToHost);
		cudaMemcpy(b, d_b, size, cudaMemcpyDeviceToHost);


		// //Print the Final Grid to CSV file
		for(int i = 0; i < N; i++) {

			if(i!=N-1 && i%init.width == init.width-1 && i != 0)
				fprintf(fp, "%f\n", a[i]);
			else if ((i==0) || (i!=N-1 && i%init.width !=init.width-1))
				fprintf(fp, "%f, ", a[i]);
			else fprintf(fp, "%f\n", a[i]);

		}

		cudaFree(d_a);
		cudaFree(d_b);
		cudaFree(d_c);
		fclose(fp);

	}


	//For 3D
	else
	{
		char *filename = (char *)"heatOutput.csv";
		FILE *fp;
		fp = fopen(filename, "w");

		float size = (init.width*init.height*init.depth) * sizeof(float);
		int N = init.width*init.height*init.depth;


		float a[N], b[N], c[N];
		float *d_a, *d_b, *d_c;

		for (int i = 0; i < N; ++i)
		{	
			a[i] = init.default_temp;
			b[i] = 0;
			c[i] = 1;
		}


		//logic for conf file and array integration 3D
		int index = 0;

		for (int i = 0; i < init.heatsource.size(); i=i+6)
		{
			for (int p = init.heatsource[i+1]; p < init.heatsource[i+1]+init.heatsource[i+4]; p++)

			{		
				for (int k = init.heatsource[i+2]; k < init.heatsource[i+2]+init.heatsource[i+5]; k++)

				{
					for (int j = init.heatsource[i]; j < init.heatsource[i]+init.heatsource[i+3]; j++)
					{

						a[p*init.width*init.depth + j + k*init.width] = init.fixed_temp[index];
						c[p*init.width*init.depth + j + k*init.width] = 0;

					}


				}

			}
			index++;
		}


		//initialize array for device 
		cudaMalloc((void **)&d_a, size);
		cudaMalloc((void **)&d_b, size);
		cudaMalloc((void **)&d_c, size);

		//copy to device from host
		cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice);
		cudaMemcpy(d_b, b, size, cudaMemcpyHostToDevice);
		cudaMemcpy(d_c, c, size, cudaMemcpyHostToDevice);

		float *swap;

		//Looping timesteps number of times to get the final grid
		for (int i = 0; i < init.timesteps; i++)
		{
			threedfunc<<<(N + T_P_B-1) / T_P_B, T_P_B>>>(d_a, d_b, d_c, init.k, init.width, init.height, init.depth, N);  //Call kernel function
			cudaDeviceSynchronize();
			swap = d_a;
			d_a = d_b;
			d_b = swap;	

		}

		//copy to host from device
		cudaMemcpy(a, d_a, size, cudaMemcpyDeviceToHost);
		cudaMemcpy(b, d_b, size, cudaMemcpyDeviceToHost);


		//Print the Final Grid to CSV file
		for (int k = 0; k < init.depth; k++)

		{		
			for (int p = 0; p < init.height; p++)

			{
				for (int j = 0; j < init.width; j++)
				{
					if (j == init.width-1)
						fprintf(fp, "%f\n", a[p*init.width*init.depth + j + k*init.width]);
					else fprintf(fp, "%f, ", a[p*init.width*init.depth + j + k*init.width]);

				}


			}
			fprintf(fp, "\n");
		}

		cudaFree(d_a);
		cudaFree(d_b);
		cudaFree(d_c);
		fclose(fp);
	}

	return 0;
}
