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
#ifndef SUBST2
  SUBST2 undefined
#else
  SUBST2 defined
#endif
SUBST end

// FOO1(asd dsd, second, third)
// FOO1(asd dsd, second)

#if (1-0)*100/(2+33) % 10
 if_has_fired
#else
 else_has_fired
#endif

#define ASDF asdf
#define FOO(x) ((x)*(x))
#define TWOARG(y,z) ((z)+(y))

#if defined ASDF
  ASDF defined!
#else
  ASDF not defined!
#endif
FOO(x)
TWOARG(FOO(TWOARG(y1,z1)),TWOARG(y2,z2))
