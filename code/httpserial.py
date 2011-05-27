#!/usr/bin/env python
#
# HTTP over serial bridge.
# Allows transfer of HTTP data via simple serial protocol.
#
# Transfers are performed all at once and block.
# Therefore, it's only practical for downloading small files.
#
# Commands
# ========
#
# 0xF8 - Request URL
# Arguments:
#   - URL with terminating null byte
# Response:
#   0xFE - response code follows
#   0x00 - timeout or other error
# If sent while there is still data from a previous
# request, it is discarded.
#
# 0xF9 - Request Data Chunk
# Arguments:
#   - Data chunk size (2 bytes, big-endian)
# Response:
#   0xFD - data follows
#   0x00 - no data left
#
# 0xFA - Data Available?
# Response:
#   0xFC - data available
#   0x00 - no data available
#
#
# Responses
# =========
#
# 0xFC - Data Available
#
# 0xFD - Data Response
#   - Data length (2 bytes, big-endian)
#   - Data
#
# 0xFE - Request Success
#   - HTTP status code (2 bytes, big-endian)
#
# 0x00 - Error

from datetime import date, datetime
from os import getenv
import urllib2, struct, serial

# remote comamnds
CMD_REQUEST_URL			= 0xF8
CMD_REQUEST_DATA		= 0xF9
CMD_DATA_AVAILABLE	= 0xFA
RESP_DATA_AVAILABLE	= 0xFC
RESP_DATA						= 0xFD
RESP_HTTP_STATUS		= 0xFE
RESP_ERROR					= 0x00

currentRequest = None
currentRequestData = None
currentRequestOffset = 0

def logMessage(msg):
	print date.strftime(datetime.now(), "[%H:%M:%S]  "), msg
	
def logError(msg):
	print date.strftime(datetime.now(), "[%H:%M:%S] *"), msg

def replyWithError():
	pass #TODO

def replyWithNoDataAvailable():
	logMessage("No data available")
	ser.write(bytearray([RESP_ERROR]))
	
def replyWithDataAvailable(bytesLeft):
	logMessage("%d byte(s) available" % bytesLeft);
	ser.write(bytearray([RESP_DATA_AVAILABLE,(bytesLeft>>8)&0xFF,bytesLeft&0xFF]))
	
def replyWithDataResponse(data,length):
	logMessage("%d byte(s) requested" % length);
	ser.write(bytearray([RESP_DATA,(length>>8)&0xFF,length&0xFF]))
	ser.write(data)
	
def replyWithHTTPStatus(status):
	logMessage("Request success, status %d" % status)
	ser.write(bytearray([RESP_HTTP_STATUS,(status>>8)&0xFF,status&0xFF]))

def cmdRequestURL(url):
	global currentRequest
	global currentRequestData
	global currentRequestOffset
	# clear old request
	if currentRequest:
		currentRequestData = None
		currentRequestOffset = 0
	# make new request
	logMessage("Request: "+url)
	try:
		currentRequest = urllib2.urlopen(url, None, 5)
		currentRequestData = currentRequest.read()
		replyWithHTTPStatus(currentRequest.getcode())
	except Exception, e:
		logError(e);
		replyWithError()
	
def cmdDataAvailable():
	global currentRequestData
	global currentRequestOffset
	if not currentRequestData:
		replyWithNoDataAvailable()
	else:	
		bytesLeft = len(currentRequestData) - currentRequestOffset
		if bytesLeft == 0:
			replyWithNoDataAvailable()
		else:
			replyWithDataAvailable(bytesLeft)

def cmdRequestData(chunksize):
	global currentRequestData
	global currentRequestOffset
	if not currentRequestData:
		replyWithNoDataAvailable()
	else:	
		bytesLeft = len(currentRequestData) - currentRequestOffset
		if bytesLeft == 0:
			replyWithNoDataAvailable()
		else:
			data = currentRequestData[currentRequestOffset:currentRequestOffset+chunksize]
			dataSize = len(data)
			currentRequestOffset += dataSize
			replyWithDataResponse(data, dataSize)
		
serialport = getenv("SER09_PORT", 0)
baudrate = getenv("SER09_BAUD", 38400)

# Connect to serial port
ser = serial.Serial(serialport, baudrate)
logMessage("Listening on "+ser.portstr)
		
#### Main loop ####
while True:
	try:
		byte = ord(ser.read(1))
		if byte == CMD_REQUEST_URL:
			# read up to a null byte
			url = ""
			while True:
				byte = ser.read(1)
				if ord(byte) == 0: break
				url += byte
			cmdRequestURL(url)
		elif byte == CMD_REQUEST_DATA:
			# read request size
			chunksize = struct.unpack(">H",ser.read(2))[0]
			cmdRequestData(chunksize)
		elif byte == CMD_DATA_AVAILABLE:
			cmdDataAvailable()
		else:
			logError("Invalid command %#02x received" % ord(byte))
	except Exception, e:
		logError(e)
