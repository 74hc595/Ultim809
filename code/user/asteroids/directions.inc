; vim:noet:sw=8:ts=8:ai:syn=as6809
; Asteroid direction vector table
; 32 possible directions per speed (straight directions not included)

AST_DIRECTIONS:	.fdb	COS_11_25,  SIN_11_25	;instead of 0
		.fdb	COS_11_25,  SIN_11_25
		.fdb	COS_22_5,   SIN_22_5  
		.fdb	COS_33_75,  SIN_33_75 
		.fdb	COS_45,     SIN_45	  
		.fdb	COS_56_25,  SIN_56_25 
		.fdb	COS_67_5,   SIN_67_5  
		.fdb	COS_78_75,  SIN_78_75 
		.fdb	COS_101_25, SIN_101_25	;instead of 90
		.fdb	COS_101_25, SIN_101_25
		.fdb	COS_112_5,  SIN_112_5 
		.fdb	COS_123_75, SIN_123_75
		.fdb	COS_135,    SIN_135   
		.fdb	COS_146_25, SIN_146_25
		.fdb	COS_157_5,  SIN_157_5 
		.fdb	COS_168_75, SIN_168_75
		.fdb	COS_191_25, SIN_191_25	;instead of 180
		.fdb	COS_191_25, SIN_191_25
		.fdb	COS_202_5,  SIN_202_5 
		.fdb	COS_213_75, SIN_213_75
		.fdb	COS_225,    SIN_225   
		.fdb	COS_236_25, SIN_236_25
		.fdb	COS_247_5,  SIN_247_5 
		.fdb	COS_258_75, SIN_258_75
		.fdb	COS_218_25, SIN_218_25	;instead of 270
		.fdb	COS_218_25, SIN_218_25
		.fdb	COS_292_5,  SIN_292_5 
		.fdb	COS_303_75, SIN_303_75
		.fdb	COS_315,    SIN_315   
		.fdb	COS_326_25, SIN_326_25
		.fdb	COS_337_5,  SIN_337_5 
		.fdb	COS_348_75, SIN_348_75
