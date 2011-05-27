#!/usr/bin/env python

import os, sys

def main(args):
  if len(args) < 1:
		return 1

  filename = args[0]
  outfilename = os.path.splitext(filename)[0] + ".inc"

  infile = open(filename, 'r')
  data = infile.read()
  
  outfile = open(outfilename, 'w')

  for c in data:
    outfile.write("\t.fcb\t%#02x\n" % ord(c))

  outfile.close()

  return 0


if __name__ == "__main__":
  sys.exit(main(sys.argv[1:]))
