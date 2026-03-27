#include <stdio.h>

int main(){
	float tab[] = {5277093, 2954133, 1600839, 1517593, 1541276};
	for (int i = 0; i < 5; i++){
		tab[i] = 5277093 / tab[i];
	}
	for (int i = 0; i < 5; i++){
		printf("%f\n", tab[i]);
	}
	return 0;
}
