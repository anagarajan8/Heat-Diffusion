#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <unistd.h>
#include <mpi.h>


using namespace std;


struct process
{

	double *arraymain; 
	double *arraytemp;
};

struct process my_process;

struct data
{
	int parts;
	int remaining;
};

struct data my_data;


void process_init(int num_grid_points, int num_processes, int my_id, double templeft, double tempright)
{

	//first get the split of array into parts to be executed by different processes

	my_data.parts = num_grid_points / num_processes;
	my_data.remaining = num_grid_points % num_processes;



	if (my_id < my_data.remaining)
	{
		my_data.parts = (my_data.parts) +1;
	}

	if (my_id ==0)
	{
		my_process.arraymain = (double *)malloc(sizeof(double)*(num_grid_points));
	}
	else
	{
		my_process.arraymain = (double *)malloc(sizeof(double)*(my_data.parts));	
	}

	my_process.arraytemp = (double *)malloc(sizeof(double)*(my_data.parts));

	//	printf("Parts %d\n", parts);
	//	memset(my_process.arraytemp, 0, parts);

	for (int i =0; i<my_data.parts; i++)
	{
		my_process.arraytemp[i] = 0;
	}


	//Initial assignment 

	if (my_id == 0)
	{
		my_process.arraymain[0] = templeft;

		for (int i=1; i< num_grid_points; i++)
		{
			my_process.arraymain[i] = 0;
		}
	}


	else if (my_id == num_processes -1)
	{

		for (int i=0; i< my_data.parts -1; i++)
		{
			my_process.arraymain[i] = 0;
		}
		my_process.arraymain[my_data.parts -1] = tempright;
	}



	else
	{

		for (int i=0; i< my_data.parts; i++)
		{
			my_process.arraymain[i] = 0;
		}
	}



}


int init_print(int num_grid_points,int num_processes,int tag, int my_id, MPI_Status status)
{
	int i,j;
	int flux = my_data.parts;
	double *arraybuff = (double *)malloc(sizeof(double)*(my_data.parts));
	//printf("Num processes %d\n", num_processes);

	for (i = my_id +1 ; i< num_processes ; i++)
	{

		if (num_grid_points%num_processes !=0)
		{
			//For case with non divisible arrays 
			if (i < my_data.remaining)
			{	
				MPI_Recv(arraybuff, my_data.parts, MPI_DOUBLE, i, tag, MPI_COMM_WORLD, &status);
				//printf("passed through here 1\n");
				int index = 0;
				for (j = flux; j< (flux+my_data.parts); j++)
				{
					my_process.arraymain[j] = arraybuff[index];
					index++;
				}
				flux = j;
			}

			else {
				MPI_Recv(arraybuff,  my_data.parts -1 , MPI_DOUBLE, i, tag, MPI_COMM_WORLD, &status);
				//printf("passed through here 7\n");
				int index = 0;
				for (j = flux; j< (flux+my_data.parts -1); j++)
				{
					my_process.arraymain[j] = arraybuff[index];
					index++;
				}
				flux = j;
			}
		}

		else {
			MPI_Recv(arraybuff, my_data.parts, MPI_DOUBLE, i, tag, MPI_COMM_WORLD, &status);
			//printf("passed through here 6\n");
			int index = 0;
			for (j = flux; j< (flux+my_data.parts); j++)
			{
				my_process.arraymain[j] = arraybuff[index];
				index++;
			}
			flux = j;
		}

	}
	return i;
}

int main(int argc, char* argv[])
{

	char *filename = (char *)"heat1Doutput.csv";
	FILE *fp;
	fp = fopen(filename, "w");

	int num_processes, my_id;

	MPI_Init(&argc,&argv);
	MPI_Comm_size(MPI_COMM_WORLD,&num_processes);
	MPI_Comm_rank(MPI_COMM_WORLD,&my_id);

	double templeft = atof(argv[1]);
	double tempright = atof(argv[2]);
	int num_grid_points = atoi(argv[3]) + 2;  //since grid points don't include T1 and T2
	int num_time_steps = atoi(argv[4]);

	if(num_processes > num_grid_points)
	{
		num_processes = num_grid_points;
	}

	//printf("Process id is %d\n", my_id);
	//printf("Num processes %d\n", num_processes);
	int k = 1, h = 2, tag = 0;
	double weight = k/(pow(h,2));
	double buff, buff2, buff3,buff4;
	MPI_Status status;

	if (my_id < num_grid_points)  //if Num processes is greater than number of grid points, the extra processes won't do anything
	{

		if (num_processes == 1) //case for np =1
		{
			my_process.arraymain = (double *)malloc(sizeof(double)*(num_grid_points));
			my_process.arraytemp = (double *)malloc(sizeof(double)*(num_grid_points));

			for (int i =0; i<my_data.parts; i++)
			{
				my_process.arraytemp[i] = 0;
			}	

			my_process.arraymain[0] = templeft;

			for (int i=1; i< num_grid_points -1; i++)
			{
				my_process.arraymain[i] = 0;
			}

			my_process.arraymain[num_grid_points -1] = tempright;

			for(int time=0; time<num_time_steps; time++)
			{
				for (int j=1; j<num_grid_points-1; j++)
				{

					my_process.arraytemp[j] = (1-2*weight)*(my_process.arraymain[j]) + weight*(my_process.arraymain[j-1]) + weight*(my_process.arraymain[j+1]);
				}

				for (int i=1; i<num_grid_points-1; i++)
				{
					my_process.arraymain[i] = my_process.arraytemp[i];
				}

			}

			for (int i=1; i<num_grid_points-2; i++)
			{
				fprintf(fp, "%f, ",my_process.arraymain[i]);
				fflush(stdout);
			}
			if (num_grid_points != 2)
			{
			fprintf(fp, "%f\n",my_process.arraymain[num_grid_points-2]);
			}



		}


		else  //for all others
		{

			//Call init function

			process_init(num_grid_points, num_processes, my_id, templeft, tempright);



			//Algorithm
			for(int time=0; time<num_time_steps; time++)
			{

				if (my_id ==0)
				{
					my_process.arraytemp[0] = my_process.arraymain[0];
				}

				else if (my_id == num_processes -1)
				{
					my_process.arraytemp[my_data.parts -1] = my_process.arraymain[my_data.parts -1];
				}


				if (my_id != 0)
				{
					buff2 = my_process.arraymain[0];
				}


				if (my_id != num_processes-1)
				{
					buff = my_process.arraymain[my_data.parts -1];
				}	



				//for the first guy
				if (my_id == 0)
				{
					for (int j=1; j<my_data.parts -1; j++)
					{

						my_process.arraytemp[j] = (1-2*weight)*(my_process.arraymain[j]) + weight*(my_process.arraymain[j-1]) + weight*(my_process.arraymain[j+1]);
					}
					MPI_Recv(&buff4, 1, MPI_DOUBLE, my_id +1, tag, MPI_COMM_WORLD, &status);
					//printf("passed through here 4\n");
					my_process.arraytemp[my_data.parts -1] = (1-2*weight)*(my_process.arraymain[my_data.parts -1]) + weight*(my_process.arraymain[my_data.parts -2]) + weight*buff4;
					//sleep(2);
					MPI_Send(&buff, 1, MPI_DOUBLE, my_id +1 , tag, MPI_COMM_WORLD);
					for (int i=1; i<my_data.parts; i++)
					{
						my_process.arraymain[i] = my_process.arraytemp[i];
					}


					//print logic
					//printf("Num processes %d\n", num_processes);

					if(time == num_time_steps -1)
					{
						//printf("Entered here\n");	
						int num = init_print(num_grid_points,num_processes,tag,my_id,status);
						//printf("num is %d\n", num);
						if (num == num_processes)
						{
							//printf("Entered the condition\n");
							for (int i=1; i<num_grid_points-2; i++)
							{
								fprintf(fp, "%f, ",my_process.arraymain[i]);
								fflush(stdout);
							}
							if (num_grid_points != 2)
							{
							fprintf(fp, "%f\n",my_process.arraymain[num_grid_points-2]);
							}
							break;
						}
					}

				}



				//for the last guy
				else if(my_id == num_processes -1)
				{
					for (int j=1; j<my_data.parts -1; j++)
					{

						my_process.arraytemp[j] = (1-2*weight)*(my_process.arraymain[j]) + weight*(my_process.arraymain[j-1]) + weight*(my_process.arraymain[j+1]);
					}

					MPI_Send(&buff2, 1, MPI_DOUBLE, my_id -1 , tag, MPI_COMM_WORLD);
					MPI_Recv(&buff4, 1, MPI_DOUBLE, my_id -1, tag, MPI_COMM_WORLD, &status);
					//printf("passed through here 5\n");
					my_process.arraytemp[0] = (1-2*weight)*(my_process.arraymain[0]) + weight*(my_process.arraymain[1]) + weight*buff4;
					for (int i=0; i<my_data.parts -1; i++)
					{
						my_process.arraymain[i] = my_process.arraytemp[i];
					}
					//sleep(2);

					if (time == num_time_steps -1)
					{
						MPI_Send(my_process.arraymain, my_data.parts, MPI_DOUBLE, 0 , tag, MPI_COMM_WORLD);
						//printf("Sent\n");
					}

				}



				else 
				{


					if (my_id%2 == 0)
					{

						for (int j=1; j<my_data.parts -1; j++)
						{
							my_process.arraytemp[j] = (1-2*weight)*(my_process.arraymain[j]) + weight*(my_process.arraymain[j-1]) + weight*(my_process.arraymain[j+1]);
						}

						MPI_Recv(&buff3, 1, MPI_DOUBLE, my_id +1, tag, MPI_COMM_WORLD, &status);
						if (my_data.parts != 1)
						{
							my_process.arraytemp[my_data.parts -1] = (1-2*weight)*(my_process.arraymain[my_data.parts -1]) + weight*(my_process.arraymain[my_data.parts -2]) + weight*buff3;
						}
						//printf("Test %lf\n", my_process.arraytemp[my_data.parts -1]);
						MPI_Send(&buff, 1, MPI_DOUBLE, my_id +1 , tag, MPI_COMM_WORLD);
						MPI_Send(&buff2, 1, MPI_DOUBLE, my_id -1 , tag, MPI_COMM_WORLD);
						MPI_Recv(&buff4, 1, MPI_DOUBLE, my_id -1, tag, MPI_COMM_WORLD, &status);
						if (my_data.parts != 1)
						{
							my_process.arraytemp[0] = (1-2*weight)*(my_process.arraymain[0]) + weight*(my_process.arraymain[1]) + weight*buff4;
						}
						if (my_data.parts == 1)
						{
							my_process.arraytemp[0] = (1-2*weight)*(my_process.arraymain[0]) + weight*buff3 + weight*buff4;
						}



					}

					else 
					{

						for (int j=1; j<my_data.parts -1; j++)
						{
							my_process.arraytemp[j] = (1-2*weight)*(my_process.arraymain[j]) + weight*(my_process.arraymain[j-1]) + weight*(my_process.arraymain[j+1]);
						}

						MPI_Send(&buff2, 1, MPI_DOUBLE, my_id -1 , tag, MPI_COMM_WORLD);
						MPI_Recv(&buff3, 1, MPI_DOUBLE, my_id -1, tag, MPI_COMM_WORLD, &status);
						if (my_data.parts != 1)
						{
							my_process.arraytemp[0] = (1-2*weight)*(my_process.arraymain[0]) + weight*(my_process.arraymain[1]) + weight*buff3;
						}
						MPI_Recv(&buff4, 1, MPI_DOUBLE, my_id +1, tag, MPI_COMM_WORLD, &status);
						if (my_data.parts != 1)
						{
							my_process.arraytemp[my_data.parts -1] = (1-2*weight)*(my_process.arraymain[my_data.parts -1]) + weight*(my_process.arraymain[my_data.parts -2]) + weight*buff4;
						}
						if (my_data.parts == 1)
						{
							my_process.arraytemp[0] = (1-2*weight)*(my_process.arraymain[0]) + weight*buff3 + weight*buff4;
						}
						MPI_Send(&buff, 1, MPI_DOUBLE, my_id +1 , tag, MPI_COMM_WORLD);


					}


					for (int i=0; i<my_data.parts; i++)
					{
						my_process.arraymain[i] = my_process.arraytemp[i];
						//printf("%lf ", my_process.arraymain[i]);
					}

					if (time == num_time_steps -1)
					{
						MPI_Send(my_process.arraymain, my_data.parts, MPI_DOUBLE, 0 , tag, MPI_COMM_WORLD);
						//printf("Sent\n");
					} 


				}



			}
		}



	}


	fclose(fp);

	MPI_Finalize();


	return 0;
}


