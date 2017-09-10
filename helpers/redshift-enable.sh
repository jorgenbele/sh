#!/bin/sh
notification -k "redshift" -a "redshift"
killall -e redshift # kill running instances (if any)
redshift &     # start new instance

