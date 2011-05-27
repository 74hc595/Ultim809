
	
	
Element(0x00 "Bicolor LED, 3mm (pin 1 is green +, pin 3 is red +, pin 2 is -)" "" "BILED3" 100 70 0 100 0x00)
(
# typical LED is 0.5 mm or 0.020" square pin.  See for example
# http://www.lumex.com and part number SSL-LX3054LGD.
# 0.020" square is 0.0288" diagonal.  A number 57 drill is 
# 0.043" which should be enough.  a 65 mil pad gives 11 mils
# of annular ring.

	Pin(-80 0 65 43 "1" 0x101)
	Pin(0 0 65 43 "2" 0x01)
	Pin(80 0 65 43 "3" 0x001)
   ElementArc(0 0 59 59    45  90 10)
	ElementArc(0 0 59 59   225  90 10)

   ElementArc(0 0 79 79    45  90 10)
	ElementArc(0 0 79 79   225  90 10)

	Mark(0 0)
)

