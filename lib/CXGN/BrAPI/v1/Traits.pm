package CXGN::BrAPI::v1::Traits;

use Moose;
use Data::Dumper;
use SGN::Model::Cvterm;
use CXGN::Trial;
use CXGN::Trait;
use CXGN::BrAPI::Pagination;
use CXGN::BrAPI::JSONResponse;

has 'bcs_schema' => (
	isa => 'Bio::Chado::Schema',
	is => 'rw',
	required => 1,
);

has 'page_size' => (
	isa => 'Int',
	is => 'rw',
	required => 1,
);

has 'page' => (
	isa => 'Int',
	is => 'rw',
	required => 1,
);

has 'status' => (
	isa => 'ArrayRef[Maybe[HashRef]]',
	is => 'rw',
	required => 1,
);


sub list {
	my $self = shift;
	my $page_size = $self->page_size;
	my $page = $self->page;
	my $status = $self->status;

	my $limit = $page_size;
	my $offset = $page*$page_size;
	my $total_count = 0;
	my @data;
	my $q = "SELECT cvterm.cvterm_id, cvterm.name, cvterm.definition, db.name, db.db_id, dbxref.accession, count(cvterm.cvterm_id) OVER() AS full_count FROM cvterm JOIN dbxref USING(dbxref_id) JOIN db using(db_id) JOIN cvterm_relationship as rel on (rel.subject_id=cvterm.cvterm_id) JOIN cvterm as reltype on (rel.type_id=reltype.cvterm_id) WHERE reltype.name='VARIABLE_OF' ORDER BY cvterm.name ASC LIMIT $limit OFFSET $offset;";
	my $sth = $self->bcs_schema->storage->dbh->prepare($q);
	$sth->execute();
	while (my ($cvterm_id, $cvterm_name, $cvterm_definition, $db_name, $db_id, $accession, $count) = $sth->fetchrow_array()) {
		$total_count = $count;
		my $trait = CXGN::Trait->new({bcs_schema=>$self->bcs_schema, cvterm_id=>$cvterm_id});
		push @data, {
			traitDbId => $cvterm_id,
			traitId => $db_name.":".$accession,
			name => $cvterm_name,
			description => $cvterm_definition,
			observationVariables => [
				$cvterm_name."|".$db_name.":".$accession
			],
			defaultValue => $trait->default_value,
		};
	}

	my %result = (data => \@data);
	my @data_files;
	my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
	return CXGN::BrAPI::JSONResponse->return_success(\%result, $pagination, \@data_files, $status, 'Traits list result constructed');
}

sub detail {
	my $self = shift;
	my $cvterm_id = shift;
	my $page_size = $self->page_size;
	my $page = $self->page;
	my $status = $self->status;

	my $total_count = 0;
	my $trait = CXGN::Trait->new({bcs_schema=>$self->bcs_schema, cvterm_id=>$cvterm_id});
	if ($trait->name){
		$total_count = 1;
	}
	my %result = (
		traitDbId => $trait->cvterm_id,
		traitId => $trait->term,
		name => $trait->name,
		description => $trait->definition,
		observationVariables => [
			$trait->display_name
		],
		defaultValue => $trait->default_value,
	);
	my @data_files;
	my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
	return CXGN::BrAPI::JSONResponse->return_success(\%result, $pagination, \@data_files, $status, 'Trait detail result constructed');
}

1;
