<CsoundSynthesizer>

<CsOptions>
; find your desired alsa midi port  number w aconnect -i -o
; -odac -+rtmidi=alsaseq -+rtaudio=jack  -M14
-odac -iadc -+rtmidi=alsaseq -+rtaudio=jack  -M14
</CsOptions>

<CsInstruments>
;==============================================================================
;==============================================================================
;							 OPTIONS & TABLES
;==============================================================================
sr = 48000
nchnls = 2
0dbfs = 1
ksmps = 32

gifn	ftgen   2,0,0dbfs,"tanh",1,-1,0	; tanh
giwaveform ftgen 0, 0, 4, -2, 0, 2, 12, -1
giwaveform2 ftgen 0, 0, 3, -2, 0, 10, 12
gisine ftgen 1, 0, 16384, 10, 1


;==============================================================================
;==============================================================================
;								PATCHBAY
;==============================================================================

connect "Mixer",   "output",     "Outputs",     	"inputL"
connect "Mixer",   "output",     "Outputs",     	"inputR"

alwayson "Mixer"
alwayson "Outputs"


;==============================================================================
;==============================================================================
;								INSTRUMENTS
;==============================================================================

instr Mixer

	; LowLvl = gain for low band
	; LowKill = toggle switch, pulls Lvl to 0 if 1

	initc7 1, 1, 0.5 ; kLowLvl
	initc7 1, 2, 0.5 ; kMidLvl
	initc7 1, 3, 0.5 ; kHighLvl
	initc7 1, 4, 0.5 ; kCrossover1Freq
	initc7 1, 5, 0.5 ; kCrossover2Freq
	initc7 1, 6, 0 ; kLowKill
	initc7 1, 7, 0 ; kMidKill
	initc7 1, 8, 0 ; kHighKill

	kLowLvl ctrl7 1, 1, 0, ampdb(10)
	kMidLvl ctrl7 1, 2, 0, ampdb(10)
	kHighLvl ctrl7 1, 3, 0, ampdb(10)
	aLowLvl interp kLowLvl
	aMidLvl interp kMidLvl
	aHighLvl interp kHighLvl

	kCrossover1Freq ctrl7 1, 4, 80, 640
	kCrossover2Freq ctrl7 1, 5, 1000, 8000
	aCrossover1Freq interp kCrossover1Freq
	aCrossover2Freq interp kCrossover2Freq

	kLowKill ctrl7 1, 6, 1, 0
	kMidKill ctrl7 1, 7, 1, 0
	kHighKill ctrl7 1, 8, 1, 0
	aLowKill interp kLowKill
	aMidKill interp kMidKill
	aHighKill interp kHighKill

	ain1, ain2 ins
	; headroom for the 10db possible bump from the bands. will still peak a lil at max tho
	ain = ain1 * 0.35

	aLow butlp ain, aCrossover1Freq
	aLow butlp aLow, aCrossover1Freq
	aMid butlp ain, aCrossover2Freq
	aMid butlp aMid, aCrossover2Freq
	aMid buthp aMid, aCrossover1Freq
	aMid buthp aMid, aCrossover1Freq
	aHigh buthp ain, aCrossover2Freq
	aHigh buthp aHigh, aCrossover2Freq

	aout = aLow * aLowLvl * aLowKill + aMid * aMidLvl * aMidKill + aHigh * aHighLvl * aHighKill

	outleta "output", aout
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
