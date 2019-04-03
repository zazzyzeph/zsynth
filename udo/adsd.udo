
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
;  interp these values!
endop