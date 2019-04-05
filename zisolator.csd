<CsoundSynthesizer>

<CsOptions>
; find your desired alsa midi port  number w aconnect -i -o
-odac -iadc4 -+rtmidi=alsaseq -+rtaudio=jack  -M14
</CsOptions>

<CsInstruments>
;==============================================================================
;==============================================================================
;							 OPTIONS & TABLES
;==============================================================================
sr = 48000
nchnls = 2
0dbfs = 1
ksmps = 8

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
	initc7 1, 1, 1
	initc7 1, 2, 1
	initc7 1, 3, 1
	initc7 1, 4, 0.5
	initc7 1, 5, 0.5
	kLowLvl ctrl7 1, 1, 0, 1
	kMidLvl ctrl7 1, 2, 0, 1
	kHighLvl ctrl7 1, 3, 0, 1
	aLowLvl interp kLowLvl
	aMidLvl interp kMidLvl
	aHighLvl interp kHighLvl
	kCrossover1Freq ctrl7 1, 4, 80, 640
	kCrossover2Freq ctrl7 1, 5, 1000, 8000

	ain1, ain2 ins
	ain = ain1 * 0.5 + ain2 * 0.5
	; 3 way crossover
	; aLow is low passed at kCrossover1Freq
	; aMid is high passed at kCrossover1Freq, then low passed at kCrossover2Freq
	; each band is fed into a peaking filter that removes 3db(still tweaking) so the summed result doesn't clip
	; aHigh is high passed at kCrossover2Freq
	; aLow clfilt ain, kCrossover1Freq, 0, 4
	; aMid clfilt ain, kCrossover1Freq, 0, 4
	; aMid clfilt ain, kCrossover2Freq, 1, 4
	; aHigh clfilt ain, kCrossover2Freq, 1, 4
	aLow clfilt ain, kCrossover1Freq, 0, 4, 0
	aLow pareq aLow, kCrossover1Freq, ampdb(-12), 0.7
	aMid clfilt ain, kCrossover2Freq, 0, 4, 0
	aMid pareq aMid, kCrossover2Freq, ampdb(-12), 0.7
	aMid clfilt ain, kCrossover1Freq, 1, 4, 0
	aMid pareq aMid, kCrossover1Freq, ampdb(-12), 0.7
	aHigh clfilt ain, kCrossover2Freq, 1, 4, 0
	aHigh pareq aHigh, kCrossover2Freq, ampdb(-12), 0.7
	; aLow butlp ain, kCrossover1Freq
	; aLow pareq aLow, kCrossover1Freq, ampdb(-3), sqrt(.5)
	; aMid butlp ain, kCrossover1Freq
	; aMid pareq aMid, kCrossover1Freq, ampdb(-3), sqrt(.5)
	; aMid buthp ain, kCrossover2Freq
	; aMid pareq aMid, kCrossover2Freq, ampdb(-3), sqrt(.5)
	; aHigh buthp ain, kCrossover2Freq
	; aHigh pareq aHigh, kCrossover2Freq, ampdb(-3), sqrt(.5)
	aout = aLow * aLowLvl + aMid * aMidLvl+ aHigh * aHighLvl


	; might be the thing to do, from http://forum.cabbageaudio.com/t/multiband/734
	;first band, 0, 500hz
	; aBand1 butterbp (a1+a2)/2, 0, 1000
	; ;second band, 500, 1500hz
	; aBand2 butterbp (a1+a2)/2, 1000, 1000
	; ;third band, 1500, 5500hz
	; aBand3 butterbp (a1+a2)/2, 3500, 5000

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
