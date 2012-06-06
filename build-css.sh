#!/bin/sh

BOOTSTRAP=./public/css/bootstrap.css
BOOTSTRAP_LESS=./css/bootstrap.less
BOOTSTRAP_RESPONSIVE=./public/css/bootstrap-responsive.css
BOOTSTRAP_RESPONSIVE_LESS=./css/responsive.less
DATE=`date +%I:%M%p`
CHECK="\033[32m✔\033[39m"
HR=\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

echo "\n${HR}"
echo "Building Bootstrap..."
echo "${HR}\n"
jshint js/*.js --config js/.jshintrc
jshint js/tests/unit/*.js --config js/.jshintrc
echo "Running JSHint on javascript...             ${CHECK} Done"
recess --compile ${BOOTSTRAP_LESS} > ${BOOTSTRAP}
recess --compile ${BOOTSTRAP_RESPONSIVE_LESS} > ${BOOTSTRAP_RESPONSIVE}
echo "Compiling LESS with Recess...               ${CHECK} Done"
cat js/bootstrap-transition.js js/bootstrap-alert.js js/bootstrap-button.js js/bootstrap-carousel.js js/bootstrap-collapse.js js/bootstrap-dropdown.js js/bootstrap-modal.js js/bootstrap-tooltip.js js/bootstrap-popover.js js/bootstrap-scrollspy.js js/bootstrap-tab.js js/bootstrap-typeahead.js > public/js/bootstrap.js
uglifyjs -nc public/js/bootstrap.js > public/js/bootstrap.min.tmp.js
echo "/**\n* Bootstrap.js by @fat & @mdo\n* Copyright 2012 Twitter, Inc.\n* http://www.apache.org/licenses/LICENSE-2.0.txt\n*/" > public/js/copyright.js
cat public/js/copyright.js public/js/bootstrap.min.tmp.js > public/js/bootstrap.min.js
rm public/js/copyright.js public/js/bootstrap.min.tmp.js
echo "Compiling and minifying javascript...       ${CHECK} Done"
echo "\n${HR}"
echo "Bootstrap successfully built at ${DATE}."
echo "${HR}\n"
echo "Thanks for using Bootstrap,"
echo "<3 @mdo and @fat\n"
