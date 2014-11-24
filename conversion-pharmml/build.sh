#!/bin/bash

# Notes for the conversion of Chen-Sherman's model in PharmML


# The human-readable pieces are translated to PharmML via the
# http://infix2pharmml.sourceforge.net service.  Based directly off
# the original XPP version.

c="perl ./convert.pl -q"


# Heaviside function
rm functions.xml
$c "heavx(x):= (abs(x)+x)/(2*abs(x)+1e-5)" >> functions.xml


# Modulus function

#PharmML has the `rem()` function. In case it does not accept
#real-valued arguments, the following can be used.

$c "modulus(a,b):=a-b*floor(a/b)" >> functions.xml



# Saturation function
$c "minf(v):= 1/(1 + exp((Vm-V)/sm))" >> functions.xml



# Parameters
# TBD


# Voltage source - a square source
# Microdomain and cytosol Ca++ concentrations
# Chain of granules

$c -q -s "

par Vrest=-70, Vburst=-20
par tstep=0.0, ton=12.0, toff=12.0
par GlucFact=1.2
par ts=60
par fmd=0.01, fi=0.01, B=200, fv=0.00365
par alpha=5.18e-15, vmd=4.2e-15, vcell=1.15e-12
par gL=250, Vm=-20, Vca=25, sm=5
par Jsercamax=41.0, Kserca=0.27, Jpmcamax=21.0, Kpmca=0.5, Jleak=-0.94, Jncx0=18.67
par k1=20, km1=100, r1=0.6, rm1=1, r20=0.006, rm2=0.001
par r30=1.205, rm3=0.0001, u1=2000, u2=3, u3=0.02
par Kp=2.3, Kp2=2.3
par tau=2.0

IL:=gL*minf(v=V)*(V- Vca)
IR:=0.25*IL

JL:=alpha*IL/vmd
JR:=alpha*IR/vcell

Jserca := Jsercamax*Ci^2/(Kserca^2 + Ci^2)
Jpmca := Jpmcamax*Ci/(Kpmca + Ci)
Jncx := Jncx0*(Ci - 0.25)
L:=Jserca + Jpmca + Jncx + Jleak

V:=Vrest + (Vburst - Vrest)*(heav(x=rem(t, tcycle)) - heav(x=rem(t,tcycle) - toff))


par Cmd_init=0.0674
par Ci_init=0.06274

diff(Cmd,t):= ts*(-fmd*JL - fmd*B*(Cmd - Ci))
diff(Ci,t):= ts*(-fi*JR + fv*fi*B*(Cmd - Ci) - fi*L)

r2:=r20*Ci/(Ci + Kp2)
r3:=GlucFact*r30*Ci/(Ci + Kp)

par N1_init=14.71376
par N2_init=0.612519
par N3_init=0.0084499
par N4_init=5.098857e-6
par N5_init=24.539936
par N6_init=218.017777
par NF_init=0.003399
par NR_init=0.50988575
par SE_init=0.0

diff(N1,t):= ts*(-(3*k1*Cmd + rm1)*N1 + km1*N2 + r1*N5)
diff(N2,t):= ts*(3*k1*Cmd*N1 -(2*k1*Cmd + km1)*N2 + 2*km1*N3)
diff(N3,t):= ts*(2*k1*Cmd*N2 -(2*km1 + k1*Cmd)*N3 + 3*km1*N4)
diff(N4,t):= ts*(k1*Cmd*N3 - (3*km1 + u1)*N4)
diff(N5,t):= ts*(rm1*N1 - (r1 + rm2)*N5 + r2*N6)
diff(N6,t):= ts*(r3 + rm2*N5 - (rm3 + r2)*N6)
diff(NF,t):= ts*(u1*N4 - u2*NF)
diff(NR,t):= ts*(u2*NF - u3*NR)

diff(SE,t):= ts*(u3*NR)

docked := N6 + N5 + N1
primed := N5 + N1
" > structural.xml

# PharmML lacks the delay() function
# measured:=4.5*(SE - delay(SE, tau))



# Merge the two
sed '/<!-- Insert FunctionDefinition here -->/ r functions.xml' structural.xml > model.xml


# Final pp
xml_pp -i model.xml

