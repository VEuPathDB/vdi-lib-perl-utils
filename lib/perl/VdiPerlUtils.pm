package VdiPerlUtils;

use strict;
use Exporter;
use File::Copy;
use File::Basename;
use DBI;
use JSON qw( );
our @ISA = 'Exporter';
our @EXPORT = qw(validationError getRefGenome $VALIDATION_ERROR_CODE);

our $VALIDATION_ERROR_CODE = 99;

# return the orgNameForFiles of the genome declared as a dependency
sub getRefGenome {
  my ($metaJsonFile) = @_;

  my $json_text = do {
    open(my $json_fh, "<:encoding(UTF-8)", $metaJsonFile)
      or die("Can't open \"$metaJsonFile\": $!\n");
    local $/;
    <$json_fh>
  };

  my $json = JSON->new;
  my $metadata = $json->decode($json_text);

  my $dependencies = $metadata->{dependencies};

  validationError("More than one reference genome") if (@$dependencies != 1);

  my $genomeIdentifier = $dependencies->[0]->{resourceIdentifier};

  # extract org name from eg PlasmoDB-51_Pfalciparum3D7_Genome
  $genomeIdentifier =~ /^[A-Za-z]+-\d+_(.+)_Genome/ || validationError("Invalid genome resource format: $genomeIdentifier");
  my $orgNameForFiles = $1;
  return $orgNameForFiles;
}


sub validationError {
  my ($msg) = @_;

  print STDOUT "$msg\n";
  exit($VALIDATION_ERROR_CODE);
}

1;
