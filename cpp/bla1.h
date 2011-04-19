#define FOO(x) ((x)*(x))
#define TWOARG(y,z) ((z)+(y))
#define THREEARG(x,y,z) [TWOARG(x,y)/(z)]
// The below should not work.
#define LOOP(x) LOOP(x+x)

THREEARG(XXX,YYY, ZZZ)
TWOARG(FOO(TWOARG(y1,z1)),THREEARG(TWOARG(y2,FOO(z2)), three, divizor))
FOO(TWOARG(THREEARG(FOO(foo),YYY,TWOARG(ZZZ,TTT)),second_arg))

defined FOO

