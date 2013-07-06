package Email::Postman::Report;
use Moose;

use DateTime;

has 'about_email' => ( is => 'ro' , isa => 'Str', required => 1 );
has 'timestamp' => ( is => 'ro', isa => 'DateTime' , required => 1 , default => sub{ DateTime->now(); } );
has 'success' => ( is => 'rw' , isa => 'Bool', default => 0);
has 'message' => ( is => 'rw' , isa => 'Str', required => 1 , default => '');
has 'failed_at' => ( is => 'rw' , isa => 'Maybe[DateTime]' , clearer => 'clear_failed_at' );

=head1 NAME

Email::Postman::Report - A report about sending a message to ONE email address.

=cut

=head2 set_failure_message

Shortcut to set the failure state AND the message at the same time.

Usage:

 $this->set_failure_message("Something went very wrong");

=cut

sub set_failure_message{
  my ($self, $message) = @_;
  $self->success(0);
  $self->message($message);
  $self->failed_at(DateTime->now());
}

=head2 reset

Resets this report success and message.

=cut

sub reset{
  my ($self) = @_;
  $self->success(0);
  $self->message('');
  $self->clear_failed_at();
}

__PACKAGE__->meta->make_immutable();
