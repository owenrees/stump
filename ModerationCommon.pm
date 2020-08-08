
package ModerationCommon;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION     = 1.00;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(hash $hashlen
                      readsettings %setting
                      sendmail_start sendmail_finish);
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    @EXPORT_OK   = qw();
}

our $hashlen=32;

sub hash ($) {
    my $r= `echo $_[0] | sha256sum`; $? and die $?;
    $r =~ s/ *\-$//;
    chomp $r;
    return $r;
}

sub sendmail_start () {
    open ::P, "|/usr/sbin/sendmail -odb -oee -oi -t" or die $!;
}
sub sendmail_finish () {
    $?=0; $!=0; close ::P or warn "$! $?";
}

our %setting;

sub readsettingsfile ($) {
    my ($file) = @_;
    open SET, "<$file" or die "$file $!";
    while (<SET>) {
	next unless m/\S/;
	next if m/^\#/;
	m/^([A-Z_]+)\=(.*?)\s*$/ or die;
	$setting{$1}= $2;
    }
}

sub readsettings () {
    readsettingsfile("../../global-settings");
    readsettingsfile("../settings");
}

1;
