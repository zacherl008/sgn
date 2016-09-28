
use strict;

use Test::More;
use lib 't/lib';
use SGN::Test::Fixture;
use Data::Dumper;
use CXGN::Phenotypes::StorePhenotypes;
use CXGN::BreedersToolbox::DeriveTrait;
use SGN::Model::Cvterm;

my $fix = SGN::Test::Fixture->new();

is(ref($fix->config()), "HASH", 'hashref check');

BEGIN {use_ok('CXGN::Trial::TrialCreate');}
BEGIN {use_ok('CXGN::Trial::TrialLayout');}
BEGIN {use_ok('CXGN::Trial::TrialDesign');}
BEGIN {use_ok('CXGN::Trial::TrialLookup');}
ok(my $chado_schema = $fix->bcs_schema);
ok(my $phenome_schema = $fix->phenome_schema);
ok(my $dbh = $fix->dbh);

# create a location for the trial
ok(my $trial_location = "test_location_for_trial_derive_trait");
ok(my $location = $chado_schema->resultset('NaturalDiversity::NdGeolocation')
   ->new({
    description => $trial_location,
	 }));
ok($location->insert());

# create stocks for the trial
ok(my $accession_cvterm = $chado_schema->resultset("Cv::Cvterm")
   ->create_with({
       name   => 'accession',
       cv     => 'stock_type',
}));
my @stock_names;
for (my $i = 1; $i <= 10; $i++) {
    push(@stock_names, "test_stock_for_trial_derive_trait".$i);
}

ok(my $organism = $chado_schema->resultset("Organism::Organism")
   ->find_or_create( {
       genus => 'Test_genus',
       species => 'Test_genus test_species',
}, ));

# create some test stocks
foreach my $stock_name (@stock_names) {
    my $accession_stock = $chado_schema->resultset('Stock::Stock')
	->create({
	    organism_id => $organism->organism_id,
	    name       => $stock_name,
	    uniquename => $stock_name,
	    type_id     => $accession_cvterm->cvterm_id,
		 });
};


ok(my $trial_design = CXGN::Trial::TrialDesign->new(), "create trial design object");
ok($trial_design->set_trial_name("test_trial_derive_trait"), "set trial name");
ok($trial_design->set_stock_list(\@stock_names), "set stock list");
ok($trial_design->set_plot_start_number(1), "set plot start number");
ok($trial_design->set_plot_number_increment(1), "set plot increment");
ok($trial_design->set_number_of_blocks(2), "set block number");
ok($trial_design->set_design_type("RCBD"), "set design type");
ok($trial_design->calculate_design(), "calculate design");
ok(my $design = $trial_design->get_design(), "retrieve design");

ok(my $trial_create = CXGN::Trial::TrialCreate->new({
    chado_schema => $chado_schema,
    phenome_schema => $phenome_schema,
    dbh => $dbh,
    user_name => "johndoe",
    design => $design,	
    program => "test",
    trial_year => "2016",
    trial_description => "test_trial_derive_trait description",
    trial_location => "test_location_for_trial_derive_trait",
    trial_name => "test_trial_derive_trait",
    design_type => "RCBD",
}), "create trial object");

ok(my $trial_id = $trial_create->save_trial(), "save trial");

my $trial = CXGN::Trial->new({ bcs_schema => $fix->bcs_schema(), trial_id => $trial_id });
$trial->create_plant_entities('2');

my %phenotype_metadata;
$phenotype_metadata{'operator'}="janedoe";
$phenotype_metadata{'date'}="2017-02-16_01:10:56";
my $parsed_data = {
            'test_trial_derive_trait1_plant_1' => {
                                'dry matter content|CO:0000092' => [
                                                                     '23',
                                                                     '2017-02-11 11:12:20-0500'
                                                                   ]
                                                   },
           'test_trial_derive_trait1_plant_2' => {
                               'dry matter content|CO:0000092' => [
                                                                    '28',
                                                                    '2017-02-11 11:13:20-0500'
                                                                  ]
                                                  },
          'test_trial_derive_trait2_plant_1' => {
                              'dry matter content|CO:0000092' => [
                                                                   '30',
                                                                   '2017-02-11 11:15:20-0500'
                                                                 ]
                                                 },
             'test_trial_derive_trait2_plant_2' => {
                                 'dry matter content|CO:0000092' => [
                                                                      '33',
                                                                      '2017-02-11 11:16:20-0500'
                                                                    ]
                                                    },
            };

my @plots = ( 'test_trial_derive_trait1_plant_1', 'test_trial_derive_trait1_plant_2', 'test_trial_derive_trait2_plant_1', 'test_trial_derive_trait2_plant_2' );
my @traits = ( 'dry matter content|CO:0000092' );

my $store_phenotypes = CXGN::Phenotypes::StorePhenotypes->new();
my $size = scalar(@plots) * scalar(@traits);
my $stored_phenotype_error_msg = $store_phenotypes->store($fix,$size,\@plots,\@traits, $parsed_data, \%phenotype_metadata, 'plant');
ok(!$stored_phenotype_error_msg, "check that store pheno spreadsheet works");

my $tn = CXGN::Trial->new( { bcs_schema => $fix->bcs_schema(),
				trial_id => $trial_id });
my $traits_assayed  = $tn->get_traits_assayed();
my @traits_assayed_sorted = sort {$a->[0] cmp $b->[0]} @$traits_assayed;
#print STDERR Dumper \@traits_assayed_sorted;
is_deeply(\@traits_assayed_sorted, [
          [
            70741,
            'Dry matter content percentage|CO:0000092'
          ]
        ], "check upload worked");


my $method = 'arithmetic_mean';
my $rounding = 'round';
my $trait_name = 'dry matter content|CO:0000092';
my $derive_trait = CXGN::BreedersToolbox::DeriveTrait->new({bcs_schema=>$fix->bcs_schema, trait_name=>$trait_name, trial_id=>$trial_id, method=>$method, rounding=>$rounding});
my ($info, $plots, $traits, $store_hash) = $derive_trait->generate_plot_phenotypes();
#print STDERR Dumper $info;
my @ordered_info;
foreach (sort @$plots) {
    foreach my $info_n (@$info) {
        if ($_ eq $info_n->{'plot_name'}) {
            push @ordered_info, { 'plot_name'=>$info_n->{'plot_name'}, 'value_to_store'=>$info_n->{'value_to_store'}, 'notes'=>$info_n->{'notes'}, 'output'=>$info_n->{'output'}, 'plant_values'=>$info_n->{'plant_values'} };
        }
    }
}
#print STDERR Dumper \@ordered_info;
is_deeply(\@ordered_info, [
          {
            'plot_name' => 'test_trial_derive_trait1',
            'value_to_store' => '26',
            'notes' => '',
            'output' => '25.5',
            'plant_values' => '[23,28]'
          },
          {
            'plot_name' => 'test_trial_derive_trait2',
            'notes' => '',
            'output' => '31.5',
            'plant_values' => '[30,33]',
            'value_to_store' => '32'
          }
        ], "check returned info array");
#print STDERR Dumper $store_hash;
is_deeply($store_hash, {
          'test_trial_derive_trait1' => {
                                          'dry matter content|CO:0000092' => [
                                                                               '26',
                                                                               ''
                                                                             ]
                                        },
          'test_trial_derive_trait2' => {
                                          'dry matter content|CO:0000092' => [
                                                                               '32',
                                                                               ''
                                                                             ]
                                        }
        }, "check returned values to store");

my $size = scalar(@$plots) * scalar(@$traits);
my %phenotype_metadata;
$phenotype_metadata{'operator'}='janedoe';
$phenotype_metadata{'date'}="2017-02-16_03:10:59";
my $overwrite_values = 1;
my $store_error = CXGN::Phenotypes::StorePhenotypes->store($fix, $size, $plots, $traits, $store_hash, \%phenotype_metadata, 'plot', $overwrite_values );
ok(!$store_error, "check that store pheno spreadsheet works");

my $trait_id = SGN::Model::Cvterm->get_cvterm_row_from_trait_name($fix->bcs_schema, 'dry matter content|CO:0000092')->cvterm_id();
my $all_stock_phenotypes_for_dry_matter_content = $tn->get_stock_phenotypes_for_trait($trait_id);
ok(scalar(@$all_stock_phenotypes_for_dry_matter_content) == 6, "check if num phenotype saved is correct");
my $plant_phenotypes_for_dry_matter_content = $tn->get_stock_phenotypes_for_trait($trait_id, 'plant');
ok(scalar(@$plant_phenotypes_for_dry_matter_content) == 4, "check num phenotype for plant is correct");
my $plot_phenotypes_for_dry_matter_content = $tn->get_stock_phenotypes_for_trait($trait_id, 'plot');
ok(scalar(@$plot_phenotypes_for_dry_matter_content) == 2, "check num phenotype for plant is correct");

done_testing();