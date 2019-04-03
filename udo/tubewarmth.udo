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