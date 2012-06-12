package Mojolicious::Plugin::CouchUser;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON;
use Store::CouchDB;

sub register {
    my ($self, $app, $params) = @_;

    my $couch = Store::CouchDB->new(
        port  => $params->{port},
        db    => $params->{db},
        debug => 1
    );

    $app->helper(
        create_user => sub {
            my ($self) = @_;

            return unless $self->session->{fb_uid};

            # TODO: get user details from FB here once

            my $user = {
                fb_uid => $self->session->{fb_uid},
                type   => 'user',
                active => 'true',
            };
            my $user_id = $couch->put_doc({ doc => $user });
            if ($user_id) {
                $self->session(user    => $user);
                $self->session(user_id => $user_id);
            }
            else {
                $self->flash(error => 'could not create user');
            }

            return 1;
        },
    );

    $app->helper(
        get_user => sub {
            my $self         = shift;
            my $username     = shift || $self->session->{user_id};
            my $account_type = shift || '';

            my $user;
            given ($account_type) {
                when ('facebook') {
                    $user = $couch->get_view(
                        {
                            view     => 'user/by_facebook',
                                opts => {
                                key              => $username,
                                    include_docs => 'true',
                            },
                        });
                }
                default {
                    return $couch->get_doc(
                        {
                            id => $username
                        }) unless ($username =~ m/@/);

                    $user = $couch->get_view({
                            view => 'site/user',
                            opts =>
                                { key => $username, include_docs => 'true' },
                    });
                }
            }
            return $user->{$username};
        },
    );

    $app->helper(
        update_user => sub {
            my $self = shift;

            my $user = $self->get_user($self->session->{user_id});
            my $page = $self->process_form($user) || return;

            return $couch->put_doc({
                    name => $user->{_id},
                    doc  => $page,
            });
        },
    );

    $app->helper(
        is_admin => sub {
            my ($self) = @_;

            my $doc = $self->get_user($self->param('username'));
            return unless $doc;

            return 1
                if (defined $doc->{role} && $doc->{role} eq 'admin');
        },
    );

}

1;
