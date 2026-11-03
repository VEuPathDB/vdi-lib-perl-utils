package VdiPerlUtils;

use strict;
use Exporter;
use File::Copy;
use File::Basename;
use DBI;
use JSON qw( );
our @ISA = 'Exporter';
our @EXPORT = qw(validationError getRefGenome getMetadata getDbh getOrgAbbrev $VALIDATION_ERROR_CODE);

our $VALIDATION_ERROR_CODE = 99;

sub getDbh {
  my $connectString = "DBI:Pg:dbname=$ENV{DB_NAME};host=$ENV{DB_HOST};port=$ENV{DB_PORT}";

  my $dbh = DBI->connect($connectString, $ENV{DB_USER}, $ENV{DB_PASS}) || die "Couldn't connect to database: " . DBI->errstr;

  $dbh->{RaiseError} = 1;
  return $dbh;
}

sub getMetadata {
  my ($metaJsonFile) = @_;

  my $json_text = do {
    open(my $json_fh, "<:encoding(UTF-8)", $metaJsonFile)
      or die("Can't open \"$metaJsonFile\": $!\n");
    local $/;
    <$json_fh>
  };

  my $json = JSON->new;
  return $json->decode($json_text);
}

# return the orgNameForFiles of the genome declared as a dependency
sub getRefGenome {
  my ($metaJsonFile) = @_;

  my $metadata = getMetadata($metaJsonFile);
  my $dependencies = $metadata->{dependencies};

  validationError("Must be exactly one reference genome, not " . scalar(@{ $dependencies || [] }))
      unless ($dependencies && @$dependencies == 1);

  my $genomeIdentifier = $dependencies->[0]->{resourceIdentifier};

  # extract org name from eg PlasmoDB-51_Pfalciparum3D7_Genome
  $genomeIdentifier =~ /^[A-Za-z]+-\d+_(.+)_Genome/ || validationError("Invalid genome resource format: $genomeIdentifier");
  my $orgNameForFiles = $1;
  return $orgNameForFiles;
}

sub getOrgAbbrev {
  my ($dbh, $orgNameForFiles) = @_;

  my $sql = "select internal_abbrev from apidbtuning.organismattributes where name_for_filenames = ?";

  print STDERR "execute query to get org_abbrev\n";
  my $sh = $dbh->prepare($sql);
  $sh->execute($orgNameForFiles);
  my ($orgAbbrev) = $sh->fetchrow_array();
  validationError("Can't find organism $orgNameForFiles") unless $orgAbbrev;
  return $orgAbbrev;
}

sub validationError {
  my ($msg) = @_;

  print STDOUT "$msg\n";
  exit($VALIDATION_ERROR_CODE);
}

1;
