#!/usr/bin/env python
#
# YM2149 frequency conversion routines.

MASTER_CLOCK = 2000000.0

def value_for_tone_freq(hz):
	"""Returns the 12-bit value for the specified tone frequency."""
	val = int(MASTER_CLOCK/(16*hz))
	if val < 1 or val > 4095:
		raise OverflowError("Frequency is out of the allowed range")
	return val
	
def value_for_noise_freq(hz):
	"""Returns the 5-bit value for the specified noise frequency."""
	val = int(MASTER_CLOCK/(16*hz))
	if val < 1 or val > 31:
		raise OverflowError("Frequency is out of the allowed range")

def value_for_env_freq(hz):
	"""Returns the 16-bit value for the specified envelope frequency."""
	val = int(MASTER_CLOCK/(256*hz))
	if val < 1 or val > 65535:
		raise OverflowError("Frequency is out of the allowed range")
	
def freq_for_tone_value(val):
	"""Returns the frequency for the specified 12-bit tone value."""
	if val < 1 or val > 4095:
		raise OverflowError("Value is out of the allowed range")
	return MASTER_CLOCK/(16*val)
	
def freq_for_noise_value(val):
	"""Returns the frequency for the specified 5-bit noise value."""
	if val < 1 or val > 31:
		raise OverflowError("Value is out of the allowed range")
	return MASTER_CLOCK/(16*val)

def freq_for_env_value(val):
	"""Returns the frequency for the specified 16-bit envelope value."""
	if val < 1 or val > 65535:
		raise OverflowError("Value is out of the allowed range")
	return MASTER_CLOCK/(256*val)