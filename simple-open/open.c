#include <stdio.h>

int main() {
    FILE *file = fopen("/chfs/piyo.txt", "r");

    if (file == NULL) {
        perror("Failed to open /chfs/piyo.txt");
        return 1;
    }

    printf("File opened successfully.\n");

    fclose(file);
    return 0;
}