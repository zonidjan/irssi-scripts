use Irssi;
use vars qw($VERSION %IRSSI);

use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->agent("SMSHi/1.0 ");

$VERSION = "0.1";
%IRSSI = (
	authors		=> "John Runyon",
	name		=> "smshi",
	description	=> "send highlights via sms",
	license		=> 'public domain',
	url			=> 'https://github.com/zonidjan/irssi-scripts',
	contact		=> 'https://github.com/zonidjan'
);

sub msg {
	return unless Irssi::settings_get_bool('smshi_active');

	my ($dest, $text, $stripped) = @_;
#	my ($server, $msg, $nick, $addr, $target) = @_;
	my $server = $dest->{server};
	my $mynick = $server->{nick};
	return unless ($dest->{level} & MSGLEVEL_HILIGHT)
	           or ($dest->{level} & MSGLEVEL_MSGS && index($stripped, $mynick) != -1);
	return if $stripped =~ /<.?\Q$mynick\E>/; # avoid quotes
	return if (!$server->{usermode_away} && Irssi::settings_get_bool('smshi_away_only'));

	my $msg = '';
	for my $c (split //, $stripped) {
		if (ord($c) > 31 && ord($c) < 127) {
			$msg .= $c;
		} else {
			$msg .= '\\x'.sprintf("%02x", ord($c));
		}
	}

	my $chname = $dest->{window}->get_active_name();
	my $sms = $server->{tag}."/".$chname.$msg;

	my $sid = Irssi::settings_get_str('smshi_sid');
	my $token = Irssi::settings_get_str('smshi_token');
	my $from = Irssi::settings_get_str('smshi_from');
	my $to = Irssi::settings_get_str('smshi_to');

	my $url = "https://$sid:$token\@api.twilio.com/2010-04-01/Accounts/$sid/Messages.json";
	my $req = HTTP::Request->new('POST', $url);
	$req->content_type('application/x-www-form-urlencoded');
	$req->content("To=$to&From=$from&Body=$sms");

	my $res = $ua->request($req);
	return unless Irssi::settings_get_bool('smshi_debug');
	if ($res->is_success) {
		print "Good. Sent to $to from $from: $sms";
	} else {
		print $req->url;
		print $req->content;
		print $res->status_line;
		print $res->content;
	}
}

Irssi::settings_add_bool('smshi', 'smshi_active', 0);
Irssi::settings_add_bool('smshi', 'smshi_away_only', 1);
Irssi::settings_add_bool('smshi', 'smshi_debug', 0);
Irssi::settings_add_str('smshi', 'smshi_sid', '');
Irssi::settings_add_str('smshi', 'smshi_token', '');
Irssi::settings_add_str('smshi', 'smshi_from', '');
Irssi::settings_add_str('smshi', 'smshi_to', '');

Irssi::signal_add('print text', 'msg');
Irssi::print('%G>>%n '.$IRSSI{name}.' '.$VERSION.' loaded');
