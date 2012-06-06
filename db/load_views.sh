#!/usr/bin/env bash

for view in dev/*/*; do echo $view:; ../bin/couch_load_views -d $view; done

