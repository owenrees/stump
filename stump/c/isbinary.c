/*
    isbinary.c

  This program reads an article from standard input and checks if it 
  is a uuencoded binary. If it is, exits with exit code 0, otherwise 
  retcode = 1.

  GNU Copyright applies. ichudov@algebra.com

*/

#include <stdio.h>

#define MAX_BUF 16384
#define MAX_BINARY_LINES 10

char buf[MAX_BUF];

int main( int argc, char *argv[] )
{
  int nBinLines = 0, maxNBinLines = 0;

  /* skip header */
  while( fgets( buf, MAX_BUF, stdin ) ) 
    if( strlen( buf ) <= 1 ) break;

  while( fgets( buf, MAX_BUF, stdin ) ) {
    if( strlen( buf ) > 45 /* buf long enough */
        && (!(strchr( buf, ' ' ) || strchr( buf, '\t' )) /* no spaces */
           || (buf[0] == 'M') )  /* some uuencoded stuff begins with 'M' */
      ) { /* likely a uuencoded line */
      nBinLines++;
      maxNBinLines = (nBinLines > maxNBinLines) ? nBinLines : maxNBinLines;
    } else nBinLines = 0;
  }

  /* more than 10 consecutive 45 char lines with no blank - likely binary */
  return( maxNBinLines < MAX_BINARY_LINES );
}
