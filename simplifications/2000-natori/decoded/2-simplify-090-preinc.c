#include <math.h>
#include <stdio.h>
double l;
int main(int V1, char **V2, char **V3) {
  char V4;

  int V5 = V1;
  V1 = V1 - 1;
  if (V5 + 1 && V5 + 4) {
    main(V1, -8, V1);
  }

  if (V1 && V2) {
    main(-1, ++V2, V3);
    l = (int)(V2 + 1) / (1 - (int)V3 * 2 - (int)V3 * (int)V3);
    V4 = "ab"[((l * l) > 3) && (((trunc((2 % 3) / 4) - 2) + (l / 2)) < 1)];
  } else {
    V4 = 'c';
  }

  return printf("%c\n", V4);
}