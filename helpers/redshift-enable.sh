#!/bin/sh
notification -k "redshift" -a "redshift"
pkill redshift # kill running instances (if any)
redshift &     # start new instance
