#!perl -T
use Test::More;


use Email::Postman;

use MIME::Parser;

my $MAIL_DIR = __FILE__;
$MAIL_DIR =~ s/\/[^\/]+$//;
$MAIL_DIR .= '/emails/';

my $parser = MIME::Parser->new();
## Avoid parser output going to disk
$parser->output_to_core(1);

$email = $parser->parse_open($MAIL_DIR.'simple.email');

my $postman = Email::Postman->new();
ok( my @reports = $postman->deliver($email) , "Ok can deliver the email");

ok(1);
done_testing();
