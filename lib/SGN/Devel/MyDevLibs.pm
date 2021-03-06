package SGN::Devel::MyDevLibs;
use strict;
use warnings FATAL => 'all';
use Class::MOP;
use Try::Tiny;
use Class::Load ':all';

our $VERSION = '0.01';
BEGIN {
    try {
      #Class::MOP::load_class('MyDevLibs');
      load_class('MyDevLibs');
    }
    catch {
        unless ( /Can't locate MyDevLibs\.pm/ ) {
            warn $_;
            die $_;
        }
    }
}

1;

