#!perl -T
use strict;
use warnings;
use Test::More;


use Email::Postman;

use MIME::Parser;

my $MAIL_DIR = __FILE__;
$MAIL_DIR =~ s/\/[^\/]+$//;
$MAIL_DIR .= '/emails/';

my $parser = MIME::Parser->new();
## Avoid parser output going to disk
$parser->output_to_core(1);


my $postman = Email::Postman->new();


{
  my $email = $parser->parse_open($MAIL_DIR.'simple.email');
  ok( my @reports = $postman->deliver($email) , "Ok can deliver the email");
  ok( $reports[0]->success() , "Sending this was a success");
  ok( $reports[0]->timestamp() , "Ok got a timestamp");
  ok( ! $reports[0]->failed_at() , "No failure date");
}

{
  my $email = $parser->parse_open($MAIL_DIR.'wrongrecpt.email');
  ok( my @reports = $postman->deliver($email) , "Ok can deliver the email");
  ok( ! $reports[0]->success() , "Sending this was NOT a success");
  diag($reports[0]->message());
  ok( $reports[0]->message() , "And we have a message in this report");
  ok( $reports[0]->failed_at() , "Ok got a failure date");

}

ok(1);
done_testing();
