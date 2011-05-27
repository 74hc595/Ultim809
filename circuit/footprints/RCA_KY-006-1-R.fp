Element ["" "" "" "" 10000 10000 5000 5000 0 100 ""]
(
	#Pin [rX rY Thickness Clearance Mask Drill "Name" "Number" SFlags]

	#Data pins
	Pin [0 0     10000 3000 10600  6000 "Center (Signal)" "1" ""]
	Pin [0 -20000 15000 3000 15600 11000 " Jacket (Ground)" "2" ""]

  #Mounting holes
  Pin [-20900 0 15000 3000 15600 11000 "Mount" "0" ""]
  Pin [ 20900 0 15000 3000 15600 11000 "Mount" "0" ""]

	#'Keep out' silkscreen box
	#ElementLine[rX1 rY1 rX2 rY2 Thickness]
  ElementLine[-31000  10000  31000  10000 1000] #Back
  ElementLine[-31000 -30000  31000 -30000 1000] #Front
  ElementLine[-31000 -30000 -31000  10000 1000] #Left
  ElementLine[ 31000 -30000  31000  10000 1000] #Right
)

