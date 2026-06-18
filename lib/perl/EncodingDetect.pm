package EncodingDetect;

use strict;
use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw(detectFileEncoding);

# ---------------------------------------------------------------------------
# Mirrors study-wrangler's detect_file_encoding() in R: check for UTF-16 via
# BOM or alternating-NUL pattern on a small sample first, then probe for valid
# UTF-8; if invalid, distinguish Windows-1252 (bytes 0x80-0x9F present) from
# ISO-8859-1 (those bytes are control codes).

sub detectFileEncoding {
  my ($path) = @_;
  open(my $fh, '<:raw', $path) or die "Cannot open '$path': $!";
  my $bytes = do { local $/; <$fh> };
  close($fh);

  # Sample ~100 lines from the start for UTF-16 detection
  my $sample = substr($bytes, 0, 4000);

  if (length($sample) >= 2) {
    return 'UTF-16LE' if substr($sample, 0, 2) eq "\xFF\xFE";
    return 'UTF-16BE' if substr($sample, 0, 2) eq "\xFE\xFF";
  }

  # No BOM: count NULs at alternating positions. For ASCII-heavy UTF-16LE the
  # high byte sits at odd offsets (1,3,5,...); for UTF-16BE at even (0,2,4,...).
  if (length($sample) >= 4) {
    my @b        = unpack('C*', $sample);
    my $pairs    = int(@b / 2);
    my $even_nuls = grep { $b[$_] == 0 } grep { !($_ % 2) } 0..$#b;
    my $odd_nuls  = grep { $b[$_] == 0 } grep {   $_ % 2  } 0..$#b;
    my $threshold = 0.4 * $pairs;
    return 'UTF-16BE' if $even_nuls >= $threshold && $odd_nuls  < $threshold;
    return 'UTF-16LE' if $odd_nuls  >= $threshold && $even_nuls < $threshold;
  }

  my $test = $bytes;
  return 'UTF-8' if utf8::decode($test);
  return ($bytes =~ /[\x80-\x9F]/) ? 'Windows-1252' : 'ISO-8859-1';
}
