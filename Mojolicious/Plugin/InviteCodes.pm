package Mojolicious::Plugin::InviteCodes;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON;
use Store::CouchDB;
use Data::Dumper;

sub register {
    my ($self, $app, $params) = @_;

    my $couch = Store::CouchDB->new(
        port  => $params->{port},
        db    => $params->{db},
        debug => 1
    );

    $app->helper(
        create_invite => sub {
            my ($self) = @_;

            my $code = $couch->put_doc({
                    doc => {
                        type       => 'invite',
                        used       => 0,
                        created_by => $self->session->{user_id},
                    },
                });

            return $code;
        },
    );

    $app->helper(
        check_invite => sub {
            my ($self, $code) = @_;

            return unless $code;

            my $invite = $couch->get_view({
                    view => 'invites/valid',
                    opts => { key => $code },
            });
            if ($invite->{$code}) {
                $self->session->{invite_code} = $code;
                return 1;
            }

            return;
        },
    );

    $app->helper(
        use_invite => sub {
            my ($self) = @_;

            my $code = $self->session->{invite_code};
            return unless ($code);

            my $invite = $couch->get_view({
                    view => 'invites/valid',
                    opts => { key => $code, include_docs => 'true' },
            });
            if ($invite->{$code}) {
                $invite            = $invite->{$code};
                $invite->{used}    = 1 unless ($invite->{_id} eq 'Talent2012'); # TODO: remove after #swhh12
                $invite->{used_by} = $self->session->{user_id};
                $couch->put_doc({ doc => $invite });
                return 1;
            }

            return;
        },
    );
}

1;
