package Mojolicious::Command::build;

use Mojo::Base 'Mojolicious::Command';
use Getopt::Long 'GetOptions';

# Short description
has description => "Build the Bootstrap CSS and JS files.\n";

# Short usage message
has usage => <<"EOF";
usage: $0 build

build is an easy way to recompile your bootstrap theme and
combine/minify the javascript in /js

These options are available:
  -i, --npm_install   Runs npm to install/update node modules
EOF

# <suitable Futurama quote here>
sub run {
    my $self = shift;

    # Handle options
    local @ARGV = @_;
    say "Building Bootstrap...";
    GetOptions('i|npm_install' => \&npm_install);

    build_js();
    build_css();
}

sub build_js {
    
    say "Combining and minifying JS";
    say "running `jshint` " . qx{./node_modules/.bin/jshint ./js/*.js --config ./js/.jshintrc};

    say "combining JS " . qx{cat ./js/*js > ./public/js/bootstrap.js};
    say "running `uglifyjs`" .  qx{./node_modules/.bin/uglifyjs -nc ./public/js/bootstrap.js > ./public/js/bootstrap.min.tmp.js};
    qx{echo "/**\n* Bootstrap.js by \@fat & \@mdo\n* Copyright 2012 Twitter, Inc.\n* http://www.apache.org/licenses/LICENSE-2.0.txt\n*/" > ./public/js/copyright.js};
    say "creating bootstrap.min.js " . qx{cat ./public/js/copyright.js ./public/js/bootstrap.min.tmp.js > ./public/js/bootstrap.min.js};
    say "cleaning up " . qx{rm ./public/js/copyright.js ./public/js/bootstrap.min.tmp.js};
    return;
}

sub build_css {
    
    say "Compiling less to CSS";
    say "running `recess` " . qx{./node_modules/.bin/recess --compile ./css/bootstrap.less > ./public/css/bootstrap.css};
    say "running `recess` " . qx{./node_modules/.bin/recess --compress ./css/bootstrap.less > ./public/css/bootstrap.min.css};
    say "running `recess` " . qx{./node_modules/.bin/recess --compile ./css/responsive.less > ./public/css/bootstrap-responsive.css};
    say "running `recess` " . qx{./node_modules/.bin/recess --compress ./css/responsive.less > ./public/css/bootstrap-responsive.min.css};
}

sub npm_install {

    say "running `npm` to update/install node requirements";

    print qx{npm install};
}

1;
