#!/bin/sh
notification -d "redshift"
notification -t 10 -a "redshift: shutting down..." &

pkill redshift # kill running instances (if any)
