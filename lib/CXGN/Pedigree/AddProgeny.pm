package CXGN::Pedigree::AddProgeny;

=head1 NAME

CXGN::Pedigree::AddProgeny - a module to add cross experiments.

=head1 USAGE

 my $progeny_add = CXGN::Pedigree::AddProgeny->new({ schema => $schema, cross_name => $cross_name, progeny_names => \@progeny_names} );
 my $progeny_validated = $progeny_add->validate_progeny(); #is true when the cross name exists and the progeny names to be assigned are valid.
 $progeny_add->add_progeny();

=head1 DESCRIPTION

Adds progeny to a cross and creates corresponding new stocks of type accession. The cross must already exist in the database, and the verify function does this check.   This module is intended to be used in independent loading scripts and interactive dialogs.

=head1 AUTHORS

 Jeremy D. Edwards (jde22@cornell.edu)

=cut

use Moose;
use MooseX::FollowPBP;
use Moose::Util::TypeConstraints;
use Try::Tiny;
use CXGN::Stock::StockLookup;
use CXGN::Location::LocationLookup;
use CXGN::BreedersToolbox::Projects;

has 'schema' => (
		 is       => 'rw',
		 isa      => 'DBIx::Class::Schema',
		 predicate => 'has_schema',
		 required => 1,
		);

has 'cross_name' => (isa =>'Str', is => 'rw', predicate => 'has_cross_name', required => 1,);
has 'progeny_names' => (isa =>'ArrayRef[Str]', is => 'rw', predicate => 'has_progeny_names', required => 1,);


sub add_progeny {
  my $self = shift;
  my $schema = $self->get_schema();
  my @progeny_names = $self->get_progeny_names();
  my $cross_stock;
  my $female_parent_cvterm = $schema->resultset("Cv::Cvterm")
    ->create_with( { name   => 'a female parent of',
		     cv     => 'stock relationship',
		     db     => 'null',
		     dbxref => 'a female parent of',
		   });
  my $male_parent_cvterm = $schema->resultset("Cv::Cvterm")
    ->create_with({ name   => 'a male parent of',
		    cv     => 'stock relationship',
		    db     => 'null',
		    dbxref => 'a male parent of',
		  });
   my $progeny_cvterm = $schema->resultset("Cv::Cvterm")
     ->create_with({ name   => 'a progeny of',
   		    cv     => 'stock relationship',
   		    db     => 'null',
   		    dbxref => 'a progeny of',
   		  });
  my $cross_name_cvterm = $schema->resultset("Cv::Cvterm")->find(
      { name   => 'cross_name',
    });


  #Get stock of type cross matching cross name
  $cross_stock = $self->_get_cross($self->get_cross_name());
  if (!$cross_stock) {
    print STDERR "Cross could not be found\n";
    return;
  }




  #Get cross experiment



  #skip Get cross project



  #add progeny to population




  #Get cross type
  #get parental accessions
  # $cross_stock
  #   ->find_or_create_related('stock_relationship_objects', {
  # 							    type_id => $female_parent_cvterm->cvterm_id(),
  # 							    object_id => $cross_stock->stock_id(),
  # 							    subject_id => $female_parent->stock_id(),
  # 							   } );

  return 1;
}


sub _get_cross {
  my $self = shift;
  my $cross_name = shift;
  my $schema = $self->get_schema();
  my $stock_lookup = CXGN::Stock::StockLookup->new(schema => $schema);
  my $stock;
  my $cross_cvterm = $schema->resultset("Cv::Cvterm")
    ->create_with({
		   name   => 'cross',
		   cv     => 'stock type',
		   db     => 'null',
		   dbxref => 'accession',
		  });
  $stock_lookup->set_stock_name($cross_name);
  $stock = $stock_lookup->get_stock_exact();

  if (!$stock) {
    print STDERR "Cross name does not exist\\n";
    return;
  }

  if ($stock->type_id() != $cross_cvterm->cvterm_id()) {
    print STDERR "Cross name is not a stock of type cross\n";
    return;
  }

  return $stock;
}

#######
1;
#######