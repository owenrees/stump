#!/usr/bin/perl -n

unless (m/^$/..0) {
    $skip= 0 unless m/^[ \t]/;
    $skip= 1 if m/^received\s*\:/i;
    next if $skip;
    s, %OURUSER% \+ [-+/0-9a-z]* \@ (\Q%DOMAIN%\E | \Q%SLIMYDOMAIN%\E) \b
		 ,%OURUSER%+?\@$1,igx;
}

s/^/> /;
print or die $!;
