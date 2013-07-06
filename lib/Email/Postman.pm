package Email::Postman;
use Carp;
use Moose;
use Log::Log4perl qw/:easy/;

use Email::Abstract;
use Email::Address;
use Net::DNS;
use Net::SMTP;

use Email::Postman::Report;

unless( Log::Log4perl->initialized() ){
  Log::Log4perl->easy_init($DEBUG);
}

my $LOGGER = Log::Log4perl->get_logger();

has 'dns_resolv' => ( is => 'ro' , isa => 'Net::DNS::Resolver', required => 1, lazy => 1 , builder => '_build_dns_resolv' );

## The sending domain.
has 'hello' => ( is => 'ro' , isa => 'Str', required => 1, default => 'localdomain');

## The sender.
has 'from' => ( is => 'ro' , isa => 'Str', required => 1, default => 'localuser@localdomain');

## Just a flag.
has 'debug' => ( is => 'rw' , isa => 'Bool', required => 1 , default => 0);

sub _build_dns_resolv{
  my ($self) = @_;
  return Net::DNS::Resolver->new();
}


=head1 NAME

Email::Postman - Send multirecipient emails to the world.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

sub deliver{
  my ($self, $email) = @_;

  ## Make sure we have an email abstract.
  unless( ( ref($email) // '' ) eq 'Email::Abstract' ){
    $email = Email::Abstract->new($email);
  }
  ## We have an email abstract.
  ## Make sure bccs are really blind.
  my @bcc = $email->get_header('bcc');
  $email->set_header('bcc');

  my @To = $email->get_header('To');
  my @cc = $email->get_header('cc');


  my @reports = ();

  ## Do the to
  foreach my $to ( @To ){
    push @reports , $self->_deliver_email_to($email, $to);
  }

  ## Do the cc
  foreach my $to ( @cc ){
    push @reports , $self->_deliver_email_to($email, $to);
  }

  ## Do the Bcc
  foreach my $to ( @bcc ){
    ## Tell the bcc he has been bcc'ed
    $email->set_header('bcc' => $to );
    push @reports , $self->_deliver_email_to($email, $to);
  }
  ## Reset the bcc to what they were.
  $email->set_header('bcc', @bcc);

  return @reports;
}


## Deliver to one and ONLY one recipient and return a report.
sub _deliver_email_to{
  my ($self, $email , $to) = @_;
  $LOGGER->debug("Delivering to '$to'");
  my @recpts = Email::Address->parse($to);
  if( @recpts != 1 ){ confess("More than one recipient in $to"); }

  my $recpt = $recpts[0];

  my $res = $self->dns_resolv();

  my $report = Email::Postman::Report->new({ about_email => $recpt->address() });

  my @mx = $res->mx($recpt->host());
  unless( @mx ){
    $report->set_failure_message("No MX host could be found for host '".$recpt->host()."'");
    return $report;
  }

  ## Try each mx and return on the first success.
  foreach my $mx ( @mx ){
    $report->reset();
    my $exchange = $mx->exchange();
    ## Works in taint mode.
    ( $exchange ) = ( $exchange =~ m/(.+)/ );
    $LOGGER->debug("Giving a go to ".$exchange);

    my $smtp = Net::SMTP->new($exchange,
                              Hello => $self->hello(),
                              Debug => $self->debug(),
                              Timeout => 5);
    unless( $smtp ){
      $report->set_failure_message("No SMTP for exchange '$exchange'");
      $LOGGER->warn("Cannot build smtp for ".$exchange);
      ## And jump to next. This MX could be down.
      next;
    }

    unless( $smtp->mail($self->from()) ){
      $report->set_failure_message("mail failure for '".$self->from."' : $!");
      ## We trust ANY MX about this thing,
      ## so we can just return the report. Same thing for any failures below.
      return $report;
    }
    unless( $smtp->recipient($recpt->address()) ){
      $report->set_failure_message("recipient failure for '".$recpt->address()."' : $!");
      return $report;
    }
    unless( $smtp->data($email->as_string()) ){
      $report->set_failure_message("data failure: $!");
      return $report;
    }
    unless( $smtp->dataend() ){
      $report->set_failure_message("dataend failure: $!");
      return $report;
    }

    unless( $smtp->quit() ){
      $report->set_failure_message("quit failure: $!");
      return $report;
    }

    $report->success(1);
    $report->message('Success');
    ## No need to try anything else. That is a success!
    return $report;
  } ## End of MX loop.

  ## This is only in the case some MX are down
  return $report;
}

__PACKAGE__->meta->make_immutable();

__END__

=head1 SYNOPSIS

my $postman = Email::Postman->new();

my $email = any Email::Abstract compatible email.

my @reports = $postman->deliver($email);

=head1 ATTRIBUTES

=head2 hello

The domain from which the emails will be sent. Defaults to 'localdomain'

=head2 from

The default 'from' enveloppe email address. Defaults to 'localuser@localdomain'

=head2 debug

Just a debugging flag. Defaults to 0

=head1 METHODS

=head2 deliver

Deliver the given email (something compatible with L<Email::Abstract> (or an email Abstract itself) to its recipients.
and returns an array of L<Email::Postman::Report> about the success/failures of email address the delivery was attempted.

Usage:

  my @report = $this->deliver($email);

=head1 AUTHOR

Jerome Eteve, C<< <jerome.eteve at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-email-postman at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Postman>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Postman


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Postman>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Postman>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Postman>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Postman/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jerome Eteve.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Email::Postman
