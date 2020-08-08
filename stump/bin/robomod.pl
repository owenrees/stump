#!/usr/bin/perl
#
# Collection of common functions
#

$MNG_ROOT = $ENV{'MNG_ROOT'} || die "Root dir for moderation not specified";

###################################################################### checkAck
# checks if poster needs ack
sub nameIsInListRegexp {
  local( $listName ) = pop( @_ );
  local( $address ) = pop( @_ );

  local( $item );

  $Result = 0;

  open( LIST, "$MNG_ROOT/data/$listName" );

  while( $item = <LIST> ) {

    chop $item;

    next if $item =~ /^ *$/;

    if( eval { $address =~ /$item/i; } ) {
      $Result = $item;
    }
  }

  close( LIST );

  return $Result;
}

sub nameIsInListExactly {
  local( $listName ) = pop( @_ );
  local( $address ) = pop( @_ );

  local( $item );

  $Result = 0;

  open( LIST, "$MNG_ROOT/data/$listName" );

  while( $item = <LIST> ) {

    chop $item;

    next if $item =~ /^ *$/;

    if( "\L$address" eq "\L$item" ) {
      $Result = $item;
    }
  }

  close( LIST );

  return $Result;
}

sub logAction {
  my $msg = pop( @_ );

  print STDERR $msg . "\n";
}


######################################################################
# Setting variables

if( defined( $ENV{'STUMP_PARANOID_PGP'} ) ) {
  $paranoid_pgp = $ENV{'STUMP_PARANOID_PGP'}  eq "YES";
} else {
   $paranoid_pgp = 0;
}

1;
