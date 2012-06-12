package Mojolicious::Plugin::FacebookAuth;

use Mojo::Base 'Mojolicious::Plugin';
use WWW::Facebook::API;

sub register {
    my ($self, $app, $params) = @_;

    my $fb = WWW::Facebook::API->new(
        parse        => 1,
        desktop      => 0,
        throw_errors => 1,
        app_id       => $params->{app_id},
        api_key      => $params->{api_key},
        secret       => $params->{secret},
    );

    $app->helper(
        auth => sub {
            my ($self) = @_;

            if ($self->param('auth_token')) {
                $fb->auth->get_session($self->param('auth_token'));

                return 1 if $self->session->{user_id};

                my $fb_uid = $fb->users->get_logged_in_user;
                return unless $fb_uid;

                $self->session->{fb_uid} = $fb_uid;
                return $self->validate_user($fb_uid);
            }

            if ($self->logged_in()) {
                return 1;
            }
            else {
                $self->session(initial_page => $self->req->url);
                $self->redirect_to(
                    $fb->get_login_url(next => 'http://skillbar.net/auth'));
            }
        },
    );

    $app->helper(
        validate_user => sub {
            my ($self, $fb_uid) = @_;

            return unless ($fb_uid);

            my $user = $self->get_user($fb_uid, 'facebook');
            if ($user) {
                $self->session->{user}    = $user;
                $self->session->{user_id} = $user->{_id};
                return 1;
            }

            return;
        },
    );

    $app->helper(
        logged_in => sub {
            my ($self, $user) = @_;

            return 1 if $self->session->{user_id};
            return;
        },
    );

    $app->helper(
        fql => sub {
            my ($self, $fql) = @_;
            return unless $self->session->{access_token};
            return $fb->fql->query(query => $fql);
        });
}

1;
