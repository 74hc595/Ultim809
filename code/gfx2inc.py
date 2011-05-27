#!/usr/bin/env python

# Converts tileset bitmaps to assembler include files.
# Currently supports TMS9918 format.
# Matt Sarnoff (msarnoff.org)
# May 5, 2011
#
# Usage:
#		gfx2inc [-s <size>] <image>
#
# <image> is an image file in any format PIL supports.
# <size> specifies tile size.
#   Currently supported values are 8x8 and 16x16.
#   The image dimensions must be multiples of the tile dimensions.
#
# Bytes are written top to bottom.
# 16x16 tiles are written out in TMS9918 byte order:
#   upper left, lower left, upper right, lower right.

import os, sys, getopt, Image

# Supported tile sizes
TILESIZES = {"8x8": (8,8), "16x16": (16,16)}

# Default tile size
tileWidth, tileHeight = TILESIZES["8x8"]

# Output file name
outfile = ""

def usage():
	print """usage: gfx2inc [-s <size>] <image>"""
	

def outputTile(image, outfd, row, col, width, height):

	# helper function to output a single pattern (sub-tile)
	def outputPattern(image, outfd, row, col, width, height):			
			for y in range(row*height, (row+1)*height):
				outfd.write("\t.fcb\t0b")
				for x in range(col*width, (col+1)*width):
					outfd.write("%d" % (image.getpixel((x,y)) / 255))
				outfd.write("\n")

	xmin, xmax = col*width, ((col+1)*width)-1
	ymin, ymax = row*height, ((row+1)*height)-1
	outfd.write("; tile (%d,%d)-(%d,%d)\n" % (xmin, ymin, xmax, ymax))
	if width == 8 and height == 8:
		# 8x8 tiles use one pattern
		outputPattern(image, outfd, row, col, width, height)
	elif width == 16 and height == 16:
		# 16x16 tiles use four patterns
		outputPattern(image, outfd, row*2, col*2, 8, 8)
		outputPattern(image, outfd, (row*2)+1, col*2, 8, 8)
		outputPattern(image, outfd, row*2, (col*2)+1, 8, 8)
		outputPattern(image, outfd, (row*2)+1, (col*2)+1, 8, 8)
	else:
		assert False, "Unsupported tile size"
		
		
def loadImage(infile):
	image = None
	try:
		# open and convert to black and white
		image = Image.open(infile).convert("1")
	except IOError:
		print "Could not open image file", infile
		return None
		
	# verify image size
	imageWidth, imageHeight = image.size
	if imageWidth % tileWidth != 0:
		print "Image width must be a multiple of", imageWidth
		return None
	if imageHeight % tileHeight != 0:
		print "Image height must be a multiple of", imageHeight
		return None

	tilesWide = imageWidth / tileWidth
	tilesHigh = imageHeight / tileHeight
	return (image, imageWidth, imageHeight, tilesWide, tilesHigh)


def convert(infile, outfile):
	image, imageWidth, imageHeight, tilesWide, tilesHigh = loadImage(infile)
	if not image:
		return
	
	outfd = open(outfile, 'w')
	for row in range(0, tilesHigh):
		for col in range(0, tilesWide):
			outputTile(image, outfd, row, col, tileWidth, tileHeight)			
	outfd.close()


def animationPreview(infile, outname, firstTile, lastTile):
	image, imageWidth, imageHeight, tilesWide, tilesHigh = loadImage(infile)
	if not image:
		return

	firstTile = int(firstTile) if firstTile != '' else 0
	lastTile = int(lastTile) if lastTile != '' else tilesWide*tilesHigh
		
	for tilenum in range(firstTile, lastTile+1):
		tileX = (tilenum % tilesWide)*tileWidth
		tileY = (tilenum / tilesWide)*tileHeight
		tilerect = (tileX, tileY, tileX+tileWidth, tileY+tileHeight)
		tileimage = image.crop(tilerect)
		tileimage.save("anim-%s-%d.png" % (outname, tilenum), "PNG")


def main(args):
	global tileWidth, tileHeight
	animate = False
	
	try:
		# TODO: use argparse
		opts, args = getopt.getopt(args, "a:t:s:")
		for o, a in opts:
			if o == "-s":
				try:
					tileWidth, tileHeight = TILESIZES[a]
				except KeyError:
					print "Tile size %s not supported" % a
					print "Supported sizes are", ", ".join(TILESIZES.keys())
					return 1
			elif o == "-a":
				# specify tiles for animation
				animate = True
				tileParams = a.split(',')
				animFirstTile = tileParams[0] if len(tileParams) >= 1 else ''
				animLastTile = tileParams[1] if len(tileParams) >= 2 else ''
			else:
				assert False, "unsupported option"
				
		if len(args) < 1:
			usage()
			return 1
				
		infile = args[0]
		basename = os.path.splitext(infile)[0]

		if not animate:
			# Normal mode, output the include file
			convert(infile, basename+".inc")
		else:
			# Animation preview mode, output multiple temp images and
			# animate with ImageMagick
			animationPreview(infile, basename, animFirstTile, animLastTile)
			
		return 0
		
	except getopt.GetoptError, e:
		print str(e)
		usage()
		return 1
	except Exception, e:
		print >>sys.stderr, e
		return 2
	
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv[1:]))