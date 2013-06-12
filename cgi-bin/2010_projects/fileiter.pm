## A small package to disguise files as iterators.  Used to
## conserve memory usage and to enforce a streaming approach.

package fileiter;
use strict;
use IO::File;

sub new {
    my $class = shift;
    my ($filename, $predicate) = @_;
    if (! $predicate) { $predicate = sub { return 1; } }
    my $self = bless {file => IO::File->new($filename),
		      predicate => $predicate,
		      nextrow => undef}, $class;
    $self->_read_next();
    return $self;
}


sub close {
    my ($self) = @_;
    $self->{file}->close();
}


sub next {
    my ($self) = @_;
    my $result = $self->{nextrow};
    $self->_read_next();
    return $result;
}


sub hasNext {
    my ($self) = @_;
    return ($self->{nextrow});
}


sub _read_next {
    my ($self) = @_;
    while (1) {
	my $fh = $self->{file};
	$self->{nextrow} = <$fh>;
	if (! $self->{nextrow} || $self->{predicate}->($self->{nextrow})) {
	    last;
	}
    }
}


1;
