" Vim syntax file
" Language:	Motorola 6809 assembler
" Maintainer:	Matt Sarnoff
" Last Change:	April 23, 2010
" URL:		http://msarnoff.org/6809/as6809.vim
" Revision:	1
"
" Supports syntax and directives of the AS6809 assembler:
" http://shop-pdp.kent.edu/ashtml/asxxxx.htm
" Based on asm68k.vim by Steve Wall.

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case ignore

" Opcodes
syn keyword as9Opcode	abx adca adcb adda addb addd anda andb andcc asla aslb
syn keyword as9Opcode	asl asra asrb asr bita bitb clra clrb clr cmpa cmpb
syn keyword as9Opcode	cmpd cmps cmpu cmpx cmpy coma comb com cwai daa deca
syn keyword as9Opcode	decb dec eora eorb exg inca incb inc jmp jsr lda ldb
syn keyword as9Opcode	ldd lds ldu ldx ldy leas leau leax leay lsla lslb lsl
syn keyword as9Opcode	lsra lsrb lsr mul nega negb neg nop ora orb orcc pshs
syn keyword as9Opcode	pshu puls pulu rola rolb rol rora rorb ror rti rts sbca
syn keyword as9Opcode	sbcb sex sta stb std sts stu stx sty suba subb subd swi
syn keyword as9Opcode	swi2 swi3 sync tfr tsta tstb tst
syn keyword as9Opcode	bcc bcs beq bge bgt bhi bhs ble blo bls blt bmi bne bpl
syn keyword as9Opcode	bra brn bsr bvc bvs
syn keyword as9Opcode	lbcc lbcs lbeq lbge lbgt lbhi lbhs lble lblo lbls lblt
syn keyword as9Opcode	lbmi lbne lbpl lbra lbrn lbsr lbvc lbvs

" Directives (for as6809 assembler)
syn match as9Directive "\.module"
syn match as9Directive "\.title"
syn match as9Directive "\.sbttl"
syn match as9Directive "\.list"
syn match as9Directive "\.nlist"
syn match as9Directive "\.page"
syn match as9Directive "\.msg"
syn match as9Directive "\.error"
syn match as9Directive "\.byte"
syn match as9Directive "\.db"
syn match as9Directive "\.fcb"
syn match as9Directive "\.word"
syn match as9Directive "\.dw"
syn match as9Directive "\.fdb"
syn match as9Directive "\.3byte"
syn match as9Directive "\.triple"
syn match as9Directive "\.4byte"
syn match as9Directive "\.quad"
syn match as9Directive "\.blkb"
syn match as9Directive "\.ds"
syn match as9Directive "\.rmb"
syn match as9Directive "\.rs"
syn match as9Directive "\.blkw"
syn match as9Directive "\.blk3"
syn match as9Directive "\.blk4"
syn match as9Directive "\.ascii"
syn match as9Directive "\.str"
syn match as9Directive "\.fcc"
syn match as9Directive "\.ascis"
syn match as9Directive "\.strs"
syn match as9Directive "\.asciz"
syn match as9Directive "\.strz"
syn match as9Directive "\.assume"
syn match as9Directive "\.radix"
syn match as9Directive "\.even"
syn match as9Directive "\.odd"
syn match as9Directive "\.bndry"
syn match as9Directive "\.area"
syn match as9Directive "\.bank"
syn match as9Directive "\.org"
syn match as9Directive "\.globl"
syn match as9Directive "\.local"
syn match as9Directive "\.equ"
syn match as9Directive "\.gblequ"
syn match as9Directive "\.lclequ"
syn match as9Directive "\.if"
syn match as9Directive "\.else"
syn match as9Directive "\.if\(tf\|t\|f\|def\|ndef\|b\|nb\|idn\|ne\|eq\|gt\|lt\|ge\|le\|dif\)"
syn match as9Directive "\.include"
syn match as9Directive "\.define"
syn match as9Directive "\.undefine"
syn match as9Directive "\.setdp"
syn match as9Directive "\.16bit"
syn match as9Directive "\.24bit"
syn match as9Directive "\.32bit"
syn match as9Directive "\.msb"
syn match as9Directive "\.lohi"
syn match as9Directive "\.hilo"
syn match as9Directive "\.end"
syn match as9Directive "\.endif"
syn match as9Directive "\.macro"
syn match as9Directive "\.endm"
syn match as9Directive "\.mexit"
syn match as9Directive "\.narg"
syn match as9Directive "\.nchr"
syn match as9Directive "\.ntyp"
syn match as9Directive "\.nval"
syn match as9Directive "\.irp"
syn match as9Directive "\.irpc"
syn match as9Directive "\.rept"
syn match as9Directive "\.mdelete"
syn match as9Directive "\.mlib"
syn match as9Directive "\.mcall"

" Registers
syn match as9Register	"\<a[a-z0-9_?.$@:]\@!"
syn match as9Register	"\<b[a-z0-9_?.$@:]\@!"
syn match as9Register	"\<d[a-z0-9_?.$@:]\@!"
syn match as9Register	"\<s[a-z0-9_?.$@:]\@!"
syn match as9Register	"\<u[a-z0-9_?.$@:]\@!"
syn match as9Register	"\<x[a-z0-9_?.$@:]\@!"
syn match as9Register	"\<y[a-z0-9_?.$@:]\@!"
syn match as9Register	"\<dp[a-z0-9_?.$@:]\@!"
syn match as9Register	"\<pc[a-z0-9_?.$@:]\@!"
syn match as9Register	"\<pcr[a-z0-9_?.$@:]\@!"
syn match as9Register	"\<cc[a-z0-9_?.$@:]\@!"

" Numbers
syn match as9HexNumber	"\(\$\|0x\)[0-9a-fA-F]\+\>"
syn match as9HexNumber	"\<[0-9a-fA-F]\+H\>"
syn match as9OctNumber	"\(@\|0[oq]\)[0-7]\+\>"
syn match as9OctNumber	"\<[0-7]\+[QO]\>"
syn match as9BinNumber	"\(%\|0b\)[01]\+\>"
syn match as9BinNumber	"\<[01]\+B\>"
syn match as9DecNumber	"\<\(0\|[1-9][0-9]*\)D\?\>"
syn match as9Char	"'."

" Immediates
syn match as9Immediate	"#\(\$\|0x\)[0-9a-fA-F]\+\>" contains=as9HexNumber
syn match as9Immediate	"#\<[0-9a-fA-F]\+H\>" contains=as9HexNumber
syn match as9Immediate	"#\(@\|0[oq]\)[0-7]\+\>" contains=as9OctNumber
syn match as9Immediate	"#\<[0-7]\+[QO]\>" contains=as9OctNumber
syn match as9Immediate	"#\(%\|0b\)[01]\+\>" contains=as9BinNumber
syn match as9Immediate	"#\<[01]\+B\>" contains=as9BinNumber
syn match as9Immediate	"#\<\(0\|[1-9][0-9]*\)D\?\>" contains=as9DecNumber
syn match as9Immediate  "#'." contains=as9Char
syn match as9Symbol     "[a-z_?.][a-z0-9_?.$]*" contained
syn match as9Immediate	"#[a-z_?.][a-z0-9_?.]*" contains=as9Symbol

" Direct page
syn match as9Direct	"\*\(\$\|0x\)[0-9a-fA-F]\+\>" contains=as9HexNumber
syn match as9Direct	"\*\<[0-9a-fA-F]\+H\>" contains=as9HexNumber
syn match as9Direct	"\*\(@\|0[oq]\)[0-7]\+\>" contains=as9OctNumber
syn match as9Direct	"\*\<[0-7]\+[QO]\>" contains=as9OctNumber
syn match as9Direct	"\*\(%\|0b\)[01]\+\>" contains=as9BinNumber
syn match as9Direct	"\*\<[01]\+B\>" contains=as9BinNumber
syn match as9Direct	"\*\<\(0\|[1-9][0-9]*\)D\?\>" contains=as9DecNumber
syn match as9Direct	"\*[a-z_?.][a-z0-9_?.]*" contains=as9Symbol

" Labels
syn case match
syn match as9Label	"^[a-z_.][a-zA-Z0-9_.$]*$"
syn match as9Label	"^[a-z_.][a-zA-Z0-9_.$]*\s"he=e-1
syn match as9Label	"^[a-z_.][a-zA-Z0-9_.$]*::\?"

syn match as9UpperLabel	"^[A-Z_.][A-Z0-9_.$]*$"
syn match as9UpperLabel	"^[A-Z_.][A-Z0-9_.$]*\s"he=e-1
syn match as9UpperLabel	"^[A-Z_.][A-Z0-9_.$]*::\?"

syn match as9ReusableLabel "^[0-9]\+\$:"

syn case ignore


" Operators
syn match as9Operator	"[-+*/%&|^]"

" String surrounded in quotes
syn region as9String	start=+"+ end=+"+

" 'Form constant character' string, with matching delimiters
syn region as9String	start="\(fcc\s\+\)\@<=\z(\S\)" end="\z1"

" Comments; bare comments aren't supported
syn keyword as9Todo	contained TODO
syn match as9Comment	";.*" contains=as9Todo
syn match as9Comment	"^\s*\*.*" contains=as9Todo


syn case match

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_as9_syntax_inits")
  if version < 508
    let did_as9_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink as9Opcode	Statement
  HiLink as9Label	Type
  HiLink as9ReusableLabel Type
  HiLink as9UpperLabel	Function

  HiLink as9Register	Identifier

  HiLink as9HexNumber	Number
  HiLink as9OctNumber	Number
  HiLink as9BinNumber	Number
  HiLink as9DecNumber	Number
  HiLink as9Char	Number
  HiLink as9Immediate	SpecialChar
  HiLink as9Direct	SpecialChar

  HiLink as9String	String

  HiLink as9Directive	PreProc

  HiLink as9Comment	Comment
  HiLink as9Todo	Todo

  HiLink as9LineNumber	LineNr
  HiLink as9ListAddr	Type
  HiLink as9ListData	Number

  delcommand HiLink
endif

let b:current_syntax = "as6809"
