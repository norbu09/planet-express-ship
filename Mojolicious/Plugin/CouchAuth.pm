package Mojolicious::Plugin::CouchAuth;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON;
use Store::CouchDB;
use Digest::SHA qw(sha256_base64);

sub register {
    my ($self, $app, $params) = @_;

    my $couch = Store::CouchDB->new(
        port  => $params->{port},
        db    => $params->{db},
        debug => 1
    );
    my $password_reset_timeout = 172800;    # two days

    $app->helper(
        auth => sub {
            my ($self) = @_;

            if ($self->session->{user_id}) {
                if ($self->param('username')) {
                    return $self->validate_user();
                }
                else {
                    return 1;
                }
            }
            return unless $self->param('username');

            return $self->validate_user();
        },
    );

    $app->helper(
        update_password => sub {
            my ($self) = @_;

            my $user = $self->get_user($self->param('username'));
            return unless $user;

            $user->{password} = sha256_base64($self->param('password'));
            return $couch->put_doc({ doc => $user });
        },
    );

    $app->helper(
        add_password_reset => sub {
            my $self = shift;

            my $user = $self->get_user($self->param('username'));
            return unless $user;

            my $reset = {
                username => $self->param('username'),
                type     => 'password_reset',
                user     => $user,
                ts       => time,
            };
            my $id = $couch->put_doc({ doc => $reset });
            return { id => $id, user => $user };
        },
    );

    $app->helper(
        get_password_reset => sub {
            my ($self, $id) = @_;

            my $reset = $couch->get_doc({ id => $id });
            return unless $reset;

            if ($reset->{ts} + $password_reset_timeout > time) {
                return $reset;
            }
            else {
                $couch->del_doc({ id => $id });
            }
            return;
        },
    );
    $app->helper(
        expire_password_reset => sub {
            my ($self, $id) = @_;
            return $couch->del_doc({ id => $id });
        },
    );
    $app->helper(
        check_free => sub {
            my ($self, $username) = @_;
            return $self->get_user($username);
        },
    );
    $app->helper(
        validate_user => sub {
            my ($self) = @_;

            my $user = $self->get_user($self->param('username'));
            return unless $user;

            if (sha256_base64($self->param('password')) eq $user->{password}) {
                $self->session(name     => $user->{name});
                $self->session(username => $user->{username});
                $self->session(user_id  => $user->{_id});
                $self->session(admin    => 1)
                    if (defined $user->{role} && $user->{role} eq 'admin');
                $self->session(last_login => _set_last_login($couch, $user));
                return 1;
            }
            return;
        },
    );
    $app->helper(
        signup_user => sub {
            my ($self, $params) = @_;
            if ($self->check_free('user', $params->{username})) {
                $self->flash(message =>
                        'This email address is already registered. Maybe you have a user already?'
                );
                return;
            }
            $params->{type}   = 'user';
            $params->{active} = 1;
            my $id = $couch->put_doc({ doc => $params });
            $self->auth();
            return $id;
        },
    );
}

sub _set_last_login {
    my ($couch, $user) = @_;

    my $last_login = $user->{last_login};
    $user->{last_login} = time;
    $couch->put_doc({ doc => $user });

    return $last_login;
}

1;
