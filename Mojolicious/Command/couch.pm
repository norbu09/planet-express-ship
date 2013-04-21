package Mojolicious::Command::couch;

use Mojo::Base 'Mojolicious::Command';
use Getopt::Long 'GetOptions';
use Store::CouchDB;
use File::Util;
use File::Path qw(mkpath);
use Data::Dumper;

# Short description
has description => "CouchDB management tools.\n";

# Short usage message
has usage => <<"EOF";
usage: $0 couch

couch is an view management interafce for CouchDB. It dumps and loads views and
helps you track them in your VCS.

These options are available:
  -d, --dump   dumps views onto file system
  -l, --load   loads views from file system
  -c, --create create the DB
  --bootstrap  bootstrap CouchDB
EOF

# <suitable Futurama quote here>
sub run {
    my $self = shift;

    # Handle options
    local @ARGV = @_;
    my $app = $self->app;
    $app->{config}->{couch}->{view_dir} = 'db'
        unless exists $app->{config}->{couch}->{view_dir};
    my $couch = Store::CouchDB->new($app->{config}->{couch});
    GetOptions(
        'l|load'    => sub { load($couch,      $app) },
        'd|dump'    => sub { cdump($couch,      $app) },
        'c|create'  => sub { create($couch,    $app) },
        'bootstrap' => sub { bootstrap($couch, $app) });

    say "Planet-Express-Ship CouchDB tools";

    #load($couch, $app) if $load == 1;
}

sub load {
    my ($couch, $app) = @_;

    my $view = {};

    say "Loading views";
    my ($f) = File::Util->new();
    foreach my $dir (_get_files($app->{config}->{couch}->{view_dir}, 'dir')) {
        foreach my $file (
            _get_files($app->{config}->{couch}->{view_dir} . '/' . $dir))
        {
            my @doc =
                $f->load_file(
                join('/', $app->{config}->{couch}->{view_dir}, $dir, $file),
                qw/ --as-lines/);
            my $hash;
            my $now;
            my $name;
            foreach (@doc) {
                if ($_ =~ /^\[(\w+)\]$/) {
                    $now = $1;
                    next;
                }
                if ($now eq 'params') {
                    my ($ky, $vl) = split(/\s*=\s*/, $_, 2);
                    if ($ky eq 'name') {
                        $name = $vl;
                        next;
                    }
                    $view->{$ky} = $vl;
                }
                else {
                    $hash->{$now} .= $_ . "\n";
                }
            }
            $view->{views}->{$name} = $hash;
        }
        print "finding\n";
        my $doc;
        eval { $doc = $couch->get_doc({ id => $view->{_id} }) };
        print "storing\n";
        delete $view->{_rev} unless $doc;
        $view->{_rev} = $doc->{_rev} if $doc;

        my $id = $couch->put_doc({ doc => $view });

        print "Saved $id\n" if $id;
        print "Error saving views!\n" unless $id;
    }
    return;
}

sub cdump {
    my ($couch, $app) = @_;

    say "Dumping views ...";
    my $docs = $couch->get_doc(
        { id => '_all_docs?startkey="_design"&endkey="_design0"' });
    foreach my $row (@{ $docs->{rows} }) {

        my $doc = $couch->get_doc({ id => $row->{id} });
        my ($_n, $name) = split(/\//, $doc->{_id}, 2);
        my $views = delete $doc->{views};
        print "saving $name\n";
        foreach my $view (keys %{$views}) {
            my $vdir = $app->{config}->{couch}->{view_dir} . '/' . $name;
            if (!-d $vdir) {
                mkpath($vdir);
                if ($@) {
                    die "Could not create missing export directory: $@";
                }
                warn "Created export directory $vdir\n";
            }
            open(FH, '>', $vdir . '/' . $view . '.view')
                || die "Could not open file: $@";
            print FH "[map]\n";
            print FH $views->{$view}->{map};
            if ($views->{$view}->{reduce}) {
                print FH "\n[reduce]\n";
                print FH $views->{$view}->{reduce};
            }
            print FH "\n[params]\n";
            print FH "name = $view\n";
            foreach my $ky (keys %{$doc}) {
                print FH $ky . ' = ' . $doc->{$ky} . "\n";
            }
            close FH;
        }

    }
    return;
}

sub create {
    my ($couch, $app) = @_;

    say "Setting up your CouchDB";

    $couch->create_db();

    return;

}

sub bootstrap {
    my ($couch, $app) = @_;

    create($couch, $app);
    load($couch, $app);
    return;
}

sub npm_install {

    say "running `npm` to update/install node requirements";

    print qx{npm install};
}

sub _get_files {
    my ($base, $type) = @_;
    $type = 'file' unless $type;
    opendir my ($dh), $base or return "Couldn't open dir '$base':
        $!";
    my @files;
    if ($type eq 'dir') {
        @files = grep { !/^\./ && -d "$base/$_" } readdir($dh);
    }
    else {
        @files = grep { !/^\./ && -f "$base/$_" } readdir($dh);
    }
    closedir $dh;
    return @files;
}

1;
