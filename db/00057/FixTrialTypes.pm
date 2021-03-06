#!/usr/bin/env perl

=head1 NAME

FixTrialTypes.pm

=head1 SYNOPSIS

mx-run FixTrialTypes [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This patch updates the list of possible trial types by removing duplicates, standardizing names, and assigning types to trials where it can be deduced from the trial name.

=head1 AUTHOR

Bryan Ellerbrock<bje24@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package FixTrialTypes;

use Moose;
use Bio::Chado::Schema;
use Try::Tiny;
extends 'CXGN::Metadata::Dbpatch';


has '+description' => ( default => <<'' );
This patch updates the list of possible trial types by removing duplicates, standardizing names, and assigning types to trials where it can be deduced from the trial name.


sub patch {
  my $self=shift;

  print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

  print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

  print STDOUT "\nExecuting the SQL commands.\n";

  my $schema = Bio::Chado::Schema->connect( sub { $self->dbh->clone } );

  my $coderef = sub {
      #get resultsets and cv_id for project types
      my $cv_rs = $schema->resultset("Cv::Cv");
      my $cvterm_rs = $schema->resultset("Cv::Cvterm");
      my $projectprop_rs = $schema->resultset("Project::Projectprop");
      my $db_rs = $schema->resultset("General::Db");
      my $cv_id = $cv_rs->search({name => 'project_type'})->first()->cv_id();
      my $db_id = $db_rs->search({name => 'local'})->first()->db_id();
    #  my $cv_id = $cv_row->cv_id;
      print STDERR "Project types cv id = $cv_id \n";
      print STDERR "Local db id = $db_id \n";

      #update the list of possible trial types by adding/updating to standardized names and removing duplicates
      my $SN_id = &update_or_create_type('%seedling%', 'Seedling Nursery', $cvterm_rs, $cv_id, $db_id);
      my $VR_id = &update_or_create_type('%variety%', 'Variety Release Trial', $cvterm_rs, $cv_id, $db_id);

      my $CE_id = &update_or_create_type('%Clonal Evaluation%', 'Clonal Evaluation', $cvterm_rs, $cv_id, $db_id);
      $CE_id = &find_or_update_type ('clonal', 'Clonal Evaluation', $cvterm_rs, $cv_id);
      &link_to_new_type('clonal', $CE_id, $cv_id, $cvterm_rs, $projectprop_rs);
      &delete_old_type('clonal', $cvterm_rs, $cv_id);

      my $PYT_id = &find_or_update_type ('PYT', 'Preliminary Yield Trial', $cvterm_rs, $cv_id);
      &link_to_new_type('PYT', $PYT_id, $cv_id, $cvterm_rs, $projectprop_rs);
      &link_to_new_type('Preliminary Yield Trials', $PYT_id, $cv_id, $cvterm_rs, $projectprop_rs);
      &delete_old_type('PYT', $cvterm_rs, $cv_id);
      &delete_old_type('Preliminary Yield Trials', $cvterm_rs, $cv_id);

      my $AYT_id = &update_or_create_type('%Advance%', 'Advanced Yield Trial', $cvterm_rs, $cv_id, $db_id);
      $AYT_id = &find_or_update_type ('AYT', 'Advanced Yield Trial', $cvterm_rs, $cv_id);
      &link_to_new_type('AYT', $AYT_id, $cv_id, $cvterm_rs, $projectprop_rs);
      &link_to_new_type('Advanced Yield Trials', $AYT_id, $cv_id, $cvterm_rs, $projectprop_rs);
      &delete_old_type('AYT', $cvterm_rs, $cv_id);
      &delete_old_type('Advanced Yield Trials', $cvterm_rs, $cv_id);

      my $UYT_id = &find_or_update_type ('UYT', 'Uniform Yield Trial', $cvterm_rs, $cv_id);
      &link_to_new_type('UYT', $UYT_id, $cv_id, $cvterm_rs, $projectprop_rs);
      &link_to_new_type('Uniform Yield Trials', $UYT_id, $cv_id, $cvterm_rs, $projectprop_rs);
      &delete_old_type('UYT', $cvterm_rs, $cv_id);
      &delete_old_type('Uniform Yield Trials', $cvterm_rs, $cv_id);

      #delete any types not among the standard 6
      my $all_ids = [$SN_id, $CE_id, $VR_id, $PYT_id, $AYT_id, $UYT_id ];
      my $obsolete_types = $cvterm_rs->search(
        {
          cv_id => $cv_id,
          cvterm_id => { 'not in' => $all_ids}
        });
      my $num_to_delete = $obsolete_types->count;
      print STDERR "Deleting $num_to_delete additional obsolete trial types . . .\n";
      $obsolete_types->delete();
      print STDERR $schema->resultset("Cv::Cvterm")->search({ cv_id => $cv_id })->count() . " standard trial types remaining.\n";

      # get all projects
      my $all_trial_rs = $schema->resultset('Project::Project')->search;

      #loop through all projects and use regex on trial name. if matches type abbrevation, set type.
      while (my $trial = $all_trial_rs->next) {
        my $trial_name = $trial->name;
        for ($trial_name) {
          if (/seedling/i) {
            my $action = &update_or_create_prop($schema, $trial->project_id, $all_ids, $SN_id, 'Seedling Nursery');
            print STDERR "trial $trial_name matched '/seedling/i', $action\n";
          } elsif (/clonal/i) {
            my $action = &update_or_create_prop($schema, $trial->project_id, $all_ids, $CE_id, 'Clonal Evaluation');
            print STDERR "trial $trial_name matched '/clonal/i', $action\n";
          } elsif (/pyt/i) {
            my $action = &update_or_create_prop($schema, $trial->project_id, $all_ids, $PYT_id, 'Preliminary Yield Trial');
            print STDERR "trial $trial_name matched '/pyt/i', $action\n";
          } elsif (/ayt/i) {
            my $action = &update_or_create_prop($schema, $trial->project_id, $all_ids, $AYT_id, 'Advanced Yield Trial');
            print STDERR "trial $trial_name matched '/ayt/i', $action\n";
          } elsif (/uyt/i) {
            my $action = &update_or_create_prop($schema, $trial->project_id, $all_ids, $UYT_id, 'Uniform Yield Trial');
            print STDERR "trial $trial_name matched '/uyt/i', $action\n";
          } elsif (/variety/i) {
            my $action = &update_or_create_prop($schema, $trial->project_id, $all_ids, $VR_id, 'Variety Release Trial');
            print STDERR "trial $trial_name matched '/variety/i', $action\n";
          } else {
            print STDERR "no indication of type found in name of trial $trial_name\n";
          }
        }
      }

          sub update_or_create_type () {
            my ($duplicate_type_name, $new_type_name, $cvterm_rs, $cv_id, $db_id) = @_;
            my ($cvterm_id, $cvterm_name);
            my $duplicate_rs = $cvterm_rs->search(
              {
                cv_id => $cv_id,
                name => { -like => $duplicate_type_name }
              });
            if ($duplicate_rs->first) {
              $cvterm_id = $duplicate_rs->first->cvterm_id;
              $cvterm_name = $duplicate_rs->first->name;
              print STDERR "Updating cvterm with name $cvterm_name and id $cvterm_id to $new_type_name \n";
              $duplicate_rs->first->update( { name => $new_type_name }, );
            } else {
              print STDERR "Adding cvterm with name $new_type_name \n";
              # looks like we may need to ge the local db_id and include it in the creation here while joining dbxref table
              my $dbxref_rs = $schema->resultset("General::Dbxref")->create(
      		      {
                  cvterm => { cv_id => $cv_id, name => $new_type_name, },
                  db_id => $db_id,
                  accession => $new_type_name,
      		      },
              );
              $cvterm_id = $cvterm_rs->search( {name => $new_type_name }, )->first->cvterm_id;
            }
            print STDERR "$new_type_name has been created with id $cvterm_id \n";
            return $cvterm_id;
          }

          sub find_or_update_type () {
            my ($duplicate_type_name, $type_name, $cvterm_rs, $cv_id) = @_;
            my $type_rs = $cvterm_rs->search(
              {
                cv_id => $cv_id,
                name => $type_name
              });
            if (!$type_rs->first) {
              $type_rs = $cvterm_rs->search(
                {
                  cv_id => $cv_id,
                  name => $duplicate_type_name
                });
                print STDERR "Updating cvterm with name $duplicate_type_name to $type_name \n";
              $type_rs->first->update( { name => $type_name }, );
            } else {
              print STDERR "Found exisiting cvterm with name $type_name and id ". $type_rs->first->cvterm_id ."\n";
            }
            return $type_rs->first->cvterm_id;
          }

          sub link_to_new_type () {
            my ($old_type_name, $new_type_id, $cv_id, $cvterm_rs, $projectprop_rs) = @_;
            my $duplicate_rs = $cvterm_rs->search(
              {
                cv_id => $cv_id,
                name => $old_type_name
              });
            if ($duplicate_rs->first) {
              my $duplicate_cvterm_id = $duplicate_rs->first->cvterm_id;
              print STDERR "updating prop rows linked to type ". $duplicate_rs->first->name ." to standardized type with id $new_type_id \n";
              my $trials_to_update_rs = $projectprop_rs->search(
                {
                  type_id => $duplicate_cvterm_id
                });
              if ($trials_to_update_rs->first) {
                foreach my $row ($trials_to_update_rs) {
                  my $trial_id = $row->first->project_id;
                  print STDERR "Updating trial with id $trial_id from old type $old_type_name to new type $new_type_id \n";
                  $row->update( { type_id => $new_type_id } );
                }
              }
            }
          }

          sub delete_old_type () {
            my ($old_type_name, $cvterm_rs, $cv_id) = @_;
            my $old_type_row = $cvterm_rs->search(
              {
                cv_id => $cv_id,
                name => $old_type_name
              });
            if ($old_type_row->first) {
              print STDERR "Deleting obsolete type $old_type_name\n";
              $old_type_row->delete;
            }
          }

          sub update_or_create_prop () {
            my ($schema, $project_id, $all_ids, $type_id, $value) = @_;
            my $exisiting_type = $schema->resultset('Project::Projectprop')->search(
              {
                project_id => $project_id,
                type_id => { -in => $all_ids}
              });
            if ($exisiting_type->first) {
              if ($exisiting_type->first->type_id eq $type_id) {
                return "and type is already set to $value";
              } else {
                my $old_type = $schema->resultset("Cv::Cvterm")->search({ cvterm_id => $exisiting_type->first->type_id() })->first()->name();
                $exisiting_type->first->update( { type_id => $type_id, value => $value }, );
                return "type updated from $old_type to $value";
              }
            } else {
              my $new_type = $schema->resultset('Project::Projectprop')->create(
              {
                project_id => $project_id,
                type_id => $type_id,
                value => $value
              });
              return "type set to $value";
            }
          }
  };

  try {
    $schema->txn_do($coderef);
  } catch {
    die "FixTrialTypes patch failed! " . $_ .  "\n" ;
  };

  print "You're done!\n";

}

####
1; #
####
