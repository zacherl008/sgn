#!/usr/bin/env perl


=head1 NAME

GrantPublicMatviews

=head1 SYNOPSIS

mx-run ThisPackageName [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This patch grants permission to webuser on public.matviews

This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

 Isaak Y Tecle<iyt2@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package GrantPublicMatviews;

use Moose;

extends 'CXGN::Metadata::Dbpatch';


has '+description' => ( default => <<'' );
This patch grants permission to webuser on public.matviews

has '+prereq' => (
    default => sub {
        [],
    },
  );

sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    print STDOUT "\nExecuting the SQL commands.\n";



   $self->dbh->do(<<EOSQL);
--do your SQL here
--
grant select, update, insert, delete on public.matviews to web_usr;
grant usage on public.matviews_mv_id_seq to web_usr;


EOSQL

    
print "You're done!\n";

}


####
1; #
####
