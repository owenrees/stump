our $hashlen=32;

sub hash ($) {
    my $r= `echo $_[0] | sha256sum`; $? and die $?;
    $r =~ s/ *\-$//;
    chomp $r;
    return $r;
}


1;
