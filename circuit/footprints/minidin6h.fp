# $Id: minidin6h.fp,v 1.4 2009/02/25 09:18:52 alexander_kurz Exp $
Element[0x0 "Hosiden TCS7567-0121077 Mini-Din-6 Horizontal Socket" "Xx" "minidin6" 26575 15000 5500 -16000 0 100 ""]
(
	# signal pins
	Pin[29528 13386 7000 3000 7500 3500 "3" "3" 0x0]
	Pin[29528 5118 7000 3000 7500 3500 "1" "1" 0x0]
	Pin[29528 -5118 7000 3000 7500 3500 "2" "2" 0x0]
	Pin[29528 -13386 7000 3000 7500 3500 "4" "4" 0x0]
	Pin[39370 13386 7000 3000 7500 3500 "5" "5" 0x0]
	Pin[39370 -13386 7000 3000 7500 3500 "6" "6" 0x0]
	# shield connectors
	Pin[17717 26575 14500 4000 15100 9000 "" "M1" ""]
	Pin[14567 0 14500 4000 15100 9000 "" "M3" ""]
	Pin[17717 -26575 14500 4000 15100 9000 "" "M2" ""]
	# the element box
	ElementLine [46850 27559 46850 -27559 2000]
	ElementLine [-3937 -27559 46850 -27559 2000]
	ElementLine [-3937 27559 46850 27559 2000]
	ElementLine [-3937 27559 -3937 -27559 2000]
	ElementLine [3937 27559 3937 -27559 1000]
	#
	Attribute("author" "Alexander Kurz")
	Attribute("copyright" "2008 Alexander Kurz")
	Attribute("use-license" "Unlimited")
	Attribute("dist-license" "CC-BY-SA-2.5")
	Attribute("height" "12.8mm")
	Attribute("ref" "http://www.hosiden.com/web/products/pdf/e_c02_mini.pdf")	
)
