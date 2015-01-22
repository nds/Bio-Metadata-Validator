#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp;
use File::Slurp qw( read_file );

use Bio::Metadata::Config;

use_ok('Bio::Metadata::Manifest');

my $m;
throws_ok { $m = Bio::Metadata::Manifest->new }
  qr/Attribute \(config\) is required/, 'exception when instantiating without a config';

my $config = Bio::Metadata::Config->new( config_file => 't/data/03_manifest.conf' );

lives_ok { $m = Bio::Metadata::Manifest->new( config => $config ) }
   'no exception when instantiating with a config';

throws_ok { $m->md5('xxxxxxxxxxx') }
  qr/Attribute \(md5\) does not pass the type constraint/, 'exception when setting an invalid MD5';
lives_ok  { $m->md5('6df23dc03f9b54cc38a0fc1483df6e21') } 'no error when setting a valid MD5';

throws_ok { $m->uuid('xxxxxxxxxxx') }
  qr/Attribute \(uuid\) does not pass the type constraint/, 'exception when setting an invalid uuid';
lives_ok  { $m->uuid('4162F712-1DD2-11B2-B17E-C09EFE1DC403') } 'no error when setting a valid uuid';

my $expected_field_defs = [
  { name => 'one', type => 'Bool', description => 'Testing description' },
  { name => 'two', type => 'Str' },
];
my $expected_field_names = [ qw( one two ) ];

is_deeply( $m->fields,      $expected_field_defs,  'got expected fields from config via manifest' );
is_deeply( $m->field_names, $expected_field_names, 'got expected field names from config via manifest' );

$m->add_rows( [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] );
$m->set_invalid_row( 2, [ 5, 6, '[error message]' ] );

is( $m->row_count, 3, 'starting with 3 rows' );
is( $m->invalid_row_count, 1, 'starting with one invalid row' );
ok( $m->is_invalid, '"is_invalid" correctly shows false' );

my $all_fh = File::Temp->new;
$all_fh->close;

diag 'writing all rows to ' . $all_fh->filename;

$m->write_csv( $all_fh->filename );

my $file_contents = read_file( $all_fh->filename );

my $expected_contents = <<EOF;
one,two
1,2
3,4
5,6,[error message]
EOF

is( $file_contents, $expected_contents, 'output file is correct' );

my $invalid_fh = File::Temp->new;
$invalid_fh->close;

diag 'writing invalid rows to ' . $invalid_fh->filename;

$m->write_csv( $invalid_fh->filename, 1 );

$file_contents = read_file( $invalid_fh->filename );

$expected_contents = <<EOF;
one,two
5,6,[error message]
EOF

is( $file_contents, $expected_contents, 'output file is correct' );

$m->reset;

is( $m->row_count, 3, 'still 3 rows' );
is( $m->has_invalid_rows, 0, 'no invalid rows' );
is( $m->is_invalid, 0, '"is_invalid" correctly shows false' );

done_testing();
