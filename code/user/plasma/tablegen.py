#!/usr/bin/env python

from math import *

def functionGenerator():
  for x in range(-128,0):
    # convert x from an integer to a real in the range [0,2*pi)
    xr = (x/256.0)*2*pi
    # evaluate the function
    yr = sin(xr)
    # convert back to an integer in the range [-128,127]
    y = int(floor(yr*127.5))
    yield y

values = functionGenerator()
print ",".join(map(str, values))
