#include <stdio.h>

int F1(int V1, int V2) {
  int V3, V4;

  V4 = 1;
  V3 = V4;

  int V5;

  if (V3 * V3 <= V1) {
    if (V1 % V3) {
      V4 = V4;
      V5 = V4;
    } else {
      V4 = V3;
      V5 = V4;
    }
  } else {
    if (V2 + 1) {
      if (V4 < 2) {
        V1 && F1(V2, 0);
      } else {
        F1(V4, V2);
      }
      printf("%c", V2 ? 10 : 32 << !V1);
      V5 = V1 -= V4 * !!V1;
    } else {
      F1(V4, V1 / V4);
      V5 = 0;
    }
  }

  for (;V5;) {
    V3++;

    if (V3 * V3 <= V1) {
      if (V1 % V3) {
        V4 = V4;
        V5 = V4;
      } else {
        V4 = V3;
        V5 = V4;
      }
    } else {
      if (V2 + 1) {
        if (V4 < 2) {
          V1 && F1(V2, 0);
        } else {
          F1(V4, V2);
        }
        printf("%c", V2 ? 10 : 32 << !V1);
        V5 = V1 -= V4 * !!V1;
      } else {
        F1(V4, V1 / V4);
        V5 = 0;
      }
    }
  }

  return 0;
}

int main(int V6, char **V7) {
  F1(V5 - 1, -1);
}
