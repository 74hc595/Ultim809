#!/usr/bin/env python

# Loads programs to the Ultim809 over the serial port and runs them
# Matt Sarnoff (msarnoff.org/6809)
# December 15, 2010
#
# Usage:
#  ser09 load file.s19  load file.s19 into memory (RAM or ROM)
#  ser09 run file.s19   load file.s19 into memory and execute it
#  ser09 run            start execution at 0x0100
#
# The first serial port is used by default. Can be overridden with the
# -p option or the SER09_PORT environment variable.

import getopt, sys, serial
from os import getenv
from time import sleep

# size of chunks sent to device
# must be 64 for programming an AT28C64B EEPROM
PAGE_SIZE = 64

# start address of ROM
ROM_START = 0xE000

# RAM program start address
RAM_PROG_START = 0x0100

# mandatory length of ROM images
ROM_LENGTH = 8192

# remote commands
FN_READ_MEM			= b'\xFE'
FN_WRITE_MEM		= b'\xFD'
FN_RUN_TARGET		= b'\xFA'
FN_ROMLD_START	= b'\xF3'
FN_ROMLD_DONE		= b'\xF2'
FN_SUCCESS			= b'\x01'

# --------------------
class Group:
	"""splits a sequence into groups of elements"""
	def __init__(self,l,size):
		self.size = size
		self.l = l
	
	def __getitem__(self, group):
		idx = group * self.size
		if idx >= len(self.l):
			raise IndexError("Out of range")
		return self.l[idx:idx+self.size]
	

# --------------------
class MemImage:
	"""represents a memory image as a sequence of bytes"""
	def __init__(self):
		self.bytes = bytearray()
		self.startAddr = 0
		self.startAddrSet = False
		self.currentAddr = 0

	def setAddress(self, newaddr):
		if not self.startAddrSet:
			self.startAddr = newaddr
			self.currentAddr = newaddr
			self.startAddrSet = True
		else:
			if newaddr < self.currentAddr:
				raise Exception("Backward jumps not allowed")
			elif newaddr > self.currentAddr:
				# fill intermediate bytes with 0xFF
				self.bytes.extend(b"\xFF"*(newaddr-self.currentAddr))
				self.currentAddr = newaddr
	
	def appendByte(self, byte):
		self.bytes.append(byte)
		self.currentAddr += 1
		
	def length(self):
		return len(self.bytes)
	
	def endAddr(self):
		return self.startAddr + self.length()
		
	@staticmethod
	def fromS19File(filename):
		f = open(filename)
		mem = MemImage()
		for line in f:
			recordtype = line[0:2]
			if recordtype == "S0":		# don't care about S0 records
				pass
			elif recordtype == "S9":	# don't care about S9 records
				pass
			elif recordtype == "S1":	# only care about S1 records
				line = line.rstrip()
				bytecount = int(line[2:4],16)
				addr = int(line[4:8],16)
				databytes = line[8:-2]
				checksum = int(line[-2:],16)
				thischecksum = bytecount + ((addr>>8)&0xFF) + (addr&0xFF)
				mem.setAddress(addr)
				for hexbyte in Group(databytes,2):
					byteval = int(hexbyte,16)
					mem.appendByte(byteval)
					thischecksum += byteval
				thischecksum = (~thischecksum)&0xFF
				if thischecksum != checksum:
					raise Exception("Bad checksum")
			else:											# anything else isn't supported
				raise Exception("'%s' record not supported" % recordtype)
		return mem
			

# --------------------
def romLoadStart(ser):
	ser.write(FN_ROMLD_START)
	if ser.read(1) != FN_SUCCESS:
		raise Exception("FN_ROMLD_START command failed")

# --------------------
def romLoadDone(ser):
	ser.write(FN_ROMLD_DONE)

# --------------------
def writeMem(ser, addr, chunk):
	addrhi = (addr>>8)&0xFF
	addrlo = addr&0xFF
	numbytes = len(chunk)
	ser.write(bytearray([FN_WRITE_MEM, addrhi, addrlo, numbytes]))
	ser.write(chunk)
	if ser.read(1) != FN_SUCCESS:
		raise Exception("FN_WRITE_MEM command failed")

# --------------------
def readMem(ser, addr, numbytes):
	addrhi = (addr>>8)&0xFF
	addrlo = addr&0xFF
	ser.write(bytearray([FN_READ_MEM, addrhi, addrlo, numbytes]))
	return bytearray(ser.read(numbytes))

# --------------------
def readAndPrintMem(ser, addr, numbytes):
	bytes = readMem(ser, addr, numbytes)
	for bytegroup in Group(bytes, 16):
		print "0x%04X:" % addr,
		for byte in bytegroup:
			print "%02X" % byte,
		print
		addr += 16

# --------------------
def execAtAddress(ser, addr):
	addrhi = (addr>>8)&0xFF
	addrlo = addr&0xFF
	ser.write(bytearray([FN_RUN_TARGET, addrhi, addrlo]))


# --------------------
def sendData(ser, memimage, isRom):
	# if sending a rom image, machine must relocate its monitor
	if isRom:
		print "Preparing to upload ROM image"
		romLoadStart(ser)
		print "OK"
	# now send the byte chunks
	addr = memimage.startAddr
	for chunk in Group(memimage.bytes,PAGE_SIZE):
		numbytes = len(chunk)
		print "Writing %d byte(s) to 0x%04X" % (numbytes, addr)
		# send the data and wait for acknowledge
		writeMem(ser, addr, chunk)
		# read the data back
		response = readMem(ser, addr, numbytes)
		if response != chunk:
			print repr(chunk)
			print repr(response)
			raise Exception("Chunk verify failed")
		addr += numbytes
	# finish the rom transfer if necessary
	if isRom:
		print "Finishing ROM upload"
		romLoadDone(ser)
	print "All OK"


# --------------------
def usage():
	print """usage: ser09 [-p device] <action> [file.s19]

Options:
  -p     specify serial device
  
Actions:
  load   load file into memory (RAM or ROM)
  run    load file into memory and execute it
           if no file is specified, start executing at address 0x0100

If file's base address is 0x0100, it will be loaded into RAM.
If file's base address is 0xE000, it will be loaded into ROM.
  (write enable switch must be turned on)"""


# --------------------
def load(ser,file):
	# load the file
	memimage = MemImage.fromS19File(file)
	isRom = False
	if memimage.startAddr == ROM_START:
		isRom = True
		if memimage.length() != ROM_LENGTH:
			raise Exception("ROM image must be exactly %d bytes" % ROM_LENGTH)
		elif memimage.startAddr > ROM_START:
			raise Exception("ROM image must start at 0x%04X" % ROM_START)
	elif memimage.startAddr != RAM_PROG_START:
		raise Exception("RAM program must start at 0x%04X" % RAM_PROG_START)	
	# send it
	sendData(ser, memimage, isRom)


# --------------------
def run(ser,file):
	# load it
	if file:
		load(ser,file)
	# then run it
	execAtAddress(ser, RAM_PROG_START)


# --------------------
def main(args):
	try:
		serialport = getenv("SER09_PORT", 0)
		baudrate = getenv("SER09_BAUD", 38400)
		startupdelay = float(getenv("SER09_STARTUP_DELAY", 0))
		
		opts, args = getopt.getopt(args, "p:")
		for o, a in opts:
			if o == "-p":
				serialport = a
			else:
				assert False, "unhandled option"
	
		if len(args) < 1:
			usage()
			return 1
		
		action = None
		if args[0] == "load" and len(args) == 2:
			action = lambda ser: load(ser,args[1])
		elif args[0] == "run" and len(args) <= 2:
			if len(args) == 2:
				action = lambda ser: run(ser,args[1])
			else:
				action = lambda ser: run(ser,None)
		elif args[0] == "read" and len(args) == 3:
			addr = int(args[1], 16)
			count = int(args[2], 10)
			action = lambda ser: readAndPrintMem(ser,addr,count)
		elif args[0] == "v0":
			action = lambda ser: readMem(ser,0xCC03,1)
		elif args[0] == "v1":
			action = lambda ser: readMem(ser,0xCC05,1)
		else:
			usage()
			return 1
			
		if action:
			ser = serial.Serial(serialport, baudrate)
			print "Using", ser.portstr
			
			# optional delay, in case the remote device is an Arduino
			# that resets every time the serial port is opened (stupid)
			if startupdelay:
				print "Waiting for remote...",
				sys.stdout.flush()
				sleep(startupdelay)
				print "done"
			
			action(ser);
			ser.close()

	except getopt.GetoptError, e:
		print str(e)
		usage()
		return 1
	except Exception, e:
		print >>sys.stderr, e
		return 2
		
	return 0

# --------------------
if __name__ == "__main__":
	sys.exit(main(sys.argv[1:]))
