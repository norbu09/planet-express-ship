package Mojolicious::Plugin::Uploader;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $params) = @_;

    $app->helper(
        upload_file => sub {
            my ($self, $file, $prefix) = @_;

            $app->log->debug('Got a file upload request');

            # Check file size
            return { error => 'File is too big.', status => 400 }
                if $self->req->is_limit_exceeded;
            $app->log->debug('it was not too big ...');

            # Process uploaded file
            return { error => 'No File found.', status => 400 }
                unless $file;
            $app->log->debug('... and we got the file');
            my $size = $file->size;
            my $name = $file->filename;
            return {
                error  => 'Could not upload to CDN.',
                status => 400
                }
                unless my $cdn_url = $self->cdn_save($file, $prefix);
            $app->log->debug('... and we pushed it to the CDN');
            $app->log->debug("file $name uploaded");
            return { url => $cdn_url };
        });
}

1;
