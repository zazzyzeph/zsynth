<CsoundSynthesizer>

<CsOptions>
-odac -+rtmidi=virtual -+rtaudio=jack  -M1
</CsOptions>

<CsInstruments>
;==============================================================================
;==============================================================================
;							 OPTIONS & TABLES
;==============================================================================
sr = 48000
ksmps = 32
nchnls = 2
0dbfs = 1

gifn	ftgen	0,0, 257, 9, .5,1,270	; sigmoid


;==============================================================================
;==============================================================================
;								PATCHBAY
;==============================================================================

; very much work in progress

; LOUD

connect "VCO",   "output",     "Outputs",     	"inputL"
connect "VCO",   "output",     "Outputs",     	"inputR"
connect "LPF",   "output",     "Reverb",     	"input"
connect "Reverb",   "outputL",     "Outputs",     	"inputL"
connect "Reverb",   "outputR",     "Outputs",     	"inputR"


alwayson "Gate"
alwayson "VcaEnv"
alwayson "VCO"
alwayson "LPF"
alwayson "Reverb"
alwayson "Outputs"


;==============================================================================
;==============================================================================
;							CUSTOM OPCODES
;==============================================================================

; Responsive analog style envelopes for MIDI instruments

opcode ADSD,k,kkkkk
 kmax,katt,kdec,ksus,ktrig    xin 
 ktime init 0
 kv init 0
 iper = 1/kr
 if (ktrig == 1) then
   if ktime <= katt then
     kt = katt 
     kv = kmax
   else 
     kt = kdec
     kv = ksus
   endif
   ktime += iper
 else
   kt = kdec
   kv = 0
   ktime = 0
 endif
 kenv  portk  kv, kt
       xout  kenv
endop

; Tube style drive

opcode tap_tubewarmth,a,akk

	setksmps 1

	ain, kdrive, kblend xin

	kdrive	 	limit kdrive, 0.1, 10
	kblend 		limit kblend, -10, 10

	kprevdrive init 0
	kprevblend init 0

	krdrive 	init 0
	krbdr 		init 0
	kkpa 		init 0
	kkpb 		init 0
	kkna 		init 0
	kknb 		init 0
	kap 		init 0
	kan 		init 0
	kimr 		init 0
	kkc 		init 0
	ksrct 		init 0
	ksq 		init 0
	kpwrq 		init 0

	#define TAP_EPS # 0.000000001 # 
	#define TAP_M(X) # $X = (($X > $TAP_EPS || $X < -$TAP_EPS) ? $X : 0) #
	#define TAP_D(A) # 
	if ($A > $TAP_EPS) then
	$A = sqrt($A)
	elseif ($A < $TAP_EPS) then
	$A = sqrt(-$A)
	else
	$A = 0
	endif
	#

	if (kprevdrive != kdrive || kprevblend != kblend) then

	krdrive = 12.0 / kdrive;
	krbdr = krdrive / (10.5 - kblend) * 780.0 / 33.0;

	kkpa = 2.0 * (krdrive*krdrive) - 1.0
	$TAP_D(kkpa)
	kkpa = kkpa + 1.0;

	kkpb = (2.0 - kkpa) / 2.0;
	kap = ((krdrive*krdrive) - kkpa + 1.0) / 2.0;

	kkc = 2.0 * (krdrive*krdrive) - 1.0
	$TAP_D(kkc)
	kkc = 2.0 * kkc - 2.0 * krdrive * krdrive
	$TAP_D(kkc)

	kkc = kkpa / kkc

	ksrct = (0.1 * sr) / (0.1 * sr + 1.0);
	ksq = kkc*kkc + 1.0

	kknb = ksq
	$TAP_D(kknb)
	kknb = -1.0 * krbdr / kknb

	kkna = ksq
	$TAP_D(kkna)
	kkna = 2.0 * kkc * krbdr / kkna

	kan = krbdr*krbdr / ksq

	kimr = 2.0 * kkna + 4.0 * kan - 1.0
	$TAP_D(kimr)
	kimr = 2.0 * kknb + kimr


	kpwrq = 2.0 / (kimr + 1.0)

	kprevdrive = kdrive
	kprevblend = kblend

	endif

	aprevmed 	init 0
	amed 		init 0
	aprevout	init 0

	kin downsamp ain

	if (kin >= 0.0) then
	kmed = kap + kin * (kkpa - kin)
	$TAP_D(kmed)
	amed = (kmed + kkpb) * kpwrq
	else
	kmed = kap - kin * (kkpa + kin)
	$TAP_D(kmed)
	amed = (kmed + kkpb) * kpwrq * -1
	endif

	aout = ksrct * (amed - aprevmed + aprevout)

	kout downsamp aout
	kmed downsamp amed


	if (kout < -1.0) then
	aout = -1.0
	kout = -1.0
	endif

	$TAP_M(kout)
	$TAP_M(kmed)

	aprevmed = kmed
	aprevout = kout

	#undef TAP_D
	#undef TAP_M
	#undef TAP_EPS

	xout aout

endop
;==============================================================================
;==============================================================================
;								INSTRUMENTS
;==============================================================================
instr midiIn
	icps     cpsmidi
	gkcps = icps
endin

instr Gate
	kNoteCount active "midiIn"
	if (kNoteCount > 0) then
		gkGate = 1
	else
		gkGate = 0
	endif
endin

instr VcaEnv
	initc7 1, 1, 0.0001
	initc7 1, 2, 1
	initc7 1, 3, 1
	initc7 1, 4, 1
	kVcaMax init 1
	kVcaAttack ctrl7 1, 1, 0.0001, 1
	kVcaDecay ctrl7 1, 2, 0.001, 1
	kVcaSustain ctrl7 1, 3, 0.001, 1
	kVcaRelease ctrl7 1, 4, 0.05, 1
	if (kVcaSustain > 0.001) then
		kVcaMax = kVcaSustain
	else
		kVcaMax = 1
	endif
	gkVcaEnv ADSD kVcaMax, kVcaAttack, kVcaDecay, kVcaSustain, gkGate
endin

; instr pitchEnv
; 	initc7 1, 1, 0.0001
; 	initc7 1, 2, 1
; 	initc7 1, 3, 1
; 	initc7 1, 4, 1
; 	kFiltMax init 1
; 	kFiltAttack ctrl7 1, 1, 0.0001, 1
; 	kFiltDecay ctrl7 1, 2, 0.001, 1
; 	kFiltSustain ctrl7 1, 3, 0.001, 1
; 	kFiltRelease ctrl7 1, 4, 0.05, 1
; 	if (kFiltSustain > 0.001) then
; 		kFiltMax = kFiltSustain
; 	else
; 		kFiltMax = 1
; 	endif
; 	gkFiltEnv ADSD kFiltMax, kFiltAttack, kFiltDecay, kFiltSustain, gkGate
; endin

instr VCO
	asaw vco2 0dbfs * 0.4, gkcps
	ashaped distort asaw, 1, gifn
	avca = ashaped * gkVcaEnv
	outleta "output", avca
endin

instr LPF
	initc7 1, 5, 1
	initc7 1, 6, 0.0001
	kDriveAmt ctrl7 1, 7, 2, 20
	kCutoff ctrl7 1, 5, 0, 1
	kRes ctrl7 1, 6, 0, 0.9
	ainput inleta "input"
	afilt moogladder ainput, 10000, kRes
	denorm afilt
	adistorted tap_tubewarmth afilt, kDriveAmt, -5
	outleta "output", adistorted
endin

instr Reverb
	kcont17 init 0.91 ; delay
	kcont18 init 12000 ;cutoff
	kcont19 init 0.5 ; dry/wet mix
	kcont17 ctrl7 1, 17, 0.3, 0.9
	kcont18 ctrl7 1, 18, 0, 12000
	kcont19 ctrl7 1, 19, 0, 1
	kcont19inv ctrl7 1, 19, 1, 0
	ainput inleta "input"
	awetleftout, awetrightout reverbsc ainput, ainput, kcont17, kcont18
	aleftout = (awetleftout*kcont19) + (ainput * kcont19inv)
	arightout = (awetrightout*(kcont19)) + (ainput * kcont19inv)
	; Stereo output.
	outleta "outputL", aleftout
	outleta "outputR", arightout 
endin

instr Outputs
  ainputL inleta "inputL"
  ainputR inleta "inputR"
  alimitedL clip ainputL, 0, 0dbfs
  alimitedR clip ainputR, 0, 0dbfs
  outs alimitedL, alimitedR
endin

</CsInstruments>

<CsScore>

</CsScore>

</CsoundSynthesizer>