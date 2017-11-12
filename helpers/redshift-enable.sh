#!/bin/sh
notification -k "redshift" -a "rs"
killall -e redshift # kill running instances (if any)
redshift &     # start new instance

