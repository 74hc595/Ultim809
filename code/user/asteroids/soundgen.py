#!/usr/bin/env python

import ym2149

STOP = 0
REPEAT = 0xFFFF

# Sound frequencies in hertz
# Sample rate: 60Hz
effects = {
	"SHIPFIRE": 		[816,793,748,720,684,645,617,561,535,476,436,385,326,264,201,137,STOP],
	"SAUCERFIRE": 	[824,818,810,802,797,796,772,751,737,731,721,714,710,696,671,652,STOP],
	"LARGESAUCER":	[552,733,894,1048,1177,1301,1412,1211,947,716,REPEAT],
	"SMALLSAUCER":	[814,1051,1245,1420,1580,1503,849,REPEAT]
	}
	
def val_for_freq(freq):
	val = ym2149.value_for_tone_freq(freq) if freq != STOP and freq != REPEAT else freq
	return "0x%04X" % val
	
for fxname, fxfreqs in effects.iteritems():
	vals = map(val_for_freq, fxfreqs)
	print fxname+":\t.fdb\t"+(",".join(vals))