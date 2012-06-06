package Mojolicious::Plugin::FormValidate;

use Mojo::Base 'Mojolicious::Plugin';
use Digest::SHA qw(sha256_base64);
use Data::Dumper;

sub register {
    my ( $plugin, $app, $conf ) = @_;

    $app->helper(
        check_missing => sub {
            my $self = shift;
            my @mandatory = split( /,/, $self->param('mandatoryfields') );
            my @err;
            foreach my $ky (@mandatory) {
                push(@err, $ky) unless $self->param($ky);
            }
            return \@err;
        }
    );

    $app->helper(
        process_form => sub {
            #$app->log->debug(Dumper(@_));
            my $self   = shift;
            my $page   = shift || {};
            my $back   = shift || $self->req->url->to_string;
            my @fields = split( /,/, $self->param('formfields') );
            my @error;
            foreach my $ky (@fields) {
                next unless $self->param($ky);
                if(check_field($ky, $self->param($ky))){
                    push(@error, $ky);
                }
                if ( $ky eq 'password' ) {
                    $page->{$ky} = sha256_base64( $self->param($ky) );
                }
                else {
                    $page->{$ky} = $self->param($ky);
                }
            }
            my @msg;
            my $missing = $self->check_missing();
            if($missing->[0]){
                push(@msg, "You are missing the following fields: " . join(', ', @{$missing}) );
            } elsif (@error){
                push(@msg, "The following fields were not validating: " . join(', ', @error));
            }
            if(@msg){
                $self->flash(error => join('<br>', @msg));
                $app->log->debug("Got errors, should not return anything!");
                $app->log->debug(Dumper(@msg));
                $self->flash(page => $page);
                $self->redirect_to($back);
                return;
            } else {
                return $page;
            }
        },

    );

}

sub check_field {
    my $field = shift;
    my $string = shift;

    my $definitions = {
        #username => '^[-\w\.]+@[-\w\.]+\.[-\w\.]+$',
        password => '\w{3,128}',
        description => '.{3,20000}',
    };
    # fall back to a rather generic test to cover all fields not defined
    # explicitly.
    my $def = $definitions->{$field} || '.{3,200}';
    return 1 unless ($string =~ m{^$def$});
    return;
}

1;
