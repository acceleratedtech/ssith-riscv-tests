
#include <stdlib.h>
#include <stdio.h>
#include <util.h>

int main(int argc, const char* argv[])
{
	char buf [80];

	printf("Hello World!\n");
	printf("Enter text followed by return and it will be echo'd back to you:!\n");

	while (1) {	
	  read_input(buf, 80);
	  printf(buf);
	  printf("\n");
	}
	return 0;
}

