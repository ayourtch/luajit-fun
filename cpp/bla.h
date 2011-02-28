/\
*
*/ # /*
*/ defi\
ne FO\
O 10\
20 /* 
*/ 23

#define testing sometest

%: define BAR testing

#define SUBST1 subst1
#define SUBSTx subst2
#define SUBST2 SUBSTx

#define FOO1(x,y) x y
//#define FOO1(x,y,z) x y z
#define BAZ() FOO1(1,2)

SUBST1
 SUBST2

    SUBST1  SUBST2
  SUBST1    SUBST2 

FOO

BAR
BAR()
BAZ
BAZ()

SUBST start
#ifdef SUBST1
  SUBST1 defined
#else
  SUBST1 undefined
#endif
SUBST end

// FOO1(asd dsd, second, third)
// FOO1(asd dsd, second)

