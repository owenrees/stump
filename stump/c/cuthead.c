/* cuthead.c

   This program simply ignires first line, or if argc == 2, first
   lines specified by argv[1].

   I am not responsible for any damages, GNU copyright applies.
*/

#include <stdio.h>

#define MAX_BUF 4096

const char * Usage = "Usage: %s [number-of-lines]\n";

char buf[MAX_BUF];

int main( int argc, char **argv )
{
  int first;

  if( argc == 1 ) first = 1;
  else if( argc == 2 ) {
    if( (first = atoi( argv[1] ) ) <= 0 ) {
      fprintf( stderr, Usage, argv[0] );
      exit( 1 );
    }
  } else {
    fprintf( stderr, Usage, argv[0] );
    exit( 1 );
  }

  while( fgets( buf, sizeof( buf ), stdin ) ) {
    if( first )
      first--;
    else
      fputs( buf, stdout );
  }
}
