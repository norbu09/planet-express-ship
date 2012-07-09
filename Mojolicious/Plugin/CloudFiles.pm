package Mojolicious::Plugin::CloudFiles;

use Mojo::Base 'Mojolicious::Plugin';
use WebService::Rackspace::CloudFiles;
use File::Type::WebImages 'mime_type';

sub register {
    my ( $self, $app, $params ) = @_;

    my $cf = WebService::Rackspace::CloudFiles->new(
        user => $params->{cdn}->{user},
        key  => $params->{cdn}->{key},
    );
    my $c = $cf->container( name => 'startup-platform' );

    $app->helper(
        cdn_save => sub {
            my ( $self, $blob, $project ) = @_;

            my $filename =
              'project-' . $project . '-' . $blob->filename;
            my $file = $c->object(
                name         => $filename,
                content_type => mime_type( $blob->slurp )
            );
            $file->object_metadata(
                {
                    uploaded => time,
                    user_id  => $self->session->{user_id},
                }
            );
            $file->put( $blob->slurp );
            return $params->{cdn}->{url} . '/' . $filename;
        }
    );
}

1;
