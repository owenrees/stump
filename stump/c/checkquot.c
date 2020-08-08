#include <stdio.h>
#include <stdlib.h>


main(int argc, char *argv[])
{
  double Qratio;
  int MaxLines;

  FILE *fp;
  char buf[100];
  int i, lines=0, prefixes[256];
  
  /* initialize array of # of prefixes (for each ascii char) */
  for(i=0; i<256; prefixes[i]=0, i++);

  /* set values for quote ratio and max #lines */
  Qratio   = argc>1 ? atof(argv[1]) : .75 ;
  MaxLines = argc>2 ? atoi(argv[2]) : 20 ;
      
  /* open input file or stdin */
  if(argc<=3 || ! ( fp = fopen(argv[3], "r") ) )
    fp = stdin;
  
  /* read input  */
  while( fgets(buf, 99, fp) )
    {
      int i;

      /* get to the first non-white char in line */
      for(i=0; buf[i] < 33 && buf[i] > 0; i++);

      /* string is non-empty */
      if( buf[i] != '\0' )
	{
	  /* increment prefix counter for this prefix */
	  prefixes[ (int) buf[i] ]++;
      
	  /* increment line counter */
	  lines++;
	}
    }
  
    if( lines > MaxLines )
      for( i=0; i<256; i++ )

	/* overquote with char i */
	if( prefixes[i] > Qratio*lines )
	    exit(1);

  /* everytjing seems ok */
  exit(0);
}

