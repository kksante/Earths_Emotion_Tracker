#!/usr/bin/env python

from app import app
# remember to turn off debug before final, and tornado is set up on a different port
app.run(host='0.0.0.0', debug = False) # default 5000
