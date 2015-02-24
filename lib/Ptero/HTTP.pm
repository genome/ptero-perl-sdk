package Ptero::HTTP;

use strict;
use warnings FATAL => 'all';

use Data::Dump qw(pp);
use HTTP::Request qw();
use JSON qw();
use LWP::UserAgent::Determined qw();
use Log::Log4perl qw();
use Params::Validate qw(validate_pos :types);

use Exporter 'import';
our @EXPORT_OK = qw(make_request_and_decode_repsonse);

Log::Log4perl->easy_init($Log::Log4perl::DEBUG);
my $logger = Log::Log4perl->get_logger();


my @RAW_DELAYS = (5, 5, 10, 20, 40, 80, 160);
for (1..20) {
    push @RAW_DELAYS, 320;
}
# This will spread out the distribution of requests over time.
my @RETRY_DELAYS = map {$_ + _random_int(4)} @RAW_DELAYS;

my $_json_codec = JSON->new;
my $_user_agent = _get_user_agent();

sub decode_response {
    my ($response) = validate_pos(@_, 1);

    if ($response->is_success) {
        return $_json_codec->decode(
            $response->decoded_content(raise_error => 1));
    } else {
        Carp::confess(sprintf("Can't extract content from failed response: %s",
                pp($response)));
    }
}

sub make_request {
    my ($method, $url, $data) = validate_pos(@_, 1, 1, 0);

    my @request_args = ($method, $url,[
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
    ]);
    if (defined $data) {
        push @request_args, $_json_codec->encode($data);
    }

    my $req = HTTP::Request->new(@request_args);
    my $response = $_user_agent->request($req);

    $logger->info(sprintf("Got %d from %s  %s", $response->code,
            uc($method), $url));
    $logger->debug("    Request \n" . indent($req->as_string, 4));
    $logger->debug("    Response: \n" . indent($response->as_string, 4));

    return $response
}

sub indent {
    my ($string, $num_spaces) = @_;
    return join("\n", map {" "x$num_spaces . $_} split(/\n/,$string));
}

sub get   { make_request('GET',   @_) }
sub patch { make_request('PATCH', @_) }
sub post  { make_request('POST',  @_) }

sub make_request_and_decode_repsonse {
    my %p = Params::Validate::validate(@_, {
            method => { regex => qr/^(GET|PATCH|POST)$/ },
            url => { type => SCALAR },
            valid_response_codes => { type => ARRAYREF, default => [200] },
    });

    my $response = make_request($p{'method'}, $p{'url'});
    unless (grep {$response->code == $_} @{$p{valid_response_codes}}) {
        die sprintf "Failed to %s json resource %s\n"
            ."Status code (%s)\n"
            ."Valid status codes (%s)"
            ."Response:\n%s\n",
            $p{'method'},
            $p{url}, $response->code,
            join(', ', @{$p{valid_response_codes}}),
            $response->content;
    }

    return decode_response($response);
}

sub _random_int {
    my $magnitude = shift;
    my $int_mag = int($magnitude);
    return int(rand(2*$int_mag+1)) - $int_mag;
}

sub _get_user_agent {
    my $_timing = join(',', @RETRY_DELAYS);

    my $agent = LWP::UserAgent::Determined->new;
    $agent->timing($_timing);
    $agent->after_determined_callback(\&__after_determined_callback);

    return $agent;
}

sub __after_determined_callback {
    my ($user_agent, $timing, $pause, $codes_to_determinate, $args, $resp) = @_;

    if(defined($codes_to_determinate->{$resp->code})) {
        $logger->warn("Server responded to request (", $args->[0]->url, ") with code (",
            $resp->code, ").");
        if ($pause) {
            $logger->warn("Retrying request in ", $pause, " seconds.");
        }
    }
}

1;
