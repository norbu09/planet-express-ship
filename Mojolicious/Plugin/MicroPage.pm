package Mojolicious::Plugin::MicroPage;

use Mojo::Base 'Mojolicious::Plugin';
use Store::CouchDB;
use Text::Upskirt ':all';
use JSON;

sub register {
    my ($self, $app, $params) = @_;

    my $couch = Store::CouchDB->new(
        port  => $params->{port},
        db    => $params->{db},
        debug => 1
    );

    $app->helper(
        nav => sub {
            my ($self) = @_;
            my $docs = $couch->get_view({ view => 'site/navigation' });
            my @nav;
            foreach my $item (keys %{$docs}) {
                push(@nav, $item);
            }
            return sort(@nav);
        },
    );
    $app->helper(
        get_content => sub {
            my ($self, $path, $raw) = @_;
            my $docs = $couch->get_view({
                    view => 'site/content',
                    opts => { key => $path, include_docs => 'true' },
            });
            if ($raw) {
                foreach my $param (keys %{ $docs->{$path} }) {
                    if ($docs->{$path}->{$param} eq 'on') {
                        $docs->{$path}->{$param} = 'checked';
                    }
                }
                return $docs->{$path};
            }
            my $content = $docs->{$path}->{content};

            $content = markdown($content, MKDEXT_AUTOLINK, HTML_HARD_WRAP);
            $docs->{$path}->{content} = $content;
            return $docs->{$path};
        },
    );
    $app->helper(
        get_update_path => sub {
            my ($self) = @_;
            my $path = $self->req->url->path();
            $path =~ s{^/}{};
            my $docs = $couch->get_view({
                    view => 'site/content',
                    opts => { key => $path, include_docs => 'true' },
            });
            return ($docs->{$path} ? $path : undef);
        },
    );
    $app->helper(
        create_content => sub {
            my ($self, $params) = @_;
            foreach my $param (keys %{$params}) {
                if ($param eq 'path') {
                    $params->{$param} =~ s{^/}{};
                }
            }
            $couch->put_doc({
                    doc   => $params,
                    owner => $self->session->{user_id},
            });
            return $params->{path};
        },
    );
    $app->helper(
        delete_content => sub {
            my ($self, $path) = @_;
            my $docs = $couch->get_view({
                    view => 'site/content',
                    opts => { key => $path, include_docs => 'true' },
            });
            return unless $docs->{$path};
            return $couch->del_doc({ id => $docs->{$path}->{_id} });
        },
    );
    $app->helper(
        update_content => sub {
            my ($self, $path, $params) = @_;
            my $docs = $couch->get_view({
                    view => 'site/content',
                    opts => { key => $path, include_docs => 'true' },
            });
            return unless $docs->{$path};
            foreach my $param (keys %{$params}) {
                $docs->{$path}->{$param} = $params->{$param};
            }
            return $couch->put_doc({
                    doc  => $docs->{$path},
                    name => $docs->{$path}->{_id} });
        },
    );
    $app->helper(
        active_menu => sub {
            my $self  = shift;
            my @items = split(/\//, shift);
            my $item  = $items[0];

            if ($self->req->url =~ m{^/$item}) {
                return ' class="active"';
            }
        },
    );
    $app->helper(
        get_forms => sub {
            my ($self, $type) = @_;

            my $docs = $couch->get_view({
                    view => 'site/templates',
                    opts => { key => $type, include_docs => 'true' },
            });
            return unless $docs->{$type};
            return $docs->{$type}->{fields};
        },
    );
}

1;
