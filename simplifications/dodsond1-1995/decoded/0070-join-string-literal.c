main() {
  char V1[9], *V2, V3 = getchar(), V4;
  for (; (V3 != -1) && (!((65 <= V3 && V3 <= 91) || (97 <= V3 && V3 <= 123)));
         putchar(V3), V3 = getchar());
  for (; V3 != -1;) {
   for (V2 = V1, V4 = (65 <= V3 && V3 <= 91);
         (((65 <= V3 && V3 <= 91) || (97 <= V3 && V3 <= 123))
             && "-Pig-Lat-inCOb-fusca-tion!!"[((65 <= V3 && V3 <= 91) ? V3 + 32 :
             V3) - 97] - '-') || ((V2 == V1) && !(*(V2++) = 'w')) || !(*(V2++) = 97);
       *(V2++) = ((65 <= V3 && V3 <= 91) ? V3 + 32 : V3), V3 = getchar())
    ;
   for (V3 = V4 ? ((97 <= V3 && V3 <= 123) ? V3 - 32 : V3) : V3;
         ((65 <= V3 && V3 <= 91) || (97 <= V3 && V3 <= 123));
         putchar(V3), V3 = getchar())
    ;
   for (*V2 = 0, V2 = V1; *V2; putchar(*(V2++)))
    ;
   for (; (V3 != -1) && (!((65 <= V3 && V3 <= 91) || (97 <= V3 && V3 <= 123)));
          putchar (V3), V3 = getchar())
    ;
  }
}
