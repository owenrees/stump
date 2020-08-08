#!/usr/bin/perl

$MNG_ROOT=$ENV{'MNG_ROOT'} 
	|| die "Newsgroup Root Directory (\$MNG_ROOT) Not Defined!";


sub start {

  my $robomod_pl = "$MNG_ROOT/bin/robomod.pl";
  require "$robomod_pl" if( -f $robomod_pl && -r $robomod_pl );

  my $script = shift @ARGV
	|| die "Syntax: $0 script-name [parameters]\n";
  my $script_file = "$MNG_ROOT/bin/$script";
  if( -f $script_file ) {
    require $script_file;
  } else {
    die "ERROR: $script_file not found and could not be executed.";
  }
}

start;
