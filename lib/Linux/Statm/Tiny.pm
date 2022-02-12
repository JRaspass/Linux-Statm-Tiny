package Linux::Statm::Tiny;

use v5.10;
use strict;
use warnings;

use POSIX ();

use constant page_size =>
    do { no warnings 'numeric'; 0 + `getconf PAGE_SIZE` } || 4096;

my @stats = qw/size resident share text lib data dt/;

sub new {
    my ( $class, $pid ) = @_;

    return bless( { pid => $pid // $$ }, $class )->refresh;
}

sub pid { return shift->{pid} }

sub refresh {
    my $self = shift;

    open my $fh, '<', "/proc/$self->{pid}/statm"
        or die "Unable to open /proc/$self->{pid}/statm: $!";

    @$self{@stats} = split ' ', scalar <$fh>;

    return $self;
}

sub statm { return [ shift->@{@stats} ] }

my %methods = ( rss => 'resident', vsz => 'size' );
@methods{@stats} = @stats;

my %suffixes = (
    ''      => 1,
    _pages  => 1,
    _bytes  => page_size,
    _kb     => page_size / 1024,
    _mb     => page_size / 1048576,
);

while ( my ( $method, $stat ) = each %methods ) {
    while ( my ( $suffix, $factor ) = each %suffixes ) {
        no strict 'refs';

        *{ $method . $suffix } = sub { POSIX::ceil shift->{$stat} * $factor };
    }
}

1;
