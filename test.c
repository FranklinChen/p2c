/* Output from p2c 2.00.Oct.15, the Pascal-to-C translator */
/* From input file "test.p" */


#include <p2c/p2c.h>


#define pi              3.14


/* version = 1.05; (* of testconst.p 2015 Nov 17 */
Static Void callme()
{
  printf("callme pi =%4.2f\n", pi);
}

#undef pi


main(argc, argv)
int argc;
Char *argv[];
{
  PASCAL_MAIN(argc, argv);
  printf("testconst\n");
  callme();
  exit(EXIT_SUCCESS);
}



/* End. */
