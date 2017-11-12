#!/bin/sh
notification -d "redshift"
notification -t 10 -a "rs: shutting down..." &

redshift -x # restore colors and brightness
killall -e redshift # kill running instances (if any)
