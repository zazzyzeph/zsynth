<CsoundSynthesizer>

<CsOptions>
-odac -+rtmidi=alsaseq -+rtaudio=jack  -M0
</CsOptions>

<CsInstruments>
;==============================================================================
;==============================================================================
;							 OPTIONS & TABLES
;==============================================================================
sr = 48000
ksmps = 1
nchnls = 2
0dbfs = 1

gifn	ftgen   2,0,0dbfs,"tanh",1,-1,0	; tanh
; gifn	ftgen	0,0, 257, 9, .5,1, 270	; sigmoid
; gifn	ftgen	1, 0, 16384, 10, 1
gisine ftgen 1, 0, 16384, 10, 1


;==============================================================================
;==============================================================================
;								PATCHBAY
;==============================================================================

connect "Kick", "output", "Mixer", "input1"

connect "Mixer",   "output",     "Outputs",     	"inputL"
connect "Mixer",   "output",     "Outputs",     	"inputR"

alwayson "Gate0"
alwayson "Gate1"
alwayson "VcaEnv"
alwayson "PitchEnv"
alwayson "NoiseVcaEnv"
alwayson "Kick"
alwayson "Mixer"
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
instr dummy
endin
instr midiIn0
	icps     cpsmidi
	gkcps0 = icps
endin
instr midiIn1
	icps     cpsmidi
	gkcps1 = icps
endin

instr Gate0
	kNoteCount active "midiIn0"
	if (kNoteCount > 0) then
		gkGate0 = 1
	else
		gkGate0 = 0
	endif
endin
instr Gate1
	kNoteCount active "midiIn1"
	if (kNoteCount > 0) then
		gkGate1 = 1
	else
		gkGate1 = 0
	endif
endin

instr VcaEnv
	initc7 1, 1, 0.1
	kDecay ctrl7 1, 1, 0.05, 0.3
	gkVcaEnv ADSD 1, 0.005, kDecay, 0, gkGate0
endin

instr PitchEnv
	initc7 1, 2, 0.3
	initc7 1, 3, 0.4
	kPitchBendAmt ctrl7 1,2,0,1
	kPitchBendDecay ctrl7 1, 3, 0.001, 0.4
	gkPitchBendEnv ADSD kPitchBendAmt, 0.001, kPitchBendDecay, 0, gkGate0
endin

instr NoiseVcaEnv
	initc7 1, 4, 0.6
	initc7 1, 5, 0.2
	kNoiseVcaAmt ctrl7 1,4,0,0.2
	kNoiseVcaDecay ctrl7 1, 5, 0.001, 0.1
	gkNoiseVcaEnv ADSD kNoiseVcaAmt, 0.001, kNoiseVcaDecay, 0, gkGate0
endin

instr Kick
	initc7 1, 6, 0.5
	initc7 1, 7, 0.5
	kDriveAmt ctrl7 1, 6, 2, 5
	kTone ctrl7 1, 7, -10, 10
	asine poscil 0dbfs, gkcps0 + (gkPitchBendEnv * 150)
	ashaped distort asine, 0.4, gifn
	anoise noise 0dbfs * gkNoiseVcaEnv, 0.999
	amixed distort anoise + ashaped, 0.4, gifn
	atubed tap_tubewarmth amixed, kDriveAmt, kTone
	avca = (atubed * 3) * gkVcaEnv
	outleta "output", avca
endin

instr Mixer
  ainput1 inleta "input1"
  outleta "output", ainput1
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
