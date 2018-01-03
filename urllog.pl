use Irssi;
use DBI;
use URI::Find qw(find_uris);

use strict;
use warnings;
use vars qw($VERSION %IRSSI $dbh);

$VERSION = "0.1";
%IRSSI = (
	authors		=> "John Runyon",
	name		=> "urllog",
	description	=> "Log URLs to MySQL",
	license		=> "public domain",
	url			=> "https://github.com/zonidjan/irssi-scripts",
	contact		=> "https://github.com/zonidjan"
);

our @MAPPING = split(//, 'abcdefghijklmnopqrstuvwxyz0123456789');


our $INURLLOG = 0;

sub urllog { our $INURLLOG; return if $INURLLOG; $INURLLOG = 1; _urllog(@_); $INURLLOG = 0; }
sub _urllog {
	my ($dest, $text, $stripped) = @_;
	return if $stripped =~ /URL:/;

	if (defined($dest->{server}) && defined($dest->{server}->{tag}) && defined($dest->{target}) && $dest->{server}->{tag} && $dest->{target}) {
		my $output = '';
		find_uris($stripped, sub { found_url($dest->{server}->{tag}, $dest->{target}, \$output, $stripped, @_); });
		unless ($output eq '') {
			$dest->{window}->print($text =~ s/%/%%/gr, $dest->{level});
			Irssi::signal_stop();
			if (lc($dest->{target}) eq '#minix') {
				$dest->{window}->command("msg ".$dest->{target}." URL: ".$output);
			} else {
				$dest->{window}->print("URL: ".$output, $dest->{level});
			}
		}
	}
}

sub found_url { # found_url($server_tag, $target_name, \$output_buffer, $full_line, @find_uris_callback_args)
	my ($tag, $target, $output, $line, $uriobj, $url) = @_;
	my $ignorechansre = Irssi::settings_get_str('ignore_chans_re');
	return if
		($ignorechansre && $target =~ m/$ignorechansre/i)
		or $url =~ m!://jfr\.im/u[0-9a-z]+!i
		or $line =~ m!\] has quit \[.*?\Q$url\E.*?\]$!;
	$dbh->do("INSERT INTO urls(server,target,url,fullline) VALUES (?,?,?,?)", undef, $tag, $target, $url, $line);
	$$output .= "http://jfr.im/u".numtoalpha($dbh->last_insert_id((undef) x 4))." ";
}

sub numtoalpha {
	my $num = shift;

	our @MAPPING;
	my $alpha = '';

	while ($num > 0) {
		$alpha = $MAPPING[$num % scalar @MAPPING].$alpha;
		$num = int($num / scalar @MAPPING);
	}
	return $alpha;
}


Irssi::settings_add_str('urllog', 'db_dsn', 'DBI:mysql:urllog');
Irssi::settings_add_str('urllog', 'db_username', 'urllog');
Irssi::settings_add_str('urllog', 'db_password', '');
Irssi::settings_add_str('urllog', 'ignore_chans_re', '');

$dbh = DBI->connect(
    Irssi::settings_get_str('db_dsn'),
    Irssi::settings_get_str('db_username'),
    Irssi::settings_get_str('db_password'),
) or warn $DBI::errstr;


Irssi::signal_add('print text', 'urllog');
Irssi::print('%G>>%n '.$IRSSI{name}.' '.$VERSION.' loaded');


__END__

CREATE DATABASE `urllog`;
CREATE TABLE `urllog`.`urls` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `server` varchar(25) NULL DEFAULT NULL,
  `target` varchar(100) NULL DEFAULT NULL,
  `nick` varchar(40) NULL DEFAULT NULL,
  `url` text NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fullline` text NOT NULL
) CHARSET=utf8;
GRANT INSERT ON `urllog`.`urls` TO 'urllog'@'localhost';
