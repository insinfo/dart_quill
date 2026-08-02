(function dartProgram(){function copyProperties(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
b[q]=a[q]}}function mixinPropertiesHard(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
if(!b.hasOwnProperty(q)){b[q]=a[q]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var s=function(){}
s.prototype={p:{}}
var r=new s()
if(!(Object.getPrototypeOf(r)&&Object.getPrototypeOf(r).p===s.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var q=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(q))return true}}catch(p){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var s=Object.create(b.prototype)
copyProperties(a.prototype,s)
a.prototype=s}}function inheritMany(a,b){for(var s=0;s<b.length;s++){inherit(b[s],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){var r=d()
if(a[b]!==s){A.Km(b)}a[b]=r}var q=a[b]
a[c]=function(){return q}
return q}}function makeConstList(a){a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var s=0;s<a.length;++s){convertToFastObject(a[s])}}var y=0
function instanceTearOffGetter(a,b){var s=null
return a?function(c){if(s===null)s=A.yf(b)
return new s(c,this)}:function(){if(s===null)s=A.yf(b)
return new s(this,null)}}function staticTearOffGetter(a){var s=null
return function(){if(s===null)s=A.yf(a).prototype
return s}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var s=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var r=staticTearOffGetter(s)
a[b]=r}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var s=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var r=instanceTearOffGetter(c,s)
a[b]=r}function setOrUpdateInterceptorsByTag(a){var s=v.interceptorsByTag
if(!s){v.interceptorsByTag=a
return}copyProperties(a,s)}function setOrUpdateLeafTags(a){var s=v.leafTags
if(!s){v.leafTags=a
return}copyProperties(a,s)}function updateTypes(a){var s=v.types
var r=s.length
s.push.apply(s,a)
return r}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var s=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},r=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:s(0,0,null,["$0"],0),_instance_1u:s(0,1,null,["$1"],0),_instance_2u:s(0,2,null,["$2"],0),_instance_0i:s(1,0,null,["$0"],0),_instance_1i:s(1,1,null,["$1"],0),_instance_2i:s(1,2,null,["$2"],0),_static_0:r(0,null,["$0"],0),_static_1:r(1,null,["$1"],0),_static_2:r(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
yp(a,b,c,d){return{i:a,p:b,e:c,x:d}},
w9(a){var s,r,q,p,o,n=a[v.dispatchPropertyName]
if(n==null)if($.yn==null){A.IE()
n=a[v.dispatchPropertyName]}if(n!=null){s=n.p
if(!1===s)return n.i
if(!0===s)return a
r=Object.getPrototypeOf(a)
if(s===r)return n.i
if(n.e===r)throw A.i(A.xK("Return interceptor for "+A.p(s(a,n))))}q=a.constructor
if(q==null)p=null
else{o=$.tY
if(o==null)o=$.tY=v.getIsolateTag("_$dart_js")
p=q[o]}if(p!=null)return p
p=A.Jf(a)
if(p!=null)return p
if(typeof a=="function")return B.cm
s=Object.getPrototypeOf(a)
if(s==null)return B.by
if(s===Object.prototype)return B.by
if(typeof q=="function"){o=$.tY
if(o==null)o=$.tY=v.getIsolateTag("_$dart_js")
Object.defineProperty(q,o,{value:B.ax,enumerable:false,writable:true,configurable:true})
return B.ax}return B.ax},
zu(a,b){if(a<0||a>4294967295)throw A.i(A.aK(a,0,4294967295,"length",null))
return J.xe(new Array(a),b)},
nT(a,b){if(a<0)throw A.i(A.au("Length must be a non-negative integer: "+a,null))
return A.a(new Array(a),b.i("w<0>"))},
zt(a,b){if(a<0)throw A.i(A.au("Length must be a non-negative integer: "+a,null))
return A.a(new Array(a),b.i("w<0>"))},
xe(a,b){var s=A.a(a,b.i("w<0>"))
s.$flags=1
return s},
DE(a,b){var s=t.hO
return J.CL(s.a(a),s.a(b))},
zv(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
DG(a,b){var s,r
for(s=a.length;b<s;){r=a.charCodeAt(b)
if(r!==32&&r!==13&&!J.zv(r))break;++b}return b},
DH(a,b){var s,r,q
for(s=a.length;b>0;b=r){r=b-1
if(!(r<s))return A.d(a,r)
q=a.charCodeAt(r)
if(q!==32&&q!==13&&!J.zv(q))break}return b},
a3(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.hL.prototype
return J.jU.prototype}if(typeof a=="string")return J.dO.prototype
if(a==null)return J.hM.prototype
if(typeof a=="boolean")return J.jT.prototype
if(Array.isArray(a))return J.w.prototype
if(typeof a!="object"){if(typeof a=="function")return J.da.prototype
if(typeof a=="symbol")return J.fq.prototype
if(typeof a=="bigint")return J.fp.prototype
return a}if(a instanceof A.J)return a
return J.w9(a)},
aO(a){if(typeof a=="string")return J.dO.prototype
if(a==null)return a
if(Array.isArray(a))return J.w.prototype
if(typeof a!="object"){if(typeof a=="function")return J.da.prototype
if(typeof a=="symbol")return J.fq.prototype
if(typeof a=="bigint")return J.fp.prototype
return a}if(a instanceof A.J)return a
return J.w9(a)},
bx(a){if(a==null)return a
if(Array.isArray(a))return J.w.prototype
if(typeof a!="object"){if(typeof a=="function")return J.da.prototype
if(typeof a=="symbol")return J.fq.prototype
if(typeof a=="bigint")return J.fp.prototype
return a}if(a instanceof A.J)return a
return J.w9(a)},
iV(a){if(typeof a=="number")return J.eA.prototype
if(a==null)return a
if(!(a instanceof A.J))return J.e0.prototype
return a},
Ip(a){if(typeof a=="number")return J.eA.prototype
if(typeof a=="string")return J.dO.prototype
if(a==null)return a
if(!(a instanceof A.J))return J.e0.prototype
return a},
f5(a){if(typeof a=="string")return J.dO.prototype
if(a==null)return a
if(!(a instanceof A.J))return J.e0.prototype
return a},
Iq(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.da.prototype
if(typeof a=="symbol")return J.fq.prototype
if(typeof a=="bigint")return J.fp.prototype
return a}if(a instanceof A.J)return a
return J.w9(a)},
A(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.a3(a).n(a,b)},
CH(a,b){if(typeof a=="number"&&typeof b=="number")return a>=b
return J.iV(a).m_(a,b)},
CI(a,b){if(typeof a=="number"&&typeof b=="number")return a>b
return J.iV(a).dE(a,b)},
CJ(a,b){if(typeof a=="number"&&typeof b=="number")return a<b
return J.iV(a).uK(a,b)},
ej(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.IM(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.aO(a).h(a,b)},
yP(a,b,c){return J.bx(a).j(a,b,c)},
j_(a,b){return J.bx(a).k(a,b)},
wW(a,b){return J.f5(a).dU(a,b)},
CK(a,b,c){return J.f5(a).dV(a,b,c)},
j0(a,b){return J.bx(a).c0(a,b)},
ho(a,b,c){return J.Iq(a).kJ(a,b,c)},
yQ(a,b,c){return J.iV(a).aC(a,b,c)},
CL(a,b){return J.Ip(a).bi(a,b)},
ly(a,b){return J.aO(a).v(a,b)},
lz(a,b){return J.bx(a).ar(a,b)},
CM(a,b){return J.f5(a).be(a,b)},
CN(a,b){return J.bx(a).cR(a,b)},
CO(a,b,c,d){return J.bx(a).ag(a,b,c,d)},
wX(a,b){return J.bx(a).O(a,b)},
ek(a){return J.bx(a).gF(a)},
b4(a){return J.a3(a).ga3(a)},
lA(a){return J.aO(a).ga6(a)},
yR(a){return J.aO(a).gal(a)},
U(a){return J.bx(a).gJ(a)},
b1(a){return J.aO(a).gm(a)},
yS(a){return J.a3(a).gaz(a)},
el(a,b,c){return J.bx(a).bU(a,b,c)},
CP(a,b){return J.a3(a).W(a,b)},
yT(a,b){return J.bx(a).Z(a,b)},
CQ(a,b,c){return J.f5(a).b8(a,b,c)},
CR(a,b){return J.aO(a).sm(a,b)},
lB(a,b){return J.bx(a).bL(a,b)},
CS(a,b){return J.f5(a).aN(a,b)},
CT(a,b){return J.f5(a).a0(a,b)},
CU(a,b){return J.f5(a).L(a,b)},
CV(a,b){return J.bx(a).lE(a,b)},
CW(a){return J.iV(a).aA(a)},
wY(a){return J.bx(a).cZ(a)},
CX(a,b){return J.iV(a).ac(a,b)},
L(a){return J.a3(a).B(a)},
yU(a){return J.f5(a).R(a)},
CY(a,b){return J.bx(a).iq(a,b)},
hK:function hK(){},
jT:function jT(){},
hM:function hM(){},
hN:function hN(){},
dQ:function dQ(){},
kf:function kf(){},
e0:function e0(){},
da:function da(){},
fp:function fp(){},
fq:function fq(){},
w:function w(a){this.$ti=a},
nV:function nV(a){this.$ti=a},
d2:function d2(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
eA:function eA(){},
hL:function hL(){},
jU:function jU(){},
dO:function dO(){}},A={xg:function xg(){},
x0(a,b,c){if(b.i("M<0>").b(a))return new A.ij(a,b.i("@<0>").U(c).i("ij<1,2>"))
return new A.em(a,b.i("@<0>").U(c).i("em<1,2>"))},
wa(a){var s,r=a^48
if(r<=9)return r
s=a|32
if(97<=s&&s<=102)return s-87
return-1},
dj(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
q2(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
eg(a,b,c){return a},
yo(a){var s,r
for(s=$.c5.length,r=0;r<s;++r)if(a===$.c5[r])return!0
return!1},
dg(a,b,c,d){A.bE(b,"start")
if(c!=null){A.bE(c,"end")
if(b>c)A.a4(A.aK(b,0,c,"start",null))}return new A.eD(a,b,c,d.i("eD<0>"))},
ft(a,b,c,d){if(t.ez.b(a))return new A.er(a,b,c.i("@<0>").U(d).i("er<1,2>"))
return new A.bU(a,b,c.i("@<0>").U(d).i("bU<1,2>"))},
zR(a,b,c){var s="count"
if(t.ez.b(a)){A.lC(b,s,t.S)
A.bE(b,s)
return new A.ff(a,b,c.i("ff<0>"))}A.lC(b,s,t.S)
A.bE(b,s)
return new A.de(a,b,c.i("de<0>"))},
cP(){return new A.fC("No element")},
zs(){return new A.fC("Too few elements")},
ea:function ea(){},
hu:function hu(a,b){this.a=a
this.$ti=b},
em:function em(a,b){this.a=a
this.$ti=b},
ij:function ij(a,b){this.a=a
this.$ti=b},
ih:function ih(){},
bd:function bd(a,b){this.a=a
this.$ti=b},
d5:function d5(a,b){this.a=a
this.$ti=b},
m7:function m7(a,b){this.a=a
this.b=b},
m6:function m6(a,b){this.a=a
this.b=b},
m5:function m5(a){this.a=a},
m8:function m8(a,b){this.a=a
this.b=b},
db:function db(a){this.a=a},
eo:function eo(a){this.a=a},
pE:function pE(){},
M:function M(){},
ad:function ad(){},
eD:function eD(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.$ti=d},
be:function be(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
bU:function bU(a,b,c){this.a=a
this.b=b
this.$ti=c},
er:function er(a,b,c){this.a=a
this.b=b
this.$ti=c},
aS:function aS(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
a1:function a1(a,b,c){this.a=a
this.b=b
this.$ti=c},
an:function an(a,b,c){this.a=a
this.b=b
this.$ti=c},
dq:function dq(a,b,c){this.a=a
this.b=b
this.$ti=c},
de:function de(a,b,c){this.a=a
this.b=b
this.$ti=c},
ff:function ff(a,b,c){this.a=a
this.b=b
this.$ti=c},
hZ:function hZ(a,b,c){this.a=a
this.b=b
this.$ti=c},
es:function es(a){this.$ti=a},
hD:function hD(a){this.$ti=a},
ae:function ae(a,b){this.a=a
this.$ti=b},
aQ:function aQ(a,b){this.a=a
this.$ti=b},
aI:function aI(){},
e1:function e1(){},
fN:function fN(){},
hX:function hX(a,b){this.a=a
this.$ti=b},
dh:function dh(a){this.a=a},
iJ:function iJ(){},
mL(){throw A.i(A.aV("Cannot modify unmodifiable Map"))},
D7(){throw A.i(A.aV("Cannot modify constant Set"))},
C2(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
IM(a,b){var s
if(b!=null){s=b.x
if(s!=null)return s}return t.yP.b(a)},
p(a){var s
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
s=J.L(a)
return s},
a8(a,b,c,d,e,f){var s
A.h(b)
s=t.j
return new A.fo(a,A.v(c),s.a(d),s.a(e),A.v(f))},
Lw(a,b,c,d,e,f){var s
A.h(b)
s=t.j
return new A.fo(a,A.v(c),s.a(d),s.a(e),A.v(f))},
hU(a){var s,r=$.zG
if(r==null)r=$.zG=Symbol("identityHashCode")
s=a[r]
if(s==null){s=Math.random()*0x3fffffff|0
a[r]=s}return s},
V(a,b){var s,r,q,p,o,n=null,m=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(m==null)return n
if(3>=m.length)return A.d(m,3)
s=m[3]
if(b==null){if(s!=null)return parseInt(a,10)
if(m[2]!=null)return parseInt(a,16)
return n}if(b<2||b>36)throw A.i(A.aK(b,2,36,"radix",n))
if(b===10&&s!=null)return parseInt(a,10)
if(b<10||s==null){r=b<=10?47+b:86+b
q=m[1]
for(p=q.length,o=0;o<p;++o)if((q.charCodeAt(o)|32)>r)return n}return parseInt(a,b)},
bg(a){var s,r
if(!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(a))return null
s=parseFloat(a)
if(isNaN(s)){r=B.b.R(a)
if(r==="NaN"||r==="+NaN"||r==="-NaN")return s
return null}return s},
oN(a){return A.DU(a)},
DU(a){var s,r,q,p
if(a instanceof A.J)return A.bj(A.b3(a),null)
s=J.a3(a)
if(s===B.cl||s===B.cn||t.qF.b(a)){r=B.aG(a)
if(r!=="Object"&&r!=="")return r
q=a.constructor
if(typeof q=="function"){p=q.name
if(typeof p=="string"&&p!=="Object"&&p!=="")return p}}return A.bj(A.b3(a),null)},
zH(a){if(a==null||typeof a=="number"||A.ef(a))return J.L(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.bq)return a.B(0)
if(a instanceof A.aW)return a.kB(!0)
return"Instance of '"+A.oN(a)+"'"},
DV(){return Date.now()},
E3(){var s,r
if($.oO!==0)return
$.oO=1000
if(typeof window=="undefined")return
s=window
if(s==null)return
if(!!s.dartUseDateNowForTicks)return
r=s.performance
if(r==null)return
if(typeof r.now!="function")return
$.oO=1e6
$.cd=new A.oM(r)},
zF(a){var s,r,q,p,o=a.length
if(o<=500)return String.fromCharCode.apply(null,a)
for(s="",r=0;r<o;r=q){q=r+500
p=q<o?q:o
s+=String.fromCharCode.apply(null,a.slice(r,p))}return s},
E4(a){var s,r,q,p=A.a([],t.X)
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.k)(a),++r){q=a[r]
if(!A.cI(q))throw A.i(A.f3(q))
if(q<=65535)B.a.k(p,q)
else if(q<=1114111){B.a.k(p,55296+(B.d.cn(q-65536,10)&1023))
B.a.k(p,56320+(q&1023))}else throw A.i(A.f3(q))}return A.zF(p)},
zI(a){var s,r,q
for(s=a.length,r=0;r<s;++r){q=a[r]
if(!A.cI(q))throw A.i(A.f3(q))
if(q<0)throw A.i(A.f3(q))
if(q>65535)return A.E4(a)}return A.zF(a)},
E5(a,b,c){var s,r,q,p
if(c<=500&&b===0&&c===a.length)return String.fromCharCode.apply(null,a)
for(s=b,r="";s<c;s=q){q=s+500
p=q<c?q:c
r+=String.fromCharCode.apply(null,a.subarray(s,p))}return r},
W(a){var s
if(0<=a){if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){s=a-65536
return String.fromCharCode((B.d.cn(s,10)|55296)>>>0,s&1023|56320)}}throw A.i(A.aK(a,0,1114111,null,null))},
bX(a){if(a.date===void 0)a.date=new Date(a.a)
return a.date},
E2(a){return a.c?A.bX(a).getUTCFullYear()+0:A.bX(a).getFullYear()+0},
E0(a){return a.c?A.bX(a).getUTCMonth()+1:A.bX(a).getMonth()+1},
DX(a){return a.c?A.bX(a).getUTCDate()+0:A.bX(a).getDate()+0},
DY(a){return a.c?A.bX(a).getUTCHours()+0:A.bX(a).getHours()+0},
E_(a){return a.c?A.bX(a).getUTCMinutes()+0:A.bX(a).getMinutes()+0},
E1(a){return a.c?A.bX(a).getUTCSeconds()+0:A.bX(a).getSeconds()+0},
DZ(a){return a.c?A.bX(a).getUTCMilliseconds()+0:A.bX(a).getMilliseconds()+0},
dV(a,b,c){var s,r,q={}
q.a=0
s=[]
r=[]
q.a=b.length
B.a.H(s,b)
q.b=""
if(c!=null&&c.a!==0)c.O(0,new A.oL(q,r,s))
return J.CP(a,new A.fo(B.my,0,s,r,0))},
xq(a,b,c){var s,r,q=c==null||c.a===0
if(q){s=b.length
if(s===0){if(!!a.$0)return a.$0()}else if(s===1){if(!!a.$1)return a.$1(b[0])}else if(s===2){if(!!a.$2)return a.$2(b[0],b[1])}else if(s===3){if(!!a.$3)return a.$3(b[0],b[1],b[2])}else if(s===4){if(!!a.$4)return a.$4(b[0],b[1],b[2],b[3])}else if(s===5)if(!!a.$5)return a.$5(b[0],b[1],b[2],b[3],b[4])
r=a[""+"$"+s]
if(r!=null)return r.apply(a,b)}return A.DT(a,b,c)},
DT(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=b.length,e=a.$R
if(f<e)return A.dV(a,b,c)
s=a.$D
r=s==null
q=!r?s():null
p=J.a3(a)
o=p.$C
if(typeof o=="string")o=p[o]
if(r){if(c!=null&&c.a!==0)return A.dV(a,b,c)
if(f===e)return o.apply(a,b)
return A.dV(a,b,c)}if(Array.isArray(q)){if(c!=null&&c.a!==0)return A.dV(a,b,c)
n=e+q.length
if(f>n)return A.dV(a,b,null)
if(f<n){m=q.slice(f-e)
l=A.N(b,!0,t.z)
B.a.H(l,m)}else l=b
return o.apply(a,l)}else{if(f>e)return A.dV(a,b,c)
l=A.N(b,!0,t.z)
k=Object.keys(q)
if(c==null)for(r=k.length,j=0;j<k.length;k.length===r||(0,A.k)(k),++j){i=q[A.h(k[j])]
if(B.aK===i)return A.dV(a,l,c)
B.a.k(l,i)}else{for(r=k.length,h=0,j=0;j<k.length;k.length===r||(0,A.k)(k),++j){g=A.h(k[j])
if(c.p(g)){++h
B.a.k(l,c.h(0,g))}else{i=q[g]
if(B.aK===i)return A.dV(a,l,c)
B.a.k(l,i)}}if(h!==c.a)return A.dV(a,l,c)}return o.apply(a,l)}},
DW(a){var s=a.$thrownJsError
if(s==null)return null
return A.cJ(s)},
zJ(a,b){var s
if(a.$thrownJsError==null){s=A.i(a)
a.$thrownJsError=s
s.stack=b.B(0)}},
ym(a){throw A.i(A.f3(a))},
d(a,b){if(a==null)J.b1(a)
throw A.i(A.iS(a,b))},
iS(a,b){var s,r="index"
if(!A.cI(b))return new A.cp(!0,b,r,null)
s=A.v(J.b1(a))
if(b<0||b>=s)return A.nP(b,s,a,r)
return A.ki(b,r)},
f3(a){return new A.cp(!0,a,null,null)},
i(a){return A.BK(new Error(),a)},
BK(a,b){var s
if(b==null)b=new A.dl()
a.dartException=b
s=A.Kn
if("defineProperty" in Object){Object.defineProperty(a,"message",{get:s})
a.name=""}else a.toString=s
return a},
Kn(){return J.L(this.dartException)},
a4(a){throw A.i(a)},
lt(a,b){throw A.BK(b,a)},
ak(a,b,c){var s
if(b==null)b=0
if(c==null)c=0
s=Error()
A.lt(A.G7(a,b,c),s)},
G7(a,b,c){var s,r,q,p,o,n,m,l,k
if(typeof b=="string")s=b
else{r="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
q=r.length
p=b
if(p>q){c=p/q|0
p%=q}s=r[p]}o=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
n=t.j.b(a)?"list":"ByteData"
m=a.$flags|0
l="a "
if((m&4)!==0)k="constant "
else if((m&2)!==0){k="unmodifiable "
l="an "}else k=(m&1)!==0?"fixed-length ":""
return new A.i5("'"+s+"': Cannot "+o+" "+l+k+n)},
k(a){throw A.i(A.aD(a))},
dm(a){var s,r,q,p,o,n
a=A.BX(a.replace(String({}),"$receiver$"))
s=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(s==null)s=A.a([],t.s)
r=s.indexOf("\\$arguments\\$")
q=s.indexOf("\\$argumentsExpr\\$")
p=s.indexOf("\\$expr\\$")
o=s.indexOf("\\$method\\$")
n=s.indexOf("\\$receiver\\$")
return new A.t4(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),r,q,p,o,n)},
t5(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(s){return s.message}}(a)},
Al(a){return function($expr$){try{$expr$.$method$}catch(s){return s.message}}(a)},
xh(a,b){var s=b==null,r=s?null:b.method
return new A.jV(a,r,s?null:b.receiver)},
bk(a){var s
if(a==null)return new A.or(a)
if(a instanceof A.hE){s=a.a
return A.eh(a,s==null?t.K.a(s):s)}if(typeof a!=="object")return a
if("dartException" in a)return A.eh(a,a.dartException)
return A.HD(a)},
eh(a,b){if(t.yt.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
HD(a){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(!("message" in a))return a
s=a.message
if("number" in a&&typeof a.number=="number"){r=a.number
q=r&65535
if((B.d.cn(r,16)&8191)===10)switch(q){case 438:return A.eh(a,A.xh(A.p(s)+" (Error "+q+")",null))
case 445:case 5007:A.p(s)
return A.eh(a,new A.hT())}}if(a instanceof TypeError){p=$.Ce()
o=$.Cf()
n=$.Cg()
m=$.Ch()
l=$.Ck()
k=$.Cl()
j=$.Cj()
$.Ci()
i=$.Cn()
h=$.Cm()
g=p.bV(s)
if(g!=null)return A.eh(a,A.xh(A.h(s),g))
else{g=o.bV(s)
if(g!=null){g.method="call"
return A.eh(a,A.xh(A.h(s),g))}else if(n.bV(s)!=null||m.bV(s)!=null||l.bV(s)!=null||k.bV(s)!=null||j.bV(s)!=null||m.bV(s)!=null||i.bV(s)!=null||h.bV(s)!=null){A.h(s)
return A.eh(a,new A.hT())}}return A.eh(a,new A.kF(typeof s=="string"?s:""))}if(a instanceof RangeError){if(typeof s=="string"&&s.indexOf("call stack")!==-1)return new A.i_()
s=function(b){try{return String(b)}catch(f){}return null}(a)
return A.eh(a,new A.cp(!1,null,null,typeof s=="string"?s.replace(/^RangeError:\s*/,""):s))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof s=="string"&&s==="too much recursion")return new A.i_()
return a},
cJ(a){var s
if(a instanceof A.hE)return a.b
if(a==null)return new A.iy(a)
s=a.$cachedTrace
if(s!=null)return s
s=new A.iy(a)
if(typeof a==="object")a.$cachedTrace=s
return s},
ls(a){if(a==null)return J.b4(a)
if(typeof a=="object")return A.hU(a)
return J.b4(a)},
I4(a){if(typeof a=="number")return B.f.ga3(a)
if(a instanceof A.iz)return A.hU(a)
if(a instanceof A.aW)return a.ga3(a)
if(a instanceof A.dh)return a.ga3(0)
return A.ls(a)},
Ij(a,b){var s,r,q,p=a.length
for(s=0;s<p;s=q){r=s+1
q=r+1
b.j(0,a[s],a[r])}return b},
Ik(a,b){var s,r=a.length
for(s=0;s<r;++s)b.k(0,a[s])
return b},
GL(a,b,c,d,e,f){t.BO.a(a)
switch(A.v(b)){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.i(A.hF("Unsupported number of arguments for wrapped closure"))},
hh(a,b){var s=a.$identity
if(!!s)return s
s=A.I5(a,b)
a.$identity=s
return s},
I5(a,b){var s
switch(b){case 0:s=a.$0
break
case 1:s=a.$1
break
case 2:s=a.$2
break
case 3:s=a.$3
break
case 4:s=a.$4
break
default:s=null}if(s!=null)return s.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.GL)},
D6(a2){var s,r,q,p,o,n,m,l,k,j,i=a2.co,h=a2.iS,g=a2.iI,f=a2.nDA,e=a2.aI,d=a2.fs,c=a2.cs,b=d[0],a=c[0],a0=i[b],a1=a2.fT
a1.toString
s=h?Object.create(new A.ks().constructor.prototype):Object.create(new A.fa(null,null).constructor.prototype)
s.$initialize=s.constructor
r=h?function static_tear_off(){this.$initialize()}:function tear_off(a3,a4){this.$initialize(a3,a4)}
s.constructor=r
r.prototype=s
s.$_name=b
s.$_target=a0
q=!h
if(q)p=A.z3(b,a0,g,f)
else{s.$static_name=b
p=a0}s.$S=A.D2(a1,h,g)
s[a]=p
for(o=p,n=1;n<d.length;++n){m=d[n]
if(typeof m=="string"){l=i[m]
k=m
m=l}else k=""
j=c[n]
if(j!=null){if(q)m=A.z3(k,m,g,f)
s[j]=m}if(n===e)o=m}s.$C=o
s.$R=a2.rC
s.$D=a2.dV
return r},
D2(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.i("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.CZ)}throw A.i("Error in functionType of tearoff")},
D3(a,b,c,d){var s=A.z_
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,s)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,s)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,s)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,s)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,s)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,s)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,s)}},
z3(a,b,c,d){if(c)return A.D5(a,b,d)
return A.D3(b.length,d,a,b)},
D4(a,b,c,d){var s=A.z_,r=A.D_
switch(b?-1:a){case 0:throw A.i(new A.km("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,r,s)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,r,s)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,r,s)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,r,s)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,r,s)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,r,s)
default:return function(e,f,g){return function(){var q=[g(this)]
Array.prototype.push.apply(q,arguments)
return e.apply(f(this),q)}}(d,r,s)}},
D5(a,b,c){var s,r
if($.yY==null)$.yY=A.yX("interceptor")
if($.yZ==null)$.yZ=A.yX("receiver")
s=b.length
r=A.D4(s,c,a,b)
return r},
yf(a){return A.D6(a)},
CZ(a,b){return A.iE(v.typeUniverse,A.b3(a.a),b)},
z_(a){return a.a},
D_(a){return a.b},
yX(a){var s,r,q,p=new A.fa("receiver","interceptor"),o=Object.getOwnPropertyNames(p)
o.$flags=1
s=o
for(o=s.length,r=0;r<o;++r){q=s[r]
if(p[q]===a)return q}throw A.i(A.au("Field name "+a+" not found.",null))},
ac(a){if(a==null)A.HI("boolean expression must not be null")
return a},
HI(a){throw A.i(new A.kX(a))},
LH(a){throw A.i(new A.l1(a))},
Ir(a){return v.getIsolateTag(a)},
DL(a,b,c){var s=new A.cx(a,b,c.i("cx<0>"))
s.c=a.e
return s},
Lz(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
Jf(a){var s,r,q,p,o,n=A.h($.BJ.$1(a)),m=$.vI[n]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.wi[n]
if(s!=null)return s
r=v.interceptorsByTag[n]
if(r==null){q=A.m($.Bv.$2(a,n))
if(q!=null){m=$.vI[q]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.wi[q]
if(s!=null)return s
r=v.interceptorsByTag[q]
n=q}}if(r==null)return null
s=r.prototype
p=n[0]
if(p==="!"){m=A.wr(s)
$.vI[n]=m
Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}if(p==="~"){$.wi[n]=s
return s}if(p==="-"){o=A.wr(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}if(p==="+")return A.BU(a,s)
if(p==="*")throw A.i(A.xK(n))
if(v.leafTags[n]===true){o=A.wr(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}else return A.BU(a,s)},
BU(a,b){var s=Object.getPrototypeOf(a)
Object.defineProperty(s,v.dispatchPropertyName,{value:J.yp(b,s,null,null),enumerable:false,writable:true,configurable:true})
return b},
wr(a){return J.yp(a,!1,null,!!a.$ibS)},
Jh(a,b,c){var s=b.prototype
if(v.leafTags[a]===true)return A.wr(s)
else return J.yp(s,c,null,null)},
IE(){if(!0===$.yn)return
$.yn=!0
A.IF()},
IF(){var s,r,q,p,o,n,m,l
$.vI=Object.create(null)
$.wi=Object.create(null)
A.ID()
s=v.interceptorsByTag
r=Object.getOwnPropertyNames(s)
if(typeof window!="undefined"){window
q=function(){}
for(p=0;p<r.length;++p){o=r[p]
n=$.BW.$1(o)
if(n!=null){m=A.Jh(o,s[o],n)
if(m!=null){Object.defineProperty(n,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
q.prototype=n}}}}for(p=0;p<r.length;++p){o=r[p]
if(/^[A-Za-z_]/.test(o)){l=s[o]
s["!"+o]=l
s["~"+o]=l
s["-"+o]=l
s["+"+o]=l
s["*"+o]=l}}},
ID(){var s,r,q,p,o,n,m=B.bY()
m=A.hg(B.bZ,A.hg(B.c_,A.hg(B.aH,A.hg(B.aH,A.hg(B.c0,A.hg(B.c1,A.hg(B.c2(B.aG),m)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){s=dartNativeDispatchHooksTransformer
if(typeof s=="function")s=[s]
if(Array.isArray(s))for(r=0;r<s.length;++r){q=s[r]
if(typeof q=="function")m=q(m)||m}}p=m.getTag
o=m.getUnknownTag
n=m.prototypeForTag
$.BJ=new A.wb(p)
$.Bv=new A.wc(o)
$.BW=new A.wd(n)},
hg(a,b){return a(b)||b},
Fe(a,b){var s,r
for(s=0;s<a.length;++s){r=a[s]
if(!(s<b.length))return A.d(b,s)
if(!J.A(r,b[s]))return!1}return!0},
I9(a,b){var s=b.length,r=v.rttc[""+s+";"+a]
if(r==null)return null
if(s===0)return r
if(s===r.length)return r.apply(null,b)
return r(b)},
xf(a,b,c,d,e,f){var s=b?"m":"",r=c?"":"i",q=d?"u":"",p=e?"s":"",o=f?"g":"",n=function(g,h){try{return new RegExp(g,h)}catch(m){return m}}(a,s+r+q+p+o)
if(n instanceof RegExp)return n
throw A.i(A.bc("Illegal RegExp pattern ("+String(n)+")",a,null))},
JU(a,b,c){var s
if(typeof b=="string")return a.indexOf(b,c)>=0
else if(b instanceof A.dP){s=B.b.L(a,c)
return b.b.test(s)}else return!J.wW(b,B.b.L(a,c)).ga6(0)},
yj(a){if(a.indexOf("$",0)>=0)return a.replace(/\$/g,"$$$$")
return a},
JX(a,b,c,d){var s=b.jN(a,d)
if(s==null)return a
return A.yt(a,s.b.index,s.gbw(),c)},
BX(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
O(a,b,c){var s
if(typeof b=="string")return A.JW(a,b,c)
if(b instanceof A.dP){s=b.gjZ()
s.lastIndex=0
return a.replace(s,A.yj(c))}return A.JV(a,b,c)},
JV(a,b,c){var s,r,q,p
for(s=J.wW(b,a),s=s.gJ(s),r=0,q="";s.l();){p=s.gq()
q=q+a.substring(r,p.gex())+c
r=p.gbw()}s=q+a.substring(r)
return s.charCodeAt(0)==0?s:s},
JW(a,b,c){var s,r,q
if(b===""){if(a==="")return c
s=a.length
r=""+c
for(q=0;q<s;++q)r=r+a[q]+c
return r.charCodeAt(0)==0?r:r}if(a.indexOf(b,0)<0)return a
if(a.length<500||c.indexOf("$",0)>=0)return a.split(b).join(c)
return a.replace(new RegExp(A.BX(b),"g"),A.yj(c))},
Bq(a){return a},
iY(a,b,c,d){var s,r,q,p,o,n,m
for(s=b.dU(0,a),s=new A.e9(s.a,s.b,s.c),r=t.he,q=0,p="";s.l();){o=s.d
if(o==null)o=r.a(o)
n=o.b
m=n.index
p=p+A.p(A.Bq(B.b.t(a,q,m)))+A.p(c.$1(o))
q=m+n[0].length}s=p+A.p(A.Bq(B.b.L(a,q)))
return s.charCodeAt(0)==0?s:s},
JY(a,b,c,d){var s,r,q,p
if(typeof b=="string"){s=a.indexOf(b,d)
if(s<0)return a
return A.yt(a,s,s+b.length,c)}if(b instanceof A.dP)return d===0?a.replace(b.b,A.yj(c)):A.JX(a,b,c,d)
r=J.CK(b,a,d)
q=r.gJ(r)
if(!q.l())return a
p=q.gq()
return B.b.bI(a,p.gex(),p.gbw(),c)},
yt(a,b,c,d){return a.substring(0,b)+d+a.substring(c)},
ao:function ao(a,b){this.a=a
this.b=b},
h5:function h5(a,b){this.a=a
this.b=b},
ba:function ba(a,b){this.a=a
this.b=b},
iv:function iv(a,b){this.a=a
this.b=b},
h6:function h6(a,b){this.a=a
this.b=b},
f_:function f_(a,b){this.a=a
this.b=b},
h7:function h7(a,b){this.a=a
this.b=b},
f0:function f0(a,b){this.a=a
this.b=b},
d0:function d0(a,b,c){this.a=a
this.b=b
this.c=c},
c3:function c3(a){this.a=a},
iw:function iw(a){this.a=a},
h8:function h8(a){this.a=a},
hx:function hx(a,b){this.a=a
this.$ti=b},
hw:function hw(){},
mM:function mM(a,b,c){this.a=a
this.b=b
this.c=c},
E:function E(a,b,c){this.a=a
this.b=b
this.$ti=c},
eW:function eW(a,b){this.a=a
this.$ti=b},
dv:function dv(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
fc:function fc(){},
al:function al(a,b,c){this.a=a
this.b=b
this.$ti=c},
et:function et(a,b){this.a=a
this.$ti=b},
jR:function jR(){},
ez:function ez(a,b){this.a=a
this.$ti=b},
fo:function fo(a,b,c,d,e){var _=this
_.a=a
_.c=b
_.d=c
_.e=d
_.f=e},
oM:function oM(a){this.a=a},
oL:function oL(a,b,c){this.a=a
this.b=b
this.c=c},
t4:function t4(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
hT:function hT(){},
jV:function jV(a,b,c){this.a=a
this.b=b
this.c=c},
kF:function kF(a){this.a=a},
or:function or(a){this.a=a},
hE:function hE(a,b){this.a=a
this.b=b},
iy:function iy(a){this.a=a
this.b=null},
bq:function bq(){},
jf:function jf(){},
jg:function jg(){},
kA:function kA(){},
ks:function ks(){},
fa:function fa(a,b){this.a=a
this.b=b},
l1:function l1(a){this.a=a},
km:function km(a){this.a=a},
kX:function kX(a){this.a=a},
u9:function u9(){},
bT:function bT(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
nX:function nX(a){this.a=a},
nW:function nW(a){this.a=a},
od:function od(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
as:function as(a,b){this.a=a
this.$ti=b},
cx:function cx(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
hO:function hO(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
wb:function wb(a){this.a=a},
wc:function wc(a){this.a=a},
wd:function wd(a){this.a=a},
aW:function aW(){},
c2:function c2(){},
h4:function h4(){},
ee:function ee(){},
dP:function dP(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
ip:function ip(a){this.b=a},
kW:function kW(a,b,c){this.a=a
this.b=b
this.c=c},
e9:function e9(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
i0:function i0(a,b){this.a=a
this.c=b},
lf:function lf(a,b,c){this.a=a
this.b=b
this.c=c},
lg:function lg(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
Km(a){A.lt(new A.db("Field '"+a+"' has been assigned during initialization."),new Error())},
c(){A.lt(new A.db("Field '' has not been initialized."),new Error())},
ai(){A.lt(new A.db("Field '' has already been initialized."),new Error())},
ei(){A.lt(new A.db("Field '' has been assigned during initialization."),new Error())},
l_(){var s=new A.tB()
return s.b=s},
tB:function tB(){this.b=null},
uE(a){return a},
DO(a){return new Int8Array(a)},
DP(a){return new Uint8Array(a)},
xo(a,b,c){return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
dy(a,b,c){if(a>>>0!==a||a>=c)throw A.i(A.iS(b,a))},
dT:function dT(){},
hR:function hR(){},
uj:function uj(a){this.a=a},
k2:function k2(){},
bf:function bf(){},
hQ:function hQ(){},
bV:function bV(){},
k3:function k3(){},
k4:function k4(){},
k5:function k5(){},
k6:function k6(){},
k7:function k7(){},
k8:function k8(){},
k9:function k9(){},
hS:function hS(){},
eC:function eC(){},
iq:function iq(){},
ir:function ir(){},
is:function is(){},
it:function it(){},
zO(a,b){var s=b.c
return s==null?b.c=A.xY(a,b.x,!0):s},
xt(a,b){var s=b.c
return s==null?b.c=A.iC(a,"cs",[b.x]):s},
zP(a){var s=a.w
if(s===6||s===7||s===8)return A.zP(a.x)
return s===12||s===13},
Eg(a){return a.as},
ys(a,b){var s,r=b.length
for(s=0;s<r;++s)if(!a[s].b(b[s]))return!1
return!0},
ax(a){return A.lj(v.typeUniverse,a,!1)},
II(a,b){var s,r,q,p,o
if(a==null)return null
s=b.y
r=a.Q
if(r==null)r=a.Q=new Map()
q=b.as
p=r.get(q)
if(p!=null)return p
o=A.dB(v.typeUniverse,a.x,s,0)
r.set(q,o)
return o},
dB(a1,a2,a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=a2.w
switch(a0){case 5:case 1:case 2:case 3:case 4:return a2
case 6:s=a2.x
r=A.dB(a1,s,a3,a4)
if(r===s)return a2
return A.AK(a1,r,!0)
case 7:s=a2.x
r=A.dB(a1,s,a3,a4)
if(r===s)return a2
return A.xY(a1,r,!0)
case 8:s=a2.x
r=A.dB(a1,s,a3,a4)
if(r===s)return a2
return A.AI(a1,r,!0)
case 9:q=a2.y
p=A.hd(a1,q,a3,a4)
if(p===q)return a2
return A.iC(a1,a2.x,p)
case 10:o=a2.x
n=A.dB(a1,o,a3,a4)
m=a2.y
l=A.hd(a1,m,a3,a4)
if(n===o&&l===m)return a2
return A.xW(a1,n,l)
case 11:k=a2.x
j=a2.y
i=A.hd(a1,j,a3,a4)
if(i===j)return a2
return A.AJ(a1,k,i)
case 12:h=a2.x
g=A.dB(a1,h,a3,a4)
f=a2.y
e=A.Hy(a1,f,a3,a4)
if(g===h&&e===f)return a2
return A.AH(a1,g,e)
case 13:d=a2.y
a4+=d.length
c=A.hd(a1,d,a3,a4)
o=a2.x
n=A.dB(a1,o,a3,a4)
if(c===d&&n===o)return a2
return A.xX(a1,n,c,!0)
case 14:b=a2.x
if(b<a4)return a2
a=a3[b-a4]
if(a==null)return a2
return a
default:throw A.i(A.j5("Attempted to substitute unexpected RTI kind "+a0))}},
hd(a,b,c,d){var s,r,q,p,o=b.length,n=A.un(o)
for(s=!1,r=0;r<o;++r){q=b[r]
p=A.dB(a,q,c,d)
if(p!==q)s=!0
n[r]=p}return s?n:b},
Hz(a,b,c,d){var s,r,q,p,o,n,m=b.length,l=A.un(m)
for(s=!1,r=0;r<m;r+=3){q=b[r]
p=b[r+1]
o=b[r+2]
n=A.dB(a,o,c,d)
if(n!==o)s=!0
l.splice(r,3,q,p,n)}return s?l:b},
Hy(a,b,c,d){var s,r=b.a,q=A.hd(a,r,c,d),p=b.b,o=A.hd(a,p,c,d),n=b.c,m=A.Hz(a,n,c,d)
if(q===r&&o===p&&m===n)return b
s=new A.l4()
s.a=q
s.b=o
s.c=m
return s},
a(a,b){a[v.arrayRti]=b
return a},
ln(a){var s=a.$S
if(s!=null){if(typeof s=="number")return A.Iv(s)
return a.$S()}return null},
IH(a,b){var s
if(A.zP(b))if(a instanceof A.bq){s=A.ln(a)
if(s!=null)return s}return A.b3(a)},
b3(a){if(a instanceof A.J)return A.u(a)
if(Array.isArray(a))return A.K(a)
return A.y7(J.a3(a))},
K(a){var s=a[v.arrayRti],r=t.n
if(s==null)return r
if(s.constructor!==r.constructor)return r
return s},
u(a){var s=a.$ti
return s!=null?s:A.y7(a)},
y7(a){var s=a.constructor,r=s.$ccache
if(r!=null)return r
return A.GH(a,s)},
GH(a,b){var s=a instanceof A.bq?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,r=A.Fr(v.typeUniverse,s.name)
b.$ccache=r
return r},
Iv(a){var s,r=v.types,q=r[a]
if(typeof q=="string"){s=A.lj(v.typeUniverse,q,!1)
r[a]=s
return s}return q},
iW(a){return A.cn(A.u(a))},
yl(a){var s=A.ln(a)
return A.cn(s==null?A.b3(a):s)},
yd(a){var s
if(a instanceof A.aW)return a.jS()
s=a instanceof A.bq?A.ln(a):null
if(s!=null)return s
if(t.sg.b(a))return J.yS(a).a
if(Array.isArray(a))return A.K(a)
return A.b3(a)},
cn(a){var s=a.r
return s==null?a.r=A.AZ(a):s},
AZ(a){var s,r,q=a.as,p=q.replace(/\*/g,"")
if(p===q)return a.r=new A.iz(a)
s=A.lj(v.typeUniverse,p,!0)
r=s.r
return r==null?s.r=A.AZ(s):r},
Ih(a,b){var s,r,q=b,p=q.length
if(p===0)return t.ep
if(0>=p)return A.d(q,0)
s=A.iE(v.typeUniverse,A.yd(q[0]),"@<0>")
for(r=1;r<p;++r){if(!(r<q.length))return A.d(q,r)
s=A.AL(v.typeUniverse,s,A.yd(q[r]))}return A.iE(v.typeUniverse,s,a)},
co(a){return A.cn(A.lj(v.typeUniverse,a,!1))},
GG(a){var s,r,q,p,o,n,m=this
if(m===t.K)return A.dz(m,a,A.GQ)
if(!A.dC(m))s=m===t.tw
else s=!0
if(s)return A.dz(m,a,A.GW)
s=m.w
if(s===7)return A.dz(m,a,A.Gg)
if(s===1)return A.dz(m,a,A.Ba)
r=s===6?m.x:m
q=r.w
if(q===8)return A.dz(m,a,A.GM)
if(r===t.S)p=A.cI
else if(r===t.pR||r===t.fY)p=A.GP
else if(r===t.N)p=A.GU
else p=r===t.v?A.ef:null
if(p!=null)return A.dz(m,a,p)
if(q===9){o=r.x
if(r.y.every(A.IK)){m.f="$i"+o
if(o==="t")return A.dz(m,a,A.GO)
return A.dz(m,a,A.GV)}}else if(q===11){n=A.I9(r.x,r.y)
return A.dz(m,a,n==null?A.Ba:n)}return A.dz(m,a,A.Ge)},
dz(a,b,c){a.b=c
return a.b(b)},
GF(a){var s,r=this,q=A.Gd
if(!A.dC(r))s=r===t.tw
else s=!0
if(s)q=A.FN
else if(r===t.K)q=A.FM
else{s=A.iX(r)
if(s)q=A.Gf}r.a=q
return r.a(a)},
ll(a){var s=a.w,r=!0
if(!A.dC(a))if(!(a===t.tw))if(!(a===t.g5))if(s!==7)if(!(s===6&&A.ll(a.x)))r=s===8&&A.ll(a.x)||a===t.b||a===t.Be
return r},
Ge(a){var s=this
if(a==null)return A.ll(s)
return A.BN(v.typeUniverse,A.IH(a,s),s)},
Gg(a){if(a==null)return!0
return this.x.b(a)},
GV(a){var s,r=this
if(a==null)return A.ll(r)
s=r.f
if(a instanceof A.J)return!!a[s]
return!!J.a3(a)[s]},
GO(a){var s,r=this
if(a==null)return A.ll(r)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
s=r.f
if(a instanceof A.J)return!!a[s]
return!!J.a3(a)[s]},
Gd(a){var s=this
if(a==null){if(A.iX(s))return a}else if(s.b(a))return a
A.B1(a,s)},
Gf(a){var s=this
if(a==null)return a
else if(s.b(a))return a
A.B1(a,s)},
B1(a,b){throw A.i(A.AG(A.Ay(a,A.bj(b,null))))},
lm(a,b,c,d){if(A.BN(v.typeUniverse,a,b))return a
throw A.i(A.AG("The type argument '"+A.bj(a,null)+"' is not a subtype of the type variable bound '"+A.bj(b,null)+"' of type variable '"+c+"' in '"+d+"'."))},
Ay(a,b){return A.dH(a)+": type '"+A.bj(A.yd(a),null)+"' is not a subtype of type '"+b+"'"},
AG(a){return new A.iA("TypeError: "+a)},
bv(a,b){return new A.iA("TypeError: "+A.Ay(a,b))},
GM(a){var s=this,r=s.w===6?s.x:s
return r.x.b(a)||A.xt(v.typeUniverse,r).b(a)},
GQ(a){return a!=null},
FM(a){if(a!=null)return a
throw A.i(A.bv(a,"Object"))},
GW(a){return!0},
FN(a){return a},
Ba(a){return!1},
ef(a){return!0===a||!1===a},
I(a){if(!0===a)return!0
if(!1===a)return!1
throw A.i(A.bv(a,"bool"))},
La(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.i(A.bv(a,"bool"))},
f1(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.i(A.bv(a,"bool?"))},
a9(a){if(typeof a=="number")return a
throw A.i(A.bv(a,"double"))},
Lb(a){if(typeof a=="number")return a
if(a==null)return a
throw A.i(A.bv(a,"double"))},
FL(a){if(typeof a=="number")return a
if(a==null)return a
throw A.i(A.bv(a,"double?"))},
cI(a){return typeof a=="number"&&Math.floor(a)===a},
v(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.i(A.bv(a,"int"))},
Lc(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.i(A.bv(a,"int"))},
lk(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.i(A.bv(a,"int?"))},
GP(a){return typeof a=="number"},
aF(a){if(typeof a=="number")return a
throw A.i(A.bv(a,"num"))},
Ld(a){if(typeof a=="number")return a
if(a==null)return a
throw A.i(A.bv(a,"num"))},
y0(a){if(typeof a=="number")return a
if(a==null)return a
throw A.i(A.bv(a,"num?"))},
GU(a){return typeof a=="string"},
h(a){if(typeof a=="string")return a
throw A.i(A.bv(a,"String"))},
Le(a){if(typeof a=="string")return a
if(a==null)return a
throw A.i(A.bv(a,"String"))},
m(a){if(typeof a=="string")return a
if(a==null)return a
throw A.i(A.bv(a,"String?"))},
Bl(a,b){var s,r,q
for(s="",r="",q=0;q<a.length;++q,r=", ")s+=r+A.bj(a[q],b)
return s},
Hi(a,b){var s,r,q,p,o,n,m=a.x,l=a.y
if(""===m)return"("+A.Bl(l,b)+")"
s=l.length
r=m.split(",")
q=r.length-s
for(p="(",o="",n=0;n<s;++n,o=", "){p+=o
if(q===0)p+="{"
p+=A.bj(l[n],b)
if(q>=0)p+=" "+r[q];++q}return p+"})"},
B3(a4,a5,a6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=", ",a3=null
if(a6!=null){s=a6.length
if(a5==null)a5=A.a([],t.s)
else a3=a5.length
r=a5.length
for(q=s;q>0;--q)B.a.k(a5,"T"+(r+q))
for(p=t.dy,o=t.tw,n="<",m="",q=0;q<s;++q,m=a2){l=a5.length
k=l-1-q
if(!(k>=0))return A.d(a5,k)
n=n+m+a5[k]
j=a6[q]
i=j.w
if(!(i===2||i===3||i===4||i===5||j===p))l=j===o
else l=!0
if(!l)n+=" extends "+A.bj(j,a5)}n+=">"}else n=""
p=a4.x
h=a4.y
g=h.a
f=g.length
e=h.b
d=e.length
c=h.c
b=c.length
a=A.bj(p,a5)
for(a0="",a1="",q=0;q<f;++q,a1=a2)a0+=a1+A.bj(g[q],a5)
if(d>0){a0+=a1+"["
for(a1="",q=0;q<d;++q,a1=a2)a0+=a1+A.bj(e[q],a5)
a0+="]"}if(b>0){a0+=a1+"{"
for(a1="",q=0;q<b;q+=3,a1=a2){a0+=a1
if(c[q+1])a0+="required "
a0+=A.bj(c[q+2],a5)+" "+c[q]}a0+="}"}if(a3!=null){a5.toString
a5.length=a3}return n+"("+a0+") => "+a},
bj(a,b){var s,r,q,p,o,n,m,l=a.w
if(l===5)return"erased"
if(l===2)return"dynamic"
if(l===3)return"void"
if(l===1)return"Never"
if(l===4)return"any"
if(l===6)return A.bj(a.x,b)
if(l===7){s=a.x
r=A.bj(s,b)
q=s.w
return(q===12||q===13?"("+r+")":r)+"?"}if(l===8)return"FutureOr<"+A.bj(a.x,b)+">"
if(l===9){p=A.HC(a.x)
o=a.y
return o.length>0?p+("<"+A.Bl(o,b)+">"):p}if(l===11)return A.Hi(a,b)
if(l===12)return A.B3(a,b,null)
if(l===13)return A.B3(a.x,b,a.y)
if(l===14){n=a.x
m=b.length
n=m-1-n
if(!(n>=0&&n<m))return A.d(b,n)
return b[n]}return"?"},
HC(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
Fs(a,b){var s=a.tR[b]
for(;typeof s=="string";)s=a.tR[s]
return s},
Fr(a,b){var s,r,q,p,o,n=a.eT,m=n[b]
if(m==null)return A.lj(a,b,!1)
else if(typeof m=="number"){s=m
r=A.iD(a,5,"#")
q=A.un(s)
for(p=0;p<s;++p)q[p]=r
o=A.iC(a,b,q)
n[b]=o
return o}else return m},
Fq(a,b){return A.AT(a.tR,b)},
Fp(a,b){return A.AT(a.eT,b)},
lj(a,b,c){var s,r=a.eC,q=r.get(b)
if(q!=null)return q
s=A.AD(A.AB(a,null,b,c))
r.set(b,s)
return s},
iE(a,b,c){var s,r,q=b.z
if(q==null)q=b.z=new Map()
s=q.get(c)
if(s!=null)return s
r=A.AD(A.AB(a,b,c,!0))
q.set(c,r)
return r},
AL(a,b,c){var s,r,q,p=b.Q
if(p==null)p=b.Q=new Map()
s=c.as
r=p.get(s)
if(r!=null)return r
q=A.xW(a,b,c.w===10?c.y:[c])
p.set(s,q)
return q},
dx(a,b){b.a=A.GF
b.b=A.GG
return b},
iD(a,b,c){var s,r,q=a.eC.get(c)
if(q!=null)return q
s=new A.ce(null,null)
s.w=b
s.as=c
r=A.dx(a,s)
a.eC.set(c,r)
return r},
AK(a,b,c){var s,r=b.as+"*",q=a.eC.get(r)
if(q!=null)return q
s=A.Fn(a,b,r,c)
a.eC.set(r,s)
return s},
Fn(a,b,c,d){var s,r,q
if(d){s=b.w
if(!A.dC(b))r=b===t.b||b===t.Be||s===7||s===6
else r=!0
if(r)return b}q=new A.ce(null,null)
q.w=6
q.x=b
q.as=c
return A.dx(a,q)},
xY(a,b,c){var s,r=b.as+"?",q=a.eC.get(r)
if(q!=null)return q
s=A.Fm(a,b,r,c)
a.eC.set(r,s)
return s},
Fm(a,b,c,d){var s,r,q,p
if(d){s=b.w
r=!0
if(!A.dC(b))if(!(b===t.b||b===t.Be))if(s!==7)r=s===8&&A.iX(b.x)
if(r)return b
else if(s===1||b===t.g5)return t.b
else if(s===6){q=b.x
if(q.w===8&&A.iX(q.x))return q
else return A.zO(a,b)}}p=new A.ce(null,null)
p.w=7
p.x=b
p.as=c
return A.dx(a,p)},
AI(a,b,c){var s,r=b.as+"/",q=a.eC.get(r)
if(q!=null)return q
s=A.Fk(a,b,r,c)
a.eC.set(r,s)
return s},
Fk(a,b,c,d){var s,r
if(d){s=b.w
if(A.dC(b)||b===t.K||b===t.tw)return b
else if(s===1)return A.iC(a,"cs",[b])
else if(b===t.b||b===t.Be)return t.eZ}r=new A.ce(null,null)
r.w=8
r.x=b
r.as=c
return A.dx(a,r)},
Fo(a,b){var s,r,q=""+b+"^",p=a.eC.get(q)
if(p!=null)return p
s=new A.ce(null,null)
s.w=14
s.x=b
s.as=q
r=A.dx(a,s)
a.eC.set(q,r)
return r},
iB(a){var s,r,q,p=a.length
for(s="",r="",q=0;q<p;++q,r=",")s+=r+a[q].as
return s},
Fj(a){var s,r,q,p,o,n=a.length
for(s="",r="",q=0;q<n;q+=3,r=","){p=a[q]
o=a[q+1]?"!":":"
s+=r+p+o+a[q+2].as}return s},
iC(a,b,c){var s,r,q,p=b
if(c.length>0)p+="<"+A.iB(c)+">"
s=a.eC.get(p)
if(s!=null)return s
r=new A.ce(null,null)
r.w=9
r.x=b
r.y=c
if(c.length>0)r.c=c[0]
r.as=p
q=A.dx(a,r)
a.eC.set(p,q)
return q},
xW(a,b,c){var s,r,q,p,o,n
if(b.w===10){s=b.x
r=b.y.concat(c)}else{r=c
s=b}q=s.as+(";<"+A.iB(r)+">")
p=a.eC.get(q)
if(p!=null)return p
o=new A.ce(null,null)
o.w=10
o.x=s
o.y=r
o.as=q
n=A.dx(a,o)
a.eC.set(q,n)
return n},
AJ(a,b,c){var s,r,q="+"+(b+"("+A.iB(c)+")"),p=a.eC.get(q)
if(p!=null)return p
s=new A.ce(null,null)
s.w=11
s.x=b
s.y=c
s.as=q
r=A.dx(a,s)
a.eC.set(q,r)
return r},
AH(a,b,c){var s,r,q,p,o,n=b.as,m=c.a,l=m.length,k=c.b,j=k.length,i=c.c,h=i.length,g="("+A.iB(m)
if(j>0){s=l>0?",":""
g+=s+"["+A.iB(k)+"]"}if(h>0){s=l>0?",":""
g+=s+"{"+A.Fj(i)+"}"}r=n+(g+")")
q=a.eC.get(r)
if(q!=null)return q
p=new A.ce(null,null)
p.w=12
p.x=b
p.y=c
p.as=r
o=A.dx(a,p)
a.eC.set(r,o)
return o},
xX(a,b,c,d){var s,r=b.as+("<"+A.iB(c)+">"),q=a.eC.get(r)
if(q!=null)return q
s=A.Fl(a,b,c,r,d)
a.eC.set(r,s)
return s},
Fl(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e){s=c.length
r=A.un(s)
for(q=0,p=0;p<s;++p){o=c[p]
if(o.w===1){r[p]=o;++q}}if(q>0){n=A.dB(a,b,r,0)
m=A.hd(a,c,r,0)
return A.xX(a,n,m,c!==m)}}l=new A.ce(null,null)
l.w=13
l.x=b
l.y=c
l.as=d
return A.dx(a,l)},
AB(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
AD(a){var s,r,q,p,o,n,m,l=a.r,k=a.s
for(s=l.length,r=0;r<s;){q=l.charCodeAt(r)
if(q>=48&&q<=57)r=A.F9(r+1,q,l,k)
else if((((q|32)>>>0)-97&65535)<26||q===95||q===36||q===124)r=A.AC(a,r,l,k,!1)
else if(q===46)r=A.AC(a,r,l,k,!0)
else{++r
switch(q){case 44:break
case 58:k.push(!1)
break
case 33:k.push(!0)
break
case 59:k.push(A.ed(a.u,a.e,k.pop()))
break
case 94:k.push(A.Fo(a.u,k.pop()))
break
case 35:k.push(A.iD(a.u,5,"#"))
break
case 64:k.push(A.iD(a.u,2,"@"))
break
case 126:k.push(A.iD(a.u,3,"~"))
break
case 60:k.push(a.p)
a.p=k.length
break
case 62:A.Fb(a,k)
break
case 38:A.Fa(a,k)
break
case 42:p=a.u
k.push(A.AK(p,A.ed(p,a.e,k.pop()),a.n))
break
case 63:p=a.u
k.push(A.xY(p,A.ed(p,a.e,k.pop()),a.n))
break
case 47:p=a.u
k.push(A.AI(p,A.ed(p,a.e,k.pop()),a.n))
break
case 40:k.push(-3)
k.push(a.p)
a.p=k.length
break
case 41:A.F8(a,k)
break
case 91:k.push(a.p)
a.p=k.length
break
case 93:o=k.splice(a.p)
A.AE(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-1)
break
case 123:k.push(a.p)
a.p=k.length
break
case 125:o=k.splice(a.p)
A.Fd(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-2)
break
case 43:n=l.indexOf("(",r)
k.push(l.substring(r,n))
k.push(-4)
k.push(a.p)
a.p=k.length
r=n+1
break
default:throw"Bad character "+q}}}m=k.pop()
return A.ed(a.u,a.e,m)},
F9(a,b,c,d){var s,r,q=b-48
for(s=c.length;a<s;++a){r=c.charCodeAt(a)
if(!(r>=48&&r<=57))break
q=q*10+(r-48)}d.push(q)
return a},
AC(a,b,c,d,e){var s,r,q,p,o,n,m=b+1
for(s=c.length;m<s;++m){r=c.charCodeAt(m)
if(r===46){if(e)break
e=!0}else{if(!((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124))q=r>=48&&r<=57
else q=!0
if(!q)break}}p=c.substring(b,m)
if(e){s=a.u
o=a.e
if(o.w===10)o=o.x
n=A.Fs(s,o.x)[p]
if(n==null)A.a4('No "'+p+'" in "'+A.Eg(o)+'"')
d.push(A.iE(s,o,n))}else d.push(p)
return m},
Fb(a,b){var s,r=a.u,q=A.AA(a,b),p=b.pop()
if(typeof p=="string")b.push(A.iC(r,p,q))
else{s=A.ed(r,a.e,p)
switch(s.w){case 12:b.push(A.xX(r,s,q,a.n))
break
default:b.push(A.xW(r,s,q))
break}}},
F8(a,b){var s,r,q,p=a.u,o=b.pop(),n=null,m=null
if(typeof o=="number")switch(o){case-1:n=b.pop()
break
case-2:m=b.pop()
break
default:b.push(o)
break}else b.push(o)
s=A.AA(a,b)
o=b.pop()
switch(o){case-3:o=b.pop()
if(n==null)n=p.sEA
if(m==null)m=p.sEA
r=A.ed(p,a.e,o)
q=new A.l4()
q.a=s
q.b=n
q.c=m
b.push(A.AH(p,r,q))
return
case-4:b.push(A.AJ(p,b.pop(),s))
return
default:throw A.i(A.j5("Unexpected state under `()`: "+A.p(o)))}},
Fa(a,b){var s=b.pop()
if(0===s){b.push(A.iD(a.u,1,"0&"))
return}if(1===s){b.push(A.iD(a.u,4,"1&"))
return}throw A.i(A.j5("Unexpected extended operation "+A.p(s)))},
AA(a,b){var s=b.splice(a.p)
A.AE(a.u,a.e,s)
a.p=b.pop()
return s},
ed(a,b,c){if(typeof c=="string")return A.iC(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.Fc(a,b,c)}else return c},
AE(a,b,c){var s,r=c.length
for(s=0;s<r;++s)c[s]=A.ed(a,b,c[s])},
Fd(a,b,c){var s,r=c.length
for(s=2;s<r;s+=3)c[s]=A.ed(a,b,c[s])},
Fc(a,b,c){var s,r,q=b.w
if(q===10){if(c===0)return b.x
s=b.y
r=s.length
if(c<=r)return s[c-1]
c-=r
b=b.x
q=b.w}else if(c===0)return b
if(q!==9)throw A.i(A.j5("Indexed base must be an interface type"))
s=b.y
if(c<=s.length)return s[c-1]
throw A.i(A.j5("Bad index "+c+" for "+b.B(0)))},
BN(a,b,c){var s,r=b.d
if(r==null)r=b.d=new Map()
s=r.get(c)
if(s==null){s=A.aX(a,b,null,c,null,!1)?1:0
r.set(c,s)}if(0===s)return!1
if(1===s)return!0
return!0},
aX(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j,i
if(b===d)return!0
if(!A.dC(d))s=d===t.tw
else s=!0
if(s)return!0
r=b.w
if(r===4)return!0
if(A.dC(b))return!1
s=b.w
if(s===1)return!0
q=r===14
if(q)if(A.aX(a,c[b.x],c,d,e,!1))return!0
p=d.w
s=b===t.b||b===t.Be
if(s){if(p===8)return A.aX(a,b,c,d.x,e,!1)
return d===t.b||d===t.Be||p===7||p===6}if(d===t.K){if(r===8)return A.aX(a,b.x,c,d,e,!1)
if(r===6)return A.aX(a,b.x,c,d,e,!1)
return r!==7}if(r===6)return A.aX(a,b.x,c,d,e,!1)
if(p===6){s=A.zO(a,d)
return A.aX(a,b,c,s,e,!1)}if(r===8){if(!A.aX(a,b.x,c,d,e,!1))return!1
return A.aX(a,A.xt(a,b),c,d,e,!1)}if(r===7){s=A.aX(a,t.b,c,d,e,!1)
return s&&A.aX(a,b.x,c,d,e,!1)}if(p===8){if(A.aX(a,b,c,d.x,e,!1))return!0
return A.aX(a,b,c,A.xt(a,d),e,!1)}if(p===7){s=A.aX(a,b,c,t.b,e,!1)
return s||A.aX(a,b,c,d.x,e,!1)}if(q)return!1
s=r!==12
if((!s||r===13)&&d===t.BO)return!0
o=r===11
if(o&&d===t.op)return!0
if(p===13){if(b===t.g)return!0
if(r!==13)return!1
n=b.y
m=d.y
l=n.length
if(l!==m.length)return!1
c=c==null?n:n.concat(c)
e=e==null?m:m.concat(e)
for(k=0;k<l;++k){j=n[k]
i=m[k]
if(!A.aX(a,j,c,i,e,!1)||!A.aX(a,i,e,j,c,!1))return!1}return A.B9(a,b.x,c,d.x,e,!1)}if(p===12){if(b===t.g)return!0
if(s)return!1
return A.B9(a,b,c,d,e,!1)}if(r===9){if(p!==9)return!1
return A.GN(a,b,c,d,e,!1)}if(o&&p===11)return A.GR(a,b,c,d,e,!1)
return!1},
B9(a3,a4,a5,a6,a7,a8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
if(!A.aX(a3,a4.x,a5,a6.x,a7,!1))return!1
s=a4.y
r=a6.y
q=s.a
p=r.a
o=q.length
n=p.length
if(o>n)return!1
m=n-o
l=s.b
k=r.b
j=l.length
i=k.length
if(o+j<n+i)return!1
for(h=0;h<o;++h){g=q[h]
if(!A.aX(a3,p[h],a7,g,a5,!1))return!1}for(h=0;h<m;++h){g=l[h]
if(!A.aX(a3,p[o+h],a7,g,a5,!1))return!1}for(h=0;h<i;++h){g=l[m+h]
if(!A.aX(a3,k[h],a7,g,a5,!1))return!1}f=s.c
e=r.c
d=f.length
c=e.length
for(b=0,a=0;a<c;a+=3){a0=e[a]
for(;!0;){if(b>=d)return!1
a1=f[b]
b+=3
if(a0<a1)return!1
a2=f[b-2]
if(a1<a0){if(a2)return!1
continue}g=e[a+1]
if(a2&&!g)return!1
g=f[b-1]
if(!A.aX(a3,e[a+2],a7,g,a5,!1))return!1
break}}for(;b<d;){if(f[b+1])return!1
b+=3}return!0},
GN(a,b,c,d,e,f){var s,r,q,p,o,n=b.x,m=d.x
for(;n!==m;){s=a.tR[n]
if(s==null)return!1
if(typeof s=="string"){n=s
continue}r=s[m]
if(r==null)return!1
q=r.length
p=q>0?new Array(q):v.typeUniverse.sEA
for(o=0;o<q;++o)p[o]=A.iE(a,b,r[o])
return A.AU(a,p,null,c,d.y,e,!1)}return A.AU(a,b.y,null,c,d.y,e,!1)},
AU(a,b,c,d,e,f,g){var s,r=b.length
for(s=0;s<r;++s)if(!A.aX(a,b[s],d,e[s],f,!1))return!1
return!0},
GR(a,b,c,d,e,f){var s,r=b.y,q=d.y,p=r.length
if(p!==q.length)return!1
if(b.x!==d.x)return!1
for(s=0;s<p;++s)if(!A.aX(a,r[s],c,q[s],e,!1))return!1
return!0},
iX(a){var s=a.w,r=!0
if(!(a===t.b||a===t.Be))if(!A.dC(a))if(s!==7)if(!(s===6&&A.iX(a.x)))r=s===8&&A.iX(a.x)
return r},
IK(a){var s
if(!A.dC(a))s=a===t.tw
else s=!0
return s},
dC(a){var s=a.w
return s===2||s===3||s===4||s===5||a===t.dy},
AT(a,b){var s,r,q=Object.keys(b),p=q.length
for(s=0;s<p;++s){r=q[s]
a[r]=b[r]}},
un(a){return a>0?new Array(a):v.typeUniverse.sEA},
ce:function ce(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
l4:function l4(){this.c=this.b=this.a=null},
iz:function iz(a){this.a=a},
l3:function l3(){},
iA:function iA(a){this.a=a},
EX(){var s,r,q={}
if(self.scheduleImmediate!=null)return A.HJ()
if(self.MutationObserver!=null&&self.document!=null){s=self.document.createElement("div")
r=self.document.createElement("span")
q.a=null
new self.MutationObserver(A.hh(new A.tw(q),1)).observe(s,{childList:true})
return new A.tv(q,s,r)}else if(self.setImmediate!=null)return A.HK()
return A.HL()},
EY(a){self.scheduleImmediate(A.hh(new A.tx(t.R.a(a)),0))},
EZ(a){self.setImmediate(A.hh(new A.ty(t.R.a(a)),0))},
F_(a){A.xI(B.c9,t.R.a(a))},
xI(a,b){var s=B.d.bC(a.a,1000)
return A.Fi(s<0?0:s,b)},
Fi(a,b){var s=new A.li()
s.ns(a,b)
return s},
H0(a){return new A.kY(new A.aN($.aB,a.i("aN<0>")),a.i("kY<0>"))},
FR(a,b){a.$2(0,null)
b.b=!0
return b.a},
FO(a,b){A.FT(a,b)},
FQ(a,b){b.dW(a)},
FP(a,b){b.hv(A.bk(a),A.cJ(a))},
FT(a,b){var s,r,q=new A.up(b),p=new A.uq(b)
if(a instanceof A.aN)a.kA(q,p,t.z)
else{s=t.z
if(a instanceof A.aN)a.ii(q,p,s)
else{r=new A.aN($.aB,t.hR)
r.a=8
r.c=a
r.kA(q,p,s)}}},
HE(a){var s=function(b,c){return function(d,e){while(true){try{b(d,e)
break}catch(r){e=r
d=c}}}}(a,1)
return $.aB.lA(new A.vu(s),t.jW,t.S,t.z)},
AF(a,b,c){return 0},
wZ(a){var s
if(t.yt.b(a)){s=a.gdK()
if(s!=null)return s}return B.R},
Dq(a,b){var s=new A.aN($.aB,b.i("aN<0>"))
A.BZ(new A.nu(a,s))
return s},
B8(a,b){if($.aB===B.p)return null
return null},
GI(a,b){if($.aB!==B.p)A.B8(a,b)
if(b==null)if(t.yt.b(a)){b=a.gdK()
if(b==null){A.zJ(a,B.R)
b=B.R}}else b=B.R
else if(t.yt.b(a))A.zJ(a,b)
return new A.d3(a,b)},
xQ(a,b){var s,r,q
for(s=t.hR;r=a.a,(r&4)!==0;)a=s.a(a.c)
if(a===b){b.eD(new A.cp(!0,a,null,"Cannot complete a future with itself"),A.zS())
return}s=r|b.a&1
a.a=s
if((s&24)!==0){q=b.eN()
b.eG(a)
A.h0(b,q)}else{q=t.f7.a(b.c)
b.kp(a)
a.hj(q)}},
F4(a,b){var s,r,q,p={},o=p.a=a
for(s=t.hR;r=o.a,(r&4)!==0;o=a){a=s.a(o.c)
p.a=a}if(o===b){b.eD(new A.cp(!0,o,null,"Cannot complete a future with itself"),A.zS())
return}if((r&24)===0){q=t.f7.a(b.c)
b.kp(o)
p.a.hj(q)
return}if((r&16)===0&&b.c==null){b.eG(o)
return}b.a^=2
A.hc(null,null,b.b,t.R.a(new A.tN(p,b)))},
h0(a,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c={},b=c.a=a
for(s=t.Fq,r=t.f7,q=t.o0;!0;){p={}
o=b.a
n=(o&16)===0
m=!n
if(a0==null){if(m&&(o&1)===0){l=s.a(b.c)
A.yc(l.a,l.b)}return}p.a=a0
k=a0.a
for(b=a0;k!=null;b=k,k=j){b.a=null
A.h0(c.a,b)
p.a=k
j=k.a}o=c.a
i=o.c
p.b=m
p.c=i
if(n){h=b.c
h=(h&1)!==0||(h&15)===8}else h=!0
if(h){g=b.b.b
if(m){o=o.b===g
o=!(o||o)}else o=!1
if(o){s.a(i)
A.yc(i.a,i.b)
return}f=$.aB
if(f!==g)$.aB=g
else f=null
b=b.c
if((b&15)===8)new A.tU(p,c,m).$0()
else if(n){if((b&1)!==0)new A.tT(p,i).$0()}else if((b&2)!==0)new A.tS(c,p).$0()
if(f!=null)$.aB=f
b=p.c
if(b instanceof A.aN){o=p.a.$ti
o=o.i("cs<2>").b(b)||!o.y[1].b(b)}else o=!1
if(o){q.a(b)
e=p.a.b
if((b.a&24)!==0){d=r.a(e.c)
e.c=null
a0=e.eO(d)
e.a=b.a&30|e.a&1
e.c=b.c
c.a=b
continue}else A.xQ(b,e)
return}}e=p.a.b
d=r.a(e.c)
e.c=null
a0=e.eO(d)
b=p.b
o=p.c
if(!b){e.$ti.c.a(o)
e.a=8
e.c=o}else{s.a(o)
e.a=e.a&1|16
e.c=o}c.a=e
b=e}},
Hj(a,b){var s
if(t.nW.b(a))return b.lA(a,t.z,t.K,t.AH)
s=t.h_
if(s.b(a))return s.a(a)
throw A.i(A.hp(a,"onError",u.w))},
H3(){var s,r
for(s=$.hb;s!=null;s=$.hb){$.iN=null
r=s.b
$.hb=r
if(r==null)$.iM=null
s.a.$0()}},
Hx(){$.y8=!0
try{A.H3()}finally{$.iN=null
$.y8=!1
if($.hb!=null)$.yG().$1(A.Bx())}},
Bo(a){var s=new A.kZ(a),r=$.iM
if(r==null){$.hb=$.iM=s
if(!$.y8)$.yG().$1(A.Bx())}else $.iM=r.b=s},
Hv(a){var s,r,q,p=$.hb
if(p==null){A.Bo(a)
$.iN=$.iM
return}s=new A.kZ(a)
r=$.iN
if(r==null){s.b=p
$.hb=$.iN=s}else{q=r.b
s.b=q
$.iN=r.b=s
if(q==null)$.iM=s}},
BZ(a){var s=null,r=$.aB
if(B.p===r){A.hc(s,s,B.p,a)
return}A.hc(s,s,r,t.R.a(r.hr(a)))},
KS(a,b){A.eg(a,"stream",t.K)
return new A.le(b.i("le<0>"))},
rF(a,b){var s=$.aB
if(s===B.p)return A.xI(a,t.R.a(b))
return A.xI(a,t.R.a(s.hr(b)))},
yc(a,b){A.Hv(new A.vs(a,b))},
Bk(a,b,c,d,e){var s,r=$.aB
if(r===c)return d.$0()
$.aB=c
s=r
try{r=d.$0()
return r}finally{$.aB=s}},
Ht(a,b,c,d,e,f,g){var s,r=$.aB
if(r===c)return d.$1(e)
$.aB=c
s=r
try{r=d.$1(e)
return r}finally{$.aB=s}},
Hs(a,b,c,d,e,f,g,h,i){var s,r=$.aB
if(r===c)return d.$2(e,f)
$.aB=c
s=r
try{r=d.$2(e,f)
return r}finally{$.aB=s}},
hc(a,b,c,d){t.R.a(d)
if(B.p!==c)d=c.hr(d)
A.Bo(d)},
tw:function tw(a){this.a=a},
tv:function tv(a,b,c){this.a=a
this.b=b
this.c=c},
tx:function tx(a){this.a=a},
ty:function ty(a){this.a=a},
li:function li(){this.b=null},
uh:function uh(a,b){this.a=a
this.b=b},
kY:function kY(a,b){this.a=a
this.b=!1
this.$ti=b},
up:function up(a){this.a=a},
uq:function uq(a){this.a=a},
vu:function vu(a){this.a=a},
H:function H(a,b){var _=this
_.a=a
_.e=_.d=_.c=_.b=null
_.$ti=b},
cH:function cH(a,b){this.a=a
this.$ti=b},
d3:function d3(a,b){this.a=a
this.b=b},
nu:function nu(a,b){this.a=a
this.b=b},
l0:function l0(){},
eR:function eR(a,b){this.a=a
this.$ti=b},
eS:function eS(a,b,c,d,e){var _=this
_.a=null
_.b=a
_.c=b
_.d=c
_.e=d
_.$ti=e},
aN:function aN(a,b){var _=this
_.a=0
_.b=a
_.c=null
_.$ti=b},
tK:function tK(a,b){this.a=a
this.b=b},
tR:function tR(a,b){this.a=a
this.b=b},
tO:function tO(a){this.a=a},
tP:function tP(a){this.a=a},
tQ:function tQ(a,b,c){this.a=a
this.b=b
this.c=c},
tN:function tN(a,b){this.a=a
this.b=b},
tM:function tM(a,b){this.a=a
this.b=b},
tL:function tL(a,b,c){this.a=a
this.b=b
this.c=c},
tU:function tU(a,b,c){this.a=a
this.b=b
this.c=c},
tV:function tV(a){this.a=a},
tT:function tT(a,b){this.a=a
this.b=b},
tS:function tS(a,b){this.a=a
this.b=b},
kZ:function kZ(a){this.a=a
this.b=null},
le:function le(a){this.$ti=a},
iI:function iI(){},
vs:function vs(a,b){this.a=a
this.b=b},
lb:function lb(){},
ua:function ua(a,b){this.a=a
this.b=b},
x9(a,b,c,d,e){if(c==null)if(b==null){if(a==null)return new A.du(d.i("@<0>").U(e).i("du<1,2>"))
b=A.BC()}else{if(A.I8()===b&&A.I7()===a)return new A.eV(d.i("@<0>").U(e).i("eV<1,2>"))
if(a==null)a=A.BB()}else{if(b==null)b=A.BC()
if(a==null)a=A.BB()}return A.F3(a,b,c,d,e)},
xR(a,b){var s=a[b]
return s===a?null:s},
xT(a,b,c){if(c==null)a[b]=a
else a[b]=c},
xS(){var s=Object.create(null)
A.xT(s,"<non-identifier-key>",s)
delete s["<non-identifier-key>"]
return s},
F3(a,b,c,d,e){var s=c!=null?c:new A.tG(d)
return new A.ii(a,b,s,d.i("@<0>").U(e).i("ii<1,2>"))},
cR(a,b){return new A.bT(a.i("@<0>").U(b).i("bT<1,2>"))},
l(a,b,c){return b.i("@<0>").U(c).i("xj<1,2>").a(A.Ij(a,new A.bT(b.i("@<0>").U(c).i("bT<1,2>"))))},
b(a,b){return new A.bT(a.i("@<0>").U(b).i("bT<1,2>"))},
zz(a){return new A.dw(a.i("dw<0>"))},
xk(a){return new A.dw(a.i("dw<0>"))},
DM(a,b){return b.i("zy<0>").a(A.Ik(a,new A.dw(b.i("dw<0>"))))},
xV(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s},
xU(a,b,c){var s=new A.eY(a,b,c.i("eY<0>"))
s.c=a.e
return s},
G1(a,b){return J.A(a,b)},
G2(a){return J.b4(a)},
DB(a,b){var s,r=A.K(a),q=new J.d2(a,a.length,r.i("d2<1>"))
if(q.l()){s=q.d
return s==null?r.c.a(s):s}return null},
DC(a,b){var s,r=J.U(a.a),q=a.$ti,p=new A.aQ(r,q.i("aQ<1>"))
if(!p.l())return null
q=q.c
do s=q.a(r.gq())
while(p.l())
return s},
Y(a,b,c){var s=A.cR(b,c)
a.O(0,new A.oe(s,b,c))
return s},
aJ(a,b,c){var s=A.cR(b,c)
s.H(0,a)
return s},
xl(a,b){var s=A.zz(b)
s.H(0,a)
return s},
xn(a){var s,r={}
if(A.yo(a))return"{...}"
s=new A.a_("")
try{B.a.k($.c5,a)
s.a+="{"
r.a=!0
a.O(0,new A.om(r,s))
s.a+="}"}finally{if(0>=$.c5.length)return A.d($.c5,-1)
$.c5.pop()}r=s.a
return r.charCodeAt(0)==0?r:r},
du:function du(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
tW:function tW(a){this.a=a},
eV:function eV(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
ii:function ii(a,b,c,d){var _=this
_.f=a
_.r=b
_.w=c
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=d},
tG:function tG(a){this.a=a},
eT:function eT(a,b){this.a=a
this.$ti=b},
il:function il(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
dw:function dw(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
l8:function l8(a){this.a=a
this.b=null},
eY:function eY(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
oe:function oe(a,b,c){this.a=a
this.b=b
this.c=c},
R:function R(){},
P:function P(){},
ol:function ol(a){this.a=a},
om:function om(a,b){this.a=a
this.b=b},
im:function im(a,b){this.a=a
this.$ti=b},
io:function io(a,b,c){var _=this
_.a=a
_.b=b
_.c=null
_.$ti=c},
iF:function iF(){},
fs:function fs(){},
eL:function eL(a,b){this.a=a
this.$ti=b},
cg:function cg(){},
ix:function ix(){},
h9:function h9(){},
Hc(a,b){var s,r,q,p=null
try{p=JSON.parse(a)}catch(r){s=A.bk(r)
q=A.bc(String(s),null,null)
throw A.i(q)}q=A.uw(p)
return q},
uw(a){var s
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.l6(a,Object.create(null))
for(s=0;s<a.length;++s)a[s]=A.uw(a[s])
return a},
FI(a,b,c){var s,r,q,p,o,n=c-b
if(n<=4096)s=$.Cr()
else s=new Uint8Array(n)
for(r=a.length,q=0;q<n;++q){p=b+q
if(!(p<r))return A.d(a,p)
o=a[p]
if((o&255)!==o)o=255
s[q]=o}return s},
FH(a,b,c,d){var s=a?$.Cq():$.Cp()
if(s==null)return null
if(0===c&&d===b.length)return A.AS(s,b)
return A.AS(s,b.subarray(c,d))},
AS(a,b){var s,r
try{s=a.decode(b)
return s}catch(r){}return null},
yV(a,b,c,d,e,f){if(B.d.b4(f,4)!==0)throw A.i(A.bc("Invalid base64 padding, padded length must be multiple of four, is "+f,a,c))
if(d+e!==f)throw A.i(A.bc("Invalid base64 padding, '=' not at the end",a,b))
if(e>2)throw A.i(A.bc("Invalid base64 padding, more than two '=' characters",a,b))},
F0(a,b,c,d,e,f,g,a0){var s,r,q,p,o,n,m,l,k,j,i=a0>>>2,h=3-(a0&3)
for(s=b.length,r=a.length,q=f.$flags|0,p=c,o=0;p<d;++p){if(!(p<s))return A.d(b,p)
n=b[p]
o|=n
i=(i<<8|n)&16777215;--h
if(h===0){m=g+1
l=i>>>18&63
if(!(l<r))return A.d(a,l)
q&2&&A.ak(f)
k=f.length
if(!(g<k))return A.d(f,g)
f[g]=a.charCodeAt(l)
g=m+1
l=i>>>12&63
if(!(l<r))return A.d(a,l)
if(!(m<k))return A.d(f,m)
f[m]=a.charCodeAt(l)
m=g+1
l=i>>>6&63
if(!(l<r))return A.d(a,l)
if(!(g<k))return A.d(f,g)
f[g]=a.charCodeAt(l)
g=m+1
l=i&63
if(!(l<r))return A.d(a,l)
if(!(m<k))return A.d(f,m)
f[m]=a.charCodeAt(l)
i=0
h=3}}if(o>=0&&o<=255){if(h<3){m=g+1
j=m+1
if(3-h===1){s=i>>>2&63
if(!(s<r))return A.d(a,s)
q&2&&A.ak(f)
q=f.length
if(!(g<q))return A.d(f,g)
f[g]=a.charCodeAt(s)
s=i<<4&63
if(!(s<r))return A.d(a,s)
if(!(m<q))return A.d(f,m)
f[m]=a.charCodeAt(s)
g=j+1
if(!(j<q))return A.d(f,j)
f[j]=61
if(!(g<q))return A.d(f,g)
f[g]=61}else{s=i>>>10&63
if(!(s<r))return A.d(a,s)
q&2&&A.ak(f)
q=f.length
if(!(g<q))return A.d(f,g)
f[g]=a.charCodeAt(s)
s=i>>>4&63
if(!(s<r))return A.d(a,s)
if(!(m<q))return A.d(f,m)
f[m]=a.charCodeAt(s)
g=j+1
s=i<<2&63
if(!(s<r))return A.d(a,s)
if(!(j<q))return A.d(f,j)
f[j]=a.charCodeAt(s)
if(!(g<q))return A.d(f,g)
f[g]=61}return 0}return(i<<2|3-h)>>>0}for(p=c;p<d;){if(!(p<s))return A.d(b,p)
n=b[p]
if(n>255)break;++p}if(!(p<s))return A.d(b,p)
throw A.i(A.hp(b,"Not a byte value at index "+p+": 0x"+B.d.ac(b[p],16),null))},
zw(a,b,c){return new A.hP(a,b)},
G3(a){return a.bs()},
F6(a,b){return new A.u_(a,[],A.I6())},
F7(a,b,c){var s,r=new A.a_(""),q=A.F6(r,b)
q.fp(a)
s=r.a
return s.charCodeAt(0)==0?s:s},
FJ(a){switch(a){case 65:return"Missing extension byte"
case 67:return"Unexpected extension byte"
case 69:return"Invalid UTF-8 byte"
case 71:return"Overlong encoding"
case 73:return"Out of unicode range"
case 75:return"Encoded surrogate"
case 77:return"Unfinished UTF-8 octet sequence"
default:return""}},
l6:function l6(a,b){this.a=a
this.b=b
this.c=null},
tZ:function tZ(a){this.a=a},
l7:function l7(a){this.a=a},
um:function um(){},
ul:function ul(){},
ui:function ui(){},
hr:function hr(){},
lE:function lE(){},
tz:function tz(a){this.a=0
this.b=a},
bN:function bN(){},
jq:function jq(){},
jx:function jx(){},
nJ:function nJ(){},
nI:function nI(){},
hP:function hP(a,b){this.a=a
this.b=b},
jX:function jX(a,b){this.a=a
this.b=b},
jW:function jW(){},
nZ:function nZ(a){this.b=a},
nY:function nY(a){this.a=a},
u0:function u0(){},
u1:function u1(a,b){this.a=a
this.b=b},
u_:function u_(a,b,c){this.c=a
this.a=b
this.b=c},
jZ:function jZ(){},
o9:function o9(a){this.a=a},
kH:function kH(){},
td:function td(a){this.a=a},
uk:function uk(a){this.a=a
this.b=16
this.c=0},
IB(a){return A.ls(a)},
x8(a,b){return A.xq(a,b,null)},
ns(a,b){return new A.jy(new WeakMap(),a,b.i("jy<0>"))},
jz(a){if(A.ef(a)||typeof a=="number"||typeof a=="string"||a instanceof A.aW)A.zg(a)},
zg(a){throw A.i(A.hp(a,"object","Expandos are not allowed on strings, numbers, bools, records or null"))},
bM(a,b){var s=A.V(a,b)
if(s!=null)return s
throw A.i(A.bc(a,null,null))},
Dl(a,b){a=A.i(a)
if(a==null)a=t.K.a(a)
a.stack=b.B(0)
throw a
throw A.i("unreachable")},
eB(a,b,c,d){var s,r=c?J.nT(a,d):J.zu(a,d)
if(a!==0&&b!=null)for(s=0;s<r.length;++s)r[s]=b
return r},
a5(a,b,c){var s,r=A.a([],c.i("w<0>"))
for(s=J.U(a);s.l();)B.a.k(r,c.a(s.gq()))
if(b)return r
r.$flags=1
return r},
N(a,b,c){var s
if(b)return A.zC(a,c)
s=A.zC(a,c)
s.$flags=1
return s},
zC(a,b){var s,r
if(Array.isArray(a))return A.a(a.slice(0),b.i("w<0>"))
s=A.a([],b.i("w<0>"))
for(r=J.U(a);r.l();)B.a.k(s,r.gq())
return s},
cc(a,b){var s=A.a5(a,!1,b)
s.$flags=3
return s},
i1(a,b,c){var s,r,q,p,o
A.bE(b,"start")
s=c==null
r=!s
if(r){q=c-b
if(q<0)throw A.i(A.aK(c,b,null,"end",null))
if(q===0)return""}if(Array.isArray(a)){p=a
o=p.length
if(s)c=o
return A.zI(b>0||c<o?p.slice(b,c):p)}if(t.iT.b(a))return A.En(a,b,c)
if(r)a=J.CV(a,c)
if(b>0)a=J.lB(a,b)
return A.zI(A.N(a,!0,t.S))},
Em(a){return A.W(a)},
En(a,b,c){var s=a.length
if(b>=s)return""
return A.E5(a,b,c==null||c>s?s:c)},
D(a,b,c){return new A.dP(a,A.xf(a,c,b,!1,!1,!1))},
IA(a,b){return a==null?b==null:a===b},
zT(a,b,c){var s=J.U(b)
if(!s.l())return a
if(c.length===0){do a+=A.p(s.gq())
while(s.l())}else{a+=A.p(s.gq())
for(;s.l();)a=a+c+A.p(s.gq())}return a},
zE(a,b){return new A.dc(a,b.glm(),b.gi8(),b.gtR())},
zS(){return A.cJ(new Error())},
Da(a,b,c){var s="microsecond"
if(b<0||b>999)throw A.i(A.aK(b,0,999,s,null))
if(a<-864e13||a>864e13)throw A.i(A.aK(a,-864e13,864e13,"millisecondsSinceEpoch",null))
if(a===864e13&&b!==0)throw A.i(A.hp(b,s,"Time including microseconds is outside valid range"))
A.eg(c,"isUtc",t.v)
return a},
D9(a){var s=Math.abs(a),r=a<0?"-":""
if(s>=1000)return""+a
if(s>=100)return r+"0"+s
if(s>=10)return r+"00"+s
return r+"000"+s},
z6(a){if(a>=100)return""+a
if(a>=10)return"0"+a
return"00"+a},
jr(a){if(a>=10)return""+a
return"0"+a},
ng(a,b){return new A.cr(1000*b+864e8*a)},
dH(a){if(typeof a=="number"||A.ef(a)||a==null)return J.L(a)
if(typeof a=="string")return JSON.stringify(a)
return A.zH(a)},
Dm(a,b){A.eg(a,"error",t.K)
A.eg(b,"stackTrace",t.AH)
A.Dl(a,b)},
j5(a){return new A.hq(a)},
au(a,b){return new A.cp(!1,null,b,a)},
hp(a,b,c){return new A.cp(!0,a,b,c)},
lC(a,b,c){return a},
Ed(a){var s=null
return new A.fv(s,s,!1,s,s,a)},
ki(a,b){return new A.fv(null,null,!0,a,b,"Value not in range")},
aK(a,b,c,d,e){return new A.fv(b,c,!0,a,d,"Invalid value")},
Ee(a,b,c,d){if(a<b||a>c)throw A.i(A.aK(a,b,c,d,null))
return a},
b6(a,b,c){if(0>a||a>c)throw A.i(A.aK(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.i(A.aK(b,a,c,"end",null))
return b}return c},
bE(a,b){if(a<0)throw A.i(A.aK(a,0,null,b,null))
return a},
zo(a,b,c){var s=J.b1(b)
A.v(s)
return new A.hJ(s,!0,a,c,"Index out of range")},
nP(a,b,c,d){return new A.hJ(b,!0,a,d,"Index out of range")},
aV(a){return new A.i5(a)},
xK(a){return new A.kE(a)},
aL(a){return new A.fC(a)},
aD(a){return new A.jp(a)},
hF(a){return new A.tJ(a)},
bc(a,b,c){return new A.c9(a,b,c)},
DD(a,b,c){var s,r
if(A.yo(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}s=A.a([],t.s)
B.a.k($.c5,a)
try{A.GY(a,s)}finally{if(0>=$.c5.length)return A.d($.c5,-1)
$.c5.pop()}r=A.zT(b,t.Y.a(s),", ")+c
return r.charCodeAt(0)==0?r:r},
xd(a,b,c){var s,r
if(A.yo(a))return b+"..."+c
s=new A.a_(b)
B.a.k($.c5,a)
try{r=s
r.a=A.zT(r.a,a,", ")}finally{if(0>=$.c5.length)return A.d($.c5,-1)
$.c5.pop()}s.a+=c
r=s.a
return r.charCodeAt(0)==0?r:r},
GY(a,b){var s,r,q,p,o,n,m,l=a.gJ(a),k=0,j=0
while(!0){if(!(k<80||j<3))break
if(!l.l())return
s=A.p(l.gq())
B.a.k(b,s)
k+=s.length+2;++j}if(!l.l()){if(j<=5)return
if(0>=b.length)return A.d(b,-1)
r=b.pop()
if(0>=b.length)return A.d(b,-1)
q=b.pop()}else{p=l.gq();++j
if(!l.l()){if(j<=4){B.a.k(b,A.p(p))
return}r=A.p(p)
if(0>=b.length)return A.d(b,-1)
q=b.pop()
k+=r.length+2}else{o=l.gq();++j
for(;l.l();p=o,o=n){n=l.gq();++j
if(j>100){while(!0){if(!(k>75&&j>3))break
if(0>=b.length)return A.d(b,-1)
k-=b.pop().length+2;--j}B.a.k(b,"...")
return}}q=A.p(p)
r=A.p(o)
k+=r.length+q.length+4}}if(j>b.length+2){k+=5
m="..."}else m=null
while(!0){if(!(k>80&&b.length>3))break
if(0>=b.length)return A.d(b,-1)
k-=b.pop().length+2
if(m==null){k+=5
m="..."}}if(m!=null)B.a.k(b,m)
B.a.k(b,q)
B.a.k(b,r)},
zD(a,b,c,d,e){return new A.d5(a,b.i("@<0>").U(c).U(d).U(e).i("d5<1,2,3,4>"))},
dU(a,b,c,d){var s
if(B.m===c){s=J.b4(a)
b=J.b4(b)
return A.q2(A.dj(A.dj($.lw(),s),b))}if(B.m===d){s=J.b4(a)
b=J.b4(b)
c=J.b4(c)
return A.q2(A.dj(A.dj(A.dj($.lw(),s),b),c))}s=J.b4(a)
b=J.b4(b)
c=J.b4(c)
d=J.b4(d)
d=A.q2(A.dj(A.dj(A.dj(A.dj($.lw(),s),b),c),d))
return d},
xp(a){var s,r=$.lw()
for(s=J.U(a);s.l();)r=A.dj(r,J.b4(s.gq()))
return A.q2(r)},
BV(a){A.JG(a)},
EF(a6,a7,a8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5=null
a8=a6.length
s=a7+5
if(a8>=s){r=a7+4
if(!(r<a8))return A.d(a6,r)
if(!(a7<a8))return A.d(a6,a7)
q=a7+1
if(!(q<a8))return A.d(a6,q)
p=a7+2
if(!(p<a8))return A.d(a6,p)
o=a7+3
if(!(o<a8))return A.d(a6,o)
n=((a6.charCodeAt(r)^58)*3|a6.charCodeAt(a7)^100|a6.charCodeAt(q)^97|a6.charCodeAt(p)^116|a6.charCodeAt(o)^97)>>>0
if(n===0)return A.An(a7>0||a8<a8?B.b.t(a6,a7,a8):a6,5,a5).glS()
else if(n===32)return A.An(B.b.t(a6,s,a8),0,a5).glS()}m=A.eB(8,0,!1,t.S)
B.a.j(m,0,0)
r=a7-1
B.a.j(m,1,r)
B.a.j(m,2,r)
B.a.j(m,7,r)
B.a.j(m,3,a7)
B.a.j(m,4,a7)
B.a.j(m,5,a8)
B.a.j(m,6,a8)
if(A.Bn(a6,a7,a8,0,m)>=14)B.a.j(m,7,a8)
l=m[1]
if(l>=a7)if(A.Bn(a6,a7,l,20,m)===20)m[7]=l
k=m[2]+1
j=m[3]
i=m[4]
h=m[5]
g=m[6]
if(g<h)h=g
if(i<k)i=h
else if(i<=l)i=l+1
if(j<k)j=i
f=m[7]<a7
e=a5
if(f){f=!1
if(!(k>l+3)){r=j>a7
d=0
if(!(r&&j+1===i)){if(!B.b.aS(a6,"\\",i))if(k>a7)q=B.b.aS(a6,"\\",k-1)||B.b.aS(a6,"\\",k-2)
else q=!1
else q=!0
if(!q){if(!(h<a8&&h===i+2&&B.b.aS(a6,"..",i)))q=h>i+2&&B.b.aS(a6,"/..",h-3)
else q=!0
if(!q)if(l===a7+4){if(B.b.aS(a6,"file",a7)){if(k<=a7){if(!B.b.aS(a6,"/",i)){c="file:///"
n=3}else{c="file://"
n=2}a6=c+B.b.t(a6,i,a8)
l-=a7
s=n-a7
h+=s
g+=s
a8=a6.length
a7=d
k=7
j=7
i=7}else if(i===h){s=a7===0
s
if(s){a6=B.b.bI(a6,i,h,"/");++h;++g;++a8}else{a6=B.b.t(a6,a7,i)+"/"+B.b.t(a6,h,a8)
l-=a7
k-=a7
j-=a7
i-=a7
s=1-a7
h+=s
g+=s
a8=a6.length
a7=d}}e="file"}else if(B.b.aS(a6,"http",a7)){if(r&&j+3===i&&B.b.aS(a6,"80",j+1)){s=a7===0
s
if(s){a6=B.b.bI(a6,j,i,"")
i-=3
h-=3
g-=3
a8-=3}else{a6=B.b.t(a6,a7,j)+B.b.t(a6,i,a8)
l-=a7
k-=a7
j-=a7
s=3+a7
i-=s
h-=s
g-=s
a8=a6.length
a7=d}}e="http"}}else if(l===s&&B.b.aS(a6,"https",a7)){if(r&&j+4===i&&B.b.aS(a6,"443",j+1)){s=a7===0
s
if(s){a6=B.b.bI(a6,j,i,"")
i-=4
h-=4
g-=4
a8-=3}else{a6=B.b.t(a6,a7,j)+B.b.t(a6,i,a8)
l-=a7
k-=a7
j-=a7
s=4+a7
i-=s
h-=s
g-=s
a8=a6.length
a7=d}}e="https"}f=!q}}}}if(f){if(a7>0||a8<a6.length){a6=B.b.t(a6,a7,a8)
l-=a7
k-=a7
j-=a7
i-=a7
h-=a7
g-=a7}return new A.ld(a6,l,k,j,i,h,g,e)}if(e==null)if(l>a7)e=A.FB(a6,a7,l)
else{if(l===a7)A.ha(a6,a7,"Invalid empty scheme")
e=""}b=a5
if(k>a7){a=l+3
a0=a<k?A.FC(a6,a,k-1):""
a1=A.Fx(a6,k,j,!1)
s=j+1
if(s<i){a2=A.V(B.b.t(a6,s,i),a5)
b=A.Fz(a2==null?A.a4(A.bc("Invalid port",a6,s)):a2,e)}}else{a1=a5
a0=""}a3=A.Fy(a6,i,h,a5,e,a1!=null)
a4=h<g?A.FA(a6,h+1,g,a5):a5
return A.Ft(e,a0,a1,b,a3,a4,g<a8?A.Fw(a6,g+1,a8):a5)},
xM(a){var s,r,q=0,p=null
try{s=A.EF(a,q,p)
return s}catch(r){if(A.bk(r) instanceof A.c9)return null
else throw r}},
EE(a,b,c){var s,r,q,p,o,n,m,l="IPv4 address should contain exactly 4 parts",k="each part must be in the range 0..255",j=new A.ta(a),i=new Uint8Array(4)
for(s=a.length,r=b,q=r,p=0;r<c;++r){if(!(r>=0&&r<s))return A.d(a,r)
o=a.charCodeAt(r)
if(o!==46){if((o^48)>9)j.$2("invalid character",r)}else{if(p===3)j.$2(l,r)
n=A.bM(B.b.t(a,q,r),null)
if(n>255)j.$2(k,q)
m=p+1
if(!(p<4))return A.d(i,p)
i[p]=n
q=r+1
p=m}}if(p!==3)j.$2(l,c)
n=A.bM(B.b.t(a,q,c),null)
if(n>255)j.$2(k,q)
if(!(p<4))return A.d(i,p)
i[p]=n
return i},
Ao(a,a0,a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=null,d=new A.tb(a),c=new A.tc(d,a),b=a.length
if(b<2)d.$2("address is too short",e)
s=A.a([],t.X)
for(r=a0,q=r,p=!1,o=!1;r<a1;++r){if(!(r>=0&&r<b))return A.d(a,r)
n=a.charCodeAt(r)
if(n===58){if(r===a0){++r
if(!(r<b))return A.d(a,r)
if(a.charCodeAt(r)!==58)d.$2("invalid start colon.",r)
q=r}if(r===q){if(p)d.$2("only one wildcard `::` is allowed",r)
B.a.k(s,-1)
p=!0}else B.a.k(s,c.$2(q,r))
q=r+1}else if(n===46)o=!0}if(s.length===0)d.$2("too few parts",e)
m=q===a1
b=B.a.gK(s)
if(m&&b!==-1)d.$2("expected a part after last `:`",a1)
if(!m)if(!o)B.a.k(s,c.$2(q,a1))
else{l=A.EE(a,q,a1)
B.a.k(s,(l[0]<<8|l[1])>>>0)
B.a.k(s,(l[2]<<8|l[3])>>>0)}if(p){if(s.length>7)d.$2("an address with a wildcard must have less than 7 parts",e)}else if(s.length!==8)d.$2("an address without a wildcard must contain exactly 8 parts",e)
k=new Uint8Array(16)
for(b=s.length,j=9-b,r=0,i=0;r<b;++r){h=s[r]
if(h===-1)for(g=0;g<j;++g){if(!(i>=0&&i<16))return A.d(k,i)
k[i]=0
f=i+1
if(!(f<16))return A.d(k,f)
k[f]=0
i+=2}else{f=B.d.cn(h,8)
if(!(i>=0&&i<16))return A.d(k,i)
k[i]=f
f=i+1
if(!(f<16))return A.d(k,f)
k[f]=h&255
i+=2}}return k},
Ft(a,b,c,d,e,f,g){return new A.iG(a,b,c,d,e,f,g)},
AM(a){if(a==="http")return 80
if(a==="https")return 443
return 0},
ha(a,b,c){throw A.i(A.bc(c,a,b))},
Fz(a,b){var s=A.AM(b)
if(a===s)return null
return a},
Fx(a,b,c,d){var s,r,q,p,o,n
if(b===c)return""
s=a.length
if(!(b>=0&&b<s))return A.d(a,b)
if(a.charCodeAt(b)===91){r=c-1
if(!(r>=0&&r<s))return A.d(a,r)
if(a.charCodeAt(r)!==93)A.ha(a,b,"Missing end `]` to match `[` in host")
s=b+1
q=A.Fv(a,s,r)
if(q<r){p=q+1
o=A.AR(a,B.b.aS(a,"25",p)?q+3:p,r,"%25")}else o=""
A.Ao(a,s,q)
return B.b.t(a,b,q).toLowerCase()+o+"]"}for(n=b;n<c;++n){if(!(n<s))return A.d(a,n)
if(a.charCodeAt(n)===58){q=B.b.bl(a,"%",b)
q=q>=b&&q<c?q:c
if(q<c){p=q+1
o=A.AR(a,B.b.aS(a,"25",p)?q+3:p,c,"%25")}else o=""
A.Ao(a,b,q)
return"["+B.b.t(a,b,q)+o+"]"}}return A.FE(a,b,c)},
Fv(a,b,c){var s=B.b.bl(a,"%",b)
return s>=b&&s<c?s:c},
AR(a,b,c,d){var s,r,q,p,o,n,m,l,k,j,i,h=d!==""?new A.a_(d):null
for(s=a.length,r=b,q=r,p=!0;r<c;){if(!(r>=0&&r<s))return A.d(a,r)
o=a.charCodeAt(r)
if(o===37){n=A.y_(a,r,!0)
m=n==null
if(m&&p){r+=3
continue}if(h==null)h=new A.a_("")
l=h.a+=B.b.t(a,q,r)
if(m)n=B.b.t(a,r,r+3)
else if(n==="%")A.ha(a,r,"ZoneID should not contain % anymore")
h.a=l+n
r+=3
q=r
p=!0}else{if(o<127){m=o>>>4
if(!(m<8))return A.d(B.a_,m)
m=(B.a_[m]&1<<(o&15))!==0}else m=!1
if(m){if(p&&65<=o&&90>=o){if(h==null)h=new A.a_("")
if(q<r){h.a+=B.b.t(a,q,r)
q=r}p=!1}++r}else{k=1
if((o&64512)===55296&&r+1<c){m=r+1
if(!(m<s))return A.d(a,m)
j=a.charCodeAt(m)
if((j&64512)===56320){o=(o&1023)<<10|j&1023|65536
k=2}}i=B.b.t(a,q,r)
if(h==null){h=new A.a_("")
m=h}else m=h
m.a+=i
l=A.xZ(o)
m.a+=l
r+=k
q=r}}}if(h==null)return B.b.t(a,b,c)
if(q<c){i=B.b.t(a,q,c)
h.a+=i}s=h.a
return s.charCodeAt(0)==0?s:s},
FE(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h
for(s=a.length,r=b,q=r,p=null,o=!0;r<c;){if(!(r>=0&&r<s))return A.d(a,r)
n=a.charCodeAt(r)
if(n===37){m=A.y_(a,r,!0)
l=m==null
if(l&&o){r+=3
continue}if(p==null)p=new A.a_("")
k=B.b.t(a,q,r)
if(!o)k=k.toLowerCase()
j=p.a+=k
i=3
if(l)m=B.b.t(a,r,r+3)
else if(m==="%"){m="%25"
i=1}p.a=j+m
r+=i
q=r
o=!0}else{if(n<127){l=n>>>4
if(!(l<8))return A.d(B.aR,l)
l=(B.aR[l]&1<<(n&15))!==0}else l=!1
if(l){if(o&&65<=n&&90>=n){if(p==null)p=new A.a_("")
if(q<r){p.a+=B.b.t(a,q,r)
q=r}o=!1}++r}else{if(n<=93){l=n>>>4
if(!(l<8))return A.d(B.X,l)
l=(B.X[l]&1<<(n&15))!==0}else l=!1
if(l)A.ha(a,r,"Invalid character")
else{i=1
if((n&64512)===55296&&r+1<c){l=r+1
if(!(l<s))return A.d(a,l)
h=a.charCodeAt(l)
if((h&64512)===56320){n=(n&1023)<<10|h&1023|65536
i=2}}k=B.b.t(a,q,r)
if(!o)k=k.toLowerCase()
if(p==null){p=new A.a_("")
l=p}else l=p
l.a+=k
j=A.xZ(n)
l.a+=j
r+=i
q=r}}}}if(p==null)return B.b.t(a,b,c)
if(q<c){k=B.b.t(a,q,c)
if(!o)k=k.toLowerCase()
p.a+=k}s=p.a
return s.charCodeAt(0)==0?s:s},
FB(a,b,c){var s,r,q,p,o
if(b===c)return""
s=a.length
if(!(b<s))return A.d(a,b)
if(!A.AO(a.charCodeAt(b)))A.ha(a,b,"Scheme not starting with alphabetic character")
for(r=b,q=!1;r<c;++r){if(!(r<s))return A.d(a,r)
p=a.charCodeAt(r)
if(p<128){o=p>>>4
if(!(o<8))return A.d(B.W,o)
o=(B.W[o]&1<<(p&15))!==0}else o=!1
if(!o)A.ha(a,r,"Illegal scheme character")
if(65<=p&&p<=90)q=!0}a=B.b.t(a,b,c)
return A.Fu(q?a.toLowerCase():a)},
Fu(a){if(a==="http")return"http"
if(a==="file")return"file"
if(a==="https")return"https"
if(a==="package")return"package"
return a},
FC(a,b,c){return A.iH(a,b,c,B.cK,!1,!1)},
Fy(a,b,c,d,e,f){var s=e==="file",r=s||f,q=A.iH(a,b,c,B.aY,!0,!0)
if(q.length===0){if(s)return"/"}else if(r&&!B.b.a0(q,"/"))q="/"+q
return A.FD(q,e,f)},
FD(a,b,c){var s=b.length===0
if(s&&!c&&!B.b.a0(a,"/")&&!B.b.a0(a,"\\"))return A.FF(a,!s||c)
return A.FG(a)},
FA(a,b,c,d){return A.iH(a,b,c,B.U,!0,!1)},
Fw(a,b,c){return A.iH(a,b,c,B.U,!0,!1)},
y_(a,b,c){var s,r,q,p,o,n,m=b+2,l=a.length
if(m>=l)return"%"
s=b+1
if(!(s>=0&&s<l))return A.d(a,s)
r=a.charCodeAt(s)
if(!(m>=0))return A.d(a,m)
q=a.charCodeAt(m)
p=A.wa(r)
o=A.wa(q)
if(p<0||o<0)return"%"
n=p*16+o
if(n<127){m=B.d.cn(n,4)
if(!(m<8))return A.d(B.a_,m)
m=(B.a_[m]&1<<(n&15))!==0}else m=!1
if(m)return A.W(c&&65<=n&&90>=n?(n|32)>>>0:n)
if(r>=97||q>=97)return B.b.t(a,b,b+3).toUpperCase()
return null},
xZ(a){var s,r,q,p,o,n,m,l,k="0123456789ABCDEF"
if(a<128){s=new Uint8Array(3)
s[0]=37
r=a>>>4
if(!(r<16))return A.d(k,r)
s[1]=k.charCodeAt(r)
s[2]=k.charCodeAt(a&15)}else{if(a>2047)if(a>65535){q=240
p=4}else{q=224
p=3}else{q=192
p=2}r=3*p
s=new Uint8Array(r)
for(o=0;--p,p>=0;q=128){n=B.d.qr(a,6*p)&63|q
if(!(o<r))return A.d(s,o)
s[o]=37
m=o+1
l=n>>>4
if(!(l<16))return A.d(k,l)
if(!(m<r))return A.d(s,m)
s[m]=k.charCodeAt(l)
l=o+2
if(!(l<r))return A.d(s,l)
s[l]=k.charCodeAt(n&15)
o+=3}}return A.i1(s,0,null)},
iH(a,b,c,d,e,f){var s=A.AQ(a,b,c,d,e,f)
return s==null?B.b.t(a,b,c):s},
AQ(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j,i,h=null
for(s=!e,r=a.length,q=b,p=q,o=h;q<c;){if(!(q>=0&&q<r))return A.d(a,q)
n=a.charCodeAt(q)
if(n<127){m=n>>>4
if(!(m<8))return A.d(d,m)
m=(d[m]&1<<(n&15))!==0}else m=!1
if(m)++q
else{l=1
if(n===37){k=A.y_(a,q,!1)
if(k==null){q+=3
continue}if("%"===k)k="%25"
else l=3}else if(n===92&&f)k="/"
else{m=!1
if(s)if(n<=93){m=n>>>4
if(!(m<8))return A.d(B.X,m)
m=(B.X[m]&1<<(n&15))!==0}if(m){A.ha(a,q,"Invalid character")
l=h
k=l}else{if((n&64512)===55296){m=q+1
if(m<c){if(!(m<r))return A.d(a,m)
j=a.charCodeAt(m)
if((j&64512)===56320){n=(n&1023)<<10|j&1023|65536
l=2}}}k=A.xZ(n)}}if(o==null){o=new A.a_("")
m=o}else m=o
i=m.a+=B.b.t(a,p,q)
m.a=i+A.p(k)
if(typeof l!=="number")return A.ym(l)
q+=l
p=q}}if(o==null)return h
if(p<c){s=B.b.t(a,p,c)
o.a+=s}s=o.a
return s.charCodeAt(0)==0?s:s},
AP(a){if(B.b.a0(a,"."))return!0
return B.b.ae(a,"/.")!==-1},
FG(a){var s,r,q,p,o,n,m
if(!A.AP(a))return a
s=A.a([],t.s)
for(r=a.split("/"),q=r.length,p=!1,o=0;o<q;++o){n=r[o]
if(n===".."){m=s.length
if(m!==0){if(0>=m)return A.d(s,-1)
s.pop()
if(s.length===0)B.a.k(s,"")}p=!0}else{p="."===n
if(!p)B.a.k(s,n)}}if(p)B.a.k(s,"")
return B.a.ab(s,"/")},
FF(a,b){var s,r,q,p,o,n
if(!A.AP(a))return!b?A.AN(a):a
s=A.a([],t.s)
for(r=a.split("/"),q=r.length,p=!1,o=0;o<q;++o){n=r[o]
if(".."===n){p=s.length!==0&&B.a.gK(s)!==".."
if(p){if(0>=s.length)return A.d(s,-1)
s.pop()}else B.a.k(s,"..")}else{p="."===n
if(!p)B.a.k(s,n)}}r=s.length
if(r!==0)if(r===1){if(0>=r)return A.d(s,0)
r=s[0].length===0}else r=!1
else r=!0
if(r)return"./"
if(p||B.a.gK(s)==="..")B.a.k(s,"")
if(!b){if(0>=s.length)return A.d(s,0)
B.a.j(s,0,A.AN(s[0]))}return B.a.ab(s,"/")},
AN(a){var s,r,q,p=a.length
if(p>=2&&A.AO(a.charCodeAt(0)))for(s=1;s<p;++s){r=a.charCodeAt(s)
if(r===58)return B.b.t(a,0,s)+"%3A"+B.b.L(a,s+1)
if(r<=127){q=r>>>4
if(!(q<8))return A.d(B.W,q)
q=(B.W[q]&1<<(r&15))===0}else q=!0
if(q)break}return a},
AO(a){var s=a|32
return 97<=s&&s<=122},
An(a,b,c){var s,r,q,p,o,n,m,l,k="Invalid MIME type",j=A.a([b-1],t.X)
for(s=a.length,r=b,q=-1,p=null;r<s;++r){p=a.charCodeAt(r)
if(p===44||p===59)break
if(p===47){if(q<0){q=r
continue}throw A.i(A.bc(k,a,r))}}if(q<0&&r>b)throw A.i(A.bc(k,a,r))
for(;p!==44;){B.a.k(j,r);++r
for(o=-1;r<s;++r){if(!(r>=0))return A.d(a,r)
p=a.charCodeAt(r)
if(p===61){if(o<0)o=r}else if(p===59||p===44)break}if(o>=0)B.a.k(j,o)
else{n=B.a.gK(j)
if(p!==44||r!==n+7||!B.b.aS(a,"base64",n+1))throw A.i(A.bc("Expecting '='",a,r))
break}}B.a.k(j,r)
m=r+1
if((j.length&1)===1)a=B.aE.tU(a,m,s)
else{l=A.AQ(a,m,s,B.U,!0,!1)
if(l!=null)a=B.b.bI(a,m,s,l)}return new A.t9(a,j,c)},
G_(){var s,r,q,p,o,n="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._~!$&'()*+,;=",m=".",l=":",k="/",j="\\",i="?",h="#",g="/\\",f=J.zt(22,t.uo)
for(s=0;s<22;++s)f[s]=new Uint8Array(96)
r=new A.ux(f)
q=new A.uy()
p=new A.uz()
o=r.$2(0,225)
q.$3(o,n,1)
q.$3(o,m,14)
q.$3(o,l,34)
q.$3(o,k,3)
q.$3(o,j,227)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(14,225)
q.$3(o,n,1)
q.$3(o,m,15)
q.$3(o,l,34)
q.$3(o,g,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(15,225)
q.$3(o,n,1)
q.$3(o,"%",225)
q.$3(o,l,34)
q.$3(o,k,9)
q.$3(o,j,233)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(1,225)
q.$3(o,n,1)
q.$3(o,l,34)
q.$3(o,k,10)
q.$3(o,j,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(2,235)
q.$3(o,n,139)
q.$3(o,k,131)
q.$3(o,j,131)
q.$3(o,m,146)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(3,235)
q.$3(o,n,11)
q.$3(o,k,68)
q.$3(o,j,68)
q.$3(o,m,18)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(4,229)
q.$3(o,n,5)
p.$3(o,"AZ",229)
q.$3(o,l,102)
q.$3(o,"@",68)
q.$3(o,"[",232)
q.$3(o,k,138)
q.$3(o,j,138)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(5,229)
q.$3(o,n,5)
p.$3(o,"AZ",229)
q.$3(o,l,102)
q.$3(o,"@",68)
q.$3(o,k,138)
q.$3(o,j,138)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(6,231)
p.$3(o,"19",7)
q.$3(o,"@",68)
q.$3(o,k,138)
q.$3(o,j,138)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(7,231)
p.$3(o,"09",7)
q.$3(o,"@",68)
q.$3(o,k,138)
q.$3(o,j,138)
q.$3(o,i,172)
q.$3(o,h,205)
q.$3(r.$2(8,8),"]",5)
o=r.$2(9,235)
q.$3(o,n,11)
q.$3(o,m,16)
q.$3(o,g,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(16,235)
q.$3(o,n,11)
q.$3(o,m,17)
q.$3(o,g,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(17,235)
q.$3(o,n,11)
q.$3(o,k,9)
q.$3(o,j,233)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(10,235)
q.$3(o,n,11)
q.$3(o,m,18)
q.$3(o,k,10)
q.$3(o,j,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(18,235)
q.$3(o,n,11)
q.$3(o,m,19)
q.$3(o,g,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(19,235)
q.$3(o,n,11)
q.$3(o,g,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(11,235)
q.$3(o,n,11)
q.$3(o,k,10)
q.$3(o,j,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(12,236)
q.$3(o,n,12)
q.$3(o,i,12)
q.$3(o,h,205)
o=r.$2(13,237)
q.$3(o,n,13)
q.$3(o,i,13)
p.$3(r.$2(20,245),"az",21)
o=r.$2(21,245)
p.$3(o,"az",21)
p.$3(o,"09",21)
q.$3(o,"+-.",21)
return f},
Bn(a,b,c,d,e){var s,r,q,p,o,n=$.CC()
for(s=a.length,r=b;r<c;++r){if(!(d>=0&&d<n.length))return A.d(n,d)
q=n[d]
if(!(r<s))return A.d(a,r)
p=a.charCodeAt(r)^96
o=q[p>95?31:p]
d=o&31
B.a.j(e,o>>>5,r)}return d},
on:function on(a,b){this.a=a
this.b=b},
cN:function cN(a,b,c){this.a=a
this.b=b
this.c=c},
cr:function cr(a){this.a=a},
tI:function tI(){},
aq:function aq(){},
hq:function hq(a){this.a=a},
dl:function dl(){},
cp:function cp(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
fv:function fv(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
hJ:function hJ(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
dc:function dc(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
i5:function i5(a){this.a=a},
kE:function kE(a){this.a=a},
fC:function fC(a){this.a=a},
jp:function jp(a){this.a=a},
kb:function kb(){},
i_:function i_(){},
tJ:function tJ(a){this.a=a},
c9:function c9(a,b,c){this.a=a
this.b=b
this.c=c},
o:function o(){},
F:function F(a,b,c){this.a=a
this.b=b
this.$ti=c},
ah:function ah(){},
J:function J(){},
lh:function lh(){},
ch:function ch(){this.b=this.a=0},
a_:function a_(a){this.a=a},
ta:function ta(a){this.a=a},
tb:function tb(a){this.a=a},
tc:function tc(a,b){this.a=a
this.b=b},
iG:function iG(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.y=_.w=$},
t9:function t9(a,b,c){this.a=a
this.b=b
this.c=c},
ux:function ux(a){this.a=a},
uy:function uy(){},
uz:function uz(){},
ld:function ld(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=null},
l2:function l2(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.y=_.w=$},
jy:function jy(a,b,c){this.a=a
this.b=b
this.$ti=c},
f2(a){var s
if(typeof a=="function")throw A.i(A.au("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d){return b(c,d,arguments.length)}}(A.FU,a)
s[$.wU()]=a
return s},
FU(a,b,c){t.BO.a(a)
if(A.v(c)>=1)return a.$1(b)
return a.$0()},
FV(a,b,c,d){t.BO.a(a)
A.v(d)
if(d>=2)return a.$2(b,c)
if(d===1)return a.$1(b)
return a.$0()},
JH(a,b){var s=new A.aN($.aB,b.i("aN<0>")),r=new A.eR(s,b.i("eR<0>"))
a.then(A.hh(new A.ww(r,b),1),A.hh(new A.wx(r),1))
return s},
Bf(a){return a==null||typeof a==="boolean"||typeof a==="number"||typeof a==="string"||a instanceof Int8Array||a instanceof Uint8Array||a instanceof Uint8ClampedArray||a instanceof Int16Array||a instanceof Uint16Array||a instanceof Int32Array||a instanceof Uint32Array||a instanceof Float32Array||a instanceof Float64Array||a instanceof ArrayBuffer||a instanceof DataView},
iQ(a){if(A.Bf(a))return a
return new A.vF(new A.eV(t.BT)).$1(a)},
ww:function ww(a,b){this.a=a
this.b=b},
wx:function wx(a){this.a=a},
vF:function vF(a){this.a=a},
oq:function oq(a){this.a=a},
BT(a,b,c){A.lm(c,t.fY,"T","min")
return Math.min(c.a(a),c.a(b))},
BS(a,b,c){A.lm(c,t.fY,"T","max")
return Math.max(c.a(a),c.a(b))},
Ec(){return B.I},
tX:function tX(){},
ep:function ep(a){this.$ti=a},
fn:function fn(a,b){this.a=a
this.$ti=b},
dS:function dS(a,b){this.a=a
this.$ti=b},
bm:function bm(){},
fO:function fO(a,b){this.a=a
this.$ti=b},
fz:function fz(a,b){this.a=a
this.$ti=b},
h3:function h3(a,b,c){this.a=a
this.b=b
this.c=c},
fr:function fr(a,b,c){this.a=a
this.b=b
this.$ti=c},
fe:function fe(a){this.b=a},
fy(a,b){if(b===65535)return!0
return(a&b)===b},
X:function X(a,b,c,d,e,f,g,h,i){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i},
p8:function p8(a,b,c){this.a=a
this.b=b
this.c=c},
p9:function p9(){},
C:function C(){},
z:function z(){},
oE:function oE(){},
oC:function oC(){},
oD:function oD(a,b){this.a=a
this.b=b},
oB:function oB(a){this.a=a},
oF:function oF(a,b){this.a=a
this.b=b},
j9:function j9(){},
ay:function ay(){},
aE:function aE(){},
cO:function cO(){},
hY:function hY(){},
By(a,b){var s,r,q,p,o,n,m,l,k,j=null,i=new A.r(A.a([],t.t))
for(s=a.a4(t.at),r=s.$ti,s=new A.H(s.a(),r.i("H<1>")),r=r.c,q=t.G,p=t.N,o=t.z;s.l();){n=s.b
if(n==null)n=r.a(n)
if(n.E(0)===0)continue
m=A.cm(n,b,j)
l=n instanceof A.cO&&!q.b(n.bY())?A.l([n.gA(),n.bY()],p,o):n.bY()
i.V(0,l,m.a===0?j:m)}k=A.cm(a,b,j)
i.V(0,"\n",k.a===0?j:k)
return i},
cm(a,b,c){var s,r,q
if(a==null)return c==null?A.b(t.N,t.z):c
if(c==null){s=t.z
s=A.b(s,s)}else s=c
r=A.Y(s,t.N,t.z)
r.H(0,a.P())
if(b)r.Z(0,"code-token")
q=a.a
if(q==null||q instanceof A.bh||q.gT()!==a.gT())return r
return A.cm(q,b,r)},
lV(a){return new A.a0(A.b(t.N,t.z),A.a([],t.E),a)},
a0:function a0(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
lX:function lX(){},
lY:function lY(){},
lW:function lW(a){this.a=a},
f8:function f8(){},
ht(){$.y().a.a===$&&A.c()
var s=t.m
return new A.ap(new A.f(A.b(t.O,t.g),s.a(s.a(self.document).createElement("BR"))))},
ap:function ap(a){var _=this
_.c=_.b=_.a=null
_.d=a},
hy:function hy(){},
z5(a){var s,r,q
$.y().a.a===$&&A.c()
s=t.m
r=s.a(new self.Text("\ufeff"))
q=a.a
s.a(q.classList).add("ql-cursor")
s.a(q.appendChild(r))
return new A.cM(new A.bl(r),a)},
cM:function cM(a,b){var _=this
_.as=a
_.at=0
_.c=_.b=_.a=_.ay=_.ax=null
_.d=b},
mO:function mO(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
mP:function mP(a){this.a=a},
d8:function d8(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
fg:function fg(){},
zp(a,b){var s=B.a.ae(B.aT,a),r=B.a.ae(B.aT,b)
if(s>=0||r>=0)return s-r
if(a===b)return 0
return B.b.bi(a,b)},
dL:function dL(a,b){var _=this
_.z=$
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
aP:function aP(){},
nR:function nR(){},
IN(a){t.U.a(a)
return a instanceof A.a0||a instanceof A.bt},
Eh(a){return B.a.ag(a.a,0,new A.pb(),t.S)},
we(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g,f={}
f.a=b
for(s=c.a,r=s.length,q=t.G,p=t.N,o=t.z,n=0;n<s.length;s.length===r||(0,A.k)(s),++n){m=s[n]
l=m.b
k=m.d
if(k==null)j=null
else{k=A.Y(k,p,o)
j=k}if(j==null)j=A.b(p,o)
i=m.c
if(typeof i=="string"){a.aF(f.a,i)
j=A.dG(A.cm(a.bv(new A.wf(),f.a).a,!0,null),j)
if(j==null)j=A.b(p,o)}else if(q.b(i)){h=J.ek(i.ga7())
if(h==null)continue
k=f.a
A.h(h)
a.aL(k,h,i.h(0,h))
g=a.gaR()
if(g==null)A.a4(A.aL("Blot is not attached to a scroll"))
if(g.z.aw(h,2)!=null){j=A.dG(A.cm(a.bv(new A.wg(),f.a).a,!0,null),j)
if(j==null)j=A.b(p,o)}}if(l!=null){j.O(0,new A.wh(f,a,l))
f.a+=l}}},
bh:function bh(a,b,c,d){var _=this
_.cy=a
_.db=null
_.z=b
_.Q=null
_.as=0
_.e=c
_.c=_.b=_.a=_.f=null
_.d=d},
pj:function pj(){},
pl:function pl(a){this.a=a},
pm:function pm(){},
pn:function pn(){},
pk:function pk(){},
pg:function pg(){},
ph:function ph(a,b){this.a=a
this.b=b},
pi:function pi(a){this.a=a},
pb:function pb(){},
pd:function pd(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
pe:function pe(a,b){this.a=a
this.b=b},
pf:function pf(a){this.a=a},
pc:function pc(a,b){this.a=a
this.b=b},
wf:function wf(){},
wg:function wg(){},
wh:function wh(a,b,c){this.a=a
this.b=b
this.c=c},
Ai(a){var s=a==null?null:J.L(a)
if(s==null)s=""
$.y().a.a===$&&A.c()
return new A.aM(new A.bl(t.m.a(new self.Text(s))))},
Ig(a){return A.iY(a,A.D("[&<>\"']",!0,!1),t.tj.a(t.pj.a(new A.vK())),null)},
aM:function aM(a){var _=this
_.c=_.b=_.a=null
_.d=a},
vK:function vK(){},
ja:function ja(){},
jO:function jO(){},
nS:function nS(){},
mR(a){var s,r,q=a.length
if(q===0)return!1
if(0>=q)return A.d(a,0)
s=a[0]
if(s!=="{"&&s!=="[")return!1
try{B.q.hx(a,null)
return!0}catch(r){return!1}},
mQ:function mQ(a,b,c){var _=this
_.a=!0
_.c=a
_.d=b
_.e=c},
cQ:function cQ(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.f=_.e=!1
_.r=1
_.w=e
_.x=f
_.y=""
_.z=g
_.Q=h},
oa:function oa(){},
az:function az(){},
j1:function j1(a,b){this.c=a
this.a=b},
j7:function j7(a){this.a=a},
jb:function jb(a){this.a=a},
jc:function jc(a){this.a=a},
jh:function jh(a){this.a=a},
ji:function ji(a){this.a=a},
jA:function jA(a){this.a=a},
jD:function jD(a){this.a=a},
jE:function jE(a,b){this.c=a
this.a=b},
jM:function jM(a){this.a=a},
jS:function jS(a){this.a=a},
k_:function k_(a){this.a=a},
ob:function ob(a){this.a=a},
k0:function k0(a){this.a=a},
oh:function oh(a){this.a=a},
oi:function oi(a){this.a=a},
kn:function kn(a,b){this.c=a
this.a=b},
ko:function ko(a){this.a=a},
kt:function kt(a){this.a=a},
ku:function ku(a){this.a=a},
rD:function rD(a,b){this.a=a
this.b=b},
rC:function rC(a,b){this.a=a
this.b=b},
ci(a){var s,r
if(a==null)return null
s=J.L(a)
if(s.length===0)return null
r=A.O(s,"&","&amp;")
r=A.O(r,"<","&lt;")
r=A.O(r,">","&gt;")
r=A.O(r,'"',"&quot;")
return A.O(r,"'","&#39;")},
zY(a,b){var s,r=B.b.R(b)
if(r.length===0)return a
s=B.b.R(a)
if(s.length===0)return b
return(B.b.be(s,";")?s:s+";")+" "+r},
kv:function kv(a){this.a=a},
ql:function ql(a,b){this.a=a
this.b=b},
qx:function qx(){},
qy:function qy(){},
qq:function qq(a,b,c){this.a=a
this.b=b
this.c=c},
qs:function qs(a,b){this.a=a
this.b=b},
qt:function qt(a,b){this.a=a
this.b=b},
qo:function qo(a,b){this.a=a
this.b=b},
qp:function qp(a,b,c){this.a=a
this.b=b
this.c=c},
qr:function qr(a,b,c){this.a=a
this.b=b
this.c=c},
qu:function qu(a,b,c){this.a=a
this.b=b
this.c=c},
qv:function qv(){},
qw:function qw(a){this.a=a},
kB:function kB(a){this.a=a},
kD:function kD(a){this.a=a},
kI:function kI(a,b){this.c=a
this.a=b},
cz:function cz(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
JF(a){var s,r,q,p,o,n,m=t.N,l=A.b(m,m)
if(B.b.R(a).length===0)return l
for(m=A.Hw(a),s=m.length,r=0;r<m.length;m.length===s||(0,A.k)(m),++r){q=m[r]
p=B.b.ae(q,":")
if(p<=0)continue
o=B.b.R(B.b.t(q,0,p)).toLowerCase()
n=B.b.R(B.b.L(q,p+1))
if(o.length===0||n.length===0)continue
l.j(0,o,n)}return l},
Hw(a){var s,r,q,p,o,n,m,l=A.a([],t.s)
for(s=a.length,r=0,q=null,p=0,o="";p<s;++p){n=a[p]
if(q!=null){o+=n
if(n===q)if(p!==0){m=p-1
if(!(m>=0))return A.d(a,m)
m=a[m]!==""}else m=!0
else m=!1
if(m)q=null
continue}switch(n){case'"':case"'":o+=n
q=n
break
case"(":++r
o+=n
break
case")":if(r>0)--r
o+=n
break
case";":if(r>0)o+=n
else{B.a.k(l,o.charCodeAt(0)==0?o:o)
o=""}break
default:o+=n}}if(o.length!==0)B.a.k(l,o.charCodeAt(0)==0?o:o)
s=t.vY
return A.N(new A.an(l,t.Ag.a(new A.vt()),s),!0,s.i("o.E"))},
JZ(a){var s
if(a.a===0)return""
s=A.a([],t.s)
a.O(0,new A.wE(s))
return B.a.ab(s,"; ")+";"},
vt:function vt(){},
wE:function wE(a){this.a=a},
jo:function jo(a,b){this.a=a
this.b=b
this.c=!1},
mK:function mK(a){this.a=a},
mJ:function mJ(a,b){this.a=a
this.b=b},
y6(a){var s=J.A(a,"ordered")?"ol":"ul",r=t.s
switch(a){case"checked":return A.a([s,' data-list="checked"'],r)
case"unchecked":return A.a([s,' data-list="unchecked"'],r)
default:return A.a([s,""],r)}},
iL(a,b,c){var s,r,q,p,o,n,m,l,k
if(a.length===0){if(0>=c.length)return A.d(c,-1)
s=A.y6(c.pop())[0]
if(b<=0)return"</li></"+s+">"
return"</li></"+s+">"+A.iL(A.a([],t.th),b-1,c)}r=B.a.gF(a)
q=B.a.dL(a,1)
p=r.e
o=A.y6(p)
n=o[0]
m=o[1]
l=r.d
if(l>b){B.a.k(c,p)
p=b+1
if(l===p)return"<"+n+"><li"+m+">"+A.lo(r.a,r.b,r.c,!1)+A.iL(q,l,c)
return"<"+n+"><li>"+A.iL(a,p,c)}k=c.length!==0?B.a.gK(c):null
if(l===b&&J.A(p,k))return"</li><li"+m+">"+A.lo(r.a,r.b,r.c,!1)+A.iL(q,l,c)
if(0>=c.length)return A.d(c,-1)
return"</li></"+A.y6(c.pop())[0]+">"+A.iL(a,b-1,c)},
lo(a,b,c,d){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=a.cT(b,c)
if(f!=null)return f
if(a instanceof A.aM){s=A.h(t.y.a(a.d).a.data)
r=b+c
q=s.length
if(r>q)r=q
p=A.Ig(B.b.t(s,b>q?q:b,r))
return A.O(p," ","&nbsp;")}if(a instanceof A.z){if(a.gA()==="list-container"){o=A.a([],t.th)
a.e4(b,c,new A.vC(o))
return A.iL(o,-1,[])}n=A.a([],t.s)
a.e4(b,c,new A.vD(n))
if(d||a.gA()==="list")return B.a.bn(n)
m=t.T.a(a.d)
l=m.glt()
k=m.gaf()
j=l.split(">"+(k==null?"":k)+"<")
i=j.length
if(0>=i)return A.d(j,0)
h=j[0]
r=i>1?j[1]:""
if(h==="<table")return'<table style="border: 1px solid #000;">'+B.a.bn(n)+"<"+r
return h+">"+B.a.bn(n)+"<"+r}g=a.d
return g instanceof A.f?g.glt():""},
nh:function nh(a,b){this.a=a
this.b=b},
nj:function nj(){},
nk:function nk(){},
nl:function nl(){},
nm:function nm(a,b,c){this.a=a
this.b=b
this.c=c},
ni:function ni(){},
nn:function nn(a,b,c){this.a=a
this.b=b
this.c=c},
no:function no(a,b,c){this.a=a
this.b=b
this.c=c},
l9:function l9(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
vC:function vC(a){this.a=a},
vD:function vD(a){this.a=a},
If(){var s,r,q,p,o,n=$.y().a.a
n===$&&A.c()
s=n.gff()
r=$.Cu()
A.jz(s)
q=r.a.get(s)
if(A.ac(q==null?!1:q))return
r.j(0,s,!0)
for(p=0;p<4;++p){o=B.ds[p]
n.I(o,new A.vJ(n,o))}},
ze(a,b,c,d){var s,r,q,p=[]
for(s=[a,b,c,d],r=0;r<4;++r){q=s[r]
if(q===B.k)break
p.push(q)}return p},
zf(a,b){var s,r,q=b.length,p=t.dz
while(!0){s=q
if(typeof s!=="number")return s.m_()
if(!(s>=0))break
try{s=B.a.dM(b,0,q)
A.xq(a,s,null)
return}catch(r){if(p.b(A.bk(r))){if(J.A(q,0))throw r}else throw r}s=q
if(typeof s!=="number")return s.fG()
q=s-1}},
vJ:function vJ(a,b){this.a=a
this.b=b},
jw:function jw(a,b){this.a=a
this.b=b},
nq:function nq(){},
nr:function nr(a,b,c){this.a=a
this.b=b
this.c=c},
np:function np(){},
eb:function eb(a,b){this.a=a
this.b=b},
IG(){if($.B7)return
$.B7=!0
A.Hl()
A.Hm()
A.Hk()},
Hl(){A.cB("keyboard",new A.ve(),!1)
A.cB("history",new A.vf(),!1)
A.cB("clipboard",new A.vg(),!1)
A.cB("input",new A.vh(),!1)
A.cB("uploader",new A.vi(),!1)
A.cB("imageResize",new A.vj(),!1)
A.cB("table",new A.vk(),!1)
A.cB("syntax",new A.vl(),!1)
A.cB("uiNode",new A.vm(),!1)
A.cB("tableEmbed",new A.vn(),!1)},
Hm(){A.zM("bubble",new A.vo())
A.zM("snow",new A.vp())},
Hk(){var s,r,q=null,p="code-block-container",o="list-container",n=A.a([new A.X("block",5,new A.uR(),B.ab,B.i,q,q,q,!1),new A.X("break",3,new A.uS(),B.cX,B.i,q,q,q,!1),new A.X("cursor",3,new A.uT(),B.F,B.ek,q,q,q,!1),new A.X("text",3,new A.v3(),B.i,B.i,q,q,q,!1),new A.X("inline",3,new A.v7(),B.F,B.i,q,q,q,!1),new A.X("bold",3,A.HM(),B.ac,B.i,q,q,q,!1),new A.X("italic",3,new A.v8(),B.aa,B.i,q,q,q,!1),new A.X("underline",3,new A.v9(),B.dF,B.i,q,q,q,!1),new A.X("strike",3,new A.va(),B.ad,B.i,q,q,q,!1),new A.X("link",3,new A.vb(),B.cU,B.i,q,A.Ja(),q,!1),new A.X("code",3,new A.vc(),B.d_,B.i,q,q,q,!1),new A.X(p,5,new A.vd(),B.V,B.aV,q,q,q,!1),new A.X("code-block",5,new A.uU(),B.V,B.b6,p,new A.uV(),q,!1),new A.X("blockquote",5,new A.uW(),B.cV,B.i,q,new A.uX(),q,!1),new A.X("header",5,new A.uY(),B.w,B.i,q,new A.uZ(),q,!1),new A.X(o,5,A.Jb(),B.aZ,B.i,q,q,q,!1),new A.X("list",5,A.Jc(),B.aW,B.i,o,new A.v_(),q,!1),new A.X("script",3,new A.v0(),B.dz,B.i,q,A.JM(),q,!1),new A.X("image",3,new A.v1(),B.db,B.i,q,new A.v2(),A.IC(),!0),new A.X("formula",3,new A.v4(),B.F,B.dx,q,q,A.Im(),!0)],t.nw)
B.a.H(n,A.K4())
n.push(new A.X("video",5,new A.v5(),B.da,B.cI,q,new A.v6(),A.Kp(),!0))
for(s=n.length,r=0;r<n.length;n.length===s||(0,A.k)(n),++r)A.dd(n[r],!1)
A.zX(q)
for(n=A.l(["attributors/attribute/direction",$.yz(),"attributors/class/align",$.yw(),"attributors/class/background",$.C6(),"attributors/class/color",$.C8(),"attributors/class/direction",$.yA(),"attributors/class/font",$.yC(),"attributors/class/size",$.yE(),"attributors/style/align",$.yx(),"attributors/style/background",$.wS(),"attributors/style/color",$.wT(),"attributors/style/direction",$.yB(),"attributors/style/font",$.yD(),"attributors/style/size",$.yF()],t.N,t.d).gao(),n=n.gJ(n);n.l();){s=n.gq()
A.hV(s.a,s.b,!0)}A.dd($.yw(),!1)
A.dd($.yA(),!1)
A.dd($.Ca(),!1)
A.dd($.wT(),!1)
A.dd($.wS(),!1)
A.dd($.yC(),!1)
A.dd($.yE(),!1)},
Hr(a){var s,r
if(a instanceof A.cb)return a
s=t.G
if(s.b(a)){r=a.h(0,"bindings")
if(s.b(r))return new A.cb(A.Y(r,t.N,t.z))}return new A.cb(B.l)},
Hp(a){var s,r,q,p,o
if(a instanceof A.cu)return a
if(t.G.b(a)){s=a.h(0,"delay")
r=a.h(0,"maxStack")
q=a.h(0,"userOnly")
p=A.cI(s)?s:1000
o=A.cI(r)?r:100
return new A.cu(p,o,A.ef(q)&&q)}return new A.cu(1000,100,!1)},
Ho(a){var s
if(a instanceof A.bp)return a
if(t.G.b(a)){s=a.h(0,"matchers")
if(t.j.b(s))return new A.bp(A.a5(s,!0,t.z))}return new A.bp(B.r)},
Hq(a){if(a instanceof A.dN)return a
return A.Dw(a)},
ve:function ve(){},
vf:function vf(){},
vg:function vg(){},
vh:function vh(){},
vi:function vi(){},
vj:function vj(){},
vk:function vk(){},
vl:function vl(){},
vm:function vm(){},
vn:function vn(){},
vo:function vo(){},
vp:function vp(){},
uR:function uR(){},
uS:function uS(){},
uT:function uT(){},
v3:function v3(){},
v7:function v7(){},
v8:function v8(){},
v9:function v9(){},
va:function va(){},
vb:function vb(){},
vc:function vc(){},
vd:function vd(){},
uV:function uV(){},
uU:function uU(){},
uX:function uX(){},
uW:function uW(){},
uZ:function uZ(){},
uY:function uY(){},
v_:function v_(){},
v0:function v0(){},
v2:function v2(){},
uQ:function uQ(){},
v1:function v1(){},
v4:function v4(){},
v6:function v6(){},
uP:function uP(){},
v5:function v5(){},
oU:function oU(a){this.a=a},
aA:function aA(){},
dd(a,b){var s,r
if(typeof a=="string"){A.hV(a,b,!1)
return}if(t.G.b(a)){for(s=a.gao(),s=s.gJ(s);s.l();){r=s.gq()
A.hV(J.L(r.a),r.b,b)}return}if(a instanceof A.X){A.hV("formats/"+a.a,a,b)
return}if(a instanceof A.aj){A.hV("formats/"+a.a,a,b)
return}throw A.i(A.au("Unsupported registration type: "+J.yS(a).B(0),null))},
hV(a,b,c){if(!c&&$.oW.p(a))return
$.oW.j(0,a,b)
if(!B.b.a0(a,"formats/"))return
if(b instanceof A.X)$.zL.j(0,b.a,b)
else if(b instanceof A.aj)$.zK.j(0,b.a,b)},
cB(a,b,c){if(!c&&$.xs.p(a))return
$.xs.j(0,a,b)
$.oW.j(0,"modules/"+a,b)},
zM(a,b){var s=$.lu(),r=s.p(a)
if(r)return
s.j(0,a,b)
$.oW.j(0,"themes/"+a,b)},
Eb(a,b,c){var s=$.xs.h(0,b)
if(s==null)return null
return s.$2(a,c)},
Ea(a){var s
if(a!=null&&$.lu().p(a)){s=$.lu().h(0,a)
s.toString
return s}s=$.lu().h(0,"default")
s.toString
return s},
E6(a,b){var s=t.N
s=new A.ab(a,new A.jw(A.b(s,t.eO),A.b(s,t.tb)))
s.nh(a,b)
return s},
H2(a){var s=t.N,r=t.z,q=A.l(["keyboard",A.b(s,r),"history",A.b(s,r),"clipboard",A.b(s,r),"input",A.b(s,r),"uploader",A.b(s,r),"imageResize",A.b(s,r),"table",A.b(s,r)],s,r)
q.H(0,a.d)
s=A.Aj(a.c,a.b,q,a.e,!1,a.a)
return s},
G6(a){return B.a.ag(a.a,0,new A.uC(),t.S)},
ab:function ab(a,b){var _=this
_.a=a
_.c=_.b=$
_.d=b
_.Q=_.z=_.y=_.x=_.w=_.r=_.f=_.e=$},
oX:function oX(){},
oY:function oY(a){this.a=a},
oZ:function oZ(a){this.a=a},
oV:function oV(a){this.a=a},
p7:function p7(a){this.a=a},
p5:function p5(a,b){this.a=a
this.b=b},
p6:function p6(a,b){this.a=a
this.b=b},
p4:function p4(a,b,c){this.a=a
this.b=b
this.c=c},
p0:function p0(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
p1:function p1(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
p2:function p2(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
p3:function p3(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
p_:function p_(a,b,c){this.a=a
this.b=b
this.c=c},
uC:function uC(){},
JR(a,b,c,d){var s=new A.wD(b,d,c),r=a.a,q=s.$1(r)
return new A.G(q,Math.max(0,s.$1(r+a.b)-q))},
Ei(a,b){var s=new A.po(a,b)
s.ni(a,b)
return s},
G:function G(a,b){this.a=a
this.b=b},
fu:function fu(a,b){this.a=a
this.b=b},
op:function op(a,b,c){this.a=a
this.b=b
this.c=c},
wD:function wD(a,b,c){this.a=a
this.b=b
this.c=c},
po:function po(a,b){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=null
_.w=_.r=!1
_.x=null},
pz:function pz(a){this.a=a},
pr:function pr(a){this.a=a},
pA:function pA(a){this.a=a},
pq:function pq(a,b){this.a=a
this.b=b},
pp:function pp(a){this.a=a},
pB:function pB(a){this.a=a},
pv:function pv(a){this.a=a},
pw:function pw(a){this.a=a},
pu:function pu(a,b){this.a=a
this.b=b},
px:function px(a){this.a=a},
py:function py(a){this.a=a},
ps:function ps(a){this.a=a},
pt:function pt(a){this.a=a},
pD:function pD(a,b){this.a=a
this.b=b},
pC:function pC(){},
Aj(a,b,c,d,e,f){var s=A.Y(c,t.N,t.z)
return new A.cG(f,b,a,s,d,!1)},
Ez(a,b){var s=t.N,r=t.z
r=new A.ck(a,b,A.b(s,r),A.b(s,r),A.b(s,r))
r.h5()
return r},
kh:function kh(a,b){this.a=a
this.b=b},
cG:function cG(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
ck:function ck(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
rE:function rE(a){this.a=a},
B4(a,b,c,d,e,f){var s=a<c
if(s&&b>d)return 0
if(s)return-(c-a+e)
if(b>d)return b-a>d-c?a+e-c:b-d+f
return 0},
Gh(a){var s,r,q,p,o,n,m,l,k,j=$.y().a.ce(a)
if(j==null)return null
s=j.h(0,"width")
r=s==null?null:s
if(r==null)r=A.aF(j.h(0,"right"))-A.aF(j.h(0,"left"))
s=j.h(0,"height")
q=s==null?null:s
if(q==null)q=A.aF(j.h(0,"bottom"))-A.aF(j.h(0,"top"))
p=a.gdt()===0?0:Math.abs(r)/a.gdt()
o=a.glo()===0?0:Math.abs(q)/a.glo()
n=p===0?1:p
m=o===0?1:o
l=A.aF(j.h(0,"left"))
k=A.aF(j.h(0,"top"))
s=a.a
return new A.fw(k,l+A.v(s.clientWidth)*n,k+A.v(s.clientHeight)*m,l)},
JN(a6,a7,a8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3="^[-+]?\\d+(?:\\.\\d+)?",a4={},a5=t.A.a(a6.a.ownerDocument)
a5.toString
s=new A.bu(a5)
r=A.a([],t.kz)
a5=a4.a=a6
for(q=a7;a5!=null;a5=a2){p=a5.n(0,s.gcq())
a5=$.y().a
o=a5.iF(s)
if(p){n=o.h(0,"width")
n.toString
m=o.h(0,"height")
m.toString
l=new A.fw(0,n,m,0)}else l=A.Gh(a4.a)
if(l==null)break
n=new A.wC(a4)
m=q.d
k=q.b
j=l.d
i=l.b
h=n.$1("scroll-padding-left")
g=A.D(a3,!0,!1).bk(B.b.R(h))
if(g==null)h=0
else{h=g.b
if(0>=h.length)return A.d(h,0)
h=h[0]
h.toString
h=A.bg(h)
if(h==null)h=0}f=n.$1("scroll-padding-right")
g=A.D(a3,!0,!1).bk(B.b.R(f))
if(g==null)f=0
else{f=g.b
if(0>=f.length)return A.d(f,0)
f=f[0]
f.toString
f=A.bg(f)
if(f==null)f=0}e=A.B4(m,k,j,i,h,f)
f=q.a
h=q.c
i=l.a
j=l.c
d=n.$1("scroll-padding-top")
g=A.D(a3,!0,!1).bk(B.b.R(d))
if(g==null)d=0
else{d=g.b
if(0>=d.length)return A.d(d,0)
d=d[0]
d.toString
d=A.bg(d)
if(d==null)d=0}c=n.$1("scroll-padding-bottom")
g=A.D(a3,!0,!1).bk(B.b.R(c))
if(g==null)c=0
else{c=g.b
if(0>=c.length)return A.d(c,0)
c=c[0]
c.toString
c=A.bg(c)
if(c==null)c=0}b=A.B4(f,h,i,j,d,c)
if(e!==0||b!==0){j=a4.a
i=j.a
a=B.f.ah(A.a9(i.scrollLeft))
a0=B.f.ah(A.a9(i.scrollTop))
j.mn(e,b)
B.a.k(r,new A.lc(a4.a,e,b))
if(!p){j=a4.a.a
i=-(B.f.ah(A.a9(j.scrollLeft))-a)
j=-(B.f.ah(A.a9(j.scrollTop))-a0)
q=new A.fw(f+j,k+i,h+j,m+i)}}a1=J.A(n.$1("position"),"fixed")
a2=p||a1?null:a5.me(a4.a)
a4.a=a2}},
fw:function fw(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
pa:function pa(){},
lc:function lc(a,b,c){this.a=a
this.b=b
this.c=c},
wC:function wC(a){this.a=a},
bQ(a,b){var s
if(a==null||a.a===0)return A.b(t.N,t.z)
s=A.b(t.N,t.z)
a.O(0,new A.mW(b,s))
return s},
mZ(a,b){var s,r,q=a!=null
if(!q||a.ga6(a))s=b==null||b.a===0
else s=!1
if(s)return null
r=A.b(t.N,t.z)
if(q)r.H(0,a)
if(b!=null)r.H(0,b)
return r.a===0?null:r},
mS(a){var s
if(a instanceof A.r)return new A.r(A.a5(a.a,!0,t.Q))
if(t.j.b(a)){s=J.el(a,A.Ia(),t.z)
return A.N(s,!0,s.$ti.i("ad.E"))}if(t.G.b(a)){s=t.z
return a.bo(0,new A.mT(),s,s)}return a},
Db(a,b,c){var s,r,q,p,o,n,m,l,k=A.bQ(a,!0),j=A.bQ(b,!0)
if(k.a===0&&j.a===0)return null
s=t.N
r=A.b(s,t.z)
s=A.xl(new A.as(k,A.u(k).i("as<1>")),s)
s.H(0,new A.as(j,A.u(j).i("as<1>")))
for(s=A.xU(s,s.r,A.u(s).c),q=s.$ti.c;s.l();){p=s.d
if(p==null)p=q.a(p)
o=$.hz.h(0,p)
if(o==null)continue
n=k.h(0,p)
m=j.h(0,p)
l=o.a.$3$keepNull(n,m,c)
if(l!=null)r.j(0,p,l)}return r.a===0?null:r},
Dc(a,b,c){var s,r={}
if(b.a===0||!t.G.b(a))return null
r.a=!1
s=a.bo(0,new A.mU(),t.N,t.z)
b.O(0,new A.mV(r,s,c))
return r.a?s:null},
De(a,b,c){var s,r,q,p,o,n,m,l,k=A.bQ(a,!0),j=A.bQ(b,!0)
if(k.a===0&&j.a===0)return null
s=t.N
r=A.b(s,t.z)
s=A.xl(new A.as(k,A.u(k).i("as<1>")),s)
s.H(0,new A.as(j,A.u(j).i("as<1>")))
for(s=A.xU(s,s.r,A.u(s).c),q=s.$ti.c;s.l();){p=s.d
if(p==null)p=q.a(p)
o=$.hz.h(0,p)
if(o==null)continue
n=k.h(0,p)
m=j.h(0,p)
l=o.b.$3(n,m,c)
if(l!=null)r.j(0,p,l)}return r.a===0?null:r},
Dd(a,b){var s,r,q={},p=A.bQ(a,!0)
if(p.a===0)return A.b(t.N,t.z)
s=A.bQ(b.ga9(),!0)
q.a=null
if(b.a==="insert"&&t.G.b(b.c))q.a=t.G.a(b.c).bo(0,new A.mX(),t.N,t.z)
r=A.b(t.N,t.z)
p.O(0,new A.mY(q,s,r))
return r},
z9(a,b,c){var s
if(a==null)return b
if(b==null)return null
if(!c)return b
s=new A.as(b,A.u(b).i("as<1>")).ag(0,A.b(t.N,t.z),new A.n7(a,b),t.P)
return s.ga6(s)?null:s},
z7(a,b,c){var s,r,q,p,o
if(a==null)a=B.l
if(b==null)b=B.l
s=A.Y(a,t.N,t.z)
s.H(0,b)
r=A.u(s).i("as<1>")
q=A.N(new A.as(s,r),!1,r.i("o.E"))
if(!c)for(r=q.length,p=0;p<r;++p){o=q[p]
if(s.h(0,o)==null)s.Z(0,o)}return s.a===0?null:s},
z8(a,b){var s,r,q,p={}
p.a=a
p.b=b
if(a==null)p.a=B.l
s=t.z
r=(b==null?p.b=B.l:b).ga7().ag(0,A.b(s,s),new A.n3(p),s)
q=t.G
return A.Y(p.a.ga7().ag(0,q.a(r),new A.n4(p),q),t.N,s)},
dG(a,b){var s,r,q,p,o
if(a==null)a=B.l
if(b==null)b=B.l
s=A.b(t.N,t.z)
for(r=J.wY(a.ga7()),B.a.H(r,b.ga7()),q=r.length,p=0;p<r.length;r.length===q||(0,A.k)(r),++p){o=r[p]
if(!J.A(a.h(0,o),b.h(0,o)))s.j(0,o,b.p(o)?b.h(0,o):null)}return!new A.as(s,s.$ti.i("as<1>")).ga6(0)?s:null},
x3(a){var s=J.el(a,new A.n2(null),t.Q)
return new A.r(A.N(s,!0,s.$ti.i("ad.E")))},
jv:function jv(a,b,c){this.a=a
this.b=b
this.c=c},
r:function r(a){this.a=a
this.b=0},
mW:function mW(a,b){this.a=a
this.b=b},
mT:function mT(){},
mU:function mU(){},
mV:function mV(a,b,c){this.a=a
this.b=b
this.c=c},
mX:function mX(){},
mY:function mY(a,b,c){this.a=a
this.b=b
this.c=c},
n7:function n7(a,b){this.a=a
this.b=b},
n3:function n3(a){this.a=a},
n4:function n4(a){this.a=a},
n2:function n2(a){this.a=a},
n6:function n6(){},
n_:function n_(a,b){this.a=a
this.b=b},
n0:function n0(a,b){this.a=a
this.b=b},
n1:function n1(){},
n5:function n5(a,b){this.a=a
this.b=b},
c7:function c7(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=0},
He(a){return a},
bW(a,b,c,d){return new A.aZ(a,b,c,d!=null?A.Y(d,t.N,t.z):null)},
oz(a,b){return A.bW("insert",typeof a=="string"?a.length:1,a,b)},
DR(a,b){var s,r,q="insert",p="attributes",o="delete",n="retain",m=A.Y(a,t.N,t.z)
if(m.p(q)){s=m.h(0,q)
a=A.He(s==null?t.K.a(s):s)
r=typeof a=="string"?a.length:1
return A.bW(q,r,a,t.yq.a(m.h(0,p)))}else if(m.p(o))return A.bW(o,A.lk(m.h(0,o)),"",null)
else if(m.p(n))return A.bW(n,A.lk(m.h(0,n)),"",t.yq.a(m.h(0,p)))
throw A.i(A.hp(a,"Invalid data for Delta operation.",null))},
aZ:function aZ(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
oA:function oA(){},
Bz(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=A.a([],t.X)
for(s=!1,r=null,q=0,p=0,o=0,n=0,m=0;l=a.length,q<l;){if(!(q>=0))return A.d(a,q)
l=a[q]
k=l.a
j=0
i=0
if(k===0){B.a.k(c,q)
if(!(q<a.length))return A.d(a,q)
r=a[q].b
o=m
m=i
p=n
n=j}else{l=l.b.length
if(k===1)n+=l
else m+=l
if(r!=null){l=r.length
l=l<=Math.max(p,o)&&l<=Math.max(n,m)}else l=!1
if(l){B.a.V(a,B.a.gK(c),new A.aw(-1,r))
l=B.a.gK(c)+1
if(!(l>=0&&l<a.length))return A.d(a,l)
a[l].a=1
if(0>=c.length)return A.d(c,-1)
c.pop()
l=c.length
if(l!==0){if(0>=l)return A.d(c,-1)
c.pop()}q=c.length===0?-1:B.a.gK(c)
m=i
n=j
s=!0
r=null
p=0
o=0}}++q}if(s)A.ye(a)
A.HO(a)
for(q=1;q<a.length;){l=q-1
k=a[l]
if(k.a===-1&&a[q].a===1){h=k.b
g=a[q].b
f=A.BE(h,g)
e=A.BE(g,h)
if(f>=e){k=h.length
if(f>=k/2||f>=g.length/2){B.a.V(a,q,new A.aw(0,B.b.t(g,0,f)))
d=a.length
if(!(l<d))return A.d(a,l)
a[l].b=B.b.t(h,0,k-f);++q
if(!(q<d))return A.d(a,q)
a[q].b=B.b.L(g,f)}}else if(e>=h.length/2||e>=g.length/2){B.a.V(a,q,new A.aw(0,B.b.t(h,0,e)))
B.a.j(a,l,new A.aw(1,B.b.t(g,0,g.length-e)));++q
B.a.j(a,q,new A.aw(-1,B.b.L(h,e)))}++q}++q}},
HO(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=new A.vA()
for(s=a.$flags|0,r=1;q=a.length,r<q-1;){p=r-1
if(!(p>=0))return A.d(a,p)
o=a[p]
if(o.a===0){n=r+1
if(!(n>=0))return A.d(a,n)
n=a[n].a===0}else n=!1
if(n){m=o.b
if(!(r>=0))return A.d(a,r)
l=a[r].b
k=a[r+1].b
j=A.vB(m,l)
if(j!==0){q=l.length-j
i=B.b.L(l,q)
m=B.b.t(m,0,m.length-j)
l=i+B.b.t(l,0,q)
k=i+k}q=c.$2(m,l)
o=c.$2(l,k)
if(typeof q!=="number")return q.lY()
if(typeof o!=="number")return A.ym(o)
h=q+o
g=k
f=l
e=m
while(!0){q=l.length
o=!1
if(q!==0){n=k.length
if(n!==0){if(0>=q)return A.d(l,0)
o=l[0]
if(0>=n)return A.d(k,0)
o=o===k[0]}}if(!o)break
if(0>=q)return A.d(l,0)
m+=l[0]
q=B.b.L(l,1)
if(0>=k.length)return A.d(k,0)
l=q+k[0]
k=B.b.L(k,1)
q=c.$2(m,l)
o=c.$2(l,k)
if(typeof q!=="number")return q.lY()
if(typeof o!=="number")return A.ym(o)
d=q+o
if(d>=h){h=d
g=k
f=l
e=m}}q=a.length
if(!(p<q))return A.d(a,p)
o=a[p]
if(o.b!==e){if(e.length!==0)o.b=e
else{s&1&&A.ak(a,18)
A.b6(p,r,q)
a.splice(p,r-p)
r=p}q=a.length
if(!(r<q))return A.d(a,r)
a[r].b=f
p=r+1
if(g.length!==0){if(!(p<q))return A.d(a,p)
a[p].b=g}else{o=r+2
s&1&&A.ak(a,18)
A.b6(p,o,q)
a.splice(p,o-p);--r}}}++r}},
ye(a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a
B.a.k(a0,new A.aw(0,""))
for(s=a0.$flags|0,r=0,q=0,p=0,o="",n="";m=a0.length,r<m;){if(!(r>=0))return A.d(a0,r)
l=a0[r]
switch(l.a){case 1:++p
n+=l.b;++r
break
case-1:++q
o+=l.b;++r
break
case 0:if(q+p>1){m=q===0
if(!m&&p!==0){k=A.yg(n,o)
if(k!==0){l=r-q-p
if(l>0){j=l-1
if(!(j<a0.length))return A.d(a0,j)
j=a0[j].a===0}else j=!1
if(j){i=l-1
if(!(i>=0&&i<a0.length))return A.d(a0,i)
l=a0[i]
l.b=l.b+B.b.t(n,0,k)}else{B.a.V(a0,0,new A.aw(0,B.b.t(n,0,k)));++r}n=B.b.L(n,k)
o=B.b.L(o,k)}k=A.vB(n,o)
if(k!==0){if(!(r<a0.length))return A.d(a0,r)
l=a0[r]
j=n.length-k
l.b=B.b.L(n,j)+l.b
n=B.b.t(n,0,j)
o=B.b.t(o,0,o.length-k)}}if(m){l=r-p
s&1&&A.ak(a0,18)
A.b6(l,r,a0.length)
a0.splice(l,r-l)
B.a.V(a0,l,new A.aw(1,n))}else{l=r-q
if(p===0){s&1&&A.ak(a0,18)
A.b6(l,r,a0.length)
a0.splice(l,r-l)
B.a.V(a0,l,new A.aw(-1,o))}else{l-=p
s&1&&A.ak(a0,18)
A.b6(l,r,a0.length)
a0.splice(l,r-l)
B.a.V(a0,l,new A.aw(1,n))
B.a.V(a0,l,new A.aw(-1,o))}}m=m?0:1
l=p===0?0:1
r=r-q-p+m+l+1}else{if(r!==0){j=r-1
if(!(j>=0))return A.d(a0,j)
j=a0[j].a===0}else j=!1
h=r+1
if(j){j=r-1
if(!(j>=0))return A.d(a0,j)
j=a0[j]
j.b=j.b+l.b
s&1&&A.ak(a0,18)
A.b6(r,h,m)
a0.splice(r,h-r)}else r=h}q=0
p=0
o=""
n=""
break}}if(B.a.gK(a0).b.length===0){if(0>=a0.length)return A.d(a0,-1)
a0.pop()}for(r=1,g=!1;m=a0.length,r<m-1;){l=r-1
j=a0[l]
if(j.a===0&&a0[r+1].a===0){f=a0[r]
e=f.b
d=j.b
c=!0
if(B.b.be(e,d)){f.b=d+B.b.t(e,0,e.length-d.length)
f=a0[r+1]
f.b=j.b+f.b
s&1&&A.ak(a0,18)
A.b6(l,r,m)
a0.splice(l,r-l)
g=c}else{l=r+1
b=a0[l]
a=b.b
if(B.b.a0(e,a)){j.b=d+a
j=f.b
b=b.b
f.b=B.b.L(j,b.length)+b
b=r+2
s&1&&A.ak(a0,18)
A.b6(l,b,m)
a0.splice(l,b-l)
g=c}}}++r}if(g)A.ye(a0)},
Ic(a,b,c){var s,r,q,p,o,n,m
if(c<=0)return null
s=a.length>b.length
r=s?a:b
q=s?b:a
p=r.length
if(p<4||q.length*2<p)return null
o=A.B0(r,q,B.d.aA(B.f.kP((p+3)/4)))
n=A.B0(r,q,B.d.aA(B.f.kP((p+1)/2)))
p=o==null
if(p&&n==null)return null
else if(n==null)m=o
else if(p)m=n
else m=o[4].length>n[4].length?o:n
if(s)return m
else return A.a([m[2],m[3],m[0],m[1],m[4]],t.s)},
B0(a,b,c){var s,r,q,p,o,n,m,l,k,j,i=a.length,h=B.b.t(a,c,c+B.d.aA(B.f.hK(i/4)))
for(s=-1,r="",q="",p="",o="",n="";s=B.b.bl(b,h,s+1),s!==-1;){m=A.yg(B.b.L(a,c),B.b.L(b,s))
l=A.vB(B.b.t(a,0,c),B.b.t(b,0,s))
if(r.length<l+m){k=s-l
j=s+m
r=B.b.t(b,k,s)+B.b.t(b,s,j)
q=B.b.t(a,0,c-l)
p=B.b.L(a,c+m)
o=B.b.t(b,0,k)
n=B.b.L(b,j)}}if(r.length*2>=i)return A.a([q,p,o,n,r],t.s)
else return null},
hj(a,b,c,d,e){var s,r,q,p,o
if(d==null){d=new A.cN(Date.now(),0,!1)
d=e<=0?d.jm(A.ng(365,0).a):d.jm(A.ng(0,B.d.aA(e*1000)).a)}if(a===b){s=A.a([],t.zM)
if(a.length!==0)B.a.k(s,new A.aw(0,a))
return s}r=A.yg(a,b)
q=B.b.t(a,0,r)
a=B.b.L(a,r)
b=B.b.L(b,r)
r=A.vB(a,b)
p=a.length-r
o=B.b.L(a,p)
s=A.G8(B.b.t(a,0,p),B.b.t(b,0,b.length-r),e,c,d)
if(q.length!==0)B.a.V(s,0,new A.aw(0,q))
if(o.length!==0)B.a.k(s,new A.aw(0,o))
A.ye(s)
return s},
G8(a,b,c,a0,a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=A.a([],t.zM),d=a.length
if(d===0){B.a.k(e,new A.aw(1,b))
return e}s=b.length
if(s===0){B.a.k(e,new A.aw(-1,a))
return e}r=d>s
q=r?a:b
p=r?b:a
o=B.b.ae(q,p)
if(o!==-1){n=r?-1:1
B.a.k(e,new A.aw(n,B.b.t(q,0,o)))
B.a.k(e,new A.aw(0,p))
B.a.k(e,new A.aw(n,B.b.L(q,o+p.length)))
return e}if(p.length===1){B.a.k(e,new A.aw(-1,a))
B.a.k(e,new A.aw(1,b))
return e}m=A.Ic(a,b,c)
if(m!=null){l=m[0]
k=m[1]
j=m[2]
i=m[3]
h=m[4]
g=A.hj(l,j,a0,a1,c)
f=A.hj(k,i,a0,a1,c)
B.a.k(g,new A.aw(0,h))
B.a.H(g,f)
return g}if(a0&&d>100&&s>100)return A.G9(a,b,c,a1)
return A.Ib(a,b,c,a1)},
G9(a,b,c,d){var s,r,q,p,o,n,m,l,k,j,i,h=t.s,g=A.a([],h),f=t.N,e=A.x9(null,null,null,f,t.S)
B.a.k(g,"")
s=A.l(["chars1",A.Bd(a,g,e),"chars2",A.Bd(b,g,e),"lineArray",g],f,t.z)
a=A.h(s.h(0,"chars1"))
b=A.h(s.h(0,"chars2"))
r=t.gR.a(s.h(0,"lineArray"))
if(r==null)r=A.a([],h)
q=A.hj(a,b,!1,d,c)
A.HN(q,r)
A.Bz(q)
B.a.k(q,new A.aw(0,""))
p=new A.a_("")
o=new A.a_("")
for(n=q.$flags|0,m=0,l=0,k=0;h=q.length,m<h;){if(!(m>=0))return A.d(q,m)
f=q[m]
switch(f.a){case 1:++k
o.a+=f.b
break
case-1:++l
p.a+=f.b
break
case 0:if(l>=1&&k>=1){f=m-l-k
n&1&&A.ak(q,18)
A.b6(f,m,h)
q.splice(f,m-f)
h=p.a
j=o.a
s=A.hj(h.charCodeAt(0)==0?h:h,j.charCodeAt(0)==0?j:j,!1,d,c)
for(i=s.length-1;i>=0;--i){if(!(i<s.length))return A.d(s,i)
B.a.V(q,f,s[i])}m=f+s.length}o.a=p.a=""
l=0
k=0
break}++m}if(0>=h)return A.d(q,-1)
q.pop()
return q},
Ib(a8,a9,b0,b1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=a8.length,a2=a9.length,a3=B.d.bC(a1+a2+1,2),a4=2*a3,a5=t.S,a6=A.eB(a4,0,!1,a5),a7=A.eB(a4,0,!1,a5)
for(s=0;s<a4;++s){B.a.j(a6,s,-1)
B.a.j(a7,s,-1)}a5=a3+1
B.a.j(a6,a5,0)
B.a.j(a7,a5,0)
r=a1-a2
a5=B.d.b4(r,2)===0
q=!a5
for(p=a3+r,o=0,n=0,m=0,l=0,k=0;k<a3;++k){if(new A.cN(Date.now(),0,!1).bi(0,b1)===1)break
for(j=-k,i=j+o;i<=k-n;i+=2){h=a3+i
if(i!==j)if(i!==k){g=h-1
if(!(g>=0&&g<a4))return A.d(a6,g)
g=a6[g]
f=h+1
if(!(f>=0&&f<a4))return A.d(a6,f)
f=g<a6[f]
g=f}else g=!1
else g=!0
if(g){g=h+1
if(!(g>=0&&g<a4))return A.d(a6,g)
e=a6[g]}else{g=h-1
if(!(g>=0&&g<a4))return A.d(a6,g)
e=a6[g]+1}d=e-i
while(!0){g=!1
if(e<a1)if(d<a2){if(!(e>=0))return A.d(a8,e)
g=a8[e]
if(!(d>=0))return A.d(a9,d)
g=g===a9[d]}if(!g)break;++e;++d}B.a.j(a6,h,e)
if(e>a1)n+=2
else if(d>a2)o+=2
else if(q){c=p-i
if(c>=0&&c<a4&&a7[c]!==-1){if(!(c>=0&&c<a4))return A.d(a7,c)
if(e>=a1-a7[c])return A.B_(a8,a9,e,d,b0,b1)}}}for(b=j+m;b<=k-l;b+=2){c=a3+b
if(b!==j)if(b!==k){g=c-1
if(!(g>=0&&g<a4))return A.d(a7,g)
g=a7[g]
f=c+1
if(!(f>=0&&f<a4))return A.d(a7,f)
f=g<a7[f]
g=f}else g=!1
else g=!0
if(g){g=c+1
if(!(g>=0&&g<a4))return A.d(a7,g)
a=a7[g]}else{g=c-1
if(!(g>=0&&g<a4))return A.d(a7,g)
a=a7[g]+1}a0=a-b
while(!0){g=!1
if(a<a1)if(a0<a2){g=a1-a-1
if(!(g>=0&&g<a1))return A.d(a8,g)
g=a8[g]
f=a2-a0-1
if(!(f>=0&&f<a2))return A.d(a9,f)
f=g===a9[f]
g=f}if(!g)break;++a;++a0}B.a.j(a7,c,a)
if(a>a1)l+=2
else if(a0>a2)m+=2
else if(a5){h=p-b
if(h>=0&&h<a4&&a6[h]!==-1){if(!(h>=0&&h<a4))return A.d(a6,h)
e=a6[h]
d=a3+e-h
if(e>=a1-a)return A.B_(a8,a9,e,d,b0,b1)}}}}return A.a([new A.aw(-1,a8),new A.aw(1,a9)],t.zM)},
B_(a,b,c,d,e,f){var s=B.b.t(a,0,c),r=B.b.t(b,0,d),q=B.b.L(a,c),p=B.b.L(b,d),o=A.hj(s,r,!1,f,e)
B.a.H(o,A.hj(q,p,!1,f,e))
return o},
Bd(a,b,c){var s,r,q,p,o,n,m,l
for(s=a.length-1,r=t.X,q=0,p=-1,o="";p<s;q=n){p=B.b.bl(a,"\n",q)
if(p===-1)p=s
n=p+1
m=B.b.t(a,q,n)
if(c.p(m)){l=c.h(0,m)
l.toString
l=o+A.i1(A.a([l],r),0,null)
o=l}else{B.a.k(b,m)
c.j(0,m,b.length-1)
o+=A.i1(A.a([b.length-1],r),0,null)}}return o.charCodeAt(0)==0?o:o},
HN(a,b){var s,r,q,p,o,n,m,l,k
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.k)(a),++r){q=a[r]
for(p=q.b,o=p.length,n=b.length,m=0,l="";m<o;++m,l=k){k=p.charCodeAt(m)
if(!(k<n))return A.d(b,k)
k=l+b[k]}q.b=l.charCodeAt(0)==0?l:l}},
yg(a,b){var s,r,q=a.length,p=b.length,o=Math.min(q,p)
for(s=0;s<o;++s){if(!(s<q))return A.d(a,s)
r=a[s]
if(!(s<p))return A.d(b,s)
if(r!==b[s])return s}return o},
vB(a,b){var s,r,q,p=a.length,o=b.length,n=Math.min(p,o)
for(s=1;s<=n;++s){r=p-s
if(!(r>=0))return A.d(a,r)
r=a[r]
q=o-s
if(!(q>=0))return A.d(b,q)
if(r!==b[q])return s-1}return n},
BE(a,b){var s,r,q,p,o,n,m=a.length
if(m===0||b.length===0)return 0
s=b.length
if(m>s)a=B.b.L(a,m-s)
else if(m<s)b=B.b.t(b,0,m)
r=Math.min(m,s)
if(a===b)return r
for(q=0,p=1;!0;){o=B.b.ae(b,B.b.L(a,r-p))
if(o===-1)return q
p+=o
if(o===0||B.b.L(a,r-p)===B.b.t(b,0,p)){n=p+1
q=p
p=n}}},
vA:function vA(){},
aw:function aw(a,b){this.a=a
this.b=b},
z1(a){var s,r,q=A.m(a.a.getAttribute("class"))
if(q==null)q=""
q=B.b.aN(q,A.D("\\s+",!0,!1))
s=A.K(q)
r=s.i("bU<1,e>")
return A.N(new A.bU(new A.an(q,s.i("x(1)").a(new A.mp()),s.i("an<1>")),s.i("e(1)").a(new A.mq()),r),!0,r.i("o.E"))},
zU(a){var s=A.m(a.a.getAttribute("style")),r=t.e
r=new A.a1(A.a((s==null?"":s).split(";"),t.s),t.C.a(new A.pQ()),r).fJ(0,r.i("x(ad.E)").a(new A.pR()))
return A.N(r,!0,r.$ti.i("o.E"))},
Eo(a){return A.iY(a,A.D("#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\\b",!0,!1),t.tj.a(t.pj.a(new A.pO())),null)},
aj:function aj(){},
f7:function f7(a,b){this.a=a
this.b=b
this.c=!1},
lD:function lD(a,b){this.a=a
this.b=b},
hv:function hv(){},
ms:function ms(a){this.a=a},
mr:function mr(a){this.a=a},
mp:function mp(){},
mq:function mq(){},
i2:function i2(){},
pQ:function pQ(){},
pR:function pR(){},
pP:function pP(a){this.a=a},
pO:function pO(){},
pN:function pN(){},
jj:function jj(){},
mG:function mG(){},
j2:function j2(a,b,c){this.a=a
this.b=b
this.c=c},
j3:function j3(a,b,c){this.a=a
this.b=b
this.c=c},
j4:function j4(a,b,c){this.a=a
this.b=b
this.c=c},
j6:function j6(a,b,c){this.a=a
this.b=b
this.c=c},
j8:function j8(a,b,c){this.a=a
this.b=b
this.c=c},
x_(a){return new A.f9(A.b(t.N,t.z),A.a([],t.E),a)},
f9:function f9(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
yW(a){var s,r
if(a instanceof A.f)return new A.d4(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=B.a.gF(B.ac)
r=t.m
s=r.a(r.a(self.document).createElement(s))
return new A.d4(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
d4:function d4(a,b){var _=this
_.z=$
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
x1(a){return new A.dE(A.b(t.N,t.z),A.a([],t.E),a)},
d7:function d7(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
mD:function mD(){},
mE:function mE(){},
dE:function dE(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
mF:function mF(){},
dD:function dD(a,b){var _=this
_.z=$
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
jk:function jk(a,b,c){this.a=a
this.b=b
this.c=c},
jm:function jm(a,b,c){this.a=a
this.b=b
this.c=c},
js:function js(a,b,c){this.a=a
this.b=b
this.c=c},
jt:function jt(a,b,c){this.a=a
this.b=b
this.c=c},
ju:function ju(a,b,c){this.a=a
this.b=b
this.c=c},
jB:function jB(a,b,c){this.a=a
this.b=b
this.c=c},
jC:function jC(a,b,c){this.a=a
this.b=b
this.c=c},
zh(a){var s=new A.fh(a)
s.jh(a)
return s},
Dp(a){return A.m(t.T.a(a).a.getAttribute("data-value"))},
fh:function fh(a){var _=this
_.ax=_.at=_.as=$
_.c=_.b=_.a=null
_.d=a},
xa(a){return new A.dI(A.b(t.N,t.z),A.a([],t.E),a)},
zi(a){var s,r,q=A.cI(a)&&a>=1&&a<=6?a:1
$.y().a.a===$&&A.c()
s=q-1
if(!(s>=0&&s<6))return A.d(B.w,s)
s=B.w[s]
r=t.m
return new A.f(A.b(t.O,t.g),r.a(r.a(self.document).createElement(s)))},
dI:function dI(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
JL(a,b){var s=A.xM(a)
if(s==null)return"//:0"
if(s.gcH().length===0)return a
if(B.a.v(b,s.gcH().toLowerCase()))return a
return"//:0"},
zm(a){var s=new A.fm(a)
s.jh(a)
return s},
zn(a){return B.a.ag(B.b_,A.b(t.N,t.dR),new A.nO(a),t.cw)},
Dv(a){return A.m(t.T.a(a).a.getAttribute("src"))},
fm:function fm(a){var _=this
_.ax=_.at=_.as=$
_.c=_.b=_.a=null
_.d=a},
nO:function nO(a){this.a=a},
jN:function jN(a,b,c){this.a=a
this.b=b
this.c=c},
d9:function d9(a,b){var _=this
_.z=$
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
xi(a){var s,r="about:blank",q=A.xM(a)
if(q==null)return r
s=q.gcH().length===0?null:q.gcH().toLowerCase()
if(s==null)return a
return A.DA(B.dq,new A.oc(s),t.N)!=null?a:r},
DK(a){return A.m(t.T.a(a).a.getAttribute("href"))},
cw:function cw(a,b){var _=this
_.z=$
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
oc:function oc(a){this.a=a},
zA(a){var s
if(a instanceof A.f)return new A.dR(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("OL"))
return new A.dR(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
xm(a){var s=new A.cy(A.b(t.N,t.z),A.a([],t.E),a)
s.ji(a)
return s},
zB(a){var s
if(a instanceof A.f)return A.xm(a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("LI"))
if(a!=null&&!J.A(a,!1)&&A.p(a).length!==0)s.setAttribute("data-list",A.p(a))
return A.xm(new A.f(A.b(t.O,t.g),s))},
dR:function dR(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
of:function of(){},
cy:function cy(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
og:function og(a){this.a=a},
xu(a){var s=A.h(t.T.a(a).a.tagName).toUpperCase()
if(s==="SUB")return"sub"
if(s==="SUP")return"super"
return null},
dW:function dW(a,b){var _=this
_.z=$
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
kp:function kp(a,b,c){this.a=a
this.b=b
this.c=c},
kq:function kq(a,b,c){this.a=a
this.b=b
this.c=c},
df:function df(a,b){var _=this
_.z=$
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
C_(){return"row-"+B.d.ac(B.I.am(1048576),36)},
K4(){var s="table-container",r=null,q="table-body",p="table-row"
return A.a([new A.X(s,5,new A.wI(),B.b0,B.i,r,r,r,!1),new A.X(q,5,new A.wJ(),B.b1,B.i,s,r,r,!1),new A.X(p,5,new A.wK(),B.ae,B.i,q,r,r,!1),new A.X("table",5,new A.wL(),B.b2,B.i,p,r,r,!1)],t.nw)},
A6(a){var s
if(a instanceof A.f)return new A.cD(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("TABLE"))
return new A.cD(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
zZ(a){var s
if(a instanceof A.f)return new A.cC(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("TBODY"))
return new A.cC(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
xE(a){var s
if(a instanceof A.f)return new A.b2(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("TR"))
return new A.b2(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
xy(a){return new A.aG(A.b(t.N,t.z),A.a([],t.E),a)},
kx(a){var s,r
if(a instanceof A.f)return A.xy(a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("TD"))
r=a==null?null:J.L(a)
if(r!=null&&r.length!==0)s.setAttribute("data-row",A.h(r))
else s.setAttribute("data-row",A.C_())
return A.xy(new A.f(A.b(t.O,t.g),s))},
wI:function wI(){},
wJ:function wJ(){},
wK:function wK(){},
wL:function wL(){},
cD:function cD(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
qJ:function qJ(){},
qM:function qM(){},
qL:function qL(){},
qN:function qN(){},
cC:function cC(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
qz:function qz(){},
b2:function b2(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
ra:function ra(){},
aG:function aG(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
dn:function dn(a,b){var _=this
_.z=$
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
EG(a){return B.a.ag(B.aj,A.b(t.N,t.dR),new A.te(a),t.cw)},
EH(a){return A.m(t.T.a(a).a.getAttribute("src"))},
bt:function bt(a){var _=this
_.as=$
_.c=_.b=_.a=null
_.d=a},
te:function te(a){this.a=a},
tf:function tf(a){this.a=a},
F2(a){var s,r=a.x
if(r==null||r.length===0)return A.a([a],t.x)
s=A.K(r)
return new A.a1(r,s.i("q(1)").a(new A.tD(a)),s.i("a1<1,q>"))},
F1(a){return A.iY(A.h(a),A.D("[.*+?^${}()|[\\]\\\\]",!0,!1),t.tj.a(t.pj.a(new A.tC())),null)},
Ff(a,b){return new A.ub(a,b,new A.tE(a.d,A.b(t.sT,t.CF)),A.a([],t.Cu),A.a([],t.ia))},
Fg(a){var s,r,q,p,o=A.a([],t.Cu)
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.k)(a),++r){q=a[r]
p=q.a
if(p.length===0)continue
if(o.length!==0&&B.a.gK(o).b==q.b){B.a.j(o,o.length-1,new A.ct(B.a.gK(o).a+p,q.b))
continue}B.a.k(o,q)}return o},
cZ:function cZ(a,b){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=null
_.f=$
_.w=_.r=null},
tD:function tD(a){this.a=a},
tC:function tC(){},
tE:function tE(a,b){this.a=a
this.b=b},
tF:function tF(a,b){this.a=a
this.b=b},
eX:function eX(a,b){this.a=a
this.b=b},
tA:function tA(a,b,c){this.a=a
this.b=b
this.c=c},
ec:function ec(a,b){this.a=a
this.b=b},
ub:function ub(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
uc:function uc(a,b,c){this.a=a
this.b=b
this.c=c},
GE(a){var s,r,q,p,o,n=A.b(t.N,t.v9)
for(s=0;s<14;++s){r=a[s]
n.j(0,r.a,r)
for(q=r.b,p=q.length,o=0;o<p;++o)n.aQ(q[o],new A.uI(r))}return n},
uI:function uI(a){this.a=a},
q:function q(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o
_.ay=p
_.ch=q},
aY:function aY(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ct:function ct(a,b){this.a=a
this.b=b},
cK:function cK(a,b){this.a=a
this.b=b},
n:function n(a,b,c){this.a=a
this.b=b
this.c=c},
aT(a,b){return new A.k1(a,b)},
Kl(a,b){var s,r,q,p,o,n,m,l,k,j='<span class="ql-formula-error" style="color: ',i=!1
try{o=new A.ud(a)
n=new A.u4(o,B.au,B.av).hg(B.au)
m=o.bW()
if(m.a!==B.E)A.a4(A.aT("unexpected "+m.b,m.c))
s=A.eZ(n)
r=A.ac(i)?"block":"inline"
o=A.p(r)
l=A.p(s)
return'<math xmlns="http://www.w3.org/1998/Math/MathML" display="'+o+'">'+l+"</math>"}catch(k){o=A.bk(k)
if(o instanceof A.k1){q=o
return j+b+'" title="'+A.b_(q.a)+'">'+A.b_(a)+"</span>"}else{p=o
o=A.b_(A.p(p))
l=A.b_(a)
return j+b+'" title="'+o+'">'+l+"</span>"}}},
b_(a){var s=A.O(a,"&","&amp;")
s=A.O(s,"<","&lt;")
s=A.O(s,">","&gt;")
return A.O(s,'"',"&quot;")},
eZ(a){var s=A.K(a)
return new A.a1(a,s.i("e(1)").a(new A.u6()),s.i("a1<1,e>")).bn(0)},
Az(a){var s=a.length
if(s===0)return"<mrow></mrow>"
if(s===1)return B.a.gF(a).a
return"<mrow>"+A.eZ(a)+"</mrow>"},
u5(a,b,c,d){var s='<mo fence="true" stretchy="',r=(a.length!==0?"<mrow>"+(s+d+'">'+A.b_(a)+"</mo>"):"<mrow>")+b
r=(c.length!==0?r+(s+d+'">'+A.b_(c)+"</mo>"):r)+"</mrow>"
return r.charCodeAt(0)==0?r:r},
k1:function k1(a,b){this.a=a
this.b=b},
bK:function bK(a,b){this.a=a
this.b=b},
c4:function c4(a,b,c){this.a=a
this.b=b
this.c=c},
ud:function ud(a){this.a=a
this.b=0
this.c=null},
Q:function Q(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
u4:function u4(a,b,c){this.a=a
this.b=b
this.c=c},
u7:function u7(){},
u6:function u6(){},
FS(a){var s=$.wV()
A.jz(a)
s=s.a.get(a)
return s==null?B.bk:s},
AW(a){var s,r,q,p=A.b(t.N,t.d)
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.k)(a),++r){q=a[r]
p.j(0,q.b,q)}return p},
z2(a,b){var s=new A.d6(A.a([],t.t6),a,b)
s.jg(a,b)
return s},
y2(a){var s=a.a
if(s==="insert")return A.oz(a.c,a.ga9())
if(s==="retain")return A.bW("retain",a.b,"",a.ga9())
s=a.b
return A.bW("delete",s==null?0:s,"",null)},
hf(a,b,c,d){var s,r,q,p,o,n,m,l,k,j,i=d.z,h=i.aw(b,65535)!=null||i.bq(b,65535)!=null,g=A.FS(d).p(b)
if(!h&&!g)return a
s=new A.r(A.a([],t.t))
for(i=a.a,r=i.length,q=c!=null,p=t.N,o=t.z,n=0;n<i.length;i.length===r||(0,A.k)(i),++n){m=i[n]
if(m.a!=="insert"){s.b3(A.y2(m))
continue}l=m.d
if(l==null)k=null
else{l=A.Y(l,p,o)
k=l}if(k==null)k=B.l
if(k.p(b)&&k.h(0,b)!=null){s.b3(A.y2(m))
continue}j=A.b(p,o)
if(q){l=J.a3(c)
l=!l.n(c,!1)&&!l.n(c,"")}else l=!1
if(l)j.j(0,b,c)
j.H(0,k)
l=j.a===0?null:j
s.V(0,m.c,l)}return s},
G4(a){var s,r,q,p,o,n
for(s=a.a,r=s.length,q=0,p=0;p<r;++p){o=s[p]
if(o.a!=="insert")continue
n=o.c
q=typeof n=="string"?q+n.length:q+1}return q},
lq(a,b){var s,r=a.a,q=r.length,p=q-1,o=b.length,n=""
while(!0){if(!(p>=0&&n.length<o))break
if(!(p>=0))return A.d(r,p)
s=r[p].c
if(typeof s!="string")break
n=s+n;--p}return B.b.L(n,Math.max(0,n.length-o))===b},
HB(a){var s,r,q,p,o=a.a
if(o.length===0)return a
s=B.a.gK(o)
r=s.c
if(typeof r!="string"||!B.b.be(r,"\n"))return a
o=A.a5(o,!0,t.Q)
q=new A.r(o)
if(0<0||0>=o.length)return A.d(o,-1)
o.pop()
o=J.aO(r)
p=o.t(r,0,o.gm(r)-1)
if(p.length!==0)q.V(0,p,s.ga9())
return q},
Hg(a){var s,r,q=a.geh()
for(s=t.A;q!=null;){if(q instanceof A.f)return q
r=q.a
if(s.a(r.previousSibling)==null)q=null
else{r=s.a(r.previousSibling)
r.toString
q=A.S(r)}}return null},
H6(a){var s,r,q=a.gcB()
for(s=t.A;q!=null;){if(q instanceof A.f)return q
r=q.a
if(s.a(r.nextSibling)==null)q=null
else{r=s.a(r.nextSibling)
r.toString
q=A.S(r)}}return null},
hl(a,b){if(!(a instanceof A.f))return!1
return B.jU.v(0,A.h(a.a.tagName).toLowerCase())},
FX(a){var s,r,q=A.h(a.a.className)
if(q.length===0)return null
s=A.D("ql-indent-(\\d+)",!0,!1).bk(q)
if(s==null)return null
r=s.b
if(1>=r.length)return A.d(r,1)
r=r[1]
r.toString
return A.V(r,null)},
IJ(a,b){var s=A.Hg(a),r=A.H6(a)
if(s==null||r==null)return!1
return!A.hl(s,b)&&!A.hl(r,b)},
BM(a){var s,r
if(a==null)return!1
s=$.CB()
A.jz(a)
r=s.a
if(r.get(a)==null)if(A.h(a.a.nodeName)==="PRE")s.j(0,a,!0)
else s.j(0,a,A.BM(a.gaG()))
A.jz(a)
s=r.get(a)
s.toString
return s},
yv(a,b,c,d,e){var s=b.a
if(A.v(s.nodeType)===3)return B.a.ag(d,new A.r(A.a([],t.t)),new A.wO(b,a),t.D)
if(A.v(s.nodeType)===1)return B.a.ag(t.T.a(b).gan(),new A.r(A.a([],t.t)),new A.wP(a,c,d,e),t.D)
return new A.r(A.a([],t.t))},
lp(a){return new A.vE(a)},
GX(a){var s=a.a
if(A.h(s.tagName).toUpperCase()==="IFRAME")return!0
return A.I(t.m.a(s.classList).contains("ql-video"))},
y1(a,b){var s,r=a.ba(b)
if(r!=null)s=r!==""
else s=!1
if(!s)return null
return a.dg(b,r)?r:null},
Ji(a,b,c){var s,r,q,p,o,n,m,l,k,j={}
t.I.a(a)
t.D.a(b)
t._.a(c)
if(!(a instanceof A.f))return b
s=t.N
r=A.N(a.gkL(),!0,s)
B.a.H(r,A.z1(a))
B.a.H(r,A.zU(a))
q=A.b(s,t.z)
for(s=r.length,p=c.z,o=0;o<r.length;r.length===s||(0,A.k)(r),++o){n=r[o]
if(n.length===0)continue
m=$.wV()
m=m.a.get(c)
l=(m==null?B.bk:m).h(0,n)
if(l==null)l=p.bq(n,256)
if(l!=null){k=A.y1(l,a)
q.j(0,l.a,k)
if(k!=null)m=k!==""
else m=!1
if(m)continue}l=$.C4().h(0,n)
if(l!=null)m=l.a===n||l.b===n
else m=!1
if(m)q.j(0,l.a,A.y1(l,a))
l=$.Cc().h(0,n)
if(l!=null)m=l.a===n||l.b===n
else m=!1
if(m)q.j(0,l.a,A.y1(l,a))}if(q.a===0)return b
j.a=b
q.O(0,new A.ws(j,c))
return j.a},
Hh(a,b){var s,r,q=b.a,p=A.m(q.getAttribute("class"))
if(p!=null&&p.length!==0){s=a.z.u3(p)
if(s!=null)return s}r=A.h(q.tagName)
if(r.length===0)return null
return a.z.u4(r)},
AV(a,b,c){var s,r
switch(a){case"header":s=B.a.ae(B.w,A.h(b.a.tagName).toUpperCase())+1
return s>0?s:null
case"list":return A.m(b.a.getAttribute("data-list"))
case"code-block":r=A.m(b.a.getAttribute("data-language"))
return r==null?!0:r
case"table":return A.m(b.a.getAttribute("data-row"))
case"link":return A.m(b.a.getAttribute("href"))
case"script":return A.xu(b)
case"blockquote":return!0
default:return!0}},
H1(a,b){var s,r,q,p,o=null,n=a.w,m=n==null?o:n.$1(b)
if(m==null)m=A.H_(a.a,b)
if(m!=null)n=typeof m=="string"&&m.length===0
else n=!0
if(n)return o
n=a.r
s=n==null?o:n.$1(b)
n=t.N
r=t.z
q=A.b(n,r)
if(t.G.b(s))s.O(0,new A.uL(q))
p=new A.r(A.a([],t.t))
r=A.l([a.a,m],n,r)
p.V(0,r,q.a===0?o:q)
return p},
H_(a,b){switch(a){case"image":return A.m(b.a.getAttribute("src"))
case"video":return A.m(b.a.getAttribute("src"))
case"formula":return A.m(b.a.getAttribute("data-value"))}return null},
Jj(a,b,c){var s,r,q,p
t.I.a(a)
t.D.a(b)
t._.a(c)
if(!(a instanceof A.f))return b
s=A.Hh(c,a)
if(s==null)return b
r=s.a
if(s.x||B.jQ.v(0,r)){q=A.H1(s,a)
return q==null?b:q}q=s.r
p=q==null
if(p&&B.jP.v(0,r))return b
if(A.fy(s.b,5)&&!A.lq(b,"\n"))b.aE(0,"\n")
return A.hf(b,r,!p?q.$1(a):A.AV(r,a,c),c)},
Jk(a,b,c){t.I.a(a)
t.D.a(b)
t._.a(c)
if(!A.lq(b,"\n"))b.aE(0,"\n")
return b},
Jl(a,b,c){var s="code-block"
t.I.a(a)
t.D.a(b)
t._.a(c)
return A.hf(b,s,c.z.aw(s,65535)==null||!(a instanceof A.f)?!0:A.AV(s,a,c),c)},
Jm(a,b,c){t.I.a(a)
t.D.a(b)
t._.a(c)
return new A.r(A.a([],t.t))},
Jn(a,a0,a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b
t.I.a(a)
t.D.a(a0)
t._.a(a1)
if(!A.lq(a0,"\n"))return a0
if(!(a instanceof A.f))return a0
s=A.FX(a)
if(s!=null)r=s
else{q=a.gaG()
for(p=t.A,o=-1;q!=null;){if(q instanceof A.f){n=A.h(q.a.tagName).toUpperCase()
if(n==="OL"||n==="UL")++o}m=q.a
if(p.a(m.parentNode)==null)q=null
else{m=p.a(m.parentNode)
m.toString
q=A.S(m)}}r=o}l=A.m(a.a.getAttribute("data-list"))
k=l!=null&&l.length!==0
j=r>0
if(!j&&!k)return a0
i=new A.r(A.a([],t.t))
for(p=a0.a,m=p.length,h=t.N,g=t.z,f=0;f<p.length;p.length===m||(0,A.k)(p),++f){e=p[f]
if(e.a!=="insert"){i.b3(A.y2(e))
continue}d=e.d
if(d==null)c=null
else{d=A.Y(d,h,g)
c=d}if(c==null)c=B.l
b=A.b(h,g)
if(j&&typeof c.h(0,"indent")!="number")b.j(0,"indent",r)
if(k&&!c.p("list"))b.j(0,"list",l)
b.H(0,c)
d=b.a===0?null:b
i.V(0,e.c,d)}return i},
Jo(a,b,c){var s,r,q
t.I.a(a)
t.D.a(b)
t._.a(c)
s=t.T.a(a).a
r=A.h(s.tagName).toUpperCase()==="OL"?"ordered":"bullet"
q=A.m(s.getAttribute("data-checked"))
if(q!=null&&q.length!==0)r=q==="true"?"checked":"unchecked"
return A.hf(b,"list",r,c)},
Jp(a,b,c){var s,r,q,p,o
t.I.a(a)
t.D.a(b)
t._.a(c)
if(A.lq(b,"\n"))return b
s=a.gan().length
r=a instanceof A.f
q=r&&A.h(a.a.tagName)==="P"
if(r){r=a.a
p=A.h(r.tagName)==="TD"||A.h(r.tagName)==="TH"}else p=!1
if(A.hl(a,c))s=s!==0||q||p
else s=!1
if(s){b.aE(0,"\n")
return b}if(b.a.length>0&&a.gcB()!=null){o=a.gcB()
for(s=t.A;o!=null;){if(A.hl(o,c)){b.aE(0,"\n")
return b}if(o instanceof A.f){if(A.GX(o)){b.aE(0,"\n")
return b}r=o.a
if(s.a(r.firstChild)==null)o=null
else{r=s.a(r.firstChild)
r.toString
o=A.S(r)}continue}break}}return b},
Jq(a,b,c){var s,r,q,p,o,n,m,l,k,j,i="underline",h={}
t.I.a(a)
t.D.a(b)
t._.a(c)
s=A.b(t.N,t.z)
r=A.m(t.T.a(a).a.getAttribute("style"))
if(r!=null&&r.length!==0){q=t.s
p=t.e
o=new A.a1(A.a(r.split(";"),q),t.C.a(new A.wt()),p).fJ(0,p.i("x(ad.E)").a(new A.wu()))
for(p=J.U(o.a),n=new A.dq(p,o.b,o.$ti.i("dq<1>"));n.l();){m=A.a(p.gq().split(":"),q)
if(m.length<2)continue
l=B.b.R(m[0])
k=B.b.R(B.a.ab(B.a.dL(m,1),":"))
if(l==="font-weight")if(k!=="bold"){j=A.V(k,null)
j=(j==null?0:j)>=700}else j=!0
else j=!1
if(j)s.j(0,"bold",!0)
else if(l==="font-style"&&k==="italic")s.j(0,"italic",!0)
else{j=l==="text-decoration"
if(j&&B.b.v(k,i))s.j(0,i,!0)
else if(j&&B.b.v(k,"line-through"))s.j(0,"strike",!0)
else{j=l==="vertical-align"
if(j&&k==="super")s.j(0,"script","super")
else if(j&&k==="sub")s.j(0,"script","sub")}}}}if(s.a===0)return b
h.a=b
s.O(0,new A.wv(h,c))
return h.a},
Jr(a,b,c){var s,r,q,p,o
t.I.a(a)
t.D.a(b)
t._.a(c)
if(!(a instanceof A.f))return b
s=a.gaG()
r=s instanceof A.f
if(r&&A.h(s.a.tagName).toUpperCase()==="TABLE")q=s
else if(r){p=s.gaG()
q=p instanceof A.f&&A.h(p.a.tagName).toUpperCase()==="TABLE"?p:null}else q=null
if(q==null)return b
o=B.a.ae(q.a_("tr"),a)+1
if(o<=0)return b
return A.hf(b,"table",o,c)},
Jw(a,b,c){var s,r,q,p,o,n
t.I.a(a)
t.D.a(b)
t._.a(c)
s=A.m(a.a.textContent)
if(s==null)s=""
r=a.gaG()
if(r instanceof A.f&&A.h(r.a.tagName)==="O:P"){b.aE(0,B.b.R(s))
return b}if(!A.BM(a)){if(B.b.R(s).length===0&&B.b.v(s,"\n")&&!A.IJ(a,c))return b
q=A.D("[^\\S\\u00A0]",!0,!1)
s=A.O(s,q," ")
q=A.D(" {2,}",!0,!1)
s=A.O(s,q," ")
p=r!=null&&A.hl(r,c)
o=a.geh()
if(!(o==null&&p))q=o instanceof A.f&&A.hl(o,c)
else q=!0
if(q)s=B.b.b8(s,A.D("^ ",!0,!1),"")
n=a.gcB()
if(!(n==null&&p))q=n instanceof A.f&&A.hl(n,c)
else q=!0
if(q)s=B.b.b8(s,A.D(" $",!0,!1),"")
s=A.O(s,"\xa0"," ")}if(s.length===0)return b
b.aE(0,s)
return b},
bp:function bp(a){this.a=a},
d6:function d6(a,b,c){this.c=a
this.a=b
this.b=c},
mt:function mt(a){this.a=a},
mu:function mu(a){this.a=a},
mv:function mv(a){this.a=a},
mw:function mw(a){this.a=a},
mx:function mx(a){this.a=a},
my:function my(){},
mC:function mC(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mz:function mz(){},
mA:function mA(){},
mB:function mB(a,b){this.a=a
this.b=b},
wO:function wO(a,b){this.a=a
this.b=b},
wP:function wP(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
wM:function wM(a,b){this.a=a
this.b=b},
wN:function wN(a,b){this.a=a
this.b=b},
vE:function vE(a){this.a=a},
ws:function ws(a,b){this.a=a
this.b=b},
uL:function uL(a){this.a=a},
wt:function wt(){},
wu:function wu(){},
wv:function wv(a,b){this.a=a
this.b=b},
zj(a,b){var s=new A.eu(a,b)
s.nc(a,b)
return s},
Is(a,b){var s,r,q=b.a
if(q.length===0)return 0
s=B.a.ag(q,0,new A.vQ(),t.S)
r=A.G5(b)-s
if(A.Ga(a,b))--r
return r<0?0:r},
Bs(a,b){var s,r,q,p,o,n
for(s=a.length-1,r=b;s>=0;--s){if(!(s<a.length))return A.d(a,s)
q=a[s]
p=q.a
o=r.d_(p,!0)
n=A.yu(q.b,r)
r=p.d_(r,!1)
if(o.a.length===0){B.a.cC(a,s)
continue}B.a.j(a,s,new A.fB(o,n))}},
G5(a){return B.a.ag(a.a,0,new A.uB(),t.S)},
Ga(a,b){var s,r,q,p,o,n=b.a
if(n.length===0)return!1
s=B.a.gK(n)
if(s.a==="insert"){r=s.c
if(typeof r=="string")return B.b.be(r,"\n")}q=s.ga9()
if(q==null||q.a===0)return!1
for(n=A.DL(q,q.r,A.u(q).c),p=a.z;n.l();){o=n.d
if(p.aw(o,4)!=null||p.aw(o,260)!=null||B.k3.v(0,o))return!0}return!1},
yu(a,b){var s,r
if(a==null)return null
s=a.a
r=b.lM(s)
return new A.G(r,b.lM(s+a.b)-r)},
eu:function eu(a,b){var _=this
_.e=_.d=_.c=$
_.f=null
_.a=a
_.b=b},
nv:function nv(a,b){this.a=a
this.b=b},
nw:function nw(a){this.a=a},
nx:function nx(a){this.a=a},
ny:function ny(a){this.a=a},
nz:function nz(a){this.a=a},
nA:function nA(a){this.a=a},
cu:function cu(a,b,c){this.a=a
this.b=b
this.c=c},
pM:function pM(a,b){this.a=a
this.b=b},
fB:function fB(a,b){this.a=a
this.b=b},
vQ:function vQ(){},
uB:function uB(){},
Dt(a){var s,r="preserveRatio"
if(a instanceof A.dK)return a
if(t.G.b(a)){s=A.y0(a.h(0,"minimumSize"))
if(s==null)s=null
if(s==null)s=24
return new A.dK(s,!A.ef(a.h(0,r))||A.I(a.h(0,r)))}return B.ck},
Ds(a,b){var s=new A.ey(A.a([],t.r),a,b)
s.nf(a,b)
return s},
Du(a){var s,r=$.hn(),q=r.h(0,"align"),p=null
if(t.G.b(q)){$label0$0:{if("left"===a){s=q.h(0,"")
break $label0$0}if("center"===a){s=q.h(0,"center")
break $label0$0}if("right"===a){s=q.h(0,"right")
break $label0$0}s=p
break $label0$0}p=s}if(p==null)p=r.h(0,"image")
if(typeof p!="string")return""
return B.b.b8(p,"<svg ",'<svg width="18" height="18" ')},
dK:function dK(a,b){this.a=a
this.b=b},
ey:function ey(a,b,c){var _=this
_.c=$
_.e=_.d=null
_.x=_.w=_.r=_.f=0
_.y=a
_.a=b
_.b=c},
nM:function nM(a){this.a=a},
nN:function nN(a,b){this.a=a
this.b=b},
Dw(a){var s
if(a instanceof A.dN)return a
if(t.P.b(a)){s=a.h(0,"listenCompositionBeforeStart")
if(A.ef(s))return new A.dN(s)}return B.aP},
zq(a,b){var s,r=new A.dM(a,b),q=a.b
q===$&&A.c()
q.I("beforeinput",r.goz())
s=b.a
if(s==null?!r.gp8():s)a.d.av("composition-before-start",r.goD())
return r},
dN:function dN(a){this.a=a},
dM:function dM(a,b){this.a=a
this.b=b},
BL(){var s,r
$.y()
s=t.m
r=A.h(s.a(s.a(self.window).navigator).userAgent).toLowerCase()
return B.b.v(r,"mac os")||B.b.v(r,"macintosh")||B.b.v(r,"iphone")||B.b.v(r,"ipad")},
bz(a,b,c,d,e,f,g,h,i,j,k,l,m){return new A.av(g,l,k,a,h,c,j,m,e,f,b,d,i)},
DI(a){return new A.cb(a)},
zx(a,b){var s=new A.bD(A.b(t.z,t.Dl),a,b)
s.ng(a,b)
return s},
DJ(a,b){var s,r
if(!(a instanceof A.cv))return!1
s=b.d
if(s!=null&&s!==A.I(a.a.altKey))return!1
s=b.f
if(s!=null&&s!==A.I(a.a.ctrlKey))return!1
s=b.e
if(s!=null&&s!==A.I(a.a.metaKey))return!1
s=b.c
if(s!=null&&s!==A.I(a.a.shiftKey))return!1
s=a.a
if(!J.A(b.a,A.h(s.key))){r=b.a
s=B.d.B(A.v(s.keyCode))
s=J.A(r,s)}else s=!0
return s},
JA(a){var s,r,q,p=null
if(typeof a=="string"||A.cI(a))s=new A.av(a,p,!1,!1,!1,!1,p,p,p,p,p,p,p)
else if(a instanceof A.av)s=new A.av(a.a,a.b,a.c,a.d,a.e,a.f,a.r,a.w,a.x,a.y,a.z,a.Q,a.as)
else if(t.G.b(a)){s=new A.av(p,p,!1,!1,!1,!1,p,p,p,p,p,p,p)
s.iO(A.Y(a,t.N,t.z))}else s=p
if(s==null)return p
if(s.b!=null){r=A.BL()?"metaKey":"ctrlKey"
q=s.b
if(r==="metaKey")s.e=q
else s.f=q
s.b=null}return s},
iR(a,b){var s,r,q,p,o,n,m=b.b
if(m<=0)return
s=a.c
s===$&&A.c()
r=b.a
q=s.cA(r,m)
s=t.N
p=t.z
o=A.b(s,p)
if(q.length>1){n=B.a.gF(q).P()
o=A.dG(B.a.gK(q).P(),n)
if(o==null)o=A.b(s,p)}s=new A.r(A.a([],t.t))
s.a8(r)
s.aY(m)
a.aM(s,"user")
if(o.a!==0)o.O(0,new A.vH(a,b))
a.S(new A.G(r,0),"silent")},
K5(a,b,c,d){var s=b.b==null
if(s&&b.c==null){s=c.b==null
if(s&&c.c==null)return d===0?-1:1
return s?-1:1}if(s)return-1
if(b.c==null)return 1
return null},
AX(a){var s
for(s=a;s!=null;){if(s.gA()==="table-container")return s
s=s.a}return null},
BQ(a){var s=null,r=A.l(["code-block",!0],t.N,t.v),q=a?A.IS():A.IT()
return new A.av("Tab",s,!a,!1,!1,!1,s,s,r,q,s,s,s)},
Gk(a,b,c){return A.B5(t.p.a(a),t.F.a(b),t.i.a(c),!0)},
Gl(a,b,c){return A.B5(t.p.a(a),t.F.a(b),t.i.a(c),!1)},
B5(a,b,c,d){var s,r,q,p,o,n=a.a,m=b.b,l=m===0
if(l){s=c.r
s=!(s instanceof A.cv&&A.I(s.a.shiftKey))}else s=!1
if(s){l=b.a
n.fc(l,"  ","user")
n.S(new A.G(l+2,0),"silent")
return null}s=n.c
r=b.a
if(l){s===$&&A.c()
q=s.cA(r,1)}else{s===$&&A.c()
q=s.cA(r,m)}for(p=0;p<q.length;++p){o=q[p]
if(d){o.aF(0,"  ")
if(p===0)r+=2
else m+=2}else{l=A.m(o.d.a.textContent)
if(B.b.a0(l==null?"":l,"  ")){o.bS(0,2)
if(p===0)r-=2
else m-=2}}}n.ad("user")
n.S(new A.G(Math.max(0,r),Math.max(0,m)),"silent")
return null},
wp(a,b){var s,r,q=null,p=a==="ArrowLeft"
if(p)s=b?A.IW():A.IV()
else s=b?A.IY():A.IX()
r=new A.av(a,q,b,q,!1,!1,q,q,q,s,q,q,q)
if(p)r.r=A.D("^$",!0,!1)
else r.w=A.D("^$",!0,!1)
return r},
Gn(a,b,c){t.p.a(a)
t.F.a(b)
t.i.a(c)
return A.uH(a,b,"ArrowLeft",!1)},
Go(a,b,c){t.p.a(a)
t.F.a(b)
t.i.a(c)
return A.uH(a,b,"ArrowLeft",!0)},
Gp(a,b,c){t.p.a(a)
t.F.a(b)
t.i.a(c)
return A.uH(a,b,"ArrowRight",!1)},
Gq(a,b,c){t.p.a(a)
t.F.a(b)
t.i.a(c)
return A.uH(a,b,"ArrowRight",!0)},
uH(a,b,c,d){var s="user",r=a.a,q=b.a,p=c==="ArrowRight"?q+(b.b+1):q,o=r.c
o===$&&A.c()
if(!(o.cW(p).a instanceof A.cO))return!0
if(c==="ArrowLeft"){o=q-1
if(d)r.S(new A.G(Math.max(0,o),b.b+1),s)
else r.S(new A.G(Math.max(0,o),0),s)}else{o=b.b
if(d)r.S(new A.G(q,o+1),s)
else r.S(new A.G(q+o+1,0),s)}return!1},
yq(a){var s=null
if(0>=a.length)return A.d(a,0)
return new A.av(a[0],!0,!1,!1,!1,!1,s,s,s,new A.wq(a),s,s,s)},
BR(a){var s=null,r=a?"ArrowUp":"ArrowDown",q=A.a(["table"],t.s)
return new A.av(r,s,!1,!1,!1,!1,s,s,q,a?A.J9():A.J6(),!0,s,s)},
GD(a,b,c){t.p.a(a)
t.F.a(b)
A.B6(a,t.i.a(c),!0)
return!1},
Gz(a,b,c){t.p.a(a)
t.F.a(b)
A.B6(a,t.i.a(c),!1)
return!1},
B6(a,b,c){var s,r,q,p,o,n,m,l,k=null,j="user",i=a.a,h=b.w,g=h.a
if(c)s=g==null?k:g.b
else s=g==null?k:g.c
if(s!=null){if(s.gA()==="table-row"&&s instanceof A.z){r=s.e
q=r.length!==0?B.a.gF(r):k
p=h
while(!0){if(!((p==null?k:p.b)!=null&&q!=null))break
p=p.b
q=q.c}if(q!=null){r=i.c
r===$&&A.c()
o=r.aP(q)
if(o>=0)i.S(new A.G(Math.max(0,o+Math.min(b.c,q.E(0)-1)),0),j)}}}else{n=A.AX(h)
if(c)m=n==null?k:n.b
else m=n==null?k:n.c
if(m!=null){r=i.c
r===$&&A.c()
l=r.aP(m)
if(l>=0)if(c)i.S(new A.G(Math.max(0,l+m.E(0)-1),0),j)
else i.S(new A.G(l,0),j)}}return!1},
Gs(a,b,c){t.p.a(a)
t.F.a(b)
t.i.a(c)
if(c.a&&c.c!==0)return!0
a.a.aD("indent","+1","user")
return!1},
Gv(a,b,c){t.p.a(a)
t.F.a(b)
t.i.a(c)
if(c.a&&c.c!==0)return!0
a.a.aD("indent","-1","user")
return!1},
Gw(a,b,c){var s
t.p.a(a)
t.F.a(b)
s=t.i.a(c).f
if(s.h(0,"indent")!=null)a.a.aD("indent","-1","user")
else if(s.h(0,"list")!=null)a.a.aD("list",!1,"user")
return null},
Gx(a,b,c){var s
t.p.a(a)
t.F.a(b)
t.i.a(c)
s=b.a
if(s<=0)return null
a.a.ro(s-1,1,"user")
return null},
Gy(a,b,c){var s,r,q,p
t.p.a(a)
t.F.a(b)
s=t.i.a(c).f.h(0,"table")
if(s!=null){r=J.a3(s)
s=!r.n(s,!1)&&!r.n(s,"")}else s=!1
if(s)return!0
q=a.a
s=q.z
s===$&&A.c()
s.d=0
p=new A.r(A.a([],t.t))
r=b.a
p.a8(r)
p.aY(b.b)
p.aE(0,"\t")
q.aM(p,"user")
s.d=0
q.S(new A.G(r+1,0),"silent")
return!1},
Gi(a,b,c){t.p.a(a)
t.F.a(b)
t.i.a(c)
a.a.aD("blockquote",!1,"user")
return null},
Gu(a,b,c){var s,r,q,p,o
t.p.a(a)
t.F.a(b)
t.i.a(c)
s=a.a
r=b.a
q=b.b
s.e5(r,q,"list",!1,"user")
p=c.f.h(0,"indent")
if(p!=null){o=J.a3(p)
p=!o.n(p,!1)&&!o.n(p,"")}else p=!1
if(p)s.e5(r,q,"indent",!1,"user")
return null},
Gj(a,b,c){var s,r,q,p,o,n,m,l
t.p.a(a)
t.F.a(b)
t.i.a(c)
s=a.a
r=b.a
q=s.c
q===$&&A.c()
p=q.ap(r)
o=p.a
if(o==null)return null
q=t.N
n=t.z
m=A.aJ(o.P(),q,n)
m.j(0,"list","checked")
l=new A.r(A.a([],t.t))
l.a8(r)
l.V(0,"\n",m)
l.a8(Math.max(0,o.E(0)-p.b-1))
l.br(1,A.l(["list","unchecked"],q,n))
s.aM(l,"user")
s.S(new A.G(r+1,0),"silent")
s.b5()
return null},
Gr(a,b,c){var s,r,q,p,o,n,m
t.p.a(a)
t.F.a(b)
t.i.a(c)
s=a.a
r=b.a
q=s.c
q===$&&A.c()
p=q.ap(r)
o=p.a
if(o==null)return null
n=new A.r(A.a([],t.t))
n.a8(r)
q=t.N
m=t.z
n.V(0,"\n",A.Y(c.f,q,m))
n.a8(Math.max(0,o.E(0)-p.b-1))
n.br(1,A.l(["header",null],q,m))
s.aM(n,"user")
s.S(new A.G(r+1,0),"silent")
s.b5()
return null},
GB(a,b,c){t.p.a(a)
t.F.a(b)
t.i.a(c)
return null},
GA(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h=null,g="user"
t.p.a(a)
t.F.a(b)
t.i.a(c)
s=a.a
r=s.w
r===$&&A.c()
q=r.c.h(0,"table")
if(q instanceof A.bF){p=q.cf(b)
o=p.a
n=p.b
m=p.c
l=p.d}else{m=c.w
n=m.a
o=A.AX(m)
l=c.c}if(o==null||n==null||m==null)return h
k=A.K5(o,n,m,l)
if(k==null)return h
r=s.c
r===$&&A.c()
j=r.aP(o)
if(j<0)return h
if(k<0){i=new A.r(A.a([],t.t))
i.a8(j)
i.aE(0,"\n")
s.aM(i,g)
s.S(new A.G(b.a+1,b.b),"silent")}else if(k>0){j+=o.E(0)
i=new A.r(A.a([],t.t))
i.a8(j)
i.aE(0,"\n")
s.aM(i,g)
s.S(new A.G(j,0),g)}return h},
GC(a,b,c){var s,r,q,p
t.p.a(a)
t.F.a(b)
t.i.a(c)
s=a.a
r=c.w
q=s.c
q===$&&A.c()
p=q.aP(r)
if(p<0)return null
q=c.r
if(q instanceof A.cv&&A.I(q.a.shiftKey))s.S(new A.G(Math.max(0,p-1),0),"user")
else s.S(new A.G(p+r.E(0),0),"user")
return null},
Gt(a,b,c){var s,r,q,p,o,n,m,l,k,j
t.p.a(a)
t.F.a(b)
t.i.a(c)
s=a.a
r=s.c
r===$&&A.c()
if(r.z.aw("list",65535)==null)return!0
q=c.d
p=q.length
o=b.a
n=r.ap(o)
m=n.a
l=n.b
if(m==null||l>p)return!0
switch(B.b.R(q)){case"[]":case"[ ]":k="unchecked"
break
case"[x]":k="checked"
break
case"-":case"*":k="bullet"
break
default:k="ordered"}s.fc(o," ","user")
r=s.z
r===$&&A.c()
r.d=0
j=new A.r(A.a([],t.t))
j.a8(Math.max(0,o-l))
j.aY(p+1)
j.a8(Math.max(0,m.E(0)-2-l))
j.br(1,A.l(["list",k],t.N,t.z))
s.aM(j,"user")
r.d=0
s.S(new A.G(Math.max(0,o-p),0),"silent")
return!1},
Gm(a,b,c){var s,r,q,p,o,n,m,l,k
t.p.a(a)
t.F.a(b)
t.i.a(c)
s=a.a
r=b.a
q=s.c
q===$&&A.c()
p=q.ap(r)
o=p.a
if(o==null)return!0
n=o
m=2
while(!0){q=!1
if(n!=null)if(n.E(0)<=1){l=n.P().h(0,"code-block")
if(l!=null){q=J.a3(l)
q=!q.n(l,!1)&&!q.n(l,"")}}if(!q)break
n=n.b;--m
if(m<=0){k=new A.r(A.a([],t.t))
k.a8(Math.max(0,r+o.E(0)-p.b-2))
k.br(1,A.l(["code-block",null],t.N,t.z))
k.aY(1)
s.aM(k,"user")
s.S(new A.G(Math.max(0,r-1),0),"silent")
return!1}}return!0},
oj:function oj(){},
bP:function bP(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
av:function av(a,b,c,d,e,f,g,h,i,j,k,l,m){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m},
cT:function cT(a,b,c,d,e,f,g,h,i,j,k,l,m){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m},
cb:function cb(a){this.a=a},
bD:function bD(a,b,c){this.c=a
this.a=b
this.b=c},
o1:function o1(a){this.a=a},
o2:function o2(){},
o0:function o0(a,b){this.a=a
this.b=b},
o_:function o_(){},
o6:function o6(a){this.a=a},
o7:function o7(a,b,c){this.a=a
this.b=b
this.c=c},
o4:function o4(a){this.a=a},
o5:function o5(a,b,c){this.a=a
this.b=b
this.c=c},
o3:function o3(a,b){this.a=a
this.b=b},
vH:function vH(a,b){this.a=a
this.b=b},
wq:function wq(a){this.a=a},
oo:function oo(a){this.a=a},
Hd(a,b){var s,r,q,p,o,n=null,m=A.m(a.a.getAttribute("style")),l=m==null,k=l?n:$.Cx().bk(m)
if(k==null)return n
s=k.b
if(1>=s.length)return A.d(s,1)
s=s[1]
r=A.V(s==null?"":s,n)
if(r==null)return n
q=l?n:$.Cz().bk(m)
if(q==null)p=1
else{l=q.b
if(1>=l.length)return A.d(l,1)
l=l[1]
l=A.V(l==null?"":l,n)
p=l==null?1:l}o=A.D("@list l"+A.p(r)+":level"+p+"\\s*\\{[^\\}]*mso-level-number-format:\\s*([\\w-]+)",!1,!1).bk(b)
if(o!=null){l=o.b
if(1>=l.length)return A.d(l,1)
l=l[1]
l=(l==null?n:l.toLowerCase())==="bullet"}else l=!1
return new A.la(r,p,l?"bullet":"ordered",a)},
H5(a){var s,r,q=a.gcB()
for(s=t.A;q!=null;){if(q instanceof A.f)return q
r=q.a
if(s.a(r.nextSibling)==null)q=null
else{r=s.a(r.nextSibling)
r.toString
q=A.S(r)}}return null},
H9(a7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=a7.a_("[style*=mso-list]"),a4=t.r,a5=A.a([],a4),a6=A.a([],a4)
for(a4=a3.length,s=0;s<a3.length;a3.length===a4||(0,A.k)(a3),++s){r=a3[s]
q=A.m(r.a.getAttribute("style"))
if(q==null)q=""
p=$.Cy()
if(p.b.test(q))B.a.k(a5,r)
else B.a.k(a6,r)}for(a4=a5.length,p=t.A,o=t.m,s=0;s<a5.length;a5.length===a4||(0,A.k)(a5),++s){n=a5[s].a
m=p.a(n.parentNode)
if(m!=null)o.a(m.removeChild(n))}l=a7.ghF().gaf()
if(l==null)l=""
a4=t.z3
k=A.a([],a4)
for(n=a6.length,s=0;s<a6.length;a6.length===n||(0,A.k)(a6),++s){j=A.Hd(a6[s],l)
if(j!=null)B.a.k(k,j)}for(n=t.K;k.length!==0;){i=A.a([],a4)
h=B.a.cC(k,0)
for(;!0;){B.a.k(i,h)
if(k.length===0)break
g=B.a.gF(k)
f=A.H5(h.d)
if(f!=null&&g.d.n(0,f)&&g.a===h.a){h=B.a.cC(k,0)
continue}break}e=a7.cN("ul")
for(d=i.length,c=e.a,s=0;s<i.length;i.length===d||(0,A.k)(i),++s){b=i[s]
a=a7.cN("li")
a0=a.a
a0.setAttribute("data-list",b.c)
a1=b.b
if(a1>1)a0.setAttribute("class","ql-indent-"+(a1-1))
a1=A.iQ(n.a(b.d.a.innerHTML))
a.saf(a1==null?null:J.L(a1))
o.a(c.appendChild(a0))}d=B.a.gF(i).d.a
if(p.a(d.parentNode)==null)a2=null
else{a0=p.a(d.parentNode)
a0.toString
a2=A.S(a0)}if(a2!=null){a0=a2.a
o.a(a0.insertBefore(c,d))}for(d=i.length,s=0;s<i.length;i.length===d||(0,A.k)(i),++s){c=i[s].d.a
m=p.a(c.parentNode)
if(m!=null)o.a(m.removeChild(c))}}},
JC(a){t.uF.a(a)
if(A.m(a.ghF().a.getAttribute("xmlns:w"))==="urn:schemas-microsoft-com:office:word")A.H9(a)},
la:function la(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
BY(a){var s,r,q,p,o=A.JP(a)
if(o!=null)return o
for(s=a.a_("option"),r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q].a
if(A.I(p.hasAttribute("selected")))return A.m(p.getAttribute("value"))}return null},
C3(a,b){var s,r,q,p
A.JQ(a,b)
for(s=a.a_("option"),r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q].a
if(A.m(p.getAttribute("value"))===b)p.setAttribute("selected","selected")
else p.removeAttribute("selected")}},
Eq(a){var s,r,q,p,o,n,m,l=null
if(a instanceof A.dY)return a
if(t.G.b(a)){s=a.h(0,"interval")
r=a.h(0,"highlighter")
q=a.h(0,"htmlHighlighter")
if(q==null)q=a.h(0,"hljs")
if(A.cI(s))p=A.ng(0,s)
else p=s instanceof A.cr?s:B.aM
o=A.Er(a.h(0,"languages"))
n=t.no.b(r)?r:l
m=t.gr.b(q)?q:l
return new A.dY(p,o==null?B.bb:o,n,m)}return new A.dY(B.aM,B.bb,l,l)},
Er(a){var s,r
if(t.v_.b(a))return a
if(t.j.b(a)){s=J.CY(a,t.G)
r=s.$ti
r=A.ft(s,r.i("aU(o.E)").a(new A.pW()),r.i("o.E"),t.s3)
return A.N(r,!1,A.u(r).i("o.E"))}return null},
x2(a,b){var s=new A.dF(A.a([],t.E),a)
t.m.a(a.a.classList).add("ql-token")
if(b!=null&&!J.A(b,!1))s.kr(b)
return s},
z4(a){var s
if(a instanceof A.f)return A.x2(a,null)
$.y().a.a===$&&A.c()
s=t.m
return A.x2(new A.f(A.b(t.O,t.g),s.a(s.a(self.document).createElement("span"))),a)},
xv(a){var s=A.a([],t.E)
t.m.a(a.a.classList).add("ql-code-block")
return new A.di(A.b(t.N,t.z),s,a)},
zW(a){var s,r
if(a instanceof A.f)return A.xv(a)
$.y().a.a===$&&A.c()
s=t.m
r=s.a(s.a(self.document).createElement("DIV"))
s.a(r.classList).add("ql-code-block")
if(typeof a=="string"&&a.length!==0)r.setAttribute("data-language",A.h(a))
return A.xv(new A.f(A.b(t.O,t.g),r))},
xx(a){var s=A.m(a.a.getAttribute("data-language"))
return s==null||s.length===0?"plain":s},
xw(a){var s=A.a([],t.E),r=a.a
t.m.a(r.classList).add("ql-code-block-container")
r.setAttribute("spellcheck","false")
return new A.cV(s,a)},
zV(a){var s
if(a instanceof A.f)return A.xw(a)
$.y().a.a===$&&A.c()
s=t.m
return A.xw(new A.f(A.b(t.O,t.g),s.a(s.a(self.document).createElement("DIV"))))},
zX(a){var s,r=null,q="code-block-container",p=[new A.X("code-token",3,A.K1(),B.F,B.ep,r,r,r,!1),new A.X(q,5,A.K2(),B.V,B.aV,r,r,r,!1),new A.X("code-block",5,A.K3(),B.V,B.b6,q,r,r,!1)]
if(a!=null){for(s=0;s<3;++s)a.ia(p[s])
return}for(s=0;s<3;++s)A.dd(p[s],!0)},
kC:function kC(a,b,c){this.a=a
this.b=b
this.c=c},
aU:function aU(a,b){this.a=a
this.b=b},
dY:function dY(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
pW:function pW(){},
dF:function dF(a,b){var _=this
_.z=$
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
di:function di(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
pV:function pV(){},
pU:function pU(a){this.a=a},
cV:function cV(a,b){var _=this
_.dy=!1
_.fr=null
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
pS:function pS(a){this.a=a},
pT:function pT(){},
eE:function eE(a,b){var _=this
_.c=$
_.d=null
_.a=a
_.b=b},
q1:function q1(a){this.a=a},
q0:function q0(a,b,c){this.a=a
this.b=b
this.c=c},
pZ:function pZ(){},
q_:function q_(a){this.a=a},
pY:function pY(a){this.a=a},
pX:function pX(a){this.a=a},
Es(a,b){var s=new A.bF(a,b)
s.nm(a,b)
return s},
Ey(a){var s=$.hn().h(0,a)
if(typeof s!="string")return""
return B.b.b8(s,"<svg ",'<svg width="18" height="18" ')},
fI:function fI(){},
bF:function bF(a,b){var _=this
_.c=!1
_.d=$
_.f=_.e=null
_.a=a
_.b=b},
rA:function rA(a){this.a=a},
rn:function rn(){},
ro:function ro(a,b){this.a=a
this.b=b},
rp:function rp(a){this.a=a},
rq:function rq(a){this.a=a},
rr:function rr(a){this.a=a},
rs:function rs(a){this.a=a},
rz:function rz(a,b){this.a=a
this.b=b},
rx:function rx(a){this.a=a},
rv:function rv(){},
rw:function rw(a){this.a=a},
ry:function ry(){},
rt:function rt(a,b){this.a=a
this.b=b},
ru:function ru(){},
rB:function rB(){},
ky:function ky(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
iP(a){if(t.P.b(a))return A.Y(a,t.N,t.z)
if(t.G.b(a))return a.bo(0,new A.uO(),t.N,t.z)
return A.b(t.N,t.z)},
bb(a){if(a instanceof A.r)return new A.r(A.a5(a.a,!0,t.Q))
if(t.j.b(a))return A.x3(a)
return new A.r(A.a([],t.t))},
cl(a){if(t.P.b(a))return A.Y(a,t.N,t.z)
if(t.G.b(a))return a.bo(0,new A.uo(),t.N,t.z)
return A.b(t.N,t.z)},
iO(a){var s
if(a==null)return null
s=A.cl(a)
return s.a===0?null:s},
ur(a){var s
if(a instanceof A.r)return new A.r(A.a5(a.a,!0,t.Q))
if(t.j.b(a)){s=J.el(a,A.Kk(),t.z)
return A.N(s,!0,s.$ti.i("ad.E"))}if(t.G.b(a))return a.bo(0,new A.us(),t.N,t.z)
return a},
y3(a,b){var s=A.b(t.N,t.z)
if(a.a.length!==0)s.j(0,"content",a.bs())
if(b!=null&&b.gal(b))s.j(0,"attributes",b)
return s.a===0?null:s},
y4(a,b,c){var s=t.N,r=A.b(s,t.z)
if(a.a.length!==0)r.j(0,"rows",a.bs())
if(b.a.length!==0)r.j(0,"columns",b.bs())
if(c.a!==0)r.j(0,"cells",c.bo(0,new A.ut(),s,t.P))
return r},
y9(a){var s,r=a.split(":"),q=r.length
if(0>=q)return A.d(r,0)
s=A.bM(r[0],null)
if(1>=q)return A.d(r,1)
return new A.h5(A.bM(r[1],null)-1,s-1)},
iK(a,b){var s,r,q=new A.c7(a,a.b),p=b,o=0
while(!0){if(!(q.aZ()<1073741824&&o<=p))break
s=q.aZ()
r=q.bp().a
if(r==="delete"){if(s>p-o)return null
p-=s}else{o+=s
if(r==="insert")p+=s}}return p},
yb(a,b,c){var s=A.b(t.N,t.P)
A.cl(a).O(0,new A.vr(c,b,s))
return s},
FY(a,b,c){var s="rows",r="columns",q=A.iP(a),p=A.iP(b),o=A.bb(q.h(0,s)).c3(A.bb(p.h(0,s))),n=A.bb(q.h(0,r)).c3(A.bb(p.h(0,r))),m=q.h(0,"cells"),l=A.bb(p.h(0,s)),k=A.yb(m,A.bb(p.h(0,r)),l)
A.cl(p.h(0,"cells")).O(0,new A.uu(k,c))
return A.y4(o,n,k)},
HA(a7,a8,a9){var s,r,q,p,o,n,m,l,k,j,i,h="attributes",g=A.iP(a7),f=A.iP(a8),e=A.bb(g.h(0,"rows")),d=A.bb(g.h(0,"columns")),c=A.bb(f.h(0,"rows")),b=A.bb(f.h(0,"columns")),a=e.d_(c,a9),a0=d.d_(b,a9),a1=f.h(0,"cells"),a2=!a9,a3=c.d_(e,a2),a4=A.yb(a1,b.d_(d,a2),a3),a5=A.cl(g.h(0,"cells")),a6=A.a5(new A.as(a5,A.u(a5).i("as<1>")),!0,t.N)
for(a1=a6.length,s=0;s<a1;++s){r=a6[s]
q=a5.h(0,r)
p=A.y9(r)
o=A.iK(a,p.b)
n=A.iK(a0,p.a)
if(o==null||n==null)continue
m=""+(o+1)+":"+(n+1)
l=a4.h(0,m)
if(l==null)continue
k=A.cl(q)
j=A.cl(l)
i=A.y3(A.bb(k.h(0,"content")).d_(A.bb(j.h(0,"content")),a9),A.z9(A.iO(k.h(0,h)),A.iO(j.h(0,h)),a9))
if(i!=null)a4.j(0,m,i)
else a4.Z(0,m)}return A.y4(a,a0,a4)},
GK(a4,a5){var s,r,q,p,o,n,m,l,k,j,i="cells",h="attributes",g=A.iP(a4),f=A.iP(a5),e=A.bb(g.h(0,"rows")),d=A.bb(f.h(0,"rows")),c=A.bb(g.h(0,"columns")),b=A.bb(f.h(0,"columns")),a=e.e9(d),a0=c.e9(b),a1=A.yb(g.h(0,i),a0,a),a2=t.N,a3=A.a5(new A.as(a1,A.u(a1).i("as<1>")),!0,a2)
for(s=a3.length,r=t.z,q=t.yq,p=0;p<s;++p){o=a3[p]
n=a1.h(0,o)
if(n==null)continue
m=A.cl(n)
l=q.a(f.h(0,i))
k=A.cl(l==null?null:l.c2(0,a2,r).h(0,o))
j=A.y3(A.bb(m.h(0,"content")).e9(A.bb(k.h(0,"content"))),A.z8(A.iO(m.h(0,h)),A.iO(k.h(0,h))))
if(j!=null)a1.j(0,o,j)
else a1.Z(0,o)}A.cl(f.h(0,i)).O(0,new A.uK(e,c,a1))
return A.y4(a,a0,a1)},
uO:function uO(){},
uo:function uo(){},
us:function us(){},
ut:function ut(){},
vr:function vr(a,b,c){this.a=a
this.b=b
this.c=c},
vq:function vq(){},
uu:function uu(a,b){this.a=a
this.b=b},
uK:function uK(a,b,c){this.a=a
this.b=b
this.c=c},
uJ:function uJ(){},
wF:function wF(){},
wG:function wG(){},
wH:function wH(){},
fH:function fH(a,b){this.a=a
this.b=b},
EB(a,b){var s=new A.i3(A.a([],t.t6),A.b(t.N,t.V),a,b)
s.no(a,b)
return s},
Fh(a,b,c){var s=new A.ue(a,b,A.a([],t.r))
s.nr(a,b,c)
return s},
Bu(a,b,c){var s,r,q
$.y().a.a===$&&A.c()
s=t.m
r=s.a(s.a(self.document).createElement("button"))
r.setAttribute("type","button")
s.a(r.classList).add("ql-"+b)
r.setAttribute("aria-pressed","false")
if(c!=null){q=J.L(c)
r.setAttribute("value",q)
r.setAttribute("aria-label",b+": "+q)}else r.setAttribute("aria-label",b)
r.setAttribute("title",A.y5(b,c))
s.a(a.a.appendChild(r))},
y5(a,b){var s=b==null,r=B.fy.h(0,s?a:a+":"+A.p(b))
if(r==null)s=s?a:a+": "+A.p(b)
else s=r
return s},
HF(a,b){var s=$.y().a.a
s===$&&A.c()
B.a.O(b.a,new A.vx(s,a))},
HH(a,b,c){var s,r,q=$.y().a.a
q===$&&A.c()
s=t.m
r=s.a(s.a(self.document).createElement("select"))
s.a(r.classList).add("ql-"+b)
r.setAttribute("title",A.y5(b,null))
r.setAttribute("aria-label",A.y5(b,null))
J.wX(c,new A.vy(q,new A.f(A.b(t.O,t.g),r)))
s.a(a.a.appendChild(r))},
ok:function ok(){},
fK:function fK(a){this.a=a},
fL:function fL(a,b){this.a=a
this.b=b},
i3:function i3(a,b,c,d){var _=this
_.c=null
_.d=a
_.e=b
_.r=_.f=null
_.a=c
_.b=d},
rW:function rW(a){this.a=a},
rX:function rX(a){this.a=a},
rU:function rU(a){this.a=a},
rY:function rY(a,b){this.a=a
this.b=b},
rV:function rV(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
t0:function t0(a,b,c){this.a=a
this.b=b
this.c=c},
t1:function t1(a){this.a=a},
rZ:function rZ(){},
t_:function t_(a){this.a=a},
rG:function rG(a){this.a=a},
rH:function rH(a){this.a=a},
rI:function rI(a){this.a=a},
rM:function rM(a){this.a=a},
rN:function rN(a){this.a=a},
rO:function rO(a){this.a=a},
rP:function rP(){},
rQ:function rQ(){},
rR:function rR(){},
rS:function rS(){},
rT:function rT(){},
rJ:function rJ(){},
rK:function rK(){},
rL:function rL(a,b){this.a=a
this.b=b},
ue:function ue(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.f=_.e=_.d=$},
uf:function uf(a,b,c){this.a=a
this.b=b
this.c=c},
ug:function ug(a,b,c){this.a=a
this.b=b
this.c=c},
vx:function vx(a,b){this.a=a
this.b=b},
vw:function vw(a){this.a=a},
vy:function vy(a,b){this.a=a
this.b=b},
FW(a){var s,r,q=a.a,p=new A.ca(q).geb()
if(p==="ArrowLeft"||p==="ArrowRight"||p==="ArrowUp"||p==="ArrowDown"||p==="Home")return!0
$.y()
s=t.m
s=A.h(s.a(s.a(self.window).navigator).platform)
r=!1
if(B.b.v(s.toLowerCase(),"mac"))if(p==="a"){s=A.Z(q,"KeyboardEvent")
q=s&&A.I(q.ctrlKey)}else q=r
else q=r
if(q)return!0
return!1},
fM:function fM(a,b){var _=this
_.c=!1
_.d=0
_.a=a
_.b=b},
t7:function t7(a){this.a=a},
t8:function t8(a){this.a=a},
t6:function t6(a,b,c){this.a=a
this.b=b
this.c=c},
vG(a,b,c){var s=0,r=A.H0(t.jW),q,p,o,n,m,l,k,j,i
var $async$vG=A.HE(function(d,e){if(d===1)return A.FP(e,r)
while(true)switch(s){case 0:i=a.c
i===$&&A.c()
if(i.z.aw("image",65535)==null){s=1
break}p=A.a([],t.s)
i=c.length,o=0
case 3:if(!(o<c.length)){s=5
break}n=c[o]
s=6
return A.FO($.y().a.u6(n),$async$vG)
case 6:m=e
if(m!=null&&m.length!==0)B.a.k(p,m)
case 4:c.length===i||(0,A.k)(c),++o
s=3
break
case 5:if(p.length===0){s=1
break}l=new A.r(A.a([],t.t))
i=b.a
l.a8(i)
l.aY(b.b)
for(k=p.length,j=t.N,o=0;o<p.length;p.length===k||(0,A.k)(p),++o)l.aE(0,A.l(["image",p[o]],j,j))
a.aM(l,"user")
a.S(new A.G(i+p.length,0),"silent")
case 1:return A.FQ(q,r)}})
return A.FR($async$vG,r)},
xL(a){var s,r,q,p,o
if(a instanceof A.e2)return a
if(t.G.b(a)){s=A.a([],t.s)
r=a.h(0,"mimetypes")
if(t.Y.b(r))for(q=J.U(r);q.l();){p=q.gq()
if(p!=null)B.a.k(s,J.L(p))}o=a.h(0,"handler")
q=s.length===0?B.b3:A.cc(s,t.N)
return new A.e2(q,t.gh.b(o)?o:null)}return B.nd},
Am(a,b){var s=new A.dp(a,b),r=a.b
r===$&&A.c()
r.I("drop",s.goN())
return s},
e2:function e2(a,b){this.a=a
this.b=b},
dp:function dp(a,b){this.a=a
this.b=b},
nt:function nt(a){this.a=a},
aC(a,b){var s=a==null?null:a.u(b)
return s==null?null:A.V(s,null)},
bL(a){var s
if(a==null)return null
s=a.u("w:val")
if(s==null)return!0
return!(s==="0"||s==="false"||s==="none")},
EL(a){if(a==null)return null
return new A.to(A.aC(a,"w:before"),A.aC(a,"w:after"),A.aC(a,"w:line"),a.u("w:lineRule"))},
Ap(a){var s
if(a==null)return null
s=A.aC(a,"w:left")
if(s==null)s=A.aC(a,"w:start")
if(A.aC(a,"w:right")==null)A.aC(a,"w:end")
return new A.ti(s,A.aC(a,"w:firstLine"),A.aC(a,"w:hanging"))},
xP(a){if(a==null)return null
a.u("w:val")
a.u("w:color")
return new A.tn(a.u("w:fill"))},
i7(a){var s,r
if(a==null)return null
s=a.u("w:val")
A.aC(a,"w:sz")
r=a.u("w:color")
A.aC(a,"w:space")
return new A.i6(s,r)},
xN(a){var s,r,q,p
if(a==null)return null
s=A.i7(a.C("w:top"))
r=a.C("w:left")
r=A.i7(r==null?a.C("w:start"):r)
q=A.i7(a.C("w:bottom"))
p=a.C("w:right")
return new A.tg(s,r,q,A.i7(p==null?a.C("w:end"):p),A.i7(a.C("w:insideH")),A.i7(a.C("w:insideV")))},
kL(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=null,b="w:val"
if(a==null)return c
s=a.C("w:rFonts")
r=a.C("w:rStyle")
r=r==null?c:r.u(b)
q=s==null
p=q?c:s.u("w:ascii")
o=q?c:s.u("w:hAnsi")
q=q?c:s.u("w:cs")
n=A.bL(a.C("w:b"))
m=A.bL(a.C("w:i"))
l=a.C("w:u")
l=l==null?c:l.u(b)
k=A.bL(a.C("w:strike"))
j=A.bL(a.C("w:caps"))
i=A.bL(a.C("w:smallCaps"))
h=A.aC(a.C("w:sz"),b)
g=a.C("w:color")
g=g==null?c:g.u(b)
f=a.C("w:highlight")
f=f==null?c:f.u(b)
e=A.xP(a.C("w:shd"))
d=a.C("w:vertAlign")
return new A.eO(r,p,o,q,n,m,l,k,j,i,h,g,f,e,d==null?c:d.u(b))},
xO(a){var s,r,q,p,o,n,m,l,k,j=null,i="w:val"
if(a==null)return j
s=a.C("w:numPr")
if(s!=null){r=A.aC(s.C("w:numId"),i)
q=A.aC(s.C("w:ilvl"),i)
p=new A.tj(r,q==null?0:q)}else p=j
o=a.C("w:tabs")
if(o!=null){r=A.a([],t.Fa)
for(q=o.bD("w:tab"),n=q.$ti,q=new A.H(q.a(),n.i("H<1>")),n=n.c;q.l();){m=q.b
if(m==null)m=n.a(m)
m.u(i)
l=m.u("w:pos")
if(l!=null)A.V(l,j)
m.u("w:leader")
r.push(new A.kN())}k=r}else k=j
r=a.C("w:pStyle")
r=r==null?j:r.u(i)
q=a.C("w:jc")
q=q==null?j:q.u(i)
return new A.eM(r,p,q,A.EL(a.C("w:spacing")),A.Ap(a.C("w:ind")),k,A.xP(a.C("w:shd")),A.xN(a.C("w:pBdr")),A.bL(a.C("w:keepNext")),A.bL(a.C("w:keepLines")),A.bL(a.C("w:pageBreakBefore")),A.bL(a.C("w:widowControl")),A.bL(a.C("w:contextualSpacing")),A.aC(a.C("w:outlineLvl"),i),A.kL(a.C("w:rPr")))},
Aw(a){if(a==null)return null
A.aC(a,"w:w")
return new A.ts(a.u("w:type"))},
Av(a){var s,r,q
if(a==null)return null
s=a.C("w:tblStyle")
s=s==null?null:s.u("w:val")
A.Aw(a.C("w:tblW"))
r=a.C("w:jc")
if(r!=null)r.u("w:val")
r=A.xN(a.C("w:tblBorders"))
A.aC(a.C("w:tblInd"),"w:w")
q=a.C("w:tblLayout")
if(q!=null)q.u("w:type")
return new A.tq(s,r)},
EO(a){var s,r=a.C("w:trHeight"),q=A.aC(r,"w:val")
if(r!=null)r.u("w:hRule")
s=A.bL(a.C("w:tblHeader"))
A.bL(a.C("w:cantSplit"))
return new A.tr(q,s===!0)},
EN(a){var s,r,q,p,o,n="w:val",m=a.C("w:vMerge")
A.Aw(a.C("w:tcW"))
s=A.aC(a.C("w:gridSpan"),n)
if(m==null)r=null
else{r=m.u(n)
if(r==null)r="continue"}q=A.xN(a.C("w:tcBorders"))
p=A.xP(a.C("w:shd"))
o=a.C("w:vAlign")
return new A.tp(s,r,q,p,o==null?null:o.u(n))},
EJ(a){var s,r,q,p,o,n,m,l,k,j,i,h
if(a==null)return null
s=a.C("w:pgSz")
r=a.C("w:pgMar")
q=new A.tm(a)
p=A.aC(s,"w:w")
o=A.aC(s,"w:h")
if(s!=null)s.u("w:orient")
n=A.aC(r,"w:top")
m=A.aC(r,"w:right")
l=A.aC(r,"w:bottom")
k=A.aC(r,"w:left")
j=A.aC(r,"w:header")
i=A.aC(r,"w:footer")
A.aC(r,"w:gutter")
A.bL(a.C("w:titlePg"))
h=q.$1("w:headerReference")
q=q.$1("w:footerReference")
a.ek()
return new A.tl(p,o,n,m,l,k,j,i,h,q)},
EK(a){if(a==null)return B.c6
A.bL(a.C("w:autoHyphenation"))
A.bL(a.C("w:evenAndOddHeaders"))
A.aC(a.C("w:defaultTabStop"),"w:val")
return new A.kM()},
to:function to(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ti:function ti(a,b,c){this.a=a
this.c=b
this.d=c},
kN:function kN(){},
tn:function tn(a){this.c=a},
i6:function i6(a,b){this.a=a
this.c=b},
tg:function tg(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
eO:function eO(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o},
tj:function tj(a,b){this.a=a
this.b=b},
eM:function eM(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o},
bJ:function bJ(){},
cY:function cY(a){this.a=a},
ib:function ib(){},
fQ:function fQ(a){this.a=a},
i9:function i9(){},
ia:function ia(a){this.b=a},
i8:function i8(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
fR:function fR(a){this.a=a},
fU:function fU(a){this.a=a},
fY:function fY(a){this.a=a},
h_:function h_(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.c=b
_.d=c
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h},
e4:function e4(){},
eN:function eN(a,b){this.a=a
this.b=b},
tk:function tk(){},
fT:function fT(a,b,c){this.a=a
this.b=b
this.c=c},
fZ:function fZ(a,b){this.a=a
this.b=b},
fX:function fX(a){this.a=a},
e3:function e3(){},
cX:function cX(a,b){this.a=a
this.b=b},
ts:function ts(a){this.b=a},
tq:function tq(a,b){this.a=a
this.d=b},
tr:function tr(a,b){this.a=a
this.c=b},
tp:function tp(a,b,c,d,e){var _=this
_.b=a
_.c=b
_.d=c
_.e=d
_.f=e},
kO:function kO(a,b){this.a=a
this.b=b},
kP:function kP(a,b){this.a=a
this.b=b},
eQ:function eQ(a,b,c){this.a=a
this.b=b
this.c=c},
fW:function fW(a){this.a=a},
fS:function fS(a,b){this.a=a
this.b=b},
tl:function tl(a,b,c,d,e,f,g,h,i,j){var _=this
_.a=a
_.b=b
_.d=c
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h
_.Q=i
_.as=j},
tm:function tm(a){this.a=a},
th:function th(a,b){this.a=a
this.b=b},
kJ:function kJ(a,b){this.a=a
this.b=b},
kM:function kM(){},
Ar(a){var s,r,q,p,o,n=null,m="w:val",l=a.u("w:ilvl")
l=A.V(l==null?"":l,n)
if(l==null)l=0
s=a.C("w:start")
s=s==null?n:s.u(m)
s=A.V(s==null?"":s,n)
if(s==null)s=1
r=a.C("w:numFmt")
r=r==null?n:r.u(m)
if(r==null)r="decimal"
q=a.C("w:lvlText")
q=q==null?n:q.u(m)
if(q==null)q=""
p=a.C("w:lvlJc")
if(p!=null)p.u(m)
p=a.C("w:pPr")
p=A.Ap(p==null?n:p.C("w:ind"))
A.kL(a.C("w:rPr"))
o=a.C("w:lvlRestart")
o=o==null?n:o.u(m)
A.V(o==null?"":o,n)
return new A.kK(l,s,r,q,p)},
Aq(a,b){var s=a==null?A.b(t.S,t.r3):a
return new A.e5(s,b==null?A.b(t.S,t.n_):b)},
As(a,b){return A.Aq(a,b)},
EI(a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=null,a="w:abstractNumId",a0=A.id()
A.ie(a1,new A.d_(a0,A.a([],t.lx)))
a0=new A.ae(a0.b,t.dd).gF(0)
s=t.S
r=A.b(s,t.r3)
for(q=a0.bD("w:abstractNum"),p=q.$ti,q=new A.H(q.a(),p.i("H<1>")),o=t.iV,p=p.c;q.l();){n=q.b
if(n==null)n=p.a(n)
m=n.u(a)
l=A.V(m==null?"":m,b)
if(l==null)continue
k=A.b(s,o)
for(m=n.bD("w:lvl"),j=m.$ti,m=new A.H(m.a(),j.i("H<1>")),j=j.c;m.l();){i=m.b
h=A.Ar(i==null?j.a(i):i)
k.j(0,h.a,h)}n=n.C("w:multiLevelType")
if(n!=null)n.u("w:val")
r.j(0,l,new A.fP(k))}g=A.b(s,t.n_)
for(a0=a0.bD("w:num"),q=a0.$ti,a0=new A.H(a0.a(),q.i("H<1>")),q=q.c;a0.l();){p=a0.b
if(p==null)p=q.a(p)
n=p.u("w:numId")
f=A.V(n==null?"":n,b)
n=p.C(a)
n=n==null?b:n.u("w:val")
e=A.V(n==null?"":n,b)
if(f==null||e==null)continue
d=A.b(s,o)
for(p=p.bD("w:lvlOverride"),n=p.$ti,p=new A.H(p.a(),n.i("H<1>")),n=n.c;p.l();){m=p.b
c=(m==null?n.a(m):m).C("w:lvl")
if(c!=null){h=A.Ar(c)
d.j(0,h.a,h)}}g.j(0,f,new A.fV(e,d))}return A.Aq(r,g)},
Il(a,b){var s
switch(b){case"decimal":return""+a
case"decimalZero":s=""+a
return a<10?"0"+s:s
case"lowerLetter":return A.Bc(a).toLowerCase()
case"upperLetter":return A.Bc(a).toUpperCase()
case"lowerRoman":return A.Bj(a).toLowerCase()
case"upperRoman":return A.Bj(a)
case"bullet":return""
case"none":return""
default:return""+a}},
Bc(a){var s,r
for(s=a,r="";s>0;){--s
r+=A.W(65+B.d.b4(s,26))
s=B.d.bC(s,26)}return new A.hX(A.a((r.charCodeAt(0)==0?r:r).split(""),t.s),t.q6).bn(0)},
Bj(a){var s,r,q,p,o,n=new A.a_("")
for(s=a,r=0;r<13;++r){q=B.cT[r]
p=q.a
o=q.b
for(;s>=p;){n.a+=o
s-=p}}q=n.a
return q.charCodeAt(0)==0?q:q},
DQ(a){var s,r=a.length
if(r===0)return"\u2022"
if(0>=r)return A.d(a,0)
s=a.charCodeAt(0)
$label0$0:{if(61623===s||183===s){r="\u2022"
break $label0$0}if(61607===s||167===s){r="\u25a0"
break $label0$0}if(61551===s||111===s){r="\u25cb"
break $label0$0}if(61692===s){r="\u2713"
break $label0$0}if(61656===s){r="\u27a2"
break $label0$0}r=a
break $label0$0}return r},
kK:function kK(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.f=e},
fP:function fP(a){this.c=a},
fV:function fV(a,b){this.b=a
this.c=b},
e5:function e5(a,b){this.a=a
this.b=b},
os:function os(a,b){this.a=a
this.b=b},
ot:function ot(){},
ou:function ou(a){this.a=a},
za(a,b,c,d,e){var s=B.b.a0(b,"/")?B.b.L(b,1):b,r=a.a.dv(s)
return r==null?d.$0():c.$1(r)},
n8:function n8(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.x=e
_.y=f},
n9:function n9(a){this.a=a},
At(a,b,c){return new A.e6(c,b,a==null?A.b(t.N,t.xD):a)},
Au(a,b,c){return A.At(a,b,c)},
EM(a){var s,r,q,p,o,n,m,l,k,j,i=null,h="w:val",g="w:default",f=A.id()
A.ie(a,new A.d_(f,A.a([],t.lx)))
f=new A.ae(f.b,t.dd).gF(0)
s=f.C("w:docDefaults")
if(s!=null){r=s.C("w:rPrDefault")
q=A.kL(r==null?i:r.C("w:rPr"))
r=s.C("w:pPrDefault")
p=A.xO(r==null?i:r.C("w:pPr"))}else{p=i
q=p}o=A.b(t.N,t.xD)
for(f=f.bD("w:style"),r=f.$ti,f=new A.H(f.a(),r.i("H<1>")),r=r.c;f.l();){n=f.b
if(n==null)n=r.a(n)
m=n.u("w:styleId")
if(m==null)continue
l=n.u("w:type")
if(l==null)l="paragraph"
k=n.C("w:name")
if(k!=null)k.u(h)
k=n.C("w:basedOn")
k=k==null?i:k.u(h)
j=n.C("w:link")
if(j!=null)j.u(h)
j=n.u(g)==="1"||n.u(g)==="true"
o.j(0,m,new A.eP(m,l,k,j,A.xO(n.C("w:pPr")),A.kL(n.C("w:rPr")),A.Av(n.C("w:tblPr"))))}return A.At(o,p,q)},
eP:function eP(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.d=c
_.f=d
_.r=e
_.w=f
_.x=g},
e6:function e6(a,b,c){this.a=a
this.b=b
this.c=c},
D8(a){var s,r,q,p,o,n,m,l,k,j,i="ContentType",h=A.id()
A.ie(a,new A.d_(h,A.a([],t.lx)))
s=t.N
r=A.b(s,s)
s=A.b(s,s)
for(h=B.a.gJ(new A.ae(h.b,t.dd).gF(0).d),q=new A.aQ(h,t.bi),p=t.rI;q.l();){o=p.a(h.gq())
n=o.b
m=B.b.ae(n,":")
switch(m<0?n:B.b.L(n,m+1)){case"Default":l=o.u("Extension")
k=o.u(i)
if(l!=null&&k!=null)r.j(0,l.toLowerCase(),k)
break
case"Override":j=o.u("PartName")
k=o.u(i)
if(j!=null&&k!=null)s.j(0,j,k)
break}}return new A.mN(r,s)},
mN:function mN(a,b){this.a=a
this.b=b},
ov:function ov(a,b,c){this.a=a
this.b=b
this.c=c},
ow:function ow(){},
zN(){var s=A.a([],t.Ew)
return new A.kl(s)},
Ef(a){var s,r,q,p,o,n,m,l,k,j,i=A.id()
A.ie(a,new A.d_(i,A.a([],t.lx)))
s=A.zN()
for(i=B.a.gJ(new A.ae(i.b,t.dd).gF(0).d),r=new A.aQ(i,t.bi),q=s.a,p=t.rI;r.l();){o=p.a(i.gq())
n=o.b
m=B.b.ae(n,":")
if((m<0?n:B.b.L(n,m+1))!=="Relationship")continue
l=o.u("Id")
k=o.u("Type")
j=o.u("Target")
if(l==null||k==null||j==null)continue
B.a.k(q,new A.kk(l,k,j,o.u("TargetMode")==="External"))}return s},
kk:function kk(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
kl:function kl(a){this.a=a},
id(){var s=A.a([],t.ha)
return new A.kR(s)},
dr:function dr(){},
ig:function ig(a){this.b=a},
ic:function ic(a){this.b=a},
kQ:function kQ(a){this.b=a},
kS:function kS(a,b){this.b=a
this.c=b},
e7:function e7(a,b){this.a=a
this.b=b},
c1:function c1(a,b,c){this.b=a
this.c=b
this.d=c},
kR:function kR(a){this.b=a},
d_:function d_(a,b){this.a=a
this.b=b},
tH:function tH(){},
aR(a,b,c){return new A.tt(A.ET(a,b,c),null,null)},
ET(a,b,c){var s=b.length,r=1,q=0,p=0
while(!0){if(!(p<c&&p<s))break
if(!(p<s))return A.d(b,p)
if(b.charCodeAt(p)===10){++r
q=p+1}++p}return a+" (linha "+r+", coluna "+(c-q+1)+")"},
ie(a,b){var s,r=a.length
if(r!==0){if(0>=r)return A.d(a,0)
r=a.charCodeAt(0)===65279}else r=!1
s=r?1:0
new A.kU(s===0?a:B.b.L(a,s),b).kc()},
EU(a){var s,r,q
for(s=a.length,r=0;r<s;++r){q=a.charCodeAt(r)
if(q===32||q===9||q===10||q===13)return r}return-1},
EV(a){var s,r,q,p,o,n,m=t.N,l=A.b(m,m)
for(m=A.D("([A-Za-z]+)\\s*=\\s*(\"([^\"]*)\"|'([^']*)')",!0,!1).dU(0,a),m=new A.e9(m.a,m.b,m.c),s=t.he;m.l();){r=m.d
q=(r==null?s.a(r):r).b
p=q.length
if(1>=p)return A.d(q,1)
o=q[1]
o.toString
if(3>=p)return A.d(q,3)
n=q[3]
if(n==null){if(4>=p)return A.d(q,4)
q=q[4]}else q=n
l.j(0,o,q==null?"":q)}return l},
e8:function e8(a,b){this.a=a
this.b=b},
kT:function kT(){},
tt:function tt(a,b,c){this.a=a
this.b=b
this.c=c},
kU:function kU(a,b){this.a=a
this.b=b
this.c=0},
jI(a){var s=new A.nL()
s.nd(a)
return s},
nL:function nL(){this.a=$
this.b=0
this.c=2147483647},
nQ:function nQ(a,b,c,d){var _=this
_.a=a
_.b=null
_.c=b
_.e=_.d=0
_.r=c
_.w=d},
m4:function m4(a,b){this.a=a
this.b=b},
xc(a,b,c,d){var s,r,q=new A.jP(b)
if(d==null)d=0
if(c==null)c=a.length-d
s=a.length
if(d+c>s)c=s-d
r=t.uo.b(a)?a:new Uint8Array(A.uE(a))
s=J.ho(B.u.gdf(r),r.byteOffset+d,c)
q.b=s
q.d=s.length
return q},
jP:function jP(a){var _=this
_.b=null
_.c=0
_.d=$
_.a=a},
jQ:function jQ(){},
kc:function kc(a){this.b=0
this.c=a},
kd:function kd(){},
EW(b3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9=A.a([],t.bo),b0=A.b(t.N,t.S),b1=new A.tu(a9,b0,new Uint8Array(0)),b2=b3.length
if(b2===0)return b1
s=A.Gc(b3)
if(s<0)throw A.i(B.cd)
r=A.Bi(b3,s+10)
q=A.dA(b3,s+12)
p=A.dA(b3,s+16)
o=s+22
b1.c=new Uint8Array(A.uE(A.i4(b3,o,o+A.Bi(b3,s+20))))
n=p+q
m=p
l=0
while(!0){if(!(l<r&&m<n))break
if(A.dA(b3,m)!==33639248)throw A.i(B.ce)
o=m+8
if(!(o>=0&&o<b2))return A.d(b3,o)
k=b3[o];++o
if(!(o<b2))return A.d(b3,o)
j=k|b3[o]<<8
o=m+10
if(!(o>=0&&o<b2))return A.d(b3,o)
k=b3[o];++o
if(!(o<b2))return A.d(b3,o)
o=b3[o]
A.dA(b3,m+16)
i=A.dA(b3,m+20)
h=A.dA(b3,m+24)
g=m+28
if(!(g>=0&&g<b2))return A.d(b3,g)
f=b3[g];++g
if(!(g<b2))return A.d(b3,g)
g=b3[g]
e=m+30
if(!(e>=0&&e<b2))return A.d(b3,e)
d=b3[e];++e
if(!(e<b2))return A.d(b3,e)
e=b3[e]
c=m+32
if(!(c>=0&&c<b2))return A.d(b3,c)
b=b3[c];++c
if(!(c<b2))return A.d(b3,c)
c=b3[c]
a=A.dA(b3,m+42)
a0=m+46
a1=a0+((f|g<<8)>>>0)
a2=a1+((d|e<<8)>>>0)+((b|c<<8)>>>0)
a3=A.G0(b3,a0,a1,(j&2048)!==0)
if(i===4294967295||h===4294967295||a===4294967295)throw A.i(A.aV("ZIP64 archives are not supported."))
if(A.dA(b3,a)!==67324752)throw A.i(B.cf)
g=a+26
if(!(g<b2))return A.d(b3,g)
f=b3[g];++g
if(!(g<b2))return A.d(b3,g)
g=b3[g]
e=a+28
if(!(e<b2))return A.d(b3,e)
d=b3[e];++e
if(!(e<b2))return A.d(b3,e)
a4=a+30+((f|g<<8)>>>0)+((d|b3[e]<<8)>>>0)
a5=a4+i
if((j&8)!==0)a6=a5+4<=b2&&A.dA(b3,a5)===134695760?a5+16:a5+12
else a6=a5
a7=new A.kV()
A.i4(b3,a,a6)
A.i4(b3,m,a2)
a7.d=A.i4(b3,a4,a5)
a7.e=(k|o<<8)>>>0
a7.r=h
a8=b0.h(0,a3)
if(a8!=null)B.a.j(a9,a8,a7)
else{b0.j(0,a3,a9.length)
B.a.k(a9,a7)}++l
m=a2}return b1},
Gc(a){var s,r=a.length,q=r>65558?r-65558:0
for(s=r-22;s>=q;--s)if(A.dA(a,s)===101010256)return s
return-1},
G0(a,b,c,d){var s,r,q=A.i4(a,b,c)
if(!d)return B.aI.dY(q)
try{s=B.aJ.dY(q)
return s}catch(r){s=B.aI.dY(q)
return s}},
Bi(a,b){var s,r,q=a.length
if(!(b>=0&&b<q))return A.d(a,b)
s=a[b]
r=b+1
if(!(r<q))return A.d(a,r)
return(s|a[r]<<8)>>>0},
dA(a,b){var s,r,q,p,o=a.length
if(!(b>=0&&b<o))return A.d(a,b)
s=a[b]
r=b+1
if(!(r<o))return A.d(a,r)
r=a[r]
q=b+2
if(!(q<o))return A.d(a,q)
q=a[q]
p=b+3
if(!(p<o))return A.d(a,p)
return(s|r<<8|q<<16|a[p]<<24)>>>0},
kV:function kV(){var _=this
_.d=null
_.e=8
_.r=0
_.w=null},
tu:function tu(a,b,c){this.a=a
this.b=b
this.c=c},
bR:function bR(a,b){this.a=a
this.b=b},
fx:function fx(a,b){this.a=a
this.b=b},
kw:function kw(a,b){this.a=a
this.b=b},
eI:function eI(a,b){this.a=a
this.b=b},
dZ:function dZ(a,b){this.a=a
this.b=b},
bC(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,a0){return new A.ew(o,r,f,l,a0,g,a,e,h,i,p,m,k,d,n,s,q,j)},
ew:function ew(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r){var _=this
_.b=a
_.c=b
_.e=null
_.f=c
_.r=d
_.w=e
_.x=f
_.y=g
_.z=h
_.Q=i
_.as=j
_.at=k
_.ax=l
_.ay=m
_.id=n
_.k1=o
_.y1=p
_.y2=q
_.rB=r},
jJ:function jJ(a){this.b=a},
jK:function jK(a,b,c,d){var _=this
_.r=null
_.x=a
_.y=b
_.z=c
_.dx=d},
ex:function ex(a,b){this.d=a
this.e=b},
x6(a,b){var s,r,q,p,o,n,m,l,k,j
if(a.e==null)a.e="wp:"+b
s=a.y1
if(s!=null)for(r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q)A.x6(s[q],b)
p=a.k1
if(p!=null)for(r=p.length,q=0;q<p.length;p.length===r||(0,A.k)(p),++q)for(o=p[q].e,n=o.length,m=0;m<o.length;o.length===n||(0,A.k)(o),++m)for(l=o[m].z,k=l.length,j=0;j<l.length;l.length===k||(0,A.k)(l),++j)A.x6(l[j],b)},
x5(a){var s
$label0$0:{if("center"===a){s=B.aq
break $label0$0}if("right"===a||"end"===a){s=B.ar
break $label0$0}if("both"===a){s=B.as
break $label0$0}if("distribute"===a){s=B.at
break $label0$0}s=null
break $label0$0}return s},
hB(a,b){},
x4(a){if(a==null||a==="auto")return null
return"#"+A.p(a)},
zb(a){var s=a==null?null:a.c
if(s==null||s==="auto")return null
return"#"+A.p(s)},
Dg(a){var s
$label0$0:{if(0===a){s=B.mV
break $label0$0}if(1===a){s=B.mW
break $label0$0}if(2===a){s=B.mX
break $label0$0}if(3===a){s=B.mY
break $label0$0}if(4===a){s=B.mZ
break $label0$0}s=B.n_
break $label0$0}return s},
Df(a){var s,r,q=a.b
if(q==null)return"\u2022"
s=A.V(q,16)
if(s==null)return"\u2022"
$label0$0:{if(61623===s){r="\u2022"
break $label0$0}if(61607===s){r="\u25a0"
break $label0$0}if(61551===s){r="\u25cb"
break $label0$0}if(61692===s){r="\u2713"
break $label0$0}if(61656===s){r="\u27a2"
break $label0$0}r=s>=61440&&s<=61695?"\u2022":A.W(s)
break $label0$0}return r},
hA:function hA(){},
na:function na(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
nc:function nc(a,b){this.a=a
this.b=b},
nd:function nd(){},
nb:function nb(){},
ik:function ik(a,b){this.a=a
this.b=b},
u2:function u2(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
u3:function u3(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
E9(a){var s,r,q={},p=A.a([],t.cs)
q.a=0
new A.oS(q,p,new A.oQ(p),new A.oR(p)).$2(a,B.l)
s=p.length===0?null:B.a.gK(p)
r=s==null?null:s.h(0,"insert")
if(typeof r!="string"||!B.b.be(r,"\n"))B.a.k(p,A.l(["insert","\n"],t.N,t.z))
return A.l(["ops",p],t.N,t.z)},
xr(a,b){var s,r,q,p,o,n="table-cell-block",m="table-th-block",l="header",k="list",j="table-cell",i="table-th",h="align",g=b.h(0,n)
if(g==null)g=b.h(0,m)
s=g==null
r=!s
q=t.N
p=t.z
o=A.b(q,p)
if(b.p(l)&&s)o.j(0,l,b.h(0,l))
if(b.p(k)&&s)o.j(0,k,b.h(0,k))
if(b.p(l)&&r)o.j(0,"table-header",A.l(["cellId",g,"value",b.h(0,l)],q,p))
else if(b.p(k)&&r)o.j(0,"table-list",A.l(["cellId",g,"value",b.h(0,k)],q,p))
else if(b.p(n))o.j(0,n,b.h(0,n))
if(b.p(m)&&!b.p(l)&&!b.p(k))o.j(0,m,b.h(0,m))
if(b.p(j))o.j(0,j,b.h(0,j))
if(b.p(i))o.j(0,i,b.h(0,i))
if(a.ay===B.aq)o.j(0,h,"center")
if(a.ay===B.ar)o.j(0,h,"right")
s=a.ay
if(s===B.as||s===B.at)o.j(0,h,"justify")
return o},
E8(a){switch(a.a){case 0:return 1
case 1:return 2
case 2:return 3
case 3:return 4
case 4:return 5
case 5:return 6}},
E7(a){var s,r,q,p,o=a.h(0,"table-cell-block")
if(o==null)o=a.h(0,"table-th-block")
if(typeof o=="string"&&o.length!==0)return o
s=t.G
if(s.b(o))return A.m(o.h(0,"cellId"))
r=a.h(0,"table-header")
if(r==null)r=a.h(0,"table-list")
if(s.b(r))return A.m(r.h(0,"cellId"))
q=a.h(0,"table-cell")
if(q==null)q=a.h(0,"table-th")
if(s.b(q)){p=q.h(0,"data-row")
if(typeof p=="string")return"cell-"+p}return null},
oR:function oR(a){this.a=a},
oQ:function oQ(a){this.a=a},
oS:function oS(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
oT:function oT(){},
eq:function eq(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
FK(a){var s=A.xM(a)
if(s==null)return!1
if(!s.glf())return!0
return B.jL.v(0,s.gcH().toLowerCase())},
Hu(a){var s,r,q,p,o=t.Cf.a(a.getAttributeNames())
for(s=J.U(t.c.b(o)?o:new A.bd(o,A.K(o).i("bd<1,e>")));s.l();){r=s.gq()
q=r.toLowerCase()
if(B.b.a0(q,"on")){a.removeAttribute(r)
continue}if(B.k4.v(0,q)){p=A.m(a.getAttribute(r))
if(p==null||!A.FK(B.b.R(p)))a.removeAttribute(r)}}},
Bm(a){var s,r,q,p=t.A,o=p.a(a.firstChild)
for(s=t.m;o!=null;o=r){r=p.a(o.nextSibling)
q=A.Z(o,"Element")
if(q)if(B.k8.v(0,A.h(o.tagName).toUpperCase()))s.a(a.removeChild(o))
else{A.Hu(o)
A.Bm(o)}}},
S(a){var s=A.Z(a,"Element")
if(s)return new A.f(A.b(t.O,t.g),a)
s=A.Z(a,"Text")
if(s)return new A.bl(a)
return new A.eU(a)},
B2(a,b){var s,r,q={}
q.a=b<0?0:b
q.b=null
s=new A.uF(q).$1(a)
if(s!=null)return s
r=q.b
if(r!=null)return new A.f0(r,A.h(r.data).length)
return new A.f0(a,A.v(t.m.a(a.childNodes).length))},
h2(a){var s,r,q,p
for(s=new A.eo(a),r=t.sU,s=new A.be(s,s.gm(0),r.i("be<R.E>")),r=r.i("R.E"),q="data-";s.l();){p=s.d
if(p==null)p=r.a(p)
q=p>=65&&p<=90?q+A.W(45)+A.W(p+32):q+A.W(p)}return q.charCodeAt(0)==0?q:q},
F5(a){var s,r,q,p,o=new A.a_("")
for(s=new A.eo(B.b.L(a,5)),r=t.sU,s=new A.be(s,s.gm(0),r.i("be<R.E>")),r=r.i("R.E"),q=!1;s.l();){p=s.d
if(p==null)p=r.a(p)
if(p===45)q=!0
else if(q){if(p>=97&&p<=122){p=A.W(p-32)
o.a+=p}else{p=A.W(p)
o.a+=p}q=!1}else{p=A.W(p)
o.a+=p}}s=o.a
return s.charCodeAt(0)==0?s:s},
zl(a){var s,r,q,p
for(s=new A.eo(a),r=t.sU,s=new A.be(s,s.gm(0),r.i("be<R.E>")),r=r.i("R.E"),q="";s.l();){p=s.d
if(p==null)p=r.a(p)
q=p>=65&&p<=90?q+A.W(45)+A.W(p+32):q+A.W(p)}return q.charCodeAt(0)==0?q:q},
eU:function eU(a){this.a=a},
ca:function ca(a){this.a=a},
nK:function nK(a){this.a=a},
fj:function fj(a){this.a=a},
ev:function ev(a){this.a=a},
jH:function jH(a){this.a=a},
fk:function fk(a){this.a=a},
hH:function hH(a){this.a=a},
bB:function bB(a){this.a=a},
cv:function cv(a){this.a=a},
fi:function fi(a){this.a=a},
dJ:function dJ(a){this.a=a},
jF:function jF(){this.a=$},
nD:function nD(a,b){this.a=a
this.b=b},
nE:function nE(a,b){this.a=a
this.b=b},
nF:function nF(a){this.a=a},
uF:function uF(a){this.a=a},
hI:function hI(){},
nG:function nG(a){this.a=a},
fl:function fl(a){this.a=a},
bu:function bu(a){this.a=a},
f:function f(a,b){this.b=a
this.a=b},
nH:function nH(a,b){this.a=a
this.b=b},
bl:function bl(a){this.a=a},
b9:function b9(a){this.a=a},
h1:function h1(a){this.a=a},
jG:function jG(a){this.a=a},
ne:function ne(a){this.a=a},
Iu(a5,a6){var s,r,q,p,o=null,n="dropdown",m="border-style",l="color",k="border-color",j="colorMsg",i="input",h="border-width",g="width",f="dimsMsg",e="background",d="background-color",c="height",b="menus",a="align-left",a0="align-center",a1="align-right",a2="padding",a3="text-align",a4="vertical-align"
if(a5.a==="table"){s=a5.b
r=t.N
q=t.ci
return new A.kg(a6.$1("tblProps"),A.a([new A.cU(a6.$1("border"),A.a([new A.b5(n,m,s.h(0,m),B.aS,o,o,o,o),new A.b5(l,k,s.h(0,k),o,A.l(["type","text","placeholder",a6.$1(l)],r,r),A.wR(),a6.$1(j),o),new A.b5(i,h,A.hi(s.h(0,h)),o,A.l(["type","text","placeholder",a6.$1(g)],r,r),A.hm(),a6.$1(f),o)],q)),new A.cU(a6.$1(e),A.a([new A.b5(l,d,s.h(0,d),o,A.l(["type","text","placeholder",a6.$1(l)],r,r),A.wR(),a6.$1(j),o)],q)),new A.cU(a6.$1("dimsAlm"),A.a([new A.b5(i,g,A.hi(s.h(0,g)),o,A.l(["type","text","placeholder",a6.$1(g)],r,r),A.hm(),a6.$1(f),o),new A.b5(i,c,A.hi(s.h(0,c)),o,A.l(["type","text","placeholder",a6.$1(c)],r,r),A.hm(),a6.$1(f),o),new A.b5(b,"align",s.h(0,"align"),o,o,o,o,A.a([new A.bY(a,a6.$1("alTblL"),"left"),new A.bY(a0,a6.$1("tblC"),"center"),new A.bY(a1,a6.$1("alTblR"),"right")],t.bD))],q))],t.eR))}s=a5.b
r=t.N
q=t.ci
p=t.bD
return new A.kg(a6.$1("cellProps"),A.a([new A.cU(a6.$1("border"),A.a([new A.b5(n,m,s.h(0,m),B.aS,o,o,o,o),new A.b5(l,k,s.h(0,k),o,A.l(["type","text","placeholder",a6.$1(l)],r,r),A.wR(),a6.$1(j),o),new A.b5(i,h,A.hi(s.h(0,h)),o,A.l(["type","text","placeholder",a6.$1(g)],r,r),A.hm(),a6.$1(f),o)],q)),new A.cU(a6.$1(e),A.a([new A.b5(l,d,s.h(0,d),o,A.l(["type","text","placeholder",a6.$1(l)],r,r),A.wR(),a6.$1(j),o)],q)),new A.cU(a6.$1("dims"),A.a([new A.b5(i,g,A.hi(s.h(0,g)),o,A.l(["type","text","placeholder",a6.$1(g)],r,r),A.hm(),a6.$1(f),o),new A.b5(i,c,A.hi(s.h(0,c)),o,A.l(["type","text","placeholder",a6.$1(c)],r,r),A.hm(),a6.$1(f),o),new A.b5(i,a2,A.hi(s.h(0,a2)),o,A.l(["type","text","placeholder",a6.$1(a2)],r,r),A.hm(),a6.$1(f),o)],q)),new A.cU(a6.$1("tblCellTxtAlm"),A.a([new A.b5(b,a3,s.h(0,a3),o,o,o,o,A.a([new A.bY(a,a6.$1("alCellTxtL"),"left"),new A.bY(a0,a6.$1("alCellTxtC"),"center"),new A.bY(a1,a6.$1("alCellTxtR"),"right"),new A.bY("align-justify",a6.$1("jusfCellTxt"),"justify")],p)),new A.b5(b,a4,s.h(0,a4),o,o,o,o,A.a([new A.bY("align-top",a6.$1("alCellTxtT"),"top"),new A.bY("align-middle",a6.$1("alCellTxtM"),"middle"),new A.bY("align-bottom",a6.$1("alCellTxtB"),"bottom")],p))],q))],t.eR))},
oP:function oP(a,b){this.a=a
this.b=b},
bY:function bY(a,b,c){this.a=a
this.b=b
this.c=c},
b5:function b5(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
cU:function cU(a,b){this.a=a
this.b=b},
kg:function kg(a,b){this.a=a
this.b=b},
xC(a){return new A.c_(A.b(t.N,t.z),A.a([],t.E),a)},
A8(a){var s,r,q,p,o,n
if(a instanceof A.f)return A.xC(a)
s=t.G.b(a)?a:B.l
r=s.h(0,"value")
if(r==null)r=a
q=A.V(A.p(r==null?1:r),null)
p=A.zi(q==null?1:q)
r=p.a
t.m.a(r.classList).add("ql-table-header")
r.setAttribute("class","ql-table-header")
o=s.h(0,"cellId")
n=o==null?"cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0"):A.p(o)
r.setAttribute("data-cell",n)
return A.xC(p)},
c_:function c_(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
A9(a){var s,r,q,p,o,n,m,l
if(a instanceof A.f)return new A.b8(A.a([],t.E),a)
s=A.xA(null,"OL","table-list-container")
r=s.a
r.removeAttribute("data-cell")
q=t.z
p=t.G.b(a)?A.Y(a,q,q):A.b(q,q)
for(o=0;o<2;++o){n=B.b5[o]
q=p.h(0,n)
if(A.p(q==null?"":q)==="1")p.Z(0,n)}for(q=p.gao(),q=q.gJ(q);q.l();){m=q.gq()
n=A.p(m.a)
if(n==="data-row")l=n
else l=n==="cellId"?"data-cell":"data-"+n
r.setAttribute(l,A.p(m.b))}return new A.b8(A.a([],t.E),s)},
Aa(a){var s,r,q,p,o=t.N,n=A.b(o,o)
for(o=a.a,s=0;s<6;++s){r=B.b9[s]
q=B.b.a0(r,"data-")?r:"data-"+r
p=A.m(o.getAttribute(q))
if(p!=null)n.j(0,r,p)}o=A.m(o.getAttribute("data-cell"))
n.j(0,"cellId",o==null?"cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0"):o)
for(s=0;s<2;++s)n.aQ(B.b5[s],new A.qR())
return n},
xD(a){var s=new A.cW(A.b(t.N,t.z),A.a([],t.E),a)
s.ji(a)
return s},
Ab(a){var s,r
if(a instanceof A.f)return A.xD(a)
s=A.p(a).length===0?"bullet":A.p(a)
$.y().a.a===$&&A.c()
r=t.m
r=r.a(r.a(self.document).createElement("LI"))
r.setAttribute("data-list",s)
r.setAttribute("class","table-list")
return A.xD(new A.f(A.b(t.O,t.g),r))},
b8:function b8(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
qR:function qR(){},
qQ:function qQ(){},
cW:function cW(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
Br(a){var s=A.V(a==null?"":a,null)
return s==null?0:s},
Hb(a){var s=a.gaG()
return s instanceof A.f?s:null},
Be(a){var s,r=a==null?null:a.gcB(),q=t.A
while(!0){if(!(r!=null&&!(r instanceof A.f)))break
s=r.a
if(q.a(s.nextSibling)==null)r=null
else{s=q.a(s.nextSibling)
s.toString
r=A.S(s)}}return t.q.a(r)},
ya(a){var s,r=a.geh(),q=t.A
while(!0){if(!(r!=null&&!(r instanceof A.f)))break
s=r.a
if(q.a(s.previousSibling)==null)r=null
else{s=q.a(s.previousSibling)
s.toString
r=A.S(s)}}return t.q.a(r)},
yr(a){var s,r
$.y().a.a===$&&A.c()
s=t.m
r=s.a(s.a(self.document).createElement("DIV"))
s.a(r.appendChild(s.a(a.a.cloneNode(!0))))
r=new A.f(A.b(t.O,t.g),r).gaf()
return r==null?"":r},
c6(a,b,c){var s=t.ty.a(a.gX().z.a5(b,c)),r=a.a
if(r!=null)r.D(s,a.c)
s.D(a,null)
return s},
bo(a,b,c){var s=a.gX().z.a5(b,c),r=a.a
if(r!=null)r.D(s,a.c)
if(s instanceof A.z)a.b2(s,null)
a.Y(0)
return s},
Bp(a,b){var s,r,q,p,o,n
for(s=B.b.aN(b,A.D("\\s+",!0,!1)),r=s.length,q=a.a,p=t.m,o=0;o<s.length;s.length===r||(0,A.k)(s),++o){n=s[o]
if(n.length!==0)p.a(q.classList).add(n)}q.setAttribute("class",b)},
uD(a,b,c,d,e){var s,r=a.a
if(r instanceof A.ay){s=r.gaO()
if(s!=null&&!A.ac(s.$1(a)))return!1}return A.Gb(a,b,c,d,e)},
Gb(a,b,c,d,e){var s,r,q=a.a
if(q==null||A.ac(c.$1(q)))return!1
s=a.b
if(s instanceof A.z&&A.ac(c.$1(s))){s.D(a,null)
r=a.b
if(r!=null)r.G(d,e)
else a.G(d,e)
return!0}A.c6(a,b,null).G(d,e)
return!0},
xz(a){return new A.bG(A.b(t.N,t.z),A.a([],t.E),a)},
A0(a){if(a instanceof A.f)return A.xz(a)
return A.xz(A.xA(a,"P","ql-table-block"))},
xA(a,b,c){var s,r,q,p
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement(b))
r=new A.f(A.b(t.O,t.g),s)
A.Bp(r,c)
if(a!=null){q=J.a3(a)
q=q.n(a,!1)||q.n(a,"")}else q=!0
p=q?null:A.p(a)
if(p!=null)s.setAttribute("data-cell",p)
else s.setAttribute("data-cell","cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0"))
return r},
xH(a){return new A.fJ(A.b(t.N,t.z),A.a([],t.E),a)},
Ae(a){if(a instanceof A.f)return A.xH(a)
return A.xH(A.xA(a,"P","table-th-block"))},
A2(a){var s,r
if(a instanceof A.f)return new A.a6(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
r=new A.f(A.b(t.O,t.g),s.a(s.a(self.document).createElement("TD")))
A.A1(r,a)
return new A.a6(A.a([],t.E),r)},
A1(a,b){var s,r,q,p
if(t.G.b(b))for(s=b.gao(),s=s.gJ(s),r=a.a;s.l();){q=s.gq()
p=q.b
if(p==null||J.A(p,!1)||A.p(p).length===0)continue
r.setAttribute(A.p(q.a),A.p(p))}},
eH(a){var s,r,q,p,o,n,m,l,k
t.T.a(a)
s=A.Ev(a)
r=t.N
q=A.b(r,r)
for(r=a.a,p=s>0,o=0;o<6;++o){n=B.b9[o]
if(A.I(r.hasAttribute(n))){m=A.m(r.getAttribute(n))
if(m==null)m=""
if(n==="rowspan"&&p){l=A.V(m,null)
q.j(0,n,""+((l==null?0:l)-s))}else{l=A.D("mso.*?;",!0,!1)
q.j(0,n,A.O(m,l,""))}}}if(A.Ew(a)){q.Z(0,"width")
k=q.h(0,"style")
if(k!=null){r=A.D("width.*?;",!0,!1)
q.j(0,"style",A.O(k,r,""))}}return q},
Ev(a){var s,r,q=A.Be(A.Hb(a)),p=t.K,o=0
while(!0){s=!1
if(q!=null){r=q.a
if(A.h(r.tagName)==="TR"){s=A.iQ(p.a(r.innerHTML))
s=s==null?null:J.L(s)
if(s==null)s=""
r=A.D("\\s",!0,!1)
s=A.O(s,r,"").length===0}}if(!s)break;++o
q=A.Be(q)}return o},
Ew(a){var s,r,q=t.A,p=a
while(!0){s=p==null
if(!(!s&&A.h(p.a.tagName)!=="TBODY"))break
r=null
if(!s){s=p.a
if(!(q.a(s.parentNode)==null)){s=q.a(s.parentNode)
s.toString
s=A.S(s)
r=s}}p=r instanceof A.f?r:null}for(;p!=null;){if(A.h(p.a.tagName)==="COLGROUP")return!0
p=A.ya(p)}return!1},
Ag(a){var s,r
if(a instanceof A.f)return new A.cF(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
r=new A.f(A.b(t.O,t.g),s.a(s.a(self.document).createElement("TH")))
A.A1(r,a)
return new A.cF(A.a([],t.E),r)},
Ac(a){var s
if(a instanceof A.f)return new A.ag(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("TR"))
return new A.ag(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
Af(a){var s
if(a instanceof A.f)return new A.bI(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("TR"))
return new A.bI(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
A_(a){var s
if(a instanceof A.f)return new A.bs(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("TBODY"))
return new A.bs(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
Ah(a){var s
if(a instanceof A.f)return new A.c0(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("THEAD"))
return new A.c0(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
xF(a){return new A.cE(A.b(t.N,t.z),A.a([],t.E),a)},
Ad(a){var s,r,q,p,o,n
if(a instanceof A.f)return A.xF(a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("TEMPORARY"))
r=new A.f(A.b(t.O,t.g),s)
A.Bp(r,"ql-table-temporary")
if(t.G.b(a))for(q=a.gao(),q=q.gJ(q);q.l();){p=q.gq()
o=A.p(p.a)
n=A.p(p.b)
if(o==="data-class"&&!B.b.v(n,"ql-table-better"))s.setAttribute(o,"ql-table-better "+n)
else s.setAttribute(o,n)}return A.xF(r)},
xG(a){var s,r,q,p=t.N,o=A.b(p,p)
for(p=t.T.a(a).a,s=0;s<4;++s){r=B.bc[s]
if(A.I(p.hasAttribute(r))){q=A.m(p.getAttribute(r))
o.j(0,r,q==null?"":q)}}return o},
xB(a){return new A.bZ(A.b(t.N,t.z),A.a([],t.E),a)},
A3(a){var s,r,q
if(a instanceof A.f)return A.xB(a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("COL"))
if(t.G.b(a))for(r=a.gao(),r=r.gJ(r);r.l();){q=r.gq()
s.setAttribute(A.p(q.a),A.p(q.b))}return A.xB(new A.f(A.b(t.O,t.g),s))},
A4(a){var s,r,q,p=t.N,o=A.b(p,p)
for(p=t.T.a(a).a,s=0;s<1;++s){r=B.f_[s]
if(A.I(p.hasAttribute(r))){q=A.m(p.getAttribute(r))
o.j(0,r,q==null?"":q)}}return o},
A5(a){var s
if(a instanceof A.f)return new A.bH(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("COLGROUP"))
return new A.bH(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
A7(a){var s
if(a instanceof A.f)return new A.b7(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("TABLE"))
return new A.b7(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
fE:function fE(){},
bG:function bG(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
qB:function qB(){},
fJ:function fJ(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
a6:function a6(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
qC:function qC(){},
qD:function qD(){},
cF:function cF(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
ag:function ag(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
rb:function rb(){},
bI:function bI(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
rf:function rf(){},
bs:function bs(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
qA:function qA(){},
c0:function c0(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
rg:function rg(){},
cE:function cE(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
re:function re(){},
bZ:function bZ(a,b,c){var _=this
_.ch=a
_.CW=$
_.e=b
_.c=_.b=_.a=_.f=null
_.d=c},
qE:function qE(){},
bH:function bH(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
qF:function qF(){},
dt:function dt(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
b7:function b7(a,b){var _=this
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
qK:function qK(){},
qO:function qO(){},
qP:function qP(){},
qG:function qG(){},
qH:function qH(){},
qI:function qI(a,b){this.a=a
this.b=b},
jY:function jY(a,b){this.a=a
this.b=b},
o8:function o8(){this.b=this.a=$},
Ex(a,b){var s,r=A.a([],t.t6),q=new A.fG(r,a,b)
q.jg(a,b)
s=t.z6
B.a.k(r,["tr",s.a(A.I0())])
B.a.k(r,["td, th",s.a(A.HZ())])
B.a.k(r,["col",s.a(A.I_())])
B.a.k(r,["table",s.a(A.I1())])
return q},
Bt(a){var s
if(a!=null){s=J.a3(a)
s=!s.n(a,!1)&&!s.n(a,"")&&!s.n(a,0)}else s=!1
return s},
FZ(a){return B.a.ag(a.a,0,new A.uv(),t.S)},
fG:function fG(a,b,c){this.c=a
this.a=b
this.b=c},
uv:function uv(){},
rh:function rh(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
rj:function rj(a,b){this.a=a
this.b=b},
rk:function rk(){},
rl:function rl(){},
ri:function ri(a){this.a=a},
rm:function rm(a){this.a=a},
JI(){var s,r,q=null
for(s=[new A.X("table-header",5,A.Ix(),B.w,B.d4,q,q,q,!1),new A.X("table-list-container",5,A.Jd(),B.aZ,B.eJ,q,q,q,!1),new A.X("table-list",5,A.Je(),B.aW,B.cW,q,q,q,!1),new A.X("table-cell-block",5,A.K7(),B.ab,B.dJ,q,q,q,!1),new A.X("table-th-block",5,A.Kg(),B.ab,B.dh,q,q,q,!1),new A.X("table-cell",5,A.K8(),B.b2,B.i,q,A.C0(),q,!1),new A.X("table-th",5,A.Ki(),B.dD,B.i,q,A.C0(),q,!1),new A.X("table-row",5,A.Kd(),B.ae,B.i,q,q,q,!1),new A.X("table-th-row",5,A.Kh(),B.ae,B.i,q,q,q,!1),new A.X("table-body",5,A.K6(),B.b1,B.i,q,q,q,!1),new A.X("table-thead",5,A.Kj(),B.dE,B.i,q,q,q,!1),new A.X("table-temporary",5,A.Ke(),B.dC,B.eX,q,A.Kf(),q,!1),new A.X("table-container",5,A.Kc(),B.b0,B.i,q,q,q,!1),new A.X("table-col",5,A.K9(),B.d0,B.i,q,A.Ka(),q,!1),new A.X("table-colgroup",5,A.Kb(),B.d1,B.i,q,q,q,!1)],r=0;r<15;++r)A.dd(s[r],!0)
A.cB("clipboard",new A.wy(),!0)
A.cB("table-better",new A.wz(),!0)},
wy:function wy(){},
wz:function wz(){},
Eu(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f
if(a instanceof A.eG)return a
s=t.G
if(s.b(a)){r=a.h(0,"language")
if(s.b(r)){q=r.h(0,"name")
p=A.p(q==null?"":q)
o=r.h(0,"content")
q=t.N
n=A.b(q,q)
if(s.b(o))for(q=o.gao(),q=q.gJ(q);q.l();){m=q.gq()
n.j(0,A.p(m.a),A.p(m.b))}l=new A.jY(p,n)}else l=r
k=a.h(0,"menus")
j=a.h(0,"toolbarButtons")
q=t.j
if(q.b(k)){m=J.el(k,new A.q3(),t.N)
m=A.N(m,!1,m.$ti.i("ad.E"))}else m=null
if(s.b(j)){s=t.N
i=A.b(s,t.c)
for(h=j.gao(),h=h.gJ(h);h.l();){g=h.gq()
f=A.p(g.a)
g=g.b
if(q.b(g)){g=J.el(g,new A.q4(),s)
g=A.N(g,!1,g.$ti.i("ad.E"))}else g=B.i
i.j(0,f,g)}s=i}else s=null
return new A.eG(l,m,s,J.A(a.h(0,"toolbarTable"),!0))}return B.mO},
Et(a,b){var s,r,q=b.a,p=new A.o8(),o=t.N,n=t.J,m=t.Bg
p.sjk(m.a(A.l(["en_US",B.fw,"zh_CN",B.fh,"fr_FR",B.fq,"pl_PL",B.fr,"de_DE",B.fk,"ru_RU",B.fo,"tr_TR",B.fj,"pt_PT",B.fi,"ja_JP",B.ft,"pt_BR",B.fv,"cs_CZ",B.fl,"da_DK",B.fp,"nb_NO",B.fn,"it_IT",B.fu,"sv_SE",B.fm,"zh_TW",B.fs],o,n)))
s=q==null
if(s||typeof q=="string"){A.m(q)
p.b=s?"en_US":q}else if(q instanceof A.jY){s=q.b
if(s.a!==0){r=q.a
n.a(s)
n=A.aJ(p.gkW(),o,n)
n.j(0,r,s)
p.sjk(m.a(n))}q=q.a
if(q.length!==0)p.b=q}else p.b="en_US"
q=new A.eF(p,a,b)
q.nn(a,b)
return q},
eG:function eG(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
q3:function q3(){},
q4:function q4(){},
fF:function fF(a,b){this.a=a
this.c=b},
eF:function eF(a,b,c){var _=this
_.c=a
_.e=_.d=$
_.f=null
_.w=_.r=$
_.a=b
_.b=c},
qb:function qb(a){this.a=a},
qc:function qc(a){this.a=a},
qd:function qd(a){this.a=a},
qe:function qe(a){this.a=a},
qf:function qf(a){this.a=a},
qg:function qg(a){this.a=a},
q5:function q5(){},
q6:function q6(a,b){this.a=a
this.b=b},
q7:function q7(a){this.a=a},
q8:function q8(a){this.a=a},
q9:function q9(a){this.a=a},
qa:function qa(a){this.a=a},
qm:function qm(a){this.a=a},
qn:function qn(a,b){this.a=a
this.b=b},
qh:function qh(a,b){this.a=a
this.b=b},
qi:function qi(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
qk:function qk(a){this.a=a},
qj:function qj(){},
z0(a,b,c,d){var s=d<b,r=s?d:b,q=c<a,p=q?c:a
s=s?b:d
return new A.mg(r,p,s,q?a:c)},
m9:function m9(){},
mg:function mg(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ds:function ds(a,b,c){this.a=a
this.b=b
this.c=c},
en:function en(a){this.b=this.a=null
this.c=a},
mo:function mo(){},
mk:function mk(){},
ml:function ml(){},
mm:function mm(a,b){this.a=a
this.b=b},
mn:function mn(){},
mi:function mi(){},
mj:function mj(){},
mh:function mh(a){this.a=a},
mf:function mf(a,b,c,d,e,f,g,h,i){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i},
je:function je(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.r=_.f=_.e=$
_.x=_.w=null
_.y=e
_.z=f
_.Q=null},
ma:function ma(a,b){this.a=a
this.b=b},
mb:function mb(a){this.a=a},
md:function md(a){this.a=a},
mc:function mc(a){this.a=a},
me:function me(){},
zk(a,b,c){var s,r,q,p=a/255,o=b/255,n=c/255,m=Math.max(p,Math.max(o,n)),l=m-Math.min(p,Math.min(o,n))
if(l!==0)if(m===p)s=B.f.b4((o-n)/l,6)
else s=m===o?(n-p)/l+2:(p-o)/l+4
else s=0
r=B.f.b4(B.f.b4(s*60,360)+360,360)
q=m===0?0:l/m*100
return new A.hG(r,q,m*100)},
Dr(a){var s,r,q,p,o,n,m=null,l=B.b.R(a)
if(l.length===0)return m
if(B.b.a0(l,"#")){s=B.b.L(l,1)
if(s.length===3)s=new A.a1(A.a(s.split(""),t.s),t.C.a(new A.nC()),t.e).bn(0)
if(s.length!==6)return m
r=A.V(s,16)
if(r==null)return m
return A.zk(B.d.cn(r,16)&255,B.d.cn(r,8)&255,r&255)}q=A.D("rgba?\\(\\s*(\\d+)\\D+(\\d+)\\D+(\\d+)",!0,!1).bk(l)
if(q==null)return m
p=q.b
if(1>=p.length)return A.d(p,1)
o=p[1]
o.toString
o=A.bM(o,m)
if(2>=p.length)return A.d(p,2)
n=p[2]
n.toString
n=A.bM(n,m)
if(3>=p.length)return A.d(p,3)
p=p[3]
p.toString
return A.zk(o,n,A.bM(p,m))},
hG:function hG(a,b,c){this.a=a
this.b=b
this.c=c},
nC:function nC(){},
nB:function nB(){},
jn:function jn(a,b){var _=this
_.a=a
_.y=_.x=$
_.z=b},
mI:function mI(a,b){this.a=a
this.b=b},
mH:function mH(a){this.a=a},
ox:function ox(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
iu:function iu(a,b,c){this.a=a
this.b=b
this.c=c},
ka:function ka(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=$
_.e=null
_.f=!1
_.y=_.x=_.w=_.r=null
_.z=$
_.Q=!1
_.at=_.as=$},
oy:function oy(a,b){this.a=a
this.b=b},
It(a,b){var s,r,q,p,o,n=new A.w7(a),m=new A.w8(),l=t.yU,k=t.zP,j=A.a([new A.cj("column",n.$1("col"),u.O,m,A.a([new A.bi(n.$1("insColL"),new A.vR(),!1,!1),new A.bi(n.$1("insColR"),new A.vS(),!1,!1),new A.bi(n.$1("delCol"),new A.vT(),!1,!1),new A.bi(n.$1("selCol"),new A.w_(),!1,!1)],l)),new A.cj("row",n.$1("row"),u.v,m,A.a([new A.bi(n.$1("headerRow"),new A.w0(),!0,!0),new A.bi(n.$1("insRowAbv"),new A.w1(),!1,!1),new A.bi(n.$1("insRowBlw"),new A.w2(),!1,!1),new A.bi(n.$1("delRow"),new A.w3(),!1,!1),new A.bi(n.$1("selRow"),new A.w4(),!1,!1)],l)),new A.cj("merge",n.$1("mCells"),u.S,m,A.a([new A.bi(n.$1("mCells"),new A.w5(),!1,!1),new A.bi(n.$1("sCell"),new A.w6(),!1,!1)],l)),new A.cj("table",n.$1("tblProps"),u.W,new A.vU(),B.Z),new A.cj("cell",n.$1("cellProps"),u.l,new A.vV(),B.Z),new A.cj("wrap",n.$1("insParaOTbl"),u.N,m,A.a([new A.bi(n.$1("insB4"),new A.vW(),!1,!1),new A.bi(n.$1("insAft"),new A.vX(),!1,!1)],l)),new A.cj("delete",n.$1("delTable"),u.g,new A.vY(),B.Z)],k),i=A.a([new A.cj("copy",n.$1("copyTable"),u.X,new A.vZ(),B.Z)],k)
if(b==null||b.length===0)return j
l=t.qe
s=A.b(t.N,l)
for(l=A.N(j,!0,l),B.a.H(l,i),r=l.length,q=0;q<l.length;l.length===r||(0,A.k)(l),++q){p=l[q]
s.j(0,p.a,p)}l=A.a([],k)
for(k=b.length,q=0;q<b.length;b.length===k||(0,A.k)(b),++q){o=b[q]
if(s.p(o)){r=s.h(0,o)
r.toString
l.push(r)}}return l},
bi:function bi(a,b,c,d){var _=this
_.b=a
_.c=b
_.d=c
_.e=d},
cj:function cj(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
w7:function w7(a){this.a=a},
w8:function w8(){},
vR:function vR(){},
vS:function vS(){},
vT:function vT(){},
w_:function w_(){},
w0:function w0(){},
w1:function w1(){},
w2:function w2(){},
w3:function w3(){},
w4:function w4(){},
w5:function w5(){},
w6:function w6(){},
vU:function vU(){},
vV:function vV(){},
vW:function vW(){},
vX:function vX(){},
vY:function vY(){},
vZ:function vZ(){},
dk:function dk(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.r=null
_.x=_.w=$
_.as=_.Q=_.z=_.y=null
_.at=!1
_.ax=f},
qU:function qU(a,b){this.a=a
this.b=b},
qV:function qV(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
qW:function qW(){},
qS:function qS(a){this.a=a},
qT:function qT(a){this.a=a},
l5:function l5(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
qX:function qX(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
kz:function kz(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.e=d
_.f=e
_.r=null
_.w=$
_.x=f},
r8:function r8(a){this.a=a},
r3:function r3(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
r4:function r4(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
r5:function r5(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
r2:function r2(a,b){this.a=a
this.b=b},
r1:function r1(a,b){this.a=a
this.b=b},
r6:function r6(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
r7:function r7(a,b){this.a=a
this.b=b},
r_:function r_(a,b,c){this.a=a
this.b=b
this.c=c},
r0:function r0(a){this.a=a},
qZ:function qZ(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
qY:function qY(a,b){this.a=a
this.b=b},
r9:function r9(a){this.a=a},
Ak(a){var s
if(a instanceof A.f)return new A.e_(A.a([],t.E),a)
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("SPAN"))
return new A.e_(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
e_:function e_(a,b){var _=this
_.z=$
_.e=a
_.c=_.b=_.a=_.f=null
_.d=b},
rc:function rc(a,b,c){var _=this
_.a=a
_.b=$
_.c=b
_.d=c
_.e=$},
rd:function rd(a){this.a=a},
bw(a){var s,r=$.y().a.ce(a)
if(r==null)throw A.i(A.xK("table-better: element bounding rects are not available on this platform adapter; assign elementRectResolver before using layout-dependent helpers."))
s=new A.uA(r)
return new A.fd(s.$1("left"),s.$1("top"),s.$1("right"),s.$1("bottom"),s.$1("width"),s.$1("height"))},
HG(a){if(a.length===0)return a
if(B.b.b8(a,A.D("\\d+\\.?\\d*",!0,!1),"").length===0)return a+"px"
return a},
hi(a){var s,r
if(a==null||a.length===0||B.b.be(a,"%"))return a
s=J.CQ(a,A.D("\\d+\\.?\\d*",!0,!1),"")
r=s.length
r=A.bg(r===0?a:B.b.t(a,0,a.length-r))
return""+B.f.ah(r==null?0:r)+s},
yh(a){var s,r
$.y().a.a===$&&A.c()
s=t.m
r=s.a(s.a(self.document).createElement("div"))
r.textContent=a
s.a(r.classList).add("ql-table-tooltip")
s.a(r.classList).add("ql-hidden")
r.setAttribute("class","ql-table-tooltip ql-hidden")
return new A.f(A.b(t.O,t.g),r)},
In(a){var s,r,q,p,o=new A.vM(),n=new A.vN(),m=A.N(a.a4(t.hB),!0,t.ty)
B.a.H(m,a.a4(t.wj))
B.a.H(m,a.a4(t.p4))
for(s=m.length,r=null,q=0;q<m.length;m.length===s||(0,A.k)(m),++q,r=p){p=o.$1(m[q])
if(!A.ac(n.$2(r,p)))return"left"}return r==null?"left":r},
BI(a){var s=a.a4(t.hB),r=s.$ti
s=new A.H(s.a(),r.i("H<1>"))
if(s.l()){s=s.b
return s==null?r.c.a(s):s}s=a.a4(t.fR)
r=s.$ti
s=new A.H(s.a(),r.i("H<1>"))
if(s.l()){s=s.b
return s==null?r.c.a(s):s}s=a.a4(t.p4)
r=s.$ti
s=new A.H(s.a(),r.i("H<1>"))
if(s.l()){s=s.b
return s==null?r.c.a(s):s}return null},
f4(a){var s,r,q=A.eH(t.T.a(a.d)),p=A.BI(a)
if(p==null){s=q.h(0,"data-row")
r=(s==null?"":s).split("-")
return new A.ao(q,"cell-"+(r.length>1?r[1]:""))}s=A.hk(p.P().h(0,p.gA()))
return new A.ao(q,s==null?"":s)},
hk(a){if(t.G.b(a))return A.m(a.h(0,"cellId"))
return A.m(a)},
Io(a){var s,r=A.D('data-(?!list)[a-z]+="[^"]*"',!0,!1)
r=A.iY(A.O(a,r,""),A.D('class="[^"]*"',!0,!1),t.tj.a(t.pj.a(new A.vO())),null)
s=A.D('class="\\s*"',!0,!1)
return A.O(r,s,"")},
bn(a,b){var s,r,q,p,o,n,m
if(b==null)b=a
s=A.bw(a)
r=A.bw(b)
q=b.a
p=s.a-r.a-B.f.ah(A.a9(q.scrollLeft))
o=s.b-r.b-B.f.ah(A.a9(q.scrollTop))
n=s.e
m=s.f
return new A.fd(p,o,p+n,o+m,n,m)},
iT(a){for(;a!=null;){if(a.gA()==="table-cell"||a.gA()==="table-th")return t.Z.a(a)
a=a.a}return null},
Bb(a){var s,r=B.b.R(a)
if(r.length===0)return 0
s=A.bg(r)
if(s==null||isNaN(s)||s==1/0||s==-1/0)return 0
return J.CW(s)},
iU(a,b){var s,r,q,p,o
if(!b)return A.af(a)+"px"
s=$.y().a
r=s.a
r===$&&A.c()
q=r.aI(".ql-editor")
if(q==null)A.a4(A.aL("table-better: no .ql-editor container found"))
p=A.Bb(s.dC(q,"padding-left"))
o=A.Bb(s.dC(q,"padding-right"))
return B.f.uq(a/(A.v(q.a.clientWidth)-p-o)*100,2)+"%"},
yk(a,b){var s,r,q,p=new A.vP(A.d1(a),a),o=t.N
o=A.b(o,o)
for(s=b.length,r=0;r<s;++r){q=b[r]
o.j(0,q,A.JJ(p.$1(q)))}return o},
IL(a){if(B.b.be(a,"width")||B.b.be(a,"height"))return!0
return!1},
BO(a){var s,r
if(a.length===0)return!0
s=A.D("^#([A-Fa-f0-9]{3,6})$",!0,!1)
r=A.D("^rgb\\((\\d{1,3}), (\\d{1,3}), (\\d{1,3})\\)$",!0,!1)
if(s.b.test(a))return!0
if(r.b.test(a))return!0
return B.a.v(B.dI,a)},
IP(a){var s,r
if(a.length===0)return!0
s=B.b.b8(a,A.D("\\d+\\.?\\d*",!0,!1),"")
if(s.length===0)return!0
if(s!=="px"&&s!=="em"&&s!=="%"){r=A.D("[a-z]",!0,!1)
return!r.b.test(s)&&A.bg(s)!=null}return!0},
d1(a){var s,r,q,p,o,n,m=t.N,l=A.b(m,m),k=A.m(a.a.getAttribute("style"))
if(k==null||B.b.R(k).length===0)return l
for(m=k.split(";"),s=m.length,r=0;r<s;++r){q=m[r]
p=B.b.ae(q,":")
if(p<=0)continue
o=B.b.R(B.b.t(q,0,p))
n=B.b.R(B.b.L(q,p+1))
if(o.length!==0&&n.length!==0)l.j(0,o,n)}return l},
he(a,b){if(b.a===0){a.a.removeAttribute("style")
return}a.a.setAttribute("style",b.gao().bU(0,new A.vv(),t.N).ab(0," "))},
JJ(a){if(B.b.a0(a,"rgba("))return A.JK(a)
if(!B.b.a0(a,"rgb("))return a
return"#"+new A.a1(A.a(B.b.b8(B.b.b8(a,A.D("^[^\\d]+",!0,!1),""),A.D("[^\\d]+$",!0,!1),"").split(","),t.s),t.C.a(new A.wA()),t.e).bn(0)},
JK(a){var s,r,q,p,o=t.e,n=A.N(new A.a1(A.a(B.b.b8(B.b.b8(a,A.D("^[^\\d]+",!0,!1),""),A.D("[^\\d]+$",!0,!1),"").split(","),t.s),t.C.a(new A.wB()),o),!0,o.i("ad.E"))
if(n.length<4)return a
o=A.bg(n[0])
s=B.f.ah(o==null?0:o)
o=A.bg(n[1])
r=B.f.ah(o==null?0:o)
o=A.bg(n[2])
q=B.f.ah(o==null?0:o)
o=A.bg(n[3])
p=B.b.ai(B.d.ac(B.f.ah((o==null?0:o)*255),16).toUpperCase(),2,"0")
return"#"+B.b.L(B.d.ac(16777216+(s<<16>>>0)+(r<<8>>>0)+q,16),1)+p},
f6(a,b){var s,r,q,p
for(s=b.gao(),s=s.gJ(s),r=a.a;s.l();){q=s.gq()
p=q.a
q=q.b
r.setAttribute(A.h(p),A.h(q))}},
aH(a,b){var s=A.d1(a)
s.H(0,b)
A.he(a,s)},
af(a){if(a===B.f.fk(a))return B.d.B(B.f.ah(a))
return B.f.B(a)},
wQ(a,b,c){var s,r,q,p,o,n,m,l,k,j=a.i_()
if(j&&c===0)return
s=a.dj()
r=a.eK(t.qk)
if(r==null)return
if(s!=null)if(j){for(q=t.T,p=q.a(s.d).a_("col"),o=p.length,n=0,m=0;m<p.length;p.length===o||(0,A.k)(p),++m){l=A.d1(p[m]).h(0,"width")
if(l!=null&&l.length!==0){k=A.D("[^\\d.\\-]",!0,!1)
k=A.bg(A.O(l,k,""))
n+=k==null?0:k}}p=t.N
A.aH(q.a(r.d),A.l(["width",A.af(n)+"%"],p,p))}else{for(q=t.T,p=q.a(s.d).a_("col"),o=p.length,n=0,m=0;m<p.length;p.length===o||(0,A.k)(p),++m){k=A.m(p[m].a.getAttribute("width"))
k=A.V(k==null?"":k,null)
n+=k==null?0:k}p=t.N
A.aH(q.a(r.d),A.l(["width",A.iU(n,!1)],p,p))}else{q=t.N
A.aH(t.T.a(r.d),A.l(["width",A.iU(b.e+c,j)],q,q))}},
fd:function fd(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
uA:function uA(a){this.a=a},
vM:function vM(){},
vN:function vN(){},
vO:function vO(){},
vP:function vP(a,b){this.a=a
this.b=b},
vv:function vv(){},
wA:function wA(){},
wB:function wB(){},
Ii(a){var s,r,q,p=A.D("^(?:(https?):\\/\\/)?(?:(?:www|m)\\.)?youtube\\.com\\/watch.*v=([a-zA-Z0-9_-]+)",!0,!1).bk(a)
if(p==null)p=A.D("^(?:(https?):\\/\\/)?(?:(?:www|m)\\.)?youtu\\.be\\/([a-zA-Z0-9_-]+)",!0,!1).bk(a)
if(p!=null){s=p.b
r=s.length
if(1>=r)return A.d(s,1)
q=s[1]
if(q==null)q="https"
if(2>=r)return A.d(s,2)
return q+"://www.youtube.com/embed/"+A.p(s[2])+"?showinfo=0"}p=A.D("^(?:(https?):\\/\\/)?(?:www\\.)?vimeo\\.com\\/(\\d+)",!0,!1).bk(a)
if(p!=null){s=p.b
r=s.length
if(1>=r)return A.d(s,1)
q=s[1]
if(q==null)q="https"
if(2>=r)return A.d(s,2)
return q+"://player.vimeo.com/video/"+A.p(s[2])+"/"}return a},
lr(a,b,c){var s=$.y().a.a
s===$&&A.c()
B.a.O(b,new A.vL(s,c,a))},
hs:function hs(){},
lT:function lT(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
lF:function lF(a){this.a=a},
lK:function lK(a){this.a=a},
lL:function lL(a){this.a=a},
lM:function lM(a,b){this.a=a
this.b=b},
lJ:function lJ(a,b){this.a=a
this.b=b},
lG:function lG(){},
lH:function lH(){},
lI:function lI(){},
lN:function lN(){},
lQ:function lQ(a,b,c){this.a=a
this.b=b
this.c=c},
lP:function lP(a,b,c){this.a=a
this.b=b
this.c=c},
lS:function lS(a){this.a=a},
lO:function lO(){},
lR:function lR(a){this.a=a},
cL:function cL(){},
lU:function lU(a){this.a=a},
vL:function vL(a,b,c){this.a=a
this.b=b
this.c=c},
D1(a,b){var s=a.eU("ql-tooltip"),r=new A.jd(a,b,s)
r.jj(a,b,'<span class="ql-tooltip-arrow"></span><div class="ql-tooltip-editor"><input type="text" data-formula="e=mc^2" data-link="https://quilljs.com" data-video="Embed URL"><a class="ql-close"></a></div>')
r.e=s.aI('input[type="text"]')
r.ed()
r.nb(a,b)
return r},
D0(a,b){var s=t.N,r=t.z
r=new A.fb(a,b,A.b(s,r),A.b(s,r),A.b(s,r))
r.h5()
r.jf(a,b)
r.na(a,b)
return r},
jd:function jd(a,b,c){var _=this
_.f=_.e=null
_.r=!1
_.a=a
_.b=b
_.c=c
_.d=null},
m0:function m0(a,b){this.a=a
this.b=b},
m2:function m2(a){this.a=a},
m3:function m3(a){this.a=a},
m1:function m1(a){this.a=a},
fb:function fb(a,b,c,d,e){var _=this
_.r=_.f=null
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
lZ:function lZ(){},
m_:function m_(a){this.a=a},
JT(a){var s=$.Cv()
if(s.b.test(a)&&!B.b.a0(a,"mailto:"))return"mailto:"+a
return a},
Ek(a,b){var s,r=$.Cd(),q=a.b
q===$&&A.c()
q=t.A.a(q.a.ownerDocument)
q.toString
q=new A.bu(q).gcq()
s=a.eU("ql-tooltip")
q=new A.kr(a,q,s)
q.jj(a,b,r)
q.e=s.aI('input[type="text"]')
q.ed()
s=s.aI("a.ql-preview")
q.Q!==$&&A.ai()
q.Q=s
return q},
Ej(a,b){var s=t.N,r=t.z
r=new A.fA(a,b,A.b(s,r),A.b(s,r),A.b(s,r))
r.h5()
r.jf(a,b)
r.nj(a,b)
return r},
kr:function kr(a,b,c){var _=this
_.Q=$
_.f=_.e=null
_.r=!1
_.a=a
_.b=b
_.c=c
_.d=null},
pJ:function pJ(a){this.a=a},
pK:function pK(a){this.a=a},
pL:function pL(a){this.a=a},
pI:function pI(){},
fA:function fA(a,b,c,d,e){var _=this
_.r=_.f=null
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
pF:function pF(){},
pG:function pG(a){this.a=a},
pH:function pH(a){this.a=a},
DS(a,b){var s=t.r
s=new A.cA(a,b,A.a([],s),A.a([],s),A.a([],t.yH))
s.hi()
return s},
cA:function cA(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=$
_.f=c
_.r=d
_.w=e
_.x=null},
oI:function oI(a){this.a=a},
oJ:function oJ(a){this.a=a},
oK:function oK(a){this.a=a},
oG:function oG(a,b){this.a=a
this.b=b},
oH:function oH(a,b){this.a=a
this.b=b},
jl:function jl(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=$
_.f=c
_.r=d
_.w=e
_.x=null},
jL:function jL(a,b,c,d,e,f){var _=this
_.y=a
_.z=null
_.a=b
_.b=c
_.e=_.d=_.c=$
_.f=d
_.r=e
_.w=f
_.x=null},
IO(a){var s=A.I2(a)
if(s==null||s.length===0)return!0
return s!=="visible"&&s!=="clip"},
eJ:function eJ(){},
t2:function t2(a){this.a=a},
uG(){var s,r=self,q=t.m,p=t.A,o=p.a(q.a(r.document).getElementById("bench-host"))
if(o!=null)o.remove()
s=q.a(q.a(r.document).createElement("div"))
s.id="bench-host"
q.a(p.a(q.a(r.document).body).appendChild(s))
return s},
uM(a){var s=t.z
return A.E6(new A.f(A.b(t.O,t.g),a),A.Aj(null,B.j9,A.l(["table-better",A.b(s,s)],t.N,s),null,!1,"snow"))},
Jg(){var s,r,q
A.IG()
A.JI()
s=new A.wn()
r=t.m.a(self)
q=t.qE
r.benchSetContents=A.f2(s.$1$1(new A.wm(),q))
r.benchInnerHtml=A.f2(s.$1$1(new A.wl(),q))
q=t.N
r.benchFromHtml=A.f2(s.$1$1(new A.wk(),q))
r.benchFromDeltaJson=A.f2(s.$1$1(new A.wj(),q))
r.benchReady=!0},
wm:function wm(){},
wl:function wl(){},
wk:function wk(){},
wj:function wj(){},
wn:function wn(){},
wo:function wo(a,b){this.a=a
this.b=b},
i4(a,b,c){var s=a.BYTES_PER_ELEMENT
c=A.b6(b,c,B.d.je(a.byteLength,s))
return J.ho(B.u.gdf(a),a.byteOffset+b*s,(c-b)*s)},
JG(a){if(typeof dartPrint=="function"){dartPrint(a)
return}if(typeof console=="object"&&typeof console.log!="undefined"){console.log(a)
return}if(typeof print=="function"){print(a)
return}throw"Unable to print message: "+String(a)},
Z(a,b){var s,r,q,p,o,n
if(b.length===0)return!1
s=b.split(".")
r=t.m.a(self)
for(q=s.length,p=t.A,o=0;o<q;++o){n=s[o]
r=p.a(r[n])
if(r==null)return!1}return a instanceof t.g.a(r)},
DF(a,b,c,d,e,f){var s
if(c==null)return a[b]()
else if(d==null)return a[b](c)
else{s=a[b](c,d)
return s}},
nU(a,b,c,d,e){return e.a(A.DF(a,b,c,d,null,null))},
DA(a,b,c){var s,r
for(s=0;s<5;++s){r=a[s]
if(A.ac(b.$1(r)))return r}return null},
DN(a,b,c){var s,r
if(a.length!==b.length)return!1
for(s=0;s<a.length;++s){r=a[s]
if(!(s<b.length))return A.d(b,s)
if(!J.A(r,b[s]))return!1}return!0},
BG(a){var s,r,q,p,o,n,m,l,k,j,i=t.s,h=new A.n9(A.a([],i)).q4(a)
i=A.a([],i)
s=A.a([],t.jY)
r=new A.na(h,new A.nt(h.c),new A.os(h.d,A.b(t.S,t.qu)),i,s)
q=r.jA(h.b.a,h.a.glk(),!0)
B.a.M(s)
p=h.x
o=p.h(0,"default")
n=h.y.h(0,"default")
if(o!=null)r.fZ(o.b,o.a)
A.a5(s,!0,t.ht)
s=n==null
m=s?null:r.oo(n)
if(s)l=A.a([],t.fE)
else{s=n.b
k=n.a
j=m==null?null:m.f
l=r.o6(s,k,j==null?B.jY:j)}if(m!=null)r.qw(l)
if(p.a>1)B.a.k(i,"headers first/even convertidos apenas como default (sele\xe7\xe3o por tipo na Fase 4.6)")
return A.x3(t.j.a(A.E9(A.Ha(q)).h(0,"ops")))},
GT(a){var s=a.b
return(s==null||s===B.a5)&&a.c==="\n"},
GS(a){var s=a.b
return s===B.S||s===B.a6||s===B.T},
Ha(a){var s,r,q,p,o,n,m,l=null,k=A.a([],t.fE)
for(s=a.length,r=l,q=0;q<a.length;a.length===s||(0,A.k)(a),++q,r=p){p=a[q]
o=p.b
if((o==null||o===B.a5)&&p.c==="\n"){o=r!=null
if(o){n=r.b
n=n===B.S||n===B.a6||n===B.T}else n=!1
if(n)continue
if(o){o=r.b
n=!((o==null||o===B.a5)&&r.c==="\n")
o=n}else o=!1
p.ay=o?r.ay:l}B.a.k(k,p)}m=k.length===0?l:B.a.gK(k)
s=!1
if(m!=null)if(!A.GT(m))if(!A.GS(m)){s=m.ay
s=s===B.aq||s===B.ar||s===B.as||s===B.at}if(s)B.a.k(k,A.bC(l,l,l,l,l,l,l,l,l,l,m.ay,l,l,l,l,l,l,"\n",l,l))
return k},
Iy(a,b){var s,r,q
if(a.length===0)return B.e5
s=$.yM().h(0,b.toLowerCase())
if(s!=null)r=s.c.w.length===0&&s.c.f==null
else r=!0
if(r)return A.a([new A.ct(a,null)],t.Cu)
try{r=A.Ff(s,A.Iz()).ui(a)
return r}catch(q){r=A.a([new A.ct(a,null)],t.Cu)
return r}},
Hn(a){return $.yM().h(0,a.uL(0))},
Hf(a){var s,r,q=a.geh()
for(s=t.A;q!=null;){if(q instanceof A.f)return q
r=q.a
if(s.a(r.previousSibling)==null)q=null
else{r=s.a(r.previousSibling)
r.toString
q=A.S(r)}}return null},
H4(a){var s,r,q=a.gcB()
for(s=t.A;q!=null;){if(q instanceof A.f)return q
r=q.a
if(s.a(r.nextSibling)==null)q=null
else{r=s.a(r.nextSibling)
r.toString
q=A.S(r)}}return null},
H7(a){var s,r,q,p,o,n,m,l,k,j=a.a_("br")
for(s=j.length,r=t.A,q=t.m,p=0;p<j.length;j.length===s||(0,A.k)(j),++p){o=j[p]
n=A.Hf(o)
m=A.H4(o)
if(n!=null&&B.bA.v(0,A.h(n.a.tagName))&&m!=null&&B.bA.v(0,A.h(m.a.tagName))){l=o.a
k=r.a(l.parentNode)
if(k!=null)q.a(k.removeChild(l))}}},
H8(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=a.a_('b[style*="font-weight"]')
for(s=e.length,r=t.A,q=t.m,p=t.I,o=0;o<e.length;e.length===s||(0,A.k)(e),++o){n=e[o]
m=n.a
l=A.m(m.getAttribute("style"))
if(l!=null){k=$.CA()
k=!k.b.test(l)}else k=!0
if(k)continue
if(r.a(m.parentNode)==null)j=null
else{k=r.a(m.parentNode)
k.toString
j=A.S(k)}if(j==null)continue
i=A.a5(n.gan(),!0,p)
for(k=i.length,h=j.a,g=0;g<k;++g){f=i[g]
q.a(h.insertBefore(f.a,m))}j=r.a(m.parentNode)
if(j!=null)q.a(j.removeChild(m))}},
JB(a){t.uF.a(a)
if(a.aI('[id^="docs-internal-guid-"]')!=null){A.H8(a)
A.H7(a)}},
ES(a){var s,r,q,p
if(!A.EQ(a))return a
for(s=a.length,r=0,q="";r<s;++r){p=a.charCodeAt(r)
switch(p){case 38:q+="&amp;"
break
case 60:q+="&lt;"
break
case 62:q+="&gt;"
break
case 13:q+="&#xD;"
break
default:q+=A.W(p)}}return q.charCodeAt(0)==0?q:q},
ER(a){var s,r,q,p
if(!A.EP(a))return a
for(s=a.length,r=0,q="";r<s;++r){p=a.charCodeAt(r)
switch(p){case 38:q+="&amp;"
break
case 60:q+="&lt;"
break
case 62:q+="&gt;"
break
case 34:q+="&quot;"
break
case 9:q+="&#x9;"
break
case 10:q+="&#xA;"
break
case 13:q+="&#xD;"
break
default:q+=A.W(p)}}return q.charCodeAt(0)==0?q:q},
EQ(a){var s,r,q
for(s=a.length,r=0;r<s;++r){q=a.charCodeAt(r)
if(q===38||q===60||q===62||q===13)return!0}return!1},
EP(a){var s,r,q
for(s=a.length,r=0;r<s;++r){q=a.charCodeAt(r)
if(q===38||q===60||q===62||q===34||q===9||q===10||q===13)return!0}return!1},
Bw(a,b,c){var s,r,q,p,o,n,m,l,k,j=new A.r(A.a([],t.t))
for(s=a.a,r=s.length,q=t.N,p=t.z,o=0;o<s.length;s.length===r||(0,A.k)(s),++o){n=s[o]
m=n.d
if(m==null)l=null
else l=A.Y(m,q,p)
m=l!=null
if(m&&l.h(0,b)!=null){j.b3(n)
continue}k=A.b(q,p)
k.j(0,b,c)
if(m)k.H(0,l)
j.V(0,n.c,k)}return j},
Bh(a){var s=a.gaG()
return s instanceof A.f?s:null},
AY(a){var s,r,q,p=A.Bh(a)
for(s=t.A;p!=null;){r=p.a
if(A.h(r.tagName).toUpperCase()==="TABLE")return p
q=null
if(!(s.a(r.parentNode)==null)){r=s.a(r.parentNode)
r.toString
r=A.S(r)
q=r}p=q instanceof A.f?q:null}return null},
Ju(a,b,c){var s,r,q,p
t.I.a(a)
t.D.a(b)
t._.a(c)
if(!(a instanceof A.f))return b
s=A.AY(a)
if(s==null)return b
r=a.gaf()
if(r==null)r=""
q=A.D("\\s",!0,!1)
if(A.O(r,q,"").length===0)return new A.r(A.a([],t.t))
p=B.a.ae(s.a_("tr"),a)+1
if(p<=0)return b
return A.Bw(b,a.a_("th").length!==0?"table-th":"table-cell",p)},
Js(a9,b0,b1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8=null
t.I.a(a9)
t.D.a(b0)
t._.a(b1)
if(!(a9 instanceof A.f))return b0
s=a9.a
r=A.h(s.tagName).toUpperCase()
q=r==="TD"
p=!q
if(p&&r!=="TH")return b0
o=q?"table-cell":"table-th"
n=q?"table-cell-block":"table-th-block"
m=A.AY(a9)
l=A.Bh(a9)
if(m==null||l==null)return b0
k=m.a_("tr")
j=l.a_(r.toLowerCase())
i=A.m(s.getAttribute("data-row"))
h=i!=null&&i.length!==0?i:B.a.ae(k,l)+1
s=B.a.gJ(a9.gan())
g=new A.aQ(s,t.mG).l()?t.T.a(s.gq()):a8
f=g==null?a8:A.m(g.a.getAttribute("data-cell"))
e=f!=null&&f.length!==0?f:B.a.ae(j,a9)+1
s=b0.a
if(s.length===0){q=t.N
d=t.z
b0.V(0,"\n",A.l([o,A.l(["data-row",h],q,d)],q,d))}c=new A.r(A.a([],t.t))
for(q=s.length,d=t.N,b=t.z,a=t.G,a0=0;a0<s.length;s.length===q||(0,A.k)(s),++a0){a1=s[a0]
a2=a1.d
if(a2==null)a3=a8
else a3=A.Y(a2,d,b)
a2=a3==null
a4=a2?a8:a3.h(0,o)
if(a4!=null){a5=A.b(d,b)
if(!a2)a5.H(0,a3)
a2=A.b(d,b)
if(a.b(a4))a2.H(0,a4.c2(0,d,b))
a2.j(0,"data-row",h)
a5.j(0,o,a2)
a6=a5}else a6=a3
a7=a1.c
c.V(0,p&&typeof a7=="string"&&!B.b.be(a7,"\n")?A.p(a7)+"\n":a7,a6)}return A.Bw(c,n,e)},
Jt(a,b,c){var s,r,q,p,o,n
t.I.a(a)
t.D.a(b)
t._.a(c)
if(!(a instanceof A.f))return b
s=a.a
r=A.m(s.getAttribute("span"))
q=A.V(r==null?"":r,null)
if(q==null)q=1
p=A.m(s.getAttribute("width"))
o=new A.r(A.a([],t.t))
for(s=t.N,r=t.dR,n=t.z;q>1;){o.V(0,"\n",A.l(["table-col",A.l(["width",p],s,r)],s,n));--q}return o.bj(b)},
Jv(a,b,c){var s,r,q,p,o,n,m,l,k
t.I.a(a)
t.D.a(b)
t._.a(c)
if(!(a instanceof A.f))return b
s=t.N
r=t.z
q=A.b(s,r)
for(p=a.a,o=0;o<4;++o){n=B.dS[o]
if(!A.I(p.hasAttribute(n)))continue
m=A.m(p.getAttribute(n))
if(m==null)m=""
l=n==="class"?"data-class":n
k=A.D("mso.*?;",!0,!1)
q.j(0,l,A.O(m,k,""))}p=new A.r(A.a([],t.t))
p.V(0,"\n",A.l(["table-temporary",q],s,r))
return p.bj(b)},
uN(a){var s=a.a,r=A.Z(s,"Element")
if(!r)return null
return s},
I2(a){var s,r,q=A.uN(a)
if(q==null)return null
try{s=t.m
s=A.h(s.a(s.a(self.window).getComputedStyle(q)).overflowY)
return s}catch(r){return null}},
Id(a,b){var s=A.uN(a)
if(s==null)return!1
A.I(s.dispatchEvent(t.m.a(new self.Event(b,{bubbles:!0}))))
return!0},
JP(a){var s,r=A.uN(a)
if(r!=null){s=A.Z(r,"HTMLSelectElement")
s=!s}else s=!0
if(s)return null
return A.h(r.value)},
JQ(a,b){var s,r=A.uN(a)
if(r!=null){s=A.Z(r,"HTMLSelectElement")
s=!s}else s=!0
if(s)return!1
r.value=b
return!0},
aa(a){return'<i class="ti ti-'+a+'" aria-hidden="true"></i>'}},B={}
var w=[A,J,B]
var $={}
A.xg.prototype={}
J.hK.prototype={
n(a,b){return a===b},
ga3(a){return A.hU(a)},
B(a){return"Instance of '"+A.oN(a)+"'"},
W(a,b){throw A.i(A.zE(a,t.pN.a(b)))},
gaz(a){return A.cn(A.y7(this))}}
J.jT.prototype={
B(a){return String(a)},
ga3(a){return a?519018:218159},
gaz(a){return A.cn(t.v)},
$iat:1,
$ix:1}
J.hM.prototype={
n(a,b){return null==b},
B(a){return"null"},
ga3(a){return 0},
W(a,b){return this.mS(a,t.pN.a(b))},
$iat:1,
$iah:1}
J.hN.prototype={$iam:1}
J.dQ.prototype={
ga3(a){return 0},
gaz(a){return B.n7},
B(a){return String(a)}}
J.kf.prototype={}
J.e0.prototype={}
J.da.prototype={
B(a){var s=a[$.wU()]
if(s==null)return this.mT(a)
return"JavaScript function for "+J.L(s)},
$ibr:1}
J.fp.prototype={
ga3(a){return 0},
B(a){return String(a)}}
J.fq.prototype={
ga3(a){return 0},
B(a){return String(a)}}
J.w.prototype={
k(a,b){A.K(a).c.a(b)
a.$flags&1&&A.ak(a,29)
a.push(b)},
cC(a,b){a.$flags&1&&A.ak(a,"removeAt",1)
if(b<0||b>=a.length)throw A.i(A.ki(b,null))
return a.splice(b,1)[0]},
V(a,b,c){A.K(a).c.a(c)
a.$flags&1&&A.ak(a,"insert",2)
if(b<0||b>a.length)throw A.i(A.ki(b,null))
a.splice(b,0,c)},
uc(a){a.$flags&1&&A.ak(a,"removeLast",1)
if(a.length===0)throw A.i(A.iS(a,-1))
return a.pop()},
Z(a,b){var s
a.$flags&1&&A.ak(a,"remove",1)
for(s=0;s<a.length;++s)if(J.A(a[s],b)){a.splice(s,1)
return!0}return!1},
H(a,b){var s
A.K(a).i("o<1>").a(b)
a.$flags&1&&A.ak(a,"addAll",2)
if(Array.isArray(b)){this.nD(a,b)
return}for(s=J.U(b);s.l();)a.push(s.gq())},
nD(a,b){var s,r
t.n.a(b)
s=b.length
if(s===0)return
if(a===b)throw A.i(A.aD(a))
for(r=0;r<s;++r)a.push(b[r])},
M(a){a.$flags&1&&A.ak(a,"clear","clear")
a.length=0},
O(a,b){var s,r
A.K(a).i("~(1)").a(b)
s=a.length
for(r=0;r<s;++r){b.$1(a[r])
if(a.length!==s)throw A.i(A.aD(a))}},
bU(a,b,c){var s=A.K(a)
return new A.a1(a,s.U(c).i("1(2)").a(b),s.i("@<1>").U(c).i("a1<1,2>"))},
ab(a,b){var s,r=A.eB(a.length,"",!1,t.N)
for(s=0;s<a.length;++s)this.j(r,s,A.p(a[s]))
return r.join(b)},
bn(a){return this.ab(a,"")},
lE(a,b){return A.dg(a,0,A.eg(b,"count",t.S),A.K(a).c)},
bL(a,b){return A.dg(a,b,null,A.K(a).c)},
lz(a,b){var s,r,q
A.K(a).i("1(1,1)").a(b)
s=a.length
if(s===0)throw A.i(A.cP())
if(0>=s)return A.d(a,0)
r=a[0]
for(q=1;q<s;++q){r=b.$2(r,a[q])
if(s!==a.length)throw A.i(A.aD(a))}return r},
ag(a,b,c,d){var s,r,q
d.a(b)
A.K(a).U(d).i("1(1,2)").a(c)
s=a.length
for(r=b,q=0;q<s;++q){r=c.$2(r,a[q])
if(a.length!==s)throw A.i(A.aD(a))}return r},
rE(a,b,c){var s,r,q,p=A.K(a)
p.i("x(1)").a(b)
p.i("1()?").a(c)
s=a.length
for(r=0;r<s;++r){q=a[r]
if(A.ac(b.$1(q)))return q
if(a.length!==s)throw A.i(A.aD(a))}return c.$0()},
ar(a,b){if(!(b>=0&&b<a.length))return A.d(a,b)
return a[b]},
dM(a,b,c){if(b<0||b>a.length)throw A.i(A.aK(b,0,a.length,"start",null))
if(c==null)c=a.length
else if(c<b||c>a.length)throw A.i(A.aK(c,b,a.length,"end",null))
if(b===c)return A.a([],A.K(a))
return A.a(a.slice(b,c),A.K(a))},
dL(a,b){return this.dM(a,b,null)},
gF(a){if(a.length>0)return a[0]
throw A.i(A.cP())},
gK(a){var s=a.length
if(s>0)return a[s-1]
throw A.i(A.cP())},
cg(a,b,c,d,e){var s,r,q,p,o
A.K(a).i("o<1>").a(d)
a.$flags&2&&A.ak(a,5)
A.b6(b,c,a.length)
s=c-b
if(s===0)return
A.bE(e,"skipCount")
if(t.j.b(d)){r=d
q=e}else{r=J.lB(d,e).b9(0,!1)
q=0}p=J.aO(r)
if(q+s>p.gm(r))throw A.i(A.zs())
if(q<b)for(o=s-1;o>=0;--o)a[b+o]=p.h(r,q+o)
else for(o=0;o<s;++o)a[b+o]=p.h(r,q+o)},
dG(a,b,c,d){return this.cg(a,b,c,d,0)},
bI(a,b,c,d){var s,r,q,p,o,n,m=this
A.K(a).i("o<1>").a(d)
a.$flags&1&&A.ak(a,"replaceRange","remove from or add to")
A.b6(b,c,a.length)
if(!t.ez.b(d))d=J.wY(d)
s=c-b
r=J.b1(d)
q=b+r
p=a.length
if(s>=r){o=s-r
n=p-o
m.dG(a,b,q,d)
if(o!==0){m.cg(a,q,n,a,c)
m.sm(a,n)}}else{n=p+(r-s)
a.length=n
m.cg(a,q,n,a,c)
m.dG(a,b,q,d)}},
c0(a,b){var s,r
A.K(a).i("x(1)").a(b)
s=a.length
for(r=0;r<s;++r){if(A.ac(b.$1(a[r])))return!0
if(a.length!==s)throw A.i(A.aD(a))}return!1},
cR(a,b){var s,r
A.K(a).i("x(1)").a(b)
s=a.length
for(r=0;r<s;++r){if(!A.ac(b.$1(a[r])))return!1
if(a.length!==s)throw A.i(A.aD(a))}return!0},
iZ(a,b){var s,r,q,p,o,n=A.K(a)
n.i("j(1,1)?").a(b)
a.$flags&2&&A.ak(a,"sort")
s=a.length
if(s<2)return
if(b==null)b=J.GJ()
if(s===2){r=a[0]
q=a[1]
n=b.$2(r,q)
if(typeof n!=="number")return n.dE()
if(n>0){a[0]=q
a[1]=r}return}p=0
if(n.c.b(null))for(o=0;o<a.length;++o)if(a[o]===void 0){a[o]=null;++p}a.sort(A.hh(b,2))
if(p>0)this.qd(a,p)},
mD(a){return this.iZ(a,null)},
qd(a,b){var s,r=a.length
for(;s=r-1,r>0;r=s)if(a[s]===null){a[s]=void 0;--b
if(b===0)break}},
ae(a,b){var s,r=a.length
if(0>=r)return-1
for(s=0;s<r;++s){if(!(s<a.length))return A.d(a,s)
if(J.A(a[s],b))return s}return-1},
v(a,b){var s
for(s=0;s<a.length;++s)if(J.A(a[s],b))return!0
return!1},
ga6(a){return a.length===0},
gal(a){return a.length!==0},
B(a){return A.xd(a,"[","]")},
b9(a,b){var s=A.K(a)
return b?A.a(a.slice(0),s):J.xe(a.slice(0),s.c)},
cZ(a){return this.b9(a,!0)},
gJ(a){return new J.d2(a,a.length,A.K(a).i("d2<1>"))},
ga3(a){return A.hU(a)},
gm(a){return a.length},
sm(a,b){a.$flags&1&&A.ak(a,"set length","change the length of")
if(b<0)throw A.i(A.aK(b,0,null,"newLength",null))
if(b>a.length)A.K(a).c.a(null)
a.length=b},
h(a,b){A.v(b)
if(!(b>=0&&b<a.length))throw A.i(A.iS(a,b))
return a[b]},
j(a,b,c){A.v(b)
A.K(a).c.a(c)
a.$flags&2&&A.ak(a)
if(!(b>=0&&b<a.length))throw A.i(A.iS(a,b))
a[b]=c},
iq(a,b){return new A.ae(a,b.i("ae<0>"))},
gaz(a){return A.cn(A.K(a))},
$iM:1,
$io:1,
$it:1}
J.nV.prototype={}
J.d2.prototype={
gq(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s,r=this,q=r.a,p=q.length
if(r.b!==p){q=A.k(q)
throw A.i(q)}s=r.c
if(s>=p){r.sjF(null)
return!1}r.sjF(q[s]);++r.c
return!0},
sjF(a){this.d=this.$ti.i("1?").a(a)},
$iar:1}
J.eA.prototype={
bi(a,b){var s
A.aF(b)
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){s=this.gfd(b)
if(this.gfd(a)===s)return 0
if(this.gfd(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gfd(a){return a===0?1/a<0:a<0},
aA(a){var s
if(a>=-2147483648&&a<=2147483647)return a|0
if(isFinite(a)){s=a<0?Math.ceil(a):Math.floor(a)
return s+0}throw A.i(A.aV(""+a+".toInt()"))},
kP(a){var s,r
if(a>=0){if(a<=2147483647){s=a|0
return a===s?s:s+1}}else if(a>=-2147483648)return a|0
r=Math.ceil(a)
if(isFinite(r))return r
throw A.i(A.aV(""+a+".ceil()"))},
hK(a){var s,r
if(a>=0){if(a<=2147483647)return a|0}else if(a>=-2147483648){s=a|0
return a===s?s:s-1}r=Math.floor(a)
if(isFinite(r))return r
throw A.i(A.aV(""+a+".floor()"))},
ah(a){if(a>0){if(a!==1/0)return Math.round(a)}else if(a>-1/0)return 0-Math.round(0-a)
throw A.i(A.aV(""+a+".round()"))},
fk(a){if(a<0)return-Math.round(-a)
else return Math.round(a)},
aC(a,b,c){if(B.d.bi(b,c)>0)throw A.i(A.f3(b))
if(this.bi(a,b)<0)return b
if(this.bi(a,c)>0)return c
return a},
uq(a,b){var s
if(b>20)throw A.i(A.aK(b,0,20,"fractionDigits",null))
s=a.toFixed(b)
if(a===0&&this.gfd(a))return"-"+s
return s},
ac(a,b){var s,r,q,p,o
if(b<2||b>36)throw A.i(A.aK(b,2,36,"radix",null))
s=a.toString(b)
r=s.length
q=r-1
if(!(q>=0))return A.d(s,q)
if(s.charCodeAt(q)!==41)return s
p=/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(s)
if(p==null)A.a4(A.aV("Unexpected toString result: "+s))
r=p.length
if(1>=r)return A.d(p,1)
s=p[1]
if(3>=r)return A.d(p,3)
o=+p[3]
r=p[2]
if(r!=null){s+=r
o-=r.length}return s+B.b.er("0",o)},
B(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
ga3(a){var s,r,q,p,o=a|0
if(a===o)return o&536870911
s=Math.abs(a)
r=Math.log(s)/0.6931471805599453|0
q=Math.pow(2,r)
p=s<1?s/q:q/s
return((p*9007199254740992|0)+(p*3542243181176521|0))*599197+r*1259&536870911},
b4(a,b){var s=a%b
if(s===0)return 0
if(s>0)return s
return s+b},
je(a,b){if((a|0)===a)if(b>=1||b<-1)return a/b|0
return this.ky(a,b)},
bC(a,b){return(a|0)===a?a/b|0:this.ky(a,b)},
ky(a,b){var s=a/b
if(s>=-2147483648&&s<=2147483647)return s|0
if(s>0){if(s!==1/0)return Math.floor(s)}else if(s>-1/0)return Math.ceil(s)
throw A.i(A.aV("Result of truncating division is "+A.p(s)+": "+A.p(a)+" ~/ "+b))},
ev(a,b){if(b<0)throw A.i(A.f3(b))
return b>31?0:a<<b>>>0},
qq(a,b){return b>31?0:a<<b>>>0},
cn(a,b){var s
if(a>0)s=this.eP(a,b)
else{s=b>31?31:b
s=a>>s>>>0}return s},
qr(a,b){if(0>b)throw A.i(A.f3(b))
return this.eP(a,b)},
eP(a,b){return b>31?0:a>>>b},
dE(a,b){return a>b},
gaz(a){return A.cn(t.fY)},
$ibO:1,
$ia2:1,
$iby:1}
J.hL.prototype={
gaz(a){return A.cn(t.S)},
$iat:1,
$ij:1}
J.jU.prototype={
gaz(a){return A.cn(t.pR)},
$iat:1}
J.dO.prototype={
dV(a,b,c){var s=b.length
if(c>s)throw A.i(A.aK(c,0,s,null,null))
return new A.lf(b,a,c)},
dU(a,b){return this.dV(a,b,0)},
be(a,b){var s=b.length,r=a.length
if(s>r)return!1
return b===this.L(a,r-s)},
b8(a,b,c){A.Ee(0,0,a.length,"startIndex")
return A.JY(a,b,c,0)},
aN(a,b){var s,r
if(typeof b=="string")return A.a(a.split(b),t.s)
else{if(b instanceof A.dP){s=b.gpn()
s.lastIndex=0
r=s.exec("").length-2===0}else r=!1
if(r)return A.a(a.split(b.b),t.s)
else return this.oe(a,b)}},
bI(a,b,c,d){var s=A.b6(b,c,a.length)
return A.yt(a,b,s,d)},
oe(a,b){var s,r,q,p,o,n,m=A.a([],t.s)
for(s=J.wW(b,a),s=s.gJ(s),r=0,q=1;s.l();){p=s.gq()
o=p.gex()
n=p.gbw()
q=n-o
if(q===0&&r===o)continue
B.a.k(m,this.t(a,r,o))
r=n}if(r<a.length||q>0)B.a.k(m,this.L(a,r))
return m},
aS(a,b,c){var s
if(c<0||c>a.length)throw A.i(A.aK(c,0,a.length,null,null))
s=c+b.length
if(s>a.length)return!1
return b===a.substring(c,s)},
a0(a,b){return this.aS(a,b,0)},
t(a,b,c){return a.substring(b,A.b6(b,c,a.length))},
L(a,b){return this.t(a,b,null)},
R(a){var s,r,q,p=a.trim(),o=p.length
if(o===0)return p
if(0>=o)return A.d(p,0)
if(p.charCodeAt(0)===133){s=J.DG(p,1)
if(s===o)return""}else s=0
r=o-1
if(!(r>=0))return A.d(p,r)
q=p.charCodeAt(r)===133?J.DH(p,r):o
if(s===0&&q===o)return p
return p.substring(s,q)},
er(a,b){var s,r
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.i(B.c3)
for(s=a,r="";!0;){if((b&1)===1)r=s+r
b=b>>>1
if(b===0)break
s+=s}return r},
ai(a,b,c){var s=b-a.length
if(s<=0)return a
return this.er(c,s)+a},
bl(a,b,c){var s
if(c<0||c>a.length)throw A.i(A.aK(c,0,a.length,null,null))
s=a.indexOf(b,c)
return s},
ae(a,b){return this.bl(a,b,0)},
i0(a,b){var s=a.length,r=b.length
if(s+r>s)s-=r
return a.lastIndexOf(b,s)},
v(a,b){return A.JU(a,b,0)},
bi(a,b){var s
A.h(b)
if(a===b)s=0
else s=a<b?-1:1
return s},
B(a){return a},
ga3(a){var s,r,q
for(s=a.length,r=0,q=0;q<s;++q){r=r+a.charCodeAt(q)&536870911
r=r+((r&524287)<<10)&536870911
r^=r>>6}r=r+((r&67108863)<<3)&536870911
r^=r>>11
return r+((r&16383)<<15)&536870911},
gaz(a){return A.cn(t.N)},
gm(a){return a.length},
h(a,b){A.v(b)
if(!(b>=0&&b<a.length))throw A.i(A.iS(a,b))
return a[b]},
$iat:1,
$ibO:1,
$ike:1,
$ie:1}
A.ea.prototype={
gJ(a){return new A.hu(J.U(this.gbQ()),A.u(this).i("hu<1,2>"))},
gm(a){return J.b1(this.gbQ())},
ga6(a){return J.lA(this.gbQ())},
gal(a){return J.yR(this.gbQ())},
bL(a,b){var s=A.u(this)
return A.x0(J.lB(this.gbQ(),b),s.c,s.y[1])},
ar(a,b){return A.u(this).y[1].a(J.lz(this.gbQ(),b))},
gF(a){return A.u(this).y[1].a(J.ek(this.gbQ()))},
v(a,b){return J.ly(this.gbQ(),b)},
B(a){return J.L(this.gbQ())}}
A.hu.prototype={
l(){return this.a.l()},
gq(){return this.$ti.y[1].a(this.a.gq())},
$iar:1}
A.em.prototype={
gbQ(){return this.a}}
A.ij.prototype={$iM:1}
A.ih.prototype={
h(a,b){return this.$ti.y[1].a(J.ej(this.a,A.v(b)))},
j(a,b,c){var s=this.$ti
J.yP(this.a,A.v(b),s.c.a(s.y[1].a(c)))},
sm(a,b){J.CR(this.a,b)},
k(a,b){var s=this.$ti
J.j_(this.a,s.c.a(s.y[1].a(b)))},
Z(a,b){return J.yT(this.a,b)},
$iM:1,
$it:1}
A.bd.prototype={
gbQ(){return this.a}}
A.d5.prototype={
c2(a,b,c){return new A.d5(this.a,this.$ti.i("@<1,2>").U(b).U(c).i("d5<1,2,3,4>"))},
p(a){return this.a.p(a)},
h(a,b){return this.$ti.i("4?").a(this.a.h(0,b))},
j(a,b,c){var s=this.$ti
s.y[2].a(b)
s.y[3].a(c)
this.a.j(0,s.c.a(b),s.y[1].a(c))},
aQ(a,b){var s=this.$ti
s.y[2].a(a)
s.i("4()").a(b)
return s.y[3].a(this.a.aQ(s.c.a(a),new A.m7(this,b)))},
Z(a,b){return this.$ti.i("4?").a(this.a.Z(0,b))},
O(a,b){this.a.O(0,new A.m6(this,this.$ti.i("~(3,4)").a(b)))},
ga7(){var s=this.$ti
return A.x0(this.a.ga7(),s.c,s.y[2])},
gak(){var s=this.$ti
return A.x0(this.a.gak(),s.y[1],s.y[3])},
gm(a){var s=this.a
return s.gm(s)},
ga6(a){var s=this.a
return s.ga6(s)},
gal(a){var s=this.a
return s.gal(s)},
gao(){return this.a.gao().bU(0,new A.m5(this),this.$ti.i("F<3,4>"))},
cb(a,b){this.a.cb(0,new A.m8(this,this.$ti.i("x(3,4)").a(b)))}}
A.m7.prototype={
$0(){return this.a.$ti.y[1].a(this.b.$0())},
$S(){return this.a.$ti.i("2()")}}
A.m6.prototype={
$2(a,b){var s=this.a.$ti
s.c.a(a)
s.y[1].a(b)
this.b.$2(s.y[2].a(a),s.y[3].a(b))},
$S(){return this.a.$ti.i("~(1,2)")}}
A.m5.prototype={
$1(a){var s=this.a.$ti
s.i("F<1,2>").a(a)
return new A.F(s.y[2].a(a.a),s.y[3].a(a.b),s.i("F<3,4>"))},
$S(){return this.a.$ti.i("F<3,4>(F<1,2>)")}}
A.m8.prototype={
$2(a,b){var s=this.a.$ti
s.c.a(a)
s.y[1].a(b)
return this.b.$2(s.y[2].a(a),s.y[3].a(b))},
$S(){return this.a.$ti.i("x(1,2)")}}
A.db.prototype={
B(a){return"LateInitializationError: "+this.a}}
A.eo.prototype={
gm(a){return this.a.length},
h(a,b){var s
A.v(b)
s=this.a
if(!(b>=0&&b<s.length))return A.d(s,b)
return s.charCodeAt(b)}}
A.pE.prototype={}
A.M.prototype={}
A.ad.prototype={
gJ(a){var s=this
return new A.be(s,s.gm(s),A.u(s).i("be<ad.E>"))},
ga6(a){return this.gm(this)===0},
gF(a){if(this.gm(this)===0)throw A.i(A.cP())
return this.ar(0,0)},
v(a,b){var s,r=this,q=r.gm(r)
for(s=0;s<q;++s){if(J.A(r.ar(0,s),b))return!0
if(q!==r.gm(r))throw A.i(A.aD(r))}return!1},
cR(a,b){var s,r,q=this
A.u(q).i("x(ad.E)").a(b)
s=q.gm(q)
for(r=0;r<s;++r){if(!A.ac(b.$1(q.ar(0,r))))return!1
if(s!==q.gm(q))throw A.i(A.aD(q))}return!0},
ab(a,b){var s,r,q,p=this,o=p.gm(p)
if(b.length!==0){if(o===0)return""
s=A.p(p.ar(0,0))
if(o!==p.gm(p))throw A.i(A.aD(p))
for(r=s,q=1;q<o;++q){r=r+b+A.p(p.ar(0,q))
if(o!==p.gm(p))throw A.i(A.aD(p))}return r.charCodeAt(0)==0?r:r}else{for(q=0,r="";q<o;++q){r+=A.p(p.ar(0,q))
if(o!==p.gm(p))throw A.i(A.aD(p))}return r.charCodeAt(0)==0?r:r}},
bn(a){return this.ab(0,"")},
bU(a,b,c){var s=A.u(this)
return new A.a1(this,s.U(c).i("1(ad.E)").a(b),s.i("@<ad.E>").U(c).i("a1<1,2>"))},
ag(a,b,c,d){var s,r,q,p=this
d.a(b)
A.u(p).U(d).i("1(1,ad.E)").a(c)
s=p.gm(p)
for(r=b,q=0;q<s;++q){r=c.$2(r,p.ar(0,q))
if(s!==p.gm(p))throw A.i(A.aD(p))}return r},
bL(a,b){return A.dg(this,b,null,A.u(this).i("ad.E"))},
b9(a,b){return A.N(this,b,A.u(this).i("ad.E"))},
cZ(a){return this.b9(0,!0)},
uo(a){var s,r=this,q=A.zz(A.u(r).i("ad.E"))
for(s=0;s<r.gm(r);++s)q.k(0,r.ar(0,s))
return q}}
A.eD.prototype={
nk(a,b,c,d){var s,r=this.b
A.bE(r,"start")
s=this.c
if(s!=null){A.bE(s,"end")
if(r>s)throw A.i(A.aK(r,0,s,"start",null))}},
goh(){var s=J.b1(this.a),r=this.c
if(r==null||r>s)return s
return r},
gqu(){var s=J.b1(this.a),r=this.b
if(r>s)return s
return r},
gm(a){var s,r=J.b1(this.a),q=this.b
if(q>=r)return 0
s=this.c
if(s==null||s>=r)return r-q
if(typeof s!=="number")return s.fG()
return s-q},
ar(a,b){var s=this,r=s.gqu()+b
if(b<0||r>=s.goh())throw A.i(A.nP(b,s.gm(0),s,"index"))
return J.lz(s.a,r)},
bL(a,b){var s,r,q=this
A.bE(b,"count")
s=q.b+b
r=q.c
if(r!=null&&s>=r)return new A.es(q.$ti.i("es<1>"))
return A.dg(q.a,s,r,q.$ti.c)},
b9(a,b){var s,r,q,p=this,o=p.b,n=p.a,m=J.aO(n),l=m.gm(n),k=p.c
if(k!=null&&k<l)l=k
s=l-o
if(s<=0){n=p.$ti.c
return b?J.nT(0,n):J.zu(0,n)}r=A.eB(s,m.ar(n,o),b,p.$ti.c)
for(q=1;q<s;++q){B.a.j(r,q,m.ar(n,o+q))
if(m.gm(n)<l)throw A.i(A.aD(p))}return r},
cZ(a){return this.b9(0,!0)}}
A.be.prototype={
gq(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s,r=this,q=r.a,p=J.aO(q),o=p.gm(q)
if(r.b!==o)throw A.i(A.aD(q))
s=r.c
if(s>=o){r.sdO(null)
return!1}r.sdO(p.ar(q,s));++r.c
return!0},
sdO(a){this.d=this.$ti.i("1?").a(a)},
$iar:1}
A.bU.prototype={
gJ(a){return new A.aS(J.U(this.a),this.b,A.u(this).i("aS<1,2>"))},
gm(a){return J.b1(this.a)},
ga6(a){return J.lA(this.a)},
gF(a){return this.b.$1(J.ek(this.a))},
ar(a,b){return this.b.$1(J.lz(this.a,b))}}
A.er.prototype={$iM:1}
A.aS.prototype={
l(){var s=this,r=s.b
if(r.l()){s.sdO(s.c.$1(r.gq()))
return!0}s.sdO(null)
return!1},
gq(){var s=this.a
return s==null?this.$ti.y[1].a(s):s},
sdO(a){this.a=this.$ti.i("2?").a(a)},
$iar:1}
A.a1.prototype={
gm(a){return J.b1(this.a)},
ar(a,b){return this.b.$1(J.lz(this.a,b))}}
A.an.prototype={
gJ(a){return new A.dq(J.U(this.a),this.b,this.$ti.i("dq<1>"))},
bU(a,b,c){var s=this.$ti
return new A.bU(this,s.U(c).i("1(2)").a(b),s.i("@<1>").U(c).i("bU<1,2>"))}}
A.dq.prototype={
l(){var s,r
for(s=this.a,r=this.b;s.l();)if(A.ac(r.$1(s.gq())))return!0
return!1},
gq(){return this.a.gq()},
$iar:1}
A.de.prototype={
bL(a,b){A.lC(b,"count",t.S)
A.bE(b,"count")
return new A.de(this.a,this.b+b,A.u(this).i("de<1>"))},
gJ(a){return new A.hZ(J.U(this.a),this.b,A.u(this).i("hZ<1>"))}}
A.ff.prototype={
gm(a){var s=J.b1(this.a)-this.b
if(s>=0)return s
return 0},
bL(a,b){A.lC(b,"count",t.S)
A.bE(b,"count")
return new A.ff(this.a,this.b+b,this.$ti)},
$iM:1}
A.hZ.prototype={
l(){var s,r
for(s=this.a,r=0;r<this.b;++r)s.l()
this.b=0
return s.l()},
gq(){return this.a.gq()},
$iar:1}
A.es.prototype={
gJ(a){return B.bX},
ga6(a){return!0},
gm(a){return 0},
gF(a){throw A.i(A.cP())},
ar(a,b){throw A.i(A.aK(b,0,0,"index",null))},
v(a,b){return!1},
cR(a,b){this.$ti.i("x(1)").a(b)
return!0},
ab(a,b){return""},
bU(a,b,c){this.$ti.U(c).i("1(2)").a(b)
return new A.es(c.i("es<0>"))},
bL(a,b){A.bE(b,"count")
return this},
b9(a,b){var s=J.nT(0,this.$ti.c)
return s},
cZ(a){return this.b9(0,!0)}}
A.hD.prototype={
l(){return!1},
gq(){throw A.i(A.cP())},
$iar:1}
A.ae.prototype={
gJ(a){return new A.aQ(J.U(this.a),this.$ti.i("aQ<1>"))}}
A.aQ.prototype={
l(){var s,r
for(s=this.a,r=this.$ti.c;s.l();)if(r.b(s.gq()))return!0
return!1},
gq(){return this.$ti.c.a(this.a.gq())},
$iar:1}
A.aI.prototype={
sm(a,b){throw A.i(A.aV("Cannot change the length of a fixed-length list"))},
k(a,b){A.b3(a).i("aI.E").a(b)
throw A.i(A.aV("Cannot add to a fixed-length list"))},
Z(a,b){throw A.i(A.aV("Cannot remove from a fixed-length list"))}}
A.e1.prototype={
j(a,b,c){A.v(b)
A.u(this).i("e1.E").a(c)
throw A.i(A.aV("Cannot modify an unmodifiable list"))},
sm(a,b){throw A.i(A.aV("Cannot change the length of an unmodifiable list"))},
k(a,b){A.u(this).i("e1.E").a(b)
throw A.i(A.aV("Cannot add to an unmodifiable list"))},
Z(a,b){throw A.i(A.aV("Cannot remove from an unmodifiable list"))}}
A.fN.prototype={}
A.hX.prototype={
gm(a){return J.b1(this.a)},
ar(a,b){var s=this.a,r=J.aO(s)
return r.ar(s,r.gm(s)-1-b)}}
A.dh.prototype={
ga3(a){var s=this._hashCode
if(s!=null)return s
s=664597*B.b.ga3(this.a)&536870911
this._hashCode=s
return s},
B(a){return'Symbol("'+this.a+'")'},
n(a,b){if(b==null)return!1
return b instanceof A.dh&&this.a===b.a},
$ifD:1}
A.iJ.prototype={}
A.ao.prototype={$r:"+(1,2)",$s:1}
A.h5.prototype={$r:"+column,row(1,2)",$s:2}
A.ba.prototype={$r:"+describe,value(1,2)",$s:3}
A.iv.prototype={$r:"+hasTd,hasTh(1,2)",$s:4}
A.h6.prototype={$r:"+icon,label(1,2)",$s:5}
A.f_.prototype={$r:"+id,ref(1,2)",$s:6}
A.h7.prototype={$r:"+next,rowspan(1,2)",$s:7}
A.f0.prototype={$r:"+node,offset(1,2)",$s:8}
A.d0.prototype={$r:"+(1,2,3)",$s:10}
A.c3.prototype={$r:"+(1,2,3,4)",$s:11}
A.iw.prototype={$r:"+cx,cy,radius,width(1,2,3,4)",$s:12}
A.h8.prototype={$r:"+endNode,endOffset,startNode,startOffset(1,2,3,4)",$s:13}
A.hx.prototype={}
A.hw.prototype={
c2(a,b,c){var s=A.u(this)
return A.zD(this,s.c,s.y[1],b,c)},
ga6(a){return this.gm(this)===0},
gal(a){return this.gm(this)!==0},
B(a){return A.xn(this)},
j(a,b,c){var s=A.u(this)
s.c.a(b)
s.y[1].a(c)
A.mL()},
aQ(a,b){var s=A.u(this)
s.c.a(a)
s.i("2()").a(b)
A.mL()},
Z(a,b){A.mL()},
gao(){return new A.cH(this.rz(),A.u(this).i("cH<F<1,2>>"))},
rz(){var s=this
return function(){var r=0,q=1,p,o,n,m,l,k
return function $async$gao(a,b,c){if(b===1){p=c
r=q}while(true)switch(r){case 0:o=s.ga7(),o=o.gJ(o),n=A.u(s),m=n.y[1],n=n.i("F<1,2>")
case 2:if(!o.l()){r=3
break}l=o.gq()
k=s.h(0,l)
r=4
return a.b=new A.F(l,k==null?m.a(k):k,n),1
case 4:r=2
break
case 3:return 0
case 1:return a.c=p,3}}}},
bo(a,b,c,d){var s=A.b(c,d)
this.O(0,new A.mM(this,A.u(this).U(c).U(d).i("F<1,2>(3,4)").a(b),s))
return s},
cb(a,b){A.u(this).i("x(1,2)").a(b)
A.mL()},
$iB:1}
A.mM.prototype={
$2(a,b){var s=A.u(this.a),r=this.b.$2(s.c.a(a),s.y[1].a(b))
this.c.j(0,r.a,r.b)},
$S(){return A.u(this.a).i("~(1,2)")}}
A.E.prototype={
gm(a){return this.b.length},
gjV(){var s=this.$keys
if(s==null){s=Object.keys(this.a)
this.$keys=s}return s},
p(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
h(a,b){if(!this.p(b))return null
return this.b[this.a[b]]},
O(a,b){var s,r,q,p
this.$ti.i("~(1,2)").a(b)
s=this.gjV()
r=this.b
for(q=s.length,p=0;p<q;++p)b.$2(s[p],r[p])},
ga7(){return new A.eW(this.gjV(),this.$ti.i("eW<1>"))},
gak(){return new A.eW(this.b,this.$ti.i("eW<2>"))}}
A.eW.prototype={
gm(a){return this.a.length},
ga6(a){return 0===this.a.length},
gal(a){return 0!==this.a.length},
gJ(a){var s=this.a
return new A.dv(s,s.length,this.$ti.i("dv<1>"))}}
A.dv.prototype={
gq(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s=this,r=s.c
if(r>=s.b){s.sdP(null)
return!1}s.sdP(s.a[r]);++s.c
return!0},
sdP(a){this.d=this.$ti.i("1?").a(a)},
$iar:1}
A.fc.prototype={
k(a,b){A.u(this).c.a(b)
A.D7()}}
A.al.prototype={
gm(a){return this.b},
ga6(a){return this.b===0},
gal(a){return this.b!==0},
gJ(a){var s,r=this,q=r.$keys
if(q==null){q=Object.keys(r.a)
r.$keys=q}s=q
return new A.dv(s,s.length,r.$ti.i("dv<1>"))},
v(a,b){if(typeof b!="string")return!1
if("__proto__"===b)return!1
return this.a.hasOwnProperty(b)}}
A.et.prototype={
gm(a){return this.a.length},
ga6(a){return this.a.length===0},
gal(a){return this.a.length!==0},
gJ(a){var s=this.a
return new A.dv(s,s.length,this.$ti.i("dv<1>"))},
ov(){var s,r,q,p,o=this,n=o.$map
if(n==null){n=new A.hO(o.$ti.i("hO<1,1>"))
for(s=o.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q]
n.j(0,p,p)}o.$map=n}return n},
v(a,b){return this.ov().p(b)}}
A.jR.prototype={
n(a,b){if(b==null)return!1
return b instanceof A.ez&&this.a.n(0,b.a)&&A.yl(this)===A.yl(b)},
ga3(a){return A.dU(this.a,A.yl(this),B.m,B.m)},
B(a){var s=B.a.ab([A.cn(this.$ti.c)],", ")
return this.a.B(0)+" with "+("<"+s+">")}}
A.ez.prototype={
$1(a){return this.a.$1$1(a,this.$ti.y[0])},
$2(a,b){return this.a.$1$2(a,b,this.$ti.y[0])},
$S(){return A.II(A.ln(this.a),this.$ti)}}
A.fo.prototype={
glm(){var s=this.a
if(s instanceof A.dh)return s
return this.a=new A.dh(A.h(s))},
gi8(){var s,r,q,p,o,n=this
if(n.c===1)return B.r
s=n.d
r=J.aO(s)
q=r.gm(s)-J.b1(n.e)-n.f
if(q===0)return B.r
p=[]
for(o=0;o<q;++o)p.push(r.h(s,o))
p.$flags=3
return p},
gtR(){var s,r,q,p,o,n,m,l,k=this
if(k.c!==0)return B.bj
s=k.e
r=J.aO(s)
q=r.gm(s)
p=k.d
o=J.aO(p)
n=o.gm(p)-q-k.f
if(q===0)return B.bj
m=new A.bT(t.eA)
for(l=0;l<q;++l)m.j(0,new A.dh(A.h(r.h(s,l))),o.h(p,n+l))
return new A.hx(m,t.j8)},
$izr:1}
A.oM.prototype={
$0(){return B.f.hK(1000*this.a.now())},
$S:13}
A.oL.prototype={
$2(a,b){var s
A.h(a)
s=this.a
s.b=s.b+"$"+a
B.a.k(this.b,a)
B.a.k(this.c,b);++s.a},
$S:2}
A.t4.prototype={
bV(a){var s,r,q=this,p=new RegExp(q.a).exec(a)
if(p==null)return null
s=Object.create(null)
r=q.b
if(r!==-1)s.arguments=p[r+1]
r=q.c
if(r!==-1)s.argumentsExpr=p[r+1]
r=q.d
if(r!==-1)s.expr=p[r+1]
r=q.e
if(r!==-1)s.method=p[r+1]
r=q.f
if(r!==-1)s.receiver=p[r+1]
return s}}
A.hT.prototype={
B(a){return"Null check operator used on a null value"},
$idc:1}
A.jV.prototype={
B(a){var s,r=this,q="NoSuchMethodError: method not found: '",p=r.b
if(p==null)return"NoSuchMethodError: "+r.a
s=r.c
if(s==null)return q+p+"' ("+r.a+")"
return q+p+"' on '"+s+"' ("+r.a+")"},
$idc:1}
A.kF.prototype={
B(a){var s=this.a
return s.length===0?"Error":"Error: "+s}}
A.or.prototype={
B(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.hE.prototype={}
A.iy.prototype={
B(a){var s,r=this.b
if(r!=null)return r
r=this.a
s=r!==null&&typeof r==="object"?r.stack:null
return this.b=s==null?"":s},
$idX:1}
A.bq.prototype={
B(a){var s=this.constructor,r=s==null?null:s.name
return"Closure '"+A.C2(r==null?"unknown":r)+"'"},
gaz(a){var s=A.ln(this)
return A.cn(s==null?A.b3(this):s)},
$ibr:1,
guJ(){return this},
$C:"$1",
$R:1,
$D:null}
A.jf.prototype={$C:"$0",$R:0}
A.jg.prototype={$C:"$2",$R:2}
A.kA.prototype={}
A.ks.prototype={
B(a){var s=this.$static_name
if(s==null)return"Closure of unknown static method"
return"Closure '"+A.C2(s)+"'"}}
A.fa.prototype={
n(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.fa))return!1
return this.$_target===b.$_target&&this.a===b.a},
ga3(a){return(A.ls(this.a)^A.hU(this.$_target))>>>0},
B(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.oN(this.a)+"'")}}
A.l1.prototype={
B(a){return"Reading static variable '"+this.a+"' during its initialization"}}
A.km.prototype={
B(a){return"RuntimeError: "+this.a}}
A.kX.prototype={
B(a){return"Assertion failed: "+A.dH(this.a)}}
A.u9.prototype={}
A.bT.prototype={
gm(a){return this.a},
ga6(a){return this.a===0},
gal(a){return this.a!==0},
ga7(){return new A.as(this,A.u(this).i("as<1>"))},
gak(){var s=A.u(this)
return A.ft(new A.as(this,s.i("as<1>")),new A.nX(this),s.c,s.y[1])},
p(a){var s,r
if(typeof a=="string"){s=this.b
if(s==null)return!1
return s[a]!=null}else if(typeof a=="number"&&(a&0x3fffffff)===a){r=this.c
if(r==null)return!1
return r[a]!=null}else return this.tv(a)},
tv(a){var s=this.d
if(s==null)return!1
return this.e8(s[this.e7(a)],a)>=0},
H(a,b){A.u(this).i("B<1,2>").a(b).O(0,new A.nW(this))},
h(a,b){var s,r,q,p,o=null
if(typeof b=="string"){s=this.b
if(s==null)return o
r=s[b]
q=r==null?o:r.b
return q}else if(typeof b=="number"&&(b&0x3fffffff)===b){p=this.c
if(p==null)return o
r=p[b]
q=r==null?o:r.b
return q}else return this.tw(b)},
tw(a){var s,r,q=this.d
if(q==null)return null
s=q[this.e7(a)]
r=this.e8(s,a)
if(r<0)return null
return s[r].b},
j(a,b,c){var s,r,q=this,p=A.u(q)
p.c.a(b)
p.y[1].a(c)
if(typeof b=="string"){s=q.b
q.jl(s==null?q.b=q.hc():s,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){r=q.c
q.jl(r==null?q.c=q.hc():r,b,c)}else q.ty(b,c)},
ty(a,b){var s,r,q,p,o=this,n=A.u(o)
n.c.a(a)
n.y[1].a(b)
s=o.d
if(s==null)s=o.d=o.hc()
r=o.e7(a)
q=s[r]
if(q==null)s[r]=[o.hd(a,b)]
else{p=o.e8(q,a)
if(p>=0)q[p].b=b
else q.push(o.hd(a,b))}},
aQ(a,b){var s,r,q=this,p=A.u(q)
p.c.a(a)
p.i("2()").a(b)
if(q.p(a)){s=q.h(0,a)
return s==null?p.y[1].a(s):s}r=b.$0()
q.j(0,a,r)
return r},
Z(a,b){var s=this
if(typeof b=="string")return s.kh(s.b,b)
else if(typeof b=="number"&&(b&0x3fffffff)===b)return s.kh(s.c,b)
else return s.tx(b)},
tx(a){var s,r,q,p,o=this,n=o.d
if(n==null)return null
s=o.e7(a)
r=n[s]
q=o.e8(r,a)
if(q<0)return null
p=r.splice(q,1)[0]
o.kC(p)
if(r.length===0)delete n[s]
return p.b},
M(a){var s=this
if(s.a>0){s.b=s.c=s.d=s.e=s.f=null
s.a=0
s.h9()}},
O(a,b){var s,r,q=this
A.u(q).i("~(1,2)").a(b)
s=q.e
r=q.r
for(;s!=null;){b.$2(s.a,s.b)
if(r!==q.r)throw A.i(A.aD(q))
s=s.c}},
jl(a,b,c){var s,r=A.u(this)
r.c.a(b)
r.y[1].a(c)
s=a[b]
if(s==null)a[b]=this.hd(b,c)
else s.b=c},
kh(a,b){var s
if(a==null)return null
s=a[b]
if(s==null)return null
this.kC(s)
delete a[b]
return s.b},
h9(){this.r=this.r+1&1073741823},
hd(a,b){var s=this,r=A.u(s),q=new A.od(r.c.a(a),r.y[1].a(b))
if(s.e==null)s.e=s.f=q
else{r=s.f
r.toString
q.d=r
s.f=r.c=q}++s.a
s.h9()
return q},
kC(a){var s=this,r=a.d,q=a.c
if(r==null)s.e=q
else r.c=q
if(q==null)s.f=r
else q.d=r;--s.a
s.h9()},
e7(a){return J.b4(a)&1073741823},
e8(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.A(a[r].a,b))return r
return-1},
B(a){return A.xn(this)},
hc(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s},
$ixj:1}
A.nX.prototype={
$1(a){var s=this.a,r=A.u(s)
s=s.h(0,r.c.a(a))
return s==null?r.y[1].a(s):s},
$S(){return A.u(this.a).i("2(1)")}}
A.nW.prototype={
$2(a,b){var s=this.a,r=A.u(s)
s.j(0,r.c.a(a),r.y[1].a(b))},
$S(){return A.u(this.a).i("~(1,2)")}}
A.od.prototype={}
A.as.prototype={
gm(a){return this.a.a},
ga6(a){return this.a.a===0},
gJ(a){var s=this.a,r=new A.cx(s,s.r,this.$ti.i("cx<1>"))
r.c=s.e
return r},
v(a,b){return this.a.p(b)}}
A.cx.prototype={
gq(){return this.d},
l(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.i(A.aD(q))
s=r.c
if(s==null){r.sdP(null)
return!1}else{r.sdP(s.a)
r.c=s.c
return!0}},
sdP(a){this.d=this.$ti.i("1?").a(a)},
$iar:1}
A.hO.prototype={
e7(a){return A.I4(a)&1073741823},
e8(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.A(a[r].a,b))return r
return-1}}
A.wb.prototype={
$1(a){return this.a(a)},
$S:28}
A.wc.prototype={
$2(a,b){return this.a(a,b)},
$S:54}
A.wd.prototype={
$1(a){return this.a(A.h(a))},
$S:45}
A.aW.prototype={
gaz(a){return A.cn(this.jS())},
jS(){return A.Ih(this.$r,this.eL())},
B(a){return this.kB(!1)},
kB(a){var s,r,q,p,o,n=this.oq(),m=this.eL(),l=(a?""+"Record ":"")+"("
for(s=n.length,r="",q=0;q<s;++q,r=", "){l+=r
p=n[q]
if(typeof p=="string")l=l+p+": "
if(!(q<m.length))return A.d(m,q)
o=m[q]
l=a?l+A.zH(o):l+A.p(o)}l+=")"
return l.charCodeAt(0)==0?l:l},
oq(){var s,r=this.$s
for(;$.u8.length<=r;)B.a.k($.u8,null)
s=$.u8[r]
if(s==null){s=this.nZ()
B.a.j($.u8,r,s)}return s},
nZ(){var s,r,q,p=this.$r,o=p.indexOf("("),n=p.substring(1,o),m=p.substring(o),l=m==="()"?0:m.replace(/[^,]/g,"").length+1,k=t.K,j=J.zt(l,k)
for(s=0;s<l;++s)j[s]=s
if(n!==""){r=n.split(",")
s=r.length
for(q=l;s>0;){--q;--s
B.a.j(j,q,r[s])}}return A.cc(j,k)}}
A.c2.prototype={
eL(){return[this.a,this.b]},
n(a,b){if(b==null)return!1
return b instanceof A.c2&&this.$s===b.$s&&J.A(this.a,b.a)&&J.A(this.b,b.b)},
ga3(a){return A.dU(this.$s,this.a,this.b,B.m)}}
A.h4.prototype={
eL(){return[this.a,this.b,this.c]},
n(a,b){var s=this
if(b==null)return!1
return b instanceof A.h4&&s.$s===b.$s&&J.A(s.a,b.a)&&J.A(s.b,b.b)&&J.A(s.c,b.c)},
ga3(a){var s=this
return A.dU(s.$s,s.a,s.b,s.c)}}
A.ee.prototype={
eL(){return this.a},
n(a,b){if(b==null)return!1
return b instanceof A.ee&&this.$s===b.$s&&A.Fe(this.a,b.a)},
ga3(a){return A.dU(this.$s,A.xp(this.a),B.m,B.m)}}
A.dP.prototype={
B(a){return"RegExp/"+this.a+"/"+this.b.flags},
gjZ(){var s=this,r=s.c
if(r!=null)return r
r=s.b
return s.c=A.xf(s.a,r.multiline,!r.ignoreCase,r.unicode,r.dotAll,!0)},
gpn(){var s=this,r=s.d
if(r!=null)return r
r=s.b
return s.d=A.xf(s.a+"|()",r.multiline,!r.ignoreCase,r.unicode,r.dotAll,!0)},
bk(a){var s=this.b.exec(a)
if(s==null)return null
return new A.ip(s)},
dV(a,b,c){if(c<0||c>b.length)throw A.i(A.aK(c,0,b.length,null,null))
return new A.kW(this,b,c)},
dU(a,b){return this.dV(0,b,0)},
jN(a,b){var s,r=this.gjZ()
if(r==null)r=t.K.a(r)
r.lastIndex=b
s=r.exec(a)
if(s==null)return null
return new A.ip(s)},
$ike:1,
$ikj:1}
A.ip.prototype={
gex(){return this.b.index},
gbw(){var s=this.b
return s.index+s[0].length},
eq(a){var s=this.b
if(!(a>=0&&a<s.length))return A.d(s,a)
return s[a]},
h(a,b){var s
A.v(b)
s=this.b
if(!(b>=0&&b<s.length))return A.d(s,b)
return s[b]},
$icS:1,
$ihW:1}
A.kW.prototype={
gJ(a){return new A.e9(this.a,this.b,this.c)}}
A.e9.prototype={
gq(){var s=this.d
return s==null?t.he.a(s):s},
l(){var s,r,q,p,o,n,m=this,l=m.b
if(l==null)return!1
s=m.c
r=l.length
if(s<=r){q=m.a
p=q.jN(l,s)
if(p!=null){m.d=p
o=p.gbw()
if(p.b.index===o){s=!1
if(q.b.unicode){q=m.c
n=q+1
if(n<r){if(!(q>=0&&q<r))return A.d(l,q)
q=l.charCodeAt(q)
if(q>=55296&&q<=56319){if(!(n>=0))return A.d(l,n)
s=l.charCodeAt(n)
s=s>=56320&&s<=57343}}}o=(s?o+1:o)+1}m.c=o
return!0}}m.b=m.d=null
return!1},
$iar:1}
A.i0.prototype={
gbw(){return this.a+this.c.length},
h(a,b){A.v(b)
if(b!==0)A.a4(A.ki(b,null))
return this.c},
eq(a){if(a!==0)throw A.i(A.ki(a,null))
return this.c},
$icS:1,
gex(){return this.a}}
A.lf.prototype={
gJ(a){return new A.lg(this.a,this.b,this.c)},
gF(a){var s=this.b,r=this.a.indexOf(s,this.c)
if(r>=0)return new A.i0(r,s)
throw A.i(A.cP())}}
A.lg.prototype={
l(){var s,r,q=this,p=q.c,o=q.b,n=o.length,m=q.a,l=m.length
if(p+n>l){q.d=null
return!1}s=m.indexOf(o,p)
if(s<0){q.c=l+1
q.d=null
return!1}r=s+n
q.d=new A.i0(s,o)
q.c=r===q.c?r+1:r
return!0},
gq(){var s=this.d
s.toString
return s},
$iar:1}
A.tB.prototype={
bP(){var s=this.b
if(s===this)throw A.i(new A.db("Local '' has not been initialized."))
return s},
sl8(a){if(this.b!==this)throw A.i(new A.db("Local '' has already been initialized."))
this.b=a}}
A.dT.prototype={
gaz(a){return B.n0},
kJ(a,b,c){return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
$iat:1,
$idT:1}
A.hR.prototype={
gdf(a){if(((a.$flags|0)&2)!==0)return new A.uj(a.buffer)
else return a.buffer},
p5(a,b,c,d){var s=A.aK(b,0,c,d,null)
throw A.i(s)},
jt(a,b,c,d){if(b>>>0!==b||b>c)this.p5(a,b,c,d)}}
A.uj.prototype={
kJ(a,b,c){var s=A.xo(this.a,b,c)
s.$flags=3
return s}}
A.k2.prototype={
gaz(a){return B.n1},
$iat:1}
A.bf.prototype={
gm(a){return a.length},
qo(a,b,c,d,e){var s,r,q=a.length
this.jt(a,b,q,"start")
this.jt(a,c,q,"end")
if(b>c)throw A.i(A.aK(b,0,c,null,null))
s=c-b
if(e<0)throw A.i(A.au(e,null))
r=d.length
if(r-e<s)throw A.i(A.aL("Not enough elements"))
if(e!==0||r!==s)d=d.subarray(e,e+s)
a.set(d,b)},
$ibS:1}
A.hQ.prototype={
h(a,b){A.v(b)
A.dy(b,a,a.length)
return a[b]},
j(a,b,c){A.v(b)
A.a9(c)
a.$flags&2&&A.ak(a)
A.dy(b,a,a.length)
a[b]=c},
$iM:1,
$io:1,
$it:1}
A.bV.prototype={
j(a,b,c){A.v(b)
A.v(c)
a.$flags&2&&A.ak(a)
A.dy(b,a,a.length)
a[b]=c},
cg(a,b,c,d,e){t.uI.a(d)
a.$flags&2&&A.ak(a,5)
if(t.eJ.b(d)){this.qo(a,b,c,d,e)
return}this.mU(a,b,c,d,e)},
dG(a,b,c,d){return this.cg(a,b,c,d,0)},
$iM:1,
$io:1,
$it:1}
A.k3.prototype={
gaz(a){return B.n2},
$iat:1}
A.k4.prototype={
gaz(a){return B.n3},
$iat:1}
A.k5.prototype={
gaz(a){return B.n4},
h(a,b){A.v(b)
A.dy(b,a,a.length)
return a[b]},
$iat:1}
A.k6.prototype={
gaz(a){return B.n5},
h(a,b){A.v(b)
A.dy(b,a,a.length)
return a[b]},
$iat:1}
A.k7.prototype={
gaz(a){return B.n6},
h(a,b){A.v(b)
A.dy(b,a,a.length)
return a[b]},
$iat:1}
A.k8.prototype={
gaz(a){return B.n9},
h(a,b){A.v(b)
A.dy(b,a,a.length)
return a[b]},
$iat:1}
A.k9.prototype={
gaz(a){return B.na},
h(a,b){A.v(b)
A.dy(b,a,a.length)
return a[b]},
$iat:1,
$ixJ:1}
A.hS.prototype={
gaz(a){return B.nb},
gm(a){return a.length},
h(a,b){A.v(b)
A.dy(b,a,a.length)
return a[b]},
$iat:1}
A.eC.prototype={
gaz(a){return B.nc},
gm(a){return a.length},
h(a,b){A.v(b)
A.dy(b,a,a.length)
return a[b]},
$iat:1,
$ieC:1,
$ieK:1}
A.iq.prototype={}
A.ir.prototype={}
A.is.prototype={}
A.it.prototype={}
A.ce.prototype={
i(a){return A.iE(v.typeUniverse,this,a)},
U(a){return A.AL(v.typeUniverse,this,a)}}
A.l4.prototype={}
A.iz.prototype={
B(a){return A.bj(this.a,null)},
$it3:1}
A.l3.prototype={
B(a){return this.a}}
A.iA.prototype={$idl:1}
A.tw.prototype={
$1(a){var s=this.a,r=s.a
s.a=null
r.$0()},
$S:17}
A.tv.prototype={
$1(a){var s,r
this.a.a=t.R.a(a)
s=this.b
r=this.c
s.firstChild?s.removeChild(r):s.appendChild(r)},
$S:97}
A.tx.prototype={
$0(){this.a.$0()},
$S:21}
A.ty.prototype={
$0(){this.a.$0()},
$S:21}
A.li.prototype={
ns(a,b){if(self.setTimeout!=null)this.b=self.setTimeout(A.hh(new A.uh(this,b),0),a)
else throw A.i(A.aV("`setTimeout()` not found."))},
eX(){if(self.setTimeout!=null){var s=this.b
if(s==null)return
self.clearTimeout(s)
this.b=null}else throw A.i(A.aV("Canceling a timer."))},
$iEA:1}
A.uh.prototype={
$0(){this.a.b=null
this.b.$0()},
$S:1}
A.kY.prototype={
dW(a){var s,r=this,q=r.$ti
q.i("1/?").a(a)
if(a==null)a=q.c.a(a)
if(!r.b)r.a.fO(a)
else{s=r.a
if(q.i("cs<1>").b(a))s.js(a)
else s.fX(a)}},
hv(a,b){var s=this.a
if(this.b)s.d7(a,b)
else s.eD(a,b)}}
A.up.prototype={
$1(a){return this.a.$2(0,a)},
$S:5}
A.uq.prototype={
$2(a,b){this.a.$2(1,new A.hE(a,t.AH.a(b)))},
$S:166}
A.vu.prototype={
$2(a,b){this.a(A.v(a),b)},
$S:232}
A.H.prototype={
gq(){var s=this.b
return s==null?this.$ti.c.a(s):s},
qf(a,b){var s,r,q
a=A.v(a)
b=b
s=this.a
for(;!0;)try{r=s(this,a,b)
return r}catch(q){b=q
a=1}},
l(){var s,r,q,p,o=this,n=null,m=null,l=0
for(;!0;){s=o.d
if(s!=null)try{if(s.l()){o.sfN(s.gq())
return!0}else o.shb(n)}catch(r){m=r
l=1
o.shb(n)}q=o.qf(l,m)
if(1===q)return!0
if(0===q){o.sfN(n)
p=o.e
if(p==null||p.length===0){o.a=A.AF
return!1}if(0>=p.length)return A.d(p,-1)
o.a=p.pop()
l=0
m=null
continue}if(2===q){l=0
m=null
continue}if(3===q){m=o.c
o.c=null
p=o.e
if(p==null||p.length===0){o.sfN(n)
o.a=A.AF
throw m
return!1}if(0>=p.length)return A.d(p,-1)
o.a=p.pop()
l=1
continue}throw A.i(A.aL("sync*"))}return!1},
eT(a){var s,r,q=this
if(a instanceof A.cH){s=a.a()
r=q.e
if(r==null)r=q.e=[]
B.a.k(r,q.a)
q.a=s
return 2}else{q.shb(J.U(a))
return 2}},
sfN(a){this.b=this.$ti.i("1?").a(a)},
shb(a){this.d=this.$ti.i("ar<1>?").a(a)},
$iar:1}
A.cH.prototype={
gJ(a){return new A.H(this.a(),this.$ti.i("H<1>"))}}
A.d3.prototype={
B(a){return A.p(this.a)},
$iaq:1,
gdK(){return this.b}}
A.nu.prototype={
$0(){var s,r,q,p,o,n,m,l=null
try{l=this.a.$0()}catch(q){s=A.bk(q)
r=A.cJ(q)
p=s
o=r
A.B8(p,o)
this.b.d7(p,o)
return}p=this.b
o=p.$ti
n=o.i("1/").a(l)
if(o.i("cs<1>").b(n))if(o.b(n))A.xQ(n,p)
else p.jr(n)
else{m=p.eN()
o.c.a(n)
p.a=8
p.c=n
A.h0(p,m)}},
$S:1}
A.l0.prototype={
hv(a,b){var s,r=this.a
if((r.a&30)!==0)throw A.i(A.aL("Future already completed"))
s=A.GI(a,b)
r.eD(s.a,s.b)},
kU(a){return this.hv(a,null)}}
A.eR.prototype={
dW(a){var s,r=this.$ti
r.i("1/?").a(a)
s=this.a
if((s.a&30)!==0)throw A.i(A.aL("Future already completed"))
s.fO(r.i("1/").a(a))}}
A.eS.prototype={
tK(a){if((this.c&15)!==6)return!0
return this.b.b.ih(t.bl.a(this.d),a.a,t.v,t.K)},
rV(a){var s,r=this,q=r.e,p=null,o=t.z,n=t.K,m=a.a,l=r.b.b
if(t.nW.b(q))p=l.uk(q,m,a.b,o,n,t.AH)
else p=l.ih(t.h_.a(q),m,o,n)
try{o=r.$ti.i("2/").a(p)
return o}catch(s){if(t.bs.b(A.bk(s))){if((r.c&1)!==0)throw A.i(A.au("The error handler of Future.then must return a value of the returned future's type","onError"))
throw A.i(A.au("The error handler of Future.catchError must return a value of the future's type","onError"))}else throw s}}}
A.aN.prototype={
kp(a){this.a=this.a&1|4
this.c=a},
ii(a,b,c){var s,r,q,p=this.$ti
p.U(c).i("1/(2)").a(a)
s=$.aB
if(s===B.p){if(b!=null&&!t.nW.b(b)&&!t.h_.b(b))throw A.i(A.hp(b,"onError",u.w))}else{c.i("@<0/>").U(p.c).i("1(2)").a(a)
if(b!=null)b=A.Hj(b,s)}r=new A.aN(s,c.i("aN<0>"))
q=b==null?1:3
this.fM(new A.eS(r,q,a,b,p.i("@<1>").U(c).i("eS<1,2>")))
return r},
un(a,b){return this.ii(a,null,b)},
kA(a,b,c){var s,r=this.$ti
r.U(c).i("1/(2)").a(a)
s=new A.aN($.aB,c.i("aN<0>"))
this.fM(new A.eS(s,19,a,b,r.i("@<1>").U(c).i("eS<1,2>")))
return s},
qn(a){this.a=this.a&1|16
this.c=a},
eG(a){this.a=a.a&30|this.a&1
this.c=a.c},
fM(a){var s,r=this,q=r.a
if(q<=3){a.a=t.f7.a(r.c)
r.c=a}else{if((q&4)!==0){s=t.hR.a(r.c)
if((s.a&24)===0){s.fM(a)
return}r.eG(s)}A.hc(null,null,r.b,t.R.a(new A.tK(r,a)))}},
hj(a){var s,r,q,p,o,n,m=this,l={}
l.a=a
if(a==null)return
s=m.a
if(s<=3){r=t.f7.a(m.c)
m.c=a
if(r!=null){q=a.a
for(p=a;q!=null;p=q,q=o)o=q.a
p.a=r}}else{if((s&4)!==0){n=t.hR.a(m.c)
if((n.a&24)===0){n.hj(a)
return}m.eG(n)}l.a=m.eO(a)
A.hc(null,null,m.b,t.R.a(new A.tR(l,m)))}},
eN(){var s=t.f7.a(this.c)
this.c=null
return this.eO(s)},
eO(a){var s,r,q
for(s=a,r=null;s!=null;r=s,s=q){q=s.a
s.a=r}return r},
jr(a){var s,r,q,p=this
p.a^=2
try{a.ii(new A.tO(p),new A.tP(p),t.b)}catch(q){s=A.bk(q)
r=A.cJ(q)
A.BZ(new A.tQ(p,s,r))}},
fX(a){var s,r=this
r.$ti.c.a(a)
s=r.eN()
r.a=8
r.c=a
A.h0(r,s)},
d7(a,b){var s
t.AH.a(b)
s=this.eN()
this.qn(new A.d3(a,b))
A.h0(this,s)},
fO(a){var s=this.$ti
s.i("1/").a(a)
if(s.i("cs<1>").b(a)){this.js(a)
return}this.nH(a)},
nH(a){var s=this
s.$ti.c.a(a)
s.a^=2
A.hc(null,null,s.b,t.R.a(new A.tM(s,a)))},
js(a){var s=this.$ti
s.i("cs<1>").a(a)
if(s.b(a)){A.F4(a,this)
return}this.jr(a)},
eD(a,b){this.a^=2
A.hc(null,null,this.b,t.R.a(new A.tL(this,a,b)))},
$ics:1}
A.tK.prototype={
$0(){A.h0(this.a,this.b)},
$S:1}
A.tR.prototype={
$0(){A.h0(this.b,this.a.a)},
$S:1}
A.tO.prototype={
$1(a){var s,r,q,p=this.a
p.a^=2
try{p.fX(p.$ti.c.a(a))}catch(q){s=A.bk(q)
r=A.cJ(q)
p.d7(s,r)}},
$S:17}
A.tP.prototype={
$2(a,b){this.a.d7(t.K.a(a),t.AH.a(b))},
$S:81}
A.tQ.prototype={
$0(){this.a.d7(this.b,this.c)},
$S:1}
A.tN.prototype={
$0(){A.xQ(this.a.a,this.b)},
$S:1}
A.tM.prototype={
$0(){this.a.fX(this.b)},
$S:1}
A.tL.prototype={
$0(){this.a.d7(this.b,this.c)},
$S:1}
A.tU.prototype={
$0(){var s,r,q,p,o,n,m,l=this,k=null
try{q=l.a.a
k=q.b.b.uj(t.pF.a(q.d),t.z)}catch(p){s=A.bk(p)
r=A.cJ(p)
if(l.c&&t.Fq.a(l.b.a.c).a===s){q=l.a
q.c=t.Fq.a(l.b.a.c)}else{q=s
o=r
if(o==null)o=A.wZ(q)
n=l.a
n.c=new A.d3(q,o)
q=n}q.b=!0
return}if(k instanceof A.aN&&(k.a&24)!==0){if((k.a&16)!==0){q=l.a
q.c=t.Fq.a(k.c)
q.b=!0}return}if(k instanceof A.aN){m=l.b.a
q=l.a
q.c=k.un(new A.tV(m),t.z)
q.b=!1}},
$S:1}
A.tV.prototype={
$1(a){return this.a},
$S:95}
A.tT.prototype={
$0(){var s,r,q,p,o,n,m,l
try{q=this.a
p=q.a
o=p.$ti
n=o.c
m=n.a(this.b)
q.c=p.b.b.ih(o.i("2/(1)").a(p.d),m,o.i("2/"),n)}catch(l){s=A.bk(l)
r=A.cJ(l)
q=s
p=r
if(p==null)p=A.wZ(q)
o=this.a
o.c=new A.d3(q,p)
o.b=!0}},
$S:1}
A.tS.prototype={
$0(){var s,r,q,p,o,n,m,l=this
try{s=t.Fq.a(l.a.a.c)
p=l.b
if(p.a.tK(s)&&p.a.e!=null){p.c=p.a.rV(s)
p.b=!1}}catch(o){r=A.bk(o)
q=A.cJ(o)
p=t.Fq.a(l.a.a.c)
if(p.a===r){n=l.b
n.c=p
p=n}else{p=r
n=q
if(n==null)n=A.wZ(p)
m=l.b
m.c=new A.d3(p,n)
p=m}p.b=!0}},
$S:1}
A.kZ.prototype={}
A.le.prototype={}
A.iI.prototype={$iAx:1}
A.vs.prototype={
$0(){A.Dm(this.a,this.b)},
$S:1}
A.lb.prototype={
ul(a){var s,r,q
t.R.a(a)
try{if(B.p===$.aB){a.$0()
return}A.Bk(null,null,this,a,t.jW)}catch(q){s=A.bk(q)
r=A.cJ(q)
A.yc(t.K.a(s),t.AH.a(r))}},
hr(a){return new A.ua(this,t.R.a(a))},
h(a,b){return null},
uj(a,b){b.i("0()").a(a)
if($.aB===B.p)return a.$0()
return A.Bk(null,null,this,a,b)},
ih(a,b,c,d){c.i("@<0>").U(d).i("1(2)").a(a)
d.a(b)
if($.aB===B.p)return a.$1(b)
return A.Ht(null,null,this,a,b,c,d)},
uk(a,b,c,d,e,f){d.i("@<0>").U(e).U(f).i("1(2,3)").a(a)
e.a(b)
f.a(c)
if($.aB===B.p)return a.$2(b,c)
return A.Hs(null,null,this,a,b,c,d,e,f)},
lA(a,b,c,d){return b.i("@<0>").U(c).U(d).i("1(2,3)").a(a)}}
A.ua.prototype={
$0(){return this.a.ul(this.b)},
$S:1}
A.du.prototype={
gm(a){return this.a},
ga6(a){return this.a===0},
gal(a){return this.a!==0},
ga7(){return new A.eT(this,A.u(this).i("eT<1>"))},
gak(){var s=A.u(this)
return A.ft(new A.eT(this,s.i("eT<1>")),new A.tW(this),s.c,s.y[1])},
p(a){var s,r
if(typeof a=="string"&&a!=="__proto__"){s=this.b
return s==null?!1:s[a]!=null}else if(typeof a=="number"&&(a&1073741823)===a){r=this.c
return r==null?!1:r[a]!=null}else return this.jz(a)},
jz(a){var s=this.d
if(s==null)return!1
return this.c_(this.jR(s,a),a)>=0},
h(a,b){var s,r,q
if(typeof b=="string"&&b!=="__proto__"){s=this.b
r=s==null?null:A.xR(s,b)
return r}else if(typeof b=="number"&&(b&1073741823)===b){q=this.c
r=q==null?null:A.xR(q,b)
return r}else return this.jQ(b)},
jQ(a){var s,r,q=this.d
if(q==null)return null
s=this.jR(q,a)
r=this.c_(s,a)
return r<0?null:s[r+1]},
j(a,b,c){var s,r,q=this,p=A.u(q)
p.c.a(b)
p.y[1].a(c)
if(typeof b=="string"&&b!=="__proto__"){s=q.b
q.jw(s==null?q.b=A.xS():s,b,c)}else if(typeof b=="number"&&(b&1073741823)===b){r=q.c
q.jw(r==null?q.c=A.xS():r,b,c)}else q.ko(b,c)},
ko(a,b){var s,r,q,p,o=this,n=A.u(o)
n.c.a(a)
n.y[1].a(b)
s=o.d
if(s==null)s=o.d=A.xS()
r=o.ck(a)
q=s[r]
if(q==null){A.xT(s,r,[a,b]);++o.a
o.e=null}else{p=o.c_(q,a)
if(p>=0)q[p+1]=b
else{q.push(a,b);++o.a
o.e=null}}},
aQ(a,b){var s,r,q=this,p=A.u(q)
p.c.a(a)
p.i("2()").a(b)
if(q.p(a)){s=q.h(0,a)
return s==null?p.y[1].a(s):s}r=b.$0()
q.j(0,a,r)
return r},
Z(a,b){var s=this
if(typeof b=="string"&&b!=="__proto__")return s.jx(s.b,b)
else if(typeof b=="number"&&(b&1073741823)===b)return s.jx(s.c,b)
else return s.kg(b)},
kg(a){var s,r,q,p,o=this,n=o.d
if(n==null)return null
s=o.ck(a)
r=n[s]
q=o.c_(r,a)
if(q<0)return null;--o.a
o.e=null
p=r.splice(q,2)[1]
if(0===r.length)delete n[s]
return p},
O(a,b){var s,r,q,p,o,n,m=this,l=A.u(m)
l.i("~(1,2)").a(b)
s=m.jy()
for(r=s.length,q=l.c,l=l.y[1],p=0;p<r;++p){o=s[p]
q.a(o)
n=m.h(0,o)
b.$2(o,n==null?l.a(n):n)
if(s!==m.e)throw A.i(A.aD(m))}},
jy(){var s,r,q,p,o,n,m,l,k,j,i=this,h=i.e
if(h!=null)return h
h=A.eB(i.a,null,!1,t.z)
s=i.b
r=0
if(s!=null){q=Object.getOwnPropertyNames(s)
p=q.length
for(o=0;o<p;++o){h[r]=q[o];++r}}n=i.c
if(n!=null){q=Object.getOwnPropertyNames(n)
p=q.length
for(o=0;o<p;++o){h[r]=+q[o];++r}}m=i.d
if(m!=null){q=Object.getOwnPropertyNames(m)
p=q.length
for(o=0;o<p;++o){l=m[q[o]]
k=l.length
for(j=0;j<k;j+=2){h[r]=l[j];++r}}}return i.e=h},
jw(a,b,c){var s=A.u(this)
s.c.a(b)
s.y[1].a(c)
if(a[b]==null){++this.a
this.e=null}A.xT(a,b,c)},
jx(a,b){var s
if(a!=null&&a[b]!=null){s=A.u(this).y[1].a(A.xR(a,b))
delete a[b];--this.a
this.e=null
return s}else return null},
ck(a){return J.b4(a)&1073741823},
jR(a,b){return a[this.ck(b)]},
c_(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;r+=2)if(J.A(a[r],b))return r
return-1}}
A.tW.prototype={
$1(a){var s=this.a,r=A.u(s)
s=s.h(0,r.c.a(a))
return s==null?r.y[1].a(s):s},
$S(){return A.u(this.a).i("2(1)")}}
A.eV.prototype={
ck(a){return A.ls(a)&1073741823},
c_(a,b){var s,r,q
if(a==null)return-1
s=a.length
for(r=0;r<s;r+=2){q=a[r]
if(q==null?b==null:q===b)return r}return-1}}
A.ii.prototype={
h(a,b){if(!A.ac(this.w.$1(b)))return null
return this.n5(b)},
j(a,b,c){var s=this.$ti
this.n7(s.c.a(b),s.y[1].a(c))},
p(a){if(!A.ac(this.w.$1(a)))return!1
return this.n4(a)},
Z(a,b){if(!A.ac(this.w.$1(b)))return null
return this.n6(b)},
ck(a){return this.r.$1(this.$ti.c.a(a))&1073741823},
c_(a,b){var s,r,q,p
if(a==null)return-1
s=a.length
for(r=this.$ti.c,q=this.f,p=0;p<s;p+=2)if(A.ac(q.$2(a[p],r.a(b))))return p
return-1}}
A.tG.prototype={
$1(a){return this.a.b(a)},
$S:9}
A.eT.prototype={
gm(a){return this.a.a},
ga6(a){return this.a.a===0},
gal(a){return this.a.a!==0},
gJ(a){var s=this.a
return new A.il(s,s.jy(),this.$ti.i("il<1>"))},
v(a,b){return this.a.p(b)}}
A.il.prototype={
gq(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s=this,r=s.b,q=s.c,p=s.a
if(r!==p.e)throw A.i(A.aD(p))
else if(q>=r.length){s.scj(null)
return!1}else{s.scj(r[q])
s.c=q+1
return!0}},
scj(a){this.d=this.$ti.i("1?").a(a)},
$iar:1}
A.dw.prototype={
gJ(a){var s=this,r=new A.eY(s,s.r,A.u(s).i("eY<1>"))
r.c=s.e
return r},
gm(a){return this.a},
ga6(a){return this.a===0},
gal(a){return this.a!==0},
v(a,b){var s,r
if(typeof b=="string"&&b!=="__proto__"){s=this.b
if(s==null)return!1
return t.Af.a(s[b])!=null}else if(typeof b=="number"&&(b&1073741823)===b){r=this.c
if(r==null)return!1
return t.Af.a(r[b])!=null}else return this.o2(b)},
o2(a){var s=this.d
if(s==null)return!1
return this.c_(s[this.ck(a)],a)>=0},
gF(a){var s=this.e
if(s==null)throw A.i(A.aL("No elements"))
return A.u(this).c.a(s.a)},
k(a,b){var s,r,q=this
A.u(q).c.a(b)
if(typeof b=="string"&&b!=="__proto__"){s=q.b
return q.jv(s==null?q.b=A.xV():s,b)}else if(typeof b=="number"&&(b&1073741823)===b){r=q.c
return q.jv(r==null?q.c=A.xV():r,b)}else return q.nC(b)},
nC(a){var s,r,q,p=this
A.u(p).c.a(a)
s=p.d
if(s==null)s=p.d=A.xV()
r=p.ck(a)
q=s[r]
if(q==null)s[r]=[p.fW(a)]
else{if(p.c_(q,a)>=0)return!1
q.push(p.fW(a))}return!0},
jv(a,b){A.u(this).c.a(b)
if(t.Af.a(a[b])!=null)return!1
a[b]=this.fW(b)
return!0},
fW(a){var s=this,r=new A.l8(A.u(s).c.a(a))
if(s.e==null)s.e=s.f=r
else s.f=s.f.b=r;++s.a
s.r=s.r+1&1073741823
return r},
ck(a){return J.b4(a)&1073741823},
c_(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.A(a[r].a,b))return r
return-1},
$izy:1}
A.l8.prototype={}
A.eY.prototype={
gq(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s=this,r=s.c,q=s.a
if(s.b!==q.r)throw A.i(A.aD(q))
else if(r==null){s.scj(null)
return!1}else{s.scj(s.$ti.i("1?").a(r.a))
s.c=r.b
return!0}},
scj(a){this.d=this.$ti.i("1?").a(a)},
$iar:1}
A.oe.prototype={
$2(a,b){this.a.j(0,this.b.a(a),this.c.a(b))},
$S:16}
A.R.prototype={
gJ(a){return new A.be(a,this.gm(a),A.b3(a).i("be<R.E>"))},
ar(a,b){return this.h(a,b)},
O(a,b){var s,r
A.b3(a).i("~(R.E)").a(b)
s=this.gm(a)
for(r=0;r<s;++r){b.$1(this.h(a,r))
if(s!==this.gm(a))throw A.i(A.aD(a))}},
ga6(a){return this.gm(a)===0},
gal(a){return!this.ga6(a)},
gF(a){if(this.gm(a)===0)throw A.i(A.cP())
return this.h(a,0)},
v(a,b){var s,r=this.gm(a)
for(s=0;s<r;++s){if(J.A(this.h(a,s),b))return!0
if(r!==this.gm(a))throw A.i(A.aD(a))}return!1},
cR(a,b){var s,r
A.b3(a).i("x(R.E)").a(b)
s=this.gm(a)
for(r=0;r<s;++r){if(!A.ac(b.$1(this.h(a,r))))return!1
if(s!==this.gm(a))throw A.i(A.aD(a))}return!0},
c0(a,b){var s,r
A.b3(a).i("x(R.E)").a(b)
s=this.gm(a)
for(r=0;r<s;++r){if(A.ac(b.$1(this.h(a,r))))return!0
if(s!==this.gm(a))throw A.i(A.aD(a))}return!1},
iq(a,b){return new A.ae(a,b.i("ae<0>"))},
bU(a,b,c){var s=A.b3(a)
return new A.a1(a,s.U(c).i("1(R.E)").a(b),s.i("@<R.E>").U(c).i("a1<1,2>"))},
ag(a,b,c,d){var s,r,q
d.a(b)
A.b3(a).U(d).i("1(1,R.E)").a(c)
s=this.gm(a)
for(r=b,q=0;q<s;++q){r=c.$2(r,this.h(a,q))
if(s!==this.gm(a))throw A.i(A.aD(a))}return r},
bL(a,b){return A.dg(a,b,null,A.b3(a).i("R.E"))},
lE(a,b){return A.dg(a,0,A.eg(b,"count",t.S),A.b3(a).i("R.E"))},
b9(a,b){var s,r,q,p,o=this
if(o.ga6(a)){s=J.nT(0,A.b3(a).i("R.E"))
return s}r=o.h(a,0)
q=A.eB(o.gm(a),r,!0,A.b3(a).i("R.E"))
for(p=1;p<o.gm(a);++p)B.a.j(q,p,o.h(a,p))
return q},
cZ(a){return this.b9(a,!0)},
k(a,b){var s
A.b3(a).i("R.E").a(b)
s=this.gm(a)
this.sm(a,s+1)
this.j(a,s,b)},
Z(a,b){var s
for(s=0;s<this.gm(a);++s)if(J.A(this.h(a,s),b)){this.nU(a,s,s+1)
return!0}return!1},
nU(a,b,c){var s,r=this,q=r.gm(a),p=c-b
for(s=c;s<q;++s)r.j(a,s-p,r.h(a,s))
r.sm(a,q-p)},
rC(a,b,c,d){var s
A.b3(a).i("R.E?").a(d)
A.b6(b,c,this.gm(a))
for(s=b;s<c;++s)this.j(a,s,d)},
cg(a,b,c,d,e){var s,r,q,p,o=A.b3(a)
o.i("o<R.E>").a(d)
A.b6(b,c,this.gm(a))
s=c-b
if(s===0)return
A.bE(e,"skipCount")
if(o.i("t<R.E>").b(d)){r=e
q=d}else{q=J.lB(d,e).b9(0,!1)
r=0}o=J.aO(q)
if(r+s>o.gm(q))throw A.i(A.zs())
if(r<b)for(p=s-1;p>=0;--p)this.j(a,b+p,o.h(q,r+p))
else for(p=0;p<s;++p)this.j(a,b+p,o.h(q,r+p))},
B(a){return A.xd(a,"[","]")},
$iM:1,
$io:1,
$it:1}
A.P.prototype={
c2(a,b,c){var s=A.u(this)
return A.zD(this,s.i("P.K"),s.i("P.V"),b,c)},
O(a,b){var s,r,q,p=A.u(this)
p.i("~(P.K,P.V)").a(b)
for(s=J.U(this.ga7()),p=p.i("P.V");s.l();){r=s.gq()
q=this.h(0,r)
b.$2(r,q==null?p.a(q):q)}},
aQ(a,b){var s,r=this,q=A.u(r)
q.i("P.K").a(a)
q.i("P.V()").a(b)
if(r.p(a)){s=r.h(0,a)
return s==null?q.i("P.V").a(s):s}q=b.$0()
r.j(0,a,q)
return q},
gao(){return J.el(this.ga7(),new A.ol(this),A.u(this).i("F<P.K,P.V>"))},
bo(a,b,c,d){var s,r,q,p,o,n=A.u(this)
n.U(c).U(d).i("F<1,2>(P.K,P.V)").a(b)
s=A.b(c,d)
for(r=J.U(this.ga7()),n=n.i("P.V");r.l();){q=r.gq()
p=this.h(0,q)
o=b.$2(q,p==null?n.a(p):p)
s.j(0,o.a,o.b)}return s},
cb(a,b){var s,r,q,p,o,n=this,m=A.u(n)
m.i("x(P.K,P.V)").a(b)
s=A.a([],m.i("w<P.K>"))
for(r=J.U(n.ga7()),m=m.i("P.V");r.l();){q=r.gq()
p=n.h(0,q)
if(A.ac(b.$2(q,p==null?m.a(p):p)))B.a.k(s,q)}for(m=s.length,o=0;o<s.length;s.length===m||(0,A.k)(s),++o)n.Z(0,s[o])},
p(a){return J.ly(this.ga7(),a)},
gm(a){return J.b1(this.ga7())},
ga6(a){return J.lA(this.ga7())},
gal(a){return J.yR(this.ga7())},
gak(){return new A.im(this,A.u(this).i("im<P.K,P.V>"))},
B(a){return A.xn(this)},
$iB:1}
A.ol.prototype={
$1(a){var s=this.a,r=A.u(s)
r.i("P.K").a(a)
s=s.h(0,a)
if(s==null)s=r.i("P.V").a(s)
return new A.F(a,s,r.i("F<P.K,P.V>"))},
$S(){return A.u(this.a).i("F<P.K,P.V>(P.K)")}}
A.om.prototype={
$2(a,b){var s,r=this.a
if(!r.a)this.b.a+=", "
r.a=!1
r=this.b
s=A.p(a)
s=r.a+=s
r.a=s+": "
s=A.p(b)
r.a+=s},
$S:55}
A.im.prototype={
gm(a){var s=this.a
return s.gm(s)},
ga6(a){var s=this.a
return s.ga6(s)},
gal(a){var s=this.a
return s.gal(s)},
gF(a){var s=this.a
s=s.h(0,J.ek(s.ga7()))
return s==null?this.$ti.y[1].a(s):s},
gJ(a){var s=this.a
return new A.io(J.U(s.ga7()),s,this.$ti.i("io<1,2>"))}}
A.io.prototype={
l(){var s=this,r=s.a
if(r.l()){s.scj(s.b.h(0,r.gq()))
return!0}s.scj(null)
return!1},
gq(){var s=this.c
return s==null?this.$ti.y[1].a(s):s},
scj(a){this.c=this.$ti.i("2?").a(a)},
$iar:1}
A.iF.prototype={
j(a,b,c){var s=A.u(this)
s.c.a(b)
s.y[1].a(c)
throw A.i(A.aV("Cannot modify unmodifiable map"))},
cb(a,b){A.u(this).i("x(1,2)").a(b)
throw A.i(A.aV("Cannot modify unmodifiable map"))},
aQ(a,b){var s=A.u(this)
s.c.a(a)
s.i("2()").a(b)
throw A.i(A.aV("Cannot modify unmodifiable map"))}}
A.fs.prototype={
c2(a,b,c){return this.a.c2(0,b,c)},
h(a,b){return this.a.h(0,b)},
j(a,b,c){var s=A.u(this)
this.a.j(0,s.c.a(b),s.y[1].a(c))},
aQ(a,b){var s=A.u(this)
return this.a.aQ(s.c.a(a),s.i("2()").a(b))},
p(a){return this.a.p(a)},
O(a,b){this.a.O(0,A.u(this).i("~(1,2)").a(b))},
ga6(a){var s=this.a
return s.ga6(s)},
gal(a){var s=this.a
return s.gal(s)},
gm(a){var s=this.a
return s.gm(s)},
ga7(){return this.a.ga7()},
B(a){return this.a.B(0)},
gak(){return this.a.gak()},
gao(){return this.a.gao()},
bo(a,b,c,d){return this.a.bo(0,A.u(this).U(c).U(d).i("F<1,2>(3,4)").a(b),c,d)},
cb(a,b){this.a.cb(0,A.u(this).i("x(1,2)").a(b))},
$iB:1}
A.eL.prototype={
c2(a,b,c){return new A.eL(this.a.c2(0,b,c),b.i("@<0>").U(c).i("eL<1,2>"))}}
A.cg.prototype={
ga6(a){return this.gm(this)===0},
gal(a){return this.gm(this)!==0},
H(a,b){var s
for(s=J.U(A.u(this).i("o<1>").a(b));s.l();)this.k(0,s.gq())},
b9(a,b){return A.N(this,!0,A.u(this).c)},
cZ(a){return this.b9(0,!0)},
bU(a,b,c){var s=A.u(this)
return new A.er(this,s.U(c).i("1(2)").a(b),s.i("@<1>").U(c).i("er<1,2>"))},
B(a){return A.xd(this,"{","}")},
cR(a,b){var s
A.u(this).i("x(1)").a(b)
for(s=this.gJ(this);s.l();)if(!A.ac(b.$1(s.gq())))return!1
return!0},
bL(a,b){return A.zR(this,b,A.u(this).c)},
gF(a){var s=this.gJ(this)
if(!s.l())throw A.i(A.cP())
return s.gq()},
ar(a,b){var s,r
A.bE(b,"index")
s=this.gJ(this)
for(r=b;s.l();){if(r===0)return s.gq();--r}throw A.i(A.nP(b,b-r,this,"index"))},
$iM:1,
$io:1,
$icf:1}
A.ix.prototype={}
A.h9.prototype={}
A.l6.prototype={
h(a,b){var s,r=this.b
if(r==null)return this.c.h(0,b)
else if(typeof b!="string")return null
else{s=r[b]
return typeof s=="undefined"?this.q1(b):s}},
gm(a){return this.b==null?this.c.a:this.d8().length},
ga6(a){return this.gm(0)===0},
gal(a){return this.gm(0)>0},
ga7(){if(this.b==null){var s=this.c
return new A.as(s,A.u(s).i("as<1>"))}return new A.l7(this)},
gak(){var s=this
if(s.b==null)return s.c.gak()
return A.ft(s.d8(),new A.tZ(s),t.N,t.z)},
j(a,b,c){var s,r,q=this
A.h(b)
if(q.b==null)q.c.j(0,b,c)
else if(q.p(b)){s=q.b
s[b]=c
r=q.a
if(r==null?s!=null:r!==s)r[b]=null}else q.kD().j(0,b,c)},
p(a){if(this.b==null)return this.c.p(a)
if(typeof a!="string")return!1
return Object.prototype.hasOwnProperty.call(this.a,a)},
aQ(a,b){var s
t.pF.a(b)
if(this.p(a))return this.h(0,a)
s=b.$0()
this.j(0,a,s)
return s},
Z(a,b){if(this.b!=null&&!this.p(b))return null
return this.kD().Z(0,b)},
O(a,b){var s,r,q,p,o=this
t.iJ.a(b)
if(o.b==null)return o.c.O(0,b)
s=o.d8()
for(r=0;r<s.length;++r){q=s[r]
p=o.b[q]
if(typeof p=="undefined"){p=A.uw(o.a[q])
o.b[q]=p}b.$2(q,p)
if(s!==o.c)throw A.i(A.aD(o))}},
d8(){var s=t.jS.a(this.c)
if(s==null)s=this.c=A.a(Object.keys(this.a),t.s)
return s},
kD(){var s,r,q,p,o,n=this
if(n.b==null)return n.c
s=A.b(t.N,t.z)
r=n.d8()
for(q=0;p=r.length,q<p;++q){o=r[q]
s.j(0,o,n.h(0,o))}if(p===0)B.a.k(r,"")
else B.a.M(r)
n.a=n.b=null
return n.c=s},
q1(a){var s
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
s=A.uw(this.a[a])
return this.b[a]=s}}
A.tZ.prototype={
$1(a){return this.a.h(0,A.h(a))},
$S:45}
A.l7.prototype={
gm(a){return this.a.gm(0)},
ar(a,b){var s=this.a
if(s.b==null)s=s.ga7().ar(0,b)
else{s=s.d8()
if(!(b>=0&&b<s.length))return A.d(s,b)
s=s[b]}return s},
gJ(a){var s=this.a
if(s.b==null){s=s.ga7()
s=s.gJ(s)}else{s=s.d8()
s=new J.d2(s,s.length,A.K(s).i("d2<1>"))}return s},
v(a,b){return this.a.p(b)}}
A.um.prototype={
$0(){var s,r
try{s=new TextDecoder("utf-8",{fatal:true})
return s}catch(r){}return null},
$S:60}
A.ul.prototype={
$0(){var s,r
try{s=new TextDecoder("utf-8",{fatal:false})
return s}catch(r){}return null},
$S:60}
A.ui.prototype={
cu(a){var s,r,q,p
t.L.a(a)
s=a.length
r=A.b6(0,null,s)
for(q=0;q<r;++q){if(!(q<s))return A.d(a,q)
p=a[q]
if((p&4294967040)!==0){if(!this.a)throw A.i(A.bc("Invalid value in input: "+p,null,null))
return this.o8(a,0,r)}}return A.i1(a,0,r)},
o8(a,b,c){var s,r,q,p
t.L.a(a)
for(s=a.length,r=b,q="";r<c;++r){if(!(r<s))return A.d(a,r)
p=a[r]
q+=A.W((p&4294967040)!==0?65533:p)}return q.charCodeAt(0)==0?q:q}}
A.hr.prototype={
ghH(){return B.bV},
tU(a3,a4,a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=u.z,a1="Invalid base64 encoding length ",a2=a3.length
a5=A.b6(a4,a5,a2)
s=$.Co()
for(r=s.length,q=a4,p=q,o=null,n=-1,m=-1,l=0;q<a5;q=k){k=q+1
if(!(q<a2))return A.d(a3,q)
j=a3.charCodeAt(q)
if(j===37){i=k+2
if(i<=a5){if(!(k<a2))return A.d(a3,k)
h=A.wa(a3.charCodeAt(k))
g=k+1
if(!(g<a2))return A.d(a3,g)
f=A.wa(a3.charCodeAt(g))
e=h*16+f-(f&256)
if(e===37)e=-1
k=i}else e=-1}else e=j
if(0<=e&&e<=127){if(!(e>=0&&e<r))return A.d(s,e)
d=s[e]
if(d>=0){if(!(d<64))return A.d(a0,d)
e=a0.charCodeAt(d)
if(e===j)continue
j=e}else{if(d===-1){if(n<0){g=o==null?null:o.a.length
if(g==null)g=0
n=g+(q-p)
m=q}++l
if(j===61)continue}j=e}if(d!==-2){if(o==null){o=new A.a_("")
g=o}else g=o
g.a+=B.b.t(a3,p,q)
c=A.W(j)
g.a+=c
p=k
continue}}throw A.i(A.bc("Invalid base64 data",a3,q))}if(o!=null){a2=B.b.t(a3,p,a5)
a2=o.a+=a2
r=a2.length
if(n>=0)A.yV(a3,m,a5,n,l,r)
else{b=B.d.b4(r-1,4)+1
if(b===1)throw A.i(A.bc(a1,a3,a5))
for(;b<4;){a2+="="
o.a=a2;++b}}a2=o.a
return B.b.bI(a3,a4,a5,a2.charCodeAt(0)==0?a2:a2)}a=a5-a4
if(n>=0)A.yV(a3,m,a5,n,l,a)
else{b=B.d.b4(a,4)
if(b===1)throw A.i(A.bc(a1,a3,a5))
if(b>1)a3=B.b.bI(a3,a5,a5,b===2?"==":"=")}return a3}}
A.lE.prototype={
cu(a){var s
t.L.a(a)
s=a.length
if(s===0)return""
s=new A.tz(u.z).rw(a,0,s,!0)
s.toString
return A.i1(s,0,null)}}
A.tz.prototype={
rw(a,b,c,d){var s,r,q,p,o
t.L.a(a)
s=this.a
r=(s&3)+(c-b)
q=B.d.bC(r,3)
p=q*4
if(r-q*3>0)p+=4
o=new Uint8Array(p)
this.a=A.F0(this.b,a,b,c,!0,o,0,s)
if(p>0)return o
return null}}
A.bN.prototype={}
A.jq.prototype={}
A.jx.prototype={}
A.nJ.prototype={
B(a){return"unknown"}}
A.nI.prototype={
cu(a){var s=this.o3(a,0,a.length)
return s==null?a:s},
o3(a,b,c){var s,r,q,p
for(s=a.length,r=b,q=null;r<c;++r){if(!(r<s))return A.d(a,r)
switch(a[r]){case"&":p="&amp;"
break
case'"':p="&quot;"
break
case"'":p="&#39;"
break
case"<":p="&lt;"
break
case">":p="&gt;"
break
case"/":p="&#47;"
break
default:p=null}if(p!=null){if(q==null)q=new A.a_("")
if(r>b)q.a+=B.b.t(a,b,r)
q.a+=p
b=r+1}}if(q==null)return null
if(c>b){s=B.b.t(a,b,c)
q.a+=s}s=q.a
return s.charCodeAt(0)==0?s:s}}
A.hP.prototype={
B(a){var s=A.dH(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+s}}
A.jX.prototype={
B(a){return"Cyclic error in JSON stringify"}}
A.jW.prototype={
hx(a,b){var s=A.Hc(a,this.grk().a)
return s},
cQ(a,b){var s=A.F7(a,this.ghH().b,null)
return s},
ghH(){return B.cp},
grk(){return B.co}}
A.nZ.prototype={}
A.nY.prototype={}
A.u0.prototype={
lX(a){var s,r,q,p,o,n,m=a.length
for(s=this.c,r=0,q=0;q<m;++q){p=a.charCodeAt(q)
if(p>92){if(p>=55296){o=p&64512
if(o===55296){n=q+1
n=!(n<m&&(a.charCodeAt(n)&64512)===56320)}else n=!1
if(!n)if(o===56320){o=q-1
o=!(o>=0&&(a.charCodeAt(o)&64512)===55296)}else o=!1
else o=!0
if(o){if(q>r)s.a+=B.b.t(a,r,q)
r=q+1
o=A.W(92)
s.a+=o
o=A.W(117)
s.a+=o
o=A.W(100)
s.a+=o
o=p>>>8&15
o=A.W(o<10?48+o:87+o)
s.a+=o
o=p>>>4&15
o=A.W(o<10?48+o:87+o)
s.a+=o
o=p&15
o=A.W(o<10?48+o:87+o)
s.a+=o}}continue}if(p<32){if(q>r)s.a+=B.b.t(a,r,q)
r=q+1
o=A.W(92)
s.a+=o
switch(p){case 8:o=A.W(98)
s.a+=o
break
case 9:o=A.W(116)
s.a+=o
break
case 10:o=A.W(110)
s.a+=o
break
case 12:o=A.W(102)
s.a+=o
break
case 13:o=A.W(114)
s.a+=o
break
default:o=A.W(117)
s.a+=o
o=A.W(48)
s.a+=o
o=A.W(48)
s.a+=o
o=p>>>4&15
o=A.W(o<10?48+o:87+o)
s.a+=o
o=p&15
o=A.W(o<10?48+o:87+o)
s.a+=o
break}}else if(p===34||p===92){if(q>r)s.a+=B.b.t(a,r,q)
r=q+1
o=A.W(92)
s.a+=o
o=A.W(p)
s.a+=o}}if(r===0)s.a+=a
else if(r<m)s.a+=B.b.t(a,r,m)},
fT(a){var s,r,q,p
for(s=this.a,r=s.length,q=0;q<r;++q){p=s[q]
if(a==null?p==null:a===p)throw A.i(new A.jX(a,null))}B.a.k(s,a)},
fp(a){var s,r,q,p,o=this
if(o.lW(a))return
o.fT(a)
try{s=o.b.$1(a)
if(!o.lW(s)){q=A.zw(a,null,o.gkd())
throw A.i(q)}q=o.a
if(0>=q.length)return A.d(q,-1)
q.pop()}catch(p){r=A.bk(p)
q=A.zw(a,r,o.gkd())
throw A.i(q)}},
lW(a){var s,r,q,p=this
if(typeof a=="number"){if(!isFinite(a))return!1
s=p.c
r=B.f.B(a)
s.a+=r
return!0}else if(a===!0){p.c.a+="true"
return!0}else if(a===!1){p.c.a+="false"
return!0}else if(a==null){p.c.a+="null"
return!0}else if(typeof a=="string"){s=p.c
s.a+='"'
p.lX(a)
s.a+='"'
return!0}else if(t.j.b(a)){p.fT(a)
p.uG(a)
s=p.a
if(0>=s.length)return A.d(s,-1)
s.pop()
return!0}else if(t.G.b(a)){p.fT(a)
q=p.uH(a)
s=p.a
if(0>=s.length)return A.d(s,-1)
s.pop()
return q}else return!1},
uG(a){var s,r,q=this.c
q.a+="["
s=J.aO(a)
if(s.gal(a)){this.fp(s.h(a,0))
for(r=1;r<s.gm(a);++r){q.a+=","
this.fp(s.h(a,r))}}q.a+="]"},
uH(a){var s,r,q,p,o,n,m=this,l={}
if(a.ga6(a)){m.c.a+="{}"
return!0}s=a.gm(a)*2
r=A.eB(s,null,!1,t.dy)
q=l.a=0
l.b=!0
a.O(0,new A.u1(l,r))
if(!l.b)return!1
p=m.c
p.a+="{"
for(o='"';q<s;q+=2,o=',"'){p.a+=o
m.lX(A.h(r[q]))
p.a+='":'
n=q+1
if(!(n<s))return A.d(r,n)
m.fp(r[n])}p.a+="}"
return!0}}
A.u1.prototype={
$2(a,b){var s,r
if(typeof a!="string")this.a.b=!1
s=this.b
r=this.a
B.a.j(s,r.a++,a)
B.a.j(s,r.a++,b)},
$S:55}
A.u_.prototype={
gkd(){var s=this.c.a
return s.charCodeAt(0)==0?s:s}}
A.jZ.prototype={
dY(a){var s
t.L.a(a)
s=B.cE.cu(a)
return s}}
A.o9.prototype={}
A.kH.prototype={
dY(a){t.L.a(a)
return B.ne.cu(a)}}
A.td.prototype={
cu(a){return new A.uk(this.a).o7(t.L.a(a),0,null,!0)}}
A.uk.prototype={
o7(a,b,c,d){var s,r,q,p,o,n,m,l=this
t.L.a(a)
s=A.b6(b,c,a.length)
if(b===s)return""
if(a instanceof Uint8Array){r=a
q=r
p=0}else{q=A.FI(a,b,s)
s-=b
p=b
b=0}if(s-b>=15){o=l.a
n=A.FH(o,q,b,s)
if(n!=null){if(!o)return n
if(n.indexOf("\ufffd")<0)return n}}n=l.h0(q,b,s,!0)
o=l.b
if((o&1)!==0){m=A.FJ(o)
l.b=0
throw A.i(A.bc(m,a,p+l.c))}return n},
h0(a,b,c,d){var s,r,q=this
if(c-b>1000){s=B.d.bC(b+c,2)
r=q.h0(a,b,s,!1)
if((q.b&1)!==0)return r
return r+q.h0(a,s,c,d)}return q.rj(a,b,c,d)},
rj(a,b,a0,a1){var s,r,q,p,o,n,m,l,k=this,j="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHHHHHHHHIHHHJEEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBKCCCCCCCCCCCCDCLONNNMEEEEEEEEEEE",i=" \x000:XECCCCCN:lDb \x000:XECCCCCNvlDb \x000:XECCCCCN:lDb AAAAA\x00\x00\x00\x00\x00AAAAA00000AAAAA:::::AAAAAGG000AAAAA00KKKAAAAAG::::AAAAA:IIIIAAAAA000\x800AAAAA\x00\x00\x00\x00 AAAAA",h=65533,g=k.b,f=k.c,e=new A.a_(""),d=b+1,c=a.length
if(!(b>=0&&b<c))return A.d(a,b)
s=a[b]
$label0$0:for(r=k.a;!0;){for(;!0;d=o){if(!(s>=0&&s<256))return A.d(j,s)
q=j.charCodeAt(s)&31
f=g<=32?s&61694>>>q:(s&63|f<<6)>>>0
p=g+q
if(!(p>=0&&p<144))return A.d(i,p)
g=i.charCodeAt(p)
if(g===0){p=A.W(f)
e.a+=p
if(d===a0)break $label0$0
break}else if((g&1)!==0){if(r)switch(g){case 69:case 67:p=A.W(h)
e.a+=p
break
case 65:p=A.W(h)
e.a+=p;--d
break
default:p=A.W(h)
p=e.a+=p
e.a=p+A.W(h)
break}else{k.b=g
k.c=d-1
return""}g=0}if(d===a0)break $label0$0
o=d+1
if(!(d>=0&&d<c))return A.d(a,d)
s=a[d]}o=d+1
if(!(d>=0&&d<c))return A.d(a,d)
s=a[d]
if(s<128){while(!0){if(!(o<a0)){n=a0
break}m=o+1
if(!(o>=0&&o<c))return A.d(a,o)
s=a[o]
if(s>=128){n=m-1
o=m
break}o=m}if(n-d<20)for(l=d;l<n;++l){if(!(l<c))return A.d(a,l)
p=A.W(a[l])
e.a+=p}else{p=A.i1(a,d,n)
e.a+=p}if(n===a0)break $label0$0
d=o}else d=o}if(a1&&g>32)if(r){c=A.W(h)
e.a+=c}else{k.b=77
k.c=a0
return""}k.b=g
k.c=f
c=e.a
return c.charCodeAt(0)==0?c:c}}
A.on.prototype={
$2(a,b){var s,r,q
t.of.a(a)
s=this.b
r=this.a
q=s.a+=r.a
q+=a.a
s.a=q
s.a=q+": "
q=A.dH(b)
s.a+=q
r.a=", "},
$S:128}
A.cN.prototype={
jm(a){var s=1000,r=B.d.b4(a,s),q=B.d.bC(a-r,s),p=this.b+r,o=B.d.b4(p,s),n=this.c
return new A.cN(A.Da(this.a+B.d.bC(p-o,s)+q,o,n),o,n)},
n(a,b){if(b==null)return!1
return b instanceof A.cN&&this.a===b.a&&this.b===b.b&&this.c===b.c},
ga3(a){return A.dU(this.a,this.b,B.m,B.m)},
bi(a,b){var s
t.zG.a(b)
s=B.d.bi(this.a,b.a)
if(s!==0)return s
return B.d.bi(this.b,b.b)},
B(a){var s=this,r=A.D9(A.E2(s)),q=A.jr(A.E0(s)),p=A.jr(A.DX(s)),o=A.jr(A.DY(s)),n=A.jr(A.E_(s)),m=A.jr(A.E1(s)),l=A.z6(A.DZ(s)),k=s.b,j=k===0?"":A.z6(k)
k=r+"-"+q
if(s.c)return k+"-"+p+" "+o+":"+n+":"+m+"."+l+j+"Z"
else return k+"-"+p+" "+o+":"+n+":"+m+"."+l+j},
$ibO:1}
A.cr.prototype={
n(a,b){if(b==null)return!1
return b instanceof A.cr&&this.a===b.a},
ga3(a){return B.d.ga3(this.a)},
bi(a,b){return B.d.bi(this.a,t.ya.a(b).a)},
B(a){var s,r,q,p,o,n=this.a,m=B.d.bC(n,36e8),l=n%36e8
if(n<0){m=0-m
n=0-l
s="-"}else{n=l
s=""}r=B.d.bC(n,6e7)
n%=6e7
q=r<10?"0":""
p=B.d.bC(n,1e6)
o=p<10?"0":""
return s+m+":"+q+r+":"+o+p+"."+B.b.ai(B.d.B(n%1e6),6,"0")},
$ibO:1}
A.tI.prototype={
B(a){return this.bA()},
gc4(){return this.a}}
A.aq.prototype={
gdK(){return A.DW(this)}}
A.hq.prototype={
B(a){var s=this.a
if(s!=null)return"Assertion failed: "+A.dH(s)
return"Assertion failed"}}
A.dl.prototype={}
A.cp.prototype={
gh2(){return"Invalid argument"+(!this.a?"(s)":"")},
gh1(){return""},
B(a){var s=this,r=s.c,q=r==null?"":" ("+r+")",p=s.d,o=p==null?"":": "+A.p(p),n=s.gh2()+q+o
if(!s.a)return n
return n+s.gh1()+": "+A.dH(s.ghY())},
ghY(){return this.b}}
A.fv.prototype={
ghY(){return A.y0(this.b)},
gh2(){return"RangeError"},
gh1(){var s,r=this.e,q=this.f
if(r==null)s=q!=null?": Not less than or equal to "+A.p(q):""
else if(q==null)s=": Not greater than or equal to "+A.p(r)
else if(q>r)s=": Not in inclusive range "+A.p(r)+".."+A.p(q)
else s=q<r?": Valid value range is empty":": Only valid value is "+A.p(r)
return s}}
A.hJ.prototype={
ghY(){return A.v(this.b)},
gh2(){return"RangeError"},
gh1(){if(A.v(this.b)<0)return": index must not be negative"
var s=this.f
if(s===0)return": no indices are valid"
return": index should be less than "+s},
gm(a){return this.f}}
A.dc.prototype={
B(a){var s,r,q,p,o,n,m,l,k=this,j={},i=new A.a_("")
j.a=""
s=k.c
for(r=s.length,q=0,p="",o="";q<r;++q,o=", "){n=s[q]
i.a=p+o
p=A.dH(n)
p=i.a+=p
j.a=", "}k.d.O(0,new A.on(j,i))
m=A.dH(k.a)
l=i.B(0)
return"NoSuchMethodError: method not found: '"+k.b.a+"'\nReceiver: "+m+"\nArguments: ["+l+"]"}}
A.i5.prototype={
B(a){return"Unsupported operation: "+this.a}}
A.kE.prototype={
B(a){return"UnimplementedError: "+this.a}}
A.fC.prototype={
B(a){return"Bad state: "+this.a}}
A.jp.prototype={
B(a){var s=this.a
if(s==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.dH(s)+"."}}
A.kb.prototype={
B(a){return"Out of Memory"},
gdK(){return null},
$iaq:1}
A.i_.prototype={
B(a){return"Stack Overflow"},
gdK(){return null},
$iaq:1}
A.tJ.prototype={
B(a){return"Exception: "+this.a}}
A.c9.prototype={
B(a){var s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=""!==h?"FormatException: "+h:"FormatException",f=this.c,e=this.b
if(typeof e=="string"){if(f!=null)s=f<0||f>e.length
else s=!1
if(s)f=null
if(f==null){if(e.length>78)e=B.b.t(e,0,75)+"..."
return g+"\n"+e}for(r=e.length,q=1,p=0,o=!1,n=0;n<f;++n){if(!(n<r))return A.d(e,n)
m=e.charCodeAt(n)
if(m===10){if(p!==n||!o)++q
p=n+1
o=!1}else if(m===13){++q
p=n+1
o=!0}}g=q>1?g+(" (at line "+q+", character "+(f-p+1)+")\n"):g+(" (at character "+(f+1)+")\n")
for(n=f;n<r;++n){if(!(n>=0))return A.d(e,n)
m=e.charCodeAt(n)
if(m===10||m===13){r=n
break}}l=""
if(r-p>78){k="..."
if(f-p<75){j=p+75
i=p}else{if(r-f<75){i=r-75
j=r
k=""}else{i=f-36
j=f+36}l="..."}}else{j=r
i=p
k=""}return g+l+B.b.t(e,i,j)+k+"\n"+B.b.er(" ",f-i+l.length)+"^\n"}else return f!=null?g+(" (at offset "+A.p(f)+")"):g}}
A.o.prototype={
bU(a,b,c){var s=A.u(this)
return A.ft(this,s.U(c).i("1(o.E)").a(b),s.i("o.E"),c)},
uD(a,b){var s=A.u(this)
return new A.an(this,s.i("x(o.E)").a(b),s.i("an<o.E>"))},
iq(a,b){return new A.ae(this,b.i("ae<0>"))},
v(a,b){var s
for(s=this.gJ(this);s.l();)if(J.A(s.gq(),b))return!0
return!1},
O(a,b){var s
A.u(this).i("~(o.E)").a(b)
for(s=this.gJ(this);s.l();)b.$1(s.gq())},
ag(a,b,c,d){var s,r
d.a(b)
A.u(this).U(d).i("1(1,o.E)").a(c)
for(s=this.gJ(this),r=b;s.l();)r=c.$2(r,s.gq())
return r},
cR(a,b){var s
A.u(this).i("x(o.E)").a(b)
for(s=this.gJ(this);s.l();)if(!A.ac(b.$1(s.gq())))return!1
return!0},
ab(a,b){var s,r,q=this.gJ(this)
if(!q.l())return""
s=J.L(q.gq())
if(!q.l())return s
if(b.length===0){r=s
do r+=J.L(q.gq())
while(q.l())}else{r=s
do r=r+b+J.L(q.gq())
while(q.l())}return r.charCodeAt(0)==0?r:r},
bn(a){return this.ab(0,"")},
c0(a,b){var s
A.u(this).i("x(o.E)").a(b)
for(s=this.gJ(this);s.l();)if(A.ac(b.$1(s.gq())))return!0
return!1},
b9(a,b){return A.N(this,b,A.u(this).i("o.E"))},
cZ(a){return this.b9(0,!0)},
gm(a){var s,r=this.gJ(this)
for(s=0;r.l();)++s
return s},
ga6(a){return!this.gJ(this).l()},
gal(a){return!this.ga6(this)},
bL(a,b){return A.zR(this,b,A.u(this).i("o.E"))},
gF(a){var s=this.gJ(this)
if(!s.l())throw A.i(A.cP())
return s.gq()},
ar(a,b){var s,r
A.bE(b,"index")
s=this.gJ(this)
for(r=b;s.l();){if(r===0)return s.gq();--r}throw A.i(A.nP(b,b-r,this,"index"))},
B(a){return A.DD(this,"(",")")}}
A.F.prototype={
B(a){return"MapEntry("+A.p(this.a)+": "+A.p(this.b)+")"}}
A.ah.prototype={
ga3(a){return A.J.prototype.ga3.call(this,0)},
B(a){return"null"}}
A.J.prototype={$iJ:1,
n(a,b){return this===b},
ga3(a){return A.hU(this)},
B(a){return"Instance of '"+A.oN(this)+"'"},
W(a,b){throw A.i(A.zE(this,t.pN.a(b)))},
gaz(a){return A.iW(this)},
toString(){return this.B(this)},
$1$1(a,b){return this.W(this,A.a8("call","$1$1",0,[a,b],[],1))},
$0(){return this.W(this,A.a8("call","$0",0,[],[],0))},
$1(a){return this.W(this,A.a8("call","$1",0,[a],[],0))},
$2(a,b){return this.W(this,A.a8("call","$2",0,[a,b],[],0))},
$2$source(a,b){return this.W(this,A.a8("call","$2$source",0,[a,b],["source"],0))},
$3(a,b,c){return this.W(this,A.a8("call","$3",0,[a,b,c],[],0))},
$1$growable(a){return this.W(this,A.a8("call","$1$growable",0,[a],["growable"],0))},
$2$1(a,b,c){return this.W(this,A.a8("call","$2$1",0,[a,b,c],[],2))},
$3$keepNull(a,b,c){return this.W(this,A.a8("call","$3$keepNull",0,[a,b,c],["keepNull"],0))},
$1$0(a){return this.W(this,A.a8("call","$1$0",0,[a],[],1))},
$2$force(a,b){return this.W(this,A.a8("call","$2$force",0,[a,b],["force"],0))},
$4(a,b,c,d){return this.W(this,A.a8("call","$4",0,[a,b,c,d],[],0))},
$2$inclusive(a,b){return this.W(this,A.a8("call","$2$inclusive",0,[a,b],["inclusive"],0))},
$2$bubble(a,b){return this.W(this,A.a8("call","$2$bubble",0,[a,b],["bubble"],0))},
$2$html$text(a,b){return this.W(this,A.a8("call","$2$html$text",0,[a,b],["html","text"],0))},
$3$indexFromRange$source(a,b,c){return this.W(this,A.a8("call","$3$indexFromRange$source",0,[a,b,c],["indexFromRange","source"],0))},
$4$index$shift$source(a,b,c,d){return this.W(this,A.a8("call","$4$index$shift$source",0,[a,b,c,d],["index","shift","source"],0))},
$1$2(a,b,c){return this.W(this,A.a8("call","$1$2",0,[a,b,c],[],1))},
$2$handler(a,b){return this.W(this,A.a8("call","$2$handler",0,[a,b],["handler"],0))},
$3$html$text(a,b,c){return this.W(this,A.a8("call","$3$html$text",0,[a,b,c],["html","text"],0))},
$2$fromPart(a,b){return this.W(this,A.a8("call","$2$fromPart",0,[a,b],["fromPart"],0))},
$2$0(a,b){return this.W(this,A.a8("call","$2$0",0,[a,b],[],2))},
$4$position$width(a,b,c,d){return this.W(this,A.a8("call","$4$position$width",0,[a,b,c,d],["position","width"],0))},
$3$index$source(a,b,c){return this.W(this,A.a8("call","$3$index$source",0,[a,b,c],["index","source"],0))},
$1$rowspan(a){return this.W(this,A.a8("call","$1$rowspan",0,[a],["rowspan"],0))},
h(a,b){return this.W(a,A.a8("[]","h",0,[b],[],0))},
bs(){return this.W(this,A.a8("toJson","bs",0,[],[],0))},
j(a,b,c){return this.W(a,A.a8("[]=","j",0,[b,c],[],0))},
eT(a){return this.W(this,A.a8("_yieldStar","eT",0,[a],[],0))},
i6(a){return this.W(this,A.a8("pasteGridIntoSelection","i6",0,[a],[],0))},
c7(a,b){return this.W(this,A.a8("insertTable","c7",0,[a,b],[],0))},
dE(a,b){return this.W(a,A.a8(">","dE",0,[b],[],0))},
gm(a){return this.W(a,A.a8("length","gm",1,[],[],0))},
gdl(){return this.W(this,A.a8("emitter","gdl",1,[],[],0))},
gb_(){return this.W(this,A.a8("type","gb_",1,[],[],0))},
gcU(){return this.W(this,A.a8("isComposing","gcU",1,[],[],0))},
gct(){return this.W(this,A.a8("container","gct",1,[],[],0))},
gc4(){return this.W(this,A.a8("index","gc4",1,[],[],0))},
gd2(){return this.W(this,A.a8("selectedIndex","gd2",1,[],[],0))},
gcO(){return this.W(this,A.a8("dataTransfer","gcO",1,[],[],0))},
gil(){return this.W(this,A.a8("tooltip","gil",1,[],[],0))},
sd2(a){return this.W(this,A.a8("selectedIndex=","sd2",2,[a],[],0))}}
A.lh.prototype={
B(a){return""},
$idX:1}
A.ch.prototype={
gbT(){var s,r=this.b
if(r==null)r=$.cd.$0()
s=r-this.a
if($.iZ()===1000)return s
return B.d.bC(s,1000)},
bN(){var s=this,r=s.b
if(r!=null){s.a=s.a+($.cd.$0()-r)
s.b=null}}}
A.a_.prototype={
gm(a){return this.a.length},
B(a){var s=this.a
return s.charCodeAt(0)==0?s:s},
$iEl:1}
A.ta.prototype={
$2(a,b){throw A.i(A.bc("Illegal IPv4 address, "+a,this.a,b))},
$S:132}
A.tb.prototype={
$2(a,b){throw A.i(A.bc("Illegal IPv6 address, "+a,this.a,b))},
$S:152}
A.tc.prototype={
$2(a,b){var s
if(b-a>4)this.a.$2("an IPv6 part can only contain a maximum of 4 hex digits",a)
s=A.bM(B.b.t(this.b,a,b),16)
if(s<0||s>65535)this.a.$2("each part must be in the range of `0x0..0xFFFF`",a)
return s},
$S:44}
A.iG.prototype={
gkz(){var s,r,q,p,o=this,n=o.w
if(n===$){s=o.a
r=s.length!==0?""+s+":":""
q=o.c
p=q==null
if(!p||s==="file"){s=r+"//"
r=o.b
if(r.length!==0)s=s+r+"@"
if(!p)s+=q
r=o.d
if(r!=null)s=s+":"+A.p(r)}else s=r
s+=o.e
r=o.f
if(r!=null)s=s+"?"+r
r=o.r
if(r!=null)s=s+"#"+r
n!==$&&A.ei()
n=o.w=s.charCodeAt(0)==0?s:s}return n},
ga3(a){var s,r=this,q=r.y
if(q===$){s=B.b.ga3(r.gkz())
r.y!==$&&A.ei()
r.y=s
q=s}return q},
glT(){return this.b},
ghT(){var s=this.c
if(s==null)return""
if(B.b.a0(s,"["))return B.b.t(s,1,s.length-1)
return s},
gi7(){var s=this.d
return s==null?A.AM(this.a):s},
glx(){var s=this.f
return s==null?"":s},
gla(){var s=this.r
return s==null?"":s},
glf(){return this.a.length!==0},
glb(){return this.c!=null},
gle(){return this.f!=null},
gld(){return this.r!=null},
B(a){return this.gkz()},
n(a,b){var s,r,q,p=this
if(b==null)return!1
if(p===b)return!0
s=!1
if(t.eP.b(b))if(p.a===b.gcH())if(p.c!=null===b.glb())if(p.b===b.glT())if(p.ghT()===b.ghT())if(p.gi7()===b.gi7())if(p.e===b.glv()){r=p.f
q=r==null
if(!q===b.gle()){if(q)r=""
if(r===b.glx()){r=p.r
q=r==null
if(!q===b.gld()){s=q?"":r
s=s===b.gla()}}}}return s},
$ikG:1,
gcH(){return this.a},
glv(){return this.e}}
A.t9.prototype={
glS(){var s,r,q,p,o=this,n=null,m=o.c
if(m==null){m=o.b
if(0>=m.length)return A.d(m,0)
s=o.a
m=m[0]+1
r=B.b.bl(s,"?",m)
q=s.length
if(r>=0){p=A.iH(s,r+1,q,B.U,!1,!1)
q=r}else p=n
m=o.c=new A.l2("data","",n,n,A.iH(s,m,q,B.aY,!1,!1),p,n)}return m},
B(a){var s,r=this.b
if(0>=r.length)return A.d(r,0)
s=this.a
return r[0]===-1?"data:"+s:s}}
A.ux.prototype={
$2(a,b){var s=this.a
if(!(a<s.length))return A.d(s,a)
s=s[a]
B.u.rC(s,0,96,b)
return s},
$S:191}
A.uy.prototype={
$3(a,b,c){var s,r,q,p
for(s=b.length,r=a.$flags|0,q=0;q<s;++q){p=b.charCodeAt(q)^96
r&2&&A.ak(a)
if(!(p<96))return A.d(a,p)
a[p]=c}},
$S:67}
A.uz.prototype={
$3(a,b,c){var s,r,q,p=b.length
if(0>=p)return A.d(b,0)
s=b.charCodeAt(0)
if(1>=p)return A.d(b,1)
r=b.charCodeAt(1)
p=a.$flags|0
for(;s<=r;++s){q=(s^96)>>>0
p&2&&A.ak(a)
if(!(q<96))return A.d(a,q)
a[q]=c}},
$S:67}
A.ld.prototype={
glf(){return this.b>0},
glb(){return this.c>0},
gle(){return this.f<this.r},
gld(){return this.r<this.a.length},
gcH(){var s=this.w
return s==null?this.w=this.o_():s},
o_(){var s,r=this,q=r.b
if(q<=0)return""
s=q===4
if(s&&B.b.a0(r.a,"http"))return"http"
if(q===5&&B.b.a0(r.a,"https"))return"https"
if(s&&B.b.a0(r.a,"file"))return"file"
if(q===7&&B.b.a0(r.a,"package"))return"package"
return B.b.t(r.a,0,q)},
glT(){var s=this.c,r=this.b+3
return s>r?B.b.t(this.a,r,s-1):""},
ghT(){var s=this.c
return s>0?B.b.t(this.a,s,this.d):""},
gi7(){var s,r=this
if(r.c>0&&r.d+1<r.e)return A.bM(B.b.t(r.a,r.d+1,r.e),null)
s=r.b
if(s===4&&B.b.a0(r.a,"http"))return 80
if(s===5&&B.b.a0(r.a,"https"))return 443
return 0},
glv(){return B.b.t(this.a,this.e,this.f)},
glx(){var s=this.f,r=this.r
return s<r?B.b.t(this.a,s+1,r):""},
gla(){var s=this.r,r=this.a
return s<r.length?B.b.L(r,s+1):""},
ga3(a){var s=this.x
return s==null?this.x=B.b.ga3(this.a):s},
n(a,b){if(b==null)return!1
if(this===b)return!0
return t.eP.b(b)&&this.a===b.B(0)},
B(a){return this.a},
$ikG:1}
A.l2.prototype={}
A.jy.prototype={
h(a,b){t.K.a(b)
if(A.ef(b)||typeof b=="number"||typeof b=="string"||b instanceof A.aW)A.zg(b)
return this.a.get(b)},
j(a,b,c){this.$ti.i("1?").a(c)
this.a.set(b,c)},
B(a){return"Expando:"+A.p(this.b)}}
A.ww.prototype={
$1(a){return this.a.dW(this.b.i("0/?").a(a))},
$S:5}
A.wx.prototype={
$1(a){if(a==null)return this.a.kU(new A.oq(a===undefined))
return this.a.kU(a)},
$S:5}
A.vF.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h
if(A.Bf(a))return a
s=this.a
a.toString
if(s.p(a))return s.h(0,a)
if(a instanceof Date){r=a.getTime()
if(r<-864e13||r>864e13)A.a4(A.aK(r,-864e13,864e13,"millisecondsSinceEpoch",null))
A.eg(!0,"isUtc",t.v)
return new A.cN(r,0,!0)}if(a instanceof RegExp)throw A.i(A.au("structured clone of RegExp",null))
if(typeof Promise!="undefined"&&a instanceof Promise)return A.JH(a,t.dy)
q=Object.getPrototypeOf(a)
if(q===Object.prototype||q===null){p=t.dy
o=A.b(p,p)
s.j(0,a,o)
n=Object.keys(a)
m=[]
for(s=J.bx(n),p=s.gJ(n);p.l();)m.push(A.iQ(p.gq()))
for(l=0;l<s.gm(n);++l){k=s.h(n,l)
if(!(l<m.length))return A.d(m,l)
j=m[l]
if(k!=null)o.j(0,j,this.$1(a[k]))}return o}if(a instanceof Array){i=a
o=[]
s.j(0,a,o)
h=A.v(a.length)
for(s=J.aO(i),l=0;l<h;++l)o.push(this.$1(s.h(i,l)))
return o}return a},
$S:216}
A.oq.prototype={
B(a){return"Promise was rejected with a value of `"+(this.a?"undefined":"null")+"`."}}
A.tX.prototype={
am(a){if(a<=0||a>4294967296)throw A.i(A.Ed("max must be in range 0 < max \u2264 2^32, was "+a))
return Math.random()*a>>>0}}
A.ep.prototype={
aK(a,b){return J.A(a,b)},
aV(a){return J.b4(a)},
$ic8:1}
A.fn.prototype={
aK(a,b){var s,r,q,p=this.$ti.i("o<1>?")
p.a(a)
p.a(b)
if(a===b)return!0
s=J.U(a)
r=J.U(b)
for(p=this.a;!0;){q=s.l()
if(q!==r.l())return!1
if(!q)return!0
if(!p.aK(s.gq(),r.gq()))return!1}},
aV(a){var s,r,q
this.$ti.i("o<1>?").a(a)
for(s=J.U(a),r=this.a,q=0;s.l();){q=q+r.aV(s.gq())&2147483647
q=q+(q<<10>>>0)&2147483647
q^=q>>>6}q=q+(q<<3>>>0)&2147483647
q^=q>>>11
return q+(q<<15>>>0)&2147483647},
$ic8:1}
A.dS.prototype={
aK(a,b){var s,r,q,p,o=this.$ti.i("t<1>?")
o.a(a)
o.a(b)
if(a===b)return!0
o=J.aO(a)
s=o.gm(a)
r=J.aO(b)
if(s!==r.gm(b))return!1
for(q=this.a,p=0;p<s;++p)if(!q.aK(o.h(a,p),r.h(b,p)))return!1
return!0},
aV(a){var s,r,q,p
this.$ti.i("t<1>?").a(a)
for(s=J.aO(a),r=this.a,q=0,p=0;p<s.gm(a);++p){q=q+r.aV(s.h(a,p))&2147483647
q=q+(q<<10>>>0)&2147483647
q^=q>>>6}q=q+(q<<3>>>0)&2147483647
q^=q>>>11
return q+(q<<15>>>0)&2147483647},
$ic8:1}
A.bm.prototype={
aK(a,b){var s,r,q,p,o=A.u(this),n=o.i("bm.T?")
n.a(a)
n.a(b)
if(a===b)return!0
n=this.a
s=A.x9(o.i("x(bm.E,bm.E)").a(n.grA()),o.i("j(bm.E)").a(n.gt1()),n.gtB(),o.i("bm.E"),t.S)
for(o=J.U(a),r=0;o.l();){q=o.gq()
p=s.h(0,q)
s.j(0,q,(p==null?0:p)+1);++r}for(o=J.U(b);o.l();){q=o.gq()
p=s.h(0,q)
if(p==null||p===0)return!1
if(typeof p!=="number")return p.fG()
s.j(0,q,p-1);--r}return r===0},
aV(a){var s,r,q
A.u(this).i("bm.T?").a(a)
for(s=J.U(a),r=this.a,q=0;s.l();)q=q+r.aV(s.gq())&2147483647
q=q+(q<<3>>>0)&2147483647
q^=q>>>11
return q+(q<<15>>>0)&2147483647},
$ic8:1}
A.fO.prototype={}
A.fz.prototype={}
A.h3.prototype={
ga3(a){var s=this.a
return 3*s.a.aV(this.b)+7*s.b.aV(this.c)&2147483647},
n(a,b){var s
if(b==null)return!1
if(b instanceof A.h3){s=this.a
s=s.a.aK(this.b,b.b)&&s.b.aK(this.c,b.c)}else s=!1
return s}}
A.fr.prototype={
aK(a,b){var s,r,q,p,o=this.$ti.i("B<1,2>?")
o.a(a)
o.a(b)
if(a===b)return!0
if(a.gm(a)!==b.gm(b))return!1
s=A.x9(null,null,null,t.pJ,t.S)
for(o=J.U(a.ga7());o.l();){r=o.gq()
q=new A.h3(this,r,a.h(0,r))
p=s.h(0,q)
s.j(0,q,(p==null?0:p)+1)}for(o=J.U(b.ga7());o.l();){r=o.gq()
q=new A.h3(this,r,b.h(0,r))
p=s.h(0,q)
if(p==null||p===0)return!1
if(typeof p!=="number")return p.fG()
s.j(0,q,p-1)}return!0},
aV(a){var s,r,q,p,o,n,m,l=this.$ti
l.i("B<1,2>?").a(a)
for(s=J.U(a.ga7()),r=this.a,q=this.b,l=l.y[1],p=0;s.l();){o=s.gq()
n=r.aV(o)
m=a.h(0,o)
p=p+3*n+7*q.aV(m==null?l.a(m):m)&2147483647}p=p+(p<<3>>>0)&2147483647
p^=p>>>11
return p+(p<<15>>>0)&2147483647},
$ic8:1}
A.fe.prototype={
aK(a,b){var s,r,q=this
if(a instanceof A.cg)return b instanceof A.cg&&new A.fz(q,t.iq).aK(a,b)
s=t.G
if(s.b(a))return s.b(b)&&new A.fr(q,q,t.Ec).aK(a,b)
if(!q.b){s=t.j
if(s.b(a))return s.b(b)&&new A.dS(q,t.ot).aK(a,b)
s=t.Y
if(s.b(a))return s.b(b)&&new A.fn(q,t.mP).aK(a,b)}else{s=t.Y
if(s.b(a)){r=t.j
if(r.b(a)!==r.b(b))return!1
return s.b(b)&&new A.fO(q,t.AF).aK(a,b)}}return J.A(a,b)},
aV(a){var s=this
if(a instanceof A.cg)return new A.fz(s,t.iq).aV(a)
if(t.G.b(a))return new A.fr(s,s,t.Ec).aV(a)
if(!s.b){if(t.j.b(a))return new A.dS(s,t.ot).aV(a)
if(t.Y.b(a))return new A.fn(s,t.mP).aV(a)}else if(t.Y.b(a))return new A.fO(s,t.AF).aV(a)
return J.b4(a)},
tC(a){return!0},
$ic8:1}
A.X.prototype={}
A.p8.prototype={
ia(a){var s,r,q,p,o,n
this.a.j(0,a.a,a)
for(s=a.d,r=s.length,q=this.b,p=a.e.length===0,o=0;o<r;++o){n=s[o].toUpperCase()
if(q.h(0,n)==null||p)q.j(0,n,a)}},
bq(a,b){var s=this.c.h(0,a)
if(s==null)return null
if(b===65535||A.fy(s.gT(),b))return s
return null},
aw(a,b){var s=this.a.h(0,a)
if(s==null)return null
if(A.fy(s.b,b))return s
return null},
u4(a){var s=this.b.h(0,a.toUpperCase())
if(s==null||!A.fy(s.b,65535))return null
return s},
iH(a,b){var s,r,q,p,o,n,m,l,k=a.toUpperCase()
for(s=this.a.gak(),r=A.u(s),s=new A.aS(J.U(s.a),s.b,r.i("aS<1,2>")),r=r.y[1],q=null;s.l();){p=s.a
o=p==null?r.a(p):p
if(!A.fy(o.b,b))continue
for(p=o.d,n=p.length,m=o.e.length===0,l=0;l<n;++l){if(p[l].toUpperCase()!==k)continue
if(m)return o
if(q==null)q=o}}return q},
i9(a,b){var s,r,q,p,o,n,m
if(a.length===0)return null
s=B.b.aN(a,A.D("\\s+",!0,!1))
r=A.K(s)
q=r.i("an<1>")
p=A.N(new A.an(s,r.i("x(1)").a(new A.p9()),q),!0,q.i("o.E"))
if(p.length===0)return null
for(s=this.a.gak(),r=A.u(s),s=new A.aS(J.U(s.a),s.b,r.i("aS<1,2>")),r=r.y[1];s.l();){q=s.a
if(q==null)q=r.a(q)
if(!A.fy(q.b,b))continue
for(o=p.length,n=q.e,m=0;m<o;++m)if(B.a.v(n,p[m]))return q}return null},
u3(a){return this.i9(a,65535)},
a5(a,b){var s=this.a.h(0,a)
if(s==null)throw A.i(A.au('Unknown blot "'+a+'"',null))
return s.c.$1(b)}}
A.p9.prototype={
$1(a){return A.h(a).length!==0},
$S:8}
A.C.prototype={
gX(){var s=this.gaR()
if(s==null)throw A.i(A.aL("Blot is not attached to a scroll"))
return s},
gaR(){for(var s=this;s!=null;){if(s instanceof A.bh)return s
s=s.a}return null},
de(){},
f2(){},
P(){return B.l},
N(a,b){A.h(a)},
cT(a,b){return null},
b1(a,b,c,d){this.iW(a,b,c,d)},
iW(a,b,c,d){var s,r,q,p,o,n,m=this
if(b<=0)return
if(d!=null){s=J.a3(d)
r=!s.n(d,!1)&&!s.n(d,"")}else r=!1
if(m.gX().z.aw(c,1)!=null&&r)m.ea(a,b).ir(c,d)
else if(m.gX().z.bq(c,256)!=null){s=m.gX()
q=(m.gT()&4)!==0?"block":"inline"
p=s.z.a.h(0,q)
if(p==null)return
o=m.ea(a,b)
n=m.gX().z.a5(p.a,null)
if(!(n instanceof A.z))return
o.en(n)
n.N(c,d)}},
ea(a,b){var s=this.aN(0,a)
if(s==null)throw A.i(A.aL("Attempt to isolate at end of blot"))
s.aN(0,b)
return s},
ir(a,b){var s=this.gX().z.a5(a,b)
if(!(s instanceof A.z))throw A.i(A.au('Cannot wrap blot in non-parent "'+a+'"',null))
return this.en(s)},
uE(a){return this.ir(a,null)},
en(a){var s=this.a
if(s!=null)s.D(a,this.c)
a.D(this,null)
return a},
cD(a){var s=this.a
if(s!=null){s.D(a,this.c)
this.Y(0)}return a},
Y(a){var s=this.a
if(s!=null)s.aj(this)},
G(a,b){var s,r
t.k.a(a)
t.h.a(b)
s=this.gu9()
if(s!=null){r=this.a
r=r!=null&&r.gA()!==s}else r=!1
if(r)this.uE(s)},
gu9(){var s,r=this.gaR()
if(r==null)return null
s=r.z.aw(this.gA(),65535)
return s==null?null:s.f},
bx(a,b){var s=this.d.n(0,a)
if(s)return new A.F(this,0,t.nv)
return B.al},
eV(a,b){t.o.a(a)
t.P.a(b)},
gl3(){var s,r=this.a
for(s=0;r!=null;){++s
r=r.a}return s}}
A.z.prototype={
E(a){return B.a.ag(this.e,0,new A.oE(),t.S)},
eZ(a){var s,r,q,p,o
for(s=this.e,r=s.length,q=0,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
if(o===a)return q
q+=o.E(0)}return-1},
de(){var s,r,q
this.mJ()
for(s=A.a5(this.e,!0,t.U),r=s.length,q=0;q<r;++q)s[q].de()},
f2(){var s,r,q
for(s=A.a5(this.e,!0,t.U),r=s.length,q=0;q<r;++q)s[q].f2()
this.mK()},
kK(a){var s=this.f
if(s!=null)s.Y(0)
this.f=a
s=a.a
t.m.a(s.classList).add("ql-ui")
s.setAttribute("contenteditable","false")
s=t.T.a(this.d)
s.D(a,s.gf6())},
cw(a){return null},
dX(){return this.cw(null)},
G(a,b){var s,r,q,p,o,n=this
t.k.a(a)
t.h.a(b)
n.ey(a,b)
s=n.e
r=t.U
q=A.a5(s,!0,r)
for(p=q.length,o=0;o<p;++o)q[o].G(a,b)
n.dm()
for(s=A.a5(s,!0,r),r=s.length,o=0;o<r;++o)n.oi(s[o],a,b)},
aq(){return this.G(null,null)},
gaO(){return null},
dm(){var s,r,q,p,o,n=this,m=n.gaO()
if(m==null)return
for(s=A.a5(n.e,!0,t.U),r=s.length,q=0;q<r;++q){p=s[q]
if(A.ac(m.$1(p)))continue
if(A.fy(p.gT(),5)){if(p.c!=null)n.dJ(p)
s=p.b
if(s!=null)n.dJ(s)
o=p.a
if(o instanceof A.z)o.bX()
return}else if(p instanceof A.z)p.bX()
else p.Y(0)}},
aL(a,b,c){var s,r,q,p,o,n=this,m=n.e,l=m.length
if(l===0){s=n.cw(b)
if(s==null)throw A.i(A.aV("Cannot insert into empty "+A.iW(n).B(0)))
n.D(s,null)
s.aL(a,b,c)
return}for(r=0,q=0;q<l;++q,r=p){if(!(q<l))return A.d(m,q)
s=m[q]
p=r+s.E(0)
l=m.length
o=q===l-1
if(a<p||o){s.aL(a-r,b,c)
return}}},
aF(a,b){return this.aL(a,b,null)},
e4(a,b,c){var s,r,q,p,o,n,m,l
t.ef.a(c)
if(b<=0)return
for(s=A.a5(this.e,!0,t.U),r=s.length,q=a+b,p=0,o=0;o<r;++o,p=l){n=s[o]
m=n.E(0)
if(p>=q)break
l=p+m
if(l>a)if(a>p)c.$3(n,a-p,B.f.aA(Math.min(b,l-a)))
else c.$3(n,0,B.f.aA(Math.min(m,q-p)))}},
bS(a,b){if(b<=0)return
if(a===0&&b===this.E(0)){this.Y(0)
return}this.e4(a,b,new A.oC())},
b1(a,b,c,d){if(b<=0)return
this.e4(a,b,new A.oD(c,d))},
D(a,b){var s,r,q,p,o,n,m,l,k=this,j=null
if(a===b)return
s=b==null
r=!s
if(r&&b.a!==k)throw A.i(A.au("Reference blot is not a child of this parent",j))
q=k.e
p=r?B.a.ae(q,b):q.length
if(p===-1)throw A.i(A.au("Reference blot is not managed by this parent",j))
o=a.a
if(o!=null)o.aj(a)
if(p>0){o=p-1
if(!(o<q.length))return A.d(q,o)
n=q[o]}else n=j
if(s){s=q.length
if(p<s){if(!(p>=0))return A.d(q,p)
s=q[p]
m=s}else m=j}else m=b
a.a=k
a.b=n
a.c=m
if(n!=null)n.c=a
if(m!=null)m.b=a
s=t.T
o=k.d
l=a.d
if(r)s.a(o).D(l,b.d)
else t.m.a(s.a(o).a.appendChild(l.a))
B.a.V(q,p,a)
s=k.gaR()
if(s!=null)++s.as
a.de()},
aj(a){var s,r,q=this.e,p=B.a.ae(q,a)
if(p===-1)return
s=a.b
r=a.c
if(s!=null)s.c=r
if(r!=null)r.b=s
B.a.cC(q,p)
q=this.gaR()
if(q!=null)++q.as
a.f2()
a.c=a.b=a.a=null
a.d.Y(0)},
b2(a,b){var s,r,q=A.a5(this.e,!0,t.U)
for(s=q.length,r=0;r<s;++r)a.D(q[r],b)},
cD(a){if(a instanceof A.z)this.b2(a,null)
return this.mM(a)},
eV(a,b){t.o.a(a)
t.P.a(b)
if(J.j0(a,new A.oB(this)))this.n9(b)},
n9(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=this
t.P.a(a)
s=t.I
r=A.b(s,t.U)
for(q=f.e,p=q.length,o=0;o<q.length;q.length===p||(0,A.k)(q),++o){n=q[o]
r.j(0,n.d,n)}m=A.a([],t.E)
for(s=A.a5(t.T.a(f.d).gan(),!0,s),p=s.length,o=0;o<p;++o){l=s[o]
if(l.n(0,f.f))continue
k=r.Z(0,l)
if(k!=null){B.a.k(m,k)
continue}j=f.gaR()
if(j==null)A.a4(A.aL("Blot is not attached to a scroll"))
i=j.fP(l)
if(i!=null)B.a.k(m,i)}for(s=r.gak(),r=A.u(s),s=new A.aS(J.U(s.a),s.b,r.i("aS<1,2>")),r=r.y[1];s.l();){p=s.a
if(p==null)p=r.a(p)
h=B.a.ae(q,p)
if(h!==-1)B.a.cC(q,h)
p.c=p.b=p.a=null}B.a.M(q)
B.a.H(q,m)
for(s=q.length,g=null,o=0;o<s;++o,g=n){n=q[o]
n.a=f
n.b=g
if(g!=null)g.c=n}if(g!=null)g.c=null},
bX(){var s=this,r=s.a
if(r!=null)s.b2(r,s.c)
s.Y(0)},
dJ(a){var s,r,q=this.a1(),p=this.a
if(p!=null)p.D(q,this.c)
s=a.c
for(;s!=null;s=r){r=s.c
q.D(s,null)}return q},
oi(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h=this
t.k.a(b)
t.h.a(c)
if(a.a!==h)return
s=a.d
r=s.gaG()
q=t.T.a(h.d)
if(J.A(r,q))return
if(r==null){t.m.a(q.a.appendChild(s.a))
return}if(!(r instanceof A.f)){t.m.a(q.a.appendChild(s.a))
return}o=h.e
n=o.length
m=0
while(!0){if(!(m<o.length)){p=null
break}l=o[m]
if(l instanceof A.z&&l.d.n(0,r)){p=l
break}o.length===n||(0,A.k)(o);++m}if(p==null){k=h.gX().z
o=r.a
n=A.h(o.className)
j=k.i9(n,65535)
if(j==null)j=k.iH(A.h(o.tagName),65535)
if(j==null){q.D(s,r)
r.Y(0)
return}i=k.a5(j.a,r)
if(!(i instanceof A.z)){q.D(s,r)
r.Y(0)
return}h.D(i,a)
p=i}h.aj(a)
p.D(a,null)
p.G(b,c)},
hB(a,b){A.lm(b,t.U,"T","descendants")
return new A.cH(this.rq(a,b),b.i("cH<0>"))},
a4(a){return this.hB(null,a)},
rq(a,b){var s=this
return function(){var r=a,q=b
var p=0,o=1,n,m,l,k,j
return function $async$hB(c,d,e){if(d===1){n=e
p=o}while(true)switch(p){case 0:m=s.e,l=m.length,k=0
case 2:if(!(k<m.length)){p=4
break}j=m[k]
p=q.b(j)?5:6
break
case 5:p=7
return c.b=j,1
case 7:case 6:p=j instanceof A.z?8:9
break
case 8:p=10
return c.eT(j.hB(r,q))
case 10:case 9:case 3:m.length===l||(0,A.k)(m),++k
p=2
break
case 4:return 0
case 1:return c.c=n,3}}}},
l4(a,b,c,d){var s,r,q,p,o,n,m,l,k,j,i,h
A.lm(d,t.U,"T","descendantsAt")
s=A.a([],d.i("w<0>"))
for(r=this.e,q=r.length,p=a+b,o=b,n=0,m=0;m<r.length;r.length===q||(0,A.k)(r),++m,n=k){l=r[m]
k=n+l.E(0)
if(k>a&&n<p){j=Math.max(0,a-n)
i=Math.min(k,p)
h=Math.max(n,a)
if(d.b(l))B.a.k(s,l)
if(l instanceof A.z)B.a.H(s,l.l4(j,o,c,d))
o-=B.f.aA(Math.max(0,i-h))}if(k>=p)break}return s},
rr(a,b,c){return this.l4(a,b,null,c)},
bv(a,b){var s=this.qS(b),r=s.a,q=s.b
if(r!=null&&this.pk(r,a))return new A.F(r,q,t.nv)
if(r instanceof A.z)return r.bv(a,q)
return B.al},
qS(a){var s,r,q,p,o=this.e
for(s=a,r=0;r<o.length;){q=o[r]
p=q.E(0);++r
if(s<p)return new A.F(q,s,t.nv)
s-=p}return B.be},
pk(a,b){if(t.Ez.b(b))return b.$1(a)
return!1},
du(a,b){var s,r,q,p,o,n,m,l,k,j,i
if(a<0)throw A.i(A.zo(a,this,"index"))
s=t.mX
r=A.a([new A.F(this,a,s)],t.wx)
for(q=this.e,p=q.length,o=0,n=0;n<q.length;q.length===p||(0,A.k)(q),++n,o=l){m=q[n]
l=o+m.E(0)
if(a>=l){k=!1
if(b){if(a===l){j=m.c
j=j==null||j.E(0)!==0}else j=k
k=j}}else k=!0
if(k){i=a-o
B.a.k(r,new A.F(m,i,s))
if(m instanceof A.z){s=m.du(i,b)
q=A.K(s)
p=new A.eD(s,1,null,q.i("eD<1>"))
p.nk(s,1,null,q.c)
B.a.H(r,p)}break}}return r},
bM(a,b,c){var s,r,q=this
if(!c){if(b===0)return q
if(b===q.E(0))return q.c}s=q.a1()
r=q.a
if(r!=null)r.D(s,q.c)
q.e4(b,q.E(0),new A.oF(c,s))
return s},
aN(a,b){return this.bM(0,b,!1)},
bx(a,b){var s,r,q,p,o,n,m=this
if(m.d.n(0,a))return new A.F(m,0,t.nv)
for(s=m.e,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q].bx(a,!1)
if(p.a!=null)return p}if(b){s=m.a
if(s!=null)return s.bx(a,!0)
o=a.gaG()
for(s=t.A;o!=null;){n=m.bx(o,!1)
if(n.a!=null)return n
r=o.a
if(s.a(r.parentNode)==null)o=null
else{r=s.a(r.parentNode)
r.toString
o=A.S(r)}}}return B.al},
hI(a){return this.bx(a,!1)},
v(a,b){var s
for(s=b;s!=null;){if(s===this)return!0
s=s.a}return!1},
aP(a){var s,r,q
if(!this.v(0,a))return-1
s=a
r=0
while(!0){if(!(s!==this))break
q=s.a
if(q==null)break
r+=q.eZ(s)
s=q}return r}}
A.oE.prototype={
$2(a,b){return A.v(a)+t.U.a(b).E(0)},
$S:53}
A.oC.prototype={
$3(a,b,c){a.bS(b,c)},
$S:22}
A.oD.prototype={
$3(a,b,c){a.b1(b,c,this.a,this.b)},
$S:22}
A.oB.prototype={
$1(a){var s=t.BX.a(a).a
return A.h(s.type)==="childList"&&A.S(t.m.a(s.target)).n(0,this.a.d)},
$S:33}
A.oF.prototype={
$3(a,b,c){var s=a.bM(0,b,this.a)
if(s!=null)this.b.D(s,null)},
$S:22}
A.j9.prototype={}
A.ay.prototype={
cr(){var s=this.c,r=!1
if(s!=null)if(s.gA()===this.gA()){r=s.d
r=r instanceof A.f&&A.h(r.a.tagName)===A.h(t.T.a(this.d).a.tagName)}return r},
gll(){return!1},
bS(a,b){this.fK(a,b)
this.dm()},
b1(a,b,c,d){this.ci(a,b,c,d)
this.dm()},
aL(a,b,c){this.eB(a,b,c)
this.dm()},
aF(a,b){return this.aL(a,b,null)},
G(a,b){var s,r=this
r.eC(t.k.a(a),t.h.a(b))
if(r.gll())return
r.dm()
if(r.e.length===0){r.Y(0)
return}s=r.c
if(s instanceof A.z&&s.b===r&&r.cr()){s.b2(r,null)
s.Y(0)}},
aq(){return this.G(null,null)}}
A.aE.prototype={
E(a){return 1},
dr(a,b){t.I.a(a)
return A.v(b)},
aL(a,b,c){var s=this,r=c==null?s.gX().z.a5("text",b):s.gX().z.a5(b,c),q=s.aN(0,a),p=s.a
if(p!=null)p.D(r,q)},
aF(a,b){return this.aL(a,b,null)},
bS(a,b){this.ea(a,b).Y(0)},
bM(a,b,c){return b<=0?this:this.c},
aN(a,b){return this.bM(0,b,!1)},
eg(a,b){var s,r,q=this.a
if(q==null)return new A.F(this.d,0,t.Fv)
s=t.T.a(q.d)
r=B.a.ae(s.gan(),this.d)
if(r<0)r=0
if(a>0)++r
return new A.F(s,r,t.Fv)}}
A.cO.prototype={
N(a,b){A.h(a)
this.iW(0,this.E(0),a,b)},
b1(a,b,c,d){if(a===0&&b===this.E(0))this.N(c,d)
else this.mL(a,b,c,d)}}
A.hY.prototype={}
A.a0.prototype={
gaO(){return new A.lX()},
ga9(){var s,r=this.CW
if(r===$){s=t.T.a(this.d)
r!==$&&A.ei()
r=this.CW=new A.f7(s,A.b(t.N,t.d))}return r},
ph(a){if(this.a==null)return null
return this.gX().z.bq(a,256)},
d9(){var s,r
if(this.a==null)return
s=this.ga9()
r=t.nG.a(this.gpg())
if(!s.c)s.hs(r)},
gA(){return"block"},
gT(){return 5},
l2(){var s="delta",r=this.ch
if(!r.p(s))r.j(0,s,A.By(this,!0))
return t.D.a(r.h(0,s))},
a1(){return A.lV(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))},
bS(a,b){var s=this
if(a===0&&b>=s.E(0)){s.Y(0)
s.ch.M(0)
return}s.fK(a,b)
s.ch.M(0)},
N(a,b){var s,r,q,p,o=this
A.h(a)
s=o.gX().z.aw(a,4)
if(s!=null){r=o.P().h(0,a)
if(b==null||J.A(b,!1)){if(a!==o.gA())return
if(o.gA()==="block")return
o.kl(t.uO.a(o.gX().z.a5("block",null)))
o.ch.M(0)
return}if(s.a===o.gA()&&J.A(r,b))return
q=o.gX().z.a5(a,b)
if(q instanceof A.z){o.kl(q)
o.ch.M(0)}return}p=o.gX().z.bq(a,260)
if(p!=null){o.d9()
o.ga9().hp(p,b)
o.ch.M(0)
return}o.j5(a,b)},
P(){if(this.a==null)return B.l
this.d9()
return this.ga9().fo()},
b1(a,b,c,d){var s=this
if(b<=0)return
if(s.gX().z.aw(c,4)!=null||s.gX().z.bq(c,260)!=null){if(a+b===s.E(0))s.N(c,d)}else s.ci(a,B.f.aA(Math.min(b,B.f.aA(Math.max(0,s.E(0)-a-1)))),c,d)
s.ch.M(0)},
aL(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e=null
if(c!=null){if(f.gX().z.aw(b,2)==null){s=f.aN(0,a)
if(s==null)throw A.i(A.aL("Attempt to insertAt after block boundaries"))
r=f.gX().z.a5(b,c)
q=s.a
if(q!=null)q.D(r,s)
f.ch.M(0)
return}q=f.e
p=q.length
if(p===1){o=(p!==0?B.a.gF(q):e) instanceof A.ap
p=o}else p=!1
if(p){n=f.gX().z.a5(b,c)
f.D(n,q.length!==0?B.a.gF(q):e)
f.ch.M(0)
return}f.eB(a,b,c)
f.ch.M(0)
return}if(b.length===0)return
q=f.e
p=q.length
if(p===1){o=(p!==0?B.a.gF(q):e) instanceof A.ap
p=o}else p=!1
if(p){p=q.length!==0?B.a.gF(q):e
if(p!=null)p.Y(0)}m=A.a(b.split("\n"),t.s)
l=B.a.cC(m,0)
p=l.length
if(p!==0){if(q.length===0)f.D(A.Ai(l),e)
else{if(a>=f.E(0)-1)o=(q.length!==0?B.a.gK(q):e)==null
else o=!0
if(o)f.eB(B.f.aA(Math.min(a,B.f.aA(Math.max(f.E(0)-1,0)))),l,e)
else{q=q.length!==0?B.a.gK(q):e
if(q!=null)q.aF(q.E(0),l)}}f.ch.M(0)}k=a+p
for(q=m.length,j=f,i=0;i<m.length;m.length===q||(0,A.k)(m),++i){h=m[i]
if(!(j instanceof A.a0))break
g=j.bM(0,k,!0)
if(g!=null){g.aF(0,h)
k=h.length
j=g}}},
aF(a,b){return this.aL(a,b,null)},
D(a,b){var s=this,r=s.e
r=r.length!==0?B.a.gF(r):null
s.aT(a,b)
if(r instanceof A.ap&&r.a===s)r.Y(0)
s.ch.M(0)},
E(a){var s,r="length",q=this.ch
if(q.p(r))return A.v(q.h(0,r))
s=this.mZ(0)+1
q.j(0,r,s)
return s},
b2(a,b){this.j8(a,b)
this.ch.M(0)},
du(a,b){return this.j9(a,!0)},
G(a,b){var s,r,q,p,o,n,m,l,k,j,i,h=this
h.eC(t.k.a(a),t.h.a(b))
h.ch.M(0)
s=h.e
r=s.length
if(r===0){q=h.dX()
if(q!=null)h.D(q,null)}else if(r>1){p=B.a.gK(s)
if(p instanceof A.ap)p.Y(0)}r=A.K(s)
o=new A.a1(s,r.i("a7(1)").a(new A.lY()),r.i("a1<1,a7>")).uo(0)
for(s=A.a5(t.T.a(h.d).gan(),!0,t.I),r=s.length,n=t.A,m=t.m,l=0;l<r;++l){k=s[l]
if(!o.v(0,k)&&k instanceof A.f&&A.h(k.a.tagName).toUpperCase()==="BR"){j=k.a
i=n.a(j.parentNode)
if(i!=null)m.a(i.removeChild(j))}}},
aq(){return this.G(null,null)},
aj(a){this.n_(a)
this.ch.M(0)},
bM(a,b,c){var s,r,q,p=this
if(c)s=b===0||b>=p.E(0)-1
else s=!1
if(s){r=p.a1()
if(b===0){s=p.a
if(s!=null)s.D(r,p)
p.ch.M(0)
return p}s=p.a
if(s!=null)s.D(r,p.c)
p.ch.M(0)
return r}q=p.n1(0,b,c)
p.ch.M(0)
return q},
aN(a,b){return this.bM(0,b,!1)},
cw(a){return A.ht()},
dX(){return this.cw(null)},
kl(a){var s,r=this,q=r.a
if(q==null)return
q.D(a,r.c)
r.j8(a,null)
r.ch.M(0)
r.d9()
r.ga9().f_(new A.lW(a))
if(a.e.length===0){s=a.dX()
if(s!=null)a.D(s,null)}r.Y(0)}}
A.lX.prototype={
$1(a){return a instanceof A.ap||a instanceof A.aP||a instanceof A.cO||a instanceof A.aM},
$S:3}
A.lY.prototype={
$1(a){return t.U.a(a).d},
$S:129}
A.lW.prototype={
$2(a,b){return this.a.N(a,b)},
$S:2}
A.f8.prototype={
ga9(){var s,r=this.as
if(r===$){s=t.T.a(this.d)
r!==$&&A.ei()
r=this.as=new A.f7(s,A.b(t.N,t.d))}return r},
pj(a){return this.a!=null?this.gX().z.bq(a,260):null},
d9(){var s,r
if(this.a!=null){s=this.ga9()
r=t.nG.a(this.gpi())
if(!s.c)s.hs(r)}},
N(a,b){var s,r=this
A.h(a)
s=r.a!=null?r.gX().z.bq(a,260):null
if(s!=null){r.d9()
r.ga9().hp(s,b)}},
b1(a,b,c,d){this.N(c,d)},
gA(){return"blockEmbed"},
gT(){return 5},
bY(){var s=t.z
return A.b(s,s)},
aL(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g=this
if(c!=null){s=g.a
if(!(s instanceof A.z))return
r=g.gX().z.a5(b,c)
s.D(r,a<=0?g:g.c)
return}s=g.a
if(!(s instanceof A.z))return
q=A.a(b.split("\n"),t.s)
p=q.length
if(p!==0){if(0>=p)return A.d(q,-1)
o=q.pop()}else o=""
n=a<=0?g:g.c
for(p=q.length,m=t.uO,l=0;l<q.length;q.length===p||(0,A.k)(q),++l){k=q[l]
j=g.gaR()
if(j==null)A.a4(A.aL("Blot is not attached to a scroll"))
i=j.z.a.h(0,"block")
if(i==null)A.a4(A.au('Unknown blot "block"',null))
h=m.a(i.c.$1(null))
h.aF(0,k)
s.D(h,n)}if(o.length!==0)s.D(g.gX().z.a5("text",o),n)},
aF(a,b){return this.aL(a,b,null)}}
A.ap.prototype={
gA(){return"break"},
gT(){return 3},
E(a){return 0},
bY(){return""},
G(a,b){t.k.a(a)
t.h.a(b)
if(this.b!=null||this.c!=null)this.Y(0)}}
A.hy.prototype={}
A.cM.prototype={
gA(){return"cursor"},
gT(){return 3},
E(a){return this.at},
bY(){return""},
N(a,b){var s,r,q,p=this
A.h(a)
if(p.at!==0){p.j7(a,b)
return}s=p
r=0
while(!0){if(!((s.gT()&4)===0))break
q=s.a
if(q==null){s=null
break}r+=q.eZ(s)
s=q}if(s!=null){p.at=1
s.aq()
p.at=1
s.b1(r,1,a,b)
p.at=0}},
dr(a,b){t.I.a(a)
A.v(b)
if(a.n(0,this.as))return 0
return b>0?1:0},
eg(a,b){var s=this.as
return new A.F(s,A.h(s.a.data).length,t.Fv)},
ie(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this,a=null,a0=b.ax
a0=a0==null?a:a0.$0()
if(A.ac(a0==null?!1:a0))return a
if(b.a==null)return a
a0=b.ay
s=a0==null?a:a0.$0()
a0=t.T.a(b.d)
r=a0.gaG()
if(r instanceof A.f){q=t.m
p=r.a
o=t.A
n=b.as
while(!0){m=a0.a
if(o.a(m.lastChild)==null)l=a
else{l=o.a(m.lastChild)
l.toString
l=A.S(l)}if(l!=null){if(o.a(m.lastChild)==null)l=a
else{l=o.a(m.lastChild)
l.toString
l=A.S(l)}l=!J.A(l,n)}else l=!1
if(!l)break
if(o.a(m.lastChild)==null)l=a
else{l=o.a(m.lastChild)
l.toString
l=A.S(l)}l=l.a
q.a(p.insertBefore(l,m))}}k=b.b
k=k instanceof A.aM?k:a
a0=k==null
j=a0?a:A.h(t.y.a(k.d).a.data).length
if(j==null)j=0
i=b.c
i=i instanceof A.aM?i:a
q=i==null
p=!q
h=p?A.h(t.y.a(i.d).a.data):""
o=b.as.a
g=B.a.ab(A.a(A.h(o.data).split("\ufeff"),t.s),"")
o.data="\ufeff"
if(!a0){if(g.length!==0||p){k.aF(A.h(t.y.a(k.d).a.data).length,g+h)
if(!q)i.Y(0)}f=k}else if(p){if(g.length!==0)i.aF(0,g)
f=i}else{$.y().a.a===$&&A.c()
e=new A.aM(new A.bl(t.m.a(new self.Text(g))))
b.a.D(e,b)
f=e}b.fI(0)
b.a=null
if(s!=null){a0=new A.mO(b,k,j,i,g)
q=s.a
d=a0.$2(q[2],q[3])
c=a0.$2(q[0],q[1])
if(d!=null&&c!=null){a0=f.d
return new A.d8(a0,d,a0,c)}}return a},
eV(a,b){return this.d0(t.o.a(a),t.P.a(b))},
d0(a,b){var s
t.o.a(a)
t.P.a(b)
if(J.j0(a,new A.mP(this))){s=this.ie()
if(s!=null)b.j(0,"range",s)}},
G(a,b){var s,r,q,p,o,n=this
n.ey(t.k.a(a),t.h.a(b))
s=n.a
for(r=t.T;s!=null;){if(A.h(r.a(s.d).a.tagName)==="A"){n.at=1
r=s.aP(n)
q=n.at
p=s.aN(0,r)
if(p==null)A.a4(A.aL("Attempt to isolate at end of blot"))
p.aN(0,q)
if(p instanceof A.aP){o=p.a
if(o instanceof A.z){p.b2(o,p.c)
o.aj(p)}}n.at=0
break}s=s.a}},
aq(){return this.G(null,null)},
Y(a){this.fI(0)
this.a=null},
scU(a){this.ax=t.CC.a(a)},
stS(a){this.ay=t.DL.a(a)},
gcU(){return this.ax}}
A.mO.prototype={
$2(a,b){var s=this,r=s.b
if(r!=null&&a.n(0,r.d))return b
if(a.n(0,s.a.as))return s.c+b-1
r=s.d
if(r!=null&&a.n(0,r.d))return s.c+s.e.length+b
return null},
$S:131}
A.mP.prototype={
$1(a){var s=t.BX.a(a).a
return A.h(s.type)==="characterData"&&A.S(t.m.a(s.target)).n(0,this.a.as)},
$S:33}
A.d8.prototype={}
A.fg.prototype={
jh(a){var s,r,q,p,o,n,m=this
$.y().a.a===$&&A.c()
s=self
r=t.m
q=r.a(r.a(s.document).createElement("span"))
p=new A.f(A.b(t.O,t.g),q)
m.as!==$&&A.ai()
m.as=p
q.setAttribute("contenteditable","false")
for(q=A.a5(a.gan(),!0,t.I),o=q.length,p=p.a,n=0;n<o;++n)r.a(p.appendChild(q[n].a))
q=new A.bl(r.a(new s.Text("\ufeff")))
m.at!==$&&A.ai()
m.at=q
s=new A.bl(r.a(new s.Text("\ufeff")))
m.ax!==$&&A.ai()
m.ax=s
o=a.a
r.a(o.appendChild(q.a))
r.a(o.appendChild(p))
r.a(o.appendChild(s.a))},
dr(a,b){var s
t.I.a(a)
A.v(b)
s=this.at
s===$&&A.c()
if(a.n(0,s))return 0
s=this.ax
s===$&&A.c()
if(a.n(0,s))return 1
return b>0?1:0},
eV(a,b){return this.d0(t.o.a(a),t.P.a(b))},
d0(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e=null
t.o.a(a)
t.P.a(b)
for(s=J.U(a),r=t.m,q=t.y,p=t.s;s.l();){o=s.gq().a
if(A.h(o.type)==="characterData"){n=A.S(r.a(o.target))
m=f.at
m===$&&A.c()
if(!n.n(0,m)){n=A.S(r.a(o.target))
m=f.ax
m===$&&A.c()
m=n.n(0,m)
n=m}else n=!0}else n=!1
if(n){o=q.a(A.S(r.a(o.target)))
n=o.a
l=B.a.ab(A.a(A.h(n.data).split("\ufeff"),p),"")
$.y().a.a===$&&A.c()
m=f.at
m===$&&A.c()
if(o.n(0,m)){k=f.b
if(k instanceof A.aM){o=q.a(k.d)
j=A.h(o.a.data).length
k.aF(j,l)
i=new A.d8(o,j+l.length,e,e)}else{h=new A.bl(r.a(new self.Text(l)))
o=f.a
if(o!=null)o.D(new A.aM(h),f)
i=new A.d8(h,l.length,e,e)}}else{m=f.ax
m===$&&A.c()
if(o.n(0,m)){g=f.c
if(g instanceof A.aM){g.aF(0,l)
i=new A.d8(g.d,l.length,e,e)}else{h=new A.bl(r.a(new self.Text(l)))
o=f.a
if(o!=null)o.D(new A.aM(h),f.c)
i=new A.d8(h,l.length,e,e)}}else i=e}n.data="\ufeff"
if(i!=null)b.j(0,"range",i)}}}}
A.dL.prototype={
gA(){return"inline"},
gT(){return 3},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.dL(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.aP.prototype={
gaO(){return new A.nR()},
ga9(){var s,r=this.z
if(r===$){s=t.T.a(this.d)
r!==$&&A.ei()
r=this.z=new A.f7(s,A.b(t.N,t.d))}return r},
oZ(a){return this.a!=null?this.gX().z.bq(a,258):null},
dQ(){var s,r
if(this.a!=null){s=this.ga9()
r=t.nG.a(this.goY())
if(!s.c)s.hs(r)}},
N(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this,d=null
A.h(a)
if(a===e.gA())s=b==null||J.A(b,!1)
else s=!1
if(s){e.dQ()
if(e.ga9().fo().a!==0)for(s=A.a5(e.e,!0,t.U),r=s.length,q=e.d,p=t.T,o=t.N,n=t.d,m=0;m<r;++m){l=s[m]
if(l instanceof A.aP)k=l
else{j=l.gaR()
if(j==null)A.a4(A.aL("Blot is not attached to a scroll"))
i=j.z.a.h(0,"inline")
if(i==null)A.a4(A.au('Unknown blot "inline"',d))
h=i.c.$1(d)
if(!(h instanceof A.z))A.a4(A.au('Cannot wrap blot in non-parent "inline"',d))
k=l.en(h)}b=e.z
if(b===$){p.a(q)
b!==$&&A.ei()
b=e.z=new A.f7(q,A.b(o,n))}b.f_(k.gaU())}e.bX()
return}g=e.a!=null?e.gX().z.bq(a,258):d
if(g!=null){e.dQ()
e.ga9().hp(g,b)
return}if(b!=null){s=J.a3(b)
f=!s.n(b,!1)&&!s.n(b,"")}else f=!1
s=!1
if(f)if(e.a!=null)if(e.gX().z.aw(a,2)!=null)s=a!==e.gA()||!J.A(e.P().h(0,a),b)
if(s)e.cD(e.gX().z.a5(a,b))},
b1(a,b,c,d){var s,r,q,p=this
if(p.a!=null&&A.zp(p.gA(),c)<0&&p.gX().z.aw(c,1)!=null){s=p.ea(a,b)
if(d!=null){r=J.a3(d)
q=!r.n(d,!1)&&!r.n(d,"")}else q=!1
if(q)s.ir(c,d)
return}if(p.P().h(0,c)==null)r=p.a!=null&&p.gX().z.bq(c,256)!=null
else r=!0
if(r){p.ea(a,b).N(c,d)
return}p.ci(a,b,c,d)},
P(){this.dQ()
return this.ga9().fo()},
cD(a){var s
this.dQ()
s=this.n0(a)
if(s instanceof A.aP)this.ga9().f_(s.gaU())
return s},
en(a){var s=this.mN(a)
if(s instanceof A.aP){this.dQ()
this.ga9().tQ(s.gaU())}return s},
bX(){var s=this,r=s.a
if(r instanceof A.z){s.b2(r,s.c)
r.aj(s)}},
ot(a,b){var s,r,q=t.P
q.a(a)
q.a(b)
if(a.gm(a)!==b.gm(b))return!1
for(q=a.gao(),q=q.gJ(q);q.l();){s=q.gq()
r=s.a
if(!b.p(r)||!J.A(b.h(0,r),s.b))return!1}return!0},
G(a,b){var s,r,q,p,o=this
o.eC(t.k.a(a),t.h.a(b))
if(o.e.length===0){o.Y(0)
return}s=o.a
if(s instanceof A.aP&&A.zp(o.gA(),s.gA())>0){o.qb(s)
return}r=o.P()
if(r.ga6(r)&&o.gA()==="inline"){o.bX()
return}q=o.c
p=!1
if(q instanceof A.aP)if(q.b===o)if(q.gA()===o.gA()){p=t.T
p=A.h(p.a(q.d).a.tagName)===A.h(p.a(o.d).a.tagName)&&o.ot(r,q.P())}if(p){q.b2(o,null)
q.Y(0)}},
aq(){return this.G(null,null)},
qb(a){var s,r,q,p,o,n,m,l,k,j,i,h,g=this,f=null,e=a.a
if(!(e instanceof A.z))return
s=a.gX()
r=A.a5(a.e,!0,t.U)
q=B.a.ae(r,g)
if(q===-1)return
p=B.a.dM(r,0,q)
o=B.a.dL(r,q+1)
n=a.c
for(m=p.length,l=0;l<p.length;p.length===m||(0,A.k)(p),++l)a.aj(p[l])
a.aj(g)
for(m=o.length,l=0;l<o.length;o.length===m||(0,A.k)(o),++l)a.aj(o[l])
k=A.a([],t.E)
m=p.length
if(m!==0){for(l=0;l<p.length;p.length===m||(0,A.k)(p),++l)a.D(p[l],f)
B.a.k(k,a)}m=s.z
j=t.ty
i=j.a(m.a5(a.gA(),f))
g.b2(i,f)
g.D(i,f)
B.a.k(k,g)
if(o.length!==0){h=j.a(m.a5(a.gA(),f))
for(m=o.length,l=0;l<o.length;o.length===m||(0,A.k)(o),++l)h.D(o[l],f)
B.a.k(k,h)}else h=f
e.aj(a)
for(m=k.length,l=0;l<k.length;k.length===m||(0,A.k)(k),++l)e.D(k[l],n)
if(h!=null)h.aq()
if(p.length!==0)a.aq()}}
A.nR.prototype={
$1(a){return a instanceof A.aP||a instanceof A.ap||a instanceof A.cO||a instanceof A.aM},
$S:3}
A.bh.prototype={
gA(){return"scroll"},
gT(){return 5},
a1(){return A.a4(A.aV("Scroll cannot be cloned"))},
hq(){var s=this.db
if(s==null)return
this.seE(null)
if(s.length!==0)this.ad(s)},
bS(a,b){var s,r=this,q=r.ap(a).a,p=r.ap(a),o=r.ap(a+b).a
r.qg(a,b)
if(o!=null&&q!=null&&q!==o&&p.b>0){if(q instanceof A.bt||o instanceof A.bt){r.G(A.a([],t.B),A.b(t.N,t.z))
return}if(q instanceof A.z&&o instanceof A.z){p=o.e
s=p.length===0?null:B.a.gF(p)
q.b2(o,s instanceof A.ap?null:s)
q.Y(0)}}r.G(A.a([],t.B),A.b(t.N,t.z))},
qg(a,b){var s,r,q,p=this
p.by()
if(a===0&&b===p.E(0)){for(s=A.a5(p.e,!0,t.U),r=s.length,q=0;q<r;++q)s[q].Y(0)
return}p.fK(a,b)},
b1(a,b,c,d){this.ci(a,b,c,d)
this.G(A.a([],t.B),A.b(t.N,t.z))},
aL(a,b,c){var s,r,q,p,o,n=this
if(a>=n.E(0)){s=c==null
if(!s){r=n.z
q=r.aw(b,65535)
if(q!=null&&q.b===5){n.D(r.a5(b,c),null)
n.G(A.a([],t.B),A.b(t.N,t.z))
return}}p=n.jE()
n.D(p,null)
o=p.E(0)-1
if(s&&B.b.be(b,"\n"))p.aF(o,B.b.t(b,0,b.length-1))
else p.aL(o,b,c)}else n.eB(a,b,c)
n.G(A.a([],t.B),A.b(t.N,t.z))},
aF(a,b){return this.aL(a,b,null)},
D(a,b){var s,r
if(a.gT()===3){s=this.jE()
r=s.e
s.D(a,r.length!==0?B.a.gK(r):null)
this.aT(s,b)}else this.aT(a,b)},
cW(a){var s,r,q,p=this.du(a,!1)
if(p.length===0)return B.bf
s=B.a.gK(p)
r=s.a
q=s.b
return r instanceof A.aE?new A.F(r,q,t.lB):B.bf},
ap(a){if(a===this.E(0))return this.ap(a-1)
return this.bv(A.JO(),a)},
cA(a,b){return new A.pj().$3(this,a,b)},
tE(){return this.cA(0,2147483647)},
G(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this
t.k.a(a)
t.h.a(b)
if(d.db!=null)return
s=b==null?A.b(t.N,t.z):b
r=a==null?B.Y:a
q=A.a5(r,!0,t.BX)
for(r=d.e,p=t.m,o=t.O,n=t.g,m=t.N,l=t.z,k=t.E,j=100;!0;){i=d.as
d.eC(a,s)
if(r.length===0){$.y().a.a===$&&A.c()
h=self
g=p.a(p.a(h.document).createElement("P"))
f=new A.a0(A.b(m,l),A.a([],k),new A.f(A.b(o,n),g))
f.D(new A.ap(new A.f(A.b(o,n),p.a(p.a(h.document).createElement("BR")))),null)
d.D(f,null)}h=d.Q
e=h==null?null:h.lF()
if(e==null)e=B.Y
B.a.H(q,e)
if(e.length===0&&d.as===i)break
$.zQ=$.zQ+1;--j
if(j<=0)throw A.i(A.aL("[Parchment] Maximum optimize iterations exceeded"))}if(q.length!==0)d.cy.f4("scroll-optimize",q,s)},
aq(){return this.G(null,null)},
du(a,b){var s=this.j9(a,b)
return s.length<=1?s:B.a.dL(s,1)},
Y(a){},
d0(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g=this
t.k.a(a)
t.h.a(b)
s=g.db
if(s!=null){if(a!=null)B.a.H(s,a)
return}if(a==null){s=g.Q
s=s==null?null:s.lF()
r=s}else r=a
if(r==null)r=B.Y
s=A.K(r)
q=s.i("an<1>")
p=A.N(new A.an(r,s.i("x(1)").a(new A.pl(g)),q),!0,q.i("o.E"))
if(p.length===0){s=A.a([],t.B)
g.G(s,b==null?A.b(t.N,t.z):b)
return}s=b==null
o=!s?b.h(0,"source"):"user"
n=s?A.b(t.N,t.z):b
s=g.cy
s.f4("scroll-before-update",o,p)
m=A.b(t.U,t.o)
for(q=p.length,l=t.m,k=0;k<p.length;p.length===q||(0,A.k)(p),++k){j=p[k]
i=g.bx(A.S(l.a(j.a.target)),!0).a
if(i==null)continue
J.j_(m.aQ(i,new A.pm()),j)}q=m.$ti.i("as<1>")
h=A.N(new A.as(m,q),!0,q.i("o.E"))
B.a.iZ(h,new A.pn())
for(q=h.length,k=0;k<h.length;h.length===q||(0,A.k)(h),++k){i=h[k]
if(i!==g&&i.a==null)continue
l=m.h(0,i)
l.toString
i.eV(l,n)
g.p6(i)}s.f4("scroll-update",o,p)
g.G(p,n)},
ad(a){return this.d0(a,null)},
by(){return this.d0(null,null)},
p6(a){var s
for(s=a;s!=null;){if(s instanceof A.a0){s.ch.M(0)
return}s=s.a}},
uz(a,b,c){var s=this.bv(new A.pk(),a).a
if(s!=null)s.gA()},
rS(a){t.f.a(a).a.preventDefault()
return null},
tk(c1,c2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3=this,b4=null,b5="type",b6="block",b7="delta",b8="attributes",b9=t.t,c0=new A.r(A.a([],b9))
c0.aE(0,"\n")
s=b3.rp(c2.bj(c0))
c0=s.length
if(c0===0)return
if(0>=c0)return A.d(s,-1)
r=s.pop()
if(b3.db==null)b3.seE(A.a([],t.B))
if(s.length!==0){q=B.a.cC(s,0)
p=J.A(q.h(0,b5),b6)
if(p)o=t.D.a(q.h(0,b7))
else{o=new A.r(A.a([],b9))
o.aE(0,A.l([A.h(q.h(0,"key")),q.h(0,"value")],t.N,t.z))}n=A.Eh(o)
b9=b3.bv(new A.pg(),c1)
if(p)if(n!==0){b9=b9.a==null&&c1<b3.E(0)
m=b9}else m=!0
else m=!1
A.we(b3,c1,o)
l=p?1:0
k=c1+n+l
if(m)b3.aF(k-1,"\n")
j=A.dG(A.cm(b3.ap(c1).a,!0,b4),t.P.a(q.h(0,b8)))
if(j==null)j=A.b(t.N,t.z)
j.O(0,new A.ph(b3,k))
i=k}else i=c1
h=b3.nR(i)
g=h.a
f=h.b
if(s.length!==0){if(g!=null){g=g.aN(0,f)
f=0}for(b9=s.length,c0=t.G,e=b3.z.a,d=t.m,c=t.O,b=t.g,a=t.N,a0=t.z,a1=t.E,a2=t.D,a3=0;a3<s.length;s.length===b9||(0,A.k)(s),++a3){a4=s[a3]
if(J.A(a4.h(0,b5),b6))b3.r2(A.Y(c0.a(a4.h(0,b8)),a,a0),g,a2.a(a4.h(0,b7)))
else{a5=A.h(a4.h(0,"key"))
a6=a4.h(0,"value")
a7=e.h(0,a5)
if(a7==null)A.a4(A.au('Unknown blot "'+a5+'"',b4))
a5=a7.c.$1(a6)
if(a5.gT()===3){$.y().a.a===$&&A.c()
a6=self
a8=d.a(d.a(a6.document).createElement("P"))
a9=A.b(a,a0)
b0=A.a([],a1)
b1=new A.a0(a9,b0,new A.f(A.b(c,b),a8))
b1.D(new A.ap(new A.f(A.b(c,b),d.a(d.a(a6.document).createElement("BR")))),b4)
a6=b0.length!==0?B.a.gK(b0):b4
a8=b0.length!==0?B.a.gF(b0):b4
b1.aT(a5,a6)
if(a8 instanceof A.ap&&a8.a===b1){a6=a8.a
if(a6!=null)a6.aj(a8)}a9.M(0)
b3.aT(b1,g)}else b3.aT(a5,g)
c0.a(a4.h(0,b8)).O(0,new A.pi(a5))}}}if(J.A(r.h(0,b5),b6)){b2=t.D.a(r.h(0,b7))
if(b2.a.length!==0)A.we(b3,g!=null?b3.aP(g)+f:b3.E(0),b2)}b3.hq()
b3.G(A.a([],t.B),A.b(t.N,t.z))},
nR(a){var s,r,q,p,o,n
for(s=this.e,r=s.length,q=0,p=0;p<s.length;s.length===r||(0,A.k)(s),++p,q=n){o=s[p]
n=q+o.E(0)
if(a<n)return new A.F(o,a-q,t.nv)}return B.be},
rp(a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=null,a0=A.a([],t.cs),a1=t.t,a2=new A.r(A.a([],a1))
for(s=a3.a,r=s.length,q=t.G,p=t.N,o=t.z,n=this.z,m=0;m<s.length;s.length===r||(0,A.k)(s),++m){l=s[m]
k=l.c
if(k==null)continue
if(typeof k=="string"){j=k.split("\n")
for(i=l.d,h=i==null,g=0;g<j.length-1;++g){f=j[g]
if(f.length!==0){if(h)e=a
else e=A.Y(i,p,o)
a2.V(0,f,e)}if(h)e=a
else e=A.Y(i,p,o)
B.a.k(a0,A.l(["type","block","delta",a2,"attributes",e==null?A.b(p,o):e],p,o))
a2=new A.r(A.a([],a1))}d=B.a.gK(j)
if(d.length!==0){if(h)i=a
else i=A.Y(i,p,o)
a2.V(0,d,i)}}else if(q.b(k)){c=J.ek(k.ga7())
if(c==null)continue
b=k.h(0,c)
A.h(c)
if(n.aw(c,2)!=null)a2.b3(l)
else{if(a2.a.length!==0){B.a.k(a0,A.l(["type","block","delta",a2,"attributes",A.b(p,o)],p,o))
a2=new A.r(A.a([],a1))}i=l.d
if(i==null)i=a
else i=A.Y(i,p,o)
B.a.k(a0,A.l(["type","blockEmbed","key",c,"value",b,"attributes",i==null?A.b(p,o):i],p,o))}}}if(a2.a.length!==0)B.a.k(a0,A.l(["type","block","delta",a2,"attributes",A.b(p,o)],p,o))
return a0},
r2(a,b,c){var s,r,q,p,o,n,m,l,k,j={}
t.P.a(a)
j.a=null
s=A.b(t.N,t.z)
r=A.a([],t.s)
a.O(0,new A.pd(j,this,r,s))
q=j.a
p=q==null
o=p?"block":q
q=!p?a.h(0,q):null
n=this.z.a5(o,q)
this.D(n,b)
t.ty.a(n)
q=n.E(0)
if(q===0){for(q=r.length,m=0;m<r.length;r.length===q||(0,A.k)(r),++m){l=r[m]
s.j(0,l,a.h(0,l))}A.we(n,0,c)
k=null}else k=c
s.O(0,new A.pe(n,n.E(0)))
if(k!=null)A.we(n,0,k)
return n},
qN(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this,c=null
for(s=A.a5(t.T.a(d.d).gan(),!0,t.I),r=s.length,q=t.m,p=t.O,o=t.g,n=t.N,m=t.z,l=t.E,k=0;k<r;++k){j=d.fP(s[k])
if(j!=null)if(j.gT()===3){$.y().a.a===$&&A.c()
i=self
h=q.a(q.a(i.document).createElement("P"))
g=A.b(n,m)
f=A.a([],l)
e=new A.a0(g,f,new A.f(A.b(p,o),h))
e.D(new A.ap(new A.f(A.b(p,o),q.a(q.a(i.document).createElement("BR")))),c)
i=f.length!==0?B.a.gK(f):c
h=f.length!==0?B.a.gF(f):c
e.aT(j,i)
if(h instanceof A.ap&&h.a===e){i=h.a
if(i!=null)i.aj(h)}g.M(0)
d.aT(e,c)}else d.aT(j,c)}},
fP(a){var s,r,q,p,o,n,m,l,k,j=null
if(a instanceof A.bl){s=a.a
if(B.b.R(A.h(s.data)).length===0&&A.h(s.data).length!==0){a.Y(0)
return j}return new A.aM(a)}if(a instanceof A.f){s=this.z
r=a.a
q=A.h(r.className)
p=s.i9(q,65535)
if(p==null)p=s.iH(A.h(r.tagName),65535)
o=p==null?j:p.a
n=s.a5(o==null?"block":o,a)
if(n instanceof A.z)for(s=A.a5(a.gan(),!0,t.I),r=s.length,m=0;m<r;++m){l=s[m]
if(l.n(0,n.f))continue
k=this.fP(l)
if(k!=null)n.D(k,j)}return n}return j},
jE(){var s,r
$.y().a.a===$&&A.c()
s=t.m
r=A.lV(new A.f(A.b(t.O,t.g),s.a(s.a(self.document).createElement("P"))))
r.D(A.ht(),null)
return r},
oR(a,b){var s
t.o.a(a)
s=this.db
if(s!=null)B.a.H(s,a)
else this.ad(a)},
aW(a,b){var s,r,q,p,o=this,n=A.a([],t.E),m=A.a([],t.wV)
if(b===0)for(s=o.du(a,!1),r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q].a
if(p instanceof A.a0)B.a.k(n,p)
else if(p instanceof A.aE)B.a.k(m,p)}else{n=o.cA(a,b)
m=o.rr(a,b,t.at)}s=new A.pf(o)
r=A.aJ(s.$1(n),t.N,t.z)
r.H(0,s.$1(A.a5(m,!0,t.U)))
return r},
nX(a,b){var s,r=t.P
r.a(a)
s=A.b(t.N,t.z)
r.a(b).O(0,new A.pc(a,s))
return s},
seE(a){this.db=t.k.a(a)},
gdl(){return this.cy}}
A.pj.prototype={
$3(a,b,c){var s,r,q,p,o,n,m,l,k,j,i=A.a([],t.E)
for(s=a.e,r=s.length,q=b+c,p=c,o=0,n=0;n<s.length;s.length===r||(0,A.k)(s),++n,o=l){m=s[n]
l=o+m.E(0)
if(l>b&&o<q){k=Math.max(0,b-o)
j=B.f.aA(Math.min(l,q)-Math.max(o,b))
if(m instanceof A.a0||m instanceof A.bt)B.a.k(i,m)
else if(m instanceof A.ay)B.a.H(i,this.$3(m,k,p))
p-=j}if(l>=q)break}return i},
$S:135}
A.pl.prototype={
$1(a){var s=this.a.bx(A.S(t.m.a(t.BX.a(a).a.target)),!0)
return s.a!=null},
$S:33}
A.pm.prototype={
$0(){return A.a([],t.B)},
$S:243}
A.pn.prototype={
$2(a,b){var s=t.U
s.a(a)
return B.d.bi(s.a(b).gl3(),a.gl3())},
$S:154}
A.pk.prototype={
$1(a){return a instanceof A.bt},
$S:9}
A.pg.prototype={
$1(a){return a instanceof A.bt},
$S:9}
A.ph.prototype={
$2(a,b){var s=this.a
s.ci(this.b-1,1,A.h(a),b)
s.G(A.a([],t.B),A.b(t.N,t.z))},
$S:2}
A.pi.prototype={
$2(a,b){this.a.N(A.p(a),b)},
$S:16}
A.pb.prototype={
$2(a,b){var s
A.v(a)
s=t.Q.a(b).b
return a+(s==null?0:s)},
$S:24}
A.pd.prototype={
$2(a,b){var s,r,q=this
A.h(a)
if(q.b.z.aw(a,5)!=null){s=q.a
r=s.a
if(r!=null)B.a.k(q.c,r)
s.a=a}else q.d.j(0,a,b)},
$S:2}
A.pe.prototype={
$2(a,b){this.a.b1(0,this.b,A.h(a),b)},
$S:2}
A.pf.prototype={
$1(a){var s,r,q,p
t.xl.a(a)
if(a.length===0)return A.b(t.N,t.z)
s=A.cm(B.a.gF(a),!0,null)
r=this.a
q=1
while(!0){p=a.length
if(!(q<p&&s.a!==0))break
if(!(q<p))return A.d(a,q)
s=r.nX(A.cm(a[q],!0,null),s);++q}return s},
$S:179}
A.pc.prototype={
$2(a,b){var s,r,q,p=this
A.h(a)
s=p.a.h(0,a)
if(s==null)return
r=J.a3(b)
if(r.n(b,s))p.b.j(0,a,b)
else if(t.j.b(b)){q=p.b
if(!r.v(b,s)){r=A.N(b,!0,t.z)
r.push(s)
q.j(0,a,r)}else q.j(0,a,b)}else p.b.j(0,a,[b,s])},
$S:2}
A.wf.prototype={
$1(a){return a instanceof A.aE},
$S:9}
A.wg.prototype={
$1(a){return a instanceof A.aE},
$S:9}
A.wh.prototype={
$2(a,b){A.h(a)
this.b.b1(this.a.a,this.c,a,b)},
$S:2}
A.aM.prototype={
gA(){return"text"},
gT(){return 3},
E(a){return A.h(t.y.a(this.d).a.data).length},
P(){return B.l},
bY(){return A.h(t.y.a(this.d).a.data)},
eg(a,b){return new A.F(this.d,a,t.Fv)},
G(a,b){var s,r,q,p=this
p.ey(t.k.a(a),t.h.a(b))
s=t.y
r=s.a(p.d).a
if(A.h(r.data).length===0){p.Y(0)
return}q=p.c
if(q instanceof A.aM&&q.b===p){r.data=A.h(r.data)+A.h(s.a(q.d).a.data)
q.Y(0)}},
aL(a,b,c){var s,r,q=this,p=t.y.a(q.d).a,o=A.h(p.data)
if(a<0||a>o.length)throw A.i(A.zo(a,o,"index"))
if(c!=null){s=q.a
if(!(s instanceof A.z))throw A.i(A.au("Cannot insert embed into TextBlot without parent",null))
r=q.aN(0,a)
s.D(q.gX().z.a5(b,c),r)
return}p.data=B.b.t(o,0,a)+b+B.b.L(o,a)},
aF(a,b){return this.aL(a,b,null)},
bS(a,b){var s=t.y.a(this.d).a,r=A.h(s.data)
if(a<0||a+b>r.length)throw A.i(A.aK(a,a,r.length,"index",null))
s.data=B.b.bI(r,a,a+b,"")},
bM(a,b,c){var s,r,q,p,o=this,n=t.y.a(o.d).a,m=A.h(n.data).length
if(!c){if(b<=0)return o
if(b>=m)return o.c}s=B.d.aC(b,0,m)
r=B.b.t(A.h(n.data),0,s)
q=B.b.L(A.h(n.data),s)
n.data=r
$.y().a.a===$&&A.c()
p=new A.aM(new A.bl(t.m.a(new self.Text(q))))
n=o.a
if(n!=null)n.D(p,o.c)
return p},
aN(a,b){return this.bM(0,b,!1)}}
A.vK.prototype={
$1(a){switch(a.h(0,0)){case"&":return"&amp;"
case"<":return"&lt;"
case">":return"&gt;"
case'"':return"&quot;"
default:return"&#39;"}},
$S:18}
A.ja.prototype={
gb_(){return 2},
is(a2,a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
t.c.a(a3)
s=t.s
r=A.a(["{__buffer__}"],s)
q=A.N(a3,!0,t.N)
B.a.H(q,B.am.ga7())
for(p=q.length,o=0;o<q.length;q.length===p||(0,A.k)(q),++o)B.a.k(r,"{"+q[o]+"}")
for(p=this.a,n=p.length,o=0;o<p.length;p.length===n||(0,A.k)(p),++o){m=p[o]
l=this.ft(m)
j=m.a
k=j.a
i=l.a===k
h=l
g=""
while(!0){if(!(h!=null)){k=g
break}f=h.f
e=h.b
g+=f?e:h.d.b7(e)
h.r=3
if(h.a===k||i){k=g
break}h=h.bp()}d=A.a([k.charCodeAt(0)==0?k:k],s)
for(k=q.length,i=m.c,c=0;c<q.length;q.length===k||(0,A.k)(q),++c){b=q[c]
a=i.p(b)?i.h(0,b):null
if(B.am.p(b))B.a.k(d,B.am.h(0,b).$3(a,m,b).B(0))
else B.a.k(d,J.L(a))}for(a0=a2,a1=0;a1<r.length;++a1){k=r[a1]
if(!(a1<d.length))return A.d(d,a1)
i=d[a1]
a0=A.O(a0,k,i)}j.y=a0+"\n"
j.r=3}},
lV(a){return this.is(a,B.i)},
ft(a){var s,r,q,p=a.a,o=p.c9()
for(s=p;o!=null;){if(o===p){o=o.c9()
continue}r=!0
if(!o.w)if(!o.x)r=A.mR(o.b)&&!o.e
if(r)break
q=o.c9()
s=o
o=q}return s}}
A.jO.prototype={
gb_(){return 1},
bK(a,b){a.b=b
a.r=3
a.f=a.e=!0
this.fh(a)},
bH(a){var s,r,q,p,o,n,m
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q].a
o=p.bf(new A.nS())
if(o==null)throw A.i(A.hF("Unable to find a next element. Invalid DELTA on '"+p.bt()+"'. Maybe your delta code does not end with a newline?"))
n=p.f
m=p.b
n=n?m:p.d.b7(m)
o.z.j(0,p.a,n)}}}
A.nS.prototype={
$1(a){return!a.e},
$S:39}
A.mQ.prototype={
aJ(a){var s=this.e.h(0,a.gb_())
s.toString
s=s.h(0,a.glw())
s.toString
s.j(0,A.iW(a),a)},
md(){return this.c},
iA(a){var s
if(a>=0&&a<this.d.length){s=this.d
if(!(a>=0&&a<s.length))return A.d(s,a)
s=s[a]}else s=null
return s},
pJ(a8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5=this,a6="<!-- <![CDATA[NEWLINE]]> -->",a7=A.a([],t.Bv)
for(s=J.U(a8),r=t.S,q=t.N,p=t.s,o=t.h,n=t.G,m=t.z,l=0;s.l();){k=s.gq()
if(!n.b(k)||!k.p("insert"))continue
j=J.aO(k)
i=a5.qc(j.h(k,"insert"))
h=o.a(j.h(k,"attributes"))
if(h==null)h=A.b(q,m)
if(typeof i=="string"&&i===a6){j=A.a([],p)
B.a.k(a7,new A.cQ(l,"",h,a5,!0,!0,A.b(r,q),j));++l
continue}g=a5.ps(i)
f=a5.q9(g)
j=f===g
e=!j
d=B.b.v(g,a6)
c=f.split(a6)
b=c.length
for(a=0;a<b;){a0=c[a];++a
a1=a===b
a2=a1&&e
if(d)a3=!(a1&&j)
else a3=!1
a4=A.a([],p)
B.a.k(a7,new A.cQ(l,a0,h,a5,a2,a3,A.b(r,q),a4));++l}}return a7},
qc(a){if(typeof a=="string")return A.O(a,"\n","<!-- <![CDATA[NEWLINE]]> -->")
return a},
ps(a){if(typeof a=="string")return a
return B.q.cQ(a,null)},
q9(a){if(B.b.be(a,"<!-- <![CDATA[NEWLINE]]> -->"))return B.b.t(a,0,a.length-28)
return a},
kf(a,b){var s,r,q
for(s=this.e.h(0,b).gak(),r=A.u(s),s=new A.aS(J.U(s.a),s.b,r.i("aS<1,2>")),r=r.y[1];s.l();){q=s.a
for(q=(q==null?r.a(q):q).gak(),q=q.gJ(q);q.l();)q.gq().aH(a)}},
kj(a){var s,r,q
for(s=this.e.h(0,a).gak(),r=A.u(s),s=new A.aS(J.U(s.a),s.b,r.i("aS<1,2>")),r=r.y[1];s.l();){q=s.a
for(q=(q==null?r.a(q):q).gak(),q=q.gJ(q);q.l();)q.gq().bH(this)}},
uf(){var s,r,q,p,o,n=this
n.spc(n.pJ(n.md()))
for(s=n.d,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q]
n.kf(p,1)
n.kf(p,2)}n.kj(1)
n.kj(2)
for(s=n.d,r=s.length,q=0,o="";q<r;++q)o+=s[q].y
return o.charCodeAt(0)==0?o:o},
b7(a){var s=A.O(a,"&","&amp;")
s=A.O(s,"<","&lt;")
s=A.O(s,">","&gt;")
s=A.O(s,'"',"&quot;")
return A.O(s,"'","&#39;")},
spc(a){this.d=t.xd.a(a)}}
A.cQ.prototype={
bt(){var s=this.f,r=this.b
return s?r:this.d.b7(r)},
iu(a,b){var s=this.c
return s.p(a)?s.h(0,a):b},
u(a){return this.iu(a,null)},
hV(a){var s
if(!A.mR(this.b))return null
s=B.q.hx(this.b,null)
return t.G.b(s)&&s.p(a)?J.ej(s,a):null},
lB(){var s,r,q,p,o=this.z,n=A.u(o).i("as<1>"),m=A.N(new A.as(o,n),!0,n.i("o.E"))
B.a.mD(m)
s=A.xk(t.N)
r=new A.a_("")
for(n=m.length,q=0;q<m.length;m.length===n||(0,A.k)(m),++q){p=o.h(0,m[q])
if(p==null)continue
if(s.k(0,p))r.a+=p}o=r.a
return o.charCodeAt(0)==0?o:o},
pb(a,b,c){var s,r,q,p
t.EU.a(b)
t.Ac.a(c)
s=a.a
for(r=this.d;!0;){s=b.$1(s)
if(s>=0&&s<r.d.length){q=r.d
if(s>>>0!==s||s>=q.length)return A.d(q,s)
p=q[s]}else p=null
if(p==null)return null
if(A.ac(c.$1(p)))return p}},
bf(a){var s=this
t.fz.a(a)
if(a==null)return s.d.iA(s.a+1)
return s.pb(s,new A.oa(),a)},
bp(){return this.bf(null)},
c9(){var s=this.d.iA(this.a-1)
return s},
lU(a){var s,r,q,p,o
t.Ac.a(a)
s=this.a+1
for(r=this.d;!0;){q=r.d
p=q.length
if(s<p){if(!(s<p))return A.d(q,s)
o=q[s]}else o=null
if(o==null)break
if(!A.ac(a.$1(o)))break;++s}},
gc4(){return this.a}}
A.oa.prototype={
$1(a){return a+1},
$S:71}
A.az.prototype={
glw(){return 1},
c8(a,b){var s
t.P.a(b)
a.r=2
A.bj(A.iW(this).a,null)
s=this.a
B.a.k(s,new A.cz(a,this,b,s.length))},
fh(a){return this.c8(a,B.l)},
bH(a){}}
A.j1.prototype={
aH(a){var s
if(a.r===3)return
if(a.u("table")!=null)return
if(a.u("list")!=null)return
s=a.u("align")
if(typeof s=="string"&&B.a.v(this.c,s)){this.c8(a,A.l(["alignment",s],t.N,t.z))
a.r=3}},
bH(a){var s,r,q,p,o,n,m="alignment"
for(s=this.a,r=s.length,q=this.c,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p].c
n=o.p(m)?o.h(0,m):null
if(typeof n!="string"||!B.a.v(q,n))throw A.i(A.hF('An unknown alignment "'+A.p(n)+'" has been detected.'))}this.is('<p style="text-align: {alignment};">{__buffer__}</p>',A.a(["alignment"],t.s))}}
A.j7.prototype={
aH(a){var s,r,q=a.u("background")
if(typeof q=="string"&&q.length!==0){s=a.d.b7(q)
r=a.bt()
this.bK(a,'<span style="background-color:'+s+'">'+r+"</span>")}}}
A.jb.prototype={
aH(a){if(a.u("blockquote")!=null){this.fh(a)
a.r=3}},
bH(a){this.lV("<blockquote>{__buffer__}</blockquote>")}}
A.jc.prototype={
aH(a){if(a.u("bold")!=null)this.bK(a,"<strong>"+a.bt()+"</strong>")}}
A.jh.prototype={
aH(a){if(a.u("code-block")!=null){this.fh(a)
a.r=3}},
bH(a){this.lV("<pre><code>{__buffer__}</code></pre>")}}
A.ji.prototype={
aH(a){var s,r,q=a.u("color")
if(typeof q=="string"&&q.length!==0){s=a.d.b7(q)
r=a.bt()
this.bK(a,'<span style="color:'+s+'">'+r+"</span>")}}}
A.jA.prototype={
aH(a){var s=a.u("font")
if(typeof s=="string"&&s.length!==0)this.bK(a,this.qJ(s,a))},
qJ(a,b){return'<span style="font-family: '+b.d.b7(a)+';">'+b.bt()+"</span>"}}
A.jD.prototype={
aH(a){var s=a.hV("headerImage")
if(s!=null){this.c8(a,A.l(["url",s],t.N,t.z))
a.r=3}},
bH(a){var s,r,q,p,o=this.a,n=o.length
if(n===0)return
for(s=0;s<o.length;o.length===n||(0,A.k)(o),++s){r=o[s]
q=r.c
q=q.p("url")?q.h(0,"url"):null
p=q==null?null:J.L(q)
if(p==null)p=""
if(p.length!==0){q=r.a
q.y='<div class="ql-header-image" ><img src="'+a.b7(p)+'" style="height: 60px;" alt="Cabe\xe7alho"></div>'
q.r=3}}}}
A.jE.prototype={
aH(a){var s=a.u("header")
if(s!=null){this.c8(a,A.l(["heading",s],t.N,t.z))
a.r=3}},
bH(a){var s,r,q,p,o,n
for(s=this.a,r=s.length,q=this.c,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p].c
n=o.p("heading")?o.h(0,"heading"):null
if(!A.cI(n)||!B.a.v(q,n))throw A.i(A.hF('An unknown heading level "'+A.p(n)+'" has been detected.'))}this.is("<h{heading}>{__buffer__}</h{heading}>",A.a(["heading"],t.s))}}
A.jM.prototype={
aH(a){var s,r,q,p,o,n,m=a.hV("image")
if(m!=null){s=a.u("width")
r=s!=null?'width="'+a.d.b7(J.L(s))+'"':""
q=a.u("height")
p=q!=null?'height="'+a.d.b7(J.L(q))+'"':""
o=a.d.b7(J.L(m))
o=A.O('<img src="{src}" {width} {height} alt="" class="img-responsive img-fluid" />',"{src}",o)
o=A.O(o,"{width}",r)
n=A.O(o,"{height}",p)
o=A.D("\\s+",!0,!1)
this.bK(a,A.O(n,o," "))}}}
A.jS.prototype={
aH(a){if(a.u("italic")!=null)this.bK(a,"<em>"+a.bt()+"</em>")}}
A.k_.prototype={
aH(a){var s,r,q,p="link",o={},n=a.u(p)
if(n!=null){s=t.N
r=A.b(s,s)
s=a.c9()
if(!J.A(s==null?null:s.u(p),n)){s=""+'<a href="{link}" target="_blank">'
r.j(0,"{link}",a.d.b7(J.L(n)))}else s=""
s+="{text}"
r.j(0,"{text}",a.bt())
q=a.bp()
if(!J.A(q==null?null:q.u(p),n))s+="</a>"
o.a=s.charCodeAt(0)==0?s:s
r.O(0,new A.ob(o))
this.bK(a,o.a)}}}
A.ob.prototype={
$2(a,b){var s,r
A.h(a)
A.h(b)
s=this.a
r=s.a
s.a=A.O(r,a,b)},
$S:29}
A.k0.prototype={
aH(a){var s=a.u("list")
if(s!=null){this.c8(a,A.l(["type",s],t.N,t.z))
a.r=3}},
bH(a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3="type"
for(s=this.a,r=s.length,q=t.s,p=t.G,o=!1,n=null,m=0;m<s.length;s.length===r||(0,A.k)(s),++m,n=b){l={}
k=s[m]
j=this.ft(k)
i=j.b.length===0&&j.z.a===0
h=""
if(!i){for(g=k.a.a,f=j;f!=null;){e=f.f
d=f.b
h+=e?d:f.d.b7(d)
f.r=3
if(f.a===g)break
f=f.bp()}i=!1}l.a=!1
g=k.a
g.lU(new A.oh(l))
c=l.a
b=this.ou(k)
if(o&&n!=null&&n!==b){e=""+("</"+A.p(n)+">\n")
o=!1}else e=""
d=k.c
a=d.p(a3)?d.h(0,a3):null
a0=A.h(p.b(a)?a.h(0,a3):J.L(a))
a1=B.a.v(A.a(["checked","unchecked"],q),a0)
if(!o){e+="<"+b
e=(a1?e+' class="list-unstyled"':e)+">\n"
o=!0}a2=l.b=0
g.lU(new A.oi(l))
d=g.c
if(d.p("indent"))a2=d.h(0,"indent")
if(i)h=e+"<li></li>"
else{e+="<li>"
if(a1){e+='<input type="checkbox" disabled'
if(a0==="checked")e+=" checked"
h=e+("><label>"+(h.charCodeAt(0)==0?h:h)+"</label>")}else h=e+(h.charCodeAt(0)==0?h:h)
e=l.b
A.aF(a2)
if(e>a2)h+="<"+b+">\n"
else if(e<a2){h+="</li></"+b+"></li>\n"
if(a2-e>1)h+="</"+b+"></li>\n"}else h+="</li>\n"}if(c||k.b.a.length-1===k.d){h+="</"+b+">\n"
o=!1}g.y=h.charCodeAt(0)==0?h:h
g.r=3}},
ou(a){var s=this.ow(a)
if(s==="ordered")return"ol"
if(B.a.v(A.a(["bullet","checked","unchecked"],t.s),s))return"ul"
throw A.i(A.hF('The provided list type "'+s+'" is not a known list type (ordered or bullet).'))},
ow(a){var s=a.ls("type")
return A.h(t.G.b(s)?s.h(0,"type"):J.L(s))}}
A.oh.prototype={
$1(a){var s
if(a.u("list")!=null)return!1
s=!0
if(!a.w)if(!a.x)s=A.mR(a.b)&&!a.e
if(s)this.a.a=!0
return!0},
$S:39}
A.oi.prototype={
$1(a){var s=a.iu("indent",0)
if(a.u("list")!=null){this.a.b=A.v(s)
return!1}return!0},
$S:39}
A.kn.prototype={
aH(a){var s,r=a.u("script")
if(r!=null){s=J.L(r)
if(!B.a.v(this.c,s))A.a4(A.hF('An unknown script tag "'+s+'" has been detected.'))
if(s==="super")s="sup"
this.bK(a,"<"+s+">"+a.bt()+"</"+s+">")}}}
A.ko.prototype={
aH(a){var s,r=a.u("size")
if(r==null)return
s=this.pq(r)
if(s.length===0)return
this.bK(a,'<span style="font-size:'+s+';">'+a.bt()+"</span>")},
pq(a){var s,r,q,p=J.L(a),o=B.b.R(p).toLowerCase()
if(o.length===0)return""
s=A.D("^\\d+(\\.\\d+)?(pt|px|em|rem|%)$",!0,!1)
if(s.b.test(o))return o
r=B.b.R(o)
q=A.V(r,null)
if(q==null)q=A.bg(r)
if(q!=null)return A.p(q)+"pt"
return""}}
A.kt.prototype={
aH(a){if(a.u("strike")!=null)this.bK(a,"<del>"+a.bt()+"</del>")}}
A.ku.prototype={
aH(a){var s,r,q,p=a.u("table")
if(p!=null){s=a.c9()
r=s==null
q=r?null:s.bt()
if(q==null)q=""
this.c8(a,A.l(["row",p,"text",q,"align",a.u("align")],t.N,t.z))
if(!r)s.e=!0
if(!r)s.r=3
a.r=3}},
bH(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=null,e={},d=this.a
if(d.length===0)return
s=new A.a_("")
e.a=!1
r=new A.rD(e,s)
for(q=f,p=!1,o=0,n="";o<d.length;++o){m=d[o]
n=m.c
l=n.p("row")?n.h(0,"row"):f
k=l==null?f:J.L(l)
if(k==null)k=""
l=n.p("text")?n.h(0,"text"):f
j=J.L(l==null?"":l)
i=n.p("align")?n.h(0,"align"):f
h=typeof i=="string"&&i.length!==0?' style="text-align:'+A.p(i)+';border:1px solid #000;padding:6px;"':' style="border:1px solid #000;padding:6px;"'
if(!e.a)r.$0()
if(!p){s.a+="<tr>"
q=k
p=!0}else if(q!==k){s.a+="</tr>\n<tr>"
q=k}n="<td"+h+">"+j+"</td>"
n=s.a+=n
m.a.r=3}if(p)s.a=n+"</tr>\n"
new A.rC(e,s).$0()
g=B.a.gK(d)
d=s.a
g.a.y=d.charCodeAt(0)==0?d:d}}
A.rD.prototype={
$0(){this.b.a+='<table style="border-collapse:collapse;width:100%;">\n'
this.a.a=!0},
$S:1}
A.rC.prototype={
$0(){var s=this.a
if(s.a){this.b.a+="</table>\n"
s.a=!1}},
$S:1}
A.kv.prototype={
aH(a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=null,a1=a2.u("table-temporary")
if(a1!=null){this.c8(a2,A.l(["kind","table-start","table",a1],t.N,t.z))
a2.r=3
return}s=a2.u("table-col")
if(s!=null){this.c8(a2,A.l(["kind","col","width",t.G.b(s)?s.h(0,"width"):a0],t.N,t.z))
a2.r=3
return}r=a2.u("table-cell")
if(r==null)return
q=a2.u("table-header")
p=a2.u("table-list")
o=a2.u("table-list-container")
n=a2.u("table-cell-block")
m=n==null?a0:J.L(n)
if(m==null&&t.G.b(q)){n=q.h(0,"cellId")
m=n==null?a0:J.L(n)}if(m==null&&t.G.b(o)){n=o.h(0,"cellId")
m=n==null?a0:J.L(n)}if(m==null)m="line-"+a2.a
l=new A.ql(r,o)
k=a2.c9()
while(!0){n=!1
if(k!=null)if(!k.w)if(!k.x)n=!(A.mR(k.b)&&!k.e)
if(!n)break
k.r=3
k=k.c9()}n=t.G
if(n.b(q)){j=A.V(A.p(q.h(0,"value")),a0)
if(j==null)j=2
i="header"}else{i=p!=null?"list":"p"
j=0}n=n.b(r)
if(n){h=r.h(0,"data-row")
g=h==null?r.h(0,"row"):h}else g=r
h=g==null?a0:J.L(g)
if(h==null)h=""
f=p==null?a0:J.L(p)
e=l.$1("width")
d=l.$1("rowspan")
c=l.$1("colspan")
b=l.$1("style")
if(n){n=r.h(0,"class")
if(n==null)n=r.h(0,"data-class")}else n=a0
a=a2.u("align")
if(a==null){a=a2.c9()
a=a==null?a0:a.u("align")}this.c8(a2,A.l(["kind","cell-block","row",h,"cellId",m,"block",i,"headerLevel",j,"listType",f,"width",e,"rowspan",d,"colspan",c,"style",b,"class",n,"align",a],t.N,t.z))
a2.r=3},
nW(a){var s,r,q,p,o,n=this.ft(a),m=new A.a_("")
for(s=a.a.a,r=n;r!=null;){if(!r.e){q=r.lB()
q=m.a+=q
p=r.f
o=r.b
m.a=q+(p?o:r.d.b7(o))}if(r.a===s)break
r=r.bp()}s=m.a
return s.charCodeAt(0)==0?s:s},
bH(b1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5=null,a6="width",a7="headerLevel",a8="listType",a9={},b0=this.a
if(b0.length===0)return
a9.a=a9.b=null
a9.c=B.t
a9.d=!1
s=A.a([],t.s)
a9.e=a9.f=null
a9.r=a9.w=a9.x=!1
a9.y=null
r=A.a([],t.cs)
q=new A.qx()
p=new A.qq(a9,new A.qy(),s)
o=new A.qs(a9,r)
n=new A.qo(a9,o)
m=new A.qp(a9,p,n)
l=new A.qr(a9,s,r)
k=new A.qu(a9,s,q)
for(j=b0.length,i=t.N,h=t.z,g=t.yq,f=0;f<b0.length;b0.length===j||(0,A.k)(b0),++f){e=b0[f]
d=e.c
c=d.p("kind")?d.h(0,"kind"):a5
b=J.a3(c)
if(b.n(c,"table-start")){if(a9.b!=null){m.$0()
l.$0()}a=g.a(d.p("table")?d.h(0,"table"):a5)
k.$2(a==null?B.t:a,e)
e.a.r=3}else if(b.n(c,"col")){if(a9.b==null)k.$2(B.t,e)
if(!a9.d)B.a.rE(b0,new A.qv(),new A.qw(e))
B.a.k(s,q.$1(d.p(a6)?d.h(0,a6):a5))
e.a.r=3}else if(b.n(c,"cell-block")){if(a9.b==null)k.$2(B.t,e)
p.$0()
if(!a9.w){a9.b.a+="<tbody>\n"
a9.w=!0}a0=A.m(d.p("row")?d.h(0,"row"):a5)
if(a0==null)a0=""
a1=A.m(d.p("cellId")?d.h(0,"cellId"):a5)
if(a1==null)a1=""
if(!a9.x||a9.f!==a0){n.$0()
a9.b.a+="<tr>"
a9.x=!0
a9.f=a0}if(!a9.r||a9.e!==a1){o.$0()
a9.r=!0
a9.e=a1
b=d.p(a6)?d.h(0,a6):a5
a2=d.p("rowspan")?d.h(0,"rowspan"):a5
a3=d.p("colspan")?d.h(0,"colspan"):a5
a4=d.p("style")?d.h(0,"style"):a5
a9.y=A.l(["width",b,"rowspan",a2,"colspan",a3,"style",a4,"class",d.p("class")?d.h(0,"class"):a5],h,h)}b=d.p("block")?d.h(0,"block"):a5
if(b==null)b="p"
a2=d.p(a7)?d.h(0,a7):a5
if(a2==null)a2=0
a3=d.p(a8)?d.h(0,a8):a5
d=d.p("align")?d.h(0,"align"):a5
B.a.k(r,A.l(["block",b,"headerLevel",a2,"listType",a3,"align",d,"text",this.nW(e)],i,h))
e.a.r=3}}if(a9.b!=null){m.$0()
l.$0()}}}
A.ql.prototype={
$1(a){var s=this.a,r=t.G,q=r.b(s)?s.h(0,a):null
if(q!=null)return q
s=this.b
return r.b(s)?s.h(0,a):null},
$S:45}
A.qx.prototype={
$1(a){var s=a==null?null:B.b.R(J.L(a))
if(s==null)s=""
if(s.length===0)return""
return A.bg(s)!=null?s+"px":s},
$S:34}
A.qy.prototype={
$1(a){var s
if(a==null||B.b.R(a).length===0)return null
s=A.D("[a-zA-Z%]+",!0,!1)
return A.bg(B.b.R(A.O(a,s,"")))},
$S:113}
A.qq.prototype={
$0(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=null,a0="width",a1="margin-left",a2=this.a
if(a2.d||a2.b==null)return
a2.d=!0
s=a2.c
r=s.h(0,"data-class")
q=A.ci(r==null?s.h(0,"class"):r)
p=A.ci(s.h(0,"border"))
o=A.ci(s.h(0,"cellspacing"))
n=A.ci(s.h(0,"style"))
n=n==null?a:B.b.R(n)
m=A.JF(n==null?"":n)
if(m.p(a0)){l=this.b.$1(m.h(0,a0))
if(l!=null&&l>600){m.Z(0,a0)
m.j(0,a0,"100%")}}if(m.p(a1))m.Z(0,a1)
r=this.c
if(r.length!==0)m.j(0,"table-layout","fixed")
k=A.ci(A.JZ(m))
j=(q==null?a:q.length!==0)===!0?' class="'+A.p(q)+'"':""
i=(p==null?a:p.length!==0)===!0?' border="'+A.p(p)+'"':""
h=(o==null?a:o.length!==0)===!0?' cellspacing="'+A.p(o)+'"':""
g=A.zY("border-collapse: collapse;",k==null?"":k)
f=a2.b
e="<table"+j+i+h+' style="'+g+'">\n'
e=f.a+=e
d=r.length
if(d!==0){f.a=e+"<colgroup>"
for(c=0;c<r.length;r.length===d||(0,A.k)(r),++c){b=r[c]
f=a2.b
f.toString
e=b.length===0?"<col>":'<col style="width:'+A.p(A.ci(b))+';">'
f.a+=e}a2.b.a+="</colgroup>\n"}},
$S:1}
A.qs.prototype={
$0(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6=null,a7="text",a8={},a9=this.a
if(!a9.r||a9.b==null)return
s=a9.y
if(s==null)s=B.t
r=A.ci(s.h(0,"width"))
q=A.ci(s.h(0,"colspan"))
p=A.ci(s.h(0,"rowspan"))
o=A.ci(s.h(0,"class"))
n=A.ci(s.h(0,"style"))
m=this.b
l=m.length
if(l===1){if(0>=l)return A.d(m,0)
k=J.A(m[0].h(0,"block"),"p")}else k=!1
if(k){if(0>=m.length)return A.d(m,0)
j=A.h(m[0].h(0,a7))
if(0>=m.length)return A.d(m,0)
i=A.ci(m[0].h(0,"align"))
h=(i==null?a6:i.length!==0)===!0?"text-align:"+A.p(i)+";":""}else{g=new A.a_("")
a8.a=null
f=new A.qt(a8,g)
for(l=m.length,e=0;e<m.length;m.length===l||(0,A.k)(m),++e){d=m[e]
i=A.ci(d.h(0,"align"))
c=(i==null?a6:i.length!==0)===!0?' style="text-align:'+A.p(i)+';"':""
switch(d.h(0,"block")){case"list":b=J.A(d.h(0,"listType"),"ordered")?"ordered":"bullet"
if(a8.a!==b){f.$0()
a=b==="ordered"?"<ol>":"<ul>"
g.a+=a
a8.a=b}a="<li"+c+">"+A.p(d.h(0,a7))+"</li>"
g.a+=a
break
case"header":f.$0()
a0=A.v(d.h(0,"headerLevel"))
a=""+(a0<1||a0>6?2:a0)
a="<h"+a+c+">"+A.p(d.h(0,a7))+"</h"+a+">"
g.a+=a
break
default:f.$0()
a="<p"+c+">"+A.p(d.h(0,a7))+"</p>"
g.a+=a}}f.$0()
l=g.a
j=l.charCodeAt(0)==0?l:l
h=""}a1=A.zY("border:1px solid #000;padding:6px;",n==null?"":n)
a2=(r==null?a6:r.length!==0)===!0?' width="'+A.p(r)+'"':""
a3=(q==null?a6:q.length!==0)===!0?' colspan="'+A.p(q)+'"':""
a4=(p==null?a6:p.length!==0)===!0?' rowspan="'+A.p(p)+'"':""
a5=(o==null?a6:o.length!==0)===!0?' class="'+A.p(o)+'"':""
l=a9.b
a="<td"+a2+a3+a4+a5+(' style="'+h+a1+'"')+">"+j+"</td>"
l.a+=a
B.a.M(m)
a9.y=null
a9.r=!1
a9.e=null},
$S:1}
A.qt.prototype={
$0(){var s,r=this.a,q=r.a
if(q!=null){s=this.b
q=q==="ordered"?"</ol>":"</ul>"
s.a+=q
r.a=null}},
$S:1}
A.qo.prototype={
$0(){this.b.$0()
var s=this.a
if(s.x){s.b.a+="</tr>\n"
s.x=!1}},
$S:1}
A.qp.prototype={
$0(){var s=this.a
if(s.b!=null){this.b.$0()
this.c.$0()
if(s.w){s.b.a+="</tbody>\n"
s.w=!1}s.b.a+="</table>\n"}},
$S:1}
A.qr.prototype={
$0(){var s,r=this.a,q=r.a
if(q!=null&&r.b!=null){q=q.a
s=r.b.a
q.y=s.charCodeAt(0)==0?s:s
q.r=3}r.a=r.b=null
r.c=B.t
r.d=!1
B.a.M(this.b)
r.e=r.f=null
r.r=r.w=r.x=!1
r.y=null
B.a.M(this.c)},
$S:1}
A.qu.prototype={
$2(a,b){var s,r,q,p,o=this.a
o.b=new A.a_("")
o.a=b
o.c=a
o.d=!1
s=this.b
B.a.M(s)
r=a.h(0,"col-widths")
if(t.j.b(r))for(q=J.U(r),p=this.c;q.l();)B.a.k(s,p.$1(q.gq()))
o.x=o.w=!1
o.e=o.f=null},
$S:87}
A.qv.prototype={
$1(a){return J.A(t.jG.a(a).ls("kind"),"col")},
$S:88}
A.qw.prototype={
$0(){return this.a},
$S:93}
A.kB.prototype={
glw(){return 2},
aH(a){if(a.r!==3)this.fh(a)},
bH(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e="</p>\n"
for(s=this.a,r=s.length,q=t.s,p=t.c,o=!1,n=0;n<s.length;s.length===r||(0,A.k)(s),++n){m=s[n].a
if(m.r!==3){l=m.c
l=!l.gal(l)&&!m.e}else l=!1
if(l){m.r=3
k=m.bp()
j=m.c9()
i=A.a([],q)
h=!1
if(!o){B.a.k(p.a(i),"<p>")
o=!0}if(m.b.length===0&&m.z.a===0)l="<br>"
else{l=m.lB()
g=m.f
f=m.b
l+=g?f:m.d.b7(f)}B.a.k(i,l)
if(o&&k!=null&&!k.e){B.a.k(p.a(i),e)
o=h}else if(o&&k==null){B.a.k(p.a(i),e)
o=h}else if(o&&j!=null&&j.e&&m.w){B.a.k(p.a(i),e)
o=h}else if(m.b.length===0&&m.z.a===0&&k!=null&&k.r!==3){B.a.k(p.a(i),"</p>\n<p>")
o=!0}else if(o&&m.w){B.a.k(p.a(i),e)
o=h}if(k!=null&&k.e&&!o&&!m.w){B.a.k(p.a(i),"<p>")
o=!0}m.y=B.a.ab(i,"")}}}}
A.kD.prototype={
aH(a){if(a.u("underline")!=null)this.bK(a,"<u>"+a.bt()+"</u>")}}
A.kI.prototype={
aH(a){var s,r,q=a.hV("video")
if(q!=null){s=a.d.b7(J.L(q))
s=A.O('<div class="embed-responsive embed-responsive-16by9"><iframe class="embed-responsive-item" src="{url}" frameborder="0" allow="{allow}" allowfullscreen></iframe></div>\n',"{url}",s)
r=B.a.ab(this.c,"; ")
a.y=A.O(s,"{allow}",r)
a.r=3}}}
A.cz.prototype={
ls(a){var s=this.c
return s.p(a)?s.h(0,a):null}}
A.vt.prototype={
$1(a){return B.b.R(A.h(a)).length!==0},
$S:8}
A.wE.prototype={
$2(a,b){B.a.k(this.a,A.h(a)+": "+A.h(b))},
$S:29}
A.jo.prototype={
qp(){var s=t.T.a(this.a.d)
s.I("compositionstart",this.goG())
s.I("compositionend",new A.mK(this))},
oH(a){var s,r,q,p,o=this
t.f.a(a)
if(o.c)return
s=a.gau()
r=s!=null?o.a.bx(s,!0).a:null
if(r!=null&&!(r instanceof A.fg)){q=o.b
q.e1("composition-before-start",a)
p=o.a
if(p.db==null)p.seE(A.a([],t.B))
q.e1("composition-start",a)
o.c=!0}},
oF(a){var s,r=this
if(!r.c)return
s=r.b
s.e1("composition-before-end",a)
r.a.hq()
s.e1("composition-end",a)
r.c=!1},
gdl(){return this.b},
gcU(){return this.c}}
A.mK.prototype={
$1(a){var s
t.f.a(a)
s=this.a
if(!s.c)return
A.Dq(new A.mJ(s,a),t.jW)},
$S:0}
A.mJ.prototype={
$0(){return this.a.oF(this.b)},
$S:1}
A.nh.prototype={
ad(a){var s=this,r=s.b
s.b=s.ix()
if(a==null||!B.a4.aK(r.c3(a).bs(),s.b.bs()))return r.hD(s.b)
return a},
kI(b6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2=this,b3=null,b4={},b5=b2.a
b5.by()
s=b5.E(0)
if(b5.db==null)b5.seE(A.a([],t.B))
r=b2.k_(b6)
q=new A.r(A.a([],t.t))
b4.a=0
for(p=b2.qt(r.a),o=p.length,n=t.N,m=t.z,l=t.G,k=b5.z,j=t.y,i=0;i<p.length;p.length===o||(0,A.k)(p),++i){h=p[i]
g=b2.k0(h)
f=h.d
if(f==null)f=b3
else f=A.Y(f,n,m)
e=A.Y(f==null?B.t:f,n,m)
f=h.a
d=!1
c=!1
if(f==="insert"){q.a8(g)
b=h.c
if(typeof b=="string"){if(!B.b.be(b,"\n")){f=b4.a
c=s<=f||b2.jn(f)!=null}b5.aF(b4.a,b)
a=b5.ap(b4.a)
a0=a.a
f=A.cm(a0,!0,b3)
a1=A.cR(n,m)
a1.H(0,f)
if(a0 instanceof A.a0){a2=a0.bv(new A.nj(),a.b).a
if(a2!=null){f=A.cR(n,m)
f.H(0,a1)
f.H(0,A.cm(a2,!0,b3))
a3=f}else a3=a1}else a3=a1
e=A.dG(a3,e)
if(e==null)e=A.b(n,m)}else if(l.b(b)&&b.gal(b)){a4=A.h(J.ek(b.ga7()))
a5=k.aw(a4,2)!=null
if(a5){f=b4.a
c=s<=f||b2.jn(f)!=null}else{f=b4.a
if(f>0){a=b5.bv(new A.nk(),f-1)
a2=a.a
a6=a.b
if(a2 instanceof A.aM){a7=A.h(j.a(a2.d).a.data)
f=a7.length
if(!(a6>=f)){if(a6>>>0!==a6||a6>=f)return A.d(a7,a6)
d=a7[a6]!=="\n"}else d=!0}else d=a2 instanceof A.cO&&a2.gT()===3}}b5.aL(b4.a,a4,J.ej(b,a4))
if(a5){a2=b5.bv(new A.nl(),b4.a).a
if(a2!=null){f=A.cm(a2,!0,b3)
a1=A.cR(n,m)
a1.H(0,f)
e=A.dG(a1,e)
if(e==null)e=A.b(n,m)}}}s+=g}else{q.b3(h)
if(f==="retain"){f=h.c
f=l.b(f)&&f.gal(f)}else f=!1
if(f){a8=l.a(h.c)
a4=A.h(J.ek(a8.ga7()))
b5.uz(b4.a,a4,a8.h(0,a4))}}e.O(0,new A.nm(b4,b2,g))
a9=d?1:0
b0=c?1:0
s+=a9+b0
q.a8(a9)
q.aY(b0)
b4.a=b4.a+(g+a9+b0)}for(p=q.a,o=p.length,b1=0,i=0;i<p.length;p.length===o||(0,A.k)(p),++i){h=p[i]
if(h.a==="delete"){l=h.b
b5.bS(b1,l==null?0:l)
continue}b1+=b2.k0(h)}b5.hq()
b5.G(A.a([],t.B),A.b(n,m))
return b2.ad(r)},
k0(a){var s,r=a.a
if(r==="delete"||r==="retain"){r=a.b
return r==null?0:r}s=a.c
return typeof s=="string"?s.length:1},
qt(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=null
t.tU.a(a)
s=A.a([],t.t)
for(r=a.length,q=t.N,p=t.z,o=0;o<a.length;a.length===r||(0,A.k)(a),++o){n=a[o]
m=n.c
if(n.a==="insert"&&typeof m=="string"){l=m.split("\n")
for(k=n.d,j=k==null,i=0;i<l.length;++i){if(i>0){if(j)h=e
else h=A.Y(k,q,p)
B.a.k(s,new A.aZ("insert",1,"\n",h!=null?A.Y(h,q,p):e))}if(!(i<l.length))return A.d(l,i)
h=l[i]
g=h.length
if(g!==0){if(j)f=e
else f=A.Y(k,q,p)
B.a.k(s,new A.aZ("insert",g,h,f!=null?A.Y(f,q,p):e))}}}else B.a.k(s,n)}return s},
jn(a){return this.a.bv(new A.ni(),a).a},
hA(a,b){var s
this.a.bS(a,b)
s=new A.r(A.a([],t.t))
s.a8(a)
s.aY(b)
return this.ad(s)},
rF(a,b,c){var s,r,q
t.P.a(c)
c.O(0,new A.nn(this,b,a))
s=t.N
r=t.z
this.a.G(A.a([],t.B),A.b(s,r))
q=new A.r(A.a([],t.t))
q.a8(a)
if(b>0)q.br(b,A.Y(c,s,r))
return this.ad(q)},
k_(a){var s,r,q,p,o,n,m,l,k,j=A.a([],t.t),i=new A.r(j)
for(s=a.a,r=s.length,q=t.N,p=t.z,o=0;o<s.length;s.length===r||(0,A.k)(s),++o){n=s[o]
m=n.c
if(n.a==="insert"&&typeof m=="string"){l=A.O(m,"\r\n","\n")
l=A.O(l,"\r","\n")
k=n.d
if(k==null)k=null
else k=A.Y(k,q,p)
i.V(0,l,k)}else B.a.k(j,n)}return i},
tt(a,b,c){var s,r
t.h.a(c)
this.a.aF(a,b)
c.O(0,new A.no(this,a,b))
s=new A.r(A.a([],t.t))
s.a8(a)
r=c.a
s.V(0,b,r===0?null:c)
return this.ad(s)},
ix(){var s,r,q,p,o=new A.r(A.a([],t.t))
for(s=this.a.e,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=this.jo(s[q])
if(p.a.length!==0)o=o.bj(p)}if(o.a.length===0)o.aE(0,"\n")
return o},
ep(a,b){var s,r,q,p,o,n=new A.a_("")
for(s=this.b.ew(a,a+b).a,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q]
o=p.c
if(p.a==="insert"&&typeof o=="string")n.a+=o}s=n.a
return s.charCodeAt(0)==0?s:s},
tz(){var s,r=this.a.e,q=r.length
if(q===0)return!0
if(q>1)return!1
s=B.a.gF(r)
if(!(s instanceof A.a0))return!1
r=s.e
q=r.length
if(q>1)return!1
return q!==0&&B.a.gF(r) instanceof A.ap},
jo(a){var s,r,q,p,o,n,m,l=null
if(a instanceof A.a0)return a.l2()
if(a instanceof A.bt){s=t.N
r=t.z
q=A.aJ(A.cm(a,!0,l),s,r)
a.d9()
q.H(0,a.ga9().fo())
p=A.l(["video",A.m(t.T.a(a.d).a.getAttribute("src"))],s,r)
r=new A.r(A.a([],t.t))
r.V(0,p,q.a===0?l:q)
return r}if(a instanceof A.z){o=new A.r(A.a([],t.t))
for(s=a.e,r=s.length,n=0;n<s.length;s.length===r||(0,A.k)(s),++n)o=o.bj(this.jo(s[n]))
return o}if(a instanceof A.aE){m=A.cm(a,!0,l)
p=a.bY()
s=new A.r(A.a([],t.t))
s.V(0,p,m.a===0?l:m)
return s}return new A.r(A.a([],t.t))},
m9(a,b){var s,r,q=this.a,p=q.ap(a),o=p.a,n=p.b
if(o!=null){s=o.E(0)
if(s>=n+b)r=!(n===0&&b===s)
else r=!1
if(r)return A.lo(o,n,b,!0)
return A.lo(q,a,b,!0)}return""}}
A.nj.prototype={
$1(a){return a instanceof A.aE},
$S:9}
A.nk.prototype={
$1(a){return a instanceof A.aE},
$S:9}
A.nl.prototype={
$1(a){return a instanceof A.aE},
$S:9}
A.nm.prototype={
$2(a,b){var s
A.h(a)
s=this.b.a
s.ci(this.a.a,this.c,a,b)
s.G(A.a([],t.B),A.b(t.N,t.z))},
$S:2}
A.ni.prototype={
$1(a){return a instanceof A.bt},
$S:9}
A.nn.prototype={
$2(a,b){var s,r,q,p
A.h(a)
s=this.b
s=s>1?s:1
for(r=this.a.a.cA(this.c,s),q=r.length,p=0;p<r.length;r.length===q||(0,A.k)(r),++p)r[p].N(a,b)},
$S:2}
A.no.prototype={
$2(a,b){var s=this.a.a
s.ci(this.b,this.c.length,A.h(a),b)
s.G(A.a([],t.B),A.b(t.N,t.z))},
$S:2}
A.l9.prototype={
gm(a){return this.c},
gb_(){return this.e}}
A.vC.prototype={
$3(a,b,c){var s=a instanceof A.a0?a.P():B.l,r=A.y0(s.h(0,"indent"))
r=r==null?null:B.f.aA(r)
if(r==null)r=0
B.a.k(this.a,new A.l9(a,b,c,r,s.h(0,"list")))},
$S:22}
A.vD.prototype={
$3(a,b,c){B.a.k(this.a,A.lo(a,b,c,!1))},
$S:22}
A.vJ.prototype={
$1(a){var s,r,q,p,o,n,m,l
t.f.a(a)
for(s=this.a.a_(".ql-container"),r=s.length,q=t.z,p=this.b,o=0;o<s.length;s.length===r||(0,A.k)(s),++o){n=s[o]
m=$.yN().m0(n,q)
if(m==null)continue
l=m.gdl()
if(l instanceof A.jw)l.rL(p,a)}},
$S:0}
A.jw.prototype={
av(a,b){J.j_(this.a.aQ(a,new A.nq()),b)},
lr(a,b){this.av(a,new A.nr(this,a,b))},
e2(a,b,c,d,e){var s,r,q,p,o=this.a.h(0,a)
if(o==null)return
s=A.ze(b,c,d,e)
for(r=A.a5(o,!0,t.BO),q=r.length,p=0;p<q;++p)A.zf(r[p],s)},
f4(a,b,c){return this.e2(a,b,c,B.k,B.k)},
l6(a,b,c,d){return this.e2(a,b,c,d,B.k)},
e1(a,b){return this.e2(a,b,B.k,B.k,B.k)},
i1(a,b,c){J.j_(this.b.aQ(a,new A.np()),new A.eb(b,c))},
rL(a,b){var s,r,q,p,o,n=this.b.h(0,a)
if(n==null)return
b.gau()
for(s=A.a5(n,!0,t.EE),r=s.length,q=0;q<r;++q){p=s[q]
o=[b]
B.a.H(o,B.r)
A.xq(p.b,o,null)}}}
A.nq.prototype={
$0(){return A.a([],t.kt)},
$S:96}
A.nr.prototype={
$4(a,b,c,d){var s,r,q=this.b
t.hh.a(this)
s=this.a.a
r=s.h(0,q)
if(r!=null)J.yT(r,this)
r=s.h(0,q)
r=r==null?null:J.lA(r)
if(r===!0)s.Z(0,q)
A.zf(this.c,A.ze(a,b,c,d))},
$0(){return this.$4(B.k,B.k,B.k,B.k)},
$1(a){return this.$4(a,B.k,B.k,B.k)},
$2(a,b){return this.$4(a,b,B.k,B.k)},
$3(a,b,c){return this.$4(a,b,c,B.k)},
$C:"$4",
$R:0,
$D(){return[B.k,B.k,B.k,B.k]},
$S:102}
A.np.prototype={
$0(){return A.a([],t.aV)},
$S:104}
A.eb.prototype={}
A.ve.prototype={
$2(a,b){return A.zx(t.l.a(a),A.Hr(b))},
$S:105}
A.vf.prototype={
$2(a,b){return A.zj(t.l.a(a),A.Hp(b))},
$S:109}
A.vg.prototype={
$2(a,b){return A.z2(t.l.a(a),A.Ho(b))},
$S:115}
A.vh.prototype={
$2(a,b){return A.zq(t.l.a(a),A.Hq(b))},
$S:121}
A.vi.prototype={
$2(a,b){t.l.a(a)
return A.Am(a,b instanceof A.e2?b:A.xL(b))},
$S:127}
A.vj.prototype={
$2(a,b){t.l.a(a)
return A.Ds(a,b instanceof A.dK?b:A.Dt(b))},
$S:137}
A.vk.prototype={
$2(a,b){t.l.a(a)
return A.Es(a,b instanceof A.fI?b:B.c5)},
$S:144}
A.vl.prototype={
$2(a,b){var s,r
t.l.a(a)
s=b instanceof A.dY?b:A.Eq(b)
r=new A.eE(a,s)
r.nl(a,s)
return r},
$S:147}
A.vm.prototype={
$2(a,b){var s=new A.fM(t.l.a(a),B.fK)
s.oy()
s.oS()
return s},
$S:160}
A.vn.prototype={
$2(a,b){var s
t.l.a(a)
s=$.CG()
$.hz.j(0,"table-embed",s)
return new A.fH(a,b)},
$S:168}
A.vo.prototype={
$2(a,b){return A.D0(t.l.a(a),t.bU.a(b))},
$S:173}
A.vp.prototype={
$2(a,b){return A.Ej(t.l.a(a),t.bU.a(b))},
$S:192}
A.uR.prototype={
$1(a){var s,r
if(a instanceof A.f)return A.lV(a)
$.y().a.a===$&&A.c()
s=t.m
r=A.lV(new A.f(A.b(t.O,t.g),s.a(s.a(self.document).createElement("P"))))
if(r.e.length===0)r.D(A.ht(),null)
return r},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:197}
A.uS.prototype={
$1(a){return a instanceof A.f?new A.ap(a):A.ht()},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:202}
A.uT.prototype={
$1(a){var s
if(a instanceof A.f)s=A.z5(a)
else{$.y().a.a===$&&A.c()
s=t.m
s=A.z5(new A.f(A.b(t.O,t.g),s.a(s.a(self.document).createElement("SPAN"))))}return s},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:208}
A.v3.prototype={
$1(a){return A.Ai(a)},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:211}
A.v7.prototype={
$1(a){var s,r=t.E
if(a instanceof A.f)r=new A.dL(A.a([],r),a)
else{$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("SPAN"))
s=new A.dL(A.a([],r),new A.f(A.b(t.O,t.g),s))
r=s}return r},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:212}
A.v8.prototype={
$1(a){var s,r,q=t.E
if(a instanceof A.f)q=new A.d9(A.a([],q),a)
else{$.y().a.a===$&&A.c()
s=B.a.gF(B.aa)
r=t.m
s=r.a(r.a(self.document).createElement(s))
s=new A.d9(A.a([],q),new A.f(A.b(t.O,t.g),s))
q=s}return q},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:217}
A.v9.prototype={
$1(a){var s,r=t.E
if(a instanceof A.f)r=new A.dn(A.a([],r),a)
else{$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("U"))
s=new A.dn(A.a([],r),new A.f(A.b(t.O,t.g),s))
r=s}return r},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:74}
A.va.prototype={
$1(a){var s,r,q=t.E
if(a instanceof A.f)q=new A.df(A.a([],q),a)
else{$.y().a.a===$&&A.c()
s=B.a.gF(B.ad)
r=t.m
s=r.a(r.a(self.document).createElement(s))
s=new A.df(A.a([],q),new A.f(A.b(t.O,t.g),s))
q=s}return q},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:75}
A.vb.prototype={
$1(a){var s,r
if(a instanceof A.f)s=new A.cw(A.a([],t.E),a)
else{s=a==null?null:J.L(a)
if(s==null)s=""
$.y().a.a===$&&A.c()
r=t.m
r=r.a(r.a(self.document).createElement("A"))
r.setAttribute("href",A.xi(s))
r.setAttribute("rel","noopener noreferrer")
r.setAttribute("target","_blank")
r=new A.cw(A.a([],t.E),new A.f(A.b(t.O,t.g),r))
s=r}return s},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:76}
A.vc.prototype={
$1(a){var s,r=t.E
if(a instanceof A.f)r=new A.dD(A.a([],r),a)
else{$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("CODE"))
s=new A.dD(A.a([],r),new A.f(A.b(t.O,t.g),s))
r=s}return r},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:77}
A.vd.prototype={
$1(a){var s,r,q=t.E
if(a instanceof A.f)q=new A.d7(A.a([],q),a)
else{$.y().a.a===$&&A.c()
s=t.m
r=s.a(s.a(self.document).createElement("DIV"))
s.a(r.classList).add("ql-code-block-container")
r.setAttribute("spellcheck","false")
r=new A.d7(A.a([],q),new A.f(A.b(t.O,t.g),r))
q=r}return q},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:78}
A.uV.prototype={
$1(a){var s=A.m(a.a.getAttribute("data-language"))
return s==null?!0:s},
$S:79}
A.uU.prototype={
$1(a){var s,r
if(a instanceof A.f)s=A.x1(a)
else{$.y().a.a===$&&A.c()
s=t.m
r=s.a(s.a(self.document).createElement("DIV"))
s.a(r.classList).add("ql-code-block")
r=A.x1(new A.f(A.b(t.O,t.g),r))
s=r}return s},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:80}
A.uX.prototype={
$1(a){return!0},
$S:23}
A.uW.prototype={
$1(a){var s,r
if(a instanceof A.f)return A.x_(a)
$.y().a.a===$&&A.c()
s=t.m
r=A.x_(new A.f(A.b(t.O,t.g),s.a(s.a(self.document).createElement("BLOCKQUOTE"))))
if(r.e.length===0)r.D(A.ht(),null)
return r},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:82}
A.uZ.prototype={
$1(a){var s=B.a.ae(B.w,A.h(a.a.tagName).toUpperCase())+1
return s>0?s:null},
$S:83}
A.uY.prototype={
$1(a){var s
if(a instanceof A.f)return A.xa(a)
s=A.xa(A.zi(a))
if(s.e.length===0)s.D(A.ht(),null)
return s},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:84}
A.v_.prototype={
$1(a){return A.m(a.a.getAttribute("data-list"))},
$S:19}
A.v0.prototype={
$1(a){var s,r
if(a instanceof A.f)s=new A.dW(A.a([],t.E),a)
else{$.y().a.a===$&&A.c()
s=J.a3(a)
if(s.n(a,"super"))r="SUP"
else r=s.n(a,"sub")?"SUB":"SPAN"
s=t.m
s=s.a(s.a(self.document).createElement(r))
s=new A.dW(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}return s},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:86}
A.v2.prototype={
$1(a){var s=A.zn(a)
s.cb(0,new A.uQ())
return s},
$S:50}
A.uQ.prototype={
$2(a,b){A.h(a)
A.m(b)
return b==null||b.length===0},
$S:51}
A.v1.prototype={
$1(a){var s
if(a instanceof A.f)return A.zm(a)
if(typeof a!="string")A.a4(A.au("Image value must be a string URL",null))
$.y().a.a===$&&A.c()
s=t.m
s=s.a(s.a(self.document).createElement("IMG"))
s.setAttribute("src",A.JL(a,A.a(["http","https","data"],t.s)))
return A.zm(new A.f(A.b(t.O,t.g),s))},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:89}
A.v4.prototype={
$1(a){var s,r,q,p
if(a instanceof A.f)s=A.zh(a)
else{s=a==null?null:J.L(a)
if(s==null)s=""
$.y().a.a===$&&A.c()
r=t.m
q=r.a(r.a(self.document).createElement("SPAN"))
p=new A.f(A.b(t.O,t.g),q)
r.a(q.classList).add("ql-formula")
p.saf(A.Kl(s,"#f00"))
q.setAttribute("data-value",s)
s=A.zh(p)}return s},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:90}
A.v6.prototype={
$1(a){var s=A.EG(a)
s.cb(0,new A.uP())
return s},
$S:50}
A.uP.prototype={
$2(a,b){A.h(a)
A.m(b)
return b==null||b.length===0},
$S:51}
A.v5.prototype={
$1(a){var s,r,q
if(a instanceof A.f)return new A.bt(a)
s=a==null?null:J.L(a)
if(s==null)s=""
$.y().a.a===$&&A.c()
r=t.m
q=r.a(r.a(self.document).createElement("IFRAME"))
r.a(q.classList).add("ql-video")
q.setAttribute("frameborder","0")
q.setAttribute("allowfullscreen","true")
q.setAttribute("src",A.xi(s))
return new A.bt(new A.f(A.b(t.O,t.g),q))},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:91}
A.oU.prototype={
m0(a,b){var s,r=a.a
A.jz(r)
s=this.a.a.get(r)
return b.b(s)?s:null}}
A.aA.prototype={}
A.ab.prototype={
nh(a0,a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e="keyboard",d="clipboard",c=f.a,b=c.a,a=t.A.a(b.ownerDocument)
a.toString
s=c.gaf()
r=B.b.R(s==null?"":s)
s=t.m
s.a(b.classList).add("ql-container")
c.saf("")
a=s.a(a.createElement("div"))
f.b!==$&&A.ai()
c=f.b=new A.f(A.b(t.O,t.g),a)
s.a(a.classList).add("ql-editor")
a=c.a
s.a(a.classList).add("ql-blank")
s.a(b.appendChild(a))
q=t.N
p=t.z0
o=f.d
p=new A.bh(o,new A.p8(A.b(q,p),A.b(q,p),A.b(q,t.d)),A.a([],t.E),c)
s.a(a.classList).add("ql-editor")
s=$.y().a.rb(p.goQ())
p.Q=s
n={}
n.subtree=!0
n.childList=!0
n.characterData=!0
n.characterDataOldValue=!0
s.a.observe(a,n)
p.qN()
s=t.z
p.G(A.a([],t.B),A.b(q,s))
a.setAttribute("contenteditable","true")
c.I("dragstart",p.grR())
f.c!==$&&A.ai()
f.c=p
a.setAttribute("contenteditable","true")
for(c=$.zL.gak(),a=A.u(c),c=new A.aS(J.U(c.a),c.b,a.i("aS<1,2>")),a=a.y[1],m=p.z;c.l();){l=c.a
m.ia(l==null?a.a(l):l)}for(c=$.zK.gak(),a=A.u(c),c=new A.aS(J.U(c.a),c.b,a.i("aS<1,2>")),a=a.y[1],m=m.c;c.l();){l=c.a
if(l==null)l=a.a(l)
m.j(0,l.a,l)
m.j(0,l.b,l)}c=new A.nh(p,new A.r(A.a([],t.t)))
c.b=c.ix()
f.e!==$&&A.ai()
f.e=c
c=A.Ei(p,o)
f.f!==$&&A.ai()
f.f=c
p=new A.jo(p,o)
p.qp()
f.r!==$&&A.ai()
f.r=p
k=A.H2(a1)
p=t.eH.a(A.Ea(k.a).$2(f,k))
f.w!==$&&A.ai()
f.w=p
j=p.cp(e)
c=j instanceof A.bD?j:A.zx(f,new A.cb(A.b(q,s)))
f.x!==$&&A.ai()
f.x=c
a=p.c
a.j(0,e,c)
i=p.cp(d)
c=i instanceof A.d6?i:A.z2(f,new A.bp(B.r))
f.y!==$&&A.ai()
f.y=c
a.j(0,d,c)
h=p.cp("history")
s=h instanceof A.eu?h:A.zj(f,new A.cu(1000,100,!1))
f.z!==$&&A.ai()
f.z=s
a.j(0,"history",s)
g=p.cp("input")
q=g instanceof A.dM?g:A.zq(f,B.aP)
f.Q!==$&&A.ai()
f.Q=q
a.j(0,"input",q)
p.cp("uiNode")
p.tc()
$.yN().a.j(0,b,f)
A.If()
o.av("editor-change",new A.oY(f))
o.av("scroll-update",new A.oZ(f))
if(r.length!==0)f.fC(c.qY(r+"<p><br></p>","\n"))
c=s.c
c===$&&A.c()
B.a.M(c.a)
B.a.M(c.b)},
eU(a){var s=this.a.a,r=t.m,q=r.a(t.A.a(s.ownerDocument).createElement("div"))
r.a(q.classList).add(a)
r.a(s.appendChild(q))
return new A.f(A.b(t.O,t.g),q)},
fe(a,b,c,d,e){var s,r,q,p,o,n,m,l=this,k="text-change"
t.mE.a(a)
s=l.c
s===$&&A.c()
if(A.m(t.T.a(s.d).a.getAttribute("contenteditable"))!=="true")s=e==="user"
else s=!1
if(s)return new A.r(A.a([],t.t))
if(b!=null||c){s=l.f
s===$&&A.c()
r=s.bb(0)}else r=null
s=l.e
s===$&&A.c()
q=s.b
p=a.$0()
if(r!=null){if(c)o=r.a
else{b.toString
o=b}if(d==null){n=e==="user"
s=r.a
m=p.im(s,n)
r=new A.G(m,Math.max(0,p.im(s+r.b,n)-m))}else if(d!==0)r=A.JR(r,o,d,e)
l.S(r,"silent")}if(p.a.length!==0){if(e!=="silent")l.d.l6(k,p,q,e)
l.d.e2("editor-change",k,p,q,e)}return p},
i2(a,b){return this.fe(a,null,!1,null,b)},
tP(a,b,c){return this.fe(a,null,b,null,c)},
ee(a,b,c,d){return this.fe(a,b,!1,c,d)},
tO(a,b,c){return this.fe(a,b,!1,null,c)},
ad(a){var s,r=this,q=r.c
q===$&&A.c()
q.d0(null,A.l(["source",a],t.N,t.z))
s=r.i2(new A.p7(r),a)
q=r.f
q===$&&A.c()
q.ad(a)
return s},
by(){return this.ad("user")},
ep(a,b){var s,r,q=this.e
q===$&&A.c()
s=q.b
r=A.G6(s)
return s.mf(a,b<=0?B.d.aC(r-a,0,r):b)},
fC(a){return this.i2(new A.p5(this,a),"api")},
aM(a,b){if(a.a.length===0)return new A.r(A.a([],t.t))
return this.tP(new A.p6(this,a),!0,b)},
d1(a){var s
if(a)this.bE()
this.by()
s=this.f
s===$&&A.c()
return s.bb(0)},
aX(){return this.d1(!1)},
e3(a){var s
$.y()
s=this.f
s===$&&A.c()
s.bE()
if(!a)this.b5()
return},
bE(){return this.e3(!1)},
aD(a,b,c){var s,r,q=this,p=q.f
p===$&&A.c()
s=p.bb(0)
if(s==null)return
r=q.c
r===$&&A.c()
if(r.z.aw(a,4)!=null||r.z.bq(a,260)!=null)q.e5(s.a,s.b,a,b,c)
else{r=s.b
if(r===0)p.N(a,b)
else q.f7(s.a,r,a,b,c)}},
ua(a,b,c){return this.ee(new A.p4(this,a,b),a,b,c)},
S(a,b){var s,r,q,p,o=this.c
o===$&&A.c()
s=Math.max(0,o.E(0)-1)
o=a.a
r=Math.max(0,Math.min(o,s))
q=a.b
p=Math.max(r,Math.min(o+q,s))
if(r!==o||p-r!==q)a=new A.G(r,p-r)
$.y()
o=this.f
o===$&&A.c()
o.iR(0,a,b)
if(b!=="silent")this.b5()},
b5(){var s,r,q,p,o,n,m=this.f
m===$&&A.c()
s=m.bb(0)
if(s==null)s=m.d
if(s==null)return
r=m.cd(s.a,s.b)
if(r!=null){m=A.aF(r.h(0,"top"))
q=A.aF(r.h(0,"right"))
p=A.aF(r.h(0,"bottom"))
o=A.aF(r.h(0,"left"))
n=this.b
n===$&&A.c()
A.JN(n,new A.fw(m,q,p,o),B.c4)}},
e5(a,b,c,d,e){return this.ee(new A.p0(this,a,b,c,d),a,0,e)},
f7(a,b,c,d,e){return this.ee(new A.p1(this,a,b,c,d),a,0,e)},
tl(a,b,c,d){return this.tO(new A.p2(this,a,b,c),a,d)},
fc(a,b,c){return this.ee(new A.p3(this,a,b,null),a,b.length,c)},
ro(a,b,c){return this.ee(new A.p_(this,a,b),a,-b,c)},
cd(a,b){var s,r,q,p,o,n,m,l,k,j,i=this,h=i.f
h===$&&A.c()
s=h.cd(a,b)
if(s!=null){r=$.y().a.ce(i.a)
if(r==null)return s
q=A.aF(r.h(0,"top"))
p=A.aF(r.h(0,"left"))
return A.l(["bottom",A.aF(s.h(0,"bottom"))-q,"height",A.aF(s.h(0,"height")),"left",A.aF(s.h(0,"left"))-p,"right",A.aF(s.h(0,"right"))-p,"top",A.aF(s.h(0,"top"))-q,"width",A.aF(s.h(0,"width"))],t.N,t.z)}h=$.y()
o=i.b
o===$&&A.c()
n=h.a.m1(o,a,b)
if(n!=null)return n
h=i.c
h===$&&A.c()
m=h.ap(a).a
if(m==null)return null
l=B.a.ae(h.tE(),m)
if(l===-1)return null
k=l*20
j=o.gdt()
return A.l(["top",k,"bottom",k+20,"left",0,"right",j,"height",20,"width",j],t.N,t.z)},
gct(){return this.a},
gdl(){return this.d}}
A.oX.prototype={
$2(a,b){return A.Ez(a,b)},
$S:92}
A.oY.prototype={
$4(a,b,c,d){var s,r
if(J.A(a,"text-change")){s=this.a
r=s.b
r===$&&A.c()
r=t.m.a(r.a.classList)
s=s.e
s===$&&A.c()
new A.b9(r).el("ql-blank",s.tz())}},
$1(a){return this.$4(a,null,null,null)},
$2(a,b){return this.$4(a,b,null,null)},
$3(a,b,c){return this.$4(a,b,c,null)},
$C:"$4",
$R:1,
$D(){return[null,null,null]},
$S:52}
A.oZ.prototype={
$2(a,b){var s=this.a,r=typeof a=="string"?a:"user"
s.i2(new A.oV(s),r)},
$1(a){return this.$2(a,null)},
$C:"$2",
$R:1,
$D(){return[null]},
$S:94}
A.oV.prototype={
$0(){var s=this.a.e
s===$&&A.c()
return s.ad(null)},
$S:11}
A.p7.prototype={
$0(){var s=this.a.e
s===$&&A.c()
return s.ad(null)},
$S:11}
A.p5.prototype={
$0(){var s,r,q,p,o,n,m=this.a,l=m.c
l===$&&A.c()
s=l.E(0)
m=m.e
m===$&&A.c()
r=m.hA(0,s)
q=m.k_(this.b)
m.a.tk(0,q)
p=new A.r(A.a([],t.t))
p.a8(0)
o=m.ad(p.bj(q))
n=m.hA(l.E(0)-1,1)
return r.c3(o).c3(n)},
$S:11}
A.p6.prototype={
$0(){var s=this.a.e
s===$&&A.c()
return s.kI(this.b)},
$S:11}
A.p4.prototype={
$0(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this.a.e
d===$&&A.c()
s=this.b
r=this.c
q=d.ep(s,r)
p=d.a.ap(s+r)
o=p.a
n=p.b
m=t.t
l=new A.r(A.a([],m))
if(o instanceof A.a0){k=o.E(0)-n
j=o.l2().ew(n,n+k-1)
i=new A.r(A.a([],m))
i.aE(0,"\n")
l=j.bj(i)}else k=0
h=d.b.ew(s,s+(r+k))
g=new A.r(A.a([],m))
g.aE(0,q)
f=h.hD(g.bj(l))
r=new A.r(A.a([],m))
r.a8(s)
e=r.bj(f)
d.kI(e)
return e},
$S:11}
A.p0.prototype={
$0(){var s=this,r=s.a.e
r===$&&A.c()
return r.rF(s.b,s.c,A.l([s.d,s.e],t.N,t.z))},
$S:11}
A.p1.prototype={
$0(){var s,r,q,p,o,n,m,l=this,k=l.a.e
k===$&&A.c()
s=l.b
r=l.c
q=l.d
p=l.e
o=k.a
o.ci(s,r,q,p)
n=t.N
m=t.z
o.G(A.a([],t.B),A.b(n,m))
o=new A.r(A.a([],t.t))
o.a8(s)
o.br(r,A.l([q,p],n,m))
return k.ad(o)},
$S:11}
A.p2.prototype={
$0(){var s,r,q,p,o=this,n=o.a.e
n===$&&A.c()
s=o.b
r=o.c
q=o.d
n.a.aL(s,r,q)
p=new A.r(A.a([],t.t))
p.a8(s)
p.aE(0,A.l([r,q],t.N,t.z))
return n.ad(p)},
$S:11}
A.p3.prototype={
$0(){var s=this.a.e
s===$&&A.c()
return s.tt(this.b,this.c,A.b(t.N,t.z))},
$S:11}
A.p_.prototype={
$0(){var s,r,q=this.a.e
q===$&&A.c()
s=this.b
r=this.c
q.hA(s,r)
q=new A.r(A.a([],t.t))
q.a8(s)
q.aY(r)
return q},
$S:11}
A.uC.prototype={
$2(a,b){var s
A.v(a)
s=t.Q.a(b).b
return a+(s==null?0:s)},
$S:24}
A.G.prototype={
gc4(){return this.a},
gm(a){return this.b}}
A.fu.prototype={}
A.op.prototype={}
A.wD.prototype={
$1(a){var s,r=this.a
if(a>=r)s=a===r&&this.b==="user"
else s=!0
if(s)return a
s=this.c
if(s>=0)return a+s
return Math.max(r,a+s)},
$S:71}
A.po.prototype={
ni(a,b){var s,r=this
r.e=r.d=B.ja
$.y()
r.oC()
r.oM()
s=r.b
s.i1("selectionchange",null,new A.pz(r))
s.av("scroll-before-update",new A.pA(r))
s.av("scroll-optimize",new A.pB(r))
r.ad("silent")},
oC(){var s=this.b
s.av("composition-before-start",new A.pv(this))
s.av("composition-end",new A.pw(this))},
oM(){var s=this.b
s.i1("mousedown",null,new A.px(this))
s.i1("mouseup",null,new A.py(this))},
bb(a){$.y()
return this.iD().a},
iD(){$.y()
if(t.T.a(this.a.d).gaG()==null)return B.bz
var s=this.dD()
if(s==null)return B.bz
return new A.ao(this.i4(s),s)},
iR(a,b,c){var s,r=this
$.y()
if(b!=null){s=r.u5(b).a
r.eu(s[2],s[3],s[0],s[1],!1)}else r.mw(null)
r.ad(c)},
iQ(a,b){return this.iR(0,b,"api")},
aW(a,b){return this.a.aW(a,b)},
M(a){$.y()
this.iQ(0,null)
return},
dn(){var s=$.y().a.lc(t.T.a(this.a.d))
return s},
bE(){var s,r,q,p,o=this,n=$.y()
if(o.dn())return
s=t.T.a(o.a.d)
r=s.a
q=B.f.ah(A.a9(r.scrollTop))
n.a.l9(s)
r.scrollTop=q
p=o.d
if(p!=null)o.iQ(0,p)},
cd(a,b){var s,r,q,p,o,n,m,l,k,j,i,h=null,g=this.a,f=g.E(0)-1
a=Math.min(a,f)
b=Math.min(a+b,f)-a
s=g.cW(a)
r=s.a
q=s.b
if(r==null)return h
f=b>0
if(f&&q===r.E(0)){p=a+1
o=g.cW(p).a
if(o!=null&&J.A(g.ap(a).a,g.ap(p).a)){r=o
q=0}}n=r.eg(q,!0)
if(f){s=g.cW(a+b)
r=s.a
if(r==null)return h
m=r.eg(s.b,!0)
return $.y().a.iC(n.a,n.b,m.a,m.b)}g=n.a
if(!(g instanceof A.bl)&&r.d instanceof A.f){l=$.y().a.ce(t.T.a(r.d))
if(l==null)return h
g=n.b
if(typeof g!=="number")return g.dE()
k=A.aF(l.h(0,g>0?"right":"left"))
j=A.aF(l.h(0,"top"))
i=A.aF(l.h(0,"height"))
return A.l(["bottom",j+i,"height",i,"left",k,"right",k,"top",j,"width",0],t.N,t.z)}f=n.b
return $.y().a.iC(g,f,g,f)},
oj(a){var s=this,r=s.x
if(r==null){r=t.zs.a(a.z.a5("cursor",null))
r.scU(new A.ps(s))
r.stS(new A.pt(s))
s.x=r}return r},
N(a,b){$.y()
this.os(a,b)
return},
os(a,b){var s,r,q,p,o,n,m,l=this,k=l.a
k.by()
s=l.dD()
if(s==null||!s.c.gdk()||k.z.aw(a,4)!=null)return
r=l.oj(k)
q=s.a
p=q.a
o=r.as
if(!p.n(0,o)){n=k.bx(p,!1).a
if(n==null)return
if(r.a!=null){r.fI(0)
r.a=null}if(n instanceof A.aE){m=n.aN(0,q.b)
q=n.a
if(q!=null)q.D(r,m)}else if(n instanceof A.z)n.D(r,null)}r.N(a,b)
k.G(A.a([],t.B),A.b(t.N,t.z))
l.mx(o,A.h(o.a.data).length)
l.by()},
dD(){var s=$.y(),r=s.a.iB()
if(r==null)return null
return this.i3(r)},
u5(a){var s,r,q=null,p=this.a,o=new A.pD(p,p.E(0)),n=a.a,m=o.$2(n,!1),l=o.$2(n+a.b,!0)
o=m==null
n=o?q:m.a
o=o?q:m.b
if(o==null)o=-1
s=l==null
r=s?q:l.a
s=s?q:l.b
return new A.h8([r,s==null?-1:s,n,o])},
eu(a,b,c,d,e){var s,r,q,p,o,n,m,l,k,j,i=this,h=$.y()
if(c==null)c=a
if(d==null)d=b
s=a!=null
if(s)r=t.T.a(i.a.d).gaG()==null||a.gaG()==null||c.gaG()==null
else r=!1
if(r)return
if(s){s=b==null
if((s?0:b)>=0)r=(d==null?0:d)<0
else r=!0
if(r)return
if(!i.dn()){r=t.T.a(i.a.d)
q=r.a
p=B.f.ah(A.a9(q.scrollTop))
h.a.l9(r)
q.scrollTop=p}r=i.dD()
o=r==null?null:r.c
if(o==null||!a.n(0,o.a)||b!==o.b||!J.A(c,o.c)||d!==o.d){n=s?0:b
if(a instanceof A.f&&A.h(a.a.tagName)==="BR"){m=a.gaG()
if(m!=null){n=B.a.ae(m.gan(),a)
l=m}else l=a}else l=a
c.toString
k=d==null?0:d
if(c instanceof A.f&&A.h(c.a.tagName)==="BR"){m=c.gaG()
if(m!=null){k=B.a.ae(m.gan(),c)
j=m}else j=c}else j=c
h.a.iU(l,n,j,k)}}else{s=t.A.a(t.m.a(self.window).getSelection())
if(s!=null)s.removeAllRanges()
h.a.kM(t.T.a(i.a.d))}},
mw(a){return this.eu(a,null,null,null,!1)},
es(a,b,c,d){return this.eu(a,b,c,d,!1)},
mx(a,b){return this.eu(a,b,null,null,!1)},
ad(a){var s,r,q,p,o,n,m,l,k=this,j="selection-change"
$.y()
s=k.e
r=k.iD()
q=k.c=k.e=r.a
if(q!=null)k.d=q
if(!k.q3(s,q)){p=r.b
q=!1
if(!k.r)if(p!=null)if(p.c.gdk()){q=p.a
o=k.x
o=o==null?null:o.as
o=!q.a.n(0,o)
q=o}if(q){q=k.x
n=q==null?null:q.ie()
if(n!=null){q=n.a
o=n.b
m=n.c
if(m==null)m=q
l=n.d
k.es(q,o,m,l==null?o:l)}}q=k.b
q.e2("editor-change",j,k.e,s,a)
if(a!=="silent")q.l6(j,k.e,s,a)}},
by(){return this.ad("user")},
i3(a){var s,r=t.T.a(this.a.d),q=a.a
if(r.v(0,q))s=!a.gdk()&&!r.v(0,a.c)
else s=!0
if(s)return null
s=new A.pC()
return new A.op(s.$2(q,a.b),s.$2(a.c,a.d),a)},
i4(a){var s,r,q,p,o,n,m,l,k,j,i,h,g=A.a([a.a],t.g9)
if(!a.c.gdk())B.a.k(g,a.b)
s=A.a([],t.X)
for(r=g.length,q=this.a,p=0;p<g.length;g.length===r||(0,A.k)(g),++p){o=g[p]
n=o.a
m=q.bx(n,!0).a
if(m==null)return null
l=q.aP(m)
k=o.b
if(k===0)B.a.k(s,l)
else if(m instanceof A.aE)B.a.k(s,l+m.dr(n,k))
else B.a.k(s,l+m.E(0))}j=Math.max(0,q.E(0)-1)
i=J.yQ(B.a.lz(s,B.bT),0,j)
h=J.yQ(B.a.lz(s,B.bU),0,i)
return new A.G(h,i-h)},
q3(a,b){if(a==b)return!0
if(a==null||b==null)return!1
return a.a===b.a&&a.b===b.b},
gdl(){return this.b}}
A.pz.prototype={
$1(a){var s
t.f.a(a)
s=this.a
if(!s.w&&!s.r)A.rF(B.aL,new A.pr(s))},
$S:47}
A.pr.prototype={
$0(){return this.a.ad("user")},
$S:1}
A.pA.prototype={
$1(a){var s,r,q,p=this.a
if(!p.dn())return
s=p.dD()
if(s==null)return
r=s.a
q=p.x
q=q==null?null:q.as
if(r.a.n(0,q))return
p.b.lr("scroll-update",new A.pq(p,s))},
$S:17}
A.pq.prototype={
$2(a,b){var s,r,q,p,o,n,m,l
try{q=this.a
p=t.T.a(q.a.d)
o=this.b
n=o.a
m=n.a
if(p.v(0,m)&&p.v(0,o.b.a)){p=o.b
q.es(m,n.b,p.a,p.b)}s=t.j.b(b)?b:B.r
r=J.j0(s,new A.pp(q))
if(A.ac(r))p="silent"
else p=typeof a=="string"?a:"user"
q.ad(p)}catch(l){}},
$S:32}
A.pp.prototype={
$1(a){var s,r
if(a instanceof A.fk){s=a.a
r=!0
if(A.h(s.type)!=="characterData")if(A.h(s.type)!=="childList")s=A.h(s.type)==="attributes"&&A.S(t.m.a(s.target)).n(0,t.T.a(this.a.a.d))
else s=r
else s=r}else s=!1
return s},
$S:9}
A.pB.prototype={
$2(a,b){var s,r,q,p,o,n
if(t.G.b(b)&&b.h(0,"range") instanceof A.d8){s=t.Ed.a(J.ej(b,"range"))
r=this.a
q=s.a
p=s.b
o=s.c
if(o==null)o=q
n=s.d
r.es(q,p,o,n==null?p:n)
r.ad("silent")}},
$S:32}
A.pv.prototype={
$0(){this.a.r=!0},
$S:21}
A.pw.prototype={
$0(){var s,r=this.a,q=r.r=!1,p=r.x
if(p!=null?p.a!=null:q){s=p.ie()
if(s==null)return
A.rF(B.aL,new A.pu(r,s))}},
$S:21}
A.pu.prototype={
$0(){var s=this.b,r=s.a,q=s.b,p=s.c
if(p==null)p=r
s=s.d
if(s==null)s=q
this.a.es(r,q,p,s)},
$S:1}
A.px.prototype={
$1(a){t.f.a(a)
this.a.w=!0},
$S:47}
A.py.prototype={
$1(a){var s
t.f.a(a)
s=this.a
s.w=!1
s.ad("user")},
$S:47}
A.ps.prototype={
$0(){return this.a.r},
$S:98}
A.pt.prototype={
$0(){var s,r,q=this.a.dD()
if(q==null)return null
s=q.a
r=q.b
return new A.h8([r.a,r.b,s.a,s.b])},
$S:99}
A.pD.prototype={
$2(a,b){var s=this.a.cW(Math.max(0,Math.min(this.b-1,a))),r=s.a
if(r==null)return null
return r.eg(s.b,b)},
$S:100}
A.pC.prototype={
$2(a,b){var s,r=t.A,q=b,p=a
while(!0){if(!(!(p instanceof A.bl)&&p.gan().length!==0))break
if(p.gan().length>q){s=p.gan()
if(!(q>=0&&q<s.length))return A.d(s,q)
p=s[q]
q=0}else{if(p.gan().length===q){s=p.a
if(r.a(s.lastChild)==null)s=null
else{s=r.a(s.lastChild)
s.toString
s=A.S(s)}s.toString
if(s instanceof A.bl)q=A.h(s.a.data).length
else q=s.gan().length!==0?s.gan().length:s.gan().length+1}else break
p=s}}return new A.fu(p,q)},
$S:101}
A.kh.prototype={
bA(){return"QuillIconTheme."+this.b}}
A.cG.prototype={}
A.ck.prototype={
h5(){var s=this,r=t.N
s.dd(".ql-editor",A.l(["box-sizing","border-box","line-height","1.42","height","100%","outline","none","overflow-y","auto","padding","12px 15px","tab-size","4","text-align","left","white-space","pre-wrap","word-wrap","break-word"],r,r))
s.dd(".ql-editor ol, .ql-editor ul",A.l(["padding-left","1.5em"],r,r))
s.dd(".ql-editor p",A.l(["margin","0","padding","0"],r,r))
s.dd(".ql-editor strong",A.l(["font-weight","bold"],r,r))
s.dd(".ql-editor em",A.l(["font-style","italic"],r,r))
s.dd(".ql-editor pre",A.l(["background-color","#f0f0f0","border-radius","3px","padding","5px","margin","5px 0"],r,r))},
dd(a,b){this.d.j(0,a,t.J.a(b))},
qK(a){this.e.h(0,a)},
tc(){var s=this.b,r=s.a
if(r!=null)this.qK(r)
s.d.O(0,new A.rE(this))},
cp(a){var s,r,q=this.c
if(q.p(a))return q.h(0,a)
s=this.b.d
s=J.A(s.h(0,a),!0)?A.b(t.N,t.z):s.h(0,a)
r=A.Eb(this.a,a,s)
if(r!=null)q.j(0,a,r)
return r}}
A.rE.prototype={
$2(a,b){A.h(a)
if(b==null||J.A(b,!1))return
this.a.cp(a)},
$S:2}
A.fw.prototype={}
A.pa.prototype={}
A.lc.prototype={}
A.wC.prototype={
$1(a){var s=$.y(),r=this.a.a
r.toString
return s.a.dC(r,a)},
$S:6}
A.jv.prototype={}
A.r.prototype={
bs(){var s=A.a5(this.a,!0,t.Q),r=A.K(s),q=r.i("a1<1,B<e,@>>")
return A.N(new A.a1(s,r.i("B<e,@>(1)").a(new A.n6()),q),!0,q.i("ad.E"))},
gm(a){return this.a.length},
h(a,b){var s
A.v(b)
s=this.a
if(!(b>=0&&b<s.length))return A.d(s,b)
return s[b]},
n(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.r))return!1
return B.cF.aK(this.a,b.a)},
ga3(a){return A.xp(this.a)},
br(a,b){t.h.a(b)
if(a===0)return
this.b3(A.bW("retain",a,"",b))},
a8(a){return this.br(a,null)},
V(a,b,c){t.h.a(c)
if(typeof b=="string"&&b.length===0)return
this.b3(A.oz(b,c))},
aE(a,b){return this.V(0,b,null)},
aY(a){if(a===0)return
this.b3(A.bW("delete",a,"",null))},
h8(a){var s,r,q,p,o,n=a.b
n.toString
s=this.a
r=B.a.gK(s).b
r.toString
q=A.h(B.a.gK(s).c)
p=A.h(a.c)
o=s.length
B.a.bI(s,o-1,o,A.a([A.bW(a.a,n+r,q+p,a.ga9())],t.t))},
b3(a){var s,r,q,p,o,n,m=this
if(a.b===0)return
s=m.a
r=s.length
q=r!==0?B.a.gK(s):null
if(q!=null){p=q.a
o=p==="delete"
if(o&&a.a==="delete"){m.h8(a)
return}if(o&&a.a==="insert"){--r
if(r>0){o=r-1
if(!(o<s.length))return A.d(s,o)
n=s[o]}else n=null
if(n==null){B.a.V(s,0,a);++m.b
return}if(n.a==="insert"&&n.f8(a)&&typeof n.c=="string"&&typeof a.c=="string"){p=n.c
p.toString
A.h(p)
o=a.c
o.toString
B.a.j(s,r-1,A.oz(p+A.h(o),a.ga9()));++m.b
return}}if(p==="insert"&&a.a==="insert")if(q.f8(a)&&typeof a.c=="string"&&typeof q.c=="string"){m.h8(a)
return}if(p==="retain"&&a.a==="retain")if(q.f8(a)){m.h8(a)
return}}p=s.length
if(r===p)B.a.k(s,a)
else{if(!(r>=0&&r<p))return A.d(s,r)
B.a.bI(s,r,r+1,A.a([a,s[r]],t.t))}++m.b},
nY(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=null
if(b.gef()==="insert")return b.bp()
if(a.gef()==="delete")return a.bp()
s=Math.min(a.aZ(),b.aZ())
r=a.bf(s)
q=b.bf(s)
if(q.a==="retain"){p=r.a
o=p==="retain"
n=r.ga9()
m=q.ga9()
l=A.bQ(n,!1)
k=A.bQ(m,!1)
j=l.a===0?d:l
i=A.z7(j,k.a===0?d:k,o)
if(o)return A.bW("retain",r.b,"",A.mZ(i,A.Db(n,m,!0)))
else if(p==="insert"){h=A.bQ(m,!0)
g=r.c
if(h.a!==0){f=A.Dc(g,h,!1)
if(f!=null)g=f}e=A.bQ(n,!0)
return A.oz(g,A.mZ(i,e.a===0?d:e))}throw A.i(A.aL("Unreachable"))}else if(r.a==="retain")return q
return d},
c3(a){var s,r=new A.r(A.a([],t.t)),q=new A.c7(this,this.b),p=new A.c7(a,a.b)
while(!0){if(!(q.aZ()<1073741824||p.aZ()<1073741824))break
s=this.nY(q,p)
if(s!=null)r.b3(s)}r.R(0)
return r},
hD(a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=c.a,a=a0.a
if(A.DN(b,a,t.Q))return new A.r(A.a([],t.t))
s=t.tm
r=A.K(b)
q=new A.a1(b,r.i("J?(1)").a(s.a(new A.n_(c,a0))),r.i("a1<1,J?>")).bn(0)
r=A.K(a)
p=new A.a1(a,r.i("J?(1)").a(s.a(new A.n0(c,a0))),r.i("a1<1,J?>")).bn(0)
o=new A.r(A.a([],t.t))
n=A.hj(q,p,!0,null,1)
A.Bz(t.kQ.a(n))
m=new A.c7(c,c.b)
l=new A.c7(a0,a0.b)
k=new A.n1()
for(b=n.length,a=t.N,s=t.z,j=0;j<n.length;n.length===b||(0,A.k)(n),++j){i=n[j]
h=i.b.length
for(;h>0;){switch(i.a){case 1:g=Math.min(l.aZ(),h)
o.b3(l.bf(g))
break
case-1:g=Math.min(h,m.aZ())
m.bf(g)
o.aY(g)
break
case 0:g=Math.min(Math.min(m.aZ(),l.aZ()),h)
f=m.bf(g)
e=l.bf(g)
if(A.ac(k.$2(f.c,e.c))){r=f.d
if(r==null)r=null
else r=A.Y(r,a,s)
d=e.d
if(d==null)d=null
else d=A.Y(d,a,s)
o.br(g,A.dG(r,d))}else{o.b3(e)
o.aY(g)}break
default:g=0}h-=g}}o.R(0)
return o},
qC(a,b,c){var s,r,q,p,o,n,m,l,k=null
if(a.gef()==="insert")s=c||b.gef()!=="insert"
else s=!1
if(s)return A.bW("retain",a.bp().b,"",k)
else if(b.gef()==="insert")return b.bp()
r=Math.min(a.aZ(),b.aZ())
q=a.bf(r)
p=b.bf(r)
if(q.a==="delete")return k
else if(p.a==="delete")return p
else{o=q.ga9()
n=p.ga9()
m=A.bQ(o,!1)
l=A.bQ(n,!1)
s=m.a===0?k:m
return A.bW("retain",r,"",A.mZ(A.z9(s,l.a===0?k:l,c),A.De(o,n,c)))}},
d_(a,b){var s,r=new A.r(A.a([],t.t)),q=new A.c7(this,this.b),p=new A.c7(a,a.b)
while(!0){if(!(q.aZ()<1073741824||p.aZ()<1073741824))break
s=this.qC(q,p,b)
if(s!=null)r.b3(s)}r.R(0)
return r},
R(a){var s,r,q=this.a
if(q.length!==0){s=B.a.gK(q)
if(s.a==="retain"){r=s.d
if(r!=null)r=r.a===0
else r=!0}else r=!1
if(r)B.a.uc(q)}},
bj(a){var s=A.a5(this.a,!0,t.Q),r=new A.r(s),q=a.a
if(q.length!==0){r.b3(B.a.gF(q))
B.a.H(s,B.a.dL(q,1))}return r},
e9(a){var s,r,q,p,o,n,m,l,k,j,i=new A.r(A.a([],t.t))
for(s=this.a,r=s.length,q=t.Q,p=0,o=0;o<s.length;s.length===r||(0,A.k)(s),++o){n=s[o]
m=n.a
if(m==="insert"){m=n.b
m.toString
i.aY(m)}else{l=m==="retain"
if(l){k=n.d
if(k!=null)k=k.a===0
else k=!0}else k=!1
if(k){m=n.b
m.toString
i.a8(m)
p+=m}else{if(m!=="delete")if(l){m=n.d
if(m!=null)m=m.a===0
else m=!0
m=!m}else m=!1
else m=!0
if(m){m=n.b
m.toString
j=p+m
B.a.O(A.a5(a.ew(p,j).a,!0,q),new A.n5(n,i))}else throw A.i(A.aL("Unreachable"))
p=j}}}i.R(0)
return i},
ew(a,b){var s,r,q=new A.r(A.a([],t.t)),p=new A.c7(this,this.b),o=0
while(!0){if(!(o<b&&p.aZ()<1073741824))break
if(o<a)s=p.bf(a-o)
else{s=p.bf(b-o)
q.b3(s)}r=s.b
r.toString
o+=r}return q},
im(a,b){var s,r,q=new A.c7(this,this.b),p=0
while(!0){if(!(q.aZ()<1073741824&&p<=a))break
c$0:{s=q.bp()
r=s.a
if(r==="delete"){r=s.b
r.toString
a-=Math.min(r,a-p)
break c$0}else{if(r==="insert")r=p<a||b
else r=!1
if(r){r=s.b
r.toString
a+=r}}r=s.b
r.toString
p+=r}}return a},
lM(a){return this.im(a,!0)},
B(a){return B.a.ab(this.a,"\n")},
mf(a,b){var s,r,q,p,o,n,m,l,k,j
if(b<=0)return""
s=new A.c7(this,this.b)
r=new A.a_("")
q=b
p=0
while(!0){if(!(s.aZ()<1073741824&&q>0))break
c$0:{o=s.bp()
n=o.b
if(n==null)n=0
if(o.a!=="insert"||typeof o.c!="string"){p+=n
break c$0}m=A.h(o.c)
l=Math.max(a-p,0)
if(l>=n){p+=n
break c$0}k=Math.min(n-l,q)
r.a+=B.b.t(m,l,l+k)
q-=k
p+=n}}j=r.a
return j.charCodeAt(0)==0?j:j}}
A.mW.prototype={
$2(a,b){A.h(a)
if(this.a===$.hz.p(a))this.b.j(0,a,b)},
$S:2}
A.mT.prototype={
$2(a,b){return new A.F(a,A.mS(b),t.AC)},
$S:103}
A.mU.prototype={
$2(a,b){var s=typeof a=="string"?a:J.L(a)
return new A.F(s,A.mS(b),t.dK)},
$S:25}
A.mV.prototype={
$2(a,b){var s,r,q,p
A.h(a)
s=$.hz.h(0,a)
if(s==null)return
this.a.a=!0
r=this.b
q=r.h(0,a)
p=s.a.$3$keepNull(q,b,this.c)
if(p==null)r.Z(0,a)
else r.j(0,a,p)},
$S:2}
A.mX.prototype={
$2(a,b){var s=typeof a=="string"?a:J.L(a)
return new A.F(s,A.mS(b),t.dK)},
$S:25}
A.mY.prototype={
$2(a,b){var s,r,q,p,o
A.h(a)
s=$.hz.h(0,a)
if(s==null)return
r=this.a
q=r.a
p=q!=null&&q.p(a)?r.a.h(0,a):this.b.h(0,a)
o=s.c.$2(b,p)
if(o!=null)this.c.j(0,a,o)},
$S:2}
A.n7.prototype={
$2(a,b){t.P.a(a)
A.h(b)
if(!this.a.p(b))a.j(0,b,this.b.h(0,b))
return a},
$S:56}
A.n3.prototype={
$2(a,b){var s
A.h(b)
s=this.a
if(!J.A(s.b.h(0,b),s.a.h(0,b))&&s.a.p(b))J.yP(a,b,s.b.h(0,b))
return a},
$S:54}
A.n4.prototype={
$2(a,b){var s
t.G.a(a)
A.h(b)
s=this.a
if(!J.A(s.b.h(0,b),s.a.h(0,b))&&!s.b.p(b))a.j(0,b,null)
return a},
$S:106}
A.n2.prototype={
$1(a){return A.DR(t.G.a(a),this.a)},
$S:107}
A.n6.prototype={
$1(a){return t.Q.a(a).bs()},
$S:108}
A.n_.prototype={
$1(a){var s
t.Q.a(a)
if(a.a==="insert"){s=a.c
return typeof s=="string"?s:$.yy()}throw A.i(A.au("diff() call "+(this.a.n(0,this.b)?"on":"with")+" non-document",null))},
$S:57}
A.n0.prototype={
$1(a){var s
t.Q.a(a)
if(a.a==="insert"){s=a.c
return typeof s=="string"?s:$.yy()}throw A.i(A.au("diff() call "+(this.a.n(0,this.b)?"on":"with")+" non-document",null))},
$S:57}
A.n1.prototype={
$2(a,b){return B.c8.aK(a,b)},
$S:26}
A.n5.prototype={
$1(a){var s,r,q,p,o,n,m=null
t.Q.a(a)
s=this.a
r=s.a
if(r==="delete")this.b.b3(a)
else{if(r==="retain"){r=s.d
if(r!=null)r=r.a===0
else r=!0
r=!r}else r=!1
if(r){r=A.bQ(s.ga9(),!1)
if(r.a===0)r=m
q=A.bQ(a.ga9(),!1)
p=A.z8(r,q.a===0?m:q)
o=A.Dd(s.ga9(),a)
s=p.a===0?m:p
n=A.mZ(s,o.a===0?m:o)
s=a.b
s.toString
this.b.br(s,n)}}},
$S:110}
A.c7.prototype={
gef(){var s=this.c,r=this.a.a
if(s<r.length)return r[s].a
else return null},
aZ(){var s=this.c,r=this.a.a
if(s<r.length){s=r[s].b
s.toString
return s-this.d}return 1073741824},
bf(a){var s,r,q,p,o,n,m,l,k=this,j=k.a
if(k.b!==j.b)throw A.i(A.aD(j))
s=k.c
j=j.a
if(s<j.length){j=j[s]
r=j.a
q=j.ga9()
p=k.d
s=j.b
s.toString
s-=p
o=Math.min(s,a)
if(o===s){++k.c
k.d=0}else k.d=p+o
s=r==="insert"&&typeof j.c=="string"
n=j.c
if(s)n=B.b.t(A.h(n),p,p+o)
j=typeof n=="string"
m=!j||n.length!==0
l=j?n.length:1
return A.bW(r,m?l:o,n,q)}return A.bW("retain",a,"",null)},
bp(){return this.bf(1073741824)}}
A.aZ.prototype={
ga9(){var s=this.d
if(s==null)s=null
else s=A.Y(s,t.N,t.z)
return s},
bs(){var s=this,r=s.a,q=A.l([r,r==="insert"?s.c:s.b],t.N,t.z)
if(s.d!=null)q.j(0,"attributes",s.ga9())
return q},
n(a,b){var s=this
if(b==null)return!1
if(s===b)return!0
if(!(b instanceof A.aZ))return!1
return s.a===b.a&&s.b==b.b&&B.a4.aK(s.c,b.c)&&s.f8(b)},
f8(a){var s=this.d,r=s==null?null:s.a===0
if(r!==!1){r=a.d
r=r==null?null:r.a===0
r=r!==!1}else r=!1
if(r)return!0
return B.a4.aK(s,a.d)},
ga3(a){var s,r,q=this,p=q.d,o=p==null
if(!o)s=p.a!==0
else s=!1
if(s){r=A.xp((o?t.P.a(p):p).gao().bU(0,new A.oA(),t.dy))
p=q.a
return A.dU(p,p==="insert"?q.c:q.b,r,B.m)}p=q.a
return A.dU(p,p==="insert"?q.c:q.b,B.m,B.m)},
B(a){var s,r,q=this,p=q.ga9()==null?"":" + "+A.p(q.ga9()),o=q.a
if(o==="insert"){s=q.c
if(typeof s=="string"){s=A.O(s,"\n","\u23ce")
r=s}else{s=J.L(s)
r=s}}else r=A.p(q.b)
return o+"\u27e8 "+r+" \u27e9"+p},
gm(a){return this.b}}
A.oA.prototype={
$1(a){t.dK.a(a)
return A.dU(a.a,a.b,B.m,B.m)},
$S:111}
A.vA.prototype={
$2(a,b){var s,r,q,p,o,n,m,l,k,j,i,h=a.length
if(h===0||b.length===0)return 6
s=h-1
if(!(s>=0))return A.d(a,s)
r=a[s]
if(0>=b.length)return A.d(b,0)
q=b[0]
p=B.b.v(r,$.yK())
o=B.b.v(q,$.yK())
n=p&&B.b.v(r,$.yL())
m=o&&B.b.v(q,$.yL())
l=n&&B.b.v(r,$.yJ())
k=m&&B.b.v(q,$.yJ())
j=l&&B.b.v(a,$.Cs())
i=k&&B.b.v(b,$.Ct())
if(j||i)return 5
else if(l||k)return 4
else if(p&&!n&&m)return 3
else if(n||m)return 2
else if(p||o)return 1
return 0},
$S:112}
A.aw.prototype={
B(a){var s=this.b,r=A.O(s,"\n","\xb6")
return"Diff("+this.a+',"'+r+'")'},
n(a,b){var s,r=this
if(b==null)return!1
if(r!==b)s=b instanceof A.aw&&A.iW(r)===A.iW(b)&&r.a===b.a&&r.b===b.b
else s=!0
return s},
ga3(a){return B.d.ga3(this.a)^B.b.ga3(this.b)}}
A.aj.prototype={
gT(){var s=this.c.h(0,"scope")
if(A.cI(s))return s&6|256
return 256},
dg(a,b){var s,r=this.c.h(0,"whitelist")
if(!t.j.b(r))return!0
if(typeof b=="string"){s=A.D("[\"']",!0,!1)
return B.a.v(r,A.O(b,s,""))}return B.a.v(r,b)},
ba(a){return A.m(a.a.getAttribute(this.b))},
dc(a,b,c){if(!this.dg(b,c))return!1
b.a.setAttribute(this.b,J.L(c))
return!0},
Z(a,b){b.a.removeAttribute(this.b)
return null}}
A.f7.prototype={
hp(a,b){var s,r,q,p=this
if(b!=null&&!J.A(b,!1)){s=p.a
if(a.dc(0,s,b)){r=p.b
q=a.a
if(a.ba(s)!=null)r.j(0,q,a)
else r.Z(0,q)}}else{a.Z(0,p.a)
p.b.Z(0,a.a)}},
hs(a){var s,r,q,p,o
t.nG.a(a)
s=this.b
s.M(0)
this.c=!0
r=this.a
q=A.N(r.gkL(),!0,t.N)
B.a.H(q,A.z1(r))
B.a.H(q,A.zU(r))
for(r=q.length,p=0;p<q.length;q.length===r||(0,A.k)(q),++p){o=a.$1(q[p])
if(o!=null)s.j(0,o.a,o)}},
f_(a){var s,r,q
t.iJ.a(a)
for(s=this.b.gao(),s=s.gJ(s),r=this.a;s.l();){q=s.gq()
a.$2(q.a,q.b.ba(r))}},
tQ(a){var s,r,q,p,o
this.f_(t.iJ.a(a))
for(s=this.b,r=s.gak(),q=A.u(r),r=new A.aS(J.U(r.a),r.b,q.i("aS<1,2>")),p=this.a,q=q.y[1];r.l();){o=r.a;(o==null?q.a(o):o).Z(0,p)}s.M(0)},
fo(){var s=A.b(t.N,t.z)
this.b.O(0,new A.lD(this,s))
return s}}
A.lD.prototype={
$2(a,b){var s
A.h(a)
s=t.d.a(b).ba(this.a.a)
if(s!=null)this.b.j(0,a,s)},
$S:73}
A.hv.prototype={
ba(a){var s=new A.b9(t.m.a(a.a.classList)).gak(),r=A.K(s),q=new A.an(s,r.i("x(1)").a(new A.ms(this)),r.i("an<1>"))
if(!q.ga6(0))return J.CU(q.gF(0),this.b.length+1)
return null},
dc(a,b,c){if(!this.dg(b,c))return!1
this.Z(0,b)
t.m.a(b.a.classList).add(this.b+"-"+A.p(c))
return!0},
Z(a,b){var s,r,q=b.a,p=t.m,o=new A.b9(p.a(q.classList)).gak(),n=A.K(o),m=n.i("an<1>"),l=A.N(new A.an(o,n.i("x(1)").a(new A.mr(this)),m),!0,m.i("o.E"))
for(o=l.length,s=0;s<o;++s){r=l[s]
p.a(q.classList).remove(r)}if(new A.b9(p.a(q.classList)).gak().length===0)q.removeAttribute("class")}}
A.ms.prototype={
$1(a){return B.b.a0(A.h(a),this.a.b+"-")},
$S:8}
A.mr.prototype={
$1(a){return B.b.a0(A.h(a),this.a.b+"-")},
$S:8}
A.mp.prototype={
$1(a){return A.h(a).length!==0},
$S:8}
A.mq.prototype={
$1(a){var s=A.a(A.h(a).split("-"),t.s)
return B.a.ab(B.a.dM(s,0,s.length-1),"-")},
$S:6}
A.i2.prototype={
ba(a){return this.hf(a).h(0,this.b)},
dc(a,b,c){var s,r=this
if(!r.dg(b,c))return!1
s=r.hf(b)
s.j(0,r.b,J.L(c))
r.kF(b,s)
return!0},
Z(a,b){var s=this.hf(b)
s.Z(0,this.b)
this.kF(b,s)},
hf(a){var s,r,q,p,o,n,m,l,k=A.m(a.a.getAttribute("style"))
if(k==null||B.b.R(k).length===0){s=t.N
return A.b(s,s)}s=t.N
r=A.b(s,s)
for(s=k.split(";"),q=s.length,p=0;p<q;++p){o=s[p].split(":")
n=o.length
if(n!==2)continue
if(0>=n)return A.d(o,0)
m=B.b.R(o[0])
if(1>=n)return A.d(o,1)
l=B.b.R(o[1])
if(m.length!==0)r.j(0,m,l)}return r},
kF(a,b){var s,r
t.J.a(b)
if(b.a===0){a.a.removeAttribute("style")
return}s=new A.a_("")
b.O(0,new A.pP(s))
r=s.a
a.a.setAttribute("style",r.charCodeAt(0)==0?r:r)}}
A.pQ.prototype={
$1(a){return J.yU(B.a.gF(A.h(a).split(":")))},
$S:6}
A.pR.prototype={
$1(a){return A.h(a).length!==0},
$S:8}
A.pP.prototype={
$2(a,b){var s,r
A.h(a)
A.h(b)
s=this.a
r=s.a
if(r.length!==0)s.a=r+" "
r=a+": "+A.Eo(b)+";"
s.a+=r},
$S:29}
A.pO.prototype={
$1(a){var s=a.h(0,1)
if(s.length===3)s=new A.a1(A.a(s.split(""),t.s),t.C.a(new A.pN()),t.e).bn(0)
return"rgb("+A.bM(B.b.t(s,0,2),16)+", "+A.bM(B.b.t(s,2,4),16)+", "+A.bM(B.b.t(s,4,6),16)+")"},
$S:18}
A.pN.prototype={
$1(a){A.h(a)
return a+a},
$S:6}
A.jj.prototype={
ba(a){var s,r,q,p,o,n=this.fL(a)
if(n==null||!J.CT(n,"rgb("))return n
q=A.D("[^\\d,]",!0,!1)
s=A.a(A.O(n,q,"").split(","),t.s)
if(J.b1(s)!==3)return n
try{q=s
p=A.K(q)
r=new A.a1(q,p.i("e(1)").a(new A.mG()),p.i("a1<1,e>")).ab(0,"")
p=A.p(r)
return"#"+p}catch(o){return n}}}
A.mG.prototype={
$1(a){var s=A.bM(B.b.R(A.h(a)),null)
return B.b.ai(J.CX(s,16),2,"0")},
$S:6}
A.j2.prototype={}
A.j3.prototype={}
A.j4.prototype={
ba(a){var s=this.fL(a)
if(s==null)return null
return J.ly($.vz.h(0,"whitelist"),s)?s:""}}
A.j6.prototype={}
A.j8.prototype={}
A.f9.prototype={
gA(){return"blockquote"},
gT(){return 5},
P(){var s=A.aJ(this.d5(),t.N,t.z)
s.j(0,"blockquote",!0)
return s},
a1(){return A.x_(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))}}
A.d4.prototype={
gA(){return"bold"},
gT(){return 3},
P(){var s=A.aJ(this.cI(),t.N,t.z)
s.j(0,"bold",!0)
return s},
G(a,b){var s=this
s.eA(t.k.a(a),t.h.a(b))
if(A.h(t.T.a(s.d).a.tagName)!==B.a.gF(B.ac))s.cD(s.gX().z.a5("bold",null))},
aq(){return this.G(null,null)},
N(a,b){A.h(a)
if(a==="bold"&&J.A(b,!1)){this.bX()
return}this.d6(a,b)},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.d4(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.d7.prototype={
gA(){return"code-block-container"},
gT(){return 5},
gaO(){return new A.mD()},
kS(a,b){var s,r=this.e,q=A.K(r),p=new A.a1(r,q.i("e(1)").a(new A.mE()),q.i("a1<1,e>")).ab(0,"\n")
q=p.length
s=B.d.aC(a,0,q)
return B.b.t(p,s,B.d.aC(a+b,s,q))},
cT(a,b){return"<pre>\n"+B.aF.cu(this.kS(a,b))+"\n</pre>"},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.d7(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.mD.prototype={
$1(a){return a instanceof A.dE},
$S:3}
A.mE.prototype={
$1(a){var s
t.U.a(a)
if(a.E(0)<=1)s=""
else{s=A.m(a.d.a.textContent)
if(s==null)s=""}return s},
$S:114}
A.dE.prototype={
gaO(){return new A.mF()},
gA(){return"code-block"},
gT(){return 5},
a1(){return A.x1(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))},
P(){var s=A.aJ(this.d5(),t.N,t.z)
s.j(0,"code-block",!0)
return s}}
A.mF.prototype={
$1(a){return a instanceof A.aM||a instanceof A.ap||a instanceof A.cM},
$S:3}
A.dD.prototype={
gA(){return"code"},
gT(){return 3},
P(){var s=A.aJ(this.cI(),t.N,t.z)
s.j(0,"code",!0)
return s},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.dD(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.jk.prototype={}
A.jm.prototype={}
A.js.prototype={}
A.jt.prototype={}
A.ju.prototype={}
A.jB.prototype={}
A.jC.prototype={
ba(a){var s,r=this.fL(a)
if(r==null)return null
s=A.O(r,'"',"")
return A.O(s,"'","")}}
A.fh.prototype={
cT(a,b){var s=A.m(t.T.a(this.d).a.getAttribute("data-value"))
return"<span>"+(s==null?"":s)+"</span>"},
gA(){return"formula"},
gT(){return 3},
G(a,b){t.k.a(a)
t.h.a(b)},
P(){return A.l(["formula",A.m(t.T.a(this.d).a.getAttribute("data-value"))],t.N,t.z)},
bY(){return A.m(t.T.a(this.d).a.getAttribute("data-value"))}}
A.dI.prototype={
gA(){return"header"},
gT(){return 5},
P(){var s=A.aJ(this.d5(),t.N,t.z)
s.j(0,"header",B.a.ae(B.w,A.h(t.T.a(this.d).a.tagName).toUpperCase())+1)
return s},
a1(){return A.xa(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))}}
A.fm.prototype={
gA(){return"image"},
gT(){return 3},
N(a,b){var s,r
A.h(a)
if(B.a.v(B.b_,a)){s=t.T
r=this.d
if(b!=null)s.a(r).a.setAttribute(a,J.L(b))
else s.a(r).a.removeAttribute(a)}else this.j7(a,b)},
P(){return A.zn(t.T.a(this.d))},
bY(){return A.m(t.T.a(this.d).a.getAttribute("src"))},
G(a,b){var s
this.ey(t.k.a(a),t.h.a(b))
s=A.m(t.T.a(this.d).a.getAttribute("src"))
if(s==null||s==="//:0")this.Y(0)}}
A.nO.prototype={
$2(a,b){var s
t.cw.a(a)
A.h(b)
s=this.a.a
if(A.I(s.hasAttribute(b)))a.j(0,b,A.m(s.getAttribute(b)))
return a},
$S:58}
A.jN.prototype={
dc(a,b,c){var s,r,q=J.a3(c)
if(q.n(c,"+1")||q.n(c,"-1")){s=this.ba(b)
if(s==null)s=0
r=q.n(c,"+1")?s+1:s-1}else r=A.cI(c)?c:0
if(r===0){this.Z(0,b)
return!0}return this.mO(0,b,B.d.B(r))},
dg(a,b){return this.j2(a,b)||this.j2(a,A.V(J.L(b),null))},
ba(a){var s=this.mP(a)
return s!=null?A.V(s,null):null}}
A.d9.prototype={
gA(){return"italic"},
gT(){return 3},
P(){var s=A.aJ(this.cI(),t.N,t.z)
s.j(0,"italic",!0)
return s},
G(a,b){var s=this
s.eA(t.k.a(a),t.h.a(b))
if(A.h(t.T.a(s.d).a.tagName)!==B.a.gF(B.aa))s.cD(s.gX().z.a5("italic",null))},
aq(){return this.G(null,null)},
N(a,b){A.h(a)
if(a==="italic"&&J.A(b,!1)){this.bX()
return}this.d6(a,b)},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.d9(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.cw.prototype={
gA(){return"link"},
gT(){return 3},
P(){var s=A.aJ(this.cI(),t.N,t.z)
s.j(0,"link",A.m(t.T.a(this.d).a.getAttribute("href")))
return s},
N(a,b){var s,r
A.h(a)
if(b!=null){s=J.a3(b)
r=!s.n(b,!1)&&!s.n(b,"")}else r=!1
if(a!=="link"||!r){this.d6(a,b)
return}t.T.a(this.d).a.setAttribute("href",A.xi(J.L(b)))},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.cw(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.oc.prototype={
$1(a){return A.h(a)===this.a},
$S:8}
A.dR.prototype={
gA(){return"list-container"},
gT(){return 5},
gaO(){return new A.of()},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.dR(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.of.prototype={
$1(a){return a instanceof A.cy},
$S:3}
A.cy.prototype={
ji(a){var s=new A.f(A.b(t.O,t.g),t.m.a(t.A.a(a.a.ownerDocument).createElement("span"))),r=new A.og(this)
s.I("mousedown",r)
s.I("touchstart",r)
this.kK(s)},
nE(a){a.cy.f4("scroll-update","user",B.Y)},
gA(){return"list"},
gT(){return 5},
P(){var s=A.m(t.T.a(this.d).a.getAttribute("data-list")),r=A.aJ(this.d5(),t.N,t.z)
if(s!=null&&s.length!==0)r.j(0,"list",s)
return r},
N(a,b){var s,r
A.h(a)
if(b!=null){s=J.a3(b)
r=!s.n(b,!1)&&!s.n(b,"")}else r=!1
if(a==="list"&&r){t.T.a(this.d).a.setAttribute("data-list",A.p(b))
this.ch.M(0)}else this.dN(a,b)},
a1(){return A.xm(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))}}
A.og.prototype={
$1(a){var s,r,q,p,o
t.f.a(a)
s=this.a
r=s.gX()
q=t.T
p=q.a(r.d)
if(A.m(p.a.getAttribute("contenteditable"))!=="true")return
o=A.m(q.a(s.d).a.getAttribute("data-list"))
if(o==="checked"){s.N("list","unchecked")
a.a.preventDefault()}else if(o==="unchecked"){s.N("list","checked")
a.a.preventDefault()}else return
s.nE(r)},
$S:0}
A.dW.prototype={
gA(){return"script"},
gT(){return 3},
P(){var s=A.aJ(this.cI(),t.N,t.z)
s.j(0,"script",A.xu(t.T.a(this.d)))
return s},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.dW(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.kp.prototype={}
A.kq.prototype={}
A.df.prototype={
gA(){return"strike"},
gT(){return 3},
P(){var s=A.aJ(this.cI(),t.N,t.z)
s.j(0,"strike",!0)
return s},
G(a,b){var s=this
s.eA(t.k.a(a),t.h.a(b))
if(A.h(t.T.a(s.d).a.tagName)!==B.a.gF(B.ad))s.cD(s.gX().z.a5("strike",null))},
aq(){return this.G(null,null)},
N(a,b){A.h(a)
if(a==="strike"&&J.A(b,!1)){this.bX()
return}this.d6(a,b)},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.df(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.wI.prototype={
$1(a){return A.A6(a)},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:116}
A.wJ.prototype={
$1(a){return A.zZ(a)},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:117}
A.wK.prototype={
$1(a){return A.xE(a)},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:118}
A.wL.prototype={
$1(a){return A.kx(a)},
$0(){return this.$1(null)},
$C:"$1",
$R:0,
$D(){return[null]},
$S:119}
A.cD.prototype={
gA(){return"table-container"},
gT(){return 5},
gaO(){return new A.qJ()},
kv(){var s,r,q,p
for(s=this.e,r=s.length,q=0;q<r;++q){p=s[q]
if(p instanceof A.cC)return p}return null},
ig(){var s,r=this.kv()
if(r==null)return B.e4
s=t.fP
return A.N(new A.ae(r.e,s),!1,s.i("o.E"))},
qM(){var s,r,q,p,o,n,m,l,k,j,i,h,g=this.a4(t.h1),f=A.N(g,!1,g.$ti.i("o.E"))
if(f.length===0)return
g=t.S
s=B.a.ag(f,0,new A.qM(),g)
for(r=f.length,q=t.A7,p=t.Fc,o=t.T,n=0;n<f.length;f.length===r||(0,A.k)(f),++n){m=f[n]
l=m.e
k=s-new A.ae(l,q).ag(0,0,new A.qN(),g)
if(k<=0)continue
j=l.length!==0&&B.a.gF(l) instanceof A.aG?A.m(o.a(p.a(B.a.gF(l)).d).a.getAttribute("data-row")):null
for(i=0;i<k;++i){h=A.kx(j)
m.D(h,null)
h.aq()}}},
f0(a){var s,r,q,p,o,n
for(s=this.ig(),r=s.length,q=a>=0,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
if(q&&a<o.e.length){n=o.e
if(!(a>=0&&a<n.length))return A.d(n,a)
n[a].Y(0)}}},
c5(a){var s,r,q,p,o,n,m,l,k,j,i
for(s=this.ig(),r=s.length,q=a>=0,p=t.Fc,o=t.T,n=0;n<s.length;s.length===r||(0,A.k)(s),++n){m=s[n]
l=m.e
if(l.length!==0&&B.a.gF(l) instanceof A.aG)k=A.m(o.a(p.a(B.a.gF(l)).d).a.getAttribute("data-row"))
else k="row-"+B.d.ac(B.I.am(1048576),36)
j=A.kx(k)
if(q&&a<l.length){if(!(a>=0&&a<l.length))return A.d(l,a)
i=l[a]}else i=null
m.D(j,i)}},
c6(a){var s,r,q,p,o,n,m,l=null,k=this.kv()
if(k==null)return
s=A.C_()
r=A.xE(l)
q=k.e
p=q.length!==0&&B.a.gF(q) instanceof A.b2?t.h1.a(B.a.gF(q)):l
o=p==null?l:p.e.length
if(o==null)o=0
for(n=0;n<o;++n)r.D(A.kx(s),l)
if(a>=0&&a<q.length){if(!(a>=0&&a<q.length))return A.d(q,a)
m=q[a]}else m=l
k.D(r,m)},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.cD(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.qJ.prototype={
$1(a){return a instanceof A.cC},
$S:3}
A.qM.prototype={
$2(a,b){var s
A.v(a)
s=new A.ae(t.h1.a(b).e,t.A7).ag(0,0,new A.qL(),t.S)
return s>a?s:a},
$S:120}
A.qL.prototype={
$2(a,b){return A.v(a)+t.Fc.a(b).gcs()},
$S:48}
A.qN.prototype={
$2(a,b){return A.v(a)+t.Fc.a(b).gcs()},
$S:48}
A.cC.prototype={
gA(){return"table-body"},
gT(){return 5},
gaO(){return new A.qz()},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.cC(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.qz.prototype={
$1(a){return a instanceof A.b2},
$S:3}
A.b2.prototype={
gA(){return"table-row"},
gT(){return 5},
gaO(){return new A.ra()},
cr(){var s,r,q,p,o,n,m,l,k=this,j=null
if(!k.mQ())return!1
s=k.c
if(!(s instanceof A.z)||k.e.length===0||s.e.length===0)return!1
r=k.e
q=t.U
p=q.a(B.a.gF(r))
o=p instanceof A.aG?A.m(t.T.a(p.d).a.getAttribute("data-row")):j
r=q.a(B.a.gK(r))
n=r instanceof A.aG?A.m(t.T.a(r.d).a.getAttribute("data-row")):j
r=s.e
p=q.a(B.a.gF(r))
m=p instanceof A.aG?A.m(t.T.a(p.d).a.getAttribute("data-row")):j
r=q.a(B.a.gK(r))
l=r instanceof A.aG?A.m(t.T.a(r.d).a.getAttribute("data-row")):j
return o!=null&&o===n&&o===m&&o===l},
G(a,b){var s,r,q,p,o,n,m=this
t.k.a(a)
t.h.a(b)
m.ez(a,b)
for(s=A.a5(m.e,!0,t.U),r=s.length,q=t.T,p=0;p<r;++p){o=s[p]
n=o.c
if(!(o instanceof A.aG)||!(n instanceof A.aG))continue
if(A.m(q.a(o.d).a.getAttribute("data-row"))==A.m(q.a(n.d).a.getAttribute("data-row")))continue
m.dJ(o).G(a,b)
s=m.b
if(s!=null)s.G(a,b)
return}},
aq(){return this.G(null,null)},
dw(){var s=this.a
if(s==null)return-1
return s.eZ(this)},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.b2(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.ra.prototype={
$1(a){return a instanceof A.aG},
$S:3}
A.aG.prototype={
gA(){return"table"},
gT(){return 5},
gcs(){var s=A.m(t.T.a(this.d).a.getAttribute("colspan"))
s=A.V(s==null?"":s,null)
s=s==null?null:B.d.aC(s,1,1000)
return s==null?1:s},
gfl(){var s=A.m(t.T.a(this.d).a.getAttribute("rowspan"))
s=A.V(s==null?"":s,null)
s=s==null?null:B.d.aC(s,1,1000)
return s==null?1:s},
iV(a,b){var s,r=t.T,q=this.d
if(a>1){s=r.a(q).a
s.setAttribute("colspan",""+a)}else{s=r.a(q).a
s.removeAttribute("colspan")}if(b>1){r.a(q)
s.setAttribute("rowspan",""+b)}else{r.a(q)
s.removeAttribute("rowspan")}},
mA(a){return this.iV(1,a)},
ht(){var s=this.a
s=s==null?null:s.eZ(this)
return s==null?-1:s},
P(){var s,r=this,q=r.d5(),p=A.m(t.T.a(r.d).a.getAttribute("data-row"))
if(p!=null&&p.length!==0){s=A.aJ(q,t.N,t.z)
s.j(0,"table",p)
if(r.gcs()>1)s.j(0,"colspan",r.gcs())
if(r.gfl()>1)s.j(0,"rowspan",r.gfl())
return s}return q},
N(a,b){var s
A.h(a)
s=!1
if(a==="table")if(b!=null){s=J.a3(b)
s=!s.n(b,!1)&&!s.n(b,"")}if(s){t.T.a(this.d).a.setAttribute("data-row",J.L(b))
return}this.dN(a,b)},
a1(){return A.xy(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))}}
A.dn.prototype={
gA(){return"underline"},
gT(){return 3},
P(){var s=A.aJ(this.cI(),t.N,t.z)
s.j(0,"underline",!0)
return s},
N(a,b){A.h(a)
if(a==="underline"&&J.A(b,!1)){this.bX()
return}this.d6(a,b)},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.dn(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.bt.prototype={
gA(){return"video"},
gT(){return 5},
P(){return B.a.ag(B.aj,A.b(t.N,t.z),new A.tf(this),t.P)},
bY(){return A.m(t.T.a(this.d).a.getAttribute("src"))},
N(a,b){var s,r
A.h(a)
if(B.a.v(B.aj,a)){s=t.T
r=this.d
if(b!=null)s.a(r).a.setAttribute(a,J.L(b))
else s.a(r).a.removeAttribute(a)}else this.mI(a,b)},
cT(a,b){var s=A.p(A.m(t.T.a(this.d).a.getAttribute("src")))
return'<a href="'+s+'">'+s+"</a>"}}
A.te.prototype={
$2(a,b){var s
t.cw.a(a)
A.h(b)
s=this.a.a
if(A.I(s.hasAttribute(b)))a.j(0,b,A.m(s.getAttribute(b)))
return a},
$S:58}
A.tf.prototype={
$2(a,b){var s
t.P.a(a)
A.h(b)
s=t.T.a(this.a.d).a
if(A.I(s.hasAttribute(b)))a.j(0,b,A.m(s.getAttribute(b)))
return a},
$S:56}
A.cZ.prototype={
nq(a,b){var s,r,q,p,o=this,n=null,m=o.a,l=m.c,k=l==null
if(!k){s=A.K(l)
r="\\b(?:"+new A.a1(l,s.i("e(1)").a(A.Ie()),s.i("a1<1,e>")).ab(0,"|")+")\\b"}else r=m.b
o.c=r==null?n:A.D(r,!o.b,!0)
s=m.d
o.d=s==null?n:A.D(s,!o.b,!0)
s=m.e
o.e=s==null?n:A.D(s,!o.b,!0)
o.f=A.D("[A-Za-z_$][A-Za-z0-9_$]*",!o.b,!0)
q=m.f
if(q==null)q=k?n:A.l(["keyword",l],t.N,t.c)
if(q!=null){m=t.N
o.stD(A.b(m,m))
for(m=q.gao(),m=m.gJ(m);m.l();){l=m.gq()
for(k=J.U(l.b),l=l.a;k.l();){s=k.gq()
p=o.r
p.toString
p.j(0,b?s.toLowerCase():s,l)}}}},
qT(a){var s,r,q,p,o,n,m=this.w
if(m!=null)return m
s=A.a([],t.rT)
this.snS(s)
for(r=this.a.w,q=r.length,p=0;p<q;++p){o=r[p]
for(n=J.U(A.F2(o));n.l();)B.a.k(s,a.kT(n.gq()))}return s},
stD(a){this.r=t.km.a(a)},
snS(a){this.w=t.EL.a(a)}}
A.tD.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this
t.sT.a(a)
s=a.a
if(s==null)s=d.a.a
r=a.b
if(r==null)r=d.a.b
q=a.c
if(q==null)q=d.a.c
p=a.d
if(p==null)p=d.a.d
o=a.e
if(o==null)o=d.a.e
n=a.f
if(n==null)n=d.a.f
m=d.a
l=a.w
if(l.length===0)l=m.w
k=a.y||m.y
j=a.z||m.z
i=a.Q||m.Q
h=a.as||m.as
g=a.at||m.at
f=a.ax||m.ax
e=a.ch||m.ch
return new A.q(s,r,q,p,o,n,m.r,l,null,k,j,i,h,g,f,m.ay,e)},
$S:122}
A.tC.prototype={
$1(a){return"\\"+A.p(a.h(0,0))},
$S:18}
A.tE.prototype={
kT(a){return this.b.aQ(a,new A.tF(this,a))}}
A.tF.prototype={
$0(){var s=this.b,r=this.a.a,q=new A.cZ(s,r)
q.nq(s,r)
return q},
$S:123}
A.eX.prototype={
bA(){return"_Kind."+this.b}}
A.tA.prototype={}
A.ec.prototype={}
A.ub.prototype={
ui(a){var s,r,q,p,o,n,m,l,k=this,j=k.e
B.a.k(j,new A.ec(k.c.kT(k.a.c),new A.a_("")))
for(s=a.length,r=0,q=-1,p=-1;o=r<s,o;){n=k.po(a,r)
if(n==null)break
B.a.gK(j).b.a+=B.b.t(a,r,n.b.b.index)
m=k.nF(a,n)
l=m<r?r:m
if(l===r&&j.length===p&&r===q){o=B.a.gK(j).b
if(!(r>=0))return A.d(a,r)
o.a+=a[r];++r}else{p=j.length
q=r
r=l}}if(o)B.a.gK(j).b.a+=B.b.L(a,r)
for(s=t.nT;j.length>1;)k.bg(s.a(j.pop()))
k.bg(B.a.gK(j))
return A.Fg(k.d)},
po(a,b){var s,r,q,p,o,n,m={},l=this.e,k=B.a.gK(l).a
m.a=null
s=new A.uc(m,a,b)
for(r=k.qT(this.c),q=r.length,p=0;p<r.length;r.length===q||(0,A.k)(r),++p){o=r[p]
s.$3(B.nh,o.c,o)}s.$3(B.bQ,k.d,k)
for(n=l.length-1;n>0;){r=l.length
if(!(n<r))return A.d(l,n)
if(!l[n].a.a.ax)break;--n
if(!(n<r))return A.d(l,n)
r=l[n].a
s.$3(B.bQ,r.d,r)}s.$3(B.ni,k.e,k)
return m.a},
nF(a,b){var s,r,q,p,o,n,m,l=this,k=b.b
switch(b.a.a){case 0:s=b.c
r=s.a
if(r.ch){r=B.a.gK(l.e).b
q=k.b
if(0>=q.length)return A.d(q,0)
q=q[0]
q.toString
r.a+=q
return k.gbw()}if(r.y){r=l.e
l.bg(B.a.gK(r))
B.a.k(r,new A.ec(s,new A.a_("")))
return k.b.index}if(r.z){r=l.e
q=B.a.gK(r).b
p=k.b
if(0>=p.length)return A.d(p,0)
p=p[0]
p.toString
q.a+=p
l.bg(B.a.gK(r))
B.a.k(r,new A.ec(s,new A.a_("")))
return k.gbw()}q=l.e
l.bg(B.a.gK(q))
p=new A.a_("")
o=k.b
if(0>=o.length)return A.d(o,0)
o=o[0]
o.toString
p.a=""+o
B.a.k(q,new A.ec(s,p))
p=s.d
if(p==null){if(0>=q.length)return A.d(q,-1)
p=t.nT
l.bg(p.a(q.pop()))
if(r.at&&q.length>1){if(0>=q.length)return A.d(q,-1)
l.bg(p.a(q.pop()))}}return k.gbw()
case 1:r=l.e
q=t.nT
p=b.c
while(!0){if(!(r.length>1&&B.a.gK(r).a!==p))break
if(0>=r.length)return A.d(r,-1)
l.bg(q.a(r.pop()))}o=r.length
if(o===1)return k.gbw()
if(0>=o)return A.d(r,-1)
n=r.pop()
p=p.a
if(p.Q){l.bg(n)
return k.b.index}o=k.b
if(p.as){l.bg(n)
m=B.a.gK(r).b
if(0>=o.length)return A.d(o,0)
o=o[0]
o.toString
m.a+=o}else{m=n.b
if(0>=o.length)return A.d(o,0)
o=o[0]
o.toString
m.a+=o
l.bg(n)}if(p.at&&r.length>1){if(0>=r.length)return A.d(r,-1)
l.bg(q.a(r.pop()))}return k.gbw()
case 2:r=l.e
if(r.length>1)l.bg(t.nT.a(r.pop()))
r=B.a.gK(r).b
q=k.b
if(0>=q.length)return A.d(q,0)
q=q[0]
q.toString
r.a+=q
return k.gbw()}},
bg(a){var s,r,q,p,o,n,m,l,k,j,i,h,g=a.b,f=g.a,e=f.charCodeAt(0)==0?f:f
g.a=""
g=e.length
if(g===0)return
f=a.a
s=f.a
r=f.r
if(r==null||r.a===0){B.a.k(this.d,new A.ct(e,s.a))
return}f=f.f
f===$&&A.c()
f=f.dU(0,e)
f=new A.e9(f.a,f.b,f.c)
q=this.d
p=this.a.d
o=t.he
n=s.a
m=0
for(;f.l();){l=f.d
k=(l==null?o.a(l):l).b
if(0>=k.length)return A.d(k,0)
j=k[0]
j.toString
if(p)i=j.toLowerCase()
else i=j
h=r.h(0,i)
if(h==null)continue
i=k.index
if(i>m)B.a.k(q,new A.ct(B.b.t(e,m,i),n))
B.a.k(q,new A.ct(j,h))
m=i+k[0].length}if(m<g)B.a.k(q,new A.ct(B.b.L(e,m),n))}}
A.uc.prototype={
$3(a,b,c){var s,r,q,p
if(b==null)return
s=b.dV(0,this.b,this.c)
r=new A.e9(s.a,s.b,s.c)
if(r.l()){s=r.d
q=s==null?t.he.a(s):s}else q=null
if(q==null)return
s=this.a
p=s.a
if(p==null||q.b.index<p.b.b.index)s.a=new A.tA(a,q,c)},
$S:124}
A.uI.prototype={
$0(){return this.a},
$S:125}
A.q.prototype={}
A.aY.prototype={}
A.ct.prototype={
B(a){var s=this.b,r=this.a
if(s==null)s="text("+A.O(r,"\n","\\n")+")"
else s=s+"("+A.O(r,"\n","\\n")+")"
return s},
n(a,b){if(b==null)return!1
return b instanceof A.ct&&b.a===this.a&&b.b==this.b},
ga3(a){return A.dU(this.a,this.b,B.m,B.m)}}
A.cK.prototype={
bA(){return"AtomKind."+this.b}}
A.n.prototype={}
A.k1.prototype={
B(a){return"MathSyntaxError: "+this.a+" (at "+this.b+")"}}
A.bK.prototype={
bA(){return"_TokKind."+this.b}}
A.c4.prototype={
B(a){return this.a.b+"("+this.b+")"}}
A.ud.prototype={
bW(){var s=this.c
return s==null?this.c=this.da():s},
bG(){var s,r,q,p,o,n,m,l,k=this
if(k.c!=null)throw A.i(A.aT("internal: raw group after lookahead",k.b))
s=k.a
r=s.length
while(!0){q=k.b
if(q<r){p=$.yI()
q=s[q]
q=p.b.test(q)}else q=!1
if(!q)break;++k.b}q=k.b
if(q<r){if(!(q<r))return A.d(s,q)
p=s[q]!=="{"}else p=!0
if(p){if(q<r){o=s[q]
k.b=q+1
return o}throw A.i(A.aT("missing argument",q))}q=k.b=q+1
for(n=1,p="";q<r;){o=s[q]
if(o==="\\"&&q+1<r){m=q+1
if(!(m<r))return A.d(s,m)
l=s[m]
if(l==="{"||l==="}"||l==="\\"){p+=l
q+=2
k.b=q
continue}}if(o==="{")++n
if(o==="}"){--n
if(n===0){k.b=q+1
return p.charCodeAt(0)==0?p:p}}p+=o;++q
k.b=q}throw A.i(A.aT("unclosed group",q))},
da(){var s,r,q,p,o,n,m,l,k=this,j=k.a,i=j.length
while(!0){s=k.b
if(s<i){r=$.yI()
s=j[s]
s=r.b.test(s)}else s=!1
if(!s)break;++k.b}s=k.b
if(s>=i)return new A.c4(B.E,"",s)
q=j[s]
if(q==="\\"){r=k.b=s+1
if(r>=i)throw A.i(A.aT("trailing backslash",s))
p=j[r]
if(p==="\\"){k.b=r+1
return new A.c4(B.aA,"\\\\",s)}r=$.yH()
if(r.b.test(p)){o=new A.a_("")
while(!0){r=k.b
if(r<i){p=$.yH()
r=j[r]
r=p.b.test(r)}else r=!1
if(!r)break
r=k.b
if(!(r<i))return A.d(j,r)
o.a+=j[r]
k.b=r+1}return new A.c4(B.D,"\\"+o.B(0),s)}r=k.b
if(!(r<i))return A.d(j,r)
n=j[r]
k.b=r+1
return new A.c4(B.D,"\\"+n,s)}switch(q){case"{":k.b=s+1
return new A.c4(B.ay,"{",s)
case"}":k.b=s+1
return new A.c4(B.Q,"}",s)
case"^":k.b=s+1
return new A.c4(B.bR,"^",s)
case"_":k.b=s+1
return new A.c4(B.bS,"_",s)
case"&":k.b=s+1
return new A.c4(B.az,"&",s)}r=$.lv()
if(r.b.test(q)){r=""
while(!0){p=k.b
if(p<i){m=$.lv()
p=j[p]
p=m.b.test(p)}else p=!1
if(!p)break
p=k.b
if(!(p<i))return A.d(j,p)
r+=j[p]
k.b=p+1}p=k.b
m=p+1
l=!1
if(m<i){if(!(p<i))return A.d(j,p)
p=j[p]
if(p==="."||p===","){p=$.lv()
m=j[m]
p=p.b.test(m)}else p=l}else p=l
if(p){p=k.b
if(!(p<i))return A.d(j,p)
r+=j[p]
p=k.b=p+1
while(!0){if(p<i){m=$.lv()
if(!(p>=0))return A.d(j,p)
p=j[p]
p=m.b.test(p)}else p=!1
if(!p)break
p=k.b
if(!(p<i))return A.d(j,p)
r+=j[p];++p
k.b=p}j=r}else j=r
return new A.c4(B.nj,j.charCodeAt(0)==0?j:j,s)}++k.b
return new A.c4(B.P,q,s)}}
A.Q.prototype={}
A.u4.prototype={
dS(a,b){var s,r,q,p=this
t.qr.a(a)
t.dO.a(b)
s=p.b
r=p.c
p.skt(a)
p.sks(b)
try{q=p.pT(a,b)
return q}finally{p.skt(s)
p.sks(r)}},
hg(a){return this.dS(a,B.av)},
pT(a,b){var s,r,q,p,o,n,m,l
t.qr.a(a)
t.dO.a(b)
s=t.zn
r=A.a([],s)
for(q=this.a;!0;){p=q.c
if(p==null)p=q.c=q.da()
o=p.a
if(a.v(0,o))break
if(o===B.E)break
o=o===B.D
if(o&&b.v(0,p.b))break
if(o){o=p.b
o=o==="\\over"||o==="\\atop"||o==="\\choose"}else o=!1
if(o){if(q.c==null)q.c=q.da()
q.c=null
n=A.eZ(r)
m=A.eZ(this.dS(a,b))
q=p.b
l="<mfrac"+(q==="\\over"?"":' linethickness="0"')+"><mrow>"+n+"</mrow><mrow>"+m+"</mrow></mfrac>"
return A.a([new A.Q(q==="\\choose"?A.u5("(",l,")",!1):l,B.c,!1,null)],s)}B.a.k(r,this.ka())}return r},
ka(){var s,r,q,p,o,n,m,l,k,j,i=this,h=i.dR(),g=h.c
for(s=i.a,r=null,q=null,p=0;!0;){o=s.c
if(o==null)o=s.c=s.da()
n=o.a
m=n===B.D
if(m&&o.b==="\\limits"){s.c=null
g=!0
continue}if(m&&o.b==="\\nolimits"){s.c=null
g=!1
continue}if(n===B.P&&o.b==="'"){s.c=null;++p
continue}if(n===B.bR){if(r!=null)throw A.i(A.aT("double superscript",o.c))
s.c=null
r=i.dR().a
continue}if(n===B.bS){if(q!=null)throw A.i(A.aT("double subscript",o.c))
s.c=null
q=i.dR().a
continue}break}if(p>0){l="<mo>"+B.b.er("\u2032",p)+"</mo>"
r=r==null?l:"<mrow>"+l+r+"</mrow>"}s=r==null
if(s&&q==null)return h
n=!s
if(n&&q!=null)k=g?"munderover":"msubsup"
else if(n){m=g?"mover":"msup"
k=m}else{m=g?"munder":"msub"
k=m}if(n&&q!=null)j=q+A.p(r)
else if(s){q.toString
j=q}else j=r
return new A.Q("<"+k+">"+h.a+j+"</"+k+">",h.b,!1,null)},
dR(){var s,r=this,q=r.a,p=q.bW()
q.c=null
switch(p.a.a){case 3:s=r.hg(B.bC)
r.jO(B.Q)
return new A.Q(A.Az(s),B.c,!1,null)
case 0:return r.pN(p)
case 2:return new A.Q("<mn>"+A.b_(p.b)+"</mn>",B.c,!1,null)
case 1:return r.pM(p)
case 4:throw A.i(A.aT("unexpected }",p.c))
case 5:case 6:throw A.i(A.aT("missing base for "+p.b,p.c))
case 7:throw A.i(A.aT("& outside an environment",p.c))
case 8:throw A.i(A.aT("\\\\ outside an environment",p.c))
case 9:throw A.i(A.aT("unexpected end of formula",p.c))}},
pM(a){var s,r=null,q='<mo stretchy="false">',p=a.b
if(p==="-")return new A.Q("<mo>\u2212</mo>",B.j,!1,"\u2212")
if(B.k5.v(0,p))return new A.Q("<mo>"+A.b_(p)+"</mo>",B.j,!1,p)
if(B.jW.v(0,p))return new A.Q("<mo>"+A.b_(p)+"</mo>",B.h,!1,p)
if(B.k6.v(0,p))return new A.Q(q+p+"</mo>",B.A,!1,r)
if(B.k0.v(0,p))return new A.Q(q+p+"</mo>",B.y,!1,r)
if(p===","||p===";")return new A.Q("<mo>"+p+"</mo>",B.aB,!1,r)
if(p===".")return new A.Q("<mo>.</mo>",B.aB,!1,r)
if(p==="|")return new A.Q("<mo>|</mo>",B.c,!1,r)
if(p==="!")return new A.Q("<mo>!</mo>",B.y,!1,r)
s=A.D("[A-Za-z]",!0,!1)
if(s.b.test(p))return new A.Q("<mi>"+p+"</mi>",B.c,!1,p)
return new A.Q("<mo>"+A.b_(p)+"</mo>",B.c,!1,p)},
pN(a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=this,a1=null,a2="\\operatornamewithlimits",a3='<mi mathvariant="normal">',a4=a5.b
if(B.k2.v(0,a4))return new A.Q("<mfrac><mrow>"+a0.b0()+"</mrow><mrow>"+a0.b0()+"</mrow></mfrac>",B.c,!1,a1)
if(B.jX.v(0,a4))return new A.Q(A.u5("(",'<mfrac linethickness="0"><mrow>'+a0.b0()+"</mrow><mrow>"+a0.b0()+"</mrow></mfrac>",")",!1),B.c,!1,a1)
if(a4==="\\sqrt"){s=a0.pK()
r=a0.b0()
if(s==null)return new A.Q("<msqrt>"+r+"</msqrt>",B.c,!1,a1)
return new A.Q("<mroot><mrow>"+r+"</mrow><mrow>"+s+"</mrow></mroot>",B.c,!1,a1)}if(a4==="\\left"){q=a0.hl()
r=a0.dS(B.au,B.k_)
p=a0.a
o=p.bW()
if(o.a!==B.D||o.b!=="\\right")throw A.i(A.aT("\\left without \\right",a5.c))
p.bW()
p.c=null
n=a0.hl()
return new A.Q(A.u5(q,A.eZ(r),n,!0),B.c,!1,a1)}if(a4==="\\right")throw A.i(A.aT("\\right without \\left",a5.c))
if(a4==="\\middle"){m=a0.hl()
return new A.Q(m.length===0?"":'<mo fence="true">'+A.b_(m)+"</mo>",B.c,!1,a1)}if(B.k1.v(0,a4)){p=A.b_(a0.a.bG())
return new A.Q("<mtext>"+A.O(p," ","\xa0")+"</mtext>",B.c,!1,a1)}if(a4==="\\textbf"){p=A.b_(a0.a.bG())
return new A.Q('<mtext mathvariant="bold">'+A.O(p," ","\xa0")+"</mtext>",B.c,!1,a1)}if(a4==="\\textit"||a4==="\\emph"){p=A.b_(a0.a.bG())
return new A.Q('<mtext mathvariant="italic">'+A.O(p," ","\xa0")+"</mtext>",B.c,!1,a1)}if(a4==="\\texttt"){p=A.b_(a0.a.bG())
return new A.Q('<mtext mathvariant="monospace">'+A.O(p," ","\xa0")+"</mtext>",B.c,!1,a1)}if(a4==="\\textsf"){p=A.b_(a0.a.bG())
return new A.Q('<mtext mathvariant="sans-serif">'+A.O(p," ","\xa0")+"</mtext>",B.c,!1,a1)}if(a4==="\\operatorname"||a4===a2)return new A.Q(a3+A.b_(a0.a.bG())+"</mi>",B.aC,a4===a2,a1)
l=B.fd.h(0,a4)
if(l!=null)return new A.Q('<mstyle mathvariant="'+l+'">'+a0.b0()+"</mstyle>",B.c,!1,a1)
k=B.ff.h(0,a4)
if(k!=null){r=a0.b0()
j=B.b.a0(a4,"\\wide")||a4==="\\overline"||a4==="\\overbrace"||B.b.a0(a4,"\\overright")||B.b.a0(a4,"\\overleft")
return new A.Q('<mover accent="true"><mrow>'+r+'</mrow><mo stretchy="'+j+'">'+A.b_(k)+"</mo></mover>",B.c,!1,a1)}i=B.fx.h(0,a4)
if(i!=null)return new A.Q('<munder accentunder="true"><mrow>'+a0.b0()+'</mrow><mo stretchy="true">'+A.b_(i)+"</mo></munder>",B.c,!1,a1)
if(a4==="\\overset"||a4==="\\stackrel"){h=a0.b0()
return new A.Q("<mover><mrow>"+a0.b0()+"</mrow><mrow>"+h+"</mrow></mover>",B.c,!1,a1)}if(a4==="\\underset"){g=a0.b0()
return new A.Q("<munder><mrow>"+a0.b0()+"</mrow><mrow>"+g+"</mrow></munder>",B.c,!1,a1)}f=B.fF.h(0,a4)
if(f!=null)return new A.Q('<mspace width="'+f+'"/>',B.c,!1,a1)
if(a4==="\\hspace"||a4==="\\mspace"||a4==="\\kern")return new A.Q('<mspace width="'+A.b_(a0.a.bG())+'"/>',B.c,!1,a1)
if(a4==="\\phantom")return new A.Q("<mphantom>"+a0.b0()+"</mphantom>",B.c,!1,a1)
if(a4==="\\boxed")return new A.Q('<mrow style="padding: 0.15em; border: 1px solid currentColor">'+a0.b0()+"</mrow>",B.c,!1,a1)
if(a4==="\\textcolor"||a4==="\\color"){e=a0.a.bG()
r=a4==="\\color"?"":a0.b0()
if(r.length===0)return new A.Q("",B.c,!1,a1)
return new A.Q('<mstyle mathcolor="'+A.b_(e)+'">'+r+"</mstyle>",B.c,!1,a1)}p=a4==="\\displaystyle"
if(p||a4==="\\textstyle"||a4==="\\scriptstyle"||a4==="\\scriptscriptstyle")return new A.Q('<mstyle displaystyle="'+p+'">'+A.eZ(a0.dS(a0.b,a0.c))+"</mstyle>",B.c,!1,a1)
if(a4==="\\not"){d=a0.dR()
c=d.d
if(c!=null)return new A.Q("<mo>"+A.b_(c)+"\u0338</mo>",d.b,!1,a1)
return new A.Q("<mrow><mo>\xac</mo>"+d.a+"</mrow>",d.b,!1,a1)}if(a4==="\\pmod")return new A.Q('<mrow><mspace width="0.5em"/><mo stretchy="false">(</mo><mi mathvariant="normal">mod</mi><mspace width="0.25em"/>'+a0.b0()+'<mo stretchy="false">)</mo></mrow>',B.c,!1,a1)
if(a4==="\\begin")return a0.pS(a5)
if(a4==="\\end")throw A.i(A.aT("\\end without \\begin",a5.c))
b=B.bg.h(0,a4)
if(b!=null)return a0.qa(b)
p=B.b.L(a4,1)
a=B.f9.h(0,p)
if(a!=null)return new A.Q(a3+p+"</mi>",B.aC,a,a1)
throw A.i(A.aT("unknown command "+a4,a5.c))},
qa(a){var s='<mo stretchy="false">',r=a.a,q=A.b_(r),p=a.b
switch(p.a){case 0:p=$.Cw()
return new A.Q(p.b.test(r)?"<mi>"+q+"</mi>":s+q+"</mo>",B.c,!1,r)
case 1:p=a.c
return new A.Q('<mo movablelimits="'+p+'" largeop="true">'+q+"</mo>",B.o,p,r)
case 4:case 5:return new A.Q(s+q+"</mo>",p,!1,null)
case 7:return new A.Q('<mi mathvariant="normal">'+q+"</mi>",p,!1,null)
case 2:case 3:case 6:return new A.Q("<mo>"+q+"</mo>",p,!1,r)}},
pS(a){var s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h.bG(),f=B.fM.h(0,g)
if(f==null)throw A.i(A.aT("unknown environment "+g,a.c))
s=f[2]
if(g==="array"){r=h.bG()
q=A.D("[^lcr]",!0,!1)
s=new A.a1(A.a(A.O(r,q,"").split(""),t.s),t.C.a(new A.u7()),t.e).ab(0," ")
if(s.length===0)s="center"}p=A.a([],t.tZ)
q=t.s
o=A.a([],q)
for(;!0;){B.a.k(o,A.eZ(this.dS(B.jO,B.jM)))
n=h.c
if(n==null)n=h.c=h.da()
m=n.a
if(m===B.az){h.c=null
continue}if(m===B.aA){h.c=null
B.a.k(p,o)
o=A.a([],q)
continue}if(m===B.D&&n.b==="\\end"){h.c=null
l=h.bG()
if(l!==g)throw A.i(A.aT("\\end{"+l+"} does not match \\begin{"+g+"}",n.c))
break}throw A.i(A.aT("unclosed environment "+g,n.c))}h=o.length
if(h<=1)h=h===1&&J.b1(B.a.gF(o))!==0
else h=!0
if(h)B.a.k(p,o)
h='<mtable columnalign="'+s+'">'
for(q=p.length,k=0;k<p.length;p.length===q||(0,A.k)(p),++k){h+="<mtr>"
for(m=B.a.gJ(p[k]);m.l();)h+="<mtd>"+m.gq()+"</mtd>"
h+="</mtr>"}h+="</mtable>"
j=f[0]
i=f[1]
if(j.length===0&&i.length===0)return new A.Q(h.charCodeAt(0)==0?h:h,B.c,!1,null)
return new A.Q(A.u5(j,h.charCodeAt(0)==0?h:h,i,!0),B.c,!1,null)},
hl(){var s,r="invalid delimiter ",q=this.a,p=q.bW()
q.c=null
q=p.a
if(q===B.P){q=p.b
if(q===".")return""
return q}if(q===B.D){q=p.b
s=B.bg.h(0,q)
if(s!=null)return s.a
throw A.i(A.aT(r+q,p.c))}if(q===B.ay)return"{"
if(q===B.Q)return"}"
throw A.i(A.aT(r+p.b,p.c))},
b0(){var s,r=this,q=r.a,p=q.bW(),o=p.a
if(o===B.E)throw A.i(A.aT("missing argument",p.c))
if(o===B.ay){q.bW()
q.c=null
s=r.hg(B.bC)
r.jO(B.Q)
return A.Az(s)}return r.dR().a},
pK(){var s,r,q,p=this.a,o=p.bW()
if(o.a!==B.P||o.b!=="[")return null
p.bW()
p.c=null
s=A.a([],t.zn)
for(;!0;){r=p.c
if(r==null)r=p.c=p.da()
q=r.a
if(q===B.E)throw A.i(A.aT("unclosed [",r.c))
if(q===B.P&&r.b==="]"){p.c=null
break}B.a.k(s,this.ka())}return A.eZ(s)},
jO(a){var s=this.a,r=s.bW()
s.c=null
if(r.a!==a)throw A.i(A.aT("expected "+a.b+", got "+r.b,r.c))},
skt(a){this.b=t.qr.a(a)},
sks(a){this.c=t.dO.a(a)}}
A.u7.prototype={
$1(a){var s
A.h(a)
if(a==="l")s="left"
else s=a==="r"?"right":"center"
return s},
$S:6}
A.u6.prototype={
$1(a){return t.Dy.a(a).a},
$S:126}
A.bp.prototype={}
A.d6.prototype={
jg(a,b){var s,r,q,p,o,n=this,m=t.d,l=A.a5(B.e6,!0,m),k=$.wV(),j=a.c
j===$&&A.c()
s=t.N
r=A.b(s,m)
for(q=l.length,p=0;p<q;++p){o=l[p]
r.H(0,A.l([o.a,o,o.b,o],s,m))}k.j(0,j,r)
m=a.b
m===$&&A.c()
m.I("copy",new A.mt(n))
m.I("cut",new A.mu(n))
m.I("paste",new A.mv(n))
B.a.O($.C7(),new A.mw(n))
B.a.O(b.a,new A.mx(n))},
hw(a,b,c){var s,r,q,p,o,n,m,l,k,j,i
t.P.a(a)
s=a.h(0,"code-block")
if(s!=null&&!J.A(s,!1)){r=new A.r(A.a([],t.t))
q=c==null?"":c
r.V(0,q,A.l(["code-block",s],t.N,t.z))
return r}if(b==null){p=a.ga6(a)?null:A.Y(a,t.N,t.z)
r=new A.r(A.a([],t.t))
r.V(0,c==null?"":c,p)
return r}r=this.a
q=r.b
q===$&&A.c()
t.A.a(q.a.ownerDocument).toString
o=new A.fl(t.m.a(new self.DOMParser())).fg(b,"text/html")
$.CF().ln(o)
n=o.gcq()
q=t.AK
m=A.b(t.I,q)
l=this.u2(n,m)
k=q.a(l[0])
j=q.a(l[1])
r=r.c
r===$&&A.c()
i=A.yv(r,n,k,j,m)
if(A.lq(i,"\n"))r=B.a.gK(i.a).ga9()==null||a.h(0,"table")!=null
else r=!1
if(r)return A.HB(i)
return i},
qY(a,b){return this.hw(B.l,a,b)},
lp(a,b){var s,r,q,p,o,n,m=a.a
if(A.I(m.defaultPrevented))return
m.preventDefault()
m=this.a
s=m.aX()
if(s==null)return
r=s.a
q=s.b
p=m.ep(r,q)
o=m.e
o===$&&A.c()
n=A.l(["html",o.m9(r,q),"text",p],t.N,t.z)
q=a.gcM()
if(q!=null){r=A.h(n.h(0,"text"))
q.a.setData("text/plain",r)}r=a.gcM()
if(r!=null){q=A.h(n.h(0,"html"))
r.a.setData("text/html",q)}if(b)A.iR(m,s)},
tV(a){var s=B.b.aN(a,A.D("\\r?\\n",!0,!1)),r=A.K(s)
return new A.an(s,r.i("x(1)").a(new A.my()),r.i("an<1>")).ab(0,"\n")},
tW(a){var s,r,q,p,o,n,m,l,k=this,j=null,i=a.a
if(!A.I(i.defaultPrevented)){s=k.a.c
s===$&&A.c()
s=A.m(t.T.a(s.d).a.getAttribute("contenteditable"))!=="true"}else s=!0
if(s)return
i.preventDefault()
i=k.a
r=i.d1(!0)
if(r==null){s=i.f
s===$&&A.c()
r=s.d}if(r==null)return
s=a.gcM()
q=s==null?j:A.h(s.a.getData("text/html"))
s=a.gcM()
p=s==null?j:A.h(s.a.getData("text/plain"))
s=q==null
if(s&&p==null){o=a.gcM()
n=o==null?j:A.h(o.a.getData("text/uri-list"))
if(n!=null)p=k.tV(n)}o=a.gcM()
m=o==null?j:o.gcz()
if(m==null)m=A.a([],t.jp)
if(s&&m.length!==0)if(k.kE(r,m))return
if(!s&&m.length!==0){i=i.b
i===$&&A.c()
t.A.a(i.a.ownerDocument).toString
i=t.d0
l=A.N(new A.ae(new A.fl(t.m.a(new self.DOMParser())).fg(q,"text/html").gcq().gan(),i),!0,i.i("o.E"))
if(l.length===1&&A.h(B.a.gF(l).a.tagName)==="IMG")if(k.kE(r,m))return}k.lq(r,q,p)},
kE(a,b){var s,r
t.wU.a(b)
s=this.a.w
s===$&&A.c()
r=s.c.h(0,"uploader")
if(!(r instanceof A.dp))return!1
r.ip(a,b)
return!0},
lq(a,b,c){var s,r,q=this.a,p=a.a,o=q.f
o===$&&A.c()
s=this.hw(o.aW(p,0),b,c)
r=new A.r(A.a([],t.t))
r.a8(p)
r.aY(a.b)
q.aM(r.bj(s),"user")
q.S(new A.G(p+A.G4(s),0),"silent")
q.b5()},
u2(a,b){var s,r,q
t.ml.a(b)
s=t.ee
r=A.a([],s)
q=A.a([],s)
B.a.O(this.c,new A.mC(q,r,a,b))
return[r,q]}}
A.mt.prototype={
$1(a){return this.a.lp(t.bV.a(t.f.a(a)),!1)},
$S:0}
A.mu.prototype={
$1(a){return this.a.lp(t.bV.a(t.f.a(a)),!0)},
$S:0}
A.mv.prototype={
$1(a){return this.a.tW(t.bV.a(t.f.a(a)))},
$S:0}
A.mw.prototype={
$1(a){var s,r
t.j.a(a)
s=J.aO(a)
r=t.z6
B.a.k(this.a.c,[s.h(a,0),r.a(r.a(s.h(a,1)))])},
$S:31}
A.mx.prototype={
$1(a){var s=J.aO(a),r=t.z6
B.a.k(this.a.c,[s.h(a,0),r.a(r.a(s.h(a,1)))])},
$S:5}
A.my.prototype={
$1(a){var s
A.h(a)
s=a.length
if(s!==0){if(0>=s)return A.d(a,0)
s=a[0]!=="#"}else s=!1
return s},
$S:8}
A.mC.prototype={
$1(a){var s,r,q,p,o,n,m,l=this
t.j.a(a)
s=J.aO(a)
r=s.h(a,0)
q=t.z6.a(s.h(a,1))
switch(r){case 3:B.a.k(l.a,q)
break
case 1:B.a.k(l.b,q)
break
default:s=t.e
p=new A.a1(A.a(A.h(r).split(","),t.s),t.C.a(new A.mz()),s).fJ(0,s.i("x(ad.E)").a(new A.mA()))
for(s=J.U(p.a),o=new A.dq(s,p.b,p.$ti.i("dq<1>")),n=l.c,m=l.d;o.l();)B.a.O(n.a_(s.gq()),new A.mB(m,q))
break}},
$S:31}
A.mz.prototype={
$1(a){return B.b.R(A.h(a))},
$S:6}
A.mA.prototype={
$1(a){return A.h(a).length!==0},
$S:8}
A.mB.prototype={
$1(a){var s
t.T.a(a)
s=this.a
if(s.h(0,a)==null)s.j(0,a,A.a([],t.ee))
s=s.h(0,a)
s.toString
B.a.k(s,this.b)},
$S:30}
A.wO.prototype={
$2(a,b){t.D.a(a)
return t.z6.a(b).$3(this.a,a,this.b)},
$S:35}
A.wP.prototype={
$2(a,b){var s,r,q,p,o,n=this,m=t.D
m.a(a)
t.I.a(b)
s=n.a
r=n.b
q=n.d
p=A.yv(s,b,r,n.c,q)
if(A.v(b.a.nodeType)===1){p=B.a.ag(r,p,new A.wM(b,s),m)
o=q.h(0,b)
if(o!=null)p=B.a.ag(o,p,new A.wN(b,s),m)}return a.bj(p)},
$S:130}
A.wM.prototype={
$2(a,b){t.D.a(a)
return t.z6.a(b).$3(this.a,a,this.b)},
$S:35}
A.wN.prototype={
$2(a,b){t.D.a(a)
return t.z6.a(b).$3(this.a,a,this.b)},
$S:35}
A.vE.prototype={
$3(a,b,c){t.I.a(a)
return A.hf(t.D.a(b),this.a,!0,t._.a(c))},
$C:"$3",
$R:3,
$S:7}
A.ws.prototype={
$2(a,b){var s
A.h(a)
s=this.a
s.a=A.hf(s.a,a,b,this.b)},
$S:2}
A.uL.prototype={
$2(a,b){var s
if(b!=null)s=!(typeof b=="string"&&b.length===0)
else s=!1
if(s)this.a.j(0,A.p(a),b)},
$S:16}
A.wt.prototype={
$1(a){return B.b.R(A.h(a))},
$S:6}
A.wu.prototype={
$1(a){return A.h(a).length!==0},
$S:8}
A.wv.prototype={
$2(a,b){var s
A.h(a)
s=this.a
s.a=A.hf(s.a,a,b,this.b)},
$S:2}
A.eu.prototype={
nc(a,b){var s=this,r=null,q=t.D5,p=A.a([],q)
q=A.a([],q)
s.c!==$&&A.ai()
s.c=new A.pM(p,q)
s.d=0
s.e=!1
s.f=null
a.d.av("editor-change",new A.nv(s,b))
q=a.x
q===$&&A.c()
q.co(new A.av("z",!0,!1,!1,!1,!1,r,r,r,r,r,r,r),new A.nw(s))
q.co(new A.av("z",!0,!0,!1,!1,!1,r,r,r,r,r,r,r),new A.nx(s))
q.co(new A.av("Z",!0,!0,!1,!1,!1,r,r,r,r,r,r,r),new A.ny(s))
if(!A.BL())q.co(new A.av("y",!0,!1,!1,!1,!1,r,r,r,r,r,r,r),new A.nz(s))
q=a.b
q===$&&A.c()
q.I("beforeinput",new A.nA(s))},
dh(a,b){var s,r,q,p,o,n,m=this,l=m.c
if(a==="undo"){l===$&&A.c()
s=l.a}else{l===$&&A.c()
s=l.b}if(b==="undo"){l===$&&A.c()
r=l.a}else{l===$&&A.c()
r=l.b}l=s.length
if(l===0)return
if(0>=l)return A.d(s,-1)
q=s.pop()
p=q.a
l=m.a
o=l.e
o===$&&A.c()
n=p.e9(o.b)
B.a.k(r,new A.fB(n,A.yu(q.b,n)))
m.d=0
m.e=!0
l.aM(p,"user")
m.e=!1
m.qe(q)},
u7(a,b){var s,r,q,p,o,n,m,l=this
if(a.a.length===0)return
s=l.c
s===$&&A.c()
B.a.M(s.b)
r=a.e9(b)
q=l.f
p=Date.now()
o=l.d
o===$&&A.c()
n=l.b
if(o+n.a>p&&s.a.length!==0){p=s.a
if(0>=p.length)return A.d(p,-1)
m=p.pop()
r=r.c3(m.a)
q=m.b}else l.d=p
if(r.a.length===0)return
B.a.k(s.a,new A.fB(r,q))
s=s.a
if(s.length>n.b)B.a.cC(s,0)},
qe(a){var s,r,q=a.b
if(q!=null){this.a.S(q,"user")
return}s=this.a
r=s.c
r===$&&A.c()
s.S(new A.G(A.Is(r,a.a),0),"user")},
srh(a){this.f=t.kr.a(a)}}
A.nv.prototype={
$4(a,b,c,d){var s,r=J.a3(a)
if(r.n(a,"selection-change")){if(b instanceof A.G&&!J.A(d,"silent"))this.a.srh(b)
return}if(!r.n(a,"text-change"))return
r=this.a
s=r.e
s===$&&A.c()
if(s)return
s=t.D
s.a(b)
if(!this.b.c||J.A(d,"user"))r.u7(b,s.a(c))
else{s=r.c
s===$&&A.c()
A.Bs(s.a,b)
A.Bs(s.b,b)}r.f=A.yu(r.f,b)},
$1(a){return this.$4(a,null,null,null)},
$2(a,b){return this.$4(a,b,null,null)},
$3(a,b,c){return this.$4(a,b,c,null)},
$C:"$4",
$R:1,
$D(){return[null,null,null]},
$S:52}
A.nw.prototype={
$2(a,b){this.a.dh("undo","redo")
return null},
$S:16}
A.nx.prototype={
$2(a,b){this.a.dh("redo","undo")
return null},
$S:16}
A.ny.prototype={
$2(a,b){this.a.dh("redo","undo")
return null},
$S:16}
A.nz.prototype={
$2(a,b){this.a.dh("redo","undo")
return null},
$S:16}
A.nA.prototype={
$1(a){t.f.a(a)
if(!(a instanceof A.ev))return
if(a.ghU()==="historyUndo"){this.a.dh("undo","redo")
a.a.preventDefault()}else if(a.ghU()==="historyRedo"){this.a.dh("redo","undo")
a.a.preventDefault()}},
$S:0}
A.cu.prototype={}
A.pM.prototype={}
A.fB.prototype={}
A.vQ.prototype={
$2(a,b){var s
A.v(a)
t.Q.a(b)
if(b.a==="delete"){s=b.b
if(s==null)s=0}else s=0
return a+s},
$S:24}
A.uB.prototype={
$2(a,b){var s
A.v(a)
s=t.Q.a(b).b
return a+(s==null?0:s)},
$S:24}
A.dK.prototype={}
A.ey.prototype={
nf(a,b){var s,r,q=this,p=a.eU("ql-image-resize-overlay")
q.c!==$&&A.ai()
q.c=p
q.o0()
p=a.b
p===$&&A.c()
p.I("click",q.gpE())
p.I("scroll",new A.nM(q))
p=a.a
p.I("click",q.gpA())
p.I("mousedown",q.gpC())
p=p.a
s=t.A
r=s.a(p.ownerDocument)
r.toString
new A.bu(r).gcq().I("mousemove",q.gpy())
p=s.a(p.ownerDocument)
p.toString
new A.bu(p).gcq().I("mouseup",q.gpG())
a.d.av("text-change",new A.nN(q,a))},
o0(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this.c
c===$&&A.c()
c.ga2().sbR("display:none;position:absolute;z-index:1000;box-sizing:border-box;border:2px solid #2b7cff;pointer-events:none;")
for(s=t.m,r=this.a,q=r.a.a,p=t.A,o=t.O,n=t.g,m=t.N,l=0;l<8;++l){k=B.dH[l]
j=s.a(p.a(q.ownerDocument).createElement("span"))
s.a(j.classList).add("ql-image-resize-handle")
j.setAttribute("data-handle",k)
j.setAttribute("title","Redimensionar imagem")
i=new A.f(A.b(o,n),j).ga2()
h=A.l(["nw","left:-6px;top:-6px;cursor:nwse-resize","n","left:50%;top:-6px;cursor:ns-resize","ne","right:-6px;top:-6px;cursor:nesw-resize","e","right:-6px;top:50%;cursor:ew-resize","se","right:-6px;bottom:-6px;cursor:nwse-resize","s","left:50%;bottom:-6px;cursor:ns-resize","sw","left:-6px;bottom:-6px;cursor:nesw-resize","w","left:-6px;top:50%;cursor:ew-resize"],m,m).h(0,k)
i=i.a
i.cssText="position:absolute;width:10px;height:10px;background:#fff;border:2px solid #2b7cff;box-sizing:border-box;pointer-events:auto;"+A.p(h)
s.a(c.a.appendChild(j))}m=s.a(p.a(q.ownerDocument).createElement("span"))
s.a(m.classList).add("ql-image-layout-toolbar")
new A.f(A.b(o,n),m).ga2().sbR("position:absolute;left:0;top:-34px;display:flex;gap:0;padding:2px;background:#fff;border:1px solid #bbb;border-radius:4px;box-shadow:0 2px 6px rgba(0,0,0,.18);pointer-events:auto;")
r=r.w
r===$&&A.c()
g=r.b.b===B.C
for(r=B.fN.gao(),r=r.gJ(r),j=this.y;r.l();){i=r.gq()
h=s.a(p.a(q.ownerDocument).createElement("button"))
f=new A.f(A.b(o,n),h)
h.setAttribute("type","button")
e=A.h(i.a)
h.setAttribute("data-image-wrap",e)
i=i.b
d=i.a
h.setAttribute("title",d)
h.setAttribute("aria-label",d)
s.a(h.classList).add("ql-image-layout-button")
d=f.ga2().a
d.cssText=u.d
f.saf(g?'<i class="ti ti-'+i.b+'" aria-hidden="true"></i>':A.Du(e))
B.a.k(j,f)
s.a(m.appendChild(h))}s.a(c.a.appendChild(m))},
pF(a){var s=this,r=t.f.a(a).gau()
if(r instanceof A.f&&A.h(r.a.tagName).toLowerCase()==="img"){t.T.a(r)
s.d=r
t.m.a(r.a.classList).add("ql-image-selected")
s.qi(r)
s.fi()}else s.bF()},
pB(a){var s,r
t.f.a(a)
s=a.gau()
if(s instanceof A.f&&!A.I(s.a.hasAttribute("data-image-wrap")))s=s.gaG()
if(!(s instanceof A.f))return
r=A.m(s.a.getAttribute("data-image-wrap"))
if(r!=null){this.qL(r)
a.a.preventDefault()
return}},
pD(a){var s,r
t.f.a(a)
s=a.gau()
if(!(s instanceof A.f))return
r=A.m(s.a.getAttribute("data-handle"))
if(r!=null)this.nI(r,a)},
nI(a,b){var s,r,q,p,o=this,n=o.d
if(n==null)return
s=$.y().a.ce(n)
if(s==null)return
o.e=a
r=b.a
q=new A.ca(r)
p=q.gkQ()
o.f=p
p=q.gkR()
o.r=p
o.w=A.aF(s.h(0,"width"))
o.x=A.aF(s.h(0,"height"))
r.preventDefault()},
pz(a){var s,r,q,p,o,n,m,l,k,j,i,h,g=this
t.f.a(a)
s=g.e
r=g.d
if(s==null||r==null)return
q=a.a
p=new A.ca(q)
o=p.gkQ()
n=o-g.f
o=p.gkR()
m=o-g.r
l=g.w
k=g.x
j=J.ly(s,"e")?l+n:l
if(B.b.v(s,"w"))j-=n
i=B.b.v(s,"s")?k+m:k
if(B.b.v(s,"n"))i-=m
if(g.b.b&&s.length===2&&k>0){h=l/k
if(Math.abs(n)>=Math.abs(m)){k=j/h
l=j}else{l=i*h
k=i}}else{k=i
l=j}g.ug(l,k)
q.preventDefault()},
pH(a){t.f.a(a)
this.e=null},
qi(a){var s,r,q=this.a,p=q.c
p===$&&A.c()
s=p.bx(a,!0).a
if(s==null)return
r=p.aP(s)
if(r<0)return
q.S(new A.G(r,s.E(0)),"user")},
bF(){var s=this,r=s.d
if(r!=null)t.m.a(r.a.classList).remove("ql-image-selected")
s.e=s.d=null
r=s.c
r===$&&A.c()
r.ga2().aa("display","none")},
fi(){var s,r,q=this.d
if(q==null)return
s=$.y().a.fs(q,this.a.a)
if(s==null)return
r=this.c
r===$&&A.c()
r=r.ga2()
r.aa("display","block")
r.aa("left",A.p(s.h(0,"left"))+"px")
r.aa("top",A.p(s.h(0,"top"))+"px")
r.aa("width",A.p(s.h(0,"width"))+"px")
r.aa("height",A.p(s.h(0,"height"))+"px")},
ug(a,b){var s,r,q,p=this.d
if(p==null)return
s=this.b.a
r=B.f.ah(Math.max(s,a))
q=B.f.ah(Math.max(s,b))
s=p.a
s.setAttribute("width",""+r)
s.setAttribute("height",""+q)
this.fi()},
qL(a){var s,r,q,p,o,n,m,l,k,j=this.d
if(j==null)return
s=B.jK.v(0,a)?a:"inline"
r=j.a
r.setAttribute("data-image-wrap",s)
q=s==="inline"?"inline":"paragraph"
r.setAttribute("data-anchor",q)
switch(s){case"left":j.ga2().sbR("float:left;display:block;margin:0 12px 8px 0;max-width:100%;")
break
case"right":j.ga2().sbR("float:right;display:block;margin:0 0 8px 12px;max-width:100%;")
break
case"center":j.ga2().sbR("float:none;display:block;margin:8px auto;max-width:100%;")
break
default:j.ga2().sbR("float:none;display:inline-block;margin:0;max-width:100%;")}for(r=this.y,q=r.length,p=t.m,o=0;o<r.length;r.length===q||(0,A.k)(r),++o){n=r[o]
m=n.a
l=A.m(m.getAttribute("data-image-wrap"))===s
m=p.a(m.classList)
A.I(m.toggle("ql-active",l))
m=n.ga2()
k=l?"#dbeafe":"transparent"
m=m.a
m.setProperty("background-color",k,"")
m=n.ga2()
k=l?"#1264d1":"#444"
m=m.a
m.setProperty("color",k,"")}this.fi()}}
A.nM.prototype={
$1(a){t.f.a(a)
return this.a.fi()},
$S:0}
A.nN.prototype={
$3(a,b,c){var s,r=this.a,q=r.d
if(q!=null){s=this.b.b
s===$&&A.c()
s=!s.v(0,q)}else s=!1
if(s)r.bF()},
$C:"$3",
$R:3,
$S:15}
A.dN.prototype={}
A.dM.prototype={
gp8(){$.y()
var s=t.m
s=A.h(s.a(s.a(self.window).navigator).userAgent)
return B.b.v(s.toLowerCase(),"android")},
oA(a){var s,r,q,p,o,n,m
t.f.a(a)
if(!(a instanceof A.ev))return
s=a.a
if(A.I(s.defaultPrevented))return
r=a.ghU()
if(r==null||!B.jR.v(0,r))return
q=this.a
p=q.r
p===$&&A.c()
if(p.c)return
o=a.mj()
if(o.length===0||B.a.gF(o).gdk())return
n=this.op(a)
if(n==null)return
q=q.f
q===$&&A.c()
m=q.i3(B.a.gF(o))
if(this.kk(m==null?null:q.i4(m),n))s.preventDefault()},
oE(a){var s=this.a.aX()
if(s==null)return
this.kk(s,"")},
op(a){var s,r,q=a.gri()
if(q!=null)return q
s=a.gcO()
if(s!=null&&B.a.v(s.guv(),"text/plain")){r=A.h(s.a.getData("text/plain"))
return r}return null},
kk(a,b){var s,r,q,p,o,n
if(a==null||a.b===0)return!1
s=b.length
r=this.a
if(s!==0){q=a.a
p=r.f
p===$&&A.c()
o=p.aW(q,1)
A.iR(r,a)
n=new A.r(A.a([],t.t))
n.a8(q)
n.V(0,b,o.a===0?null:o)
r.aM(n,"user")}else A.iR(r,a)
r.S(new A.G(a.a+s,0),"silent")
return!0}}
A.oj.prototype={}
A.bP.prototype={}
A.av.prototype={
iO(a){var s=this,r="shortKey",q="shiftKey",p="collapsed"
t.P.a(a)
if(a.p("key"))s.a=a.h(0,"key")
if(a.p(r))s.b=A.f1(a.h(0,r))
if(a.p(q))s.c=A.f1(a.h(0,q))
if(a.p("altKey"))s.d=A.f1(a.h(0,"altKey"))
if(a.p("metaKey"))s.e=A.f1(a.h(0,"metaKey"))
if(a.p("ctrlKey"))s.f=A.f1(a.h(0,"ctrlKey"))
if(a.p("prefix"))s.r=t.jT.a(a.h(0,"prefix"))
if(a.p("suffix"))s.w=t.jT.a(a.h(0,"suffix"))
if(a.p("format"))s.x=a.h(0,"format")
if(a.p("handler"))s.y=t.hh.a(a.h(0,"handler"))
if(a.p(p))s.z=A.f1(a.h(0,p))
if(a.p("empty"))s.Q=A.f1(a.h(0,"empty"))
if(a.p("offset"))s.as=A.lk(a.h(0,"offset"))}}
A.cT.prototype={}
A.cb.prototype={}
A.bD.prototype={
ng(a,b){var s,r,q,p=this,o=null,n="Backspace",m=t.N,l=A.aJ($.Cb().a,m,t.z)
l.H(0,b.a)
l.O(0,new A.o1(p))
p.co(new A.av("Enter",o,o,!1,!1,!1,o,o,o,o,o,o,o),p.grT())
p.co(new A.av("Enter",o,!1,o,o,o,o,o,o,o,o,o,o),new A.o2())
l=t.K
s=p.grI()
p.bh(new A.av(n,o,!1,!1,!1,!1,o,o,o,o,o,o,o),A.l(["collapsed",!0,"prefix",A.D("^.?$",!0,!1)],m,l),s)
p.bh(new A.av("Delete",o,!1,!1,!1,!1,o,o,o,o,o,o,o),A.l(["collapsed",!0,"suffix",A.D("^.?$",!0,!1)],m,l),p.grM())
r=t.v
q=p.grP()
p.bh(new A.av(n,o,!1,!1,!1,!1,o,o,o,o,o,o,o),A.l(["collapsed",!1],m,r),q)
p.bh(new A.av("Delete",o,!1,!1,!1,!1,o,o,o,o,o,o,o),A.l(["collapsed",!1],m,r),q)
p.bh(new A.av(n,o,o,o,o,o,o,o,o,o,o,o,o),A.l(["collapsed",!0,"offset",0],m,l),s)
s=p.a.b
s===$&&A.c()
s.I("keydown",p.grX())},
bh(a,b,c){var s,r=A.JA(a)
if(r==null){$.CD()
A.BV("ERROR: "+("Attempted to add invalid keyboard binding: "+A.p(a)))
return}if(t.G.b(b))r.iO(A.Y(b,t.N,t.z))
if(c!=null)r.y=c
s=r.a
s=t.j.b(s)?s:[s]
J.wX(s,new A.o0(this,r))},
co(a,b){return this.bh(a,null,b)},
qH(a){return this.bh(a,null,null)},
rY(a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=this
t.f.a(a2)
s=a2.a
if(A.I(s.defaultPrevented)||a1.p9(a2))return!1
r=a2 instanceof A.cv
q=r?A.h(s.key):null
p=r?A.v(s.keyCode):null
if(p===229)r=q==="Enter"||q==="Backspace"
else r=!1
if(r)return!1
r=a1.c
o=r.h(0,q)
n=J.wY(o==null?A.a([],t.ua):o)
if(p!=null){r=r.h(0,p)
B.a.H(n,r==null?A.a([],t.ua):r)}r=A.K(n)
o=r.i("an<1>")
m=A.N(new A.an(n,r.i("x(1)").a(new A.o6(a2)),o),!0,o.i("o.E"))
if(m.length===0)return!1
r=a1.a
l=r.aX()
if(l!=null){o=r.f
o===$&&A.c()
o=!o.dn()}else o=!0
if(o)return!1
o=l.a
k=r.c
k===$&&A.c()
j=k.ap(o)
i=j.a
if(i==null||!(i instanceof A.a0))return!1
h=k.cW(o)
g=h.a
f=l.b
e=f===0
d=e?h:k.cW(o+f)
c=d.a
b=g instanceof A.aM?B.b.t(A.h(t.y.a(g.d).a.data),0,h.b):""
a=c instanceof A.aM?B.b.L(A.h(t.y.a(c.d).a.data),d.b):""
k=e&&i.E(0)<=1
r=r.f
r===$&&A.c()
a0=B.a.c0(m,new A.o7(a1,new A.bP(e,k,j.b,b,a,r.aW(o,f),a2,i),l))
if(a0)s.preventDefault()
return a0},
p9(a){var s,r,q,p,o,n
for(q=[a,new A.ca(a.a)],p=0;p<2;++p){s=q[p]
if(s==null)continue
try{r=s.gcU()
if(A.ef(r)){o=r
return o}}catch(n){}}return!1},
rJ(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g
t.F.a(a)
t.i.a(b)
if(a.b>0){s=this.a
A.iR(s,a)
s.bE()
return}s=A.D("[\\uD800-\\uDBFF][\\uDC00-\\uDFFF]$",!0,!1)
r=s.b.test(b.d)?2:1
s=a.a
if(s!==0){q=this.a.c
q===$&&A.c()
q=q.E(0)<=1}else q=!0
if(q)return
p=Math.max(0,s-r)
q=this.a
o=q.c
o===$&&A.c()
n=o.ap(s).a
m=t.t
l=new A.r(A.a([],m))
l.a8(p)
l.aY(s-p)
if(b.c===0&&n!=null){k=s-1
j=o.ap(k).a
if(j!=null)if(!(j.gA()==="block"&&j.E(0)<=1)){i=n.P()
o=q.f
o===$&&A.c()
h=A.dG(i,o.aW(k,1))
if(h==null)h=A.b(t.N,t.z)
if(h.a!==0){g=new A.r(A.a([],m))
g.a8(Math.max(0,s+n.E(0)-2))
g.br(1,h)
l=l.c3(g)}}}q.aM(l,"user")
q.S(new A.G(p,0),"silent")
q.bE()},
rN(a,b){var s,r,q,p,o,n,m,l,k
t.F.a(a)
t.i.a(b)
if(a.b>0){s=this.a
A.iR(s,a)
s.bE()
return}s=A.D("^[\\uD800-\\uDBFF][\\uDC00-\\uDFFF]",!0,!1)
r=s.b.test(b.e)?2:1
s=a.a
q=this.a
p=q.c
p===$&&A.c()
if(s>=p.E(0)-r)return
o=p.ap(s).a
n=new A.r(A.a([],t.t))
n.a8(s)
n.aY(r)
if(o!=null&&b.c>=o.E(0)-1){m=p.ap(s+1).a
if(m!=null){l=o.P()
p=q.f
p===$&&A.c()
k=A.dG(l,p.aW(s,1))
if(k==null)k=A.b(t.N,t.z)
if(k.a!==0){n.a8(Math.max(0,m.E(0)-1))
n.br(1,k)}}}q.aM(n,"user")
q.S(new A.G(s,0),"silent")
q.bE()},
rQ(a,b){var s
t.F.a(a)
t.i.a(b)
s=this.a
A.iR(s,a)
s.bE()},
rU(a,b){var s,r,q,p
t.F.a(a)
s=A.b(t.N,t.z)
t.i.a(b).f.O(0,new A.o3(this,s))
r=new A.r(A.a([],t.t))
q=a.a
r.a8(q)
r.aY(a.b)
r.V(0,"\n",s.a===0?null:s)
p=this.a
p.aM(r,"user")
p.S(new A.G(q+1,0),"silent")
p.bE()
return!1},
p7(a,b,c){var s,r,q
if(t.oo.b(a))return a.$3(this,b,c)
try{s=A.x8(a,[b,c])
return s}catch(r){s=t.dz
if(s.b(A.bk(r)))try{q=A.x8(a,[b])
return q}catch(r){if(s.b(A.bk(r)))return A.x8(a,[this,b,c])
else throw r}else throw r}},
hZ(a,b){var s,r,q,p=J.a3(a)
if(p.n(a,b))return!0
if(a==null||b==null)return!1
s=t.G
if(s.b(a)&&s.b(b)){if(p.gm(a)!==b.gm(b))return!1
for(s=J.U(a.ga7());s.l();){r=s.gq()
if(!b.p(r))return!1
if(!this.hZ(p.h(a,r),b.h(0,r)))return!1}return!0}s=t.j
if(s.b(a)&&s.b(b)){s=J.aO(b)
if(p.gm(a)!==s.gm(b))return!1
for(q=0;q<p.gm(a);++q)if(!this.hZ(p.h(a,q),s.h(b,q)))return!1
return!0}return!1}}
A.o1.prototype={
$2(a,b){A.h(a)
if(b==null||J.A(b,!1))return
this.a.qH(b)},
$S:2}
A.o2.prototype={
$1(a){},
$S:17}
A.o0.prototype={
$1(a){var s=this.b,r=s.b,q=s.c,p=s.d,o=s.e,n=s.f,m=s.r,l=s.w,k=s.x,j=s.y,i=s.z,h=s.Q
s=s.as
J.j_(this.a.c.aQ(a,new A.o_()),new A.cT(a,r,q,p,o,n,m,l,k,j,i,h,s))},
$S:5}
A.o_.prototype={
$0(){return A.a([],t.ua)},
$S:136}
A.o6.prototype={
$1(a){return A.DJ(this.a,t.kH.a(a))},
$S:61}
A.o7.prototype={
$1(a){var s,r,q=this
t.kH.a(a)
s=a.z
if(s!=null&&s!==q.b.a)return!1
s=a.Q
if(s!=null&&s!==q.b.b)return!1
s=a.as
if(s!=null&&s!==q.b.c)return!1
s=a.x
if(t.j.b(s)){if(!J.j0(s,new A.o4(q.b)))return!1}else if(t.G.b(s))if(!J.CN(s.ga7(),new A.o5(q.a,a,q.b)))return!1
s=a.r
if(s!=null){s=s.b
s=!s.test(q.b.d)}else s=!1
if(s)return!1
s=a.w
if(s!=null){s=s.b
s=!s.test(q.b.e)}else s=!1
if(s)return!1
r=a.y
if(r==null)return!1
return!J.A(q.a.p7(r,q.c,q.b),!0)},
$S:61}
A.o4.prototype={
$1(a){return this.a.f.h(0,a)!=null},
$S:9}
A.o5.prototype={
$1(a){var s=this,r=s.b
if(J.A(J.ej(r.x,a),!0))return s.c.f.h(0,a)!=null
if(J.A(J.ej(r.x,a),!1))return s.c.f.h(0,a)==null
return s.a.hZ(J.ej(r.x,a),s.c.f.h(0,a))},
$S:9}
A.o3.prototype={
$2(a,b){var s
A.h(a)
s=this.a.a.c
s===$&&A.c()
if(s.z.aw(a,4)!=null&&!t.j.b(b))this.b.j(0,a,b)},
$S:2}
A.vH.prototype={
$2(a,b){this.a.e5(this.b.a,1,A.h(a),b,"user")},
$S:2}
A.wq.prototype={
$3(a,b,c){var s,r,q
t.p.a(a)
t.F.a(b)
s=this.a
r=t.i.a(c).f.h(0,s)
if(r!=null){q=J.a3(r)
r=!q.n(r,!1)&&!q.n(r,"")}else r=!1
a.a.aD(s,!r,"user")
return null},
$C:"$3",
$R:3,
$S:138}
A.oo.prototype={
ln(a){var s,r,q
for(s=this.a,r=s.length,q=0;q<r;++q)s[q].$1(a)},
$1(a){return this.ln(t.uF.a(a))}}
A.la.prototype={
gb_(){return this.c}}
A.kC.prototype={}
A.aU.prototype={}
A.dY.prototype={}
A.pW.prototype={
$1(a){var s,r
t.G.a(a)
s=A.p(a.h(0,"key"))
r=a.h(0,"label")
return new A.aU(s,A.p(r==null?a.h(0,"key"):r))},
$S:139}
A.dF.prototype={
gA(){return"code-token"},
gT(){return 3},
a1(){return A.x2(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))),this.gik())},
gik(){var s=$.lx().ba(t.T.a(this.d))
return typeof s=="string"&&s.length!==0?s:null},
P(){var s=this.gik()
return s==null?B.l:A.l(["code-token",s],t.N,t.z)},
N(a,b){var s,r
A.h(a)
if(a!=="code-token"){this.d6(a,b)
return}if(b==null||J.A(b,!1)){s=$.lx()
r=t.T.a(this.d)
s.Z(0,r)
t.m.a(r.a.classList).remove("ql-token")}else this.kr(b)},
G(a,b){var s=this
s.eA(t.k.a(a),t.h.a(b))
if(s.gik()==null){t.m.a(t.T.a(s.d).a.classList).remove("ql-token")
s.bX()}},
aq(){return this.G(null,null)},
kr(a){var s=t.T.a(this.d)
t.m.a(s.a.classList).add("ql-token")
$.lx().dc(0,s,a)}}
A.di.prototype={
gaO(){return new A.pV()},
a1(){return A.xv(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))},
P(){return A.l(["code-block",A.xx(t.T.a(this.d))],t.N,t.z)},
N(a,b){var s,r=this
A.h(a)
s=a==="code-block"
if(s&&b!=null&&!J.A(b,!1)){t.T.a(r.d).a.setAttribute("data-language",A.p(b))
return}if(s)if(b!=null){s=J.a3(b)
s=s.n(b,!1)||s.n(b,"")}else s=!0
else s=!1
if(s)r.b1(0,r.E(0),"code-token",!1)
r.dN(a,b)}}
A.pV.prototype={
$1(a){return a instanceof A.dF||a instanceof A.cM||a instanceof A.aM||a instanceof A.ap||B.a.c0($.Ep,new A.pU(a))},
$S:3}
A.pU.prototype={
$1(a){return t.Ez.a(a).$1(this.a)},
$S:140}
A.cV.prototype={
a1(){return A.xw(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))},
de(){var s,r=this
r.mY()
r.dy=!1
s=r.gaR()
if(s instanceof A.bh)s.cy.e1("scroll-blot-mount",r)},
N(a,b){var s,r,q
A.h(a)
if(a==="code-block"){this.dy=!0
for(s=this.e,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q)s[q].N(a,b)
return}this.j5(a,b)},
b1(a,b,c,d){if(c==="code-block")this.dy=!0
this.j6(a,b,c,d)},
t6(a0,a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=this
t.no.a(a0)
s=a.e
if(s.length===0)return
r=t.T.a(a.d).gan()
q=A.K(r)
p=q.i("an<1>")
o=A.N(new A.an(r,q.i("x(1)").a(new A.pS(a)),p),!1,p.i("o.E"))
p=A.K(o)
n=new A.a1(o,p.i("e(1)").a(new A.pT()),p.i("a1<1,e>")).ab(0,"\n")+"\n"
m=a.gh7()
if(!a1&&!a.dy&&a.fr===n)return
if(B.b.R(n).length!==0||a.fr==null){l=new A.r(A.a([],t.t))
for(r=s.length,k=0;k<s.length;s.length===r||(0,A.k)(s),++k){j=s[k]
if(j instanceof A.a0)l=l.bj(A.By(j,!1))}for(s=l.hD(a0.$2(n,m)).a,r=s.length,q=t.N,p=t.z,i=0,k=0;k<s.length;s.length===r||(0,A.k)(s),++k){h=s[k]
if(h.a==="retain"){g=h.b
f=g==null?0:g}else f=0
if(f===0)continue
g=h.d
if(g==null)e=null
else e=A.Y(g,q,p)
if(e!=null)for(g=new A.cx(e,e.r,A.u(e).i("cx<1>")),g.c=e.e;g.l();){d=g.d
c=d==="code-block"
if(c||d==="code-token"){b=e.h(0,d)
if(c)a.dy=!0
a.j6(i,f,d,b)}}i+=f}}a.fr=n
a.dy=!1},
cT(a,b){return'<pre data-language="'+this.gh7()+'">\n'+B.aF.cu(this.kS(a,b))+"\n</pre>"},
G(a,b){var s,r,q=this
q.ez(t.k.a(a),t.h.a(b))
s=q.f
if(q.a!=null&&q.e.length!==0&&s!=null){r=q.gh7()
if(A.BY(s)!==r)A.C3(s,r)}},
aq(){return this.G(null,null)},
gh7(){var s=this.e,r=s.length===0?null:B.a.gF(s)
if(r instanceof A.di)return A.xx(t.T.a(r.d))
return"plain"}}
A.pS.prototype={
$1(a){return!t.I.a(a).n(0,this.a.f)},
$S:141}
A.pT.prototype={
$1(a){var s=A.m(t.I.a(a).a.textContent)
return s==null?"":s},
$S:142}
A.eE.prototype={
nl(a,b){var s,r=this,q=a.c
q===$&&A.c()
A.zX(q.z)
q=A.b(t.N,t.v)
for(s=J.U(b.b);s.l();)q.j(0,s.gq().a,!0)
t.m0.a(q)
r.c!==$&&A.ai()
r.snz(q)
r.td()
r.pe()},
td(){this.a.d.av("scroll-blot-mount",new A.q1(this))},
e6(a,b){var s,r,q,p,o=this.a,n=o.f
n===$&&A.c()
if(n.r)return
o.ad("user")
s=o.aX()
if(a==null){n=o.c
n===$&&A.c()
n=n.a4(t.ao)
r=A.N(n,!0,n.$ti.i("o.E"))}else r=A.a([a],t.k7)
for(n=r.length,q=this.gt8(),p=0;p<r.length;r.length===n||(0,A.k)(r),++p)r[p].t6(q,b)
o.ad("silent")
if(s!=null)o.S(s,"silent")},
t5(){return this.e6(null,!1)},
lh(a,b){var s,r,q,p=this,o=p.c
o===$&&A.c()
s=o.h(0,b)===!0?b:"plain"
if(s!=="plain"){o=p.b
r=o.c
if(r!=null)return r.$2(a,s)
q=o.d
if(q!=null)return p.qD(q.$2(a,s),s)
return p.nN(a,s)}return p.ke(a,s)},
t9(a){return this.lh(a,"plain")},
nN(a,b){var s,r,q,p,o,n,m,l,k,j,i=new A.r(A.a([],t.t))
for(s=A.Iy(a,b),r=s.length,q=t.N,p=t.z,o=0;o<s.length;s.length===r||(0,A.k)(s),++o){n=s[o]
m=n.b
l=m==null?null:A.l(["code-token",m],q,p)
k=n.a.split("\n")
for(j=0;j<k.length;++j){if(j!==0)i.V(0,"\n",A.l(["code-block",b],q,p))
m=k[j]
if(m.length!==0)i.V(0,m,l)}}return i},
qD(a,b){var s,r,q,p=this.a,o=p.b
o===$&&A.c()
t.A.a(o.a.ownerDocument).toString
s=new A.fl(t.m.a(new self.DOMParser())).fg('<div class="ql-code-block">'+a+"</div>","text/html").gcq().gf6()
if(!(s instanceof A.f))return this.ke(a,b)
o=t.ee
r=A.a([new A.pZ()],o)
q=A.a([new A.q_(b)],o)
p=p.c
p===$&&A.c()
return A.yv(p,s,r,q,A.b(t.I,t.AK))},
pe(){this.a.d.av("scroll-optimize",new A.pY(this))},
ke(a,b){var s,r,q,p,o=new A.r(A.a([],t.t)),n=a.split("\n")
for(s=t.N,r=t.z,q=0;q<n.length;++q){if(q!==0)o.V(0,"\n",A.l(["code-block",b],s,r))
p=n[q]
if(p.length!==0)o.aE(0,p)}return o},
snz(a){this.c=t.m0.a(a)}}
A.q1.prototype={
$1(a){var s,r,q,p,o,n,m,l,k
if(!(a instanceof A.cV))return
if(a.f!=null)return
s=this.a
r=s.a.b
r===$&&A.c()
r=t.A.a(r.a.ownerDocument)
q=t.m
p=q.a(r.createElement("select"))
o=new A.f(A.b(t.O,t.g),p)
for(n=J.U(s.b.b);n.l();){m=n.gq()
l=q.a(r.createElement("option"))
l.textContent=m.b
l.setAttribute("value",m.a)
q.a(p.appendChild(l))}o.I("change",new A.q0(s,o,a))
a.kK(o)
s=a.e
if(s.length!==0){k=B.a.gF(s)
if(k instanceof A.di)A.C3(o,A.xx(t.T.a(k.d)))}},
$S:17}
A.q0.prototype={
$1(a){var s,r,q
t.f.a(a)
s=A.BY(this.b)
if(s==null)s="plain"
r=this.c
r.N("code-block",s)
q=this.a
q.a.bE()
q.e6(r,!0)},
$S:0}
A.pZ.prototype={
$3(a,b,c){var s,r
t.I.a(a)
t.D.a(b)
if(!(a instanceof A.f))return b
s=$.lx().ba(a)
if(s!=null)r=s!==""
else r=!1
if(r){r=new A.r(A.a([],t.t))
r.br(b.a.length,A.l(["code-token",s],t.N,t.z))
return b.c3(r)}return b},
$C:"$3",
$R:3,
$S:62}
A.q_.prototype={
$3(a,b,c){var s,r,q,p,o,n
t.I.a(a)
t.D.a(b)
s=A.m(a.a.textContent)
r=(s==null?"":s).split("\n")
for(s=this.a,q=t.N,p=t.z,o=0;o<r.length;++o){if(o!==0)b.V(0,"\n",A.l(["code-block",s],q,p))
n=r[o]
if(n.length!==0)b.aE(0,n)}return b},
$C:"$3",
$R:3,
$S:62}
A.pY.prototype={
$1(a){var s=this.a,r=s.d
if(r!=null)r.eX()
s.d=A.rF(s.b.a,new A.pX(s))},
$S:17}
A.pX.prototype={
$0(){var s=this.a
s.d=null
s.t5()},
$S:1}
A.fI.prototype={}
A.bF.prototype={
nm(a,b){var s=this
s.nL()
s.pd()
a.d.av("text-change",new A.rA(s))
s.c1()},
nL(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e=f.a,d=e.eU("ql-table-context-toolbar")
f.d!==$&&A.ai()
f.d=d
d.a.setAttribute("role","toolbar")
d.a.setAttribute("aria-label","Ferramentas da tabela")
d.ga2().sbR("display:none;position:absolute;z-index:1100;height:40px;align-items:center;padding:4px;gap:2px;box-sizing:border-box;background:#fff;border:1px solid #ccced1;border-radius:2px;box-shadow:0 1px 2px 1px rgba(0,0,0,.15);")
s=[new A.c3(["row-insert-top","Inserir linha acima","table-row-above",f.gtn()]),new A.c3(["row-insert-bottom","Inserir linha abaixo","table-row-below",f.gtq()]),new A.c3(["column-insert-left","Inserir coluna \xe0 esquerda","table-column-left",f.gtg()]),new A.c3(["column-insert-right","Inserir coluna \xe0 direita","table-column-right",f.gti()]),new A.c3(["row-remove","Excluir linha","table-delete-row",f.ghz()]),new A.c3(["column-remove","Excluir coluna","table-delete-column",f.ghy()]),new A.c3(["arrow-merge","Mesclar com a c\xe9lula \xe0 direita","table-merge",f.gtL()]),new A.c3(["arrows-split","Dividir c\xe9lula","table-split",f.gmE()]),new A.c3(["table-off","Excluir tabela","table-delete",f.gf1()])]
r=e.w
r===$&&A.c()
q=r.b.b===B.C
for(r=t.m,p=e.a.a,o=t.A,n=t.O,m=t.g,l=0;l<9;++l){k=s[l]
j=r.a(o.a(p.ownerDocument).createElement("button"))
i=new A.f(A.b(n,m),j)
j.setAttribute("type","button")
h=k.a
j.setAttribute("title",h[1])
j.setAttribute("aria-label",h[1])
j.setAttribute("data-table-action",h[2])
g=i.ga2().a
g.cssText=u.d
if(q){h=B.fe.h(0,h[0])
h='<i class="ti ti-'+(h==null?"table":h)+'" aria-hidden="true"></i>'}else h=A.Ey(h[2])
i.saf(h)
i.I("mousedown",new A.rn())
i.I("click",new A.ro(f,k))
r.a(d.a.appendChild(j))}d=e.b
d===$&&A.c()
d.I("click",new A.rp(f))
d.I("keyup",new A.rq(f))
d.I("scroll",new A.rr(f))
e.d.av("selection-change",new A.rs(f))},
cF(){var s,r,q,p,o,n,m,l,k,j=this,i="display",h=j.f
if(h!=null){s=j.a.b
s===$&&A.c()
s=!s.v(0,h)}else s=!1
if(s){j.f=j.e=null
h=null}s=j.a
r=s.f
r===$&&A.c()
q=j.cf(r.bb(0))
r=q.c
if(r!=null){j.e=r
h=t.T.a(r.d)
j.f=h}if(h==null){s=j.d
s===$&&A.c()
s.ga2().aa(i,"none")
return}r=q.a
p=r==null?null:t.T.a(r.d)
if(p==null)p=h
s=s.a
o=$.y().a.fs(p,s)
if(o==null){s=j.d
s===$&&A.c()
s.ga2().aa(i,"none")
return}r=o.h(0,"width")
n=r==null?null:r
if(n==null)n=0
m=A.v(s.a.clientWidth)
l=B.f.aC(A.aF(o.h(0,"left"))+(n-286)/2,0,Math.max(0,m-286))
k=B.f.aC(A.aF(o.h(0,"top"))-42,0,1/0)
s=j.d
s===$&&A.c()
s=s.ga2()
s.aa(i,"flex")
s.aa("width","286px")
s.aa("left",A.p(l)+"px")
s.aa("top",A.p(k)+"px")},
c1(){var s,r,q,p,o,n,m=this
if(m.c)return
m.c=!0
try{m.b6()
m.jL()
p=m.a.c
p===$&&A.c()
p=p.a4(t.cB)
s=A.N(p,!0,p.$ti.i("o.E"))
for(p=s,o=p.length,n=0;n<p.length;p.length===o||(0,A.k)(p),++n){r=p[n]
r.qM()}for(p=s,o=p.length,n=0;n<p.length;p.length===o||(0,A.k)(p),++n){q=p[n]
m.pu(q)}m.qG()
m.b6()}finally{m.c=!1}},
qG(){var s,r,q,p,o,n,m="contextToolbarBound",l=this.a.c
l===$&&A.c()
l=l.a4(t.Fc)
s=l.$ti
l=new A.H(l.a(),s.i("H<1>"))
r=t.T
s=s.c
for(;l.l();){q=l.b
if(q==null)q=s.a(q)
p=r.a(q.d)
o=p.a
n=A.h2(m)
if(A.m(o.getAttribute(n))==="true")continue
o.setAttribute(A.h2(m),"true")
p.I("click",new A.rz(this,q))}},
dZ(){var s=this,r=s.cG(),q=r.a,p=r.c
if(q==null||p==null)return
q.f0(p.ht())
s.b6()
s.c1()
s.b6()},
e_(){var s=this,r=s.cG().b
if(r==null)return
r.Y(0)
s.b6()
s.c1()
s.b6()},
e0(){var s,r,q,p=this,o=p.cG().a
if(o==null)return
s=p.a
r=s.c
r===$&&A.c()
q=r.aP(o)
o.Y(0)
p.b6()
p.c1()
p.b6()
s.S(new A.G(B.f.aA(B.d.aC(q,0,r.E(0))),0),"silent")},
tM(){var s,r,q,p,o,n,m,l=this,k=l.e
if(k==null){s=l.a.f
s===$&&A.c()
k=l.cf(s.bb(0)).c}s=k==null
if(s)r=null
else{q=k.a
r=q instanceof A.b2?q:null}if(s||r==null)return
p=k.ht()
if(p<0||p+1>=r.e.length)return
s=r.e
q=p+1
if(!(q>=0&&q<s.length))return A.d(s,q)
o=s[q]
if(!(o instanceof A.aG))return
s=k.gcs()
q=o.gcs()
n=t.T
m=A.m(n.a(o.d).a.textContent)
if(m==null)m=""
if(m.length!==0)k.aF(k.E(0)>0?k.E(0)-1:0,m)
o.Y(0)
k.iV(s+q,k.gfl())
l.e=k
l.f=n.a(k.d)
l.cF()},
mF(){var s,r,q,p,o,n,m,l=this,k=l.e
if(k==null){s=l.a.f
s===$&&A.c()
k=l.cf(s.bb(0)).c}s=k==null
if(s)r=null
else{q=k.a
r=q instanceof A.b2?q:null}if(s||r==null||k.gcs()<=1)return
p=k.gcs()
o=k.c
k.mA(k.gfl())
for(s=k.d,q=t.T,n=1;n<p;++n){m=A.kx(A.m(q.a(s).a.getAttribute("data-row")))
r.D(m,o)
m.aq()}l.e=k
l.f=q.a(s)
l.cF()},
th(){this.c5(0)},
tj(){this.c5(1)},
tp(){this.c6(0)},
tr(){this.c6(1)},
c7(a,b){var s,r,q,p,o,n,m,l=this,k=l.a,j=k.aX()
if(j==null)return
s=new A.r(A.a([],t.t))
r=j.a
s.a8(r)
for(q=t.N,p=t.z,o=0;o<a;++o){for(n=0,m="";n<b;++n)m+="\n"
s.V(0,m.charCodeAt(0)==0?m:m,A.l(["table","row-"+B.d.ac(B.I.am(1048576),36)],q,p))}k.aM(s,"user")
l.b6()
l.c1()
l.b6()
l.om()
k.S(new A.G(r,j.b),"silent")},
c5(a){var s,r,q,p,o,n=this,m=n.a,l=m.aX()
if(l==null)return
s=n.cf(l)
r=s.a
q=s.b
p=s.c
if(r==null||q==null||p==null)return
r.c5(p.ht()+a)
n.b6()
n.c1()
n.b6()
o=q.dw()
if(a===0)++o
m.S(new A.G(l.a+o,l.b),"silent")},
c6(a){var s,r,q,p,o=this,n=o.a,m=n.aX()
if(m==null)return
s=o.cf(m)
r=s.a
q=s.b
if(r==null||q==null)return
r.c6(q.dw()+a)
o.b6()
o.c1()
o.b6()
if(a>0)n.S(m,"silent")
else{p=q.e.length
n.S(new A.G(m.a+p,m.b),"silent")}},
pd(){this.a.d.av("scroll-optimize",new A.rx(this))},
b6(){var s=this.a.c
s===$&&A.c()
s.G(A.a([],t.B),A.l(["source","user"],t.N,t.z))},
ha(){var s=this.a.c
s===$&&A.c()
return s.a4(t.Fc).c0(0,new A.ry())},
jL(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=null,a4={},a5=this.a.c
a5===$&&A.c()
s=a5.e
r=J.xe(s.slice(0),A.K(s).c)
a4.a=a4.b=null
s=t.N
q=A.b(s,t.h1)
p=new A.rt(a4,q)
for(o=r.length,n=t.T,m=t.m,l=t.O,k=t.g,j=t.z,i=t.E,h=0;h<o;++h){g=r[h]
if(!(g instanceof A.aG)||g.a instanceof A.b2){p.$0()
continue}if(a4.b==null){a4.b=A.A6(a3)
f=A.zZ(a3)
a4.a=f
a4.b.D(f,a3)
e=a4.b
if(e.gT()===3){$.y().a.a===$&&A.c()
d=self
c=m.a(m.a(d.document).createElement("P"))
b=A.b(s,j)
a=A.a([],i)
a0=new A.a0(b,a,new A.f(A.b(l,k),c))
a0.D(new A.ap(new A.f(A.b(l,k),m.a(m.a(d.document).createElement("BR")))),a3)
d=a.length!==0?B.a.gK(a):a3
c=a.length!==0?B.a.gF(a):a3
a0.aT(e,d)
if(c instanceof A.ap&&c.a===a0){e=c.a
if(e!=null)e.aj(c)}b.M(0)
a5.aT(a0,g)}else a5.aT(e,g)}e=a4.a
e.toString
a1=A.m(n.a(g.d).a.getAttribute("data-row"))
if(a1==null)a1="row-"+B.d.ac(B.I.am(1048576),36)
a2=q.h(0,a1)
if(a2==null){a2=A.xE(a3)
q.j(0,a1,a2)
e.D(a2,a3)}a2.D(g,a3)}},
pu(a){var s,r,q,p,o,n,m,l,k,j,i=this,h=a.ig(),g=h.length
if(g===0)return
for(s=t.A7,r=s.i("o.E"),q=t.T,p=!1,o=0;n=h.length,o<n;h.length===g||(0,A.k)(h),++o){m=A.N(new A.ae(h[o].e,s),!0,r)
if(m.length===0)continue
l=B.a.gF(m)
if(!p&&A.m(q.a(l.d).a.getAttribute("data-row"))==null&&i.h6(l)){n=l.a
if(n!=null)n.aj(l)
i.p0(a,1)
p=!0}}if(p){for(o=0;o<h.length;h.length===n||(0,A.k)(h),++o){m=A.N(new A.ae(h[o].e,s),!0,r)
if(m.length===0)continue
k=B.a.gK(m)
if(i.h6(k)){g=k.a
if(g!=null)g.aj(k)}}return}for(j=!1,o=0;o<h.length;h.length===n||(0,A.k)(h),++o){m=A.N(new A.ae(h[o].e,s),!0,r)
if(m.length===0)continue
k=B.a.gK(m)
if(A.m(q.a(k.d).a.getAttribute("data-row"))==null&&i.h6(k)){g=k.a
if(g!=null)g.aj(k)
j=!0}}if(j)i.p_(a,1)},
h6(a){var s=a.e
if(s.length===0)return!0
return B.a.cR(s,new A.ru())},
p0(a,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=null
for(s=this.a,r=t.uO,q=t.m,p=t.O,o=t.g,n=t.N,m=t.z,l=t.E,k=0;k<a0;++k){j=s.c
j===$&&A.c()
i=j.z.a.h(0,"block")
if(i==null)A.a4(A.au('Unknown blot "block"',b))
h=r.a(i.c.$1(b))
if(h.e.length===0){$.y().a.a===$&&A.c()
h.D(new A.ap(new A.f(A.b(p,o),q.a(q.a(self.document).createElement("BR")))),b)}if(h.gT()===3){$.y().a.a===$&&A.c()
g=self
f=q.a(q.a(g.document).createElement("P"))
e=A.b(n,m)
d=A.a([],l)
c=new A.a0(e,d,new A.f(A.b(p,o),f))
c.D(new A.ap(new A.f(A.b(p,o),q.a(q.a(g.document).createElement("BR")))),b)
g=d.length!==0?B.a.gK(d):b
f=d.length!==0?B.a.gF(d):b
c.aT(h,g)
if(f instanceof A.ap&&f.a===c){g=f.a
if(g!=null)g.aj(f)}e.M(0)
j.aT(c,a)}else j.aT(h,a)}},
p_(a0,a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=null,a=a0.c
for(s=this.a,r=t.uO,q=t.m,p=t.O,o=t.g,n=t.N,m=t.z,l=t.E,k=0;k<a1;++k){j=s.c
j===$&&A.c()
i=j.z.a.h(0,"block")
if(i==null)A.a4(A.au('Unknown blot "block"',b))
h=r.a(i.c.$1(b))
if(h.e.length===0){$.y().a.a===$&&A.c()
h.D(new A.ap(new A.f(A.b(p,o),q.a(q.a(self.document).createElement("BR")))),b)}if(h.gT()===3){$.y().a.a===$&&A.c()
g=self
f=q.a(q.a(g.document).createElement("P"))
e=A.b(n,m)
d=A.a([],l)
c=new A.a0(e,d,new A.f(A.b(p,o),f))
c.D(new A.ap(new A.f(A.b(p,o),q.a(q.a(g.document).createElement("BR")))),b)
g=d.length!==0?B.a.gK(d):b
f=d.length!==0?B.a.gF(d):b
c.aT(h,g)
if(f instanceof A.ap&&f.a===c){g=f.a
if(g!=null)g.aj(f)}e.M(0)
j.aT(c,a)}else j.aT(h,a)}},
om(){var s,r=this.a.c
r===$&&A.c()
s=r.e
if(s.length===0)return
if(!(B.a.gK(s) instanceof A.cD))return
r.aF(r.E(0),"\n")
this.b6()},
cf(a){var s,r,q,p,o,n,m
this.jL()
s=a==null?this.a.aX():a
if(s==null)return B.aw
r=this.a.c
r===$&&A.c()
q=r.bv(new A.rB(),s.a)
p=q.a
if(!(p instanceof A.aG))return B.aw
o=p.a
n=o==null?null:o.a
m=n==null?null:n.a
if(o instanceof A.b2&&n instanceof A.cC&&m instanceof A.cD)return new A.ky(m,o,p,q.b)
return B.aw},
cG(){return this.cf(null)},
snB(a){this.f=t.q.a(a)}}
A.rA.prototype={
$3(a,b,c){var s
if(J.A(c,"silent"))return
s=this.a
if(s.ha())s.c1()},
$C:"$3",
$R:3,
$S:15}
A.rn.prototype={
$1(a){var s=t.f.a(a).a
s.preventDefault()
s.stopPropagation()},
$S:0}
A.ro.prototype={
$1(a){var s
t.f.a(a)
this.b.a[3].$0()
this.a.cF()
s=a.a
s.preventDefault()
s.stopPropagation()},
$S:0}
A.rp.prototype={
$1(a){var s,r=t.f.a(a).gau(),q=t.A,p=this.a,o=p.a
while(!0){if(r!=null){s=o.b
s===$&&A.c()
s=!r.n(0,s)}else s=!1
if(!s)break
if(r instanceof A.f&&A.h(r.a.tagName).toLowerCase()==="td"){p.snB(r)
p.cF()
return}s=r.a
if(q.a(s.parentNode)==null)r=null
else{s=q.a(s.parentNode)
s.toString
r=A.S(s)}}p.f=p.e=null
q=p.d
q===$&&A.c()
q.ga2().aa("display","none")},
$S:0}
A.rq.prototype={
$1(a){t.f.a(a)
return this.a.cF()},
$S:0}
A.rr.prototype={
$1(a){t.f.a(a)
return this.a.cF()},
$S:0}
A.rs.prototype={
$3(a,b,c){var s
if(a instanceof A.G&&this.a.cf(a).c==null){s=this.a
s.f=s.e=null}this.a.cF()},
$C:"$3",
$R:3,
$S:15}
A.rz.prototype={
$1(a){var s,r
t.f.a(a)
s=this.a
r=this.b
s.e=r
s.f=t.T.a(r.d)
s.cF()},
$S:0}
A.rx.prototype={
$2(a,b){var s
if(!t.o.b(a))return
if(!(J.j0(a,new A.rv())||this.a.ha()))return
s=this.a
s.a.d.lr("text-change",new A.rw(s))},
$S:32}
A.rv.prototype={
$1(a){var s,r=A.S(t.m.a(t.BX.a(a).a.target))
if(!(r instanceof A.f))return!1
s=A.h(r.a.tagName).toUpperCase()
return s==="TD"||s==="TR"||s==="TBODY"||s==="TABLE"},
$S:33}
A.rw.prototype={
$3(a,b,c){var s
if(J.A(c,"silent"))return
s=this.a
if(s.ha())s.c1()},
$C:"$3",
$R:3,
$S:15}
A.ry.prototype={
$1(a){t.Fc.a(a)
if(!(a.a instanceof A.b2))return!0
return A.m(t.T.a(a.d).a.getAttribute("data-row"))==null},
$S:145}
A.rt.prototype={
$0(){var s=this.a
s.a=s.b=null
this.b.M(0)},
$S:1}
A.ru.prototype={
$1(a){return t.U.a(a) instanceof A.ap},
$S:3}
A.rB.prototype={
$1(a){return a instanceof A.aG},
$S:9}
A.ky.prototype={}
A.uO.prototype={
$2(a,b){var s=typeof a=="string"?a:J.L(a)
return new A.F(s,b,t.dK)},
$S:25}
A.uo.prototype={
$2(a,b){var s=typeof a=="string"?a:J.L(a)
return new A.F(s,b,t.dK)},
$S:25}
A.us.prototype={
$2(a,b){var s=typeof a=="string"?a:J.L(a)
return new A.F(s,A.ur(b),t.dK)},
$S:25}
A.ut.prototype={
$2(a,b){return new A.F(A.h(a),A.Y(t.P.a(b),t.N,t.z),t.fq)},
$S:146}
A.vr.prototype={
$2(a,b){var s,r,q
A.h(a)
if(!t.G.b(b))return
s=A.y9(a)
r=A.iK(this.a,s.b)
q=A.iK(this.b,s.a)
if(r==null||q==null)return
this.c.j(0,""+(r+1)+":"+(q+1),A.cl(b).bo(0,new A.vq(),t.N,t.z))},
$S:2}
A.vq.prototype={
$2(a,b){return new A.F(A.h(a),A.ur(b),t.dK)},
$S:63}
A.uu.prototype={
$2(a,b){var s,r,q,p,o,n="attributes"
A.h(a)
s=this.a
r=s.h(0,a)
q=A.cl(r==null?A.b(t.N,t.z):r)
p=A.cl(b)
o=A.y3(A.bb(q.h(0,"content")).c3(A.bb(p.h(0,"content"))),A.z7(A.iO(q.h(0,n)),A.iO(p.h(0,n)),this.b))
if(o!=null)s.j(0,a,o)
else s.Z(0,a)},
$S:2}
A.uK.prototype={
$2(a,b){var s,r,q
A.h(a)
s=A.y9(a)
r=A.iK(this.a,s.b)
q=A.iK(this.b,s.a)
if(r==null||q==null)this.c.j(0,a,A.cl(b).bo(0,new A.uJ(),t.N,t.z))},
$S:2}
A.uJ.prototype={
$2(a,b){return new A.F(A.h(a),A.ur(b),t.dK)},
$S:63}
A.wF.prototype={
$3$keepNull(a,b,c){return A.FY(a,b,A.I(c))},
$2(a,b){return this.$3$keepNull(a,b,!1)},
$C:"$3$keepNull",
$R:2,
$D(){return{keepNull:!1}},
$S:148}
A.wG.prototype={
$3(a,b,c){return A.HA(a,b,A.I(c))},
$C:"$3",
$R:3,
$S:149}
A.wH.prototype={
$2(a,b){return A.GK(a,b)},
$S:150}
A.fH.prototype={}
A.ok.prototype={}
A.fK.prototype={}
A.fL.prototype={
gct(){return this.a}}
A.i3.prototype={
no(a,b){var s,r,q=this,p=$.y().a.a
p===$&&A.c()
s=b.a
if(s instanceof A.fK){p=t.m
p=p.a(p.a(self.document).createElement("div"))
r=new A.f(A.b(t.O,t.g),p)
p.setAttribute("role","toolbar")
A.HF(r,s)
s=a.a
p=s.gaG()
if(p!=null)p.D(r,s)
q.c=r
p=r}else if(typeof s=="string"){p=p.aI(s)
q.c=p}else{t.q.a(s)
q.c=s
p=s}if(p==null){$.CE()
A.BV("ERROR: Container required for toolbar")
return}t.m.a(p.a.classList).add("ql-toolbar")
q.c.I("mousedown",new A.rW(q))
p=b.b
if(p!=null)p.O(0,new A.rX(q))
q.q6()
p=q.c
p.toString
new A.rU(q).$1(p)
a.d.av("editor-change",new A.rY(q,a))},
ho(a){var s,r,q,p,o,n,m,l=this,k={}
k.a=""
for(s=a.a,r=new A.b9(t.m.a(s.classList)).gak(),q=r.length,p=0;p<q;++p){o=r[p]
if(B.b.a0(o,"ql-")){k.a=o
break}}r=k.a
if(r.length===0)return
k.a=B.b.L(r,3)
if(A.h(s.tagName).toLowerCase()==="button")s.setAttribute("type","button")
if(k.a==="table"&&A.h(s.tagName).toLowerCase()==="button")if(l.r==null){r=l.c
r.toString
l.r=A.Fh(l.a,r,a)}n=A.h(s.tagName).toLowerCase()==="select"
m=n?"change":"mousedown"
a.I(m,new A.rV(k,l,n,a))
B.a.k(l.d,[k.a,a])},
ad(a){var s,r,q,p
if(a==null)s=A.b(t.N,t.z)
else{r=a.a
q=a.b
p=this.a.f
p===$&&A.c()
s=p.aW(r,q)}B.a.O(this.d,new A.t0(this,a,s))},
oW(a,b){if(b.b===0)return!1
if(!B.k7.v(0,a))return!1
return this.oV(b,a)},
oV(a,b){var s,r,q,p,o,n,m,l,k=this.a.c
k===$&&A.c()
p=k.cA(a.a,a.b)
k=p.length
if(k<=1)return!1
for(o=null,n=!0,m=0;m<p.length;p.length===k||(0,A.k)(p),++m){s=p[m]
r=null
try{q=s.P()
r=J.ej(q,b)}catch(l){r=null}if(n){o=r
n=!1
continue}if(!J.A(r,o))return!0}return!1},
qI(a,b,c){var s,r,q,p,o=this
if(c!=null)s=c.length===0
else s=!0
r=s?!1:c
s=o.f
if(s==null){s=o.a.f
s===$&&A.c()
s=s.d}q=o.km(s)
if(q==null)return
p=o.e.h(0,b)
if(p!=null)p.$1(r)
else o.jP(q,b,r)
o.ad(q)},
jp(){var s=this.a,r=s.aX()
if(r==null){s=s.f
s===$&&A.c()
r=s.d}if(r!=null)this.f=r
return r},
km(a){var s,r=this,q=a==null?r.f:a
if(q==null){s=r.a.f
s===$&&A.c()
q=s.d}if(q==null)return null
r.f=q
s=r.a
s.e3(!0)
s.S(q,"silent")
return q},
jP(a,b,c){var s,r,q=this.a,p=q.c
p===$&&A.c()
p=p.z
s=p.aw(b,4)!=null||p.bq(b,260)!=null
p=a.a
r=a.b
if(s)q.e5(p,r,b,c,"user")
else q.f7(p,r,b,c,"user")},
q6(){var s,r,q,p,o=this,n="direction",m=o.e
if(!m.p("clean"))m.j(0,"clean",t.V.a(new A.rG(o)))
if(!m.p(n))m.j(0,n,t.V.a(new A.rH(o)))
if(!m.p("indent"))m.j(0,"indent",t.V.a(new A.rI(o)))
if(!m.p("link"))m.j(0,"link",t.V.a(new A.rM(o)))
if(!m.p("list"))m.j(0,"list",t.V.a(new A.rN(o)))
if(!m.p("table"))m.j(0,"table",t.V.a(new A.rO(o)))
for(s=A.l(["table-row-above",new A.rP(),"table-row-below",new A.rQ(),"table-column-left",new A.rR(),"table-column-right",new A.rS(),"table-delete-row",new A.rT(),"table-delete-column",new A.rJ(),"table-delete",new A.rK()],t.N,t.a6).gao(),s=s.gJ(s),r=t.V;s.l();){q=s.gq()
p=q.a
if(!m.p(p))m.j(0,A.h(p),r.a(new A.rL(o,q)))}},
gct(){return this.c}}
A.rW.prototype={
$1(a){t.f.a(a)
this.a.jp()
a.a.preventDefault()},
$S:0}
A.rX.prototype={
$2(a,b){this.a.e.j(0,A.h(a),t.V.a(b))},
$S:151}
A.rU.prototype={
$1(a){var s,r,q,p,o,n
for(s=a.gan(),r=s.length,q=this.a,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
if(!(o instanceof A.f))continue
n=A.h(o.a.tagName).toLowerCase()
if(n==="button"||n==="select")q.ho(o)
this.$1(o)}},
$S:30}
A.rY.prototype={
$4(a,b,c,d){var s=this.b.f
s===$&&A.c()
this.a.ad(s.bb(0))},
$C:"$4",
$R:4,
$S:40}
A.rV.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i=this
t.f.a(a)
s=i.b
r=s.jp()
q=!1
if(i.c){p=i.d.aI("option[selected]")
if(p!=null){o=A.m(p.a.getAttribute("value"))
q=o!=null&&o.length!==0&&o}}else{n=i.d.a
if(!A.I(t.m.a(n.classList).contains("ql-active"))){m=A.m(n.getAttribute("value"))
if(m==null)q=!0
else q=m.length===0?!1:m}a.a.preventDefault()}l=s.km(r)
if(l==null)return
n=s.e
k=i.a
j=n.h(0,k.a)
k=k.a
if(j!=null)n.h(0,k).$1(q)
else s.jP(l,k,q)
s.ad(l)},
$S:0}
A.t0.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this,d="ql-active",c=t.j
c.a(a)
s=J.aO(a)
r=A.h(s.h(a,0))
q=t.T.a(s.h(a,1))
s=q.a
if(A.h(s.tagName).toLowerCase()==="select"){p=q.a_("option")
s=e.b
o=s==null
n=!o&&e.a.oW(r,s)
m=new A.t1(p)
l=null
if(!o)if(!n){s=e.c
if(!s.p(r))l=m.$1(new A.rZ())
else if(!c.b(s.h(0,r))){k=s.h(0,r)
if(typeof k=="string"){c=A.D('"',!0,!1)
k=A.O(k,c,'\\"')}j=k==null?null:J.L(k)
l=m.$1(new A.t_(j==null?"":j))}}for(c=p.length,i=0;i<p.length;p.length===c||(0,A.k)(p),++i)p[i].a.removeAttribute("selected")
if(l!=null)l.a.setAttribute("selected","selected")}else if(e.b==null){t.m.a(s.classList).remove("ql-active")
s.setAttribute("aria-pressed","false")}else{c=e.c
if(A.I(s.hasAttribute("value"))){k=c.h(0,r)
h=A.m(s.getAttribute("value"))
g=h==null||h.length===0
c=J.a3(k)
f=!0
if(!c.n(k,h)){o=k==null
if(!(!o&&c.B(k)===h)){c=o&&g
f=c}}new A.b9(t.m.a(s.classList)).el(d,f)
s.setAttribute("aria-pressed",String(f))}else{f=c.h(0,r)!=null
new A.b9(t.m.a(s.classList)).el(d,f)
s.setAttribute("aria-pressed",String(f))}}},
$S:31}
A.t1.prototype={
$1(a){var s,r,q,p
t.ik.a(a)
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q]
if(A.ac(a.$1(p)))return p}return null},
$S:153}
A.rZ.prototype={
$1(a){return A.m(a.a.getAttribute("value"))==null},
$S:23}
A.t_.prototype={
$1(a){return A.m(a.a.getAttribute("value"))===this.a},
$S:23}
A.rG.prototype={
$1(a){var s,r,q,p=this.a.a,o=p.f
o===$&&A.c()
s=o.bb(0)
if(s==null)return
r=s.b
q=s.a
if(r===0)for(o=o.aW(q,r).gao(),o=o.gJ(o);o.l();)p.aD(o.gq().a,!1,"user")
else p.ua(q,r,"user")},
$S:5}
A.rH.prototype={
$1(a){var s,r,q,p="align",o="user",n=this.a.a,m=n.f
m===$&&A.c()
s=m.bb(0)
if(s==null)return
r=m.aW(s.a,s.b).h(0,p)
m=J.a3(a)
if(m.n(a,"rtl"))q=r==null||J.A(r,!1)
else q=!1
if(q)n.aD(p,"right",o)
else if((a==null||m.n(a,!1))&&J.A(r,"right"))n.aD(p,!1,o)
n.aD("direction",a,o)},
$S:5}
A.rI.prototype={
$1(a){var s,r,q,p,o,n="indent",m=this.a.a,l=m.f
l===$&&A.c()
s=l.bb(0)
if(s==null)return
r=l.aW(s.a,s.b)
l=r.h(0,n)
q=A.V(A.p(l==null?0:l),null)
if(q==null)q=0
l=J.a3(a)
if(l.n(a,"+1"))p=1
else p=l.n(a,"-1")?-1:0
o=q+(J.A(r.h(0,"direction"),"rtl")?p*-1:p)
if(o<=0)m.aD(n,!1,"user")
else m.aD(n,o,"user")},
$S:5}
A.rM.prototype={
$1(a){var s,r,q,p,o="link",n=this.a.a,m=n.f
m===$&&A.c()
r=m.bb(0)
if(r==null)return
q=m.aW(r.a,r.b).p(o)
if(a==null||J.A(a,!0)){if(q)n.aD(o,!1,"user")
if(!q){n=n.w
n===$&&A.c()
s=n.gil()
if(s!=null)try{s.hG(o)}catch(p){}}return}n.aD(o,a,"user")},
$S:5}
A.rN.prototype={
$1(a){var s,r,q,p="list",o="unchecked",n="user",m=this.a.a,l=m.f
l===$&&A.c()
s=l.bb(0)
if(s==null)return
r=l.aW(s.a,s.b)
if(J.A(a,"check")){q=r.h(0,p)
l=J.a3(q)
if(l.n(q,"checked")||l.n(q,o))m.aD(p,!1,n)
else m.aD(p,o,n)
return}m.aD(p,a,n)},
$S:5}
A.rO.prototype={
$1(a){var s,r,q,p,o=this.a.r
if(o!=null){s=o.d
s===$&&A.c()
r=t.m
if(A.I(r.a(s.a.classList).contains("ql-hidden"))){o.e6(0,0)
q=$.y()
o=o.f
o===$&&A.c()
p=q.a.ce(o)
if(p!=null){q=s.ga2()
q.aa("left",A.p(p.h(0,"left"))+"px")
q.aa("top",A.p(A.aF(p.h(0,"bottom"))+4)+"px")}r.a(s.a.classList).remove("ql-hidden")
s.ga2().aa("display","block")
o.a.setAttribute("aria-expanded","true")}else o.bF()}},
$S:5}
A.rP.prototype={
$1(a){t.o2.a(a).c6(0)
return null},
$S:14}
A.rQ.prototype={
$1(a){t.o2.a(a).c6(1)
return null},
$S:14}
A.rR.prototype={
$1(a){t.o2.a(a).c5(0)
return null},
$S:14}
A.rS.prototype={
$1(a){t.o2.a(a).c5(1)
return null},
$S:14}
A.rT.prototype={
$1(a){return t.o2.a(a).e_()},
$S:14}
A.rJ.prototype={
$1(a){return t.o2.a(a).dZ()},
$S:14}
A.rK.prototype={
$1(a){return t.o2.a(a).e0()},
$S:14}
A.rL.prototype={
$1(a){var s,r=this.a.a.w
r===$&&A.c()
s=r.c.h(0,"table")
if(s instanceof A.bF)this.b.b.$1(s)},
$S:5}
A.ue.prototype={
nr(a,b,c){var s,r,q,p,o,n,m,l,k,j=this,i=j.a.a.a,h=t.A,g=t.m,f=g.a(h.a(i.ownerDocument).createElement("div")),e=t.O,d=t.g
j.d!==$&&A.ai()
s=j.d=new A.f(A.b(e,d),f)
g.a(f.classList).add("ql-table-select-container")
g.a(s.a.classList).add("ql-hidden")
s.a.setAttribute("role","dialog")
s.a.setAttribute("aria-label","Escolher tamanho da tabela")
s.ga2().sbR("display:none;position:fixed;z-index:1200;width:224px;padding:8px;box-sizing:border-box;background:#fff;border:1px solid #ccced1;border-radius:2px;box-shadow:0 1px 2px 1px rgba(0,0,0,.15);")
f=g.a(h.a(i.ownerDocument).createElement("div"))
g.a(f.classList).add("ql-table-select-list")
new A.f(A.b(e,d),f).ga2().sbR("display:grid;grid-template-columns:repeat(10,18px);gap:3px;justify-content:center;")
for(r=j.c,q=1;q<=10;++q)for(p=""+q,o=p+" por ",n=1;n<=10;++n){m=g.a(h.a(i.ownerDocument).createElement("span"))
l=new A.f(A.b(e,d),m)
m.setAttribute("data-row",p)
k=""+n
m.setAttribute("data-column",k)
m.setAttribute("role","button")
m.setAttribute("aria-label",o+k)
k=l.ga2().a
k.cssText="width:18px;height:18px;border:1px solid #ccced1;box-sizing:border-box;background:#fff;"
l.I("mouseenter",new A.uf(j,q,n))
l.I("click",new A.ug(j,q,n))
B.a.k(r,l)
g.a(f.appendChild(m))}i=g.a(h.a(i.ownerDocument).createElement("div"))
j.e!==$&&A.ai()
d=j.e=new A.f(A.b(e,d),i)
g.a(i.classList).add("ql-table-select-label")
d.a.textContent="0 \xd7 0"
d.ga2().sbR("padding-top:8px;text-align:center;font-size:12px;")
i=s.a
g.a(i.appendChild(f))
g.a(i.appendChild(d.a))
g.a(j.b.a.appendChild(s.a))
s=c.a
s.setAttribute("aria-haspopup","dialog")
s.setAttribute("aria-expanded","false")
j.f!==$&&A.ai()
j.f=c},
e6(a,b){var s,r,q,p,o,n,m,l,k,j
for(s=this.c,r=s.length,q=t.m,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
n=o.a
m=A.m(n.getAttribute("data-row"))
m.toString
l=A.bM(m,null)
m=A.m(n.getAttribute("data-column"))
m.toString
k=A.bM(m,null)
j=l<=a&&k<=b
n=q.a(n.classList)
A.I(n.toggle("ql-cell-selected",j))
n=o.ga2()
m=j?"#2b7cff":"#fff"
n=n.a
n.setProperty("background-color",m,"")
m=j?"#2b7cff":"#aaa"
n.setProperty("border-color",m,"")}s=this.e
s===$&&A.c()
s.a.textContent=""+a+" \xd7 "+b},
bF(){var s=this.d
s===$&&A.c()
t.m.a(s.a.classList).add("ql-hidden")
s.ga2().aa("display","none")
s=this.f
s===$&&A.c()
s.a.setAttribute("aria-expanded","false")}}
A.uf.prototype={
$1(a){t.f.a(a)
return this.a.e6(this.b,this.c)},
$S:0}
A.ug.prototype={
$1(a){var s,r,q,p,o=this
t.f.a(a)
s=o.a
r=s.a.w
r===$&&A.c()
q=r.c.h(0,"table-better")
if(q!=null)q.c7(o.b,o.c)
else{p=r.c.h(0,"table")
if(p instanceof A.bF)p.c7(o.b,o.c)}s.bF()
s=a.a
s.preventDefault()
s.stopPropagation()},
$S:0}
A.vx.prototype={
$1(a){var s,r
t.j.a(a)
s=t.m
r=s.a(s.a(self.document).createElement("span"))
s.a(r.classList).add("ql-formats")
J.wX(a,new A.vw(new A.f(A.b(t.O,t.g),r)))
s.a(this.b.a.appendChild(r))},
$S:31}
A.vw.prototype={
$1(a){var s,r,q
if(typeof a=="string")A.Bu(this.a,a,null)
else if(t.G.b(a)){s=J.ek(a.ga7())
r=a.h(0,s)
q=this.a
if(t.j.b(r))A.HH(q,A.h(s),r)
else A.Bu(q,A.h(s),r)}},
$S:5}
A.vy.prototype={
$1(a){var s=t.m,r=s.a(s.a(self.document).createElement("option")),q=J.a3(a)
if(!q.n(a,!1))r.setAttribute("value",q.B(a))
else r.setAttribute("selected","selected")
s.a(this.b.a.appendChild(r))},
$S:5}
A.fM.prototype={
oy(){var s=null,r=this.a.x
r===$&&A.c()
r.co(new A.av(A.a(["ArrowLeft","ArrowRight"],t.s),s,s,!1,!1,!1,s,s,s,s,s,s,0),new A.t7(this))},
oS(){var s=this.a.b
s===$&&A.c()
s.I("keydown",new A.t8(this))},
ol(){var s,r,q=this
q.d=Date.now()+100
if(q.c)return
q.c=!0
s=$.y().a.a
s===$&&A.c()
r=A.l_()
r.b=new A.t6(q,s,r)
s.I("selectionchange",r.bP())},
oT(){var s,r,q,p,o=$.y().a,n=o.iB()
if(n==null||!n.gdk()||n.b!==0)return
s=this.a.c
s===$&&A.c()
r=s.bx(n.a,!0).a
if(!(r instanceof A.z)||r.f==null)return
s=r.f
s.toString
q=t.T.a(r.d)
p=B.a.ae(q.gan(),s)
if(p<0)return
s=p+1
o.iU(q,s,q,s)}}
A.t7.prototype={
$2(a,b){var s,r,q,p,o,n,m,l
t.F.a(a)
t.i.a(b)
s=b.w
r=b.r
if(s.f==null)return!0
q=$.y().a.dC(t.T.a(s.d),"direction")==="rtl"
p=r.a
o=r instanceof A.cv
n=o?A.h(p.key):new A.ca(p).geb()
if(!(q&&n!=="ArrowRight"))m=!q&&n!=="ArrowLeft"
else m=!0
if(m)return!0
if(o)l=A.I(p.shiftKey)
else{o=A.Z(p,"KeyboardEvent")
l=o&&A.I(p.shiftKey)}p=l?1:0
this.a.a.S(new A.G(a.a-1,a.b+p),"user")
return!1},
$S:12}
A.t8.prototype={
$1(a){t.f.a(a)
if(!A.I(a.a.defaultPrevented)&&A.FW(a))this.a.ol()},
$S:0}
A.t6.prototype={
$1(a){var s
t.f.a(a)
this.b.ca("selectionchange",this.c.bP())
s=this.a
s.c=!1
if(Date.now()<=s.d)s.oT()},
$S:0}
A.e2.prototype={}
A.dp.prototype={
oO(a){var s,r,q,p=this
t.f.a(a)
a.a.preventDefault()
s=p.or(a)
if(s.length===0)return
r=p.og(a)
if(r==null)r=p.a.d1(!0)
if(r==null){r=p.a.f
r===$&&A.c()
r=r.d
q=r}else q=r
if(q==null){r=p.a.c
r===$&&A.c()
q=new A.G(r.E(0)-1,0)}p.ip(q,s)},
og(a){var s,r,q
if(!(a instanceof A.bB))return null
s=a.a
r=$.y().a.qO(A.v(s.clientX),A.v(s.clientY))
if(r==null)return null
s=this.a.f
s===$&&A.c()
q=s.i3(r)
if(q==null)return null
return s.i4(q)},
or(a){var s,r,q,p,o,n=null
if(a instanceof A.ev){q=a.gcO()
q=q==null?n:q.gcz()
return q==null?B.ag:q}if(a instanceof A.hH){q=a.gcM()
q=q==null?n:q.gcz()
return q==null?B.ag:q}if(a instanceof A.bB){q=a.gcO()
q=q==null?n:q.gcz()
return q==null?B.ag:q}try{p=new A.ca(a.a).gcO()
s=p
if(s instanceof A.fi){q=s.gcz()
return q}q=s
r=q==null?n:q.gcz()
if(t.j.b(r))return r}catch(o){}return B.r},
pm(a){var s,r
if(a instanceof A.dJ)return A.h(a.a.type)
try{s=A.m(a.gb_())
return s}catch(r){return null}},
ip(a,b){var s,r,q,p,o,n,m=[]
for(s=b.length,r=this.b,q=0;q<b.length;b.length===s||(0,A.k)(b),++q){p=b[q]
if(p==null)continue
o=this.pm(p)
if(o!=null&&B.a.v(r.a,o))m.push(p)}if(m.length===0)return null
n=r.b
if(n==null)n=A.Ko()
return n.$3(this.a,a,m)}}
A.nt.prototype={
k9(a){var s=a.a
s=s==null?null:s.a
if(s==null){s=this.a.rl("paragraph")
s=s==null?null:s.a}return s},
ic(a){var s,r,q,p,o=this.a,n=o.b
if(n==null)n=B.nf
for(o=o.eY(this.k9(a)),s=o.length,r=0;r<o.length;o.length===s||(0,A.k)(o),++r){q=o[r].r
if(q!=null)n=n.ds(q)}p=a.a
return p!=null?n.ds(p):n},
cY(a,b){var s,r,q,p,o=this.a,n=o.a
if(n==null)n=B.ng
for(s=o.eY(this.k9(a)),r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q].w
if(p!=null)n=n.ds(p)}s=b==null
if((s?null:b.a)!=null)for(o=o.eY(b.a),r=o.length,q=0;q<o.length;o.length===r||(0,A.k)(o),++q){p=o[q].w
if(p!=null)n=n.ds(p)}return!s?n.ds(b):n},
uh(a){var s,r,q,p,o=null,n=a.a,m=n==null,l=m?o:n.d
if(l!=null)return l
n=m?o:n.a
n=this.a.eY(n)
m=n.length
s=o
r=0
for(;r<m;++r){q=n[r].x
p=q==null?o:q.d
if(p!=null)s=p}return s}}
A.to.prototype={}
A.ti.prototype={}
A.kN.prototype={}
A.tn.prototype={}
A.i6.prototype={}
A.tg.prototype={}
A.eO.prototype={
ds(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this,d=a.a
if(d==null)d=e.a
s=a.b
if(s==null)s=e.b
r=a.c
if(r==null)r=e.c
q=a.d
if(q==null)q=e.d
p=a.e
if(p==null)p=e.e
o=a.f
if(o==null)o=e.f
n=a.r
if(n==null)n=e.r
m=a.w
if(m==null)m=e.w
l=a.x
if(l==null)l=e.x
k=a.y
if(k==null)k=e.y
j=a.z
if(j==null)j=e.z
i=a.Q
if(i==null)i=e.Q
h=a.as
if(h==null)h=e.as
g=a.at
if(g==null)g=e.at
f=a.ax
return new A.eO(d,s,r,q,p,o,n,m,l,k,j,i,h,g,f==null?e.ax:f)}}
A.tj.prototype={}
A.eM.prototype={
ds(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this,d=a.a
if(d==null)d=e.a
s=a.b
if(s==null)s=e.b
r=a.c
if(r==null)r=e.c
q=a.d
if(q==null)q=e.d
p=a.e
if(p==null)p=e.e
o=a.f
if(o==null)o=e.f
n=a.r
if(n==null)n=e.r
m=a.w
if(m==null)m=e.w
l=a.x
if(l==null)l=e.x
k=a.y
if(k==null)k=e.y
j=a.z
if(j==null)j=e.z
i=a.Q
if(i==null)i=e.Q
h=a.as
if(h==null)h=e.as
g=a.at
if(g==null)g=e.at
f=a.ax
return new A.eM(d,s,r,q,p,o,n,m,l,k,j,i,h,g,f==null?e.ax:f)}}
A.bJ.prototype={}
A.cY.prototype={}
A.ib.prototype={}
A.fQ.prototype={}
A.i9.prototype={}
A.ia.prototype={}
A.i8.prototype={}
A.fR.prototype={}
A.fU.prototype={}
A.fY.prototype={}
A.h_.prototype={}
A.e4.prototype={}
A.eN.prototype={
gdz(){var s=t.kd
return A.ft(new A.ae(this.b,s),s.i("e(o.E)").a(new A.tk()),s.i("o.E"),t.N).bn(0)}}
A.tk.prototype={
$1(a){return t.As.a(a).a},
$S:155}
A.fT.prototype={}
A.fZ.prototype={}
A.fX.prototype={}
A.e3.prototype={}
A.cX.prototype={}
A.ts.prototype={
gb_(){return this.b}}
A.tq.prototype={}
A.tr.prototype={}
A.tp.prototype={}
A.kO.prototype={}
A.kP.prototype={}
A.eQ.prototype={}
A.fW.prototype={}
A.fS.prototype={
gb_(){return this.a}}
A.tl.prototype={}
A.tm.prototype={
$1(a){var s,r,q,p,o=A.a([],t.Dk)
for(s=this.a.bD(a),r=s.$ti,s=new A.H(s.a(),r.i("H<1>")),r=r.c;s.l();){q=s.b
if(q==null)q=r.a(q)
p=q.u("w:type")
if(p==null)p="default"
q=q.u("r:id")
o.push(new A.fS(p,q==null?"":q))}return o},
$S:156}
A.th.prototype={}
A.kJ.prototype={}
A.kM.prototype={}
A.kK.prototype={}
A.fP.prototype={}
A.fV.prototype={}
A.e5.prototype={
ec(a,b){var s,r,q=this.b.h(0,a)
if(q==null)return null
s=q.c.h(0,b)
if(s!=null)return s
r=this.a.h(0,q.b)
return r==null?null:r.c.h(0,b)}}
A.os.prototype={
tT(a,b){var s,r,q,p,o,n,m,l,k=this.a,j=k.ec(a,b)
if(j==null)return null
s=this.b.aQ(a,new A.ot())
r=s.h(0,b)
s.j(0,b,(r==null?this.qv(a,b)-1:r)+1)
s.cb(0,new A.ou(b))
if(j.c==="bullet")return A.DQ(j.d)
q=j.d
for(p=1;p<=9;++p){r="%"+p
if(!B.b.v(q,r))continue
o=p-1
n=s.h(0,o)
if(n==null){m=k.ec(a,o)
m=m==null?null:m.b
n=m==null?1:m}s.j(0,o,n)
m=k.ec(a,o)
l=m==null?null:m.c
m=A.Il(n,l==null?"decimal":l)
q=A.O(q,r,m)}return q},
qv(a,b){var s=this.a.ec(a,b)
s=s==null?null:s.b
return s==null?1:s}}
A.ot.prototype={
$0(){var s=t.S
return A.b(s,s)},
$S:157}
A.ou.prototype={
$2(a,b){A.v(a)
A.v(b)
return a>this.a},
$S:158}
A.n8.prototype={
ta(a,b){var s,r=this.a,q=r.ej(b).eW(a)
if(q==null||q.d)return null
s=r.fj(b,q.c)
if(B.b.a0(s,"/"))s=B.b.L(s,1)
return r.a.ly(s)},
tb(a,b){var s,r=this.a,q=r.ej(b).eW(a)
if(q==null||q.d)return null
s=r.fj(b,q.c)
if(B.b.a0(s,"/"))s=B.b.L(s,1)
return r.b.uu(s)}}
A.n9.prototype={
q4(b6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3="word/settings.xml",b4=A.EW(b6),b5=b4.dv("[Content_Types].xml")
if(b5==null)A.a4(B.cc)
s=t.N
r=new A.ov(b4,A.D8(b5),A.b(s,t.Dm))
q=r.glk()
p=b4.dv(B.b.a0(q,"/")?B.b.L(q,1):q)
if(p==null)throw A.i(A.bc("Parte principal ausente: "+q,null,null))
o=A.id()
n=t.lx
A.ie(p,new A.d_(o,A.a([],n)))
m=t.dd
l=new A.ae(o.b,m).gF(0).C("w:body")
if(l==null)throw A.i(B.ci)
k=B.b.ae(p,"<w:body>")
j=B.b.i0(p,"</w:body>")
if(k<0||j<0)throw A.i(B.cg)
B.b.t(p,0,k+8)
B.b.L(p,j)
i=A.EJ(l.C("w:sectPr"))
h=this.he(l,B.jN)
g=A.za(r,"word/styles.xml",A.K0(),A.K_(),t.r5)
f=A.za(r,"word/numbering.xml",A.JE(),A.JD(),t.k9)
e=b4.dv(B.b.a0(b3,"/")?B.b.L(b3,1):b3)
if(e==null)o=null
else{o=A.id()
A.ie(e,new A.d_(o,A.a([],n)))
o=new A.ae(o.b,m).gF(0)}A.EK(o)
o=t.zY
d=A.b(s,o)
c=A.b(s,o)
if(i!=null){b=r.ej(q)
for(s=[new A.d0(i.Q,d,"w:hdr"),new A.d0(i.as,c,"w:ftr")],o=t.ha,a=this.a,a0=0;a0<2;++a0){a1=s[a0]
a2=a1.b
a3=a1.c
for(a1=J.U(a1.a);a1.l();){a4=a1.gq()
a5=a4.b
a6=b.eW(a5)
if(a6==null){B.a.k(a,"refer\xeancia de header/footer sem rel: "+a5)
continue}a7=r.fj(q,a6.c)
a8=b4.dv(B.b.a0(a7,"/")?B.b.L(a7,1):a7)
if(a8==null){B.a.k(a,"parte de header/footer ausente: "+a7)
continue}a5=A.a([],o)
a9=A.a([],n)
b0=a8.length
if(b0!==0){if(0>=b0)return A.d(a8,0)
b0=a8.charCodeAt(0)===65279}else b0=!1
b1=b0?1:0
b0=b1===0?a8:B.b.L(a8,b1)
new A.kU(b0,new A.d_(new A.kR(a5),a9)).kc()
b2=new A.ae(a5,m).gJ(0)
if(!b2.l())A.a4(A.cP())
a5=b2.gq()
a9=a5.b
if(a9!==a3)B.a.k(a,"raiz inesperada em "+a7+": "+a9)
a2.j(0,a4.a,new A.kJ(a7,this.kb(a5)))}}}return new A.n8(r,new A.th(h,i),g,f,d,c)},
he(a,b){var s,r,q,p,o,n,m
t.dO.a(b)
s=A.a([],t.zK)
for(r=B.a.gJ(a.d),q=new A.aQ(r,t.bi),p=this.a,o=t.rI;q.l();){n=o.a(r.gq())
m=n.b
if(b.v(0,m))continue
$label0$1:{if("w:p"===m){B.a.k(s,this.pU(n))
break $label0$1}if("w:tbl"===m){B.a.k(s,this.pX(n))
break $label0$1}B.a.k(p,"bloco preservado: "+m)
n.bZ(new A.a_(""))
B.a.k(s,new A.fW(m))}}return s},
kb(a){return this.he(a,B.av)},
pU(a){var s,r,q,p,o,n,m,l,k,j,i,h,g=A.a([],t.d5)
for(s=B.a.gJ(a.d),r=new A.aQ(s,t.bi),q=t.rI,p=t.D0,o=null;r.l();){n=q.a(s.gq())
m=n.b
if("w:pPr"===m){o=A.xO(n)
continue}if("w:r"===m){B.a.k(g,this.hh(n))
continue}if("w:hyperlink"===m){l=n.u("r:id")
k=n.u("w:anchor")
j=A.a([],p)
for(n=n.bD("w:r"),i=n.$ti,n=new A.H(n.a(),i.i("H<1>")),i=i.c;n.l();){h=n.b
j.push(this.hh(h==null?i.a(h):h))}B.a.k(g,new A.fT(l,k,j))
continue}if("w:fldSimple"===m){l=n.u("w:instr")
if(l==null)l=""
k=A.a([],p)
for(n=n.bD("w:r"),j=n.$ti,n=new A.H(n.a(),j.i("H<1>")),j=j.c;n.l();){i=n.b
k.push(this.hh(i==null?j.a(i):i))}B.a.k(g,new A.fZ(l,k))
continue}n.bZ(new A.a_(""))
B.a.k(g,new A.fX(m))}a.ek()
return new A.cX(o,g)},
hh(a){var s,r,q,p,o,n,m,l,k=A.a([],t.zE)
for(s=B.a.gJ(a.d),r=new A.aQ(s,t.bi),q=t.rI,p=null;r.l();){o=q.a(s.gq())
n=o.b
if("w:rPr"===n){p=A.kL(o)
continue}if("w:t"===n){m=new A.a_("")
o.eJ(m)
o=m.a
B.a.k(k,new A.cY(o.charCodeAt(0)==0?o:o))
continue}if("w:tab"===n){B.a.k(k,new A.ib())
continue}if("w:br"===n){B.a.k(k,new A.fQ(o.u("w:type")))
continue}if("w:cr"===n){B.a.k(k,new A.fQ(null))
continue}if("w:noBreakHyphen"===n){B.a.k(k,new A.i9())
continue}if("w:softHyphen"===n)continue
if("w:sym"===n){o.u("w:font")
B.a.k(k,new A.ia(o.u("w:char")))
continue}if("w:drawing"===n){B.a.k(k,this.pP(o))
continue}if("w:fldChar"===n){o=o.u("w:fldCharType")
B.a.k(k,new A.fR(o==null?"begin":o))
continue}if("w:instrText"===n){m=new A.a_("")
o.eJ(m)
o=m.a
B.a.k(k,new A.fU(o.charCodeAt(0)==0?o:o))
continue}if("w:lastRenderedPageBreak"===n)continue
if("mc:AlternateContent"===n){l=this.pY(o)
if(l==null){o.bZ(new A.a_(""))
o=new A.fY(n)}else o=l
B.a.k(k,o)
continue}o.bZ(new A.a_(""))
B.a.k(k,new A.fY(n))}return new A.eN(p,k)},
pY(a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=null,c="wp:posOffset",b="a:srgbClr",a=a1.cP("wps:wsp"),a0=a.$ti
a=new A.H(a.a(),a0.i("H<1>"))
$loop$0:{if(a.l()){a=a.b
s=a==null?a0.c.a(a):a
break $loop$0}else s=d}if(s==null)return d
a=s.cP("w:txbxContent")
a0=a.$ti
a=new A.H(a.a(),a0.i("H<1>"))
$loop$1:{if(a.l()){a=a.b
r=a==null?a0.c.a(a):a
break $loop$1}else r=d}if(r==null)return d
a=a1.cP("wp:anchor")
a0=a.$ti
a=new A.H(a.a(),a0.i("H<1>"))
$loop$2:{if(a.l()){a=a.b
q=a==null?a0.c.a(a):a
break $loop$2}else q=d}p=d
if(q!=null){o=q.C("wp:positionH")
a=o==null
if(!a){a0=o.C("wp:align")
p=a0==null?d:B.b.R(a0.gdz())}if(a)a=d
else{a=o.C(c)
a=a==null?d:B.b.R(a.gdz())}A.V(a==null?"":a,d)
n=q.C("wp:positionV")
if(n==null)a=d
else{a=n.C(c)
a=a==null?d:B.b.R(a.gdz())}m=A.V(a==null?"":a,d)
l=q.C("wp:extent")
a=l==null
a0=a?d:l.u("cx")
k=A.V(a0==null?"":a0,d)
a=a?d:l.u("cy")
j=A.V(a==null?"":a,d)}else{j=d
k=j
m=k}i=s.C("wps:spPr")
h=d
g=d
if(i!=null){f=i.C("a:ln")
a=f==null
a0=a?d:f.u("w")
e=A.V(a0==null?"":a0,d)
if(!a){a=f.cP(b)
a0=a.$ti
a=new A.H(a.a(),a0.i("H<1>"))
$loop$3:{if(a.l()){a=a.b
h=(a==null?a0.c.a(a):a).u("val")
break $loop$3}}}a=i.C("a:solidFill")
if(!(a==null)){a=a.C(b)
g=a==null?d:a.u("val")}}else e=d
a=this.kb(r)
a1.ek()
return new A.h_(p,m,k,j,e,h,g,a)},
pP(a){var s,r,q,p,o=null,n=a.C("wp:inline"),m=a.C("wp:anchor"),l=n==null,k=l?m:n,j=k==null?o:k.C("wp:extent")
for(s=a.cP("a:blip"),r=s.$ti,s=new A.H(s.a(),r.i("H<1>")),r=r.c,q=o;s.l();){p=s.b
if(p==null)p=r.a(p)
q=p.u("r:embed")
if(q==null)q=p.u("r:link")
if(q!=null)break}if(m!=null)B.a.k(this.a,"drawing flutuante (anchor) tratado como inline")
s=j==null
r=s?o:j.u("cx")
r=A.bg(r==null?"":r)
s=s?o:j.u("cy")
return new A.i8(q,r,A.bg(s==null?"":s),!l,a.ek())},
pX(a){var s,r,q,p,o,n,m,l,k,j=A.a([],t.X),i=A.a([],t.B7)
for(s=B.a.gJ(a.d),r=new A.aQ(s,t.bi),q=this.a,p=t.rI,o=null;r.l();){n=p.a(s.gq())
m=n.b
if("w:tblPr"===m){o=A.Av(n)
continue}if("w:tblGrid"===m){for(n=n.bD("w:gridCol"),l=n.$ti,n=new A.H(n.a(),l.i("H<1>")),l=l.c;n.l();){k=n.b
k=(k==null?l.a(k):k).u("w:w")
k=A.V(k==null?"":k,null)
B.a.k(j,k==null?0:k)}continue}if("w:tr"===m){B.a.k(i,this.pV(n))
continue}B.a.k(q,"filho de tabela ignorado: "+m)}a.ek()
return new A.eQ(o,j,i)},
pV(a){var s,r,q,p,o,n,m,l,k,j=A.a([],t.jw)
for(s=B.a.gJ(a.d),r=new A.aQ(s,t.bi),q=this.a,p=t.rI,o=null;r.l();){n=p.a(s.gq())
m=n.b
if("w:trPr"===m){o=A.EO(n)
continue}if("w:tc"===m){l=n.C("w:tcPr")
k=l!=null?A.EN(l):null
B.a.k(j,new A.kO(k,this.he(n,B.jV)))
continue}if("w:tblPrEx"===m){B.a.k(q,"tblPrEx ignorado em linha de tabela")
continue}B.a.k(q,"filho de linha ignorado: "+m)}return new A.kP(o,j)}}
A.eP.prototype={
gb_(){return this.b}}
A.e6.prototype={
h(a,b){A.m(b)
return b==null?null:this.c.h(0,b)},
rl(a){var s,r,q
for(s=this.c.gak(),r=A.u(s),s=new A.aS(J.U(s.a),s.b,r.i("aS<1,2>")),r=r.y[1];s.l();){q=s.a
if(q==null)q=r.a(q)
if(q.f&&q.b===a)return q}return null},
eY(a){var s,r=A.a([],t.hG),q=A.xk(t.N),p=a==null?null:this.c.h(0,a),o=this.c
while(!0){if(!(p!=null&&q.k(0,p.a)))break
B.a.V(r,0,p)
s=p.d
p=s==null?null:o.h(0,s)}return r}}
A.mN.prototype={
uu(a){var s,r=B.b.a0(a,"/")?a:"/"+a,q=this.b.h(0,r)
if(q!=null)return q
s=B.b.i0(r,".")
if(s<0)return null
return this.a.h(0,B.b.L(r,s+1).toLowerCase())}}
A.ov.prototype={
ej(a){var s,r,q,p,o,n,m,l
if(a==null)s="_rels/.rels"
else{r=B.b.a0(a,"/")?B.b.L(a,1):a
q=B.b.i0(r,"/")
p=q<0
o=p?"":B.b.t(r,0,q+1)
r=p?r:B.b.L(r,q+1)
s=o+"_rels/"+r+".rels"}p=this.c
n=p.h(0,s)
if(n!=null)return n
m=this.a.dv(s)
l=m==null?A.zN():A.Ef(m)
p.j(0,s,l)
return l},
fj(a,b){var s,r,q,p,o,n,m
if(B.b.a0(b,"/"))return B.b.L(b,1)
if(a==null)s=""
else{r=B.b.a0(a,"/")?B.b.L(a,1):a
s=B.b.b8(r,A.D("[^/]+$",!0,!1),"")}r=A.N(new A.an(A.a(s.split("/"),t.s),t.Ag.a(new A.ow()),t.vY),!0,t.N)
for(q=b.split("/"),p=q.length,o=0;o<p;++o){n=q[o]
if(n===".."){m=r.length
if(m!==0){if(0>=m)return A.d(r,-1)
r.pop()}}else if(n!=="."&&n.length!==0)B.a.k(r,n)}return B.a.ab(r,"/")},
glk(){var s=this.ej(null).rD("http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument")
if(s==null)throw A.i(B.ch)
return this.fj(null,s.c)}}
A.ow.prototype={
$1(a){return A.h(a).length!==0},
$S:8}
A.kk.prototype={
B(a){var s=this,r=s.d?", external":""
return"Relationship("+s.a+", "+s.b+", "+s.c+r+")"},
gb_(){return this.b}}
A.kl.prototype={
eW(a){var s,r,q,p
for(s=this.a,r=s.length,q=0;q<r;++q){p=s[q]
if(p.a===a)return p}return null},
rD(a){var s,r,q,p
for(s=this.a,r=s.length,q=0;q<r;++q){p=s[q]
if(p.b===a)return p}return null}}
A.dr.prototype={
ek(){var s,r=new A.a_("")
this.bZ(r)
s=r.a
return s.charCodeAt(0)==0?s:s}}
A.ig.prototype={
bZ(a){var s=A.ES(this.b)
a.a+=s
return null}}
A.ic.prototype={
bZ(a){var s=a.a+="<![CDATA["
s+=this.b
a.a=s
a.a=s+"]]>"}}
A.kQ.prototype={
bZ(a){var s=a.a+="<!--"
s+=this.b
a.a=s
a.a=s+"-->"}}
A.kS.prototype={
bZ(a){var s=a.a+="<?"+this.b,r=this.c
if(r!=null&&r.length!==0)s=a.a=s+(" "+A.p(r))
a.a=s+"?>"}}
A.e7.prototype={
B(a){return this.a+'="'+this.b+'"'}}
A.c1.prototype={
np(a,b,c){var s,r
for(s=this.d.length,r=0;r<s;++r);},
u(a){var s,r,q,p
for(s=this.c,r=s.length,q=0;q<r;++q){p=s[q]
if(p.a===a)return p.b}return null},
C(a){var s,r,q,p
for(s=this.d,r=s.length,q=0;q<r;++q){p=s[q]
if(p instanceof A.c1&&p.b===a)return p}return null},
bD(a){return new A.cH(this.qU(a),t.n2)},
qU(a){var s=this
return function(){var r=a
var q=0,p=1,o,n,m,l,k
return function $async$bD(b,c,d){if(c===1){o=d
q=p}while(true)switch(q){case 0:n=s.d,m=n.length,l=0
case 2:if(!(l<n.length)){q=4
break}k=n[l]
q=k instanceof A.c1&&k.b===r?5:6
break
case 5:q=7
return b.b=k,1
case 7:case 6:case 3:n.length===m||(0,A.k)(n),++l
q=2
break
case 4:return 0
case 1:return b.c=o,3}}}},
cP(a){return new A.cH(this.rs(a),t.n2)},
rs(a){var s=this
return function(){var r=a
var q=0,p=1,o,n,m,l,k
return function $async$cP(b,c,d){if(c===1){o=d
q=p}while(true)switch(q){case 0:n=s.d,m=n.length,l=0
case 2:if(!(l<n.length)){q=4
break}k=n[l]
q=k instanceof A.c1?5:6
break
case 5:q=k.b===r?7:8
break
case 7:q=9
return b.b=k,1
case 9:case 8:q=10
return b.eT(k.cP(r))
case 10:case 6:case 3:n.length===m||(0,A.k)(n),++l
q=2
break
case 4:return 0
case 1:return b.c=o,3}}}},
gdz(){var s,r=new A.a_("")
this.eJ(r)
s=r.a
return s.charCodeAt(0)==0?s:s},
eJ(a){var s,r,q,p
for(s=this.d,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q]
if(p instanceof A.ig)a.a+=p.b
if(p instanceof A.ic)a.a+=p.b
if(p instanceof A.c1)p.eJ(a)}},
bZ(a){var s,r,q,p,o=a.a+="<",n=this.b
o=a.a=o+n
for(s=this.c,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q]
o+=" "
a.a=o
o+=p.a
a.a=o
a.a=o+'="'
o=A.ER(p.b)
o=a.a+=o
o+='"'
a.a=o}s=this.d
r=s.length
if(r===0){a.a=o+"/>"
return}a.a=o+">"
for(q=0;q<s.length;s.length===r||(0,A.k)(s),++q)s[q].bZ(a)
o=a.a+="</"
n=o+n
a.a=n
a.a=n+">"}}
A.kR.prototype={}
A.d_.prototype={
j_(a,b,c){var s,r,q,p
t.gI.a(b)
if(b.length===0)s=null
else{s=A.K(b)
r=s.i("a1<1,e7>")
r=A.N(new A.a1(b,s.i("e7(1)").a(new A.tH()),r),!0,r.i("ad.E"))
s=r}r=s==null?A.a([],t.bd):s
q=A.a([],t.ha)
p=new A.c1(a,r,q)
p.np(a,s,null)
s=this.b
if(s.length===0)B.a.k(this.a.b,p)
else B.a.k(B.a.gK(s).d,p)
B.a.k(s,p)},
qR(a){var s=this.b
if(s.length===0)return
B.a.k(B.a.gK(s).d,new A.ig(a))},
qP(a){var s=this.b
if(s.length===0)return
B.a.k(B.a.gK(s).d,new A.ic(a))}}
A.tH.prototype={
$1(a){t.dB.a(a)
return new A.e7(a.a,a.b)},
$S:159}
A.e8.prototype={
B(a){return this.a+'="'+this.b+'"'}}
A.kT.prototype={}
A.tt.prototype={}
A.kU.prototype={
kc(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=this,a2=a1.a,a3=a2.length
for(s=a1.b,r=s.a.b,q=s.b,p=0,o=!1;n=a1.c,n<a3;){if(!(n>=0))return A.d(a2,n)
if(a2.charCodeAt(n)===60){m=n+1
if(m>=a3)throw A.i(A.aR("Documento termina dentro de tag",a2,n))
l=a2.charCodeAt(m)
if(l===47){k=a1.pR();--p
if(p<0)throw A.i(A.aR("Tag de fechamento sem abertura: </"+k+">",a2,a1.c))
if(0>=q.length)return A.d(q,-1)
q.pop()}else if(l===33)if(B.b.aS(a2,"<!--",n)){m=n+4
j=B.b.bl(a2,"-->",m)
if(j<0)A.a4(A.aR("Coment\xe1rio n\xe3o terminado",a2,n))
i=new A.kQ(B.b.t(a2,m,j))
if(q.length===0)B.a.k(r,i)
else B.a.k(B.a.gK(q).d,i)
a1.c=j+3}else if(B.b.aS(a2,"<![CDATA[",n)){if(p===0)throw A.i(A.aR("CDATA fora do elemento raiz",a2,n))
m=n+9
j=B.b.bl(a2,"]]>",m)
if(j<0)A.a4(A.aR("CDATA n\xe3o terminado",a2,n))
s.qP(B.b.t(a2,m,j))
a1.c=j+3}else if(B.b.aS(a2,"<!DOCTYPE",n))a1.qs()
else throw A.i(A.aR('Marca\xe7\xe3o "<!" desconhecida',a2,n))
else if(l===63){m=n+2
j=B.b.bl(a2,"?>",m)
if(j<0)A.a4(A.aR("Processing instruction n\xe3o terminada",a2,n))
h=B.b.t(a2,m,j)
a1.c=j+2
g=A.EU(h)
m=g<0
f=m?h:B.b.t(h,0,g)
e=m?null:B.b.R(B.b.L(h,g+1))
if(f.toLowerCase()==="xml"){if(n!==0)A.a4(A.aR("Declara\xe7\xe3o XML fora do in\xedcio do documento",a2,a1.c))
d=A.EV(e==null?"":e)
d.h(0,"version")
d.h(0,"encoding")
d.h(0,"standalone")}else{i=new A.kS(f,e)
if(q.length===0)B.a.k(r,i)
else B.a.k(B.a.gK(q).d,i)}}else{if(p===0&&o)throw A.i(A.aR("Mais de um elemento raiz no documento",a2,n))
if(!a1.pW())++p
o=!0}}else{c=B.b.bl(a2,"<",n)
j=c<0?a3:c
if(p>0){b=a1.oc(a2,n,j)
if(b.length!==0)s.qR(b)}else for(a=n;a<j;++a){if(!(a<a3))return A.d(a2,a)
a0=a2.charCodeAt(a)
if(a0!==32&&a0!==9&&a0!==10&&a0!==13)throw A.i(A.aR("Texto fora do elemento raiz",a2,a))}a1.c=j}}if(p!==0)throw A.i(A.aR("Elemento n\xe3o fechado no fim do documento",a2,a3===0?0:a3-1))
if(!o)throw A.i(A.aR("Documento sem elemento raiz",a2,0))},
pW(){var s,r,q,p,o,n,m,l,k,j,i=this,h='Valor do atributo "',g=i.a,f=g.length,e=i.c,d=e+1,c=d
while(!0){if(c<f){if(!(c>=0))return A.d(g,c)
s=g.charCodeAt(c)
s=!(s===32||s===9||s===10||s===13||s===62||s===47||s===61)}else s=!1
if(!s)break;++c}if(c===d)throw A.i(A.aR("Nome de elemento vazio",g,e))
r=B.b.t(g,d,c)
for(e=t.qo,d=c,q=null;!0;){d=i.eQ(d)
if(d>=f)throw A.i(A.aR("Tag n\xe3o terminada: <"+r,g,i.c))
if(!(d>=0))return A.d(g,d)
p=g.charCodeAt(d)
if(p===62){i.c=d+1
e=q==null?B.b8:q
i.b.j_(r,e,!1)
return!1}if(p===47){e=d+1
if(e<f){if(!(e<f))return A.d(g,e)
e=g.charCodeAt(e)!==62}else e=!0
if(e)throw A.i(A.aR('Esperado "/>" na tag <'+r,g,d))
i.c=d+2
e=i.b
e.j_(r,q==null?B.b8:q,!0)
e=e.b
if(0>=e.length)return A.d(e,-1)
e.pop()
return!0}for(c=d;c<f;){o=g.charCodeAt(c)
if(o===61||o===32||o===9||o===10||o===13||o===62||o===47)break;++c}if(c===d)throw A.i(A.aR("Caractere inesperado na tag <"+r,g,c))
n=B.b.t(g,d,c)
d=i.eQ(c)
if(d<f){if(!(d>=0&&d<f))return A.d(g,d)
s=g.charCodeAt(d)!==61}else s=!0
if(s)throw A.i(A.aR('Atributo "'+n+'" sem "=" na tag <'+r,g,d))
d=i.eQ(d+1)
if(d>=f)throw A.i(A.aR("Valor de atributo ausente",g,d-1))
if(!(d>=0))return A.d(g,d)
m=g.charCodeAt(d)
s=m===34
if(!s&&m!==39)throw A.i(A.aR(h+n+'" sem aspas',g,d))
l=d+1
k=B.b.bl(g,s?'"':"'",l)
if(k<0)throw A.i(A.aR(h+n+'" n\xe3o terminado',g,d))
j=i.ob(g,l,k)
if(q==null){q=A.a([],e)
s=q}else s=q
B.a.k(s,new A.e8(n,j))
d=k+1}},
pR(){var s,r,q=this,p=q.a,o=p.length,n=q.c+2,m=n
while(!0){if(m<o){if(!(m>=0))return A.d(p,m)
s=p.charCodeAt(m)
s=!(s===32||s===9||s===10||s===13||s===62||s===47||s===61)}else s=!1
if(!s)break;++m}r=B.b.t(p,n,m)
n=q.eQ(m)
if(n<o){if(!(n>=0&&n<o))return A.d(p,n)
s=p.charCodeAt(n)!==62}else s=!0
if(s)throw A.i(A.aR("Tag </"+r+" n\xe3o terminada",p,q.c))
q.c=n+1
return r},
qs(){var s,r,q,p=this,o=p.a,n=o.length,m=p.c+9
for(s=0;m<n;){if(!(m>=0))return A.d(o,m)
r=o.charCodeAt(m)
if(r===34||r===39){q=B.b.bl(o,A.W(r),m+1)
if(q<0)break
m=q+1
continue}if(r===91)++s
if(r===93)--s
if(r===62&&s<=0){p.c=m+1
return}++m}throw A.i(A.aR("DOCTYPE n\xe3o terminado",o,p.c))},
eQ(a){var s,r=this.a,q=r.length
for(;a<q;){if(!(a>=0))return A.d(r,a)
s=r.charCodeAt(a)
if(s!==32&&s!==9&&s!==10&&s!==13)break;++a}return a},
oc(a,b,c){var s,r,q,p,o,n=a.length,m=b
while(!0){if(!(m<c)){s=!1
break}if(!(m>=0&&m<n))return A.d(a,m)
r=a.charCodeAt(m)
if(r===38||r===13){s=!0
break}++m}if(!s)return B.b.t(a,b,c)
q=new A.a_("")
for(m=b;m<c;){if(!(m>=0&&m<n))return A.d(a,m)
r=a.charCodeAt(m)
if(r===38)m=this.jG(a,m,c,q)
else if(r===13){p=A.W(10)
q.a+=p
o=m+1
if(o<c){if(!(o<n))return A.d(a,o)
p=a.charCodeAt(o)===10}else p=!1
m=(p?o:m)+1}else{p=A.W(r)
q.a+=p;++m}}n=q.a
return n.charCodeAt(0)==0?n:n},
ob(a,b,c){var s,r,q,p,o,n=a.length,m=b
while(!0){if(!(m<c)){s=!1
break}if(!(m>=0&&m<n))return A.d(a,m)
r=a.charCodeAt(m)
if(r===38||r===9||r===10||r===13){s=!0
break}++m}if(!s)return B.b.t(a,b,c)
q=new A.a_("")
for(m=b;m<c;){if(!(m>=0&&m<n))return A.d(a,m)
r=a.charCodeAt(m)
if(r===38)m=this.jG(a,m,c,q)
else if(r===9||r===10||r===13){p=A.W(32)
q.a+=p
p=!1
if(r===13){o=m+1
if(o<c){if(!(o<n))return A.d(a,o)
p=a.charCodeAt(o)===10}}m=(p?m+1:m)+1}else{p=A.W(r)
q.a+=p;++m}}n=q.a
return n.charCodeAt(0)==0?n:n},
jG(a,b,c,d){var s,r,q,p,o,n,m=b+1,l=B.b.bl(a,";",m)
if(l<0||l>=c||l-b>12)throw A.i(A.aR("Refer\xeancia de entidade malformada",a,b))
s=a.length
if(!(m>=0&&m<s))return A.d(a,m)
if(a.charCodeAt(m)===35){r=b+2
if(!(r>=0&&r<s))return A.d(a,r)
q=a.charCodeAt(r)===120||a.charCodeAt(r)===88
if(q)s=b+3
else s=r
p=B.b.t(a,s,l)
o=A.V(p,q?16:10)
if(o==null)throw A.i(A.aR("Refer\xeancia de caractere inv\xe1lida: &"+B.b.t(a,m,l)+";",a,b))
m=A.W(o)
d.a+=m
return l+1}n=B.b.t(a,m,l)
$label0$0:{if("amp"===n){m=A.W(38)
d.a+=m
break $label0$0}if("lt"===n){m=A.W(60)
d.a+=m
break $label0$0}if("gt"===n){m=A.W(62)
d.a+=m
break $label0$0}if("quot"===n){m=A.W(34)
d.a+=m
break $label0$0}if("apos"===n){m=A.W(39)
d.a+=m
break $label0$0}throw A.i(A.aR("Entidade desconhecida: &"+n+";",a,b))}return l+1}}
A.nL.prototype={
nd(a){var s,r,q,p,o,n,m,l,k,j,i,h,g=this,f=a.length
for(s=0;s<f;++s){r=a[s]
if(r>g.b)g.b=r
if(r<g.c)g.c=r}r=g.b
q=B.d.ev(1,r)
p=g.a=new Uint32Array(q)
for(o=1,n=0,m=2;o<=r;){for(l=o<<16,s=0;s<f;++s)if(a[s]===o){for(k=n,j=0,i=0;i<o;++i){j=(j<<1|k&1)>>>0
k=k>>>1}for(h=(l|s)>>>0,i=j;i<q;i+=m){if(!(i>=0))return A.d(p,i)
p[i]=h}++n}++o
n=n<<1>>>0
m=m<<1>>>0}}}
A.nQ.prototype={
gbO(){var s=this.a
if(s==null)return s
s.d===$&&A.c()
return s},
oX(){var s,r,q=this
q.e=q.d=0
if(q.gbO()==null)return
while(!0){s=q.gbO()
r=s.c
s=s.d
s===$&&A.c()
if(!(r<s))break
if(!q.pL())return}},
pL(){var s,r,q,p=this,o=p.gbO()
if(o!=null){s=o.c
r=o.d
r===$&&A.c()
r=s>=r
s=r}else s=!0
if(s)return!1
q=p.bu(3)
switch(B.d.cn(q,1)){case 0:if(p.pZ()===-1)return!1
break
case 1:if(p.jH(p.r,p.w)===-1)return!1
break
case 2:if(p.pQ()===-1)return!1
break
default:return!1}return(q&1)===0},
bu(a){var s,r,q,p,o=this
if(a===0)return 0
for(;s=o.e,s<a;){s=o.gbO()
r=s.c
s=s.d
s===$&&A.c()
if(r>=s)return-1
s=o.gbO()
r=s.b
r.toString
s=s.c++
if(!(s>=0&&s<r.length))return A.d(r,s)
q=r[s]
s=o.d
r=o.e
o.d=(s|B.d.ev(q,r))>>>0
o.e=r+8}r=o.d
p=B.d.qq(1,a)
o.d=B.d.eP(r,a)
o.e=s-a
return(r&p-1)>>>0},
hk(a){var s,r,q,p,o,n,m,l=this,k=a.a
k===$&&A.c()
s=a.b
for(;r=l.e,r<s;){r=l.gbO()
q=r.c
r=r.d
r===$&&A.c()
if(q>=r)return-1
r=l.gbO()
q=r.b
q.toString
r=r.c++
if(!(r>=0&&r<q.length))return A.d(q,r)
p=q[r]
r=l.d
q=l.e
l.d=(r|B.d.ev(p,q))>>>0
l.e=q+8}q=l.d
o=(q&B.d.ev(1,s)-1)>>>0
if(!(o<k.length))return A.d(k,o)
n=k[o]
m=n>>>16
l.d=B.d.eP(q,m)
l.e=r-m
return n&65535},
pZ(){var s,r,q,p=this
p.e=p.d=0
s=p.bu(16)
r=p.bu(16)
if(s!==0&&s!==(r^65535)>>>0)return-1
if(s>p.gbO().gm(0))return-1
r=p.gbO()
q=r.mH(s,r.c)
r.c=r.c+q.gm(0)
p.c.uI(q)
return 0},
pQ(){var s,r,q,p,o,n,m,l,k,j,i=this,h=i.bu(5)
if(h===-1)return-1
h+=257
if(h>288)return-1
s=i.bu(5)
if(s===-1)return-1;++s
if(s>32)return-1
r=i.bu(4)
if(r===-1)return-1
r+=4
if(r>19)return-1
q=new Uint8Array(19)
for(p=0;p<r;++p){o=i.bu(3)
if(o===-1)return-1
n=B.dm[p]
if(!(n<19))return A.d(q,n)
q[n]=o}m=A.jI(q)
n=h+s
l=new Uint8Array(n)
k=J.ho(B.u.gdf(l),0,h)
j=J.ho(B.u.gdf(l),h,s)
if(i.oa(n,m,l)===-1)return-1
return i.jH(A.jI(k),A.jI(j))},
jH(a,b){var s,r,q,p,o,n,m,l,k=this
for(s=k.c;!0;){r=k.hk(a)
if(r<0||r>285)return-1
if(r===256)break
if(r<256){if(s.b===s.c.length)s.on()
q=s.c
p=s.b++
q.$flags&2&&A.ak(q)
if(!(p>=0&&p<q.length))return A.d(q,p)
q[p]=r&255
continue}o=r-257
if(!(o>=0&&o<29))return A.d(B.ba,o)
n=B.ba[o]+k.bu(B.dg[o])
m=k.hk(b)
if(m<0||m>29)return-1
if(!(m>=0&&m<30))return A.d(B.b4,m)
l=B.b4[m]+k.bu(B.ew[m])
for(q=-l;n>l;){s.it(s.j0(q))
n-=l}if(n===l)s.it(s.j0(q))
else s.it(s.j1(q,n-l))}for(;s=k.e,s>=8;){k.e=s-8
s=k.gbO()
q=--s.c
p=s.d
p===$&&A.c()
s.sq_(B.d.aC(q,0,p))}return 0},
oa(a,b,c){var s,r,q,p,o,n,m,l,k=this
for(s=0,r=0;r<a;){q=k.hk(b)
if(q===-1)return-1
p=0
switch(q){case 16:o=k.bu(2)
if(o===-1)return-1
o+=3
for(n=c.$flags|0;m=o-1,o>0;o=m,r=l){l=r+1
n&2&&A.ak(c)
if(!(r>=0&&r<c.length))return A.d(c,r)
c[r]=s}break
case 17:o=k.bu(3)
if(o===-1)return-1
o+=3
for(n=c.$flags|0;m=o-1,o>0;o=m,r=l){l=r+1
n&2&&A.ak(c)
if(!(r>=0&&r<c.length))return A.d(c,r)
c[r]=0}s=p
break
case 18:o=k.bu(7)
if(o===-1)return-1
o+=11
for(n=c.$flags|0;m=o-1,o>0;o=m,r=l){l=r+1
n&2&&A.ak(c)
if(!(r>=0&&r<c.length))return A.d(c,r)
c[r]=0}s=p
break
default:if(q<0||q>15)return-1
l=r+1
c.$flags&2&&A.ak(c)
if(!(r>=0&&r<c.length))return A.d(c,r)
c[r]=q
r=l
s=q
break}}return 0}}
A.m4.prototype={
bA(){return"ByteOrder."+this.b}}
A.jP.prototype={
gm(a){var s=this.b
return s==null?0:s.length-this.c},
h(a,b){var s,r
A.v(b)
s=this.b
r=this.c+b
if(!(r>=0&&r<s.length))return A.d(s,r)
return s[r]},
mH(a,b){var s=this.b
if(s==null)return A.xc(A.a([],t.X),B.aD,null,null)
return A.xc(s,this.a,a,b)},
sq_(a){this.c=A.v(a)}}
A.jQ.prototype={}
A.kc.prototype={
it(a){var s,r,q,p,o,n=this
t.L.a(a)
s=a.length
for(;r=n.b,q=r+s,p=n.c,o=p.length,q>o;)n.h3(q-o)
B.u.dG(p,r,q,a)
n.b+=s},
uI(a){var s,r,q,p,o,n,m=this
while(!0){s=m.b
r=a.b
q=r==null
p=q?0:r.length-a.c
o=m.c
n=o.length
if(!(s+p>n))break
m.h3(s+(q?0:r.length-a.c)-n)}if(!q){r=a.gm(0)
q=a.b
q.toString
B.u.cg(o,s,s+r,q,a.c)}m.b=m.b+a.gm(0)},
j1(a,b){var s=this
if(a<0)a=s.b+a
if(b==null)b=s.b
else if(b<0)b=s.b+b
return J.ho(B.u.gdf(s.c),s.c.byteOffset+a,b-a)},
j0(a){return this.j1(a,null)},
h3(a){var s=a!=null?a>32768?a:32768:32768,r=this.c,q=r.length,p=new Uint8Array((q+s)*2)
B.u.dG(p,0,q,r)
this.c=p},
on(){return this.h3(null)},
gm(a){return this.b}}
A.kd.prototype={}
A.kV.prototype={
gqX(){var s,r,q,p,o,n=this,m=n.w
if(m!=null)return m
s=n.d
s.toString
r=n.e
if(r===0)q=new Uint8Array(A.uE(s))
else if(r===8){r=n.r
p=A.jI(B.eN)
o=A.jI(B.ev)
s=A.xc(s,B.aD,null,null)
r=new A.kc(new Uint8Array(r))
new A.nQ(s,r,p,o).oX()
q=J.ho(B.u.gdf(r.c),r.c.byteOffset,r.b)}else throw A.i(A.aV("ZIP compression method "+r+" is not supported."))
return n.w=q}}
A.tu.prototype={
ly(a){var s,r=this.b.h(0,a)
if(r==null)s=null
else{s=this.a
if(r>>>0!==r||r>=s.length)return A.d(s,r)
s=s[r]}return s==null?null:s.gqX()},
dv(a){var s=this.ly(a)
if(s==null)return null
return B.aJ.dY(A.i4(s,s.length>=3&&s[0]===239&&s[1]===187&&s[2]===191?3:0,null))}}
A.bR.prototype={
bA(){return"ElementType."+this.b}}
A.fx.prototype={
bA(){return"RowFlex."+this.b}}
A.kw.prototype={
bA(){return"TableBorder."+this.b}}
A.eI.prototype={
bA(){return"TdBorder."+this.b}}
A.dZ.prototype={
bA(){return"TitleLevel."+this.b}}
A.ew.prototype={
gb_(){return this.b}}
A.jJ.prototype={}
A.jK.prototype={}
A.ex.prototype={}
A.hA.prototype={}
A.na.prototype={
oo(b3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1=null,b2="NUMPAGES"
for(s=b3.b,r=s.length,q=this.b,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
if(!(o instanceof A.cX))continue
n=new A.a_("")
for(m=o.b,l=m.length,k=b1,j=!1,i=B.z,h="",g=0;g<m.length;m.length===l||(0,A.k)(m),++g){f=m[g]
e=f instanceof A.fZ
d=e?f:b1
if(e){c=d.a.toUpperCase()
b=!0
if(B.b.v(c,b2)){n.a+="{pageCount}"
j=b}else if(B.b.v(c,"PAGE")){n.a+="{pageNo}"
j=b}else for(e=d.b,a=e.length,a0=0;a0<e.length;e.length===a||(0,A.k)(e),++a0){a1=e[a0]
a2=a1.gdz()
n.a+=a2
if(k==null)k=q.cY(o,a1.a)}continue}e=f instanceof A.eN
a1=e?f:b1
if(e){for(e=a1.b,a=e.length,a2=a1.a,a0=0;a0<e.length;e.length===a||(0,A.k)(e),++a0){a3=e[a0]
a4=a3 instanceof A.fR
a5=a4?a3:b1
if(a4){$label0$2:{a6=a5.a
if("begin"===a6){i=B.O
h=""
break $label0$2}if("separate"===a6){i=B.bP
break $label0$2}c=h.toUpperCase()
b=!0
if(B.b.v(c,b2)){n.a+="{pageCount}"
j=b}else if(B.b.v(c,"PAGE")){n.a+="{pageNo}"
j=b}i=B.z}continue}a4=a3 instanceof A.fU
c=a4?a3:b1
if(a4){if(i===B.O)h+=c.a
continue}a4=a3 instanceof A.cY
a7=a4?a3:b1
if(a4){if(i===B.z){a4=a7.a
n.a+=a4
if(k==null)k=q.cY(o,a2)}continue}continue}continue}e=f instanceof A.fT
a8=e?f:b1
if(e){for(e=a8.c,a=e.length,a2=i===B.z,a0=0;a0<e.length;e.length===a||(0,A.k)(e),++a0){a1=e[a0]
if(a2){a4=a1.gdz()
n.a+=a4
if(k==null)k=q.cY(o,a1.a)}}continue}if(f instanceof A.fX)continue}if(!j)continue
a9=q.ic(o)
b0=k==null?q.cY(o,b1):k
s=n.a
s=s.charCodeAt(0)==0?s:s
B.a.k(this.d,'campos PAGE/NUMPAGES do rodap\xe9 renderizados dinamicamente (formato "'+s+'")')
r=A.x5(a9.c)
q=b0.z
q=q==null?b1:B.f.ah(q*2/3)
m=b0.b
if(m==null)m=b0.c
return new A.u2(s,r,q,m,A.x4(b0.Q),A.DM([o],t.tn))}return b1},
jA(a,b,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this,c=null
t.AB.a(a)
s=A.a([],t.fE)
for(r=d.d,q=d.b,p=!0,o=0;o<a.length;++o){n=a[o]
m=s.length
$label0$0:{l=n instanceof A.cX
k=l?n:c
j=!1
if(l){i=q.ic(k)
if(!p)B.a.k(s,d.k8(k,i))
B.a.H(s,d.jB(k,i,b))
p=j
break $label0$0}l=n instanceof A.eQ
h=l?n:c
if(l){if(!p)B.a.k(s,A.bC(c,c,c,c,c,c,c,c,c,c,c,c,c,c,c,c,c,"\n",c,c))
g=d.jC(h,b)
if(g!=null)B.a.k(s,g)
p=j
break $label0$0}l=n instanceof A.fW
f=l?n:c
if(l)B.a.k(r,"bloco preservado n\xe3o renderizado: "+f.a)}if(a0)for(e=m;e<s.length;++e)A.x6(s[e],o)}return s},
fZ(a,b){return this.jA(a,b,!1)},
o6(a0,a1,a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this,a=null
t.AB.a(a0)
t.rz.a(a2)
s=A.a([],t.fE)
for(r=a0.length,q=b.d,p=b.b,o=!0,n=0;n<a0.length;a0.length===r||(0,A.k)(a0),++n){m=a0[n]
l=m instanceof A.cX
k=l?m:a
j=!1
if(l){i=p.ic(k)
if(!o)B.a.k(s,b.k8(k,i))
h=b.jB(k,i,a1)
if(a2.v(0,k)){g=h.length
for(f=g-1;f>=0;--f)if(h[f].c==="\n"){g=f
break}h=B.a.dM(h,0,g)}B.a.H(s,h)
o=j
continue}l=m instanceof A.eQ
e=l?m:a
if(l){if(!o)B.a.k(s,A.bC(a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,"\n",a,a))
d=b.jC(e,a1)
if(d!=null)B.a.k(s,d)
o=j
continue}l=m instanceof A.fW
c=l?m:a
if(l)B.a.k(q,"bloco de rodap\xe9 preservado n\xe3o renderizado: "+c.a)}if(s.length===0)B.a.k(s,A.bC(a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,"",a,a))
return s},
qw(a){var s,r,q,p,o,n,m,l=null
t.Dc.a(a)
for(s=a.$flags|0,r=0,q=0;p=a.length,q<=p;++q){if(q!==p){if(!(q>=0&&q<p))return A.d(a,q)
o=a[q].c==="\n"}else o=!0
if(!o)continue
p=this.jW(a,r,q)
if(this.pf(B.b.R(A.O(p,"\xa0"," ")))){if(r>0){p=r-1
if(!(p<a.length))return A.d(a,p)
p=a[p].c==="\n"}else p=!1
n=p?r-1:r
p=a.length
m=q<p?q+1:q
s&1&&A.ak(a,18)
A.b6(n,m,p)
a.splice(n,m-n)
q=n-1
r=n
continue}r=q+1}if(p===0)B.a.k(a,A.bC(l,l,l,l,l,l,l,l,l,l,l,l,l,l,l,l,l,"",l,l))},
jW(a,b,c){var s,r,q,p,o
t.Dc.a(a)
s=new A.a_("")
for(r=b;r<c;++r){if(!(r>=0&&r<a.length))return A.d(a,r)
q=a[r]
p=q.b
if(p==null||p===B.a8||p===B.a9||p===B.a7)s.a+=q.c
o=q.y1
if(o!=null){p=this.jW(o,0,o.length)
s.a+=p}}p=s.a
return p.charCodeAt(0)==0?p:p},
pf(a){var s
if(a.length===0)return!1
s=A.D("^(?:P\xe1gina|Page)\\s+\\d+\\s*(?:\\||/|de|of)\\s*\\d+$",!1,!1)
return s.b.test(a)},
k8(a,b){var s,r=null,q=this.b.cY(a,r),p=q.z,o=A.x5(b.c),n=q.b
if(n==null)n=q.c
s=A.bC(r,r,r,r,r,n,r,r,r,r,o,p==null?r:B.f.ah(p*2/3),r,r,r,r,r,"\n",r,r)
A.hB(s,this.k7(b))
return s},
jB(b1,b2,b3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=this,a5=null,a6=A.x5(b2.c),a7=a4.k7(b2),a8=t.fE,a9=A.a([],a8),b0=b2.b
if(b0!=null){s=b0.a
s=s!=null&&s!==0}else s=!1
if(s){s=b0.a
s.toString
r=a4.c.tT(s,b0.b)
if(r!=null&&r.length!==0)B.a.k(a9,a4.eR(A.p(r)+"\t",a4.b.cY(b1,a5),a6,a7))}for(s=b1.b,q=s.length,p=a4.d,o=a4.a.a,n=B.z,m=0;m<s.length;s.length===q||(0,A.k)(s),++m){l=s[m]
k=l instanceof A.eN
j=k?l:a5
if(k){n=a4.h_(b1,j,a9,n,a6,a7,b3)
continue}k=l instanceof A.fT
i=k?l:a5
if(k){h=A.a([],a8)
for(k=i.c,g=k.length,f=B.z,e=0;e<k.length;k.length===g||(0,A.k)(k),++e)f=a4.h_(b1,k[e],h,f,a5,a7,b3)
if(h.length===0)continue
k=i.a
if(k!=null){d=o.ej(b3).eW(k)
c=d!=null&&d.d?d.c:a5}else{k=i.b
c=k!=null?"#"+k:a5}b=A.bC(a5,a5,a5,a5,a5,a5,a5,a5,a5,a5,a6,a5,a5,a5,B.a7,a5,c==null?"":c,"",h,a5)
A.hB(b,a7)
B.a.k(a9,b)
continue}k=l instanceof A.fZ
a=k?l:a5
if(k){B.a.k(p,"fldSimple com resultado em cache: "+B.b.R(a.a))
for(k=a.b,g=k.length,a0=B.z,e=0;e<k.length;k.length===g||(0,A.k)(k),++e)a0=a4.h_(b1,k[e],a9,a0,a6,a7,b3)
continue}k=l instanceof A.fX
a1=k?l:a5
if(k)if(a1.a==="mc:AlternateContent")B.a.k(p,"text box (carimbo) preservado, sem render (placeholder na Fase 4.8)")}a2=b2.at
if(a2!=null&&a2>=0&&a9.length!==0){a3=A.bC(a5,a5,a5,a5,a5,a5,a5,a5,a5,A.Dg(a2),a6,a5,a5,a5,B.S,a5,a5,"",a9,a5)
A.hB(a3,a7)
return A.a([a3],a8)}return a9},
h_(a5,a6,a7,a8,a9,b0,b1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=this,a4=null
t.Dc.a(a7)
s=a3.b.cY(a5,a6.a)
for(r=a6.b,q=r.length,p=a3.d,o=a3.e,n=t.bj,m=a8,l=0;l<r.length;r.length===q||(0,A.k)(r),++l){k=r[l]
j=k instanceof A.fR
i=j?k:a4
if(j){h=i.a
$label0$0:{if("begin"===h){j=B.O
break $label0$0}if("separate"===h){j=B.bP
break $label0$0}j=B.z
break $label0$0}m=j
continue}j=k instanceof A.fU
g=j?k:a4
if(j){if(m===B.O)B.a.k(p,"campo com resultado em cache: "+B.b.R(g.a)+" (motor de campos na Fase 4.7)")
continue}j=k instanceof A.cY
f=j?k:a4
if(j){if(m!==B.O&&f.a.length!==0)B.a.k(a7,a3.eR(f.a,s,a9,b0))
continue}if(k instanceof A.ib){e=A.bC(a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a9,a4,a4,a4,B.ca,a4,a4,"",a4,a4)
A.hB(e,b0)
B.a.k(a7,e)
continue}j=k instanceof A.fQ
d=j?k:a4
if(j){if(d.a==="page")B.a.k(a7,A.bC(a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,B.aO,a4,a4,"",a4,a4))
else{c=A.bC(a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,"\n",a4,a4)
A.hB(c,b0)
B.a.k(a7,c)}continue}if(k instanceof A.i9){B.a.k(a7,a3.eR("\u2011",s,a9,b0))
continue}j=k instanceof A.ia
b=j?k:a4
if(j){B.a.k(a7,a3.eR(A.Df(b),s,a9,b0))
continue}j=k instanceof A.i8
a=j?k:a4
if(j){a0=a3.o5(a,b1)
if(a0!=null)B.a.k(a7,a0)
continue}j=k instanceof A.h_
a1=j?k:a4
if(j){B.a.k(p,"text box (carimbo) renderizado como caixa flutuante (edi\xe7\xe3o direta fica para F4.8)")
a3.fZ(n.a(a1).x,b1)
B.a.k(o,new A.hA())
continue}j=k instanceof A.fY
a2=j?k:a4
if(j){j=a2.a
if(j==="mc:AlternateContent"||j==="w:pict")B.a.k(p,"shape preservado, sem render (Fase 4.8): "+j)}}return m},
eR(a,b,c,d){var s,r,q,p,o=null,n=b.z,m=b.r,l=b.as,k=l!=null?B.fL.h(0,l):A.zb(b.at)
l=b.x===!0?a.toUpperCase():a
s=b.b
if(s==null)s=b.c
r=n==null?o:B.f.ah(n*2/3)
q=m!=null&&m!=="none"?!0:o
p=A.bC(b.e,o,o,o,A.x4(b.Q),s,o,k,b.f,o,c,r,b.w,o,o,q,o,l,o,o)
A.hB(p,d)
l=b.ax
if(l==="superscript")p.b=B.a8
else if(l==="subscript")p.b=B.a9
return p},
o5(a,b){var s,r,q,p,o,n=this,m=null,l=a.a
if(l==null){B.a.k(n.d,"drawing sem blip embed ignorado")
return m}s=n.a
r=s.ta(l,b)
if(r==null){B.a.k(n.d,"imagem n\xe3o encontrada para rel "+l+" de "+b)
return m}q=s.tb(l,b)
if(q==null)q="image/png"
if(!a.d)B.a.k(n.d,"imagem flutuante renderizada como inline (Fase 4)")
t.Bd.i("bN.S").a(r)
s=B.aE.ghH().cu(r)
p=a.b
p=p==null?100:p/9525
o=a.c
o=o==null?100:o/9525
p=A.bC(m,m,m,m,m,m,o,m,m,m,m,m,m,m,B.aN,m,m,"data:"+q+";base64,"+s,m,p)
s=t.N
A.l(["wpDrawing",a.e],s,s)
return p},
jC(b1,b2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9=null,b0=b1.c
if(b0.length===0)return a9
s=A.a([],t.F8)
for(r=b1.b,q=r.length,p=0;p<r.length;r.length===q||(0,A.k)(r),++p)s.push(new A.jJ(r[p]/15))
o=A.a([],t.uw)
for(r=b0.length,q=t.X,p=0;p<b0.length;b0.length===r||(0,A.k)(b0),++p){n=b0[p]
m=A.a([],q)
for(l=n.b,k=l.length,j=0,i=0;i<l.length;l.length===k||(0,A.k)(l),++i){h=l[i]
B.a.k(m,j)
g=h.a
g=g==null?a9:g.b
j+=g==null?1:g}B.a.k(o,m)}f=new A.nc(o,b1)
e=A.a([],t.sW)
for(r=t.h5,d=0;d<b0.length;++d){n=b0[d]
c=n.a
if((c==null?a9:c.a)!=null){q=c.a
q.toString
b=q/15}else b=40
a=A.a([],r)
for(q=n.b,a0=0;a0<q.length;++a0){h=q[a0]
a1=h.a
l=a1==null
if((l?a9:a1.c)==="continue")continue
a2=this.o4(h.b,b2)
k=l?a9:a1.b
if(k==null)k=1
g=(l?a9:a1.c)==="restart"?f.$2(d,a0):1
a3=A.zb(l?a9:a1.e)
a4=l?a9:a1.f
$label0$3:{if("center"===a4)break $label0$3
if("bottom"===a4)break $label0$3
if("top"===a4)break $label0$3
break $label0$3}this.nJ(l?a9:a1.d)
B.a.k(a,new A.jK(k,g,a2,a3))}if(a.length===0)continue
q=B.f.aC(b,20,1/0)
B.a.k(e,new A.ex(q,a))}if(e.length===0)return a9
a5=this.b.uh(b1)
b0=new A.nd()
if(a5!=null)a6=A.ac(b0.$1(a5.a))||A.ac(b0.$1(a5.c))||A.ac(b0.$1(a5.b))||A.ac(b0.$1(a5.d))||A.ac(b0.$1(a5.e))||A.ac(b0.$1(a5.f))
else a6=!1
if(a6){b0=a5.e
a7=b0==null?a5.a:b0
if(a7==null)a7=a5.b
a8=A.x4(a7==null?a9:a7.c)}else a8=a9
return A.bC(a9,a8,a6?B.mP:B.mQ,s,a9,a9,a9,a9,a9,a9,a9,a9,a9,e,B.T,a9,a9,"",a9,a9)},
o4(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g=null
t.AB.a(a)
s=A.a([],t.zK)
for(r=a.length,q=this.d,p=0;p<a.length;a.length===r||(0,A.k)(a),++p){o=a[p]
if(o instanceof A.eQ){B.a.k(q,"tabela aninhada achatada em c\xe9lula (n\xe3o suportada)")
for(n=o.c,m=n.length,l=0;l<n.length;n.length===m||(0,A.k)(n),++l)for(k=n[l].b,j=k.length,i=0;i<k.length;k.length===j||(0,A.k)(k),++i)B.a.H(s,k[i].b)}else B.a.k(s,o)}h=this.fZ(s,b)
if(h.length===0)B.a.k(h,A.bC(g,g,g,g,g,g,g,g,g,g,g,g,g,g,g,g,g,"",g,g))
return h},
nJ(a){var s,r
if(a==null)return null
s=new A.nb()
r=A.a([],t.yO)
if(A.ac(s.$1(a.a)))r.push(B.mR)
if(A.ac(s.$1(a.d)))r.push(B.mS)
if(A.ac(s.$1(a.c)))r.push(B.mT)
if(A.ac(s.$1(a.b)))r.push(B.mU)
return r.length===0?null:r},
k7(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=null,c=a.d,b=a.b
if(b!=null){s=b.a
s=s!=null&&s!==0}else s=!1
if(s){s=b.a
s.toString
s=this.a.d.ec(s,b.b)
r=s==null?d:s.f}else r=d
q=a.e
s=q==null
p=s?d:q.a
if(p==null)p=r==null?d:r.a
o=s?d:q.c
if(o==null)o=r==null?d:r.c
n=s?d:q.d
if(n==null)n=r==null?d:r.d
s=c==null
m=s?d:c.c
l=s?d:c.d
if(l==null)l="auto"
k="auto"
if(m!=null&&m>0)if(l==="atLeast"||l==="exact"){if(typeof m!=="number")return m.lZ()
j=m/15
k=l}else{if(typeof m!=="number")return m.lZ()
j=m/240}else j=1
if((s?d:c.a)==null)i=d
else{i=c.a
i.toString
i/=15}if((s?d:c.b)==null)s=d
else{s=c.b
s.toString
s/=15}h=p==null?d:p/15
g=o==null
f=g?0:o
e=n==null
if(f-(e?0:n)===0)g=d
else{g=g?0:o
g=(g-(e?0:n))/15}return new A.u3(k,j,i,s,h,g)}}
A.nc.prototype={
$2(a,b){var s,r,q,p,o,n,m,l,k,j,i=this.a,h=i.length
if(!(a<h))return A.d(i,a)
s=i[a]
if(!(b<s.length))return A.d(s,b)
r=s[b]
for(q=a+1,s=this.b.c,p=s.length,o=1;q<p;++q){n=s[q].b
l=n.length
k=0
while(!0){if(!(k<l)){m=!1
break}c$0:{if(!(q<h))return A.d(i,q)
j=i[q]
if(!(k<j.length))return A.d(j,k)
if(j[k]!==r)break c$0
l=n[k].a
m=(l==null?null:l.c)==="continue"
if(m)++o
break}++k}if(!m)break}return o},
$S:44}
A.nd.prototype={
$1(a){var s
if(a!=null){s=a.a
s=s!=null&&s!=="none"&&s!=="nil"}else s=!1
return s},
$S:64}
A.nb.prototype={
$1(a){var s
if(a!=null){s=a.a
s=s!=null&&s!=="none"&&s!=="nil"}else s=!1
return s},
$S:64}
A.ik.prototype={
bA(){return"_FieldState."+this.b}}
A.u2.prototype={}
A.u3.prototype={}
A.oR.prototype={
$2(a,b){var s,r,q
t.P.a(b)
if(a.length===0)return
s=t.N
r=t.z
q=A.b(s,r)
q.j(0,"insert",a)
if(b.a!==0)q.j(0,"attributes",A.Y(b,s,r))
B.a.k(this.a,q)},
$S:203}
A.oQ.prototype={
$1(a){var s,r,q
t.P.a(a)
s=t.N
r=t.z
q=A.b(s,r)
q.j(0,"insert","\n")
if(a.gal(a))q.j(0,"attributes",A.Y(a,s,r))
B.a.k(this.a,q)},
$S:162}
A.oS.prototype={
$2(b7,b8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3=this,b4="insert",b5="link",b6="attributes"
t.Dc.a(b7)
t.P.a(b8)
$label0$1:for(s=b7.length,r=b3.d,q=b3.c,p=t.N,o=t.z,n=b3.b,m=b3.a,l=t.G,k=t.S,j=0;j<b7.length;b7.length===s||(0,A.k)(b7),++j){i=b7[j]
switch(i.b){case B.S:h=A.cR(p,o)
h.H(0,b8)
g=i.rB
if(g!=null)h.j(0,"header",A.E8(g))
g=i.y1
b3.$2(g==null?B.ah:g,h)
if(n.length===0||!J.A(B.a.gK(n).h(0,b4),"\n"))q.$1(A.xr(i,h))
continue $label0$1
case B.a6:h=A.cR(p,o)
h.H(0,b8)
h.j(0,"list","bullet")
g=i.y1
b3.$2(g==null?B.ah:g,h)
if(n.length===0||!J.A(B.a.gK(n).h(0,b4),"\n"))q.$1(A.xr(i,h))
continue $label0$1
case B.a7:h=A.cR(p,o)
h.H(0,b8)
g=i.y2
if(g!=null)h.j(0,b5,g)
g=i.y1
b3.$2(g==null?B.ah:g,h)
continue $label0$1
case B.aN:h=A.l(["image",i.c],p,o)
g=A.b(p,o)
f=i.w
if(f!=null)g.j(0,"width",f)
f=i.x
if(f!=null)g.j(0,"height",f)
B.a.k(n,A.l(["insert",h,"attributes",g],p,o))
continue $label0$1
case B.T:if(n.length!==0){e=B.a.gK(n).h(0,b4)
if(typeof e!="string"||!B.b.be(e,"\n"))q.$1(B.l)}++m.a
d=i.k1
if(d==null)d=B.e7
h=i.id
g=h==null
c=g?null:h.length
if(c==null)c=B.a.ag(d,0,new A.oT(),k)
for(g=!g,b=0;b<c;++b){if(g&&b<h.length){if(!(b<h.length))return A.d(h,b)
a=h[b].b}else a=72
q.$1(A.l(["table-col",A.l(["width",""+B.f.ah(a)],p,o)],p,o))}for(a0=0;a0<d.length;){a1=d[a0];++a0
h=""+a0
a2="row-t"+m.a+"-r"+h
for(g=a1.e,b=0;b<g.length;){a3=g[b];++b
a4="cell-t"+m.a+"-r"+h+"-c"+b
f=A.b(p,o)
f.j(0,"data-row",a2)
a5=a3.x
if(a5>1)f.j(0,"colspan",""+a5)
a5=a3.y
if(a5>1)f.j(0,"rowspan",""+a5)
f.j(0,"height",""+B.f.ah(a1.d))
a5=a3.dx
if(a5!=null)f.j(0,"style","background-color: "+a5)
a6=A.l(["table-cell-block",a4,"table-cell",f],p,o)
a7=n.length
b3.$2(a3.z,a6)
if(!(n.length>a7&&J.A(B.a.gK(n).h(0,b4),"\n")&&l.b(B.a.gK(n).h(0,b6))&&A.E7(l.a(B.a.gK(n).h(0,b6)).c2(0,p,o))===a4))q.$1(a6)}}continue $label0$1
case B.cb:case B.aO:q.$1(B.l)
continue $label0$1
default:break}h=A.b(p,o)
if(b8.p(b5))h.j(0,b5,b8.h(0,b5))
if(i.y===!0)h.j(0,"bold",!0)
if(i.as===!0)h.j(0,"italic",!0)
if(i.at===!0)h.j(0,"underline",!0)
if(i.ax===!0)h.j(0,"strike",!0)
g=i.z
if(g!=null)h.j(0,"color",g)
g=i.Q
if(g!=null)h.j(0,"background",g)
g=i.f
if(g!=null)h.j(0,"font",g)
g=i.r
if(g!=null){a8=B.f.ah(g*0.75*2)/2
h.j(0,"size",(a8===B.f.fk(a8)?""+B.f.ah(a8):B.f.B(a8))+"pt")}if(i.b===B.a8)h.j(0,"script","super")
if(i.b===B.a9)h.j(0,"script","sub")
a9=A.xr(i,b8)
b0=i.c
for(g=b0.length,b1=0,b2=0;b2<g;++b2)if(b0[b2]==="\n"){r.$2(B.b.t(b0,b1,b2),h)
q.$1(a9)
b1=b2+1}r.$2(B.b.L(b0,b1),h)}},
$S:163}
A.oT.prototype={
$2(a,b){var s,r,q,p
A.v(a)
for(s=t.uk.a(b).e,r=s.length,q=0,p=0;p<r;++p)q+=s[p].x
return q>a?q:a},
$S:164}
A.eq.prototype={
gdk(){var s=this
return s.a.n(0,s.c)&&s.b===s.d}}
A.eU.prototype={
n(a,b){if(b==null)return!1
if(this===b)return!0
return b instanceof A.eU&&b.a===this.a},
ga3(a){return J.b4(this.a)},
D(a,b){var s=b==null?null:b.a
t.m.a(this.a.insertBefore(a.a,s))},
Y(a){var s=this.a,r=t.A.a(s.parentNode)
if(r!=null)t.m.a(r.removeChild(s))},
gan(){var s,r,q,p=t.m.a(this.a.childNodes),o=A.a([],t.wo)
for(s=t.A,r=0;r<A.v(p.length);++r){q=s.a(p.item(r))
q.toString
o.push(A.S(q))}return o},
gf6(){var s=this.a,r=t.A
if(r.a(s.firstChild)==null)s=null
else{s=r.a(s.firstChild)
s.toString
s=A.S(s)}return s},
gcB(){var s=this.a,r=t.A
if(r.a(s.nextSibling)==null)s=null
else{s=r.a(s.nextSibling)
s.toString
s=A.S(s)}return s},
gaG(){var s=this.a,r=t.A
if(r.a(s.parentNode)==null)s=null
else{s=r.a(s.parentNode)
s.toString
s=A.S(s)}return s},
geh(){var s=this.a,r=t.A
if(r.a(s.previousSibling)==null)s=null
else{s=r.a(s.previousSibling)
s.toString
s=A.S(s)}return s},
$ia7:1}
A.ca.prototype={
gb_(){return A.h(this.a.type)},
gcU(){var s=this.a,r=A.Z(s,"KeyboardEvent")
if(r)return A.I(s.isComposing)
r=A.Z(s,"InputEvent")
if(r)return A.I(s.isComposing)
return!1},
geb(){var s=this.a,r=A.Z(s,"KeyboardEvent")
return r?A.h(s.key):null},
gkQ(){var s=this.a,r=A.Z(s,"MouseEvent")
return r?A.v(s.clientX):0},
gkR(){var s=this.a,r=A.Z(s,"MouseEvent")
return r?A.v(s.clientY):0},
gau(){var s=t.A.a(this.a.target)
return s==null?null:new A.nK(s)}}
A.nK.prototype={
gcz(){var s,r,q,p=this.a,o=A.Z(p,"HTMLInputElement")
if(!o)return null
o=t.A
s=o.a(p.files)
if(s==null)return null
p=A.a([],t.yv)
for(r=0;r<A.v(s.length);++r){q=o.a(s.item(r))
q.toString
p.push(new A.dJ(q))}return p}}
A.fj.prototype={
gau(){var s,r=t.A.a(this.a.target)
if(r==null)return null
s=A.Z(r,"Node")
if(s)return A.S(r)
return null},
$ibA:1}
A.ev.prototype={
ghU(){var s=this.a,r=A.Z(s,"InputEvent")
if(!r)return null
return A.h(s.inputType)},
gri(){var s=this.a,r=A.Z(s,"InputEvent")
if(!r)return null
return A.m(s.data)},
gcO(){var s,r=this.a,q=A.Z(r,"InputEvent")
if(!q)return null
s=t.A.a(r.dataTransfer)
return s==null?null:new A.fi(s)},
mj(){var s,r,q,p=this.a,o=A.Z(p,"InputEvent")
if(!o)return B.b7
if(!("getTargetRanges" in p))return B.b7
s=t.Cf.a(p.getTargetRanges())
s=t.nx.b(s)?s:new A.bd(s,A.K(s).i("bd<1,am>"))
p=A.a([],t.yX)
for(o=J.U(s),r=t.m;o.l();){q=o.gq()
p.push(new A.eq(A.S(r.a(q.startContainer)),A.v(q.startOffset),A.S(r.a(q.endContainer)),A.v(q.endOffset)))}return p},
$iDi:1}
A.jH.prototype={
lF(){var s=A.a([],t.B),r=t.Cf.a(this.a.takeRecords())
r=J.U(t.nx.b(r)?r:new A.bd(r,A.K(r).i("bd<1,am>")))
for(;r.l();)s.push(new A.fk(r.gq()))
return s},
$inf:1}
A.fk.prototype={
gb_(){return A.h(this.a.type)},
$icq:1}
A.hH.prototype={
gcM(){var s,r=this.a,q=A.Z(r,"ClipboardEvent")
if(!q)return null
s=t.A.a(r.clipboardData)
return s==null?null:new A.fi(s)},
$izc:1}
A.bB.prototype={
gcO(){var s,r=this.a,q=A.Z(r,"DragEvent")
if(!q)return null
s=t.A.a(r.dataTransfer)
return s==null?null:new A.fi(s)},
$iDk:1}
A.cv.prototype={$iDj:1}
A.fi.prototype={
gcz(){var s,r,q,p=t.m.a(this.a.files),o=A.a([],t.jp)
for(s=t.A,r=0;r<A.v(p.length);++r){q=s.a(p.item(r))
q.toString
o.push(new A.dJ(q))}return o},
guv(){var s=A.a([],t.s),r=t.Cf.a(this.a.types)
r=J.U(t.c.b(r)?r:new A.bd(r,A.K(r).i("bd<1,e>")))
for(;r.l();)s.push(r.gq())
return s}}
A.dJ.prototype={
gb_(){return A.h(this.a.type)},
$ix7:1}
A.jF.prototype={
rb(a){var s,r,q,p
t.r9.a(a)
s=A.l_()
r=self.MutationObserver
q=new A.nD(a,s)
if(typeof q=="function")A.a4(A.au("Attempting to rewrap a JS function.",null))
p=function(b,c){return function(d,e){return b(c,d,e,arguments.length)}}(A.FV,q)
p[$.wU()]=q
s.b=new A.jH(t.m.a(new r(p)))
return s.bP()},
l9(a){var s=a.a,r=A.Z(s,"HTMLElement")
if(r)s.focus()
else{r=A.Z(s,"Element")
if(r)A.nU(s,"focus",null,null,t.dy)}},
kM(a){var s,r=a.a
if(t.A.a(t.m.a(self.document).activeElement)!==r)return
s=A.Z(r,"HTMLElement")
if(s)r.blur()},
lc(a){var s,r=a.a,q=t.A.a(t.m.a(self.document).activeElement)
if(q!=null){s=A.Z(r,"Node")
s=!s}else s=!0
if(s)return!1
return q===r||A.I(r.contains(q))},
iB(){var s,r=t.m,q=t.A.a(r.a(self.window).getSelection())
if(q==null||A.v(q.rangeCount)<=0)return null
s=r.a(q.getRangeAt(0))
return new A.eq(A.S(r.a(s.startContainer)),A.v(s.startOffset),A.S(r.a(s.endContainer)),A.v(s.endOffset))},
qO(a,b){var s,r,q,p,o,n=null,m=t.m,l=m.a(self.document)
if("caretRangeFromPoint" in l){s=A.nU(l,"caretRangeFromPoint",a,b,t.A)
if(s==null)return n
return new A.eq(A.S(m.a(s.startContainer)),A.v(s.startOffset),A.S(m.a(s.endContainer)),A.v(s.endOffset))}if("caretPositionFromPoint" in l){m=t.A
r=A.nU(l,"caretPositionFromPoint",a,b,m)
if(r==null)return n
q=m.a(r.offsetNode)
p=A.FL(r.offset)
if(q==null||p==null)return n
o=A.S(q)
A.v(p)
return new A.eq(o,p,o,p)}return n},
iU(a,b,c,d){var s,r=self,q=t.m,p=t.A.a(q.a(r.window).getSelection())
if(p==null)return
s=q.a(q.a(r.document).createRange())
s.setStart(a.a,b)
s.setEnd(c.a,d)
p.removeAllRanges()
p.addRange(s)},
m1(a,b,c){var s,r,q,p,o,n=a.a,m=A.Z(n,"Element")
if(!m)return null
s=A.B2(n,b)
r=A.B2(n,b+c)
m=t.m
q=m.a(m.a(self.document).createRange())
q.setStart(s.a,s.b)
q.setEnd(r.a,r.b)
if(c>0)p=m.a(q.getBoundingClientRect())
else{o=m.a(q.getClientRects())
p=A.v(o.length)>0?t.A.a(o.item(0)):null
if(p==null)p=m.a(q.getBoundingClientRect())}if(A.a9(p.width)===0&&A.a9(p.height)===0)return null
return A.l(["left",A.a9(p.left),"right",A.a9(p.right),"top",A.a9(p.top),"bottom",A.a9(p.bottom),"width",A.a9(p.width),"height",A.a9(p.height)],t.N,t.z)},
iC(a,b,c,d){var s,r,q,p,o=a.a,n=c.a,m=t.m,l=m.a(m.a(self.document).createRange())
if(!(o===n&&b===d)){l.setStart(o,b)
l.setEnd(n,d)
s=m.a(l.getBoundingClientRect())
return A.l(["left",A.a9(s.left),"right",A.a9(s.right),"top",A.a9(s.top),"bottom",A.a9(s.bottom),"width",A.a9(s.width),"height",A.a9(s.height)],t.N,t.z)}r=A.Z(o,"Text")
if(r){if(A.h(o.data).length===0)return null
if(b<A.h(o.data).length){l.setStart(o,b)
l.setEnd(o,b+1)
q="left"}else{l.setStart(o,b-1)
l.setEnd(o,b)
q="right"}s=m.a(l.getBoundingClientRect())}else{r=A.Z(o,"Element")
if(r){s=m.a(o.getBoundingClientRect())
q=b>0?"right":"left"}else return null}p=q==="right"?A.a9(s.right):A.a9(s.left)
return A.l(["left",p,"right",p,"top",A.a9(s.top),"bottom",A.a9(s.bottom),"width",0,"height",A.a9(s.height)],t.N,t.z)},
fs(a,b){var s,r,q,p,o,n,m,l=null,k=a.a,j=A.Z(k,"Element")
if(!j)return l
j=t.m
s=j.a(k.getBoundingClientRect())
if(b instanceof A.eU){r=b.a
q=A.Z(r,"Element")
p=q?j.a(r.getBoundingClientRect()):l}else p=l
j=A.a9(s.left)
q=p==null
o=q?l:A.a9(p.left)
n=j-(o==null?0:o)
j=A.a9(s.top)
q=q?l:A.a9(p.top)
m=j-(q==null?0:q)
return A.l(["left",n,"right",n+A.a9(s.width),"top",m,"bottom",m+A.a9(s.height),"width",A.a9(s.width),"height",A.a9(s.height)],t.N,t.z)},
ce(a){return this.fs(a,null)},
me(a){var s,r,q,p=t.T.a(a).a,o=t.A.a(p.parentElement)
if(o!=null)return new A.f(A.b(t.O,t.g),o)
s=t.m
r=s.a(p.getRootNode())
q=A.Z(r,"ShadowRoot")
if(q)return new A.f(A.b(t.O,t.g),s.a(r.host))
return null},
iF(a){var s=self,r=t.m,q=t.A,p=q.a(r.a(s.window).visualViewport),o=p==null,n=o?null:A.a9(p.width)
if(n==null)n=A.v(q.a(r.a(s.document).documentElement).clientWidth)
o=o?null:A.a9(p.height)
return A.l(["width",n,"height",o==null?A.v(q.a(r.a(s.document).documentElement).clientHeight):o],t.N,t.pR)},
dC(a,b){var s=a.a,r=A.Z(s,"Element")
if(!r)return""
r=t.m
return A.h(r.a(r.a(self.window).getComputedStyle(s)).getPropertyValue(b))},
u6(a){var s,r,q,p
if(a instanceof A.dJ)s=a.a
else{if(t.m.b(a))r=A.Z(a,"File")
else r=!1
s=r?a:null}if(s==null){r=new A.aN($.aB,t.gH)
r.fO(null)
return r}r=new A.aN($.aB,t.gH)
q=new A.eR(r,t.h6)
p=t.m.a(new self.FileReader())
p.onload=A.f2(new A.nE(q,p))
p.onerror=A.f2(new A.nF(q))
p.readAsDataURL(s)
return r},
$iDh:1}
A.nD.prototype={
$2(a,b){var s,r
t.Cf.a(a)
t.m.a(b)
s=A.a([],t.B)
r=J.U(t.nx.b(a)?a:new A.bd(a,A.K(a).i("bd<1,am>")))
for(;r.l();)s.push(new A.fk(r.gq()))
this.a.$2(s,this.b.bP())},
$S:165}
A.nE.prototype={
$1(a){var s,r,q
t.m.a(a)
s=this.a
if((s.a.a&30)===0){r=this.b.result
if(r==null)q=null
else{q=A.iQ(r)
q=q==null?null:J.L(q)}s.dW(q)}},
$S:27}
A.nF.prototype={
$1(a){var s
t.m.a(a)
s=this.a
if((s.a.a&30)===0)s.dW(null)},
$S:27}
A.uF.prototype={
$1(a){var s,r,q,p,o,n=A.Z(a,"Text")
if(n){n=this.a
n.b=a
s=A.h(a.data).length
r=n.a
if(r<=s)return new A.f0(a,r)
n.a=r-s
return null}q=t.m.a(a.childNodes)
for(n=t.A,p=0;p<A.v(q.length);++p){r=n.a(q.item(p))
r.toString
o=this.$1(r)
if(o!=null)return o}return null},
$S:167}
A.hI.prototype={
gff(){return t.m.a(self.document)},
I(a,b){var s,r
t.O.a(b)
s=new A.ao(a,b)
if($.xb.p(s))return
r=A.f2(new A.nG(b))
$.xb.j(0,s,r)
this.gff().addEventListener(a,r)},
ca(a,b){var s=$.xb.Z(0,new A.ao(a,t.O.a(b)))
if(s!=null)this.gff().removeEventListener(a,s)},
cN(a){var s=t.m
return new A.f(A.b(t.O,t.g),s.a(s.a(self.document).createElement(a)))},
a_(a){var s,r,q,p,o,n=t.m,m=n.a(n.a(self.document).querySelectorAll(a))
n=A.a([],t.r)
for(s=t.A,r=t.O,q=t.g,p=0;p<A.v(m.length);++p){o=s.a(m.item(p))
o.toString
n.push(new A.f(A.b(r,q),o))}return n},
aI(a){var s=t.A.a(t.m.a(self.document).querySelector(a))
return s==null?null:new A.f(A.b(t.O,t.g),s)},
ghF(){var s=t.A.a(t.m.a(self.document).documentElement)
s.toString
return new A.f(A.b(t.O,t.g),s)},
$ihC:1}
A.nG.prototype={
$1(a){var s
t.m.a(a)
s=A.Z(a,"MouseEvent")
s=s?new A.bB(a):new A.fj(a)
this.a.$1(s)},
$S:27}
A.fl.prototype={
fg(a,b){return new A.bu(t.m.a(this.a.parseFromString(a,b)))}}
A.bu.prototype={
gff(){return this.a},
n(a,b){var s
if(b==null)return!1
if(this!==b)s=b instanceof A.bu&&b.a===this.a
else s=!0
return s},
ga3(a){return J.b4(this.a)},
cN(a){return new A.f(A.b(t.O,t.g),t.m.a(this.a.createElement(a)))},
aI(a){var s=t.A.a(this.a.querySelector(a))
return s==null?null:new A.f(A.b(t.O,t.g),s)},
a_(a){var s,r,q,p,o,n=t.m.a(this.a.querySelectorAll(a)),m=A.a([],t.r)
for(s=t.A,r=t.O,q=t.g,p=0;p<A.v(n.length);++p){o=s.a(n.item(p))
o.toString
m.push(new A.f(A.b(r,q),o))}return m},
gcq(){var s=this.a,r=t.A,q=r.a(s.body)
if(q!=null)return new A.f(A.b(t.O,t.g),q)
s=r.a(s.documentElement)
s.toString
return new A.f(A.b(t.O,t.g),s)},
ghF(){var s=t.A.a(this.a.documentElement)
s.toString
return new A.f(A.b(t.O,t.g),s)}}
A.f.prototype={
ga2(){var s=this.a,r=A.Z(s,"HTMLElement")
if(r)return new A.jG(t.m.a(s.style))
r=A.Z(s,"SVGElement")
if(r)return new A.jG(t.m.a(s.style))
return null},
gkL(){var s=A.a([],t.s),r=t.Cf.a(this.a.getAttributeNames())
r=J.U(t.c.b(r)?r:new A.bd(r,A.K(r).i("bd<1,e>")))
for(;r.l();)s.push(r.gq())
return s},
I(a,b){var s
t.O.a(b)
s=A.f2(new A.nH(a,b))
this.b.j(0,b,s)
this.a.addEventListener(a,s)},
ca(a,b){var s=this.b.Z(0,t.O.a(b))
if(s!=null)this.a.removeEventListener(a,s)},
a_(a){var s,r,q,p,o,n=t.m.a(this.a.querySelectorAll(a)),m=A.a([],t.r)
for(s=t.A,r=t.O,q=t.g,p=0;p<A.v(n.length);++p){o=s.a(n.item(p))
o.toString
m.push(new A.f(A.b(r,q),o))}return m},
v(a,b){if(b==null)return!1
return A.I(this.a.contains(b.a))},
aI(a){var s=t.A.a(this.a.querySelector(a))
return s==null?null:new A.f(A.b(t.O,t.g),s)},
fw(){var s=this.a,r=A.Z(s,"HTMLInputElement")
if(r)s.select()
else{r=A.Z(s,"HTMLTextAreaElement")
if(r)s.select()}},
gdt(){var s=this.a,r=A.Z(s,"HTMLElement")
return r?A.v(s.offsetWidth):0},
glo(){var s=this.a,r=A.Z(s,"HTMLElement")
return r?A.v(s.offsetHeight):0},
mo(a,b,c){var s,r,q=c?"smooth":"instant",p={behavior:q,left:a,top:b}
q=this.a
s=self
r=t.m
if(q===t.A.a(r.a(s.document).body))r.a(s.window).scrollBy(p)
else q.scrollBy(p)},
mn(a,b){return this.mo(a,b,!1)},
gaf(){var s=A.iQ(t.K.a(this.a.innerHTML))
return s==null?null:J.L(s)},
glt(){var s=A.iQ(t.K.a(this.a.outerHTML))
s=s==null?null:J.L(s)
return s==null?"":s},
saf(a){var s,r,q,p=a==null?"":a,o=t.m,n=o.a(o.a(new self.DOMParser()).parseFromString(p,"text/html")),m=t.A,l=m.a(n.body)
if(l==null)l=m.a(n.documentElement)
s=l!=null
if(s)A.Bm(l)
r=this.a
r.textContent=""
if(s){q=m.a(l.firstChild)
for(;q!=null;){o.a(r.appendChild(q))
q=m.a(l.firstChild)}}},
gcc(){var s=this.a,r=A.Z(s,"HTMLInputElement")
if(r)return A.h(s.value)
r=A.Z(s,"HTMLTextAreaElement")
if(r)return A.h(s.value)
return""},
scc(a){var s=this.a,r=A.Z(s,"HTMLInputElement")
if(r)s.value=a
else{r=A.Z(s,"HTMLTextAreaElement")
if(r)s.value=a}},
$iT:1}
A.nH.prototype={
$1(a){var s,r,q=this
t.m.a(a)
s=q.a
if(s==="beforeinput")q.b.$1(new A.ev(a))
else{r=t.s
if(B.a.v(A.a(["copy","cut","paste"],r),s))q.b.$1(new A.hH(a))
else if(B.a.v(A.a(["keydown","keyup","keypress"],r),s))q.b.$1(new A.cv(a))
else{s=A.Z(a,"MouseEvent")
r=q.b
if(s)r.$1(new A.bB(a))
else r.$1(new A.fj(a))}}},
$S:27}
A.bl.prototype={$izd:1}
A.b9.prototype={
gak(){var s,r,q,p=A.a([],t.s)
for(s=this.a,r=0;r<A.v(s.length);++r){q=A.m(s.item(r))
q.toString
p.push(q)}return p},
el(a,b){var s=this.a
if(b==null)A.I(s.toggle(a))
else A.I(s.toggle(a,b))},
dB(a){return this.el(a,null)}}
A.h1.prototype={
h(a,b){return typeof b=="string"?A.m(this.a.getAttribute(A.h2(b))):null},
j(a,b,c){A.h(b)
A.h(c)
this.a.setAttribute(A.h2(b),c)},
Z(a,b){var s,r,q
if(typeof b!="string")return null
s=A.h2(b)
r=this.a
q=A.m(r.getAttribute(s))
r.removeAttribute(s)
return q},
ga7(){var s,r=A.a([],t.s),q=t.Cf.a(this.a.getAttributeNames())
q=J.U(t.c.b(q)?q:new A.bd(q,A.K(q).i("bd<1,e>")))
for(;q.l();){s=q.gq()
if(B.b.a0(s,"data-"))r.push(A.F5(s))}return r}}
A.jG.prototype={
sbR(a){this.a.cssText=a},
aa(a,b){var s=b==null?"":b
this.a.setProperty(a,s)},
W(a,b){var s,r,q,p,o,n=null
t.pN.a(b)
s=$.C9().bk('Symbol("'+b.glm().a+'")')
if(s==null)r=n
else{q=s.b
if(1>=q.length)return A.d(q,1)
r=q[1]}if(r!=null&&r.length!==0){q=b.c
if(q===2){p=A.zl(B.b.t(r,0,r.length-1))
o=b.gi8().length!==0?B.a.gF(b.gi8()):n
this.aa(p,o==null?n:J.L(o))
return n}if(q===1)return A.h(this.a.getPropertyValue(A.zl(r)))}return this.mX(0,b)}}
A.ne.prototype={}
A.oP.prototype={
gb_(){return this.a}}
A.bY.prototype={}
A.b5.prototype={}
A.cU.prototype={}
A.kg.prototype={}
A.c_.prototype={
gA(){return"table-header"},
P(){var s,r,q,p=this.mR()
p.Z(0,"header")
s=t.N
r=t.z
p=A.aJ(p,s,r)
q=t.T.a(this.d).a
p.j(0,"table-header",A.l(["cellId",A.m(q.getAttribute("data-cell")),"value",B.a.ae(B.w,A.h(q.tagName).toUpperCase())+1],s,r))
return p},
cS(a,b,c){var s,r,q,p,o,n=this,m="table-cell-block"
A.h(a)
A.I(c)
if(a==="header"){s=t.T.a(n.d).a
r=B.a.ae(B.w,A.h(s.tagName).toUpperCase())
if(b!=null){q=J.a3(b)
r=q.n(b,!1)||q.n(b,r+1)}else r=!0
if(r)A.bo(n,m,A.m(s.getAttribute("data-cell")))
else A.bo(n,"table-header",A.l(["cellId",A.m(s.getAttribute("data-cell")),"value",b],t.N,t.z))
return}if(a==="list"){p=n.fq(n.a)
o=p.a
if(c){s=t.N
s=A.aJ(o,s,s)
s.j(0,"cellId",p.b)
A.c6(n,"table-list-container",s)}else A.c6(n,p.c,o)
A.bo(n,"table-list",b)
return}if((a==="table-cell"||a==="table-th")&&b!=null&&!J.A(b,!1)){A.c6(n,a,b)
return}if(a==="table-header")s=b==null||J.A(b,!1)
else s=!1
if(s){A.bo(n,m,A.m(t.T.a(n.d).a.getAttribute("data-cell")))
return}n.dN(a,b)},
N(a,b){return this.cS(a,b,!1)},
fq(a){var s,r=A.iT(a)
if(r==null)return new A.d0(B.H,"cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0"),"table-cell")
s=A.f4(r)
return new A.d0(s.a,s.b,r.gA())},
a1(){return A.xC(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))}}
A.b8.prototype={
gA(){return"table-list-container"},
gT(){return 5},
P(){return A.l(["table-list-container",A.Aa(t.T.a(this.d))],t.N,t.z)},
gaO(){return new A.qQ()},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.b8(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.qR.prototype={
$0(){return"1"},
$S:169}
A.qQ.prototype={
$1(a){return a instanceof A.cy},
$S:3}
A.cW.prototype={
gA(){return"table-list"},
P(){var s,r="list",q=t.T,p=new A.h1(q.a(this.d).a).h(0,r)
if(p==null){p=this.a
q=p instanceof A.b8?new A.h1(q.a(p.d).a).h(0,r):null
s=q}else s=p
if(s==null)s="bullet"
q=this.mW()
q.Z(0,r)
q=A.aJ(q,t.N,t.z)
q.j(0,"table-list",s)
return q},
cS(a,b,c){var s,r,q,p,o,n,m,l=this,k="table-cell-block",j="table-list-container"
A.h(a)
A.I(c)
if(a==="list"){s=l.P().h(0,"table-list")
if(b!=null){r=J.a3(b)
r=r.n(b,!1)||r.n(b,s)}else r=!0
if(r){q=l.fS()
l.iS(c)
A.bo(l,k,q)}else{r=t.T.a(l.d)
p=A.p(b)
r.a.setAttribute(A.h2("list"),p)}return}if(a==="header"){q=l.fS()
l.iS(c)
A.bo(l,"table-header",A.l(["cellId",q,"value",b],t.N,t.z))
return}if((a==="table-cell"||a==="table-th")&&b!=null&&!J.A(b,!1)){o=l.a
if(!(o instanceof A.b8))return
r=t.N
p=t.z
n=t.h.a(A.l([j,A.Aa(t.T.a(o.d))],r,p).h(0,j))
m=A.Y(n==null?B.t:n,r,p)
A.c6(l,a,b)
r=A.aJ(m,p,p)
if(t.G.b(b))r.H(0,b)
A.c6(l,j,r)
return}if(a==="table-list")r=b==null||J.A(b,!1)
else r=!1
if(r){A.bo(l,k,l.fS())
return}l.mV(a,b)},
N(a,b){return this.cS(a,b,!1)},
iS(a){var s,r,q=this.a
if(!(q instanceof A.b8))return
s=A.iT(q)
if(s==null)return
r=A.f4(s).a
if(a)A.bo(q,s.gA(),r)
else A.c6(this,s.gA(),r)},
fS(){var s=this.a
if(s instanceof A.b8){s=A.m(t.T.a(s.d).a.getAttribute("data-cell"))
return s==null?"cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0"):s}s=A.m(t.T.a(this.d).a.getAttribute("data-cell"))
return s==null?"cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0"):s},
G(a,b){var s,r,q,p,o,n=this
t.k.a(a)
t.h.a(b)
s=n.a
if(s!=null&&!(s instanceof A.b8)){r=n.gX()
q=A.m(t.T.a(n.d).a.getAttribute("data-cell"))
if(q==null)q="cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0")
p=t.N
o=t.fR.a(r.z.a5("table-list-container",A.l(["cellId",q],p,p)))
s.D(o,n)
o.D(n,null)}},
aq(){return this.G(null,null)},
a1(){return A.xD(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))}}
A.fE.prototype={
gll(){return!0},
gcE(){return null},
bm(a){t.U.a(a)
return!0},
cr(){var s=this.c
return s!=null&&s.gA()===this.gA()},
G(a,b){var s,r,q,p,o=this
t.k.a(a)
t.h.a(b)
o.ez(a,b)
o.dm()
if(o.a==null)return
if(o.e.length===0){o.Y(0)
return}if(o.gcE()!=null){s=o.gcE()
s.toString
s=A.uD(o,s,o.gcV(),a,b)}else s=!1
if(s)return
r=o.c
s=t.T
q=o.d
while(!0){if(!(r instanceof A.ay&&r.b===o&&A.h(s.a(r.d).a.tagName)===A.h(s.a(q).a.tagName)&&o.cr()))break
r.b2(o,null)
p=r.a
if(p!=null)p.aj(r)
o.ez(a,b)
r=o.c}},
aq(){return this.G(null,null)},
dJ(a){var s,r=this.a1()
for(;s=a.c,s!=null;)r.D(s,null)
s=this.a
if(s!=null)s.D(r,this.c)
return r}}
A.bG.prototype={
gA(){return"table-cell-block"},
gT(){return 5},
a1(){return A.xz(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))},
N(a,b){var s,r,q,p=this
A.h(a)
if(b!=null){s=J.a3(b)
r=!s.n(b,!1)&&!s.n(b,"")}else r=!1
if(a==="table-cell"&&r){A.c6(p,"table-row",null)
A.c6(p,a,b)}else if(a==="table-th"&&r){A.c6(p,"table-th-row",null)
A.c6(p,a,b)}else if(a==="table-container")A.c6(p,a,b)
else if(a==="header")A.bo(p,"table-header",A.l(["cellId",p.P().h(0,p.gA()),"value",b],t.N,t.z))
else if(a==="table-header"&&r){p.uF(p.a)
A.bo(p,a,b)}else{if(a!=="list")s=a==="table-list"&&r
else s=!0
if(s){q=p.P().h(0,p.gA())
s=A.aJ(p.fq(p.a),t.N,t.z)
s.j(0,"cellId",q)
A.c6(p,"table-list-container",s)
A.bo(p,"table-list",b)}else p.dN(a,b)}},
P(){var s=A.Y(this.d5(),t.N,t.z),r=A.m(t.T.a(this.d).a.getAttribute("data-cell"))
if(r!=null)s.j(0,this.gA(),r)
return s},
fq(a){var s,r=A.iT(a)
if(r==null){s=t.N
return A.b(s,s)}return A.f4(r).a},
uF(a){var s,r=A.iT(a)
if(r==null)return
s=A.f4(r)
A.c6(this,r.gA(),s.a)},
G(a,b){var s=this
t.k.a(a)
t.h.a(b)
s.fH(a,b)
if(s.a==null)return
if(!A.I(t.m.a(t.T.a(s.d).a.classList).contains("ql-table-block")))return
A.uD(s,"table-cell",new A.qB(),a,b)},
aq(){return this.G(null,null)}}
A.qB.prototype={
$1(a){return a instanceof A.a6},
$S:3}
A.fJ.prototype={
gA(){return"table-th-block"},
a1(){return A.xH(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))}}
A.a6.prototype={
gA(){return"table-cell"},
gT(){return 5},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.a6(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
gcE(){return"table-row"},
bm(a){return t.U.a(a) instanceof A.ag},
gaO(){return new A.qC()},
cw(a){return this.gX().z.a5(this.gl0(),"cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0"))},
dX(){return this.cw(null)},
gl0(){return"table-cell-block"},
cr(){var s,r,q,p,o,n,m,l,k=this
if(!k.ja())return!1
s=k.c
if(!(s instanceof A.z)||s.e.length===0||k.e.length===0)return!1
r=k.e
q=t.U
p=q.a(B.a.gF(r))
o=A.hk(p.P().h(0,p.gA()))
r=q.a(B.a.gK(r))
n=A.hk(r.P().h(0,r.gA()))
r=s.e
p=q.a(B.a.gF(r))
m=A.hk(p.P().h(0,p.gA()))
r=q.a(B.a.gK(r))
l=A.hk(r.P().h(0,r.gA()))
return o==n&&o==m&&o==l},
P(){return A.l([this.gA(),A.eH(t.T.a(this.d))],t.N,t.z)},
cT(a,b){var s=A.D('<(ol)[^>]*><li[^>]* data-list="bullet">(?:.*?)</li></(ol)>',!1,!1)
return A.iY(A.yr(t.T.a(this.d)),s,t.tj.a(t.pj.a(new A.qD())),null)},
dw(){var s=this.a
s=s instanceof A.ag?s:null
if(s!=null)return s.dw()
return-1},
iL(a){var s,r,q,p,o
for(s=this.e,r=s.length,q=t.T,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
if(o instanceof A.z)q.a(o.d).a.setAttribute("data-cell",a)}},
fm(){var s=this.a
while(!0){if(!(s!=null&&s.gA()!=="table-container"))break
s=s.a}return s instanceof A.b7?s:null},
G(a,b){var s,r,q,p,o,n,m=this
t.k.a(a)
t.h.a(b)
m.jb(a,b)
if(m.a==null)return
for(s=A.a5(m.e,!0,t.U),r=s.length,q=0;q<r;++q){p=s[q]
if(p.a!==m)continue
o=p.c
if(o==null)continue
if(A.hk(p.P().h(0,p.gA()))!=A.hk(o.P().h(0,o.gA()))){m.dJ(p).G(a,b)
n=m.b
if(n!=null)n.G(a,b)}}},
aq(){return this.G(null,null)}}
A.qC.prototype={
$1(a){return a instanceof A.bG||a instanceof A.c_||a instanceof A.b8},
$S:3}
A.qD.prototype={
$1(a){var s=a.eq(0)
s.toString
return B.b.b8(B.b.b8(s,"ol","ul"),"ol","ul")},
$S:18}
A.cF.prototype={
gA(){return"table-th"},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.cF(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
gl0(){return"table-th-block"},
gcE(){return"table-th-row"},
bm(a){return t.U.a(a) instanceof A.bI}}
A.ag.prototype={
gA(){return"table-row"},
gT(){return 5},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.ag(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
gcE(){return"table-body"},
bm(a){return t.U.a(a) instanceof A.bs},
gaO(){return new A.rb()},
eI(a){var s=a.P().h(0,a.gA())
return t.G.b(s)?A.m(s.h(0,"data-row")):null},
cr(){var s,r,q,p,o,n,m=this
if(!m.ja())return!1
s=m.c
if(!(s instanceof A.z)||s.e.length===0||m.e.length===0)return!1
r=m.e
q=m.eI(B.a.gF(r))
p=m.eI(B.a.gK(r))
r=s.e
o=m.eI(B.a.gF(r))
n=m.eI(B.a.gK(r))
return q==p&&q==o&&q==n},
dw(){var s=this.a
if(s!=null)return B.a.ae(s.e,this)
return-1}}
A.rb.prototype={
$1(a){return a instanceof A.a6},
$S:3}
A.bI.prototype={
gA(){return"table-th-row"},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.bI(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
gcE(){return"table-thead"},
bm(a){return t.U.a(a) instanceof A.c0},
gaO(){return new A.rf()}}
A.rf.prototype={
$1(a){return a instanceof A.cF},
$S:3}
A.bs.prototype={
gA(){return"table-body"},
gT(){return 5},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.bs(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
gcE(){return"table-container"},
bm(a){return t.U.a(a) instanceof A.b7},
gaO(){return new A.qA()}}
A.qA.prototype={
$1(a){return a instanceof A.ag},
$S:3}
A.c0.prototype={
gA(){return"table-thead"},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.c0(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
gaO(){return new A.rg()}}
A.rg.prototype={
$1(a){return a instanceof A.bI},
$S:3}
A.cE.prototype={
gA(){return"table-temporary"},
gT(){return 5},
a1(){return A.xF(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))},
P(){return A.l(["table-temporary",A.xG(t.T.a(this.d))],t.N,t.z)},
G(a,b){var s,r,q,p,o,n,m,l=this
t.k.a(a)
t.h.a(b)
s=l.a
if(s instanceof A.b7){r=t.T
q=A.xG(r.a(l.d))
for(p=s.d,o=0;o<4;++o){n=B.bc[o]
m=q.h(0,n)
if(m!=null&&m.length!==0)if(n==="data-class")r.a(p).a.setAttribute("class",A.h(m))
else r.a(p).a.setAttribute(n,A.h(m))
else r.a(p).a.removeAttribute(n)}}l.fH(a,b)
if(l.a==null)return
A.uD(l,"table-container",new A.re(),a,b)},
aq(){return this.G(null,null)}}
A.re.prototype={
$1(a){return a instanceof A.b7},
$S:3}
A.bZ.prototype={
gA(){return"table-col"},
gT(){return 5},
a1(){return A.xB(new A.f(A.b(t.O,t.g),t.m.a(t.T.a(this.d).a.cloneNode(!1))))},
cw(a){return null},
dX(){return this.cw(null)},
P(){return A.l(["table-col",A.A4(t.T.a(this.d))],t.N,t.z)},
cT(a,b){return A.yr(t.T.a(this.d))},
G(a,b){var s,r,q,p=this
t.k.a(a)
t.h.a(b)
p.fH(a,b)
for(s=A.a5(p.e,!0,t.U),r=s.length,q=0;q<r;++q)s[q].Y(0)
if(p.a==null)return
A.uD(p,"table-colgroup",new A.qE(),a,b)},
aq(){return this.G(null,null)}}
A.qE.prototype={
$1(a){return a instanceof A.bH},
$S:3}
A.bH.prototype={
gA(){return"table-colgroup"},
gT(){return 5},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.bH(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
gcE(){return"table-container"},
bm(a){return t.U.a(a) instanceof A.b7},
gaO(){return new A.qF()}}
A.qF.prototype={
$1(a){return a instanceof A.bZ},
$S:3}
A.dt.prototype={}
A.b7.prototype={
gA(){return"table-container"},
gT(){return 5},
gaO(){return new A.qK()},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.b7(A.a([],t.E),new A.f(A.b(t.O,t.g),s))},
eK(a){var s,r,q
A.lm(a,t.U,"T","_firstDescendant")
s=this.a4(a)
r=s.$ti
s=new A.H(s.a(),r.i("H<1>"))
if(s.l()){q=s.b
return q==null?r.c.a(q):q}return null},
dj(){var s=this.eK(t.yk)
return s==null?t.rM.a(this.hJ("table-colgroup")):s},
rm(a,a0,a1,a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b="Blot is not attached to a scroll"
t.t1.a(a)
s=t.u
s.a(a0)
t.R.a(a1)
s.a(a2)
r=c.bJ()
s=c.a4(t.Z)
q=A.N(s,!0,s.$ti.i("o.E"))
if(r==null||r.e.length===0)return
if(a0.length===q.length)a1.$0()
else{for(s=a.length,p=0;p<a.length;a.length===s||(0,A.k)(a),++p){o=a[p]
n=c.gaR()
if(n==null)A.a4(A.aL(b))
m=n.hI(o.a).a
if(m instanceof A.a6)c.iK(m,o.b)}for(s=A.N(a0,!0,t.T),B.a.H(s,a2),l=s.length,k=t.A,j=t.d0,i=t.m,p=0;p<s.length;s.length===l||(0,A.k)(s),++p){h=s[p]
g=null
f=h.a
if(!(k.a(f.parentNode)==null)){f=k.a(f.parentNode)
f.toString
f=A.S(f)
g=f}e=g instanceof A.f?g:null
if(e!=null&&new A.ae(e.gan(),j).gm(0)===1){d=A.ya(e)
if(d!=null)c.mt(d)}n=c.gaR()
if(n==null)A.a4(A.aL(b))
m=n.hI(h).a
if(m!=null)m.Y(0)
else{f=h.a
g=k.a(f.parentNode)
if(g!=null)i.a(g.removeChild(f))}}}},
rn(b3,b4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1=this,b2=null
t.dF.a(b3)
t.R.a(b4)
s=b1.bJ()
if(s==null||s.e.length===0)return
r=b3.length
q=s.e
if(r===q.length){b4.$0()
return}r=t.Z
p=A.b(r,t.kh)
o=A.a([],t.rk)
n=A.a([],t.xC)
m=b1.eo(t.H.a(B.a.gF(q)).e)
for(q=b3.length,l=t.U,k=t.T,j=t.N,i=0;i<b3.length;b3.length===q||(0,A.k)(b3),++i){h=b1.iw(b3[i],m)
if(h==null)continue
for(g=A.a5(h.e,!0,l),f=g.length,e=0;e<f;++e){d=g[e]
if(!(d instanceof A.a6))continue
c=A.m(k.a(d.d).a.getAttribute("rowspan"))
b=A.V(c==null?"":c,b2)
if(b==null)b=0
if(b>1){a=d.gA()
a0=A.f4(d)
a1=d.a
if(a1 instanceof A.ag&&B.a.v(b3,a1)){a2=a1.c
a2=a2 instanceof A.ag?a2:b2
if(p.p(d))p.j(0,d,new A.h7(a2,p.h(0,d).b-1))
else{p.j(0,d,new A.h7(a2,b-1))
B.a.k(n,d)}}else{c=A.cR(j,j)
c.H(0,a0.a)
c.j(0,"rowspan",""+(b-1))
A.bo(d,a,c)}}}}for(q=n.length,i=0;i<n.length;n.length===q||(0,A.k)(n),++i){a3=n[i]
a4=A.f4(a3)
a5=A.bw(k.a(a3.d))
a6=p.h(0,a3)
l=a6.a
j=a5.c
g=a5.e
b1.kq(l,o,a4.a,j,a3,a6.b,g)}for(q=o.length,i=0;i<o.length;o.length===q||(0,A.k)(o),++i){a6=o[i]
a7=b1.gaR()
if(a7==null)A.a4(A.aL("Blot is not attached to a scroll"))
a8=a7.z.a.h(0,"table-cell")
if(a8==null)A.a4(A.au('Unknown blot "table-cell"',b2))
a9=r.a(a8.c.$1(a6.b))
l=a6.d
l.b2(a9,b2)
a9.iL("cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0"))
a6.a.D(a9,a6.c)
k=l.a
if(k!=null)k.aj(l)}for(r=b3.length,i=0;i<b3.length;b3.length===r||(0,A.k)(b3),++i){b0=b3[i]
q=b0.a
if(q!=null)q.aj(b0)}},
hJ(a){var s,r,q,p
for(s=this.e,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q]
if(p.gA()===a)return p}return null},
m5(){var s=A.yr(t.T.a(this.d)),r=A.D("<temporary[^>]*>(.*?)</temporary>",!1,!1)
return A.iY(A.O(s,r,""),A.D("<td[^>]*>(.*?)</td>",!1,!1),t.tj.a(t.pj.a(new A.qO())),null)},
iw(a,b){while(!0){if(!(a!=null))break
if(b===this.eo(a.e))return a
a=a.b
a=a instanceof A.ag?a:null}return a},
ma(a5,a6,a7,a8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=this,a1=null,a2=a0.bJ(),a3=a0.dA(),a4=a2!=null
if(!a4||a2.e.length===0)s=a3==null||a3.e.length===0
else s=!1
if(s)return a1
r="row-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0")
q=a8?"table-th-row":"table-row"
s=t.H
p=s.a(a0.gX().z.a5(q,a1))
if(a4&&a2.e.length!==0)o=a2
else{a3.toString
o=a3}n=a0.eo(s.a(B.a.gF(o.e)).e)
a4=a5.e
if(a0.eo(a4)===n){for(a4=A.a5(a4,!0,t.U),s=a4.length,m=t.N,l=t.T,k=0;k<s;++k){j=a4[k]
if(!(j instanceof A.a6))continue
i=A.l(["height","24","data-row",r],m,m)
h=A.m(l.a(j.d).a.getAttribute("colspan"))
g=A.V(h==null?"":h,a1)
if(g==null)g=0
a0.hX(g===0?1:g,i,p,a8)}return p}else{a4=a5.b
f=a0.iw(a4 instanceof A.ag?a4:a1,n)
if(f==null)return p
for(a4=A.a5(f.e,!0,t.U),s=a4.length,m=t.T,l=t.N,h=a7>0,e=a6==null,k=0;k<s;++k){j=a4[k]
if(!(j instanceof A.a6))continue
i=A.l(["height","24","data-row",r],l,l)
d=m.a(j.d).a
c=A.m(d.getAttribute("colspan"))
g=A.V(c==null?"":c,a1)
if(g==null)g=0
d=A.m(d.getAttribute("rowspan"))
b=A.V(d==null?"":d,a1)
if(b==null)b=0
if(b>1)if(h&&e)a0.hX(g===0?1:g,i,p,a8)
else{a=A.f4(j)
d=j.gA()
c=A.cR(l,l)
c.H(0,a.a)
c.j(0,"rowspan",""+(b+1))
A.bo(j,d,c)}else a0.hX(g===0?1:g,i,p,a8)}return p}},
eo(a){return B.a.ag(t.rD.a(a),0,new A.qP(),t.S)},
tf(a3,a4,a5,a6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this,a=null,a0=b.dj(),a1=b.bJ(),a2=b.dA()
if(a1==null||a1.e.length===0)s=a2==null||a2.e.length===0
else s=!1
if(s)return
r=A.a([],t.rk)
q=A.a([],t.un)
s=b.a4(t.H)
p=A.N(s,!0,s.$ti.i("o.E"))
for(s=p.length,o=a6>0,n=t.T,m=0;m<s;++m){l=p[m]
if(a4&&o){k=B.a.gK(l.e)
if(k instanceof A.z){j=A.m(n.a(k.d).a.getAttribute("data-row"))
i=j==null?"":j}else i=""
B.a.k(r,new A.dt(l,i,a,a))}else b.qm(l,r,a3,a5)}if(a0!=null)if(a4)B.a.k(q,new A.ao(a0,a))
else{s=a0.e
h=s.length!==0?B.a.gF(s):a
for(s=t.hi,g=0;h!=null;g=e){s.a(h)
f=A.bw(n.a(h.d))
g=g!==0?g:f.a
e=g+f.e
if(Math.abs(g-a3)<=2){B.a.k(q,new A.ao(a0,h))
break}else if(Math.abs(e-a3)<=2&&h.c==null){B.a.k(q,new A.ao(a0,a))
break}h=h.c}}for(s=r.length,m=0;m<r.length;r.length===s||(0,A.k)(r),++m){d=r[m]
o=d.a
n=d.c
if(o==null){n.toString
b.iK(n,1)}else b.fb(o,A.p(d.b),n)}for(s=q.length,o=t.N,m=0;m<q.length;q.length===s||(0,A.k)(q),++m){n=q[m]
c=b.gaR()
if(c==null)A.a4(A.aL("Blot is not attached to a scroll"))
j=A.l(["width","72"],o,o)
d=c.z.a.h(0,"table-col")
if(d==null)A.a4(A.au('Unknown blot "table-col"',a))
n.a.D(d.c.$1(j),n.b)}},
fb(a,b,c){var s,r,q,p,o,n,m,l,k=this
if(a==null){s=k.bJ()
a=t.H.a(k.gX().z.a5("table-row",null))
if(s!=null)s.D(a,null)}r=t.N
q=k.dj()!=null?A.l(["data-row",b],r,r):A.l(["data-row",b,"width","72"],r,r)
p=a.gA()==="table-row"
o=p?"table-cell":"table-th"
n=p?"table-cell-block":"table-th-block"
m=t.Z.a(k.gX().z.a5(o,q))
l=t.hB.a(k.gX().z.a5(n,"cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0")))
m.D(l,null)
a.D(m,c)
l.aq()
return m},
hW(a,b,c){var s,r,q,p,o,n,m=this,l=m.bJ(),k=m.dA()
if(l==null||l.e.length===0)s=k==null||k.e.length===0
else s=!1
if(s)return
r=c?k:l
if(r==null)return
q=c?m.fU(k,a):m.fU(l,a)
p=q instanceof A.ag?q:null
o=p==null?m.fU(l,a-1):p
if(!(o instanceof A.ag))return
n=m.ma(o,p,b,c)
if(n!=null)r.D(n,p)},
tm(a,b){return this.hW(a,b,!1)},
hX(a,b,c,d){var s,r,q,p
t.J.a(b)
if(a>1)b.j(0,"colspan",""+a)
else b.Z(0,"colspan")
s=d?"table-th":"table-cell"
r=d?"table-th-block":"table-cell-block"
q=t.Z.a(this.gX().z.a5(s,b))
p=t.hB.a(this.gX().z.a5(r,"cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0")))
q.D(p,null)
c.D(q,null)
p.aq()},
i_(){var s=t.T.a(this.d),r=A.m(s.a.getAttribute("width"))
if(r==null)r=A.d1(s).h(0,"width")
if(r==null||r.length===0)return!1
return J.CM(r,"%")},
G(a,b){var s,r,q,p,o,n=this
n.jb(t.k.a(a),t.h.a(b))
if(n.a==null)return
s=n.a4(t.qk)
r=A.N(s,!0,s.$ti.i("o.E"))
n.ql(r)
if(r.length>1)for(s=A.dg(r,1,null,A.K(r).c),q=s.$ti,s=new A.be(s,s.gm(0),q.i("be<ad.E>")),q=q.i("ad.E");s.l();){p=s.d
if(p==null)p=q.a(p)
o=p.a
if(o!=null)o.aj(p)}},
aq(){return this.G(null,null)},
iK(a,b){var s="colspan",r=a.gA(),q=t.N,p=A.Y(t.J.a(a.P().h(0,r)),q,q),o=A.Br(p.h(0,s)),n=(o===0?1:o)+b
if(n>1)p.j(0,s,""+n)
else p.Z(0,s)
A.bo(a,r,p)},
mt(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c="rowspan"
for(;a!=null;){s=a.a_("td[rowspan]")
r=s.length
if(r!==0){for(q=t.T,p=t.N,o=t.z,n=t.J,m=0;m<s.length;s.length===r||(0,A.k)(s),++m){l=s[m]
k=this.gaR()
if(k==null)A.a4(A.aL("Blot is not attached to a scroll"))
j=k.hI(l).a
if(!(j instanceof A.a6))continue
i=j.gA()
h=A.Y(n.a(A.l([j.gA(),A.eH(q.a(j.d))],p,o).h(0,i)),p,p)
g=h.h(0,c)
f=A.V(g==null?"":g,null)
if(f==null)f=0
e=(f===0?1:f)-1
d=A.BI(j)
if(e>1)h.j(0,c,""+e)
else h.Z(0,c)
if(d!=null)d.N(i,h)}break}a=A.ya(a)}},
ql(a){var s,r,q,p,o,n,m,l
t.al.a(a)
s=a.length!==0?B.a.gF(a):null
r=A.m(t.T.a(this.d).a.getAttribute("class"))
q=new A.qI(this,new A.qG())
if(s==null){p=this.b
if(!(p instanceof A.z))return
o=p.a4(t.Z)
n=o.$ti
o=new A.H(o.a(),n.i("H<1>"))
$loop$0:{if(o.l()){o=o.b
m=o==null?n.c.a(o):o
break $loop$0}else m=null}o=p.a4(t.qk)
n=o.$ti
o=new A.H(o.a(),n.i("H<1>"))
$loop$1:{if(o.l()){o=o.b
l=o==null?n.c.a(o):o
break $loop$1}else l=null}if(m==null&&l!=null)q.$2(l,r)}else q.$2(s,r)},
kq(a,b,c,d,e,f,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g=null
t.bf.a(b)
t.km.a(c)
if(a==null)return
s=a.e
r=s.length!==0?B.a.gF(s):g
for(s=c==null,q=!s,p=t.T,o=f!=null;r!=null;){n=r instanceof A.a6?r:g
if(n==null){r=r.c
continue}m=p.a(n.d)
l=A.bw(m)
k=l.a
j=l.c
i=A.m(m.a.getAttribute("data-row"))
if(i==null)i=""
if(q){if(o)c.j(0,"rowspan",A.p(f))
c.j(0,"data-row",i)}h=s?i:c
m=k-d
if(Math.abs(m)<=2){B.a.k(b,new A.dt(a,h,n,e))
break}else if(Math.abs(j-d)<=2&&n.c==null){B.a.k(b,new A.dt(a,h,g,e))
break}else if(Math.abs(m-a0)<=2){B.a.k(b,new A.dt(a,h,n,e))
break}else if(d>k&&d<j){B.a.k(b,new A.dt(g,h,n,e))
break}r=r.c}},
qm(a,b,c,d){return this.kq(a,b,null,c,null,null,d)},
bJ(){var s,r,q
for(s=this.a4(t.qj),r=s.$ti,s=new A.H(s.a(),r.i("H<1>")),r=r.c;s.l();){q=s.b
if(q==null)q=r.a(q)
if(!(q instanceof A.c0))return q}return t.rb.a(this.hJ("table-body"))},
dA(){var s=this.eK(t.Bx)
return s==null?t.rd.a(this.hJ("table-thead")):s},
fU(a,b){var s
if(a==null||b<0||b>=a.e.length)return null
s=a.e
if(!(b>=0&&b<s.length))return A.d(s,b)
return s[b]}}
A.qK.prototype={
$1(a){return a instanceof A.bs||a instanceof A.c0||a instanceof A.cE||a instanceof A.bH},
$S:3}
A.qO.prototype={
$1(a){var s=a.eq(0)
s.toString
return A.Io(s)},
$S:18}
A.qP.prototype={
$2(a,b){var s
A.v(a)
t.U.a(b)
if(!(b instanceof A.z))return a
s=A.Br(A.m(t.T.a(b.d).a.getAttribute("colspan")))
return a+(s===0?1:s)},
$S:53}
A.qG.prototype={
$1(a){var s="ql-table-better",r=B.b.aN(a,A.D("\\s+",!0,!1)),q=A.K(r),p=q.i("an<1>"),o=A.N(new A.an(r,q.i("x(1)").a(new A.qH()),p),!0,p.i("o.E"))
if(!B.a.v(o,s))B.a.V(o,0,s)
return B.b.R(B.a.ab(o," "))},
$S:6}
A.qH.prototype={
$1(a){return A.h(a).length!==0},
$S:8}
A.qI.prototype={
$2(a,b){var s,r=t.T.a(a.d).a,q=A.m(r.getAttribute("data-class")),p=b!=q&&b!=null
if(p)r.setAttribute("data-class",A.h(this.b.$1(b)))
if(b==null||b.length===0)s=q==null||q.length===0
else s=!1
if(s){r.setAttribute("data-class","ql-table-better")
p=!0}if(p)++this.a.gX().as},
$S:170}
A.jY.prototype={}
A.o8.prototype={
gkW(){var s=this.a
s===$&&A.c()
return s},
fn(a){var s=this.gkW(),r=this.b
r===$&&A.c()
r=s.h(0,r)
s=r==null?null:r.h(0,a)
return s==null?"":s},
sjk(a){this.a=t.Bg.a(a)}}
A.fG.prototype={
mi(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g,f="table-cell-block",e="table-th-block"
t.h.a(a)
s=this.hw(a,b,c)
if(A.Bt(a.h(0,f))||A.Bt(a.h(0,e))){r=t.t
q=new A.r(A.a([],r))
for(p=s.a,o=p.length,n=t.N,m=t.z,l=0;l<p.length;p.length===o||(0,A.k)(p),++l){k=p[l]
j=k.d
if(j==null)i=null
else{j=A.Y(j,n,m)
i=j}if(i==null)i=B.l
j=i.h(0,"table-temporary")
if(j!=null){h=J.a3(j)
j=!h.n(j,!1)&&!h.n(j,"")&&!h.n(j,0)}else j=!1
if(j)return new A.r(A.a([],r))
j=i.h(0,"header")
if(j!=null){h=J.a3(j)
j=!h.n(j,!1)&&!h.n(j,"")&&!h.n(j,0)}else j=!1
g=!0
if(!j){j=i.h(0,"list")
if(j!=null){h=J.a3(j)
j=!h.n(j,!1)&&!h.n(j,"")&&!h.n(j,0)}else j=!1
if(!j){j=i.h(0,f)
if(j!=null){h=J.a3(j)
j=!h.n(j,!1)&&!h.n(j,"")&&!h.n(j,0)}else j=!1
if(j){j=i.h(0,e)
if(j!=null){h=J.a3(j)
j=!h.n(j,!1)&&!h.n(j,"")&&!h.n(j,0)}else j=!1
j=!j}else j=g
g=j}}if(g){j=A.cR(n,m)
j.H(0,i)
j.H(0,a)}else j=i
q.V(0,k.c,j)}return q}return s},
lq(a,b,c){var s,r,q,p,o,n
if(b!=null&&b.length!==0){s=this.a.w
s===$&&A.c()
r=s.c.h(0,"table-better")
if(r!=null&&A.I(r.i6(b)))return}s=this.a
q=a.a
p=s.f
p===$&&A.c()
o=this.mi(p.aW(q,0),b,c)
p=new A.r(A.a([],t.t))
p.a8(q)
q=a.b
p.aY(q)
n=p.bj(o)
s.aM(n,"user")
s.S(new A.G(A.FZ(n)-q,0),"silent")
s.b5()}}
A.uv.prototype={
$2(a,b){var s
A.v(a)
s=t.Q.a(b).b
return a+(s==null?0:s)},
$S:24}
A.rh.prototype={
tu(){var s,r,q,p,o,n=this.a.w
n===$&&A.c()
s=n.c.h(0,"toolbar")
if(!(s instanceof A.i3))return
for(n=B.bB.gJ(B.bB),r=this.d,q=s.e,p=t.V;n.l();){o=n.gq()
r.j(0,o,q.h(0,o))
q.j(0,o,p.a(new A.rj(this,o)))}},
rH(a,b){var s,r=this,q=r.b.$0()
if(q==null||A.cc(q.c,t.Z).length===0){s=r.d.h(0,a)
if(s!=null)s.$1(b)
else r.a.aD(a,b,"user")
return}if(a==="list"){r.lD(a,r.tG(b,q),q)
return}r.lD(a,b,q)},
tG(a,b){var s,r,q,p,o="unchecked"
if(!J.A(a,"check"))return a
if(A.cc(b.c,t.Z).length!==1)return o
s=this.a
r=s.aX()
if(r==null)return o
q=r.a
s=s.f
s===$&&A.c()
p=s.aW(q,0).h(0,"list")
s=J.a3(p)
return s.n(p,"checked")||s.n(p,o)?!1:o},
lD(a,b,c){var s,r,q,p=this.a,o=p.aX(),n=A.cc(c.c,t.Z),m=A.a([],t.dV)
if(o!=null&&o.b===0&&n.length===1){s=o.a
p=p.c
p===$&&A.c()
r=p.ap(s).a
if(r instanceof A.a0)B.a.k(m,r)}if(m.length===0)for(p=n.length,q=0;q<p;++q)B.a.H(m,this.tF(n[q]))
this.mB(o,n,b,a,m)},
mB(a,b,c,d,e){var s,r,q,p,o,n=this
t.x7.a(b)
t.ex.a(e)
s=n.tA(a,b,e)
for(r=e.length,q=0;q<e.length;e.length===r||(0,A.k)(e),++q){p=e[q]
n.rG(p,d,c,n.t2(b,d,p,s))}r=n.a
o=r.c
o===$&&A.c()
o.G(A.a([],t.B),A.l(["source","user"],t.N,t.z))
if(b.length<2&&a!=null)r.S(a,"silent")
n.c.$0()},
tA(a,b,c){var s
t.x7.a(b)
t.ex.a(c)
s=b.length
if(s>1)return!0
if(s!==1)return!1
s=t.S
return B.a.ag(this.qW(B.a.gF(b)),0,new A.rk(),s)===B.a.ag(c,0,new A.rl(),s)},
t2(a,b,c,d){if(t.x7.a(a).length===1&&b==="list"&&c instanceof A.c_)return!0
return d},
qW(a){var s=A.a([],t.hF)
new A.ri(s).$1(a)
return s},
tF(a){var s=A.a([],t.dV)
new A.rm(s).$1(a)
return s},
rG(a,b,c,d){if(a instanceof A.c_){a.cS(b,c,d)
return}if(a instanceof A.cW){a.cS(b,c,d)
return}a.N(b,c)}}
A.rj.prototype={
$1(a){return this.a.rH(this.b,a)},
$S:5}
A.rk.prototype={
$2(a,b){return A.v(a)+t.tu.a(b).E(0)},
$S:171}
A.rl.prototype={
$2(a,b){return A.v(a)+t.uO.a(b).E(0)},
$S:172}
A.ri.prototype={
$1(a){var s,r,q,p,o
for(s=a.e,r=s.length,q=this.a,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
if(o instanceof A.hy){B.a.k(q,o)
this.$1(o)}}},
$S:66}
A.rm.prototype={
$1(a){var s,r,q,p,o
for(s=a.e,r=s.length,q=this.a,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
if(o instanceof A.b8)this.$1(o)
else if(o instanceof A.bG||o instanceof A.c_||o instanceof A.cW)if(o instanceof A.a0)B.a.k(q,o)}},
$S:66}
A.wy.prototype={
$2(a,b){t.l.a(a)
return A.Ex(a,b instanceof A.bp?b:B.c7)},
$S:174}
A.wz.prototype={
$2(a,b){return A.Et(t.l.a(a),A.Eu(b))},
$S:175}
A.eG.prototype={}
A.q3.prototype={
$1(a){return A.p(a)},
$S:34}
A.q4.prototype={
$1(a){return A.p(a)},
$S:34}
A.fF.prototype={}
A.eF.prototype={
nn(a,b){var s,r,q,p,o,n,m,l=this,k="mousedown"
l.q7()
s=new A.rh(a,new A.qb(l),new A.qc(l),A.b(t.N,t.wg))
l.d!==$&&A.ai()
l.d=s
r=l.gt4()
q=new A.dk(a,l.c,l.gqj(),r,b.b,A.a([],t.zP))
p=t.O
q.snA(p.a(q.ghL()))
o=a.b
o===$&&A.c()
n=q.x
n===$&&A.c()
o.I("click",n)
n=q.ra()
q.w!==$&&A.ai()
q.w=n
l.e!==$&&A.ai()
l.e=q
s.tu()
s=new A.ka(a,l.gqz(),new A.qd(l))
s.sny(p.a(s.grZ()))
n=s.d
n===$&&A.c()
o.I("mousemove",n)
l.r!==$&&A.ai()
l.r=s
s=l.gqB()
n=t.r
m=A.a([],n)
n=A.a([],n)
s=new A.je(a,o,new A.en(B.G),new A.mf(r,l.gmC(),q.gus(),q.grt(),q.guB(),q.ghy(),q.ghz(),s,b.c),m,n)
s.snt(p.a(s.ghL()))
r=p.a(s.ghP())
s.f!==$&&A.ai()
s.snv(r)
p=p.a(s.gpw())
s.r!==$&&A.ai()
s.snu(p)
p=s.e
p===$&&A.c()
o.I("click",p)
p=s.f
p===$&&A.c()
o.I(k,p)
p=s.r
p===$&&A.c()
o.I("keyup",p)
s.te()
l.w!==$&&A.ai()
l.w=s
l.u8(b.d)
l.tH()
o.I("keyup",new A.qe(l))
o.I(k,l.ghP())
o.I("scroll",new A.qf(l))
a.d.av("text-change",new A.qg(l))
l.ku()},
qk(a){var s,r=this.eS(a)
if(r==null)return null
s=this.w
s===$&&A.c()
s.c.ei(r)
return s.c},
eS(a){var s,r,q,p=this.a.c
p===$&&A.c()
p=p.a4(t.ll)
s=p.$ti
p=new A.H(p.a(),s.i("H<1>"))
r=t.T
s=s.c
for(;p.l();){q=p.b
if(q==null)q=s.a(q)
if(r.a(q.d).n(0,a))return q}return null},
q7(){var s,r,q,p,o,n,m,l,k,j=this,i=null
for(s=t.s,r=t.N,q=t.K,p=j.a,o=0;o<2;++o){n=B.eR[o]
m=p.x
m===$&&A.c()
l=n?"ArrowUp":"ArrowDown"
m.bh(new A.av(l,i,!1,!1,!1,!1,i,i,i,i,i,i,i),A.l(["collapsed",!0,"format",A.a(["table-cell","table-th"],s)],r,q),new A.q5())}for(o=0;o<2;++o){k=B.cY[o]
m=p.x
m===$&&A.c()
m.bh(new A.av(k,i,!1,!1,!1,!1,i,i,i,i,i,i,i),A.l(["collapsed",!0,"format",A.a(["table-cell-block","table-th-block"],s)],r,q),new A.q6(j,k))
m.bh(new A.av(k,i,!1,!1,!1,!1,i,i,i,i,i,i,i),A.l(["collapsed",!0,"empty",!0,"format",A.a(["table-header"],s)],r,q),new A.q7(j))
m.bh(new A.av(k,i,!1,!1,!1,!1,i,i,i,i,i,i,i),A.l(["collapsed",!0,"empty",!0,"format",A.a(["table-list"],s)],r,q),new A.q8(j))}p=p.x
p===$&&A.c()
p.bh(new A.av("Enter",i,!1,!1,!1,!1,i,i,i,i,i,i,i),A.l(["collapsed",!0,"suffix",A.D("^$",!0,!1),"format",A.a(["table-header"],s)],r,q),new A.q9(j))
p.bh(new A.av("Enter",i,!1,!1,!1,!1,i,i,i,i,i,i,i),A.l(["collapsed",!0,"empty",!0,"format",A.a(["table-list"],s)],r,q),new A.qa(j))},
oP(a,b){var s=b.w
if(s.b!=null){s.Y(0)
s=a.a
this.a.S(new A.G(B.f.aA(B.d.aC(s-1,0,s)),0),"silent")
return!1}this.hm(s)
return!1},
hm(a){var s=a.a,r=s instanceof A.b8?A.m(t.T.a(s.d).a.getAttribute("data-cell")):null
if(r==null)r=A.m(t.T.a(a.d).a.getAttribute("data-cell"))
A.bo(a,"table-cell-block",r==null?"cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0"):r)
return!1},
oB(a,b,c){var s,r,q=c.w,p=c.c===0
if(p&&q.b==null)return!1
s=q.b
if(p)r=s instanceof A.bG||s instanceof A.b8||s instanceof A.c_
else r=!1
if(r){q.Y(0)
p=b.a
this.a.S(new A.G(B.f.aA(B.d.aC(p-1,0,p)),0),"silent")
return!1}if(!p&&c.e.length===0&&a==="Delete")return!1
return!0},
gkH(){var s,r=this.cG().a
if(r==null)return null
s=this.w
s===$&&A.c()
s.c.ei(r)
return s.c},
gqB(){var s,r=this.a.w
r===$&&A.c()
s=r.c.h(0,"toolbar")
if(s==null)return null
return t.q.a(s.gct())},
cG(){var s,r,q,p,o,n=null,m=this.a,l=m.aX()
if(l==null)return B.mN
s=l.a
m=m.c
m===$&&A.c()
r=m.ap(s).a
if(r==null||!B.jT.v(0,r.gA()))return new A.fF(n,n)
q=r.a
while(!0){m=q==null
if(!(!m&&!(q instanceof A.a6)))break
q=q.a}p=m?n:q.a
if(p==null)o=n
else{m=p.a
o=m==null?n:m.a}if(q instanceof A.a6&&p instanceof A.ag&&o instanceof A.b7)return new A.fF(o,q)
return new A.fF(n,n)},
c7(a,b){var s,r,q,p,o,n,m,l,k,j,i,h="table-cell-block",g=this.a,f=g.d1(!0)
if(f==null)return
s=f.a
r=g.f
r===$&&A.c()
if(r.aW(s,0).p(h))return
q=s>0
p=q?r.aW(s-1,0):B.t
r=g.c
r===$&&A.c()
r=r.ap(s)
o=p.p(h)||r.b!==0
n=o?2:1
m=new A.r(A.a([],t.t))
if(q)m.a8(s)
r=f.b
if(r>0)m.aY(r)
if(o)m.aE(0,"\n")
r=t.N
q=t.z
m.V(0,"\n",A.l(["table-temporary",A.l(["style","width: 100%"],r,r)],r,q))
for(l=0;l<a;++l){k=$.b0()
j="row-"+B.b.ai(B.d.ac(k.am(1679616),36),4,"0")
for(i=0;i<b;++i)m.V(0,"\n",A.l([h,"cell-"+B.b.ai(B.d.ac(k.am(1679616),36),4,"0"),"table-cell",A.l(["data-row",j],r,r)],r,q))}g.aM(m,"user")
g.S(new A.G(s+n,0),"silent")
this.iX()},
u8(a){var s,r,q,p,o,n,m,l,k,j,i=this,h=null,g="table-better",f={}
if(!a)return
A.hV("formats/table-better",new A.X(g,3,A.C1(),B.F,B.i,h,h,h,!1),!0)
s=i.a
r=s.c
r===$&&A.c()
r.z.ia(new A.X(g,3,A.C1(),B.F,B.i,h,h,h,!1))
r=$.hn()
if(r.h(0,g)==null)r.j(0,g,u.W)
r=s.w
r===$&&A.c()
q=r.c.h(0,"toolbar")
if(q==null)return
p=t.q.a(q.gct())
if(p==null)return
f.a=null
for(r=p.a_("button"),o=r.length,n=t.m,m=0;m<r.length;r.length===o||(0,A.k)(r),++m){l=r[m]
if(A.I(n.a(l.a.classList).contains("ql-table-better"))){f.a=l
break}}if(f.a==null)return
k=$.hn().h(0,g)
if(typeof k=="string"){r=f.a.gaf()
r=!B.b.v(r==null?"":r,"<svg")}else r=!1
if(r)f.a.saf(k)
s=s.b
s===$&&A.c()
s=s.a
r=t.A
o=r.a(s.ownerDocument)
o.toString
j=A.a([],t.r)
o=new A.rc(new A.bu(o),B.ai,j)
j=o.r7()
o.b!==$&&A.ai()
o.b=j
i.f=o
n.a(f.a.a.appendChild(j.a))
f.a.I("click",new A.qm(i))
s=r.a(s.ownerDocument)
s.toString
new A.bu(s).I("click",new A.qn(f,i))},
jU(a,b){var s,r,q
for(s=t.A,r=a;r!=null;){if(r.n(0,b))return!0
q=r.a
if(s.a(q.parentNode)==null)r=null
else{q=s.a(q.parentNode)
q.toString
r=A.S(q)}}return!1},
iY(a){var s,r,q,p=this.cG(),o=p.a,n=p.c
if(o==null||n==null)return
t.ll.a(o)
s=this.w
s===$&&A.c()
r=s.c
r.ei(o)
s.fD(!0)
r=r.c.length
if(r===0)s.fF(t.T.a(n.d),!1)
s=this.e
s===$&&A.c()
r=t.T.a(o.d)
s.y=r
q=s.w
q===$&&A.c()
t.m.a(q.a.classList).remove("ql-hidden")
s.em(r)},
iX(){return this.iY(!1)},
qV(){var s,r,q,p,o,n=this.cG().a
if(n==null)return
for(s=t.T.a(n.d).a_("td"),r=s.length,q=t.m,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p].a
q.a(o.classList).remove("ql-cell-focused")
q.a(o.classList).remove("ql-cell-selected")}},
hN(a){var s=this,r=s.a.c
r===$&&A.c()
if(A.m(t.T.a(r.d).a.getAttribute("contenteditable"))!=="true")return
r=a.a
if(A.I(r.ctrlKey))r=A.h(r.key)==="z"||A.h(r.key)==="y"
else r=!1
if(r){s.dq()
s.qV()}s.qE(a)},
qE(a){var s=this.gkH()
s=s==null?null:s.gbc().length===0
if(s!==!1)return
s=a.a
if(A.h(s.key)!=="Enter")s=A.I(s.ctrlKey)&&A.h(s.key)==="v"
else s=!0
if(s){s=this.e
s===$&&A.c()
s.bz()}},
hQ(a){var s,r,q,p,o=this
t.f.a(a)
s=o.a
r=s.c
r===$&&A.c()
if(A.m(t.T.a(r.d).a.getAttribute("contenteditable"))!=="true")return
r=o.f
if(r!=null)r.bF()
q=o.kw(a.gau())
r=q==null
if(!r){s=s.b
s===$&&A.c()
s=!o.jU(q,s)}else s=!1
if(s){o.dq()
return}if(r){o.dq()
o.t_()
return}p=o.eS(q)
if(p!=null){s=o.w
s===$&&A.c()
s.c.ei(p)
s.fD(!0)}},
t_(){var s,r,q={}
q.a=null
s=A.l_()
r=A.l_()
s.sl8(new A.qh(q,this))
r.sl8(new A.qi(q,this,s,r))
q=this.a.b
q===$&&A.c()
q.I("mousemove",s.bP())
q.I("mouseup",r.bP())},
t0(){var s=this.a.c
s===$&&A.c()
if(A.m(t.T.a(s.d).a.getAttribute("contenteditable"))!=="true")return
this.dq()
s=this.e
s===$&&A.c()
s.at=!0},
kw(a){var s,r,q
for(s=t.A,r=a;r!=null;){if(r instanceof A.f&&A.h(r.a.tagName).toUpperCase()==="TABLE")return r
q=r.a
if(s.a(q.parentNode)==null)r=null
else{q=s.a(q.parentNode)
q.toString
r=A.S(q)}}return null},
i6(a){var s=this.w
s===$&&A.c()
if(s.c.gbc().length===0)return!1
return s.u_(a)},
dq(){var s,r=this.w
r===$&&A.c()
r.M(0)
r.fD(!1)
r=this.r
r===$&&A.c()
r.f9()
r.lg()
r.fa()
r=this.e
r===$&&A.c()
s=r.w
s===$&&A.c()
t.m.a(s.a.classList).add("ql-hidden")
r.hC()},
tH(){this.a.d.av("text-change",new A.qk(this))},
ku(){var s,r,q=this.w
q===$&&A.c()
if(q.c.a==null)return
s=this.a.c
s===$&&A.c()
s=s.a4(t.ll)
r=A.xl(s,s.$ti.i("o.E"))
s=q.c.a
s.toString
if(!r.v(0,s))q.M(0)}}
A.qb.prototype={
$0(){return this.a.gkH()},
$S:180}
A.qc.prototype={
$0(){var s=this.a.e
s===$&&A.c()
return s.bz()},
$S:1}
A.qd.prototype={
$1(a){var s=this.a.e
s===$&&A.c()
return s.em(a)},
$S:30}
A.qe.prototype={
$1(a){t.f.a(a)
if(a instanceof A.cv)this.a.hN(a)},
$S:0}
A.qf.prototype={
$1(a){t.f.a(a)
return this.a.t0()},
$S:0}
A.qg.prototype={
$3(a,b,c){if(J.A(c,"silent"))return
this.a.ku()},
$C:"$3",
$R:3,
$S:15}
A.q5.prototype={
$2(a,b){t.F.a(a)
t.i.a(b)
return!1},
$S:12}
A.q6.prototype={
$2(a,b){return this.a.oB(this.b,t.F.a(a),t.i.a(b))},
$S:12}
A.q7.prototype={
$2(a,b){this.a.oP(t.F.a(a),t.i.a(b))
return!1},
$S:12}
A.q8.prototype={
$2(a,b){t.F.a(a)
this.a.hm(t.i.a(b).w)
return!1},
$S:12}
A.q9.prototype={
$2(a,b){var s,r,q
t.F.a(a)
t.i.a(b)
s=new A.r(A.a([],t.t))
r=a.a
s.a8(r)
s.V(0,"\n",b.f)
s.a8(Math.max(0,b.w.E(0)-b.c-1))
s.br(1,A.l(["header",null],t.N,t.z))
q=this.a.a
q.aM(s,"user")
q.S(new A.G(r+1,0),"silent")
q.b5()
return!1},
$S:12}
A.qa.prototype={
$2(a,b){t.F.a(a)
this.a.hm(t.i.a(b).w)
return!1},
$S:12}
A.qm.prototype={
$1(a){var s,r
t.f.a(a)
s=this.a
r=s.f
r.toString
r.rK(a.gau(),s.gts())},
$S:0}
A.qn.prototype={
$1(a){var s,r,q,p
t.f.a(a)
s=this.b
r=s.f
if(r!=null){q=r.b
q===$&&A.c()
q=A.I(t.m.a(q.a.classList).contains("ql-hidden"))}else q=!0
if(q)return
q=a.gau()
p=this.a.a
p.toString
if(s.jU(q,p))return
r.bF()},
$S:0}
A.qh.prototype={
$1(a){var s
t.f.a(a)
s=this.a
if(s.a==null)s.a=this.b.kw(a.gau())},
$S:0}
A.qi.prototype={
$1(a){var s,r,q,p,o,n,m,l,k=this
t.f.a(a)
s=k.a.a
if(s!=null){r=k.b
q=r.eS(s)
r=r.a
p=r.aX()
if(q!=null&&p!=null){o=r.c
o===$&&A.c()
n=o.aP(q)
m=q.E(0)
o=p.a
l=Math.min(o,n)
r.S(new A.G(l,Math.max(o+p.b,n+m)-l),"user")}}r=k.b.a.b
r===$&&A.c()
r.ca("mousemove",k.c.bP())
r.ca("mouseup",k.d.bP())},
$S:0}
A.qk.prototype={
$3(a,b,c){var s,r,q,p,o,n,m,l
if(!J.A(c,"user"))return
s=this.a
r=s.a.c
r===$&&A.c()
q=r.a4(t.ll)
p=A.N(q,!1,q.$ti.i("o.E"))
if(p.length===0)return
q=A.K(p)
o=q.i("an<1>")
n=A.N(new A.an(p,q.i("x(1)").a(new A.qj()),o),!1,o.i("o.E"))
q=n.length
if(q===0)return
for(m=0;m<q;++m){l=n[m]
o=l.a
if(o!=null)o.aj(l)}s.dq()
r.G(A.a([],t.B),A.b(t.N,t.z))},
$C:"$3",
$R:3,
$S:15}
A.qj.prototype={
$1(a){t.ll.a(a)
return a.bJ()==null&&a.dA()==null},
$S:181}
A.m9.prototype={}
A.mg.prototype={
B(a){var s=this
return""+s.a+":"+s.b+"-"+s.c+":"+s.d}}
A.ds.prototype={}
A.en.prototype={
ei(a){var s,r,q,p,o,n=this
if(n.a===a)return
for(s=n.c,r=s.length,q=t.T,p=t.m,o=0;o<s.length;s.length===r||(0,A.k)(s),++o)p.a(q.a(s[o].d).a.classList).remove("ql-cell-focused")
n.M(0)
n.a=a},
gbc(){var s=this.c,r=A.K(s),q=r.i("a1<1,T>")
return A.N(new A.a1(s,r.i("T(1)").a(new A.mo()),q),!1,q.i("ad.E"))},
fE(a){var s,r,q=this.jq(a)
this.dT(q)
if(q!=null){s=t.T.a(q.d).a
r=t.m
r.a(s.classList).remove("ql-cell-selected")
r.a(s.classList).add("ql-cell-focused")}return q},
mz(a){var s,r,q,p,o,n,m,l=this
t.u.a(a)
l.M(0)
s=A.a([],t.xC)
for(r=a.length,q=0;q<a.length;a.length===r||(0,A.k)(a),++q){p=l.jq(a[q])
if(p!=null)B.a.k(s,p)}l.shn(A.cc(s,t.Z))
for(r=l.c,o=r.length,n=t.T,m=t.m,q=0;q<r.length;r.length===o||(0,A.k)(r),++q)m.a(n.a(r[q].d).a.classList).add("ql-cell-selected")
l.b=l.q2(l.c)},
hS(){var s=this.gbc()
return new A.iv(B.a.c0(s,new A.mk()),B.a.c0(s,new A.ml()))},
mp(){var s,r,q,p=this.b
if(p==null)return B.G
s=this.a.a4(t.H).gm(0)
r=p.b
q=s===0?0:s-1
return this.dF(p.d,q,r,0)},
mq(){var s,r,q,p,o,n,m=this,l=m.b
if(l==null)return B.G
for(s=m.cm(),r=s.length,q=0,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
n=o.c+m.bd(o.a,"colspan")
if(n>q)q=n}s=l.a
r=l.c
return m.dF(q===0?0:q-1,r,0,s)},
lQ(a){var s,r,q,p,o,n,m,l,k,j,i,h=this,g=h.b
if(g==null)return!1
s=h.cm()
r=s.length
if(r===0)return!1
for(q=0,p=0,o=0;o<s.length;s.length===r||(0,A.k)(s),++o){n=s[o]
m=n.a
l=n.b+h.bd(m,"rowspan")-1
k=n.c+h.bd(m,"colspan")-1
if(l>q)q=l
if(k>p)p=k}if(a==="column"){j=B.f.aA(B.d.aC(g.a,0,q))
i=g.d+1
if(i>p)i=g.b-1
if(i<0)return!1}else{i=B.f.aA(B.d.aC(g.b,0,p))
j=g.c+1
if(j>q)j=g.a-1
if(j<0)return!1}return h.dF(i,j,i,j).length!==0},
jq(a){var s,r,q,p
for(s=this.a.a4(t.Z),r=s.$ti,s=new A.H(s.a(),r.i("H<1>")),q=t.T,r=r.c;s.l();){p=s.b
if(p==null)p=r.a(p)
if(q.a(p.d).n(0,a))return p}return null},
jD(a){var s,r,q,p,o,n,m,l
for(s=this.cm(),r=s.length,q=null,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
if(!B.a.v(this.c,o.a))continue
if(q==null){q=o
continue}n=o.b
m=q.b
if(n>=m)l=n===m&&o.c<q.c
else l=!0
if(a?l:!l)q=o}return q},
q2(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=null
t.x7.a(a)
if(a.length===0)return f
for(s=this.cm(),r=s.length,q=f,p=q,o=p,n=o,m=0;m<s.length;s.length===r||(0,A.k)(s),++m){l=s[m]
k=l.a
if(!B.a.v(a,k))continue
j=l.b
i=j+this.bd(k,"rowspan")-1
h=l.c
g=h+this.bd(k,"colspan")-1
if(n==null||j<n)n=j
if(o==null||h<o)o=h
if(p==null||i>p)p=i
if(q==null||g>q)q=g}if(n==null)return f
o.toString
p.toString
q.toString
return A.z0(q,p,o,n)},
cv(a){var s,r,q,p
for(s=this.cm(),r=s.length,q=0;q<r;++q){p=s[q]
if(p.a===a)return new A.h5(p.c,p.b)}return null},
M(a){var s,r,q,p,o
for(s=this.c,r=s.length,q=t.T,p=t.m,o=0;o<s.length;s.length===r||(0,A.k)(s),++o)p.a(q.a(s[o].d).a.classList).remove("ql-cell-selected")
this.shn(B.G)
this.b=null},
dF(a,b,c,d){var s,r,q,p,o,n,m,l=this
l.M(0)
s=A.z0(a,b,c,d)
r=l.cm()
q=A.K(r)
p=q.i("bU<1,a6>")
l.shn(A.N(new A.bU(new A.an(r,q.i("x(1)").a(new A.mm(l,s)),q.i("an<1>")),q.i("a6(1)").a(new A.mn()),p),!1,p.i("o.E")))
l.b=s
for(q=l.c,p=q.length,o=t.T,n=t.m,m=0;m<q.length;q.length===p||(0,A.k)(q),++m)n.a(o.a(q[m].d).a.classList).add("ql-cell-selected")
return A.cc(l.c,t.Z)},
tN(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5=this,a6=null,a7="rowspan"
if(a5.c.length<2)return a6
s=a5.cm()
for(r=s.length,q=a6,p=-1,o=-1,n=-1,m=-1,l=0;l<s.length;s.length===r||(0,A.k)(s),++l){k=s[l]
j=k.a
if(!B.a.v(a5.c,j))continue
i=k.b
h=i+a5.bd(j,a7)-1
g=k.c
f=g+a5.bd(j,"colspan")-1
if(q==null){m=f
n=h
o=g
p=i
q=k
continue}if(i<p)p=i
if(g<o)o=g
if(h>n)n=h
if(f>m)m=f
j=q.b
if(i>=j)j=i===j&&g<q.c
else j=!0
if(j)q=k}if(q==null)return a6
e=q.a
for(r=a5.c,j=r.length,d=0,l=0;l<r.length;r.length===j||(0,A.k)(r),++l){c=r[l]
if(c===e)continue
b=c.a
b=b instanceof A.ag?b:a6
c.b2(e,a6)
a=c.a
if(a!=null)a.aj(c)
if(b!=null&&b.e.length===0){a=b.a
if(a!=null)a.aj(b);++d}}if(d>0){b=e.a
b=b instanceof A.ag?b:a6
if(b!=null)for(r=b.e,j=r.length,a=t.T,a0=t.Z,l=0;l<r.length;r.length===j||(0,A.k)(r),++l){a1=r[l]
if(!(a1 instanceof A.a6)||a1===e)continue
a2=a5.bd(a1,a7)-d
a3=a0.a(a1).d
if(a2>1)a.a(a3).a.setAttribute("rowspan",""+a2)
else a.a(a3).a.removeAttribute("rowspan")}}a5.kG(e,"colspan",m-o+1)
a5.kG(e,a7,n-p+1-d)
a4=A.f4(e).b
if(a4.length!==0)e.iL(a4)
a5.dT(e)
return e},
mG(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=this,a1=null,a2=A.a5(a0.c,!0,t.Z),a3=a2.length
if(a3===0)return
for(s=t.T,r=a1,q=0;q<a2.length;a2.length===a3||(0,A.k)(a2),++q){p=a2[q]
o=a0.bd(p,"colspan")
n=a0.bd(p,"rowspan")
if(o===1&&n===1)continue
m=a0.cv(p)
l=p.a
l=l instanceof A.ag?l:a1
if(m==null||l==null)continue
if(r==null)r=p
if(n>1){k=l.c
for(j=1;j<n;++j){i=k instanceof A.ag?k:a1
h=a0.q5(i,m.a)
g=h.a
f=h.b
for(e=0;e<o;++e)a0.a.fb(i,g,f)
k=i==null?a1:i.c}}if(o>1){g=A.m(s.a(p.d).a.getAttribute("data-row"))
if(g==null)g="row-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0")
d=p.c
f=d instanceof A.a6?d:a1
for(j=1;j<o;++j)a0.a.fb(l,g,f)}c=s.a(p.d).a
c.removeAttribute("colspan")
c.removeAttribute("rowspan")
b=A.m(c.getAttribute("width"))
a=A.bg(b==null?"":b)
if(a!=null)c.setAttribute("width",""+B.f.je(a,o))}if(r==null)return
a0.dT(r)},
qZ(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this,a=null,a0="Blot is not attached to a scroll",a1=b.kn(),a2=A.K(a1),a3=a2.i("an<1>"),a4=A.N(new A.an(a1,a2.i("x(1)").a(new A.mi()),a3),!0,a3.i("o.E"))
if(a4.length===0)return a
s=A.a([],t.BR)
r=B.a.gK(a4)
for(;r instanceof A.ag;){B.a.V(s,0,r)
r=r.b}q=b.a.dA()
if(q==null){q=t.Bx.a(b.a.gX().z.a5("table-thead",a))
a1=b.a
a1.D(q,a1.bJ())}for(a1=s.length,a2=t.mo,a3=t.T,p=t.iA,o=a,n=0;n<s.length;s.length===a1||(0,A.k)(s),++n){m=s[n]
l=b.a.gaR()
if(l==null)A.a4(A.aL(a0))
k=l.z.a.h(0,"table-th-row")
if(k==null)A.a4(A.au('Unknown blot "table-th-row"',a))
j=p.a(k.c.$1(a))
i=m.e
i=A.a(i.slice(0),A.K(i))
h=i.length
g=0
for(;g<i.length;i.length===h||(0,A.k)(i),++g){f=i[g]
if(!(f instanceof A.a6))continue
l=b.a.gaR()
if(l==null)A.a4(A.aL(a0))
e=A.eH(a3.a(f.d))
k=l.z.a.h(0,"table-th")
if(k==null)A.a4(A.au('Unknown blot "table-th"',a))
d=a2.a(k.c.$1(e))
f.b2(d,a)
j.D(d,a)
if(o==null)o=d}q.D(j,a)
i=m.a
if(i!=null)i.aj(m)}c=b.a.bJ()
if(c!=null&&c.e.length===0)c.Y(0)
b.dT(o)
return o},
r_(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=this,a3=null,a4="Blot is not attached to a scroll",a5=t.rL,a6=A.N(new A.ae(a2.kn(),a5),!0,a5.i("o.E"))
if(a6.length===0)return a3
s=A.a([],t.BR)
r=B.a.gF(a6)
for(;r instanceof A.ag;){B.a.k(s,r)
r=r.c}q=a2.a.bJ()
p=q==null
if(p)q=t.qj.a(a2.a.gX().z.a5("table-body",a3))
a5=q.e
o=a5.length===0?a3:B.a.gF(a5)
for(a5=s.length,n=t.Z,m=t.T,l=t.H,k=a3,j=0;j<s.length;s.length===a5||(0,A.k)(s),++j){i=s[j]
h=a2.a.gaR()
if(h==null)A.a4(A.aL(a4))
g=h.z.a.h(0,"table-row")
if(g==null)A.a4(A.au('Unknown blot "table-row"',a3))
f=l.a(g.c.$1(a3))
e=i.e
e=A.a(e.slice(0),A.K(e))
d=e.length
c=0
for(;c<e.length;e.length===d||(0,A.k)(e),++c){b=e[c]
if(!(b instanceof A.a6))continue
h=a2.a.gaR()
if(h==null)A.a4(A.aL(a4))
a=A.eH(m.a(b.d))
g=h.z.a.h(0,"table-cell")
if(g==null)A.a4(A.au('Unknown blot "table-cell"',a3))
a0=n.a(g.c.$1(a))
b.b2(a0,a3)
f.D(a0,a3)
if(k==null)k=a0}q.D(f,o)
e=i.a
if(e!=null)e.aj(i)}if(p)a2.a.D(q,a3)
a1=a2.a.dA()
if(a1!=null&&a1.e.length===0)a1.Y(0)
a2.dT(k)
return k},
r1(){var s,r,q,p,o,n,m,l,k
this.a.m5()
s=A.a([],t.s)
for(r=this.a.a4(t.H),q=r.$ti,r=new A.H(r.a(),q.i("H<1>")),p=t.ja,o=t.N,n=p.i("e(o.E)"),m=p.i("o.E"),q=q.c;r.l();){l=r.b
l=A.ft(new A.ae((l==null?q.a(l):l).e,p),n.a(new A.mj()),m,o)
k=A.N(l,!0,A.u(l).i("o.E"))
if(k.length!==0)B.a.k(s,B.a.ab(k,"\t"))}B.a.ab(s,"\n")
return new A.m9()},
kn(){var s,r,q,p=A.a([],t.BR)
for(s=this.a.a4(t.H),r=s.$ti,s=new A.H(s.a(),r.i("H<1>")),r=r.c;s.l();){q=s.b
if(q==null)q=r.a(q)
if(B.a.c0(q.e,new A.mh(this)))B.a.k(p,q)}return p},
dT(a){var s,r,q
this.M(0)
if(a==null)return
s=this.cv(a)
if(s==null)return
r=s.b
q=s.a
this.dF(q,r,q,r)},
q5(a,b){var s,r,q,p,o,n,m,l,k=null,j=1679616
if(a==null)return new A.f_("row-"+B.b.ai(B.d.ac($.b0().am(j),36),4,"0"),k)
s=a.e
r=s.length===0?k:B.a.gF(s)
if(r instanceof A.a6){s=A.m(t.T.a(r.d).a.getAttribute("data-row"))
q=s==null?"row-"+B.b.ai(B.d.ac($.b0().am(j),36),4,"0"):s}else q="row-"+B.b.ai(B.d.ac($.b0().am(j),36),4,"0")
for(s=this.cm(),p=s.length,o=0;o<p;++o){n=s[o]
m=n.a
l=m.a
if((l instanceof A.ag?l:k)!==a)continue
if(n.c>b)return new A.f_(q,m)}return new A.f_(q,k)},
kG(a,b,c){var s=t.T,r=a.d
if(c>1)s.a(r).a.setAttribute(b,""+c)
else s.a(r).a.removeAttribute(b)},
cm(){var s,r,q,p,o,n,m,l,k,j,i,h=A.a([],t.yd),g=t.S,f=A.b(g,g)
g=this.a.a4(t.H)
s=A.N(g,!0,g.$ti.i("o.E"))
for(r=0;r<s.length;++r)for(g=s[r].e,q=g.length,p=0,o=0;o<g.length;g.length===q||(0,A.k)(g),++o){n=g[o]
if(!(n instanceof A.a6))continue
while(!0){m=f.h(0,p)
if(!((m==null?-1:m)>=r))break;++p}l=this.bd(n,"rowspan")
k=this.bd(n,"colspan")
B.a.k(h,new A.ds(n,r,p))
for(m=l>1,j=r+l-1,i=0;i<k;++i)if(m)f.j(0,p+i,j)
p+=k}return h},
bd(a,b){var s=A.m(t.T.a(a.d).a.getAttribute(b)),r=A.V(s==null?"":s,null)
if(r==null)r=1
return r<1?1:r},
shn(a){this.c=t.x7.a(a)}}
A.mo.prototype={
$1(a){return t.T.a(t.Z.a(a).d)},
$S:182}
A.mk.prototype={
$1(a){return A.h(t.T.a(a).a.tagName).toUpperCase()==="TD"},
$S:23}
A.ml.prototype={
$1(a){return A.h(t.T.a(a).a.tagName).toUpperCase()==="TH"},
$S:23}
A.mm.prototype={
$1(a){var s,r,q,p,o
t.aH.a(a)
s=this.a
r=this.b
q=a.a
p=s.bd(q,"rowspan")
o=s.bd(q,"colspan")
q=a.b
s=a.c
return q<=r.c&&q+p-1>=r.a&&s<=r.d&&s+o-1>=r.b},
$S:183}
A.mn.prototype={
$1(a){return t.aH.a(a).a},
$S:184}
A.mi.prototype={
$1(a){return!(t.H.a(a) instanceof A.bI)},
$S:185}
A.mj.prototype={
$1(a){var s=A.m(t.T.a(t.Z.a(a).d).a.textContent)
return s==null?"":s},
$S:186}
A.mh.prototype={
$1(a){t.U.a(a)
return a instanceof A.a6&&B.a.v(this.a.c,a)},
$S:3}
A.mf.prototype={}
A.je.prototype={
M(a){var s,r,q,p,o,n
for(s=this.c,r=s.gbc(),q=r.length,p=t.m,o=0;o<r.length;r.length===q||(0,A.k)(r),++o){n=r[o].a
p.a(n.classList).remove("ql-cell-focused")
p.a(n.classList).remove("ql-cell-selected")}s.M(0)
this.Q=null},
m7(a,b){var s,r,q,p,o,n,m,l,k
if(A.h(a.a.tagName).toUpperCase()!=="SELECT")return A.a([a],t.r)
s=a.gaG()
q=t.A
p=t.m
while(!0){if(!(s!=null)){r=null
break}if(s instanceof A.f&&A.I(p.a(s.a.classList).contains("ql-formats"))){r=s
break}o=s.a
if(q.a(o.parentNode)==null)s=null
else{o=q.a(o.parentNode)
o.toString
s=A.S(o)}}if(r==null)return A.a([a],t.r)
n=A.a([],t.r)
for(q=r.a_("span"),o=q.length,m=0;m<q.length;q.length===o||(0,A.k)(q),++m){l=q[m]
k=l.a
if(A.I(p.a(k.classList).contains(b))&&A.I(p.a(k.classList).contains("ql-picker")))B.a.k(n,l)}q=A.N(n,!0,t.T)
q.push(a)
return q},
ho(a){var s,r,q,p,o,n=this,m=new A.b9(t.m.a(a.a.classList)).gak(),l=m.length,k=0
while(!0){if(!(k<l)){s=null
break}r=m[k]
if(B.b.a0(r,"ql-")){s=r
break}++k}if(s==null)return
q=n.d.x
if(q==null)q=B.fJ
m=q.h(0,"whiteList")
if(m==null)m=B.dA
l=q.h(0,"singleWhiteList")
if(l==null)l=B.eu
p=n.m7(a,s)
o=B.b.L(s,3)
if(!B.a.v(m,o))B.a.H(n.y,p)
if(B.a.v(l,o))B.a.H(n.z,p)},
te(){var s,r,q,p=this.d.w
if(p==null)return
for(s=A.N(p.a_("button"),!0,t.T),B.a.H(s,p.a_("select")),r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q)this.ho(s[q])},
fD(a){var s,r,q,p,o
for(s=this.y,r=s.length,q=t.m,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p].a
if(a)q.a(o.classList).add("ql-table-button-disabled")
else q.a(o.classList).remove("ql-table-button-disabled")}this.dH()},
dH(){var s,r,q,p,o,n=this.c.gbc().length>1
for(s=this.z,r=s.length,q=t.m,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p].a
if(n)q.a(o.classList).add("ql-table-button-disabled")
else q.a(o.classList).remove("ql-table-button-disabled")}},
d3(){var s=this.c.hS(),r=this.d.c
if(r!=null)r.$1(s.b&&!s.a?"true":"false")},
d4(a){var s=this.c.hS(),r=s.b,q=this.d.d
if(q!=null)q.$2(a,s.a&&r)},
fF(a,b){var s=this
s.M(0)
s.Q=s.c.fE(a)
s.d3()
s.d4("merge")
s.dH()
return},
iJ(a,b){var s,r,q,p=this.c,o=p.cv(a),n=p.cv(b)
if(o==null||n==null)return
this.M(0)
this.Q=a
s=o.b
r=o.a
q=n.b
p.dF(n.a,q,r,s)},
hQ(a){var s,r,q=this,p=q.fR(t.f.a(a).gau())
if(p==null)return
q.M(0)
q.Q=p
q.c.fE(t.T.a(p.d))
q.d3()
q.d4("merge")
q.jI()
q.sjX(new A.ma(q,p))
q.sjY(new A.mb(q))
s=q.b
r=q.w
r.toString
s.I("mousemove",r)
r=q.x
r.toString
s.I("mouseup",r)},
hM(a){var s,r,q,p
t.f.a(a)
if((a instanceof A.bB?A.v(a.a.detail):1)<3||this.c.gbc().length===0){this.oU(a)
return}s=this.a
r=s.d1(!0)
if(r==null)return
q=r.a
p=r.b
s.S(new A.G(q,p>0?p-1:0),"silent")
s.b5()},
oU(a){var s,r,q=this,p=q.fR(a.gau())
if(p==null)return
s=a instanceof A.bB&&A.I(a.a.shiftKey)
r=q.Q
if(!s||r==null){q.M(0)
q.Q=p
q.c.fE(t.T.a(p.d))
q.d3()
q.d4("merge")
return}a.a.preventDefault()
q.iJ(r,p)
q.dH()
q.d3()
q.d4("merge")},
px(a){t.f.a(a)
if(!(a instanceof A.cv))return
this.rO(a)
this.hN(a)},
hN(a){var s=a.a
switch(A.h(s.key)){case"ArrowLeft":case"ArrowRight":this.tI(A.h(s.key))
break
case"ArrowUp":case"ArrowDown":this.tJ(A.h(s.key))
break
default:break}},
rO(a){var s,r
if(this.c.gbc().length<2)return
s=a.a
if(A.h(s.key)!=="Backspace"&&A.h(s.key)!=="Delete")return
if(A.I(s.ctrlKey)||A.I(s.metaKey)){s=this.d
r=s.f
if(r!=null)r.$1(!0)
s=s.r
if(s!=null)s.$1(!0)}else this.ue()},
tI(a){var s,r,q,p=this,o=p.a,n=o.aX()
if(n==null)return
s=n.a
o=o.c
o===$&&A.c()
r=A.iT(o.ap(s).a)
if(r==null){p.d.a.$0()
return}o=p.c
if(a==="ArrowLeft"){o=o.jD(!0)
q=o==null?null:t.T.a(o.a.d)}else{o=o.jD(!1)
q=o==null?null:t.T.a(o.a.d)}if(q==null||!q.n(0,t.T.a(r.d))){p.fF(t.T.a(r.d),!1)
p.d.b.$1(!1)}},
tJ(a){var s,r,q,p,o,n,m,l,k,j,i=this,h=a==="ArrowUp",g=i.a,f=g.aX()
if(f==null)return
s=f.a
r=g.c
r===$&&A.c()
q=r.ap(s)
p=q.a
o=q.b
if(p==null)return
n=h?p.b:p.c
if(n!=null&&i.c.gbc().length!==0){m=n.E(0)-1
s=r.aP(n)
g.S(new A.G(s+(o<m?o:m),0),"user")
return}l=A.iT(p)
if(l==null)return
g=i.c
if(g.gbc().length===0){i.lC(h,l)
i.d.b.$1(!1)
return}k=g.cv(l)
if(k==null){i.l7(l,h)
return}j=i.nP(k.b,k.a,h)
if(j==null)i.l7(l,h)
else i.lC(h,j)},
lC(a,b){var s,r,q,p=b.e
if(p.length===0)return
s=a?B.a.gK(p):B.a.gF(p)
r=a?s.E(0)-1:0
this.fF(t.T.a(b.d),!1)
p=this.a
q=p.c
q===$&&A.c()
p.S(new A.G(q.aP(s)+r,0),"user")},
l7(a,b){var s,r,q,p,o=a.fm()
if(o==null)return
s=b?-1:o.E(0)
r=this.a
q=r.c
q===$&&A.c()
p=q.aP(o)
this.d.a.$0()
r.S(new A.G(B.f.aA(B.d.aC(p+s,0,q.E(0))),0),"user")},
ud(a){var s,r,q,p,o,n,m="table-cell-block",l=a.e
if(l.length===0)return
s=B.a.gF(l)
if(s instanceof A.bG){r=A.m(s.P().h(0,m))
q=r==null?"cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0"):r}else q="cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0")
r=this.a.c
r===$&&A.c()
p=r.z.a5(m,q)
a.D(p,s)
l=A.a(l.slice(0),A.K(l))
r=l.length
o=0
for(;o<l.length;l.length===r||(0,A.k)(l),++o){n=l[o]
if(n===p)continue
n.Y(0)}},
ue(){var s,r=this.c,q=t.Z
if(A.cc(r.c,q).length<2)return
for(r=A.cc(r.c,q),q=r.length,s=0;s<q;++s)this.ud(r[s])
r=this.d.e
if(r!=null)r.$0()},
u_(a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this,a=b.c
if(a.gbc().length===0)return!1
s=b.pO(a0)
if(s.length===0)return!1
r=b.Q
if(r==null){q=t.Z
r=A.DB(A.cc(a.c,q),q)}if(r==null)return!1
p=a.cv(r)
if(p==null)return!1
q=b.a
o=q.z
o===$&&A.c()
o.d=0
o=A.K(s)
n=new A.a1(s,o.i("j(1)").a(new A.md(b)),o.i("a1<1,j>")).ag(0,0,new A.me(),t.S)
b.ox(p,s.length,n)
m=A.a([],t.r)
for(o=p.b,l=t.T,k=p.a,j=0;j<s.length;++j){i=s[j]
for(h=i.length,g=o+j,f=k,e=0;e<i.length;i.length===h||(0,A.k)(i),++e){d=i[e]
c=b.nO(g,f)
if(c!=null)B.a.k(m,l.a(b.u0(c,d).d))
f+=b.eH(d)}}if(m.length!==0){t.u.a(m)
b.M(0)
a.mz(m)
b.dH()
b.d3()
b.d4("merge")}a=b.d.e
if(a!=null)a.$0()
q.b5()
return!0},
u0(a,b){var s,r,q,p,o,n,m=A.m(t.T.a(a.d).a.getAttribute("data-row")),l=t.N
l=A.aJ(A.eH(b),l,l)
if(m!=null)l.j(0,"data-row",m)
s=t.Z.a(A.bo(a,a.gA(),l))
l=s.e
l=A.a(l.slice(0),A.K(l))
r=l.length
q=0
for(;q<l.length;l.length===r||(0,A.k)(l),++q)l[q].Y(0)
l=this.a
r=l.c
r===$&&A.c()
p=s.gA()==="table-th"?"table-th-block":"table-cell-block"
o=t.hB.a(r.z.a5(p,"cell-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0")))
s.D(o,null)
p=A.m(b.a.textContent)
n=B.b.R(p==null?"":p)
if(n.length!==0)l.fc(r.aP(o),n,"user")
return s},
ox(a1,a2,a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this.c,a=t.H,a0=a1.b+a2-b.a.a4(a).gm(0)
for(s=0;s<a0;++s){r=b.a
r.tm(r.a4(a).gm(0),1)}q=b.a.bJ()
if(q==null)return
for(r=B.a.gJ(q.e),p=new A.aQ(r,t.DE),o=t.T,n=t.ja,m=t.Z,l=a1.a+a3,k=t.er;p.l();){j=a.a(r.gq())
for(i=j.e,h=B.a.gJ(i),g=new A.aQ(h,k),f=0;g.l();)f+=this.eH(o.a(m.a(h.gq()).d))
e=l-f
if(e<=0)continue
d=A.DC(new A.ae(i,n),m)
c=d==null?null:A.m(o.a(d.d).a.getAttribute("data-row"))
if(c==null)c="row-"+B.b.ai(B.d.ac($.b0().am(1679616),36),4,"0")
for(s=0;s<e;++s)b.a.fb(j,c,null)}},
nO(a,b){var s,r,q,p,o,n,m,l,k,j,i
for(s=this.c,r=s.a.a4(t.Z),q=r.$ti,r=new A.H(r.a(),q.i("H<1>")),p=t.T,q=q.c;r.l();){o=r.b
if(o==null)o=q.a(o)
n=s.cv(o)
if(n==null)continue
m=p.a(o.d)
l=this.eH(m)
m=A.m(m.a.getAttribute("rowspan"))
k=A.V(m==null?"":m,null)
if(k==null)k=1
j=k<1?1:k
m=n.b
i=!1
if(m<=a)if(a<m+j){m=n.a
m=m<=b&&b<m+l}else m=i
else m=i
if(m)return o}return null},
pO(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f
if(B.b.R(a).length===0)return B.e3
s=this.a.b
s===$&&A.c()
t.A.a(s.a.ownerDocument).toString
r=new A.fl(t.m.a(new self.DOMParser())).fg(a,"text/html")
q=A.a([],t.ux)
for(s=r.gcq().a_("tr"),p=s.length,o=t.mG,n=t.T,m=t.r,l=0;l<s.length;s.length===p||(0,A.k)(s),++l){k=s[l]
j=A.a([],m)
for(i=B.a.gJ(k.gan()),h=new A.aQ(i,o);h.l();){g=n.a(i.gq())
f=A.h(g.a.tagName).toUpperCase()
if(f==="TD"||f==="TH")B.a.k(j,g)}if(j.length!==0)B.a.k(q,j)}return q},
eH(a){var s=A.m(a.a.getAttribute("colspan")),r=A.V(s==null?"":s,null)
if(r==null)r=1
return r<1?1:r},
jI(){var s,r=this,q=r.w
if(q!=null)r.b.ca("mousemove",q)
s=r.x
if(s!=null)r.b.ca("mouseup",s)
r.sjX(null)
r.sjY(null)},
nP(a,b,c){var s,r,q,p,o,n,m,l=this.c,k=l.a.a4(t.H).gm(0),j=c?a-1:a+1,i=t.Z,h=t.T
while(!0){if(!(j>=0&&j<k))break
for(s=l.a.a4(i),r=s.$ti,s=new A.H(s.a(),r.i("H<1>")),r=r.c;s.l();){q=s.b
if(q==null)q=r.a(q)
p=l.cv(q)
if(p==null)continue
o=A.m(h.a(q.d).a.getAttribute("colspan"))
n=A.V(o==null?"":o,null)
if(n==null)n=1
m=n<1?1:n
if(p.b===j){o=p.a
o=o<=b&&b<o+m}else o=!1
if(o)return q}j=c?j-1:j+1}return null},
nQ(a){var s,r,q,p,o,n,m,l=this.a.c
l===$&&A.c()
l=l.a4(t.ll)
s=l.$ti
l=new A.H(l.a(),s.i("H<1>"))
r=t.Z
q=t.T
s=s.c
for(;l.l();){p=l.b
if(p==null)p=s.a(p)
for(o=p.a4(r),n=o.$ti,o=new A.H(o.a(),n.i("H<1>")),n=n.c;o.l();){m=o.b
if(m==null)m=n.a(m)
if(q.a(m.d).n(0,a)){this.c.ei(p)
return m}}}return null},
fR(a){var s,r,q=t.A,p=this.b,o=a
while(!0){if(!(o!=null&&!o.n(0,p)))break
if(o instanceof A.f){s=A.h(o.a.tagName).toUpperCase()
if(s==="TD"||s==="TH")return this.nQ(o)}r=o.a
if(q.a(r.parentNode)==null)o=null
else{r=q.a(r.parentNode)
r.toString
o=A.S(r)}}return null},
snt(a){this.e=t.O.a(a)},
snv(a){this.f=t.O.a(a)},
snu(a){this.r=t.O.a(a)},
sjX(a){this.w=t.Cw.a(a)},
sjY(a){this.x=t.Cw.a(a)}}
A.ma.prototype={
$1(a){var s,r=this.a,q=r.fR(t.f.a(a).gau())
if(q==null||q===this.b)return
r.iJ(this.b,q)
r=r.a
s=r.f
s===$&&A.c()
s.M(0)
s=$.y()
r=r.b
r===$&&A.c()
s.a.kM(r)},
$S:0}
A.mb.prototype={
$1(a){var s
t.f.a(a)
s=this.a
s.dH()
s.d3()
s.d4("merge")
s.jI()},
$S:0}
A.md.prototype={
$1(a){return J.CO(t.u.a(a),0,new A.mc(this.a),t.S)},
$S:187}
A.mc.prototype={
$2(a,b){return A.v(a)+this.a.eH(t.T.a(b))},
$S:188}
A.me.prototype={
$2(a,b){A.v(a)
A.v(b)
return b>a?b:a},
$S:44}
A.hG.prototype={
lG(){var s=this.a/60,r=this.b/100,q=this.c/100,p=B.f.hK(s),o=s-p,n=q*(1-r),m=q*(1-o*r),l=q*(1-(1-o)*r),k=B.d.b4(p,6),j=[q,m,n,n,l,q][k],i=[l,q,q,m,n,n][k],h=[n,n,l,q,q,m][k]
return new A.d0(B.d.aC(B.f.ah(j*255),0,255),B.d.aC(B.f.ah(i*255),0,255),B.d.aC(B.f.ah(h*255),0,255))},
gt3(){var s=this.lG(),r=new A.nB()
return"#"+A.p(r.$1(s.a))+A.p(r.$1(s.b))+A.p(r.$1(s.c))}}
A.nC.prototype={
$1(a){A.h(a)
return a+a},
$S:6}
A.nB.prototype={
$1(a){return B.b.ai(B.d.ac(a,16),2,"0")},
$S:189}
A.jn.prototype={
ghE(){return new A.iw([55,55,55,110])},
ghR(){return 41},
lN(a,b){if(b)return B.f.b4(B.f.b4(180-a,360)+360,360)
return B.f.b4(B.f.b4(0-a,360)+360,360)},
ut(a){return this.lN(a,!1)},
rW(a,b,c){var s,r,q,p,o,n=this,m=n.ghE().a,l=m[0]-a
m=m[1]-b
m=Math.sqrt(l*l+m*m)
if(!(m<55))return!1
m=n.ghE().a
s=m[0]-a
r=m[1]-b
q=n.ut(Math.atan2(-r,-s)*57.29577951308232)
p=Math.min(Math.sqrt(s*s+r*r),n.ghR())
m=n.z
l=B.f.fk(q)
o=B.f.fk(100/n.ghR()*p)
n.z=new A.hG(l,o,m.c)
n.ki()
return!0},
nK(){var s,r,q,p=this,o=p.a.a,n=t.m,m=n.a(o.createElement("div")),l=t.O,k=t.g,j=new A.f(A.b(l,k),m)
n.a(m.classList).add("IroWheel")
s=t.N
A.aH(j,A.l(["width",A.af(110)+"px","height",A.af(110)+"px","position","relative"],s,s))
r=new A.mI(p,j)
q=A.af(90)
r.$2("IroWheelHue",A.l(["transform","rotateZ("+q+"deg)","background","conic-gradient(red, magenta, blue, aqua, lime, yellow, red)"],s,s))
r.$2("IroWheelSaturation",A.l(["background","radial-gradient(circle closest-side, #fff, transparent)"],s,s))
r.$2("IroWheelBorder",A.b(s,s))
o=n.a(o.createElement("div"))
p.y!==$&&A.ai()
k=p.y=new A.f(A.b(l,k),o)
n.a(o.classList).add("IroHandle")
n.a(k.a.classList).add("IroHandle--isActive")
n.a(m.appendChild(k.a))
j.I("mousedown",new A.mH(p))
return j},
ki(){var s,r,q,p,o,n=this,m=n.z,l=n.ghE(),k=(180+n.lN(m.a,!0))*0.017453292519943295,j=m.b/100*n.ghR(),i=l.a,h=i[0],g=Math.cos(k)
i=i[1]
s=Math.sin(k)
r=n.y
r===$&&A.c()
q=A.af(16)
p=A.af(16)
g=A.af(h+j*g-8)
s=A.af(i+j*s-8)
o=n.z.lG()
i=t.N
A.aH(r,A.l(["position","absolute","width",q+"px","height",p+"px","border-radius","50%","box-sizing","border-box","border","2px solid #fff","box-shadow","0 0 3px rgba(0,0,0,.3)","left",g+"px","top",s+"px","background-color","rgb("+o.a+", "+o.b+", "+o.c+")"],i,i))}}
A.mI.prototype={
$2(a,b){var s,r,q,p
t.J.a(b)
s=t.m
r=s.a(this.a.a.a.createElement("div"))
q=new A.f(A.b(t.O,t.g),r)
s.a(r.classList).add(a)
p=t.N
p=A.b(p,p)
p.j(0,"position","absolute")
p.j(0,"top","0")
p.j(0,"left","0")
p.j(0,"width","100%")
p.j(0,"height","100%")
p.j(0,"border-radius","50%")
p.j(0,"box-sizing","border-box")
p.H(0,b)
A.aH(q,p)
s.a(this.b.a.appendChild(r))
return q},
$S:190}
A.mH.prototype={
$1(a){var s,r,q
t.f.a(a)
if(!(a instanceof A.bB))return
s=this.a
r=s.x
r===$&&A.c()
q=A.bn(r,null)
r=a.a
if(s.rW(A.v(r.clientX)-q.a,A.v(r.clientY)-q.b,!0))r.preventDefault()},
$S:0}
A.ox.prototype={}
A.iu.prototype={}
A.ka.prototype={
gcl(){var s,r=this.z
if(r===$){s=this.a.b
s===$&&A.c()
s=t.A.a(s.a.ownerDocument)
s.toString
r!==$&&A.ei()
r=this.z=new A.bu(s)}return r},
gjK(){var s,r=this.as
if(r===$){s=this.goI()
r!==$&&A.ei()
this.snx(s)
r=s}return r},
gjJ(){var s,r=this.at
if(r===$){s=this.goK()
r!==$&&A.ei()
this.snw(s)
r=s}return r},
oJ(a){var s,r,q,p,o=this
t.f.a(a)
s=a.a
s.preventDefault()
if(!o.f)return
r=a instanceof A.bB
q=r?A.v(s.clientX):0
p=r?A.v(s.clientY):0
if(o.Q){o.ux(q,p)
o.f9()}else{o.uw(q,p)
o.fa()}},
oL(a){var s,r,q,p,o,n,m=this
t.f.a(a)
s=a.a
s.preventDefault()
m.k6()
m.f=!1
r=m.e
if(r==null)return
q=a instanceof A.bB
p=q?A.v(s.clientX):0
o=q?A.v(s.clientY):0
s=m.Q
q=r.b
if(s){s=m.y
if(s==="level")m.ms(q,p)
else if(s==="vertical")m.mu(q,o)
m.lL(!1)}else{n=A.bw(r.a)
m.mv(q,p-n.c,o-n.d)
s=m.w
if(s!=null)t.m.a(s.a.classList).remove("ql-operate-block-move")
m.f9()
m.lg()}},
k6(){var s=this
s.gcl().ca("mousemove",s.gjK())
s.gcl().ca("mouseup",s.gjJ())},
lO(a){a.I("mousedown",new A.oy(this,A.I(t.m.a(a.a.classList).contains("ql-operate-line-container"))))},
iz(a){var s=A.bn(a,this.a.a),r=t.N
return A.l(["left",A.af(s.a)+"px","top",A.af(s.b)+"px","width",A.af(s.e)+"px","height",A.af(s.f)+"px","display","block"],r,r)},
fu(a){var s,r,q=this,p=A.bw(q.a.a),o=A.bw(a.a),n=A.bw(a.b),m=n.a+n.e,l=n.b+n.f,k=A.af(8),j=A.af(8),i=o.d,h=p.b,g=A.af(i-h),f=o.c,e=p.a
f=A.af(f-e)
i=i>p.d?"none":"block"
s=t.N
r=A.l(["width",k+"px","height",j+"px","top",g+"px","left",f+"px","display",i],s,s)
if(Math.abs(m-a.c)<=5){q.y="level"
return new A.iu(r,A.l(["width",A.af(5)+"px","height",A.af(p.f)+"px","top","0","left",A.af(m-e-2.5)+"px","display","flex","cursor","col-resize"],s,s),B.fH)}if(Math.abs(l-a.d)<=5){q.y="vertical"
return new A.iu(r,A.l(["width",A.af(p.e)+"px","height",A.af(5)+"px","top",A.af(l-h-2.5)+"px","left","0","display","flex","cursor","row-resize"],s,s),B.fG)}q.fa()
return new A.iu(r,null,null)},
hO(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this
t.f.a(a)
s=e.a
r=s.c
r===$&&A.c()
if(A.m(t.T.a(r.d).a.getAttribute("contenteditable"))!=="true")return
q=e.ju(a.gau(),B.jS)
r=q!=null
if(r&&!e.o1(q))return
p=e.ju(a.gau(),B.jZ)
if(!r||p==null){if(e.r!=null&&!e.f){e.fa()
e.f9()}return}r=a instanceof A.bB
o=r?A.v(a.a.clientX):0
n=new A.ox(q,p,o,r?A.v(a.a.clientY):0)
if(e.r==null){e.e=n
r=t.m
m=r.a(e.gcl().a.createElement("div"))
l=t.O
k=t.g
j=new A.f(A.b(l,k),m)
i=r.a(e.gcl().a.createElement("div"))
r.a(m.classList).add("ql-operate-line-container")
h=e.e
h.toString
g=e.fu(h)
h=g.b
if(h!=null)A.aH(j,h)
h=g.c
if(h!=null)A.aH(new A.f(A.b(l,k),i),h)
r.a(m.appendChild(i))
s=s.a.a
r.a(s.appendChild(m))
e.r=j
e.lO(j)
m=r.a(e.gcl().a.createElement("div"))
f=new A.f(A.b(l,k),m)
r.a(m.classList).add("ql-operate-block")
k=e.e
k.toString
A.aH(f,e.fu(k).a)
e.w=f
r.a(s.appendChild(m))
e.lO(f)
return}if(e.f)return
e.uC(n)},
uC(a){var s,r,q,p=this,o=p.fu(a),n=o.b
if(n==null||o.c==null)return
p.e=a
s=p.r
if(s==null)return
n.toString
A.aH(s,n)
r=s.gf6()
if(r instanceof A.f){n=o.c
n.toString
A.aH(r,n)}q=p.w
if(q!=null)A.aH(q,o.a)},
fa(){var s=this.r
if(s!=null)A.aH(s,B.an)},
f9(){var s=this.w
if(s!=null)A.aH(s,B.an)},
lg(){var s=this.x
if(s!=null)A.aH(s,B.an)},
lL(a){var s,r=this.r,q=r==null?null:r.gf6()
if(!(q instanceof A.f))return
r=t.m
s=q.a
if(a)r.a(s.classList).add("ql-operate-line")
else r.a(s.classList).remove("ql-operate-line")},
ux(a,b){var s,r,q=this.r
if(q==null)return
s=A.bw(this.a.a)
r=this.y
if(r==="level"){r=t.N
A.aH(q,A.l(["left",A.af(a-s.a-2.5)+"px"],r,r))}else if(r==="vertical"){r=t.N
A.aH(q,A.l(["top",A.af(b-s.b-2.5)+"px"],r,r))}},
uw(a,b){var s,r,q=this.w
if(q==null)return
s=A.bw(this.a.a)
t.m.a(q.a.classList).add("ql-operate-block-move")
r=t.N
A.aH(q,A.l(["top",A.af(b-s.b-4)+"px","left",A.af(a-s.a-4)+"px"],r,r))
this.uy(a,b)},
uy(a,b){var s,r,q=this.x
if(q==null)return
s=A.bw(q)
r=t.N
A.aH(q,A.l(["width",A.af(a-s.a)+"px","height",A.af(b-s.b)+"px","display","block"],r,r))},
mb(a){var s,r,q,p
for(s=a,r=0;s!=null;){q=A.m(s.a.getAttribute("colspan"))
p=A.V(q==null?"":q,null)
if(p==null)p=1
r+=Math.max(1,p)
s=this.q0(s)}return r},
mc(a){var s,r,q,p,o,n,m=this.cL(a)
if(m==null)return 0
for(s=this.cK(m),r=s.length,q=0,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=A.m(s[p].a.getAttribute("colspan"))
n=A.V(o==null?"":o,null)
if(n==null)n=1
q+=Math.max(1,n)}return q},
m6(a,b){var s=t.q9,r=A.N(new A.ae(a.e,s),!0,s.i("o.E")),q=b-1
if(q<0||q>=r.length)return null
if(!(q>=0&&q<r.length))return A.d(r,q)
return r[q]},
iM(a,b,c){var s=t.N
if(c)A.aH(a,A.l(["width",A.iU(b,!0)],s,s))
else A.f6(a,A.l(["width",A.af(b)],s,s))},
ms(b3,b4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0=this,b1=b0.fQ(b3),b2=b1==null?null:b1.fm()
if(b2==null)return
s=b4-A.bw(b3).c
r=s<0?Math.ceil(s):Math.floor(s)
q=b0.mb(b3)
p=b2.i_()
o=b2.dj()
s=t.T
n=s.a(b2.d)
m=b0.a.a
l=A.bn(n,m)
if(o!=null){k=b0.m6(o,q)
if(k!=null){j=s.a(k.d)
b0.iM(j,A.bn(j,m).e+r,p)
i=k.c
if(i instanceof A.bZ){s=s.a(i.d)
b0.iM(s,A.bn(s,m).e-r,p)}}}else{h=b0.cL(b3)
g=h==null?null:b0.cL(h)
if(g!=null){f=b0.eM(b3)==null
e=A.a([],t.mW)
for(s=b0.cK(g),j=s.length,d=t.mz,c=0;c<s.length;s.length===j||(0,A.k)(s),++c){b=b0.cK(s[c])
a=b.length
if(a===0)continue
if(f){a0=B.a.gK(b)
a=A.bn(a0,m).e+r
B.a.k(e,new A.F(a0,a<0?Math.ceil(a):Math.floor(a),d))
continue}for(a1=0,a2=0;a2<b.length;b.length===a||(0,A.k)(b),++a2){a3=b[a2]
a4=A.m(a3.a.getAttribute("colspan"))
a5=A.V(a4==null?"":a4,null)
if(a5==null)a5=1
a1+=Math.max(1,a5)
if(a1>q)break
if(a1===q){i=b0.eM(a3)
if(i==null)continue
a4=A.bn(a3,m)
a6=A.bn(i,m)
a4=a4.e+r
B.a.k(e,new A.F(a3,a4<0?Math.ceil(a4):Math.floor(a4),d))
a4=a6.e-r
B.a.k(e,new A.F(i,a4<0?Math.ceil(a4):Math.floor(a4),d))}}}for(s=e.length,m=t.N,c=0;c<e.length;e.length===s||(0,A.k)(e),++c){a7=e[c]
a8=A.iU(a7.b,p)
j=a7.a
A.f6(j,A.l(["width",a8],m,m))
d=A.l(["width",a8],m,m)
a9=A.d1(j)
a9.H(0,d)
A.he(j,a9)}}}if(b0.eM(b3)==null)A.wQ(b2,l,r)
b0.h4(n)},
mu(a,b){var s,r,q,p,o,n,m,l=this,k=l.pI(a,"rowspan"),j=k>1?l.mk(a,k):l.cK(l.cL(a))
for(s=j.length,r=t.N,q=0;q<j.length;j.length===s||(0,A.k)(j),++q){p=j[q]
o=""+B.f.aA(b-A.bw(p).b)
A.f6(p,A.l(["height",o],r,r))
o=A.l(["height",o+"px"],r,r)
n=A.d1(p)
n.H(0,o)
A.he(p,n)}s=l.fQ(a)
m=s==null?null:s.fm()
if(m!=null)l.h4(t.T.a(m.d))},
mk(a,b){var s=this.cL(a),r=b
while(!0){if(!(r>1&&s!=null))break
s=this.eM(s);--r}return this.cK(s)},
mv(b1,b2,b3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8=this,a9=a8.cL(b1),b0=a9==null?null:a8.cL(a9)
if(b0==null)return
s=a8.cK(b0)
if(s.length===0)return
r=a8.mc(b1)
if(r===0)return
q=b2/r
p=b3/s.length
o=a8.fQ(b1)
n=o==null?null:o.fm()
if(n==null)return
m=n.i_()
l=n.dj()
o=t.T
k=o.a(n.d)
j=a8.a.a
i=A.bn(k,j)
h=A.a([],t.BZ)
for(g=s.length,f=0;f<s.length;s.length===g||(0,A.k)(s),++f)for(e=a8.cK(s[f]),d=e.length,c=0;c<e.length;e.length===d||(0,A.k)(e),++c){b=e[c]
a=A.m(b.a.getAttribute("colspan"))
a0=A.V(a==null?"":a,null)
if(a0==null)a0=1
a=Math.max(1,a0)
a1=A.bn(b,j)
B.a.k(h,new A.d0(b,Math.ceil(a1.e+q*a),Math.ceil(a1.f+p)))}if(l!=null){for(g=h.length,e=t.N,f=0;f<h.length;h.length===g||(0,A.k)(h),++f){d=h[f]
a2=d.a
a3=d.c
A.f6(a2,A.l(["height",A.af(a3)],e,e))
d=A.l(["height",A.af(a3)+"px"],e,e)
a4=A.d1(a2)
a4.H(0,d)
A.he(a2,a4)}for(g=B.a.gJ(l.e),d=new A.aQ(g,t.og),a=t.hi;d.l();){a5=o.a(a.a(g.gq()).d)
a6=Math.ceil(A.bn(a5,j).e+q)
if(m){a6=A.l(["width",A.iU(a6,!0)],e,e)
a4=A.d1(a5)
a4.H(0,a6)
A.he(a5,a4)}else A.f6(a5,A.l(["width",A.af(a6)],e,e))}}else for(o=h.length,j=t.N,f=0;f<h.length;h.length===o||(0,A.k)(h),++f){g=h[f]
a2=g.a
a3=g.c
a7=A.iU(g.b,m)
A.f6(a2,A.l(["height",A.af(a3),"width",a7],j,j))
g=A.l(["height",A.af(a3)+"px","width",a7],j,j)
a4=A.d1(a2)
a4.H(0,g)
A.he(a2,a4)}A.wQ(n,i,b2)
a8.h4(k)},
h4(a){this.c.$1(a)
this.a.ad("user")},
o1(a){var s,r,q,p
for(s=t.A,r=this.a,q=a;q!=null;){p=r.b
p===$&&A.c()
if(q.n(0,p))return!0
p=q.a
if(s.a(p.parentNode)==null)q=null
else{p=s.a(p.parentNode)
p.toString
q=A.S(p)}}return!1},
ju(a,b){var s,r,q
t.dO.a(b)
for(s=t.A,r=a;r!=null;){if(r instanceof A.f&&b.v(0,A.h(r.a.tagName).toUpperCase()))return r
q=r.a
if(s.a(q.parentNode)==null)r=null
else{q=s.a(q.parentNode)
q.toString
r=A.S(q)}}return null},
fQ(a){var s,r,q,p,o,n,m=null
for(s=t.A,r=a;r!=null;){if(r instanceof A.f&&A.h(r.a.tagName).toUpperCase()==="TABLE"){q=this.b.$1(r)
if(q==null)return m
for(s=q.a4(t.Z),p=s.$ti,s=new A.H(s.a(),p.i("H<1>")),o=t.T,p=p.c;s.l();){n=s.b
if(n==null)n=p.a(n)
if(o.a(n.d).n(0,a))return n}return m}p=r.a
if(s.a(p.parentNode)==null)r=m
else{p=s.a(p.parentNode)
p.toString
r=A.S(p)}}return m},
pI(a,b){var s=A.m(a.a.getAttribute(b)),r=A.V(s==null?"":s,null)
if(r==null)r=1
return Math.max(1,r)},
cL(a){var s=a.gaG()
return s instanceof A.f?s:null},
eM(a){var s,r=a.gcB(),q=t.A
while(!0){if(!(r!=null&&!(r instanceof A.f)))break
s=r.a
if(q.a(s.nextSibling)==null)r=null
else{s=q.a(s.nextSibling)
s.toString
r=A.S(s)}}return t.q.a(r)},
q0(a){var s,r=a.geh(),q=t.A
while(!0){if(!(r!=null&&!(r instanceof A.f)))break
s=r.a
if(q.a(s.previousSibling)==null)r=null
else{s=q.a(s.previousSibling)
s.toString
r=A.S(s)}}return t.q.a(r)},
cK(a){var s
if(a==null)return B.ai
s=t.d0
return A.N(new A.ae(a.gan(),s),!1,s.i("o.E"))},
sny(a){this.d=t.O.a(a)},
snx(a){this.as=t.O.a(a)},
snw(a){this.at=t.O.a(a)}}
A.oy.prototype={
$1(a){var s,r,q,p,o,n
t.f.a(a).a.preventDefault()
s=this.a
r=s.e
if(r==null)return
s.k6()
q=this.b
s.Q=q
if(q)s.lL(!0)
else{q=s.x
p=r.a
if(q!=null)A.aH(q,s.iz(p))
else{q=t.m
o=q.a(s.gcl().a.createElement("div"))
n=new A.f(A.b(t.O,t.g),o)
q.a(o.classList).add("ql-operate-drag-table")
A.aH(n,s.iz(p))
s.x=n
q.a(s.a.a.a.appendChild(o))}}s.f=!0
s.gcl().I("mousemove",s.gjK())
s.gcl().I("mouseup",s.gjJ())},
$S:0}
A.bi.prototype={}
A.cj.prototype={}
A.w7.prototype={
$1(a){return this.a.fn(a)},
$S:6}
A.w8.prototype={
$3(a,b,c){return a.ij(b,c)},
$S:20}
A.vR.prototype={
$1(a){return t.a.a(a).c5(0)},
$S:10}
A.vS.prototype={
$1(a){return t.a.a(a).c5(1)},
$S:10}
A.vT.prototype={
$1(a){return t.a.a(a).dZ()},
$S:10}
A.w_.prototype={
$1(a){var s
t.a.a(a)
s=a.gaB()
if(s!=null)s.mp()
a.bz()
return null},
$S:10}
A.w0.prototype={
$1(a){t.a.a(a)
a.ur()
a.lJ()},
$S:10}
A.w1.prototype={
$1(a){return t.a.a(a).c6(0)},
$S:10}
A.w2.prototype={
$1(a){return t.a.a(a).c6(1)},
$S:10}
A.w3.prototype={
$1(a){return t.a.a(a).e_()},
$S:10}
A.w4.prototype={
$1(a){var s
t.a.a(a)
s=a.gaB()
if(s!=null)s.mq()
a.bz()
return null},
$S:10}
A.w5.prototype={
$1(a){var s
t.a.a(a)
s=a.gaB()
if(s!=null)s.tN()
a.a.b5()
a.bz()},
$S:10}
A.w6.prototype={
$1(a){var s
t.a.a(a)
s=a.gaB()
if(s!=null)s.mG()
a.a.b5()
a.bz()},
$S:10}
A.vU.prototype={
$3(a,b,c){var s
a.ij(b,c)
a.tZ()
s=a.w
s===$&&A.c()
t.m.a(s.a.classList).add("ql-hidden")},
$S:20}
A.vV.prototype={
$3(a,b,c){var s
a.ij(b,c)
a.tY()
s=a.w
s===$&&A.c()
t.m.a(s.a.classList).add("ql-hidden")},
$S:20}
A.vW.prototype={
$1(a){return t.a.a(a).li(-1)},
$S:10}
A.vX.prototype={
$1(a){return t.a.a(a).li(1)},
$S:10}
A.vY.prototype={
$3(a,b,c){return a.e0()},
$S:20}
A.vZ.prototype={
$3(a,b,c){return a.r0()},
$S:20}
A.dk.prototype={
gaB(){var s=this.y
return s==null?null:this.c.$1(s)},
r9(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e
t.nc.a(a)
if(a.length===0)return null
s=this.a.b
s===$&&A.c()
s=s.a
r=t.A
q=t.m
p=q.a(r.a(s.ownerDocument).createElement("ul"))
o=t.O
n=t.g
for(m=a.length,l=0;l<a.length;a.length===m||(0,A.k)(a),++l){k=a[l]
j=q.a(r.a(s.ownerDocument).createElement("li"))
i=new A.f(A.b(o,n),j)
h=k.b
if(k.e){q.a(j.classList).add("ql-table-header-row")
g=q.a(r.a(s.ownerDocument).createElement("span"))
f=q.a(r.a(s.ownerDocument).createElement("span"))
e=q.a(r.a(s.ownerDocument).createElement("span"))
g.textContent=h
q.a(f.classList).add("ql-table-switch")
q.a(e.classList).add("ql-table-switch-inner")
e.setAttribute("aria-checked","false")
q.a(f.appendChild(e))
q.a(j.appendChild(g))
q.a(j.appendChild(f))
this.as=i}else j.textContent=h
i.I("click",new A.qU(this,k))
q.a(p.appendChild(j))
if(k.d){j=q.a(r.a(s.ownerDocument).createElement("li"))
q.a(j.classList).add("ql-table-divider")
q.a(p.appendChild(j))}}q.a(p.classList).add("ql-table-dropdown-list")
q.a(p.classList).add("ql-hidden")
return new A.f(A.b(o,n),p)},
ra(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this,c=d.a,b=c.b
b===$&&A.c()
s=t.A
r=t.m
q=r.a(s.a(b.a.ownerDocument).createElement("div"))
p=t.O
o=t.g
r.a(q.classList).add("ql-table-menus-container")
r.a(q.classList).add("ql-hidden")
n=d.ax
B.a.M(n)
B.a.H(n,A.It(d.b,d.e))
for(m=n.length,l=0;l<n.length;n.length===m||(0,A.k)(n),++l){k=n[l]
j=k.e
i=d.r9(j)
h=A.yh(k.b)
g=k.c
j=j.length
f=r.a(s.a(b.a.ownerDocument).createElement("div"))
e=r.a(s.a(b.a.ownerDocument).createElement("span"))
j=j!==0?g+u.e:g
new A.f(A.b(p,o),e).saf(j)
r.a(f.classList).add("ql-table-dropdown")
r.a(e.classList).add("ql-table-tooltip-hover")
f.setAttribute("data-category",k.a)
r.a(f.appendChild(e))
r.a(f.appendChild(h.a))
if(i!=null)r.a(f.appendChild(i.a))
r.a(q.appendChild(f))
new A.f(A.b(p,o),f).I("click",new A.qV(d,k,i,h))}r.a(c.a.a.appendChild(q))
return new A.f(A.b(p,o),q)},
l5(a,b){var s,r,q=this.pl(a)
if(q==null)return
s=t.m
r=q.a
if(b)s.a(r.classList).add("ql-table-disabled")
else s.a(r.classList).remove("ql-table-disabled")},
ru(a){return this.l5(a,!1)},
ij(a,b){var s,r,q=this,p=q.z
if(p!=null&&!p.n(0,a)){s=t.m
s.a(p.a.classList).add("ql-hidden")
r=q.Q
if(r!=null)s.a(r.a.classList).remove("ql-table-tooltip-hidden")}if(a==null)return
s=t.m
new A.b9(s.a(a.a.classList)).dB("ql-hidden")
new A.b9(s.a(b.a.classList)).dB("ql-table-tooltip-hidden")
q.z=a
q.Q=b},
hM(a){var s,r,q,p,o=this
t.f.a(a)
s=o.a.c
s===$&&A.c()
if(A.m(t.T.a(s.d).a.getAttribute("contenteditable"))!=="true")return
r=o.nV(a.gau())
s=o.z
if(s!=null)t.m.a(s.a.classList).add("ql-hidden")
s=o.Q
if(s!=null)t.m.a(s.a.classList).remove("ql-table-tooltip-hidden")
o.Q=o.z=null
s=r==null
q=s?null:o.c.$1(r)
if(s){p=q==null?null:q.gbc().length===0
p=p!==!1}else p=!1
if(p){s=o.w
s===$&&A.c()
t.m.a(s.a.classList).add("ql-hidden")
o.hC()
return}p=o.w
p===$&&A.c()
t.m.a(p.a.classList).remove("ql-hidden")
o.em(r)
if(!s&&!r.n(0,o.y)||o.at)o.at=!1
o.y=r},
em(a){var s,r,q,p,o,n,m,l,k,j,i,h=this,g=a==null?h.y:a
if(g==null)return
s=h.w
s===$&&A.c()
r=t.m
r.a(s.a.classList).remove("ql-table-triangle-none")
q=h.iv(g)
p=q[0]
o=q[1]
n=A.bn(s,h.a.a)
m=n.e
l=p.b-n.f-10
k=Math.floor((p.a+p.c-m)/2)
if(l>0){r.a(s.a.classList).add("ql-table-triangle-up")
r.a(s.a.classList).remove("ql-table-triangle-down")}else{j=p.d
i=o.f
l=j>i?i+10:j+10
r.a(s.a.classList).add("ql-table-triangle-down")
r.a(s.a.classList).remove("ql-table-triangle-up")}if(k<o.a){r.a(s.a.classList).add("ql-table-triangle-none")
k=0}else{j=o.c
if(k+m>j){k=j-m
r.a(s.a.classList).add("ql-table-triangle-none")}}r=t.N
A.aH(s,A.l(["left",A.af(k)+"px","top",A.af(l)+"px"],r,r))},
bz(){return this.em(null)},
iv(a){var s,r=this.a.a,q=A.bn(r,null),p=A.bn(a,r)
r=p.e
s=q.e
if(r>=s)return A.a([new A.fd(0,p.b,s,p.d,r,p.f),q],t.sa)
return A.a([p,q],t.sa)},
c5(a){var s,r,q,p,o,n,m,l=this,k=l.gaB(),j=l.gaB()
if(j==null)s=null
else{j=j.a
j.toString
s=j}if(k==null||s==null)return
r=k.b
if(r==null)return
j=l.y
q=j==null?null:A.bn(j,l.a.a)
j=a>0
p=r.a
o=j?l.eF(k,p,r.d):l.eF(k,p,r.b)
if(o==null)return
n=A.bw(t.T.a(o.d))
p=o.c
m=j?n.c:n.a
s.tf(m,p==null,n.e,a)
if(q!=null)A.wQ(s,q,72)
l.a.b5()
l.bz()},
c6(a){var s,r,q,p,o,n,m,l=this,k=l.gaB(),j=l.gaB()
if(j==null)s=null
else{j=j.a
j.toString
s=j}if(k==null||s==null)return
r=k.b
if(r==null)return
j=a>0
q=r.b
p=j?l.eF(k,r.c,q):l.eF(k,r.a,q)
if(p==null)return
o=p.dw()
n=p.gA()==="table-th"
if(j){j=A.m(t.T.a(p.d).a.getAttribute("rowspan"))
m=A.V(j==null?"":j,null)
if(m==null)m=1
s.hW(o+a+m-1,a,n)}else s.hW(o+a,a,n)
l.a.b5()
l.bz()},
f0(a8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5=this,a6=a5.gaB(),a7=a5.gaB()
if(a7==null)s=null
else{a7=a7.a
a7.toString
s=a7}if(a6==null||s==null)return
r=a6.b
if(r==null)return
q=a5.y
a7=q==null
p=a7?null:A.bn(q,a5.a.a)
o=t.r
n=A.a([],o)
m=A.a([],t.sQ)
for(l=a5.jT(a6),k=l.length,j=r.b,i=r.d,h=t.T,g=t.p2,f=0;f<l.length;l.length===k||(0,A.k)(l),++f){e=l[f]
d=e.c
c=d+e.e-1
if(d>=j&&c<=i)B.a.k(n,h.a(e.a.d))
else{b=d>j?d:j
a=c<i?c:i
a0=a<b?0:a-b+1
if(a0>0)B.a.k(m,new A.F(h.a(e.a.d),-a0,g))}}l=n.length
if(l===0&&m.length===0)return
if(a8&&l!==a6.gbc().length)return
a1=A.a([],o)
a2=s.dj()
if(a2!=null)for(o=a2.e,l=o.length,a3=0,f=0;f<o.length;o.length===l||(0,A.k)(o),++f){a4=o[f]
if(a4 instanceof A.bZ&&a3>=j&&a3<=i)B.a.k(a1,h.a(a4.d));++a3}if(!a6.lQ("column"))a5.d.$0()
s.rm(m,n,a5.gf1(),a1)
if(!a7&&p!=null)A.wQ(s,p,-(i-j+1)*72)
a5.bz()},
dZ(){return this.f0(!1)},
l1(a){var s,r,q=this,p=q.gaB(),o=q.gaB()
if(o==null)s=null
else{o=o.a
o.toString
s=o}if(p==null||s==null)return
if(p.gbc().length===0)return
r=q.m8()
if(r.length===0)return
if(a)if(B.a.ag(r,0,new A.qW(),t.S)!==p.gbc().length)return
if(!p.lQ("row"))q.d.$0()
s.rn(r,q.gf1())
q.bz()},
e_(){return this.l1(!1)},
e0(){var s,r,q,p,o=this,n=o.gaB()
if(n==null)s=null
else{n=n.a
n.toString
s=n}if(s==null)return
n=o.a
r=n.c
r===$&&A.c()
q=r.aP(s)
s.Y(0)
o.d.$0()
p=o.w
p===$&&A.c()
t.m.a(p.a.classList).add("ql-hidden")
n.ad("user")
n.S(new A.G(B.f.aA(B.d.aC(q-1,0,r.E(0))),0),"user")
o.y=null},
li(a){var s,r,q,p,o,n=this,m=n.gaB()
if(m==null)s=null
else{m=m.a
m.toString
s=m}if(s==null)return
m=n.a
r=m.c
r===$&&A.c()
q=r.aP(s)
p=a>0?s.E(0):0
o=new A.r(A.a([],t.t))
r=q+p
o.a8(r)
o.aE(0,"\n")
m.aM(o,"user")
m.S(new A.G(r,0),"silent")
n.d.$0()
r=n.w
r===$&&A.c()
t.m.a(r.a.classList).add("ql-hidden")
m.b5()},
r0(){var s,r,q,p=this,o=p.gaB(),n=p.gaB()
if(n==null)s=null
else{n=n.a
n.toString
s=n}if(o==null||s==null)return null
r=o.r1()
n=p.a
q=n.c
q===$&&A.c()
n.S(new A.G(q.aP(s)+s.E(0),0),"silent")
p.d.$0()
q=p.w
q===$&&A.c()
t.m.a(q.a.classList).add("ql-hidden")
n.b5()
return r},
ur(){var s,r,q=this.gaB()
if(q==null)return
s=q.hS()
r=s.b
if(!s.a&&r)q.r_()
else q.qZ()},
lK(a){var s,r,q,p=this.as
if(p==null)return
s=p.a_(".ql-table-switch-inner")
if(s.length===0)return
r=B.a.gF(s)
if(a==null)q=A.m(r.a.getAttribute("aria-checked"))==="false"?"true":"false"
else q=a
r.a.setAttribute("aria-checked",q)},
lJ(){return this.lK(null)},
m8(){var s,r,q,p=this.gaB(),o=p==null,n=o?null:p.b
if(o||n==null)return B.e8
s=A.a([],t.BR)
o=p.a.a4(t.H)
r=A.N(o,!0,o.$ti.i("o.E"))
for(q=n.a,o=n.c;q<=o;++q)if(q>=0&&q<r.length){if(!(q>=0&&q<r.length))return A.d(r,q)
B.a.k(s,r[q])}return s},
mh(a){var s,r=A.m(a.a.getAttribute("align"))
if(r!=null&&r.length!==0)return r
s=A.yk(a,B.f2)
if(s.h(0,"margin-left")==="auto")return s.h(0,"margin-right")==="auto"?"center":"right"
return"left"},
fv(a){var s,r=A.yk(t.T.a(a.d),B.dT),q=A.In(a)
if(q.length!==0){s=t.N
s=A.aJ(r,s,s)
s.j(0,"text-align",q)
return s}return r},
mg(a){var s,r,q,p,o,n,m,l
t.x7.a(a)
if(a.length===0)return B.H
s=t.N
r=A.Y(this.fv(B.a.gF(a)),s,s)
q=A.xk(s)
for(s=A.dg(a,1,null,A.K(a).c),p=s.$ti,s=new A.be(s,s.gm(0),p.i("be<ad.E>")),o=A.u(r).i("cx<1>"),p=p.i("ad.E");s.l();){n=s.d
m=this.fv(n==null?p.a(n):n)
for(n=new A.cx(r,r.r,o),n.c=r.e;n.l();){l=n.d
if(q.v(0,l))continue
if(m.h(0,l)!=r.h(0,l))q.k(0,l)}}for(s=A.xU(q,q.r,q.$ti.c),p=s.$ti.c;s.l();){o=s.d
if(o==null)o=p.a(o)
n=B.fI.h(0,o)
r.j(0,o,n==null?"":n)}return r},
um(){var s,r=this.y
if(r==null)return B.H
s=t.N
s=A.aJ(A.yk(r,B.el),s,s)
s.j(0,"align",this.mh(r))
return s},
qQ(){var s=this.gaB(),r=s==null?null:A.cc(s.c,t.Z)
if(r==null)r=B.G
s=r.length
if(s===0)return B.H
return s>1?this.mg(r):this.fv(B.a.gF(r))},
tZ(){this.k5("table",this.um())},
tY(){this.k5("cell",this.qQ())},
k5(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this
t.J.a(b)
d.hC()
s=d.y
if(s==null)return
r=d.iv(s)
q=d.a.a
p=d.gaB()
if(p==null)p=null
else{p=p.a
p.toString}o=d.gaB()
o=o==null?null:A.cc(o.c,t.Z)
if(o==null)o=B.G
n=r[1]
m=r[0]
l=A.a([],t.r)
k=t.N
j=A.Y(b,k,k)
p=new A.kz(new A.qX(q,d.b,new A.qS(d),new A.qT(d),p,o,n,m),a,new A.oP(a,b),j,l,A.b(k,t.zI))
o=p.re()
p.w!==$&&A.ai()
p.w=o
l=t.m
l.a(o.a.classList).remove("ql-table-triangle-none")
i=A.bn(o,q)
h=i.f
g=i.e
f=m.d+10
e=Math.floor((m.a+m.c-g)/2)
if(f+n.b+h>p.qF()){f=m.b-h-10
if(f<0){f=Math.floor((n.f-h)/2)
l.a(o.a.classList).add("ql-table-triangle-none")}else{l.a(o.a.classList).add("ql-table-triangle-up")
l.a(o.a.classList).remove("ql-table-triangle-down")}}else{l.a(o.a.classList).add("ql-table-triangle-down")
l.a(o.a.classList).remove("ql-table-triangle-up")}if(e<n.a){l.a(o.a.classList).add("ql-table-triangle-none")
e=0}else{q=n.c
if(e+g>q){e=q-g
l.a(o.a.classList).add("ql-table-triangle-none")}}A.aH(o,A.l(["left",A.af(e)+"px","top",A.af(f)+"px"],k,k))
d.r=p},
hC(){var s,r=this.r
if(r!=null){s=r.w
s===$&&A.c()
s.Y(0)
B.a.M(r.f)}this.r=null},
pl(a){var s,r,q,p=this.w
p===$&&A.c()
p=p.a_("[data-category]")
s=p.length
r=0
for(;r<p.length;p.length===s||(0,A.k)(p),++r){q=p[r]
if(A.m(q.a.getAttribute("data-category"))===a)return q}return null},
pa(a){var s,r,q,p
for(s=t.A,r=t.m,q=a;q!=null;){if(q instanceof A.f&&A.I(r.a(q.a.classList).contains("ql-table-header-row")))return!0
p=q.a
if(s.a(p.parentNode)==null)q=null
else{p=s.a(p.parentNode)
p.toString
q=A.S(p)}}return!1},
nV(a){var s,r,q,p
for(s=t.A,r=this.a,q=a;q!=null;){if(q instanceof A.f&&A.h(q.a.tagName).toUpperCase()==="TABLE")return q
p=r.b
p===$&&A.c()
if(q.n(0,p))return null
p=q.a
if(s.a(p.parentNode)==null)q=null
else{p=s.a(p.parentNode)
p.toString
q=A.S(p)}}return null},
eF(a,b,c){var s,r,q,p,o,n
for(s=this.jT(a),r=s.length,q=0;q<r;++q){p=s[q]
o=p.b
n=!1
if(o<=b)if(b<o+p.d){o=p.c
o=o<=c&&c<o+p.e}else o=n
else o=n
if(o)return p.a}return null},
jT(a){var s,r,q,p,o,n,m,l,k,j,i,h=A.a([],t.ai),g=t.S,f=A.b(g,g)
g=a.a.a4(t.H)
s=A.N(g,!0,g.$ti.i("o.E"))
for(r=0;r<s.length;++r)for(g=s[r].e,q=g.length,p=0,o=0;o<g.length;g.length===q||(0,A.k)(g),++o){n=g[o]
if(!(n instanceof A.a6))continue
while(!0){m=f.h(0,p)
if(!((m==null?-1:m)>=r))break;++p}l=this.kx(n,"rowspan")
k=this.kx(n,"colspan")
B.a.k(h,new A.l5(n,r,p,l,k))
for(m=l>1,j=r+l-1,i=0;i<k;++i)if(m)f.j(0,p+i,j)
p+=k}return h},
kx(a,b){var s=A.m(t.T.a(a.d).a.getAttribute(b)),r=A.V(s==null?"":s,null)
if(r==null)r=1
return r<1?1:r},
snA(a){this.x=t.O.a(a)}}
A.qU.prototype={
$1(a){t.f.a(a)
return this.b.c.$1(this.a)},
$S:0}
A.qV.prototype={
$1(a){var s=this,r=s.a
if(r.pa(t.f.a(a).gau()))return
s.b.d.$3(r,s.c,s.d)},
$S:0}
A.qW.prototype={
$2(a,b){return A.v(a)+t.H.a(b).e.length},
$S:196}
A.qS.prototype={
$0(){var s,r=this.a
r.r=null
s=r.w
s===$&&A.c()
t.m.a(s.a.classList).remove("ql-hidden")
r.bz()},
$S:1}
A.qT.prototype={
$0(){return this.a.a.ad("user")},
$S:1}
A.l5.prototype={}
A.qX.prototype={
gct(){return this.a}}
A.kz.prototype={
qy(a){return this.a.b.fn(a)},
re(){var s,r,q,p=this,o=A.Iu(p.c,p.gqx()),n=p.a.a.a,m=t.A,l=t.m,k=l.a(m.a(n.ownerDocument).createElement("div"))
l.a(k.classList).add("ql-table-properties-form")
m=l.a(m.a(n.ownerDocument).createElement("h2"))
m.textContent=o.a
l.a(m.classList).add("properties-form-header")
l.a(k.appendChild(m))
for(m=o.b,s=m.length,r=0;r<m.length;m.length===s||(0,A.k)(m),++r)l.a(k.appendChild(p.rf(m[r]).a))
q=p.kX(new A.r8(p),!0)
l.a(k.appendChild(q.a))
p.mr()
l.a(n.appendChild(k))
p.my(q)
return new A.f(A.b(t.O,t.g),k)},
rf(a){var s,r,q,p,o,n,m=this.a,l=m.a.a,k=t.A,j=t.m,i=j.a(k.a(l.ownerDocument).createElement("div"))
l=j.a(k.a(l.ownerDocument).createElement("label"))
k=a.a
l.textContent=k
j.a(l.classList).add("ql-table-dropdown-label")
j.a(i.classList).add("properties-form-row")
s=a.b
if(s.length===1)j.a(i.classList).add("properties-form-row-full")
j.a(i.appendChild(l))
for(l=s.length,m=m.b,r=this.f,q=0;q<s.length;s.length===l||(0,A.k)(s),++q){p=this.rg(s[q])
if(p==null)continue
j.a(i.appendChild(p.a))
o=m.a
o===$&&A.c()
n=m.b
n===$&&A.c()
n=o.h(0,n)
o=n==null?null:n.h(0,"border")
if(k===(o==null?"":o))B.a.k(r,p)}return new A.f(A.b(t.O,t.g),i)},
rg(a){var s,r,q,p=this
switch(a.a){case"dropdown":return p.r8(a)
case"color":s=t.m
r=s.a(t.A.a(p.a.a.a.ownerDocument).createElement("div"))
s.a(r.classList).add("ql-table-color-container")
r.setAttribute("data-property",a.b)
q=p.kZ(a).a
s.a(q.classList).add("label-field-view-color")
s.a(r.appendChild(q))
s.a(r.appendChild(p.r5(a).a))
return new A.f(A.b(t.O,t.g),r)
case"menus":return p.r3(a)
case"input":return p.kZ(a)
default:return null}},
r8(a){var s,r,q,p,o,n=this.a.a.a,m=t.A,l=t.m,k=l.a(m.a(n.ownerDocument).createElement("div")),j=t.O,i=t.g,h=new A.f(A.b(j,i),k),g=l.a(m.a(n.ownerDocument).createElement("span")),f=new A.f(A.b(j,i),g),e=l.a(m.a(n.ownerDocument).createElement("span"))
new A.f(A.b(j,i),e).saf(u.e)
l.a(e.classList).add("ql-table-dropdown-icon")
s=a.c
if(s!=null)g.textContent=s
l.a(k.classList).add("ql-table-dropdown-properties")
l.a(g.classList).add("ql-table-dropdown-text")
l.a(k.appendChild(g))
l.a(k.appendChild(e))
r=a.d
if(r==null)r=B.i
g=r.length
if(g!==0){e=l.a(m.a(n.ownerDocument).createElement("ul"))
q=new A.f(A.b(j,i),e)
for(p=0;p<g;++p){o=r[p]
j=l.a(m.a(n.ownerDocument).createElement("li"))
j.textContent=o
l.a(e.appendChild(j))}l.a(e.classList).add("ql-table-dropdown-list")
l.a(e.classList).add("ql-hidden")
q.I("click",new A.r3(this,f,a,h))
l.a(k.appendChild(e))
h.I("click",new A.r4(this,q,h,f))}return h},
kZ(a){var s,r,q=this.a.a.a,p=t.A,o=t.m,n=o.a(p.a(q.ownerDocument).createElement("div")),m=t.O,l=t.g,k=new A.f(A.b(m,l),n),j=o.a(p.a(q.ownerDocument).createElement("div")),i=o.a(p.a(q.ownerDocument).createElement("label")),h=o.a(p.a(q.ownerDocument).createElement("input")),g=new A.f(A.b(m,l),h)
q=o.a(p.a(q.ownerDocument).createElement("div"))
o.a(n.classList).add("label-field-view")
n.setAttribute("data-property",a.b)
o.a(j.classList).add("label-field-view-input-wrapper")
p=a.e
s=p==null
r=s?null:p.h(0,"placeholder")
if(r==null)r=""
i.textContent=r
if(!s)A.f6(g,p)
o.a(h.classList).add("property-input")
p=a.c
g.scc(p==null?"":p)
g.I("input",new A.r5(this,a,k,new A.f(A.b(m,l),j),new A.f(A.b(m,l),q)))
o.a(q.classList).add("label-field-view-status")
o.a(q.classList).add("ql-hidden")
p=a.r
if(p!=null)q.textContent=p
o.a(j.appendChild(h))
o.a(j.appendChild(i))
o.a(n.appendChild(j))
if(a.f!=null)o.a(n.appendChild(q))
return k},
r5(a){var s,r,q,p=this.a.a.a,o=t.A,n=t.m,m=n.a(o.a(p.ownerDocument).createElement("span")),l=t.O,k=t.g
p=n.a(o.a(p.ownerDocument).createElement("span"))
s=new A.f(A.b(l,k),p)
n.a(m.classList).add("color-picker")
n.a(p.classList).add("color-button")
r=a.c
if(r!=null&&r.length!==0){o=t.N
A.aH(s,A.l(["background-color",r],o,o))}else n.a(p.classList).add("color-unselected")
q=this.r6(a.b)
s.I("click",new A.r2(this,q))
n.a(m.appendChild(p))
n.a(m.appendChild(q.a))
return new A.f(A.b(l,k),m)},
r6(a){var s=this,r=s.a,q=t.m,p=q.a(t.A.a(r.a.a.ownerDocument).createElement("div")),o=new A.f(A.b(t.O,t.g),p)
q.a(p.classList).add("color-picker-select")
q.a(p.classList).add("ql-hidden")
q.a(p.appendChild(s.kY(u.h,r.b.fn("removeColor"),new A.r1(s,a)).a))
q.a(p.appendChild(s.r4(a).a))
q.a(p.appendChild(s.rd(a,o).a))
return o},
rd(a,b){var s,r,q=this,p=q.a,o=p.a.a,n=t.A,m=t.m,l=m.a(n.a(o.ownerDocument).createElement("div")),k=t.O,j=t.g,i=m.a(n.a(o.ownerDocument).createElement("div")),h=new A.f(A.b(k,j),i),g=m.a(n.a(o.ownerDocument).createElement("div"))
o=n.a(o.ownerDocument)
o.toString
n=q.c.b.h(0,a)
n=A.Dr(n==null?"":n)
if(n==null)n=B.cj
s=new A.jn(new A.bu(o),n)
n=s.nK()
s.x!==$&&A.ai()
s.x=n
s.ki()
q.x.j(0,a,s)
r=q.kX(new A.r6(q,a,s,b,h),!1)
m.a(i.classList).add("color-picker-palette")
m.a(i.classList).add("ql-hidden")
m.a(g.classList).add("color-picker-wrap")
m.a(n.a.classList).add("iro-container")
m.a(g.appendChild(n.a))
m.a(g.appendChild(r.a))
m.a(i.appendChild(g))
m.a(l.appendChild(q.kY(u.j,p.b.fn("colorPicker"),new A.r7(q,h)).a))
m.a(l.appendChild(i))
return new A.f(A.b(k,j),l)},
r4(a){var s,r,q,p,o,n,m,l,k=this.a,j=k.a.a,i=t.A,h=t.m,g=h.a(i.a(j.ownerDocument).createElement("ul")),f=t.O,e=t.g
h.a(g.classList).add("color-list")
for(s=t.N,k=k.b,r=0;r<15;++r){q=B.d2[r]
p=h.a(i.a(j.ownerDocument).createElement("li"))
o=new A.f(A.b(f,e),p)
n=q.b
p.setAttribute("data-color",n)
h.a(p.classList).add("ql-table-tooltip-hover")
n=A.l(["background-color",n],s,s)
m=A.d1(o)
m.H(0,n)
A.he(o,m)
n=k.a
n===$&&A.c()
l=k.b
l===$&&A.c()
l=n.h(0,l)
n=l==null?null:l.h(0,q.a)
h.a(p.appendChild(A.yh(n==null?"":n).a))
o.I("click",new A.r_(this,a,q))
h.a(g.appendChild(p))}return new A.f(A.b(f,e),g)},
kY(a,b,c){var s,r,q,p,o,n,m,l
t.R.a(c)
s=this.a.a.a
r=t.A
q=t.m
p=q.a(r.a(s.ownerDocument).createElement("div"))
o=t.O
n=t.g
m=new A.f(A.b(o,n),p)
l=q.a(r.a(s.ownerDocument).createElement("span"))
s=q.a(r.a(s.ownerDocument).createElement("button"))
new A.f(A.b(o,n),l).saf(a)
s.textContent=b
s.setAttribute("type","button")
q.a(p.classList).add("erase-container")
q.a(p.appendChild(l))
q.a(p.appendChild(s))
m.I("click",new A.r0(c))
return m},
r3(a){var s,r,q,p,o,n,m,l,k,j,i=this.a.a.a,h=t.A,g=t.m,f=g.a(h.a(i.ownerDocument).createElement("div")),e=t.O,d=t.g,c=new A.f(A.b(e,d),f)
g.a(f.classList).add("ql-table-check-container")
s=a.b
f.setAttribute("data-property",s)
r=a.w
if(r==null)r=B.e2
q=r.length
p=this.c.b
o=0
for(;o<r.length;r.length===q||(0,A.k)(r),++o){n=r[o]
m=g.a(h.a(i.ownerDocument).createElement("span"))
l=new A.f(A.b(e,d),m)
k=n.a
j=B.bh.h(0,k)
l.saf(j==null?k:j)
k=n.c
m.setAttribute("data-align",k)
g.a(m.classList).add("ql-table-tooltip-hover")
if(p.h(0,s)===k)g.a(m.classList).add("ql-table-btns-checked")
g.a(m.appendChild(A.yh(n.b).a))
l.I("click",new A.qZ(this,c,l,a,n))
g.a(f.appendChild(m))}return c},
kX(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d
t.ma.a(a)
s=this.a
r=s.a.a
q=t.A
p=t.m
o=p.a(q.a(r.ownerDocument).createElement("div"))
n=t.O
m=t.g
p.a(o.classList).add("properties-form-action-row")
for(l=t.N,s=s.b,k=0;k<2;++k){j=B.dM[k]
i=p.a(q.a(r.ownerDocument).createElement("button"))
h=new A.f(A.b(n,m),i)
g=p.a(q.a(r.ownerDocument).createElement("span"))
f=B.bh.h(0,j.a)
if(f==null)f=""
new A.f(A.b(n,m),g).saf(f)
p.a(i.appendChild(g))
g=j.b
A.f6(h,A.l(["label",g,"type","button"],l,l))
if(b){f=p.a(q.a(r.ownerDocument).createElement("span"))
e=s.a
e===$&&A.c()
d=s.b
d===$&&A.c()
d=e.h(0,d)
g=d==null?null:d.h(0,g)
if(g==null)g=""
f.textContent=g
p.a(i.appendChild(f))}h.I("click",new A.qY(a,j))
p.a(o.appendChild(i))}return new A.f(A.b(n,m),o)},
fB(a,b,c){var s,r,q=this
q.e.j(0,a,b)
if(B.b.v(a,"-color")){if(c==null)s=q.fY(a)
else{r=q.fV(c,"ql-table-color-container")
s=r==null?q.fY(a):r}if(s!=null)q.lP(s,b)}},
fA(a,b){return this.fB(a,b,null)},
iN(a,b){var s
this.fA(a,b)
s=this.fY(a)
if(s!=null)this.io(s,!1,!0)},
lP(a,b){var s,r,q,p,o,n,m,l=a.a_(".color-button")
if(l.length!==0){s=B.a.gF(l)
r=t.m
q=s.a
if(b.length===0)r.a(q.classList).add("color-unselected")
else r.a(q.classList).remove("color-unselected")
r=t.N
A.aH(s,A.l(["background-color",b],r,r))}p=a.a_(".property-input")
if(p.length!==0)B.a.gF(p).scc(b)
for(r=a.a_(".color-picker-select"),q=r.length,o=t.m,n=0;n<r.length;r.length===q||(0,A.k)(r),++n)o.a(r[n].a.classList).add("ql-hidden")
m=a.a_(".label-field-view-status")
if(m.length!==0){r=B.a.gF(m)
this.jd(r,b.length===0||A.BO(b))}},
lR(a,b,c){var s,r,q,p,o,n,m=c==="color",l=a.a_(m?".color-list":".ql-table-dropdown-list")
if(l.length===0)return
s=B.a.gF(l).a_("li")
for(r=s.length,q=t.m,p="ql-table-"+c+"-selected",o=0;n=s.length,o<n;s.length===r||(0,A.k)(s),++o)q.a(s[o].a.classList).remove(p)
for(o=0;o<s.length;s.length===n||(0,A.k)(s),++o){r=s[o].a
if((m?A.m(r.getAttribute("data-color")):A.m(r.textContent))===b){q.a(r.classList).add(p)
break}}},
n8(a,b){var s,r,q,p
for(s=a.a_("span"),r=s.length,q=t.m,p=0;p<s.length;s.length===r||(0,A.k)(s),++p)q.a(s[p].a.classList).remove("ql-table-btns-checked")
q.a(b.a.classList).add("ql-table-btns-checked")},
jd(a,b){var s=t.m,r=a.a
if(b)s.a(r.classList).add("ql-hidden")
else s.a(r.classList).remove("ql-hidden")},
io(a,b,c){var s,r,q,p,o=this
if(c){s=o.fV(a,"ql-table-color-container")
r=s==null?a:s}else{s=o.fV(a,"label-field-view")
r=s==null?a:s}q=r.a_(".label-field-view-input-wrapper")
p=q.length===0?r:B.a.gF(q)
if(b){t.m.a(p.a.classList).add("label-field-view-error")
o.iT(!0)
return}t.m.a(p.a.classList).remove("label-field-view-error")
s=o.w
s===$&&A.c()
if(s.a_(".label-field-view-error").length===0)o.iT(!1)},
uA(a,b){return this.io(a,b,!1)},
my(a){var s,r,q,p
for(s=a.a_("button"),r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q]
if(A.m(p.a.getAttribute("label"))==="save"){this.r=p
return}}},
iT(a){var s,r=this.r
if(r==null)return
s=r.a
if(a)s.setAttribute("disabled","true")
else s.removeAttribute("disabled")},
mr(){var s,r=this.f
if(r.length===0)return
s=B.a.gF(r).a_(".ql-table-dropdown-text")
if(s.length===0)r=""
else{r=A.m(B.a.gF(s).a.textContent)
if(r==null)r=""}this.lI(r)},
lI(a){var s,r,q,p=this.f
if(p.length<3)return
s=p[1]
r=p[2]
if(a.length===0||a==="none"){p=this.e
p.j(0,"border-color","")
p.j(0,"border-width","")
this.lP(s,"")
q=r.a_(".property-input")
if(q.length!==0)B.a.gF(q).scc("")
p=t.m
p.a(s.a.classList).add("ql-table-disabled")
p.a(r.a.classList).add("ql-table-disabled")}else{p=t.m
p.a(s.a.classList).remove("ql-table-disabled")
p.a(r.a.classList).remove("ql-table-disabled")}},
iy(){var s,r,q,p=t.N,o=A.b(p,p)
for(p=this.e.gao(),p=p.gJ(p),s=this.c.b;p.l();){r=p.gq()
q=r.b
r=r.a
if(J.A(q,s.h(0,r)))continue
o.j(0,r,A.IL(r)?A.HG(q):q)}return o},
m2(a,b){var s,r
t.J.a(b)
s=t.N
s=A.aJ(A.d1(a),s,s)
s.H(0,b)
r=new A.a_("")
s.O(0,new A.r9(r))
s=r.a
return s.charCodeAt(0)==0?s:s},
mm(){var s,r,q,p=this.a.e
if(p==null)return
s=this.iy()
switch(s.Z(0,"align")){case"center":s.j(0,"margin","0 auto")
break
case"left":s.j(0,"margin","")
break
case"right":s.j(0,"margin-left","auto")
s.j(0,"margin-right","")
break
default:break}if(s.a===0)return
r=p.eK(t.qk)
q=r==null?null:t.T.a(r.d)
A.aH(q==null?t.T.a(p.d):q,s)},
ml(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this.a.f,a=b.length
if(a===0)return
s=this.iy()
r=s.Z(0,"text-align")
for(q=t.N,p=t.T,o=t.z,n=0;n<a;++n){m=b[n]
if(r!=null){l=r==="left"?"":r
k=m.e
k=A.a(k.slice(0),A.K(k))
j=k.length
i=0
for(;i<k.length;k.length===j||(0,A.k)(k),++i){h=k[i]
if(h instanceof A.b8){g=h.e
g=A.a(g.slice(0),A.K(g))
f=g.length
e=0
for(;e<g.length;g.length===f||(0,A.k)(g),++e)g[e].N("align",l)}else h.N("align",l)}}if(s.a===0)continue
d=m.gA()
k=m.gA()
j=p.a(m.d)
k=A.l([k,A.eH(j)],q,o).h(0,d)
k=k==null?null:new A.d5(k,A.u(k).i("d5<P.K,P.V,e,e>"))
c=A.Y(k==null?B.H:k,q,q)
c.j(0,"style",this.m2(j,s))
A.bo(m,d,c)}},
qF(){var s,r=$.y(),q=this.a.a.a,p=t.A,o=p.a(q.ownerDocument)
o.toString
s=r.a.iF(new A.bu(o)).h(0,"height")
if(s==null)s=0
if(s>0)return s
return A.v(p.a(p.a(q.ownerDocument).documentElement).clientHeight)},
fY(a){var s,r,q,p=this.w
p===$&&A.c()
p=p.a_("[data-property]")
s=p.length
r=0
for(;r<p.length;p.length===s||(0,A.k)(p),++r){q=p[r]
if(A.m(q.a.getAttribute("data-property"))===a)return q}return null},
fV(a,b){var s,r,q,p
for(s=t.A,r=t.m,q=a;q!=null;){if(q instanceof A.f&&A.I(r.a(q.a.classList).contains(b)))return q
p=q.a
if(s.a(p.parentNode)==null)q=null
else{p=s.a(p.parentNode)
p.toString
q=A.S(p)}}return null},
qA(a,b){var s,r,q
for(s=t.A,r=a;r!=null;){if(r instanceof A.f&&A.h(r.a.tagName).toUpperCase()===b)return r
q=r.a
if(s.a(q.parentNode)==null)r=null
else{q=s.a(q.parentNode)
q.toString
r=A.S(q)}}return null},
gb_(){return this.b}}
A.r8.prototype={
$1(a){var s,r=this.a
if(a==="save"){if(r.b==="table")r.mm()
else r.ml()
r.a.d.$0()}s=r.w
s===$&&A.c()
s.Y(0)
B.a.M(r.f)
r.a.c.$0()
return null},
$S:68}
A.r3.prototype={
$1(a){var s,r=this,q=r.a,p=q.qA(t.f.a(a).gau(),"LI")
if(p==null)return
s=A.m(p.a.textContent)
if(s==null)s=""
r.b.a.textContent=s
q.lI(s)
q.fA(r.c.b,s)
q.lR(r.d,s,"dropdown")},
$S:0}
A.r4.prototype={
$1(a){var s,r=this
t.f.a(a)
new A.b9(t.m.a(r.b.a.classList)).dB("ql-hidden")
s=A.m(r.d.a.textContent)
if(s==null)s=""
r.a.lR(r.c,s,"dropdown")},
$S:0}
A.r5.prototype={
$1(a){var s=this,r=t.f.a(a).gau(),q=r instanceof A.f?r.gcc():"",p=s.a,o=s.b,n=o.f
if(n!=null){p.jd(s.e,n.$1(q))
p.uA(s.d,!A.ac(n.$1(q)))}p.fB(o.b,q,s.c)},
$S:0}
A.r2.prototype={
$1(a){t.f.a(a)
return new A.b9(t.m.a(this.b.a.classList)).dB("ql-hidden")},
$S:0}
A.r1.prototype={
$0(){return this.a.iN(this.b,"")},
$S:1}
A.r6.prototype={
$1(a){var s,r,q=this
if(a==="save"){s=q.a
r=q.d
s.fB(q.b,q.c.z.gt3(),r)
s.io(r,!1,!0)}s=t.m
s.a(q.e.a.classList).add("ql-hidden")
s.a(q.d.a.classList).add("ql-hidden")},
$S:68}
A.r7.prototype={
$0(){return new A.b9(t.m.a(this.b.a.classList)).dB("ql-hidden")},
$S:1}
A.r_.prototype={
$1(a){t.f.a(a)
return this.a.iN(this.b,this.c.b)},
$S:0}
A.r0.prototype={
$1(a){t.f.a(a)
return this.a.$0()},
$S:0}
A.qZ.prototype={
$1(a){var s,r=this
t.f.a(a)
s=r.a
s.n8(r.b,r.c)
s.fA(r.d.b,r.e.c)},
$S:0}
A.qY.prototype={
$1(a){t.f.a(a)
return this.a.$1(this.b.b)},
$S:0}
A.r9.prototype={
$2(a,b){this.a.a+=A.h(a)+": "+A.h(b)+"; "
return null},
$S:29}
A.e_.prototype={
gA(){return"table-better"},
gT(){return 3},
a1(){var s=t.m.a(t.T.a(this.d).a.cloneNode(!1))
return new A.e_(A.a([],t.E),new A.f(A.b(t.O,t.g),s))}}
A.rc.prototype={
r7(){var s,r,q,p,o,n,m,l,k=this,j=k.a,i=j.cN("div"),h=j.cN("div"),g=j.cN("div")
for(s=k.d,r=h.a,q=t.m,p=1;p<=10;++p)for(o=""+p,n=1;n<=10;++n){m=j.cN("span")
l=m.a
l.setAttribute("row",o)
l.setAttribute("column",""+n)
B.a.k(s,m)
q.a(r.appendChild(l))}j=g.a
j.textContent="0 x 0"
s=i.a
q.a(s.classList).add("ql-table-select-container")
q.a(s.classList).add("ql-hidden")
q.a(r.classList).add("ql-table-select-list")
q.a(j.classList).add("ql-table-select-label")
q.a(s.appendChild(r))
q.a(s.appendChild(j))
k.e!==$&&A.ai()
k.e=g
i.I("mousemove",new A.rd(k))
return i},
iE(a){var s,r=a.a,q=A.m(r.getAttribute("row")),p=A.V(q==null?"":q,null)
if(p==null)p=0
r=A.m(r.getAttribute("column"))
s=A.V(r==null?"":r,null)
return new A.ao(p,s==null?0:s)},
iP(a){var s,r
if(a==null){s=this.e
s===$&&A.c()
s.a.textContent="0 x 0"
return}r=this.iE(a)
s=this.e
s===$&&A.c()
s.a.textContent=""+r.a+" x "+r.b},
hu(a){var s,r,q
t.ag.a(a)
s=a.length
r=t.m
q=0
for(;q<a.length;a.length===s||(0,A.k)(a),++q)r.a(a[q].a.classList).remove("ql-cell-selected")
this.skV(B.ai)
this.iP(null)},
m4(a,b){var s,r,q,p,o,n=A.a([],t.r)
for(s=this.d,r=s.length,q=0;q<s.length;s.length===r||(0,A.k)(s),++q){p=s[q]
o=A.bw(p)
if(a>=o.a&&b>=o.b)B.a.k(n,p)}return n},
hO(a){var s
if(!(a instanceof A.bB))return
s=a.a
this.t7(this.m4(A.v(s.clientX),A.v(s.clientY)))},
t7(a){var s,r,q,p=this
t.u.a(a)
p.hu(p.c)
for(s=a.length,r=t.m,q=0;q<a.length;a.length===s||(0,A.k)(a),++q)r.a(a[q].a.classList).add("ql-cell-selected")
p.skV(a)
p.iP(a.length===0?null:B.a.gK(a))},
m3(a){var s,r,q=t.A,p=t.m,o=a,n=null
while(!0){if(!(o!=null)){s=!1
break}if(o instanceof A.f){if(n==null&&A.I(o.a.hasAttribute("row")))n=o
if(A.I(p.a(o.a.classList).contains("ql-table-select-container"))){s=!0
break}}r=o.a
if(q.a(r.parentNode)==null)o=null
else{r=q.a(r.parentNode)
r.toString
o=A.S(r)}}if(s&&n==null)return B.jH
return new A.ao(!1,n)},
rK(a,b){var s,r,q,p,o=this
t.xx.a(b)
s=o.m3(a)
r=s.b
if(!s.a)o.hu(o.c)
q=o.b
q===$&&A.c()
new A.b9(t.m.a(q.a.classList)).dB("ql-hidden")
if(r==null){q=o.c
p=q.length===0?null:B.a.gK(q)
if(p!=null)o.c7(p,b)
return}o.c7(r,b)},
c7(a,b){var s
t.T.a(a)
t.xx.a(b)
s=this.iE(a)
b.$2(s.a,s.b)
this.bF()},
bF(){this.hu(this.c)
var s=this.b
s===$&&A.c()
t.m.a(s.a.classList).add("ql-hidden")},
skV(a){this.c=t.u.a(a)}}
A.rd.prototype={
$1(a){return this.a.hO(t.f.a(a))},
$S:0}
A.fd.prototype={}
A.uA.prototype={
$1(a){var s=this.a.h(0,a)
if(s==null)s=null
return s==null?0:s},
$S:198}
A.vM.prototype={
$1(a){var s,r,q,p,o="ql-align-"
for(s=new A.b9(t.m.a(t.T.a(a.d).a.classList)).gak(),r=s.length,q=0;q<r;++q){p=s[q]
if(B.b.a0(p,o)){s=p.split(o)
if(1>=s.length)return A.d(s,1)
return s[1]}}return"left"},
$S:199}
A.vN.prototype={
$2(a,b){if(a==null)return!0
return a===b},
$S:200}
A.vO.prototype={
$1(a){var s,r=a.eq(0)
r.toString
s=A.D('ql-cell-[^"]*',!0,!1)
r=B.b.b8(A.O(r,s,""),A.D('ql-table-[^"]*',!0,!1),"")
s=A.D('table-list(?:[^"]*)?',!0,!1)
return A.O(r,s,"")},
$S:18}
A.vP.prototype={
$1(a){var s=this.a.h(0,a)
if(s!=null&&s.length!==0)return s
return $.y().a.dC(this.b,a)},
$S:6}
A.vv.prototype={
$1(a){t.AT.a(a)
return A.p(a.a)+": "+A.p(a.b)+";"},
$S:201}
A.wA.prototype={
$1(a){var s=A.V(B.b.R(A.h(a)),null)
return B.b.ai(B.d.ac(s==null?0:s,16),2,"0")},
$S:6}
A.wB.prototype={
$1(a){return B.b.R(A.h(a))},
$S:6}
A.hs.prototype={
jf(a,b){var s,r=$.y().a.a
r===$&&A.c()
s=A.l_()
s.b=new A.lT(this,r,a,s)
r=t.A.a(t.m.a(self.document).body)
r.toString
new A.f(A.b(t.O,t.g),r).I("click",s.bP())},
cp(a){var s,r,q,p=this,o=p.c
if(o.p(a))return o.h(0,a)
s=p.b.d
r=s.h(0,a)
switch(a){case"toolbar":q=A.EB(p.a,p.pv(r))
o.j(0,a,q)
p.f5(q)
p.q8(q)
return q
case"keyboard":s.j(0,a,p.pt(r))
break
case"history":s.j(0,a,p.pr(r))
break
case"clipboard":s.j(0,a,p.pp(r))
break
case"uploader":s.j(0,a,A.xL(r))
break
default:break}return p.n2(a)},
f5(a){},
lu(a,b){var s=a.b.b
return s!=null&&s.p(b)},
lj(a){if(a==null||J.A(a,!1))return!0
if(typeof a=="string"&&a.length===0)return!0
return!1},
q8(a){var s=a.e
if(!s.p("formula"))s.j(0,"formula",t.V.a(new A.lK(this)))
if(!s.p("video"))s.j(0,"video",t.V.a(new A.lL(this)))
if(!s.p("image"))s.j(0,"image",t.V.a(new A.lM(this,a)))},
jM(){var s,r,q,p="uploader",o=this.c,n=o.h(0,p)
if(n instanceof A.dp)return n
s=this.b.d
r=A.xL(s.h(0,p))
q=A.Am(this.a,r)
o.j(0,p,q)
s.j(0,p,r)
return q},
pv(a){var s,r,q,p,o=null,n="container"
if(a instanceof A.fL)return a
s=o
if(a instanceof A.fK)r=a
else{q=t.j
if(q.b(a)){q=J.el(a,new A.lG(),q)
r=new A.fK(A.N(q,!0,q.$ti.i("ad.E")))}else{q=t.G
if(q.b(a)){r=a.p(n)?a.h(0,n):o
p=a.h(0,"handlers")
s=q.b(p)?p.bo(0,new A.lH(),t.N,t.V):o}else r=a!=null?a:o}}q=t.j
if(q.b(r)){q=J.el(r,new A.lI(),q)
r=new A.fK(A.N(q,!0,q.$ti.i("ad.E")))}return new A.fL(r,s)},
pt(a){var s,r="bindings"
if(a instanceof A.cb)return a
s=t.P
if(s.b(a)){s=s.b(a.h(0,r))?s.a(a.h(0,r)):B.t
return new A.cb(A.Y(s,t.N,t.z))}return new A.cb(A.b(t.N,t.z))},
pr(a){var s,r,q
if(a instanceof A.cu)return a
if(t.G.b(a)){s=A.lk(a.h(0,"delay"))
if(s==null)s=1000
r=A.lk(a.h(0,"maxStack"))
if(r==null)r=100
q=A.f1(a.h(0,"userOnly"))
q!=null
return new A.cu(s,r,q===!0)}return new A.cu(1000,100,!1)},
pp(a){var s
if(a instanceof A.bp)return a
if(t.G.b(a)){s=a.h(0,"matchers")
return new A.bp(t.j.b(s)?A.a5(s,!0,t.z):B.r)}return new A.bp(B.r)},
of(a){var s,r,q,p
for(s=new A.b9(t.m.a(a.a.classList)).gak(),r=s.length,q=0;q<r;++q){p=s[q]
if(B.b.a0(p,"ql-"))return B.b.L(p,3)}return null},
kN(a5,a6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4
t.u.a(a5)
t.P.a(a6)
for(s=a5.length,r=t.G,q=t.s,p=t.Ag,o=t.vY,n=0;n<a5.length;a5.length===s||(0,A.k)(a5),++n){m=a5[n]
l=m.a
k=A.m(l.getAttribute("class"))
if(k==null||k.length===0)continue
j=J.CS(k,A.D("\\s+",!0,!1))
h=j.length
g=0
while(!0){i=!0
if(!(g<j.length)){i=!1
break}c$1:{f=j[g]
if(!B.b.a0(f,"ql-"))break c$1
e=B.b.L(f,3)
d=a6.h(0,e)
if(d==null)break c$1
if(e==="direction"&&r.b(d)){c=d.h(0,"")
b=c==null?null:J.L(c)
if(b==null)b=""
c=d.h(0,"rtl")
a=c==null?null:J.L(c)
a0=new A.an(A.a([b,a==null?"":a],q),p.a(new A.lN()),o).ab(0," ")
if(a0.length!==0){m.saf(a0)
break}}else if(typeof d=="string"){m.saf(d)
break}else if(r.b(d)){a1=A.m(l.getAttribute("value"))
if(a1==null)a1=""
if(a1.length!==0){a2=d.h(0,a1)
if(a2!=null){m.saf(J.L(a2))
break}}a3=d.h(0,"")
if(a3==null)a3=d.h(0,!1)
if(a3!=null){m.saf(J.L(a3))
break}}}j.length===h||(0,A.k)(j);++g}if(!i){a4=A.m(l.getAttribute("aria-label"))
if(a4!=null&&a4.length!==0){a3=J.yU(B.a.gK(a4.split(":")))
if(a3.length!==0)m.saf(B.b.t(a3,0,1).toUpperCase())}}}},
kO(a,b,c){var s=this
t.u.a(b)
t.P.a(c)
s.su1(A.a([],t.a2))
B.a.O(b,new A.lQ(s,c,a))
s.a.d.av("editor-change",new A.lR(new A.lS(s)))},
su1(a){this.f=t.DT.a(a)},
gil(){return this.r}}
A.lT.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j
t.f.a(a)
s=self
r=t.m
q=t.A
p=q.a(r.a(s.document).body)
p.toString
o=t.O
n=t.g
m=this.c
l=m.b
l===$&&A.c()
if(!new A.f(A.b(o,n),p).v(0,l)){s=q.a(r.a(s.document).body)
s.toString
new A.f(A.b(o,n),s).ca("click",this.d.bP())
return}s=this.a
k=s.r
if(k!=null&&!k.c.v(0,a.gau())){if(k instanceof A.cL){r=k.e
j=r!=null&&$.y().a.lc(r)}else j=!1
if(!j){r=m.f
r===$&&A.c()
r=!r.dn()}else r=!1
if(r){k.r=!1
k.cJ()}}s=s.f
if(s!=null)B.a.O(s,new A.lF(a))},
$S:0}
A.lF.prototype={
$1(a){var s
t.Eh.a(a)
s=a.c
s===$&&A.c()
if(!s.v(0,this.a.gau()))a.di()},
$S:69}
A.lK.prototype={
$1(a){var s=this.a.r
if(s instanceof A.cL)s.hG("formula")},
$S:5}
A.lL.prototype={
$1(a){var s=this.a.r
if(s instanceof A.cL)s.hG("video")},
$S:5}
A.lM.prototype={
$1(a){var s,r,q,p,o,n,m,l=this.b.c
if(l==null)return
s=this.a
r=s.jM()
q=l.aI('input.ql-image[type="file"]')
if(q==null){p=l.a
o=t.m
n=o.a(t.A.a(p.ownerDocument).createElement("input"))
q=new A.f(A.b(t.O,t.g),n)
n.setAttribute("type","file")
o.a(n.classList).add("ql-image")
m=r.b.a
if(m.length!==0)n.setAttribute("accept",B.a.ab(m,", "))
q.ga2().aa("display","none")
o.a(p.appendChild(n))
q.I("change",new A.lJ(s,q))}s=q.a
p=A.Z(s,"HTMLElement")
if(p)s.click()
else A.nU(s,"click",null,null,t.dy)},
$S:5}
A.lJ.prototype={
$1(a){var s,r,q,p,o,n,m,l,k
t.f.a(a)
q=this.a
p=q.a.d1(!0)
if(p==null)return
o=q.jM()
s=new A.ca(a.a)
r=null
if(s!=null)try{q=s.gau()
r=q==null?null:q.gcz()}catch(n){r=null}m=[]
if(t.Y.b(r))for(q=r,l=q.length,k=0;k<q.length;q.length===l||(0,A.k)(q),++k)m.push(q[k])
else if(r!=null)m.push(r)
o.ip(p,m)
try{q=s.gau()
if(q!=null){q=q.a
l=A.Z(q,"HTMLInputElement")
if(l)q.value=""
else{l=A.Z(q,"HTMLTextAreaElement")
if(l)q.value=""}}}catch(n){this.b.a.setAttribute("value","")}},
$S:0}
A.lG.prototype={
$1(a){return A.a5(t.Y.a(a),!0,t.z)},
$S:59}
A.lH.prototype={
$2(a,b){if(t.V.b(b))return new A.F(A.h(a),b,t.Fp)
throw A.i(A.au('Toolbar handler for "'+A.p(a)+'" must be a Handler',null))},
$S:204}
A.lI.prototype={
$1(a){return A.a5(t.Y.a(a),!0,t.z)},
$S:59}
A.lN.prototype={
$1(a){return A.h(a).length!==0},
$S:8}
A.lQ.prototype={
$1(a){var s,r,q,p,o,n,m,l,k=this,j="option"
t.T.a(a)
s=k.a
r=s.of(a)
if(r==null)return
q=a.a
p=t.m
if(A.I(p.a(q.classList).contains("ql-align"))){if(a.aI(j)==null)A.lr(a,B.eb,!1)
o=k.b.h(0,"align")
if(t.G.b(o)){q=t.N
q=A.Y(o,q,q)}else q=B.H
p=t.r
n=new A.jL(q,a,null,A.a([],p),A.a([],p),A.a([],t.yH))
n.hi()
n.ne(a,q)}else if(A.I(p.a(q.classList).contains("ql-background"))||A.I(p.a(q.classList).contains("ql-color"))){m=A.I(p.a(q.classList).contains("ql-background"))?"background":"color"
if(a.aI(j)==null)A.lr(a,B.dn,m==="background"?"#ffffff":"#000000")
q=A.m(k.b.h(0,m))
if(q==null)q=u.D
l=t.r
n=new A.jl(a,q,A.a([],l),A.a([],l),A.a([],t.yH))
n.hi()
l=n.c
l===$&&A.c()
p.a(l.a.classList).add("ql-color-picker")}else{if(a.aI(j)==null)if(A.I(p.a(q.classList).contains("ql-font")))A.lr(a,B.ec,!1)
else if(A.I(p.a(q.classList).contains("ql-header")))A.lr(a,B.ex,!1)
else if(A.I(p.a(q.classList).contains("ql-size")))A.lr(a,B.eQ,!1)
n=A.DS(a,s.b.b===B.C?'<i class="ti ti-selector" aria-hidden="true"></i>':null)}n.stX(new A.lP(k.c,a,r))
s=s.f
s.toString
B.a.k(s,n)},
$S:30}
A.lP.prototype={
$1(a){this.a.qI(this.b,this.c,a)},
$S:205}
A.lS.prototype={
$0(){var s=this.a.f
s.toString
B.a.O(s,new A.lO())},
$S:21}
A.lO.prototype={
$1(a){t.Eh.a(a).by()},
$S:69}
A.lR.prototype={
$4(a,b,c,d){return this.a.$0()},
$C:"$4",
$R:4,
$S:40}
A.cL.prototype={
ed(){var s=this.e
if(s!=null)s.I("keydown",new A.lU(this))},
eX(){this.r=!1
this.cJ()
this.a.e3(!0)},
f3(a,b){var s,r,q,p,o,n=this
n.dI()
s=n.c.a
t.m.a(s.classList).add("ql-editing")
n.r=!0
r=n.e
if(r==null)return
if(b!=null)r.scc(b)
else if(a!==A.m(s.getAttribute("data-mode")))n.e.scc("")
n.e.fw()
r=n.a
q=r.f
q===$&&A.c()
p=q.d
if(p!=null){o=r.cd(p.a,p.b)
if(o!=null)n.cX(o)}r=n.e.a
q=A.m(r.getAttribute("data-"+a))
if(q==null)q=""
r.setAttribute("placeholder",q)
s.setAttribute("data-mode",a)},
hG(a){return this.f3(a,null)},
rv(){return this.f3("link",null)},
iG(){var s,r,q,p,o,n,m=this,l="user",k=m.e,j=k==null?null:k.gcc()
if(j==null)j=""
k=m.c.a
switch(A.m(k.getAttribute("data-mode"))){case"link":s=1
break
case"video":s=2
break
case"formula":s=3
break
default:s=4
break}c$0:for(;!0;)switch(s){case 1:k=m.a
r=k.b
r===$&&A.c()
q=B.f.ah(A.a9(r.a.scrollTop))
p=m.f
if(p!=null){k.f7(p.a,p.b,"link",j,l)
m.f=null}else{k.e3(!0)
k.aD("link",j,l)}r.a.scrollTop=q
break c$0
case 2:j=A.Ii(j)
s=3
continue c$0
case 3:if(j.length===0)break c$0
r=m.a
r.bE()
r.by()
p=r.f
p===$&&A.c()
o=p.bb(0)
if(o!=null){n=o.a+o.b
p=A.m(k.getAttribute("data-mode"))
p.toString
r.tl(n,p,j,l)
if(A.m(k.getAttribute("data-mode"))==="formula")r.fc(n+1," ",l)
r.S(new A.G(n+2,0),l)}break c$0
case 4:break c$0}m.e.scc("")
m.r=!1
m.cJ()}}
A.lU.prototype={
$1(a){var s=t.f.a(a).a,r=new A.ca(s).geb()
if(r==="Enter"){this.a.iG()
s.preventDefault()}else if(r==="Escape"){this.a.eX()
s.preventDefault()}},
$S:0}
A.vL.prototype={
$1(a){var s=t.m,r=s.a(s.a(self.document).createElement("option")),q=J.a3(a)
if(q.n(a,this.b))r.setAttribute("selected","selected")
else r.setAttribute("value",q.B(a))
s.a(this.c.a.appendChild(r))},
$S:5}
A.jd.prototype={
nb(a,b){a.d.av("editor-change",new A.m0(this,a))},
ed(){var s,r=this
r.j4()
s=r.c.aI("a.ql-close")
if(s!=null)s.I("click",new A.m2(r))
r.a.d.av("scroll-optimize",new A.m3(r))},
eX(){this.dI()},
cX(a){var s,r="margin-left",q=this.n3(t.P.a(a)),p=this.c.aI(".ql-tooltip-arrow")
if(p!=null){s=p.ga2()
if(s!=null)s.aa(r,"")
if(q!==0){s=p.ga2()
if(s!=null)s.aa(r,A.p(-1*q-p.gdt()/2)+"px")}}return q}}
A.m0.prototype={
$4(a,b,c,d){var s,r,q,p,o,n,m,l,k,j,i=this
if(!J.A(a,"selection-change"))return
if(b!=null&&J.CI(J.b1(b),0)&&J.A(d,"user")){s=i.a
s.dI()
r=s.c
q=r.ga2()
if(q!=null)q.aa("left","0px")
q=r.ga2()
if(q!=null)q.aa("width","")
q=r.ga2()
if(q!=null)q.aa("width",""+r.gdt()+"px")
p=A.v(b.gc4())
o=A.v(J.b1(b))
r=i.b
q=r.c
q===$&&A.c()
n=q.cA(p,o)
if(n.length<=1){m=r.cd(p,o)
if(m!=null)s.cX(m)}else{l=B.a.gK(n)
k=q.aP(l)
j=r.cd(k,Math.min(l.E(0)-1,p+o-k))
if(j!=null)s.cX(j)}}else{s=i.b.f
s===$&&A.c()
if(s.dn()){s=i.a
if(!s.r){s.r=!1
s.cJ()}}}},
$C:"$4",
$R:4,
$S:40}
A.m2.prototype={
$1(a){t.f.a(a)
t.m.a(this.a.c.a.classList).remove("ql-editing")},
$S:0}
A.m3.prototype={
$2(a,b){A.rF(A.ng(0,1),new A.m1(this.a))},
$S:32}
A.m1.prototype={
$0(){var s,r,q,p=this.a
if(A.I(t.m.a(p.c.a.classList).contains("ql-hidden")))return
s=p.a
r=s.aX()
if(r!=null){q=s.cd(r.a,r.b)
if(q!=null)p.cX(q)}},
$S:1}
A.fb.prototype={
na(a,b){var s,r=b.d,q=r.h(0,"toolbar")
if(t.P.b(q))q.aQ("container",new A.lZ())
else if(q==null)r.j(0,"toolbar",A.l(["container",B.aX],t.N,t.z))
r=a.a.a
s=t.m
s.a(r.classList).add("ql-bubble")
if(b.b===B.C)s.a(r.classList).add("ql-icons-tabler")},
f5(a){var s,r,q=this,p=q.a,o=A.D1(p,p.a)
q.r=o
p=a.c
if(p!=null){s=t.m
s.a(o.c.a.appendChild(p.a))
p=q.b.b===B.C
r=p?$.yO():$.hn()
if(p)s.a(a.c.a.classList).add("ql-icons-tabler")
q.kN(a.c.a_("button"),r)
q.kO(a,a.c.a_("select"),r)}q.ib(a)
q.j3(a)},
ib(a){if(this.lu(a,"link"))return
a.e.j(0,"link",t.V.a(new A.m_(this)))}}
A.lZ.prototype={
$0(){return B.aX},
$S:206}
A.m_.prototype={
$1(a){var s,r=this.a
if(r.lj(a))r.a.aD("link",!1,"user")
else{s=r.r
if(s instanceof A.cL)s.rv()}},
$S:5}
A.kr.prototype={
ed(){var s,r,q=this
q.j4()
s=q.c
r=s.aI("a.ql-action")
if(r!=null)r.I("click",new A.pJ(q))
s=s.aI("a.ql-remove")
if(s!=null)s.I("click",new A.pK(q))
q.a.d.av("selection-change",new A.pL(q))},
dI(){this.jc()
this.c.a.removeAttribute("data-mode")}}
A.pJ.prototype={
$1(a){var s,r
t.f.a(a)
s=this.a
if(A.I(t.m.a(s.c.a.classList).contains("ql-editing")))s.iG()
else{r=s.Q
r===$&&A.c()
s.f3("link",r==null?null:A.m(r.a.textContent))}s=a.a
s.preventDefault()
s.stopPropagation()},
$S:0}
A.pK.prototype={
$1(a){var s,r,q
t.f.a(a)
s=this.a
if(s.f!=null){r=s.a
r.e3(!0)
q=s.f
r.f7(q.a,q.b,"link",!1,"user")
s.f=null}r=a.a
r.preventDefault()
r.stopPropagation()
s.r=!1
s.cJ()},
$S:0}
A.pL.prototype={
$3(a,b,c){var s,r,q,p,o,n,m,l,k=this.a
if(k.r)return
if(a==null)return
if(J.A(J.b1(a),0)&&J.A(c,"user")){s=k.a
r=s.c
r===$&&A.c()
q=t.p7.a(r.bv(new A.pI(),A.v(a.gc4())).a)
if(q!=null){p=r.aP(q)
o=q.E(0)
k.f=new A.G(p,o)
n=A.m(q.P().h(0,"link"))
r=k.Q
if(n!=null){r===$&&A.c()
m=r==null
if(!m)r.a.setAttribute("href",n)
if(!m)r.a.textContent=n}else{r===$&&A.c()
m=r==null
if(!m)r.a.removeAttribute("href")
if(!m)r.a.textContent=""}k.jc()
k.c.a.removeAttribute("data-mode")
l=s.cd(p,o)
if(l!=null)k.cX(l)
return}}else k.f=null
k.r=!1
k.cJ()},
$C:"$3",
$R:3,
$S:15}
A.pI.prototype={
$1(a){return a instanceof A.cw},
$S:9}
A.fA.prototype={
nj(a,b){var s,r=b.d,q=r.h(0,"toolbar")
if(t.P.b(q))q.aQ("container",new A.pF())
else if(q==null)r.j(0,"toolbar",A.l(["container",B.aU],t.N,t.z))
r=a.a.a
s=t.m
s.a(r.classList).add("ql-snow")
if(b.b===B.C)s.a(r.classList).add("ql-icons-tabler")},
f5(a){var s,r,q,p=this,o=a.c
if(o!=null){s=t.m
s.a(o.a.classList).add("ql-snow")
o=p.b
r=o.b===B.C
q=r?$.yO():$.hn()
if(r)s.a(a.c.a.classList).add("ql-icons-tabler")
p.kN(a.c.a_("button"),q)
p.kO(a,a.c.a_("select"),q)
s=p.a
p.r=A.Ek(s,o.c)
p.ib(a)
if(a.c.aI(".ql-link")!=null){o=s.x
o===$&&A.c()
o.co(A.l(["key","k","shortKey",!0],t.N,t.K),new A.pG(a))}p.j3(a)}},
ib(a){if(this.lu(a,"link"))return
a.e.j(0,"link",t.V.a(new A.pH(this)))}}
A.pF.prototype={
$0(){return B.aU},
$S:207}
A.pG.prototype={
$2(a,b){var s,r
t.F.a(a)
s=t.i.a(b).f.p("link")
r=this.a.e.h(0,"link")
if(r!=null)r.$1(!s)
return!0},
$S:12}
A.pH.prototype={
$1(a){var s,r,q,p,o=this.a
if(o.lj(a)){o.a.aD("link",!1,"user")
return}s=o.a
r=s.aX()
if(r==null||r.b===0)return
q=A.JT(s.ep(r.a,r.b))
p=o.r
if(p instanceof A.cL)p.f3("link",q)},
$S:5}
A.cA.prototype={
gct(){var s=this.c
s===$&&A.c()
return s},
hi(){var s,r,q=this,p=q.a,o=t.A.a(p.a.ownerDocument),n=t.m,m=n.a(o.createElement("span")),l=t.O,k=t.g
q.c!==$&&A.ai()
m=q.c=new A.f(A.b(l,k),m)
q.o9(p,m)
n.a(m.a.classList).add("ql-picker")
s=p.gaG()
if(s!=null)s.D(m,p)
p.ga2().aa("display","none")
s=n.a(o.createElement("span"))
r=new A.f(A.b(l,k),s)
n.a(s.classList).add("ql-picker-label")
s.setAttribute("role","button")
s.setAttribute("tabindex","0")
s.setAttribute("aria-expanded","false")
k=q.b
r.saf(k==null?u.D:k)
q.d!==$&&A.ai()
q.d=r
n.a(m.a.appendChild(s))
o=q.nM(new A.bu(o))
q.e!==$&&A.ai()
q.e=o
n.a(m.a.appendChild(o.a))
r.I("mousedown",new A.oI(q))
r.I("keydown",new A.oJ(q))
p.I("change",new A.oK(q))
q.by()},
lH(){var s,r=this,q=r.c
q===$&&A.c()
s=t.m
if(A.I(s.a(q.a.classList).contains("ql-expanded")))r.di()
else{s.a(q.a.classList).add("ql-expanded")
q=r.d
q===$&&A.c()
q.a.setAttribute("aria-expanded","true")
q=r.e
q===$&&A.c()
q.a.setAttribute("aria-hidden","false")}},
di(){var s=this.c
s===$&&A.c()
t.m.a(s.a.classList).remove("ql-expanded")
s=this.d
s===$&&A.c()
s.a.setAttribute("aria-expanded","false")
s=this.e
s===$&&A.c()
s.a.setAttribute("aria-hidden","true")},
by(){var s,r,q,p,o,n,m,l=this,k=null,j=null,i=l.a,h=i
try{s=h.gd2()
if(s!=null&&J.CH(s,0)&&J.CJ(s,l.f.length)){k=B.a.h(l.f,s)
j=B.a.h(l.r,s)}}catch(r){}if(k==null)for(q=l.r,p=0;p<q.length;++p)if(A.I(q[p].a.hasAttribute("selected"))){o=l.f
if(!(p<o.length))return A.d(o,p)
k=o[p]
if(!(p<q.length))return A.d(q,p)
j=q[p]
break}l.fz(k,!1)
n=i.aI("option[selected]")
if(j!=null)m=n==null||!J.A(j,n)
else m=!1
q=l.d
q===$&&A.c()
new A.b9(t.m.a(q.a.classList)).el("ql-active",m)},
nM(a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this,a=b.f
B.a.M(a)
s=b.r
B.a.M(s)
r=b.w
B.a.M(r)
q=a0.a
p=t.m
o=p.a(q.createElement("span"))
n=t.O
m=t.g
p.a(o.classList).add("ql-picker-options")
o.setAttribute("aria-hidden","true")
o.setAttribute("tabindex","-1")
l=$.Bg
$.Bg=l+1
k="ql-picker-options-"+l
o.setAttribute("id",k)
l=b.d
l===$&&A.c()
l.a.setAttribute("aria-controls",k)
j=b.a.a_("option")
for(i=0;i<j.length;++i){h=j[i]
l=p.a(q.createElement("span"))
g=new A.f(A.b(n,m),l)
p.a(l.classList).add("ql-picker-item")
l.setAttribute("role","button")
l.setAttribute("tabindex","0")
f=h.a
e=A.m(f.getAttribute("value"))
d=e==null||e.length===0||e==="false"?null:e
if(d!=null)l.setAttribute("data-value",d)
c=A.m(f.textContent)
if(c==null)c=""
if(c.length!==0)l.setAttribute("data-label",c)
g.I("click",new A.oG(b,g))
g.I("keydown",new A.oH(b,g))
b.l_(g,h,d,i)
p.a(o.appendChild(l))
B.a.k(a,g)
B.a.k(s,h)
B.a.k(r,d)}return new A.f(A.b(n,m),o)},
fz(a,b){var s,r,q,p,o,n=this,m=n.c
m===$&&A.c()
s=m.aI(".ql-selected")
if(J.A(s,a)){if(b)n.di()
return}if(s!=null)t.m.a(s.a.classList).remove("ql-selected")
m=a!=null
r=null
if(m){t.m.a(a.a.classList).add("ql-selected")
q=B.a.ae(n.f,a)
if(q!==-1){p=n.w
if(!(q>=0&&q<p.length))return A.d(p,q)
r=p[q]
n.nG(q)}}else n.nT()
m=m&&A.I(a.a.hasAttribute("data-label"))
p=n.d
if(m){p===$&&A.c()
m=A.m(a.a.getAttribute("data-label"))
m.toString
p.a.setAttribute("data-label",m)}else{p===$&&A.c()
p.a.removeAttribute("data-label")}m=n.d
if(r!=null){m===$&&A.c()
m.a.setAttribute("data-value",r)}else{m===$&&A.c()
m.a.removeAttribute("data-value")}n.i5(r)
if(b){o=A.Id(n.a,"change")
n.di()
if(!o){m=n.x
if(m!=null)m.$1(r)}}},
iI(a){return this.fz(a,!0)},
nG(a){var s,r,q,p,o,n=this
for(r=n.r,q=0;q<r.length;++q)if(q===a)r[q].a.setAttribute("selected","selected")
else r[q].a.removeAttribute("selected")
try{s=n.a
s.sd2(a)}catch(p){}r=n.w
if(!(a>=0&&a<r.length))return A.d(r,a)
o=r[a]
r=n.a.a
if(o!=null){r.setAttribute("value",o)
r.setAttribute("data-value",o)}else{r.removeAttribute("value")
r.removeAttribute("data-value")}},
nT(){var s,r,q,p,o
for(r=this.r,q=r.length,p=0;p<r.length;r.length===q||(0,A.k)(r),++p)r[p].a.removeAttribute("selected")
r=this.a
q=r.a
q.removeAttribute("value")
q.removeAttribute("data-value")
try{s=r
s.sd2(-1)}catch(o){}},
o9(a,b){var s,r,q,p,o=a.a,n=A.h(o.className)
if(n.length!==0)b.a.setAttribute("class",n)
s=A.m(o.getAttribute("title"))
if(s!=null)b.a.setAttribute("title",s)
for(o=new A.h1(o).gao(),o=o.gJ(o),r=b.a;o.l();){q=o.gq()
p=q.a
q=q.b
A.h(p)
A.h(q)
r.setAttribute(A.h2(p),q)}},
l_(a,b,c,d){},
i5(a){},
stX(a){this.x=t.k4.a(a)}}
A.oI.prototype={
$1(a){t.f.a(a)
return this.a.lH()},
$S:0}
A.oJ.prototype={
$1(a){var s,r=t.f.a(a).a,q=new A.ca(r).geb()
if(q==="Enter"){this.a.lH()
r.preventDefault()}else if(q==="Escape"){s=this.a
s.di()
s=s.d
s===$&&A.c()
s.fw()
r.preventDefault()}},
$S:0}
A.oK.prototype={
$1(a){t.f.a(a)
return this.a.by()},
$S:0}
A.oG.prototype={
$1(a){t.f.a(a)
this.a.iI(this.b)},
$S:0}
A.oH.prototype={
$1(a){var s,r=t.f.a(a).a,q=new A.ca(r).geb()
if(q==="Enter"){this.a.iI(this.b)
r.preventDefault()}else if(q==="Escape"){s=this.a
s.di()
s=s.d
s===$&&A.c()
s.fw()
r.preventDefault()}},
$S:0}
A.jl.prototype={
l_(a,b,c,d){var s=a.ga2()
s.aa("background-color",c==null?"":c)
if(d<7)t.m.a(a.a.classList).add("ql-primary")},
i5(a){var s,r,q,p,o,n,m,l="transparent",k=this.d
k===$&&A.c()
s=k.a_(".ql-color-label")
r=s.length
if(r===0){q=k.ga2()
q.aa("border-bottom",a!=null&&a.length!==0?"2px solid "+A.p(a):"")
return}for(k=a==null,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
q=o.ga2()
if(A.h(o.a.tagName).toLowerCase()==="line"){n=k?l:a
m=q.a
m.setProperty("stroke",n)}else{n=k?l:a
m=q.a
m.setProperty("fill",n)}}}}
A.jL.prototype={
ne(a,b){var s,r,q,p,o,n,m,l,k=this,j=k.c
j===$&&A.c()
t.m.a(j.a.classList).add("ql-icon-picker")
s=j.a_(".ql-picker-item")
for(r=s.length,q=k.y,p=0;p<s.length;s.length===r||(0,A.k)(s),++p){o=s[p]
n=A.m(o.a.getAttribute("data-value"))
m=q.h(0,n==null?"":n)
l=m==null?q.h(0,""):m
if(l==null)l=""
if(l.length!==0)o.saf(l)}j=j.aI(".ql-selected")
if(j==null)j=s.length!==0?B.a.gF(s):null
k.sod(j)
k.fz(k.z,!1)},
i5(a){var s,r=this,q=a!=null?r.y.h(0,a):null
if(q==null){s=r.z
q=s==null?null:s.gaf()}if(q==null)q=r.y.h(0,"")
if(q!=null&&q.length!==0){s=r.d
s===$&&A.c()
s.saf(q)}},
sod(a){this.z=t.q.a(a)}}
A.eJ.prototype={
jj(a,b,c){var s,r,q=this
if(c.length!==0)q.c.saf(c)
s=q.a.b
s===$&&A.c()
if(A.IO(s)){q.sqh(new A.t2(q))
r=q.d
r.toString
s.I("scroll",r)}q.r=!1
q.cJ()},
bF(){t.m.a(this.c.a.classList).add("ql-hidden")},
cX(a6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=this,a3="left",a4="top",a5="bottom"
t.P.a(a6)
s=a2.c
r=s.ga2()
q=a2.bB(a6.h(0,a3))
p=a2.bB(a6.h(0,a4))
o=a2.bB(a6.h(0,a5))
n=q+a2.bB(a6.h(0,"width"))/2-s.gdt()/2
m=a2.a.b
m===$&&A.c()
l=o+B.f.ah(A.a9(m.a.scrollTop))
m=r==null
if(!m)r.aa(a3,A.p(n)+"px")
if(!m)r.aa(a4,A.p(l)+"px")
k=s.a
j=t.m
j.a(k.classList).remove("ql-flip")
i=$.y().a
h=i.ce(a2.b)
g=i.ce(s)
if(h==null||g==null)return 0
f=a2.bB(h.h(0,a3))
e=a2.bB(h.h(0,"right"))
d=a2.bB(h.h(0,a5))
c=a2.bB(g.h(0,a3))
b=a2.bB(g.h(0,"right"))
a=a2.bB(g.h(0,a4))
a0=a2.bB(g.h(0,a5))
if(b>e){a1=e-b
if(!m)r.aa(a3,A.p(n+a1)+"px")}else a1=0
if(c<f){a1=f-c
if(!m)r.aa(a3,A.p(n+a1)+"px")}if(a0>d){if(!m)r.aa(a4,A.p(l-(o-p+(a0-a)))+"px")
j.a(k.classList).add("ql-flip")}return a1},
dI(){var s=this.c.a,r=t.m
r.a(s.classList).remove("ql-editing")
r.a(s.classList).remove("ql-hidden")},
bB(a){return a},
sqh(a){this.d=t.Cw.a(a)}}
A.t2.prototype={
$1(a){var s,r
t.f.a(a)
s=this.a
r=s.c.ga2()
if(r!=null){s=s.a.b
s===$&&A.c()
r.aa("margin-top",""+-1*B.f.ah(A.a9(s.a.scrollTop))+"px")}},
$S:0}
A.wm.prototype={
$1(a){var s,r,q,p,o,n,m=A.xo(t.qE.a(a),0,null),l=new A.ch()
$.iZ()
l.bN()
s=A.BG(m)
if(l.b==null)l.b=$.cd.$0()
r=s.bs().length
q=A.uG()
p=new A.ch()
p.bN()
o=A.uM(q)
if(p.b==null)p.b=$.cd.$0()
n=new A.ch()
n.bN()
o.fC(s)
if(n.b==null)n.b=$.cd.$0()
return B.q.cQ(A.l(["ops",r,"parseMs",l.gbT(),"mountMs",p.gbT(),"hydrateMs",n.gbT()],t.N,t.S),null)},
$S:70}
A.wl.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=A.xo(t.qE.a(a),0,null),b=new A.ch()
$.iZ()
b.bN()
s=A.BG(c)
if(b.b==null)b.b=$.cd.$0()
o=s.bs().length
n=new A.ch()
n.bN()
r=null
try{m=t.DQ
l=t.ic
k=t.S
j=t.pG
i=new A.mQ(s.bs(),A.a([],t.Bv),A.l([1,A.l([1,A.b(m,l),2,A.b(m,l)],k,j),2,A.l([1,A.b(m,l),2,A.b(m,l)],k,j)],k,t.D_))
m=t.v8
i.aJ(new A.jM(A.a([],m)))
i.aJ(new A.jD(A.a([],m)))
i.aJ(new A.jc(A.a([],m)))
i.aJ(new A.jS(A.a([],m)))
i.aJ(new A.ji(A.a([],m)))
i.aJ(new A.j7(A.a([],m)))
i.aJ(new A.jA(A.a([],m)))
i.aJ(new A.ko(A.a([],m)))
i.aJ(new A.k_(A.a([],m)))
l=t.s
i.aJ(new A.kI(A.a(["accelerometer","autoplay","encrypted-media","gyroscope","picture-in-picture"],l),A.a([],m)))
i.aJ(new A.kt(A.a([],m)))
i.aJ(new A.kD(A.a([],m)))
i.aJ(new A.jE(A.a([1,2,3,4,5,6],t.X),A.a([],m)))
i.aJ(new A.jh(A.a([],m)))
i.aJ(new A.k0(A.a([],m)))
i.aJ(new A.jb(A.a([],m)))
i.aJ(new A.kn(A.a(["super","sub"],l),A.a([],m)))
i.aJ(new A.ku(A.a([],m)))
i.aJ(new A.kv(A.a([],m)))
i.aJ(new A.j1(A.a(["center","right","justify","left"],l),A.a([],m)))
i.aJ(new A.kB(A.a([],m)))
i.a=!0
h=i.uf()
r=h}catch(g){q=A.bk(g)
p=A.cJ(g)
m=t.N
m=B.q.cQ(A.l(["error",A.p(q),"where",A.dg(A.a(J.L(p).split("\n"),t.s),0,A.eg(3,"count",t.S),m).ab(0," | ")],m,m),null)
return m}if(n.b==null)n.b=$.cd.$0()
f=A.uG()
e=new A.ch()
e.bN()
new A.f(A.b(t.O,t.g),f).saf(r)
if(e.b==null)e.b=$.cd.$0()
d=new A.ch()
d.bN()
A.uM(f)
if(d.b==null)d.b=$.cd.$0()
return B.q.cQ(A.l(["ops",o,"htmlChars",J.b1(r),"parseMs",b.gbT(),"toHtmlMs",n.gbT(),"injectMs",e.gbT(),"buildMs",d.gbT()],t.N,t.S),null)},
$S:70}
A.wk.prototype={
$1(a){var s,r,q
A.h(a)
s=A.uG()
r=new A.ch()
$.iZ()
r.bN()
new A.f(A.b(t.O,t.g),s).saf(a)
if(r.b==null)r.b=$.cd.$0()
q=new A.ch()
q.bN()
A.uM(s)
if(q.b==null)q.b=$.cd.$0()
return B.q.cQ(A.l(["htmlChars",a.length,"injectMs",r.gbT(),"buildMs",q.gbT()],t.N,t.S),null)},
$S:6}
A.wj.prototype={
$1(a){var s=t.j.a(B.q.hx(A.h(a),null)),r=A.x3(s),q=A.uM(A.uG()),p=new A.ch()
$.iZ()
p.bN()
q.fC(r)
if(p.b==null)p.b=$.cd.$0()
return B.q.cQ(A.l(["ops",J.b1(s),"hydrateMs",p.gbT()],t.N,t.S),null)},
$S:6}
A.wn.prototype={
$1$1(a,b){return new A.wo(b.i("e(0)").a(a),b)},
$1(a){return this.$1$1(a,t.z)},
$S:209}
A.wo.prototype={
$1(a){var s,r,q,p
this.b.a(a)
try{q=this.a.$1(a)
return q}catch(p){s=A.bk(p)
r=A.cJ(p)
q=t.N
q=B.q.cQ(A.l(["error",A.p(s),"where",A.dg(A.a(J.L(r).split("\n"),t.s),0,A.eg(4,"count",t.S),q).ab(0," | ")],q,q),null)
return q}},
$S(){return this.b.i("e(0)")}};(function aliases(){var s=J.hK.prototype
s.mS=s.W
s=J.dQ.prototype
s.mT=s.B
s=A.du.prototype
s.n4=s.jz
s.n5=s.jQ
s.n7=s.ko
s.n6=s.kg
s=A.R.prototype
s.mU=s.cg
s=A.o.prototype
s.fJ=s.uD
s=A.J.prototype
s.mX=s.W
s=A.C.prototype
s.mJ=s.de
s.mK=s.f2
s.j5=s.N
s.mL=s.b1
s.mN=s.en
s.mM=s.cD
s.fI=s.Y
s.ey=s.G
s=A.z.prototype
s.mZ=s.E
s.mY=s.de
s.eC=s.G
s.eB=s.aL
s.fK=s.bS
s.ci=s.b1
s.aT=s.D
s.n_=s.aj
s.j8=s.b2
s.n0=s.cD
s.j9=s.du
s.n1=s.bM
s=A.ay.prototype
s.mQ=s.cr
s.j6=s.b1
s.ez=s.G
s=A.cO.prototype
s.j7=s.N
s=A.a0.prototype
s.dN=s.N
s.d5=s.P
s.fH=s.G
s=A.f8.prototype
s.mI=s.N
s=A.aP.prototype
s.d6=s.N
s.cI=s.P
s.eA=s.G
s=A.ck.prototype
s.n2=s.cp
s=A.aj.prototype
s.j2=s.dg
s=A.hv.prototype
s.mP=s.ba
s.mO=s.dc
s=A.i2.prototype
s.fL=s.ba
s=A.dI.prototype
s.mR=s.P
s=A.cy.prototype
s.mW=s.P
s.mV=s.N
s=A.fE.prototype
s.ja=s.cr
s.jb=s.G
s=A.hs.prototype
s.j3=s.f5
s=A.cL.prototype
s.j4=s.ed
s=A.eJ.prototype
s.cJ=s.bF
s.n3=s.cX
s.jc=s.dI})();(function installTearOffs(){var s=hunkHelpers._static_2,r=hunkHelpers._static_0,q=hunkHelpers._static_1,p=hunkHelpers.installStaticTearOff,o=hunkHelpers._instance_2u,n=hunkHelpers._instance_1u,m=hunkHelpers._instance_0i,l=hunkHelpers.installInstanceTearOff,k=hunkHelpers._instance_0u
s(J,"GJ","DE",210)
r(A,"GZ","DV",13)
q(A,"HJ","EY",46)
q(A,"HK","EZ",46)
q(A,"HL","F_",46)
r(A,"Bx","Hx",1)
s(A,"BB","G1",26)
q(A,"BC","G2",42)
q(A,"I6","G3",28)
q(A,"I8","IB",42)
s(A,"I7","IA",26)
p(A,"Jy",2,null,["$1$2","$2"],["BT",function(a,b){return A.BT(a,b,t.fY)}],72,1)
p(A,"Jx",2,null,["$1$2","$2"],["BS",function(a,b){return A.BS(a,b,t.fY)}],72,1)
var j
o(j=A.fe.prototype,"grA","aK",26)
n(j,"gt1","aV",42)
n(j,"gtB","tC",85)
o(A.C.prototype,"gaU","N",2)
m(A.z.prototype,"gm","E",13)
m(j=A.aE.prototype,"gm","E",13)
o(j,"gc4","dr",37)
n(j=A.a0.prototype,"gpg","ph",36)
o(j,"gaU","N",2)
m(j,"gm","E",13)
n(A.f8.prototype,"gpi","pj",36)
m(A.ap.prototype,"gm","E",13)
m(j=A.cM.prototype,"gm","E",13)
o(j,"gc4","dr",37)
o(A.fg.prototype,"gc4","dr",37)
n(j=A.aP.prototype,"goY","oZ",36)
o(j,"gaU","N",2)
q(A,"JO","IN",3)
n(j=A.bh.prototype,"grR","rS",0)
o(j,"goQ","oR",134)
m(A.aM.prototype,"gm","E",13)
n(A.jo.prototype,"goG","oH",0)
q(A,"Ia","mS",28)
p(A,"HM",0,function(){return[null]},["$1","$0"],["yW",function(){return A.yW(null)}],213,0)
o(A.d4.prototype,"gaU","N",2)
q(A,"Im","Dp",19)
q(A,"IC","Dv",19)
o(A.d9.prototype,"gaU","N",2)
q(A,"Ja","DK",19)
o(A.cw.prototype,"gaU","N",2)
p(A,"Jb",0,function(){return[null]},["$1","$0"],["zA",function(){return A.zA(null)}],214,0)
p(A,"Jc",0,function(){return[null]},["$1","$0"],["zB",function(){return A.zB(null)}],215,0)
o(A.cy.prototype,"gaU","N",2)
q(A,"JM","xu",19)
o(A.df.prototype,"gaU","N",2)
o(A.aG.prototype,"gaU","N",2)
o(A.dn.prototype,"gaU","N",2)
q(A,"Kp","EH",19)
q(A,"Ie","F1",6)
p(A,"HP",3,null,["$3"],["Ji"],7,0)
p(A,"HQ",3,null,["$3"],["Jj"],7,0)
p(A,"HR",3,null,["$3"],["Jk"],7,0)
p(A,"HS",3,null,["$3"],["Jl"],7,0)
p(A,"HT",3,null,["$3"],["Jm"],7,0)
p(A,"HU",3,null,["$3"],["Jn"],7,0)
p(A,"HV",3,null,["$3"],["Jo"],7,0)
p(A,"BA",3,null,["$3"],["Jp"],7,0)
p(A,"HW",3,null,["$3"],["Jq"],7,0)
p(A,"HX",3,null,["$3"],["Jr"],7,0)
p(A,"HY",3,null,["$3"],["Jw"],7,0)
n(j=A.ey.prototype,"gpE","pF",0)
n(j,"gpA","pB",0)
n(j,"gpC","pD",0)
n(j,"gpy","pz",0)
n(j,"gpG","pH",0)
n(j=A.dM.prototype,"goz","oA",0)
n(j,"goD","oE",5)
p(A,"IS",3,null,["$3"],["Gk"],4,0)
p(A,"IT",3,null,["$3"],["Gl"],4,0)
p(A,"IV",3,null,["$3"],["Gn"],4,0)
p(A,"IW",3,null,["$3"],["Go"],4,0)
p(A,"IX",3,null,["$3"],["Gp"],4,0)
p(A,"IY",3,null,["$3"],["Gq"],4,0)
p(A,"J9",3,null,["$3"],["GD"],4,0)
p(A,"J6",3,null,["$3"],["Gz"],4,0)
p(A,"J_",3,null,["$3"],["Gs"],4,0)
p(A,"J2",3,null,["$3"],["Gv"],4,0)
p(A,"J3",3,null,["$3"],["Gw"],4,0)
p(A,"J4",3,null,["$3"],["Gx"],4,0)
p(A,"J5",3,null,["$3"],["Gy"],4,0)
p(A,"IQ",3,null,["$3"],["Gi"],4,0)
p(A,"J1",3,null,["$3"],["Gu"],4,0)
p(A,"IR",3,null,["$3"],["Gj"],4,0)
p(A,"IZ",3,null,["$3"],["Gr"],4,0)
p(A,"BP",3,null,["$3"],["GB"],4,0)
p(A,"J7",3,null,["$3"],["GA"],4,0)
p(A,"J8",3,null,["$3"],["GC"],4,0)
p(A,"J0",3,null,["$3"],["Gt"],4,0)
p(A,"IU",3,null,["$3"],["Gm"],4,0)
n(j=A.bD.prototype,"grX","rY",133)
o(j,"grI","rJ",38)
o(j,"grM","rN",38)
o(j,"grP","rQ",38)
o(j,"grT","rU",12)
q(A,"Jz","JC",49)
p(A,"K1",0,function(){return[null]},["$1","$0"],["z4",function(){return A.z4(null)}],218,0)
p(A,"K3",0,function(){return[null]},["$1","$0"],["zW",function(){return A.zW(null)}],219,0)
p(A,"K2",0,function(){return[null]},["$1","$0"],["zV",function(){return A.zV(null)}],220,0)
o(A.dF.prototype,"gaU","N",2)
o(A.di.prototype,"gaU","N",2)
o(A.cV.prototype,"gaU","N",2)
l(A.eE.prototype,"gt8",0,1,null,["$2","$1"],["lh","t9"],143,0,0)
k(j=A.bF.prototype,"ghy","dZ",1)
k(j,"ghz","e_",1)
k(j,"gf1","e0",1)
k(j,"gtL","tM",1)
k(j,"gmE","mF",1)
k(j,"gtg","th",1)
k(j,"gti","tj",1)
k(j,"gtn","tp",1)
k(j,"gtq","tr",1)
q(A,"Kk","ur",28)
p(A,"Ko",3,null,["$3"],["vG"],221,0)
n(A.dp.prototype,"goN","oO",0)
p(A,"JD",0,null,["$2$abstractNums$nums","$0"],["As",function(){return A.As(null,null)}],222,0)
q(A,"JE","EI",223)
p(A,"K_",0,null,["$3$byId$docDefaultsParagraph$docDefaultsRun","$0"],["Au",function(){return A.Au(null,null,null)}],224,0)
q(A,"K0","EM",225)
p(A,"Ix",0,function(){return[null]},["$1","$0"],["A8",function(){return A.A8(null)}],226,0)
l(A.c_.prototype,"gaU",0,2,function(){return[!1]},["$3","$2"],["cS","N"],65,0,0)
p(A,"Jd",0,function(){return[null]},["$1","$0"],["A9",function(){return A.A9(null)}],227,0)
p(A,"Je",0,function(){return[null]},["$1","$0"],["Ab",function(){return A.Ab(null)}],228,0)
l(A.cW.prototype,"gaU",0,2,function(){return[!1]},["$3","$2"],["cS","N"],65,0,0)
p(A,"K7",0,function(){return[null]},["$1","$0"],["A0",function(){return A.A0(null)}],229,0)
p(A,"Kg",0,function(){return[null]},["$1","$0"],["Ae",function(){return A.Ae(null)}],230,0)
p(A,"K8",0,function(){return[null]},["$1","$0"],["A2",function(){return A.A2(null)}],231,0)
q(A,"C0","eH",41)
p(A,"Ki",0,function(){return[null]},["$1","$0"],["Ag",function(){return A.Ag(null)}],233,0)
p(A,"Kd",0,function(){return[null]},["$1","$0"],["Ac",function(){return A.Ac(null)}],234,0)
p(A,"Kh",0,function(){return[null]},["$1","$0"],["Af",function(){return A.Af(null)}],235,0)
p(A,"K6",0,function(){return[null]},["$1","$0"],["A_",function(){return A.A_(null)}],236,0)
p(A,"Kj",0,function(){return[null]},["$1","$0"],["Ah",function(){return A.Ah(null)}],237,0)
p(A,"Ke",0,function(){return[null]},["$1","$0"],["Ad",function(){return A.Ad(null)}],238,0)
q(A,"Kf","xG",41)
p(A,"K9",0,function(){return[null]},["$1","$0"],["A3",function(){return A.A3(null)}],239,0)
q(A,"Ka","A4",41)
p(A,"Kb",0,function(){return[null]},["$1","$0"],["A5",function(){return A.A5(null)}],240,0)
p(A,"Kc",0,function(){return[null]},["$1","$0"],["A7",function(){return A.A7(null)}],241,0)
n(A.fE.prototype,"gcV","bm",3)
o(A.bG.prototype,"gaU","N",2)
n(A.a6.prototype,"gcV","bm",3)
n(A.cF.prototype,"gcV","bm",3)
n(A.ag.prototype,"gcV","bm",3)
n(A.bI.prototype,"gcV","bm",3)
n(A.bs.prototype,"gcV","bm",3)
n(A.bH.prototype,"gcV","bm",3)
n(j=A.eF.prototype,"gqj","qk",176)
n(j,"gqz","eS",242)
o(j,"gts","c7",178)
l(j,"gmC",0,0,null,["$1","$0"],["iY","iX"],43,0,0)
n(j,"ghP","hQ",0)
k(j,"gt4","dq",1)
n(j=A.je.prototype,"ghP","hQ",0)
n(j,"ghL","hM",0)
n(j,"gpw","px",0)
n(j=A.ka.prototype,"goI","oJ",0)
n(j,"goK","oL",0)
n(j,"grZ","hO",0)
l(j=A.dk.prototype,"grt",0,1,null,["$2","$1"],["l5","ru"],193,0,0)
n(j,"ghL","hM",0)
l(j,"guB",0,0,null,["$1","$0"],["em","bz"],194,0,0)
l(j,"ghy",0,0,null,["$1","$0"],["f0","dZ"],43,0,0)
l(j,"ghz",0,0,null,["$1","$0"],["l1","e_"],43,0,0)
k(j,"gf1","e0",1)
l(j,"gus",0,0,null,["$1","$0"],["lK","lJ"],195,0,0)
n(A.kz.prototype,"gqx","qy",6)
p(A,"C1",0,function(){return[null]},["$1","$0"],["Ak",function(){return A.Ak(null)}],177,0)
q(A,"wR","BO",8)
q(A,"hm","IP",8)
q(A,"Iz","Hn",161)
q(A,"Iw","JB",49)
p(A,"I0",3,null,["$3"],["Ju"],7,0)
p(A,"HZ",3,null,["$3"],["Js"],7,0)
p(A,"I_",3,null,["$3"],["Jt"],7,0)
p(A,"I1",3,null,["$3"],["Jv"],7,0)})();(function inheritance(){var s=hunkHelpers.mixin,r=hunkHelpers.inherit,q=hunkHelpers.inheritMany
r(A.J,null)
q(A.J,[A.xg,J.hK,J.d2,A.o,A.hu,A.P,A.bq,A.aq,A.R,A.pE,A.be,A.aS,A.dq,A.hZ,A.hD,A.aQ,A.aI,A.e1,A.dh,A.aW,A.fs,A.hw,A.dv,A.cg,A.fo,A.t4,A.or,A.hE,A.iy,A.u9,A.od,A.cx,A.dP,A.ip,A.e9,A.i0,A.lg,A.tB,A.uj,A.ce,A.l4,A.iz,A.li,A.kY,A.H,A.d3,A.l0,A.eS,A.aN,A.kZ,A.le,A.iI,A.il,A.l8,A.eY,A.io,A.iF,A.jq,A.bN,A.tz,A.nJ,A.u0,A.uk,A.cN,A.cr,A.tI,A.kb,A.i_,A.tJ,A.c9,A.F,A.ah,A.lh,A.ch,A.a_,A.iG,A.t9,A.ld,A.jy,A.oq,A.tX,A.ep,A.fn,A.dS,A.bm,A.h3,A.fr,A.fe,A.X,A.p8,A.C,A.d8,A.az,A.mQ,A.cQ,A.cz,A.jo,A.nh,A.l9,A.jw,A.eb,A.oU,A.aA,A.ab,A.G,A.fu,A.op,A.po,A.cG,A.ck,A.fw,A.pa,A.lc,A.jv,A.r,A.c7,A.aZ,A.aw,A.aj,A.f7,A.cZ,A.tE,A.tA,A.ec,A.ub,A.q,A.aY,A.ct,A.n,A.k1,A.c4,A.ud,A.Q,A.u4,A.bp,A.cu,A.pM,A.fB,A.dK,A.dN,A.oj,A.bP,A.av,A.cb,A.oo,A.la,A.aU,A.dY,A.fI,A.ky,A.ok,A.fK,A.fL,A.ue,A.e2,A.nt,A.to,A.ti,A.kN,A.tn,A.i6,A.tg,A.eO,A.tj,A.eM,A.bJ,A.e4,A.e3,A.ts,A.tq,A.tr,A.tp,A.kO,A.kP,A.fS,A.tl,A.th,A.kJ,A.kM,A.kK,A.fP,A.fV,A.e5,A.os,A.n8,A.n9,A.eP,A.e6,A.mN,A.ov,A.kk,A.kl,A.dr,A.e7,A.kR,A.kT,A.e8,A.kU,A.nL,A.nQ,A.jQ,A.kd,A.kV,A.tu,A.ew,A.jJ,A.jK,A.ex,A.hA,A.na,A.u2,A.u3,A.eq,A.eU,A.ca,A.nK,A.fj,A.jH,A.fk,A.fi,A.dJ,A.jF,A.hI,A.fl,A.b9,A.jG,A.ne,A.oP,A.bY,A.b5,A.cU,A.kg,A.dt,A.jY,A.o8,A.rh,A.eG,A.fF,A.m9,A.mg,A.ds,A.en,A.mf,A.je,A.hG,A.jn,A.ox,A.iu,A.ka,A.bi,A.cj,A.dk,A.l5,A.qX,A.kz,A.rc,A.fd,A.eJ,A.cA])
q(J.hK,[J.jT,J.hM,J.hN,J.fp,J.fq,J.eA,J.dO])
q(J.hN,[J.dQ,J.w,A.dT,A.hR])
q(J.dQ,[J.kf,J.e0,J.da])
r(J.nV,J.w)
q(J.eA,[J.hL,J.jU])
q(A.o,[A.ea,A.M,A.bU,A.an,A.de,A.ae,A.eW,A.kW,A.lf,A.cH])
q(A.ea,[A.em,A.iJ])
r(A.ij,A.em)
r(A.ih,A.iJ)
r(A.bd,A.ih)
q(A.P,[A.d5,A.bT,A.du,A.l6,A.h1])
q(A.bq,[A.jf,A.jg,A.m5,A.jR,A.kA,A.nX,A.wb,A.wd,A.tw,A.tv,A.up,A.tO,A.tV,A.tW,A.tG,A.ol,A.tZ,A.uy,A.uz,A.ww,A.wx,A.vF,A.p9,A.oC,A.oD,A.oB,A.oF,A.lX,A.lY,A.mP,A.nR,A.pj,A.pl,A.pk,A.pg,A.pf,A.wf,A.wg,A.vK,A.nS,A.oa,A.oh,A.oi,A.ql,A.qx,A.qy,A.qv,A.vt,A.mK,A.nj,A.nk,A.nl,A.ni,A.vC,A.vD,A.vJ,A.nr,A.uR,A.uS,A.uT,A.v3,A.v7,A.v8,A.v9,A.va,A.vb,A.vc,A.vd,A.uV,A.uU,A.uX,A.uW,A.uZ,A.uY,A.v_,A.v0,A.v2,A.v1,A.v4,A.v6,A.v5,A.oY,A.oZ,A.wD,A.pz,A.pA,A.pp,A.px,A.py,A.wC,A.n2,A.n6,A.n_,A.n0,A.n5,A.oA,A.ms,A.mr,A.mp,A.mq,A.pQ,A.pR,A.pO,A.pN,A.mG,A.mD,A.mE,A.mF,A.oc,A.of,A.og,A.wI,A.wJ,A.wK,A.wL,A.qJ,A.qz,A.ra,A.tD,A.tC,A.uc,A.u7,A.u6,A.mt,A.mu,A.mv,A.mw,A.mx,A.my,A.mC,A.mz,A.mA,A.mB,A.vE,A.wt,A.wu,A.nv,A.nA,A.nM,A.nN,A.o2,A.o0,A.o6,A.o7,A.o4,A.o5,A.wq,A.pW,A.pV,A.pU,A.pS,A.pT,A.q1,A.q0,A.pZ,A.q_,A.pY,A.rA,A.rn,A.ro,A.rp,A.rq,A.rr,A.rs,A.rz,A.rv,A.rw,A.ry,A.ru,A.rB,A.wF,A.wG,A.rW,A.rU,A.rY,A.rV,A.t0,A.t1,A.rZ,A.t_,A.rG,A.rH,A.rI,A.rM,A.rN,A.rO,A.rP,A.rQ,A.rR,A.rS,A.rT,A.rJ,A.rK,A.rL,A.uf,A.ug,A.vx,A.vw,A.vy,A.t8,A.t6,A.tk,A.tm,A.ow,A.tH,A.nd,A.nb,A.oQ,A.nE,A.nF,A.uF,A.nG,A.nH,A.qQ,A.qB,A.qC,A.qD,A.rb,A.rf,A.qA,A.rg,A.re,A.qE,A.qF,A.qK,A.qO,A.qG,A.qH,A.rj,A.ri,A.rm,A.q3,A.q4,A.qd,A.qe,A.qf,A.qg,A.qm,A.qn,A.qh,A.qi,A.qk,A.qj,A.mo,A.mk,A.ml,A.mm,A.mn,A.mi,A.mj,A.mh,A.ma,A.mb,A.md,A.nC,A.nB,A.mH,A.oy,A.w7,A.w8,A.vR,A.vS,A.vT,A.w_,A.w0,A.w1,A.w2,A.w3,A.w4,A.w5,A.w6,A.vU,A.vV,A.vW,A.vX,A.vY,A.vZ,A.qU,A.qV,A.r8,A.r3,A.r4,A.r5,A.r2,A.r6,A.r_,A.r0,A.qZ,A.qY,A.rd,A.uA,A.vM,A.vO,A.vP,A.vv,A.wA,A.wB,A.lT,A.lF,A.lK,A.lL,A.lM,A.lJ,A.lG,A.lI,A.lN,A.lQ,A.lP,A.lO,A.lR,A.lU,A.vL,A.m0,A.m2,A.m_,A.pJ,A.pK,A.pL,A.pI,A.pH,A.oI,A.oJ,A.oK,A.oG,A.oH,A.t2,A.wm,A.wl,A.wk,A.wj,A.wn,A.wo])
q(A.jf,[A.m7,A.oM,A.tx,A.ty,A.uh,A.nu,A.tK,A.tR,A.tQ,A.tN,A.tM,A.tL,A.tU,A.tT,A.tS,A.vs,A.ua,A.um,A.ul,A.pm,A.rD,A.rC,A.qq,A.qs,A.qt,A.qo,A.qp,A.qr,A.qw,A.mJ,A.nq,A.np,A.oV,A.p7,A.p5,A.p6,A.p4,A.p0,A.p1,A.p2,A.p3,A.p_,A.pr,A.pv,A.pw,A.pu,A.ps,A.pt,A.tF,A.uI,A.o_,A.pX,A.rt,A.ot,A.qR,A.qb,A.qc,A.qS,A.qT,A.r1,A.r7,A.lS,A.m1,A.lZ,A.pF])
q(A.jg,[A.m6,A.m8,A.mM,A.oL,A.nW,A.wc,A.uq,A.vu,A.tP,A.oe,A.om,A.u1,A.on,A.ta,A.tb,A.tc,A.ux,A.oE,A.lW,A.mO,A.pn,A.ph,A.pi,A.pb,A.pd,A.pe,A.pc,A.wh,A.ob,A.qu,A.wE,A.nm,A.nn,A.no,A.ve,A.vf,A.vg,A.vh,A.vi,A.vj,A.vk,A.vl,A.vm,A.vn,A.vo,A.vp,A.uQ,A.uP,A.oX,A.uC,A.pq,A.pB,A.pD,A.pC,A.rE,A.mW,A.mT,A.mU,A.mV,A.mX,A.mY,A.n7,A.n3,A.n4,A.n1,A.vA,A.lD,A.pP,A.nO,A.qM,A.qL,A.qN,A.te,A.tf,A.wO,A.wP,A.wM,A.wN,A.ws,A.uL,A.wv,A.nw,A.nx,A.ny,A.nz,A.vQ,A.uB,A.o1,A.o3,A.vH,A.rx,A.uO,A.uo,A.us,A.ut,A.vr,A.vq,A.uu,A.uK,A.uJ,A.wH,A.rX,A.t7,A.ou,A.nc,A.oR,A.oS,A.oT,A.nD,A.qP,A.qI,A.uv,A.rk,A.rl,A.wy,A.wz,A.q5,A.q6,A.q7,A.q8,A.q9,A.qa,A.mc,A.me,A.mI,A.qW,A.r9,A.vN,A.lH,A.m3,A.pG])
q(A.aq,[A.db,A.dl,A.jV,A.kF,A.l1,A.km,A.hq,A.l3,A.hP,A.cp,A.dc,A.i5,A.kE,A.fC,A.jp])
r(A.fN,A.R)
r(A.eo,A.fN)
q(A.M,[A.ad,A.es,A.as,A.eT,A.im])
q(A.ad,[A.eD,A.a1,A.hX,A.l7])
r(A.er,A.bU)
r(A.ff,A.de)
q(A.aW,[A.c2,A.h4,A.ee])
q(A.c2,[A.ao,A.h5,A.ba,A.iv,A.h6,A.f_,A.h7,A.f0])
r(A.d0,A.h4)
q(A.ee,[A.c3,A.iw,A.h8])
r(A.h9,A.fs)
r(A.eL,A.h9)
r(A.hx,A.eL)
r(A.E,A.hw)
q(A.cg,[A.fc,A.ix])
q(A.fc,[A.al,A.et])
r(A.ez,A.jR)
r(A.hT,A.dl)
q(A.kA,[A.ks,A.fa])
r(A.kX,A.hq)
r(A.hO,A.bT)
q(A.hR,[A.k2,A.bf])
q(A.bf,[A.iq,A.is])
r(A.ir,A.iq)
r(A.hQ,A.ir)
r(A.it,A.is)
r(A.bV,A.it)
q(A.hQ,[A.k3,A.k4])
q(A.bV,[A.k5,A.k6,A.k7,A.k8,A.k9,A.hS,A.eC])
r(A.iA,A.l3)
r(A.eR,A.l0)
r(A.lb,A.iI)
q(A.du,[A.eV,A.ii])
r(A.dw,A.ix)
q(A.jq,[A.ui,A.lE,A.nI,A.nZ,A.nY,A.td])
q(A.bN,[A.hr,A.jx,A.jW])
r(A.jX,A.hP)
r(A.u_,A.u0)
q(A.jx,[A.jZ,A.kH])
r(A.o9,A.ui)
q(A.cp,[A.fv,A.hJ])
r(A.l2,A.iG)
q(A.bm,[A.fO,A.fz])
q(A.C,[A.z,A.aE])
q(A.z,[A.j9,A.ay,A.hY,A.aP])
q(A.aE,[A.cO,A.aM])
r(A.a0,A.j9)
q(A.cO,[A.f8,A.ap,A.cM,A.fg])
q(A.ay,[A.hy,A.d7,A.dR])
q(A.aP,[A.dL,A.d4,A.dD,A.d9,A.cw,A.dW,A.df,A.dn,A.dF,A.e_])
r(A.bh,A.hY)
q(A.az,[A.ja,A.jO])
q(A.ja,[A.j1,A.jb,A.jh,A.jD,A.jE,A.k0,A.ku,A.kv,A.kB,A.kI])
q(A.jO,[A.j7,A.jc,A.ji,A.jA,A.jM,A.jS,A.k_,A.kn,A.ko,A.kt,A.kD])
q(A.tI,[A.kh,A.eX,A.cK,A.bK,A.m4,A.bR,A.fx,A.kw,A.eI,A.dZ,A.ik])
q(A.aj,[A.hv,A.i2,A.j2,A.js])
q(A.i2,[A.jj,A.j4,A.ju,A.jC,A.kq])
q(A.hv,[A.j3,A.j6,A.jk,A.jt,A.jB,A.jN,A.kp,A.kC])
q(A.jj,[A.j8,A.jm])
q(A.a0,[A.f9,A.dE,A.dI,A.cy,A.aG,A.bG,A.cE,A.bZ])
q(A.fg,[A.fh,A.fm])
q(A.hy,[A.cD,A.cC,A.b2,A.fE])
r(A.bt,A.f8)
q(A.aA,[A.d6,A.eu,A.ey,A.dM,A.bD,A.eE,A.bF,A.fH,A.i3,A.fM,A.dp,A.eF])
r(A.cT,A.av)
r(A.di,A.dE)
r(A.cV,A.d7)
q(A.bJ,[A.cY,A.ib,A.fQ,A.i9,A.ia,A.i8,A.fR,A.fU,A.fY,A.h_])
q(A.e4,[A.eN,A.fT,A.fZ,A.fX])
q(A.e3,[A.cX,A.eQ,A.fW])
q(A.dr,[A.ig,A.ic,A.kQ,A.kS,A.c1])
r(A.d_,A.kT)
r(A.tt,A.c9)
r(A.jP,A.jQ)
r(A.kc,A.kd)
q(A.fj,[A.ev,A.hH,A.bB,A.cv])
r(A.bu,A.hI)
q(A.eU,[A.f,A.bl])
r(A.c_,A.dI)
q(A.fE,[A.b8,A.a6,A.ag,A.bs,A.bH,A.b7])
r(A.cW,A.cy)
r(A.fJ,A.bG)
r(A.cF,A.a6)
r(A.bI,A.ag)
r(A.c0,A.bs)
r(A.fG,A.d6)
r(A.hs,A.ck)
r(A.cL,A.eJ)
q(A.cL,[A.jd,A.kr])
q(A.hs,[A.fb,A.fA])
q(A.cA,[A.jl,A.jL])
s(A.fN,A.e1)
s(A.iJ,A.R)
s(A.iq,A.R)
s(A.ir,A.aI)
s(A.is,A.R)
s(A.it,A.aI)
s(A.h9,A.iF)})()
var v={typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{j:"int",a2:"double",by:"num",e:"String",x:"bool",ah:"Null",t:"List",J:"Object",B:"Map"},mangledNames:{},types:["~(bA)","~()","~(e,@)","x(C)","@(bD,G,bP)","~(@)","e(e)","r(a7,r,bh)","x(e)","x(@)","~(dk)","r()","x(G,bP)","j()","~(bF)","ah(@,@,@)","~(@,@)","ah(@)","e(cS)","e?(T)","~(dk,T?,T)","ah()","~(C,j,j)","x(T)","j(j,aZ)","F<e,@>(@,@)","x(J?,J?)","ah(am)","@(@)","~(e,e)","~(T)","~(t<@>)","ah(@,@)","x(cq)","e(@)","r(r,r(a7,r,bh))","aj?(e)","j(a7,j)","~(G,bP)","x(cQ)","ah(@,@,@,@)","B<e,e>(T)","j(J?)","~([x])","j(j,j)","@(e)","~(~())","ah(bA)","j(j,aG)","~(hC)","B<e,e?>(T)","x(e,e?)","ah(@[@,@,@])","j(j,C)","@(@,e)","~(J?,J?)","B<e,@>(B<e,@>,e)","J?(aZ)","B<e,e?>(B<e,e?>,e)","t<@>(@)","@()","x(cT)","r(a7,r,@)","F<e,@>(e,@)","x(i6?)","~(e,@[x])","~(z)","~(eK,e,j)","~(e)","~(cA)","e(dT)","j(j)","0^(0^,0^)<by>","~(e,aj)","dn([@])","df([@])","cw([@])","dD([@])","d7([@])","J(T)","dE([@])","ah(J,dX)","f9([@])","j?(T)","dI([@])","x(J?)","dW([@])","~(B<@,@>,cz)","x(cz)","fm([@])","fh([@])","bt([@])","ck(ab,cG)","cz()","ah(@[@])","aN<@>(@)","t<br>()","ah(~())","x()","+endNode,endOffset,startNode,startOffset(a7,j,a7,j)?()","F<a7,j>?(j,x)","fu(a7,j)","~([@,@,@,@])","F<@,@>(@,@)","t<eb>()","bD(ab,@)","B<@,@>(B<@,@>,e)","aZ(@)","B<e,@>(aZ)","eu(ab,@)","~(aZ)","j(F<e,@>)","j(e,e)","a2?(e?)","e(C)","d6(ab,@)","cD([@])","cC([@])","b2([@])","aG([@])","j(j,b2)","dM(ab,@)","q(q)","cZ()","~(eX,kj?,cZ)","aY()","e(Q)","dp(ab,@)","~(fD,@)","a7(C)","r(r,a7)","j?(a7,j)","~(e,j)","x(bA)","~(t<cq>,nf)","t<C>(z,j,j)","t<cT>()","ey(ab,@)","ah(bD,G,bP)","aU(B<@,@>)","x(x(C))","x(a7)","e(a7)","r(e[e])","bF(ab,@)","x(aG)","F<e,B<e,@>>(e,B<e,@>)","eE(ab,@)","B<e,@>(@,@{keepNull:x})","B<e,@>(@,@,x)","B<e,@>(@,@)","~(e,~(@))","~(e,j?)","T?(x(T))","j(C,C)","e(cY)","t<fS>(e)","B<j,j>()","x(j,j)","e7(e8)","fM(ab,@)","aY?(e)","~(B<e,@>)","~(t<ew>,B<e,@>)","j(j,ex)","ah(w<J?>,am)","ah(@,dX)","+node,offset(am,j)?(am)","fH(ab,@)","e()","~(cE,e?)","j(j,ay)","j(j,a0)","fb(ab,cG)","fG(ab,@)","eF(ab,@)","en?(T)","e_([@])","~(j,j)","B<e,@>(t<C>)","en?()","x(b7)","T(a6)","x(ds)","a6(ds)","x(ag)","e(a6)","j(t<T>)","j(j,T)","e(j)","T(e,B<e,e>)","eK(@,@)","fA(ab,cG)","~(e[x])","~([T?])","~([e?])","j(j,ag)","a0([@])","a2(e)","e(z)","x(e?,e)","e(F<e,e>)","ap([@])","~(e,B<e,@>)","F<e,~(@)>(@,@)","~(e?)","t<t<@>>()","t<t<J>>()","cM([@])","e(0^)(e(0^))<J?>","j(@,@)","aM([@])","dL([@])","d4([@])","dR([@])","cy([@])","J?(J?)","d9([@])","dF([@])","di([@])","cV([@])","cs<~>(ab,G,t<@>)","e5({abstractNums:B<j,fP>?,nums:B<j,fV>?})","e5(e)","e6({byId:B<e,eP>?,docDefaultsParagraph:eM?,docDefaultsRun:eO?})","e6(e)","c_([@])","b8([@])","cW([@])","bG([@])","fJ([@])","a6([@])","~(j,@)","cF([@])","ag([@])","bI([@])","bs([@])","c0([@])","cE([@])","bZ([@])","bH([@])","b7([@])","b7?(T)","t<cq>()"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;":(a,b)=>c=>c instanceof A.ao&&a.b(c.a)&&b.b(c.b),"2;column,row":(a,b)=>c=>c instanceof A.h5&&a.b(c.a)&&b.b(c.b),"2;describe,value":(a,b)=>c=>c instanceof A.ba&&a.b(c.a)&&b.b(c.b),"2;hasTd,hasTh":(a,b)=>c=>c instanceof A.iv&&a.b(c.a)&&b.b(c.b),"2;icon,label":(a,b)=>c=>c instanceof A.h6&&a.b(c.a)&&b.b(c.b),"2;id,ref":(a,b)=>c=>c instanceof A.f_&&a.b(c.a)&&b.b(c.b),"2;next,rowspan":(a,b)=>c=>c instanceof A.h7&&a.b(c.a)&&b.b(c.b),"2;node,offset":(a,b)=>c=>c instanceof A.f0&&a.b(c.a)&&b.b(c.b),"3;":(a,b,c)=>d=>d instanceof A.d0&&a.b(d.a)&&b.b(d.b)&&c.b(d.c),"4;":a=>b=>b instanceof A.c3&&A.ys(a,b.a),"4;cx,cy,radius,width":a=>b=>b instanceof A.iw&&A.ys(a,b.a),"4;endNode,endOffset,startNode,startOffset":a=>b=>b instanceof A.h8&&A.ys(a,b.a)}}
A.Fq(v.typeUniverse,JSON.parse('{"da":"dQ","kf":"dQ","e0":"dQ","w":{"t":["1"],"M":["1"],"am":[],"o":["1"]},"jT":{"x":[],"at":[]},"hM":{"ah":[],"at":[]},"hN":{"am":[]},"dQ":{"am":[]},"nV":{"w":["1"],"t":["1"],"M":["1"],"am":[],"o":["1"]},"d2":{"ar":["1"]},"eA":{"a2":[],"by":[],"bO":["by"]},"hL":{"a2":[],"j":[],"by":[],"bO":["by"],"at":[]},"jU":{"a2":[],"by":[],"bO":["by"],"at":[]},"dO":{"e":[],"bO":["e"],"ke":[],"at":[]},"ea":{"o":["2"]},"hu":{"ar":["2"]},"em":{"ea":["1","2"],"o":["2"],"o.E":"2"},"ij":{"em":["1","2"],"ea":["1","2"],"M":["2"],"o":["2"],"o.E":"2"},"ih":{"R":["2"],"t":["2"],"ea":["1","2"],"M":["2"],"o":["2"]},"bd":{"ih":["1","2"],"R":["2"],"t":["2"],"ea":["1","2"],"M":["2"],"o":["2"],"R.E":"2","o.E":"2"},"d5":{"P":["3","4"],"B":["3","4"],"P.K":"3","P.V":"4"},"db":{"aq":[]},"eo":{"R":["j"],"e1":["j"],"t":["j"],"M":["j"],"o":["j"],"R.E":"j","e1.E":"j"},"M":{"o":["1"]},"ad":{"M":["1"],"o":["1"]},"eD":{"ad":["1"],"M":["1"],"o":["1"],"o.E":"1","ad.E":"1"},"be":{"ar":["1"]},"bU":{"o":["2"],"o.E":"2"},"er":{"bU":["1","2"],"M":["2"],"o":["2"],"o.E":"2"},"aS":{"ar":["2"]},"a1":{"ad":["2"],"M":["2"],"o":["2"],"o.E":"2","ad.E":"2"},"an":{"o":["1"],"o.E":"1"},"dq":{"ar":["1"]},"de":{"o":["1"],"o.E":"1"},"ff":{"de":["1"],"M":["1"],"o":["1"],"o.E":"1"},"hZ":{"ar":["1"]},"es":{"M":["1"],"o":["1"],"o.E":"1"},"hD":{"ar":["1"]},"ae":{"o":["1"],"o.E":"1"},"aQ":{"ar":["1"]},"fN":{"R":["1"],"e1":["1"],"t":["1"],"M":["1"],"o":["1"]},"hX":{"ad":["1"],"M":["1"],"o":["1"],"o.E":"1","ad.E":"1"},"dh":{"fD":[]},"ao":{"c2":[],"aW":[]},"h5":{"c2":[],"aW":[]},"ba":{"c2":[],"aW":[]},"iv":{"c2":[],"aW":[]},"h6":{"c2":[],"aW":[]},"f_":{"c2":[],"aW":[]},"h7":{"c2":[],"aW":[]},"f0":{"c2":[],"aW":[]},"d0":{"h4":[],"aW":[]},"c3":{"ee":[],"aW":[]},"iw":{"ee":[],"aW":[]},"h8":{"ee":[],"aW":[]},"hx":{"eL":["1","2"],"h9":["1","2"],"fs":["1","2"],"iF":["1","2"],"B":["1","2"]},"hw":{"B":["1","2"]},"E":{"hw":["1","2"],"B":["1","2"]},"eW":{"o":["1"],"o.E":"1"},"dv":{"ar":["1"]},"fc":{"cg":["1"],"cf":["1"],"M":["1"],"o":["1"]},"al":{"fc":["1"],"cg":["1"],"cf":["1"],"M":["1"],"o":["1"]},"et":{"fc":["1"],"cg":["1"],"cf":["1"],"M":["1"],"o":["1"]},"jR":{"bq":[],"br":[]},"ez":{"bq":[],"br":[]},"fo":{"zr":[]},"hT":{"dl":[],"dc":[],"aq":[]},"jV":{"dc":[],"aq":[]},"kF":{"aq":[]},"iy":{"dX":[]},"bq":{"br":[]},"jf":{"bq":[],"br":[]},"jg":{"bq":[],"br":[]},"kA":{"bq":[],"br":[]},"ks":{"bq":[],"br":[]},"fa":{"bq":[],"br":[]},"l1":{"aq":[]},"km":{"aq":[]},"kX":{"aq":[]},"bT":{"P":["1","2"],"xj":["1","2"],"B":["1","2"],"P.K":"1","P.V":"2"},"as":{"M":["1"],"o":["1"],"o.E":"1"},"cx":{"ar":["1"]},"hO":{"bT":["1","2"],"P":["1","2"],"xj":["1","2"],"B":["1","2"],"P.K":"1","P.V":"2"},"c2":{"aW":[]},"h4":{"aW":[]},"ee":{"aW":[]},"dP":{"kj":[],"ke":[]},"ip":{"hW":[],"cS":[]},"kW":{"o":["hW"],"o.E":"hW"},"e9":{"ar":["hW"]},"i0":{"cS":[]},"lf":{"o":["cS"],"o.E":"cS"},"lg":{"ar":["cS"]},"dT":{"am":[],"at":[]},"hR":{"am":[]},"k2":{"am":[],"at":[]},"bf":{"bS":["1"],"am":[]},"hQ":{"R":["a2"],"bf":["a2"],"t":["a2"],"bS":["a2"],"M":["a2"],"am":[],"o":["a2"],"aI":["a2"]},"bV":{"R":["j"],"bf":["j"],"t":["j"],"bS":["j"],"M":["j"],"am":[],"o":["j"],"aI":["j"]},"k3":{"R":["a2"],"bf":["a2"],"t":["a2"],"bS":["a2"],"M":["a2"],"am":[],"o":["a2"],"aI":["a2"],"at":[],"R.E":"a2","aI.E":"a2"},"k4":{"R":["a2"],"bf":["a2"],"t":["a2"],"bS":["a2"],"M":["a2"],"am":[],"o":["a2"],"aI":["a2"],"at":[],"R.E":"a2","aI.E":"a2"},"k5":{"bV":[],"R":["j"],"bf":["j"],"t":["j"],"bS":["j"],"M":["j"],"am":[],"o":["j"],"aI":["j"],"at":[],"R.E":"j","aI.E":"j"},"k6":{"bV":[],"R":["j"],"bf":["j"],"t":["j"],"bS":["j"],"M":["j"],"am":[],"o":["j"],"aI":["j"],"at":[],"R.E":"j","aI.E":"j"},"k7":{"bV":[],"R":["j"],"bf":["j"],"t":["j"],"bS":["j"],"M":["j"],"am":[],"o":["j"],"aI":["j"],"at":[],"R.E":"j","aI.E":"j"},"k8":{"bV":[],"R":["j"],"bf":["j"],"t":["j"],"bS":["j"],"M":["j"],"am":[],"o":["j"],"aI":["j"],"at":[],"R.E":"j","aI.E":"j"},"k9":{"bV":[],"xJ":[],"R":["j"],"bf":["j"],"t":["j"],"bS":["j"],"M":["j"],"am":[],"o":["j"],"aI":["j"],"at":[],"R.E":"j","aI.E":"j"},"hS":{"bV":[],"R":["j"],"bf":["j"],"t":["j"],"bS":["j"],"M":["j"],"am":[],"o":["j"],"aI":["j"],"at":[],"R.E":"j","aI.E":"j"},"eC":{"bV":[],"eK":[],"R":["j"],"bf":["j"],"t":["j"],"bS":["j"],"M":["j"],"am":[],"o":["j"],"aI":["j"],"at":[],"R.E":"j","aI.E":"j"},"iz":{"t3":[]},"l3":{"aq":[]},"iA":{"dl":[],"aq":[]},"aN":{"cs":["1"]},"li":{"EA":[]},"H":{"ar":["1"]},"cH":{"o":["1"],"o.E":"1"},"d3":{"aq":[]},"eR":{"l0":["1"]},"iI":{"Ax":[]},"lb":{"iI":[],"Ax":[]},"du":{"P":["1","2"],"B":["1","2"],"P.K":"1","P.V":"2"},"eV":{"du":["1","2"],"P":["1","2"],"B":["1","2"],"P.K":"1","P.V":"2"},"ii":{"du":["1","2"],"P":["1","2"],"B":["1","2"],"P.K":"1","P.V":"2"},"eT":{"M":["1"],"o":["1"],"o.E":"1"},"il":{"ar":["1"]},"dw":{"cg":["1"],"zy":["1"],"cf":["1"],"M":["1"],"o":["1"]},"eY":{"ar":["1"]},"R":{"t":["1"],"M":["1"],"o":["1"]},"P":{"B":["1","2"]},"im":{"M":["2"],"o":["2"],"o.E":"2"},"io":{"ar":["2"]},"fs":{"B":["1","2"]},"eL":{"h9":["1","2"],"fs":["1","2"],"iF":["1","2"],"B":["1","2"]},"cg":{"cf":["1"],"M":["1"],"o":["1"]},"ix":{"cg":["1"],"cf":["1"],"M":["1"],"o":["1"]},"l6":{"P":["e","@"],"B":["e","@"],"P.K":"e","P.V":"@"},"l7":{"ad":["e"],"M":["e"],"o":["e"],"o.E":"e","ad.E":"e"},"hr":{"bN":["t<j>","e"],"bN.S":"t<j>"},"jx":{"bN":["e","t<j>"]},"hP":{"aq":[]},"jX":{"aq":[]},"jW":{"bN":["J?","e"],"bN.S":"J?"},"jZ":{"bN":["e","t<j>"],"bN.S":"e"},"kH":{"bN":["e","t<j>"],"bN.S":"e"},"cN":{"bO":["cN"]},"a2":{"by":[],"bO":["by"]},"cr":{"bO":["cr"]},"j":{"by":[],"bO":["by"]},"t":{"M":["1"],"o":["1"]},"by":{"bO":["by"]},"kj":{"ke":[]},"hW":{"cS":[]},"cf":{"M":["1"],"o":["1"]},"e":{"bO":["e"],"ke":[]},"hq":{"aq":[]},"dl":{"aq":[]},"cp":{"aq":[]},"fv":{"aq":[]},"hJ":{"aq":[]},"dc":{"aq":[]},"i5":{"aq":[]},"kE":{"aq":[]},"fC":{"aq":[]},"jp":{"aq":[]},"kb":{"aq":[]},"i_":{"aq":[]},"lh":{"dX":[]},"a_":{"El":[]},"iG":{"kG":[]},"ld":{"kG":[]},"l2":{"kG":[]},"ep":{"c8":["1"]},"fn":{"c8":["o<1>"]},"dS":{"c8":["t<1>"]},"bm":{"c8":["2"]},"fO":{"bm":["1","o<1>"],"c8":["o<1>"],"bm.E":"1","bm.T":"o<1>"},"fz":{"bm":["1","cf<1>"],"c8":["cf<1>"],"bm.E":"1","bm.T":"cf<1>"},"fr":{"c8":["B<1,2>"]},"fe":{"c8":["@"]},"z":{"C":[]},"ay":{"z":[],"C":[]},"aE":{"C":[]},"j9":{"z":[],"C":[]},"cO":{"aE":[],"C":[]},"hY":{"z":[],"C":[]},"a0":{"z":[],"C":[]},"f8":{"aE":[],"C":[]},"ap":{"aE":[],"C":[]},"hy":{"ay":[],"z":[],"C":[]},"cM":{"aE":[],"C":[]},"fg":{"aE":[],"C":[]},"dL":{"aP":[],"z":[],"C":[]},"aP":{"z":[],"C":[]},"bh":{"hY":[],"z":[],"C":[]},"aM":{"aE":[],"C":[]},"ja":{"az":[]},"jO":{"az":[]},"j1":{"az":[]},"j7":{"az":[]},"jb":{"az":[]},"jc":{"az":[]},"jh":{"az":[]},"ji":{"az":[]},"jA":{"az":[]},"jD":{"az":[]},"jE":{"az":[]},"jM":{"az":[]},"jS":{"az":[]},"k_":{"az":[]},"k0":{"az":[]},"kn":{"az":[]},"ko":{"az":[]},"kt":{"az":[]},"ku":{"az":[]},"kv":{"az":[]},"kB":{"az":[]},"kD":{"az":[]},"kI":{"az":[]},"hv":{"aj":[]},"i2":{"aj":[]},"jj":{"aj":[]},"j2":{"aj":[]},"j3":{"aj":[]},"j4":{"aj":[]},"j6":{"aj":[]},"j8":{"aj":[]},"f9":{"a0":[],"z":[],"C":[]},"d4":{"aP":[],"z":[],"C":[]},"d7":{"ay":[],"z":[],"C":[]},"dE":{"a0":[],"z":[],"C":[]},"dD":{"aP":[],"z":[],"C":[]},"jk":{"aj":[]},"jm":{"aj":[]},"js":{"aj":[]},"jt":{"aj":[]},"ju":{"aj":[]},"jB":{"aj":[]},"jC":{"aj":[]},"fh":{"aE":[],"C":[]},"dI":{"a0":[],"z":[],"C":[]},"fm":{"aE":[],"C":[]},"jN":{"aj":[]},"d9":{"aP":[],"z":[],"C":[]},"cw":{"aP":[],"z":[],"C":[]},"dR":{"ay":[],"z":[],"C":[]},"cy":{"a0":[],"z":[],"C":[]},"dW":{"aP":[],"z":[],"C":[]},"kp":{"aj":[]},"kq":{"aj":[]},"df":{"aP":[],"z":[],"C":[]},"cD":{"ay":[],"z":[],"C":[]},"cC":{"ay":[],"z":[],"C":[]},"b2":{"ay":[],"z":[],"C":[]},"aG":{"a0":[],"z":[],"C":[]},"dn":{"aP":[],"z":[],"C":[]},"bt":{"aE":[],"C":[]},"d6":{"aA":["bp"],"aA.T":"bp"},"eu":{"aA":["cu"],"aA.T":"cu"},"ey":{"aA":["dK"],"aA.T":"dK"},"dM":{"aA":["dN"],"aA.T":"dN"},"bD":{"aA":["cb"],"aA.T":"cb"},"dF":{"aP":[],"z":[],"C":[]},"di":{"a0":[],"z":[],"C":[]},"cV":{"ay":[],"z":[],"C":[]},"eE":{"aA":["dY"],"aA.T":"dY"},"kC":{"aj":[]},"bF":{"aA":["fI"],"aA.T":"fI"},"fH":{"aA":["@"],"aA.T":"@"},"i3":{"aA":["fL"],"aA.T":"fL"},"fM":{"aA":["B<e,0&>"],"aA.T":"B<e,0&>"},"dp":{"aA":["e2"],"aA.T":"e2"},"cY":{"bJ":[]},"eN":{"e4":[]},"cX":{"e3":[]},"ib":{"bJ":[]},"fQ":{"bJ":[]},"i9":{"bJ":[]},"ia":{"bJ":[]},"i8":{"bJ":[]},"fR":{"bJ":[]},"fU":{"bJ":[]},"fY":{"bJ":[]},"h_":{"bJ":[]},"fT":{"e4":[]},"fZ":{"e4":[]},"fX":{"e4":[]},"eQ":{"e3":[]},"fW":{"e3":[]},"c1":{"dr":[]},"ig":{"dr":[]},"ic":{"dr":[]},"kQ":{"dr":[]},"kS":{"dr":[]},"d_":{"kT":[]},"jP":{"jQ":[]},"kc":{"kd":[]},"T":{"a7":[]},"dJ":{"x7":[]},"eU":{"a7":[]},"fj":{"bA":[]},"ev":{"Di":[],"bA":[]},"jH":{"nf":[]},"fk":{"cq":[]},"hH":{"zc":[],"bA":[]},"bB":{"Dk":[],"bA":[]},"cv":{"Dj":[],"bA":[]},"jF":{"Dh":[]},"hI":{"hC":[]},"bu":{"hC":[]},"f":{"T":[],"a7":[]},"bl":{"zd":[],"a7":[]},"h1":{"P":["e","e"],"B":["e","e"],"P.K":"e","P.V":"e"},"c_":{"a0":[],"z":[],"C":[]},"b8":{"ay":[],"z":[],"C":[]},"cW":{"a0":[],"z":[],"C":[]},"bG":{"a0":[],"z":[],"C":[]},"fJ":{"bG":[],"a0":[],"z":[],"C":[]},"a6":{"ay":[],"z":[],"C":[]},"cF":{"a6":[],"ay":[],"z":[],"C":[]},"ag":{"ay":[],"z":[],"C":[]},"bI":{"ag":[],"ay":[],"z":[],"C":[]},"bs":{"ay":[],"z":[],"C":[]},"c0":{"bs":[],"ay":[],"z":[],"C":[]},"cE":{"a0":[],"z":[],"C":[]},"bZ":{"a0":[],"z":[],"C":[]},"bH":{"ay":[],"z":[],"C":[]},"b7":{"ay":[],"z":[],"C":[]},"fE":{"ay":[],"z":[],"C":[]},"fG":{"d6":[],"aA":["bp"],"aA.T":"bp"},"eF":{"aA":["eG"],"aA.T":"eG"},"e_":{"aP":[],"z":[],"C":[]},"hs":{"ck":[]},"cL":{"eJ":[]},"fb":{"ck":[]},"jd":{"eJ":[]},"fA":{"ck":[]},"kr":{"eJ":[]},"jl":{"cA":[]},"jL":{"cA":[]},"Dz":{"t":["j"],"M":["j"],"o":["j"]},"eK":{"t":["j"],"M":["j"],"o":["j"]},"ED":{"t":["j"],"M":["j"],"o":["j"]},"Dx":{"t":["j"],"M":["j"],"o":["j"]},"EC":{"t":["j"],"M":["j"],"o":["j"]},"Dy":{"t":["j"],"M":["j"],"o":["j"]},"xJ":{"t":["j"],"M":["j"],"o":["j"]},"Dn":{"t":["a2"],"M":["a2"],"o":["a2"]},"Do":{"t":["a2"],"M":["a2"],"o":["a2"]}}'))
A.Fp(v.typeUniverse,JSON.parse('{"fN":1,"iJ":2,"bf":1,"ix":1,"jq":2}'))
var u={S:'<svg t="1692084199654" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="1975" width="16" height="16" xmlns:xlink="http://www.w3.org/1999/xlink"><path d="M776.08580741 364.42263703c-15.53445925-7.76722963-31.06891852-7.76722963-46.60337778 0L589.6722963 512l139.81013333 147.57736297c15.53445925 7.76722963 31.06891852 7.76722963 46.60337778 0 15.53445925-15.53445925 15.53445925-31.06891852 0-46.60337779L706.18074075 543.06891852h163.11182222c15.53445925 0 31.06891852-15.53445925 31.06891851-31.06891852s-15.53445925-31.06891852-31.06891851-31.06891852H706.18074075l69.90506666-69.90506666c7.76722963-15.53445925 7.76722963-31.06891852 0-46.60337779z m-528.17161482 0c-15.53445925 15.53445925-15.53445925 31.06891852 0 46.60337779l69.90506666 69.90506666H154.70743703c-15.53445925 0-31.06891852 15.53445925-31.06891851 31.06891852s15.53445925 31.06891852 31.06891851 31.06891852H317.81925925l-69.90506666 69.90506666c-15.53445925 15.53445925-15.53445925 31.06891852 0 46.60337779 15.53445925 7.76722963 31.06891852 7.76722963 46.60337778 0L434.3277037 512 294.51757037 364.42263703c-15.53445925-7.76722963-31.06891852-7.76722963-46.60337778 0z" fill="currentColor" p-id="1976"></path><path d="M317.81925925 939.19762963H84.80237037V84.80237037h233.01688888v116.50844445h77.6722963V7.13007408H7.13007408v1009.73985184h388.36148147V822.68918518h-77.6722963zM628.50844445 7.13007408v194.18074074h77.6722963v-116.50844445h233.01688888v854.39525926H706.18074075v-116.50844445h-77.6722963v194.18074074h388.36148147V7.13007408z" fill="currentColor" p-id="1977"></path></svg>',O:'<svg t="1692084271333" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="2200" xmlns:xlink="http://www.w3.org/1999/xlink" width="16" height="16"><path d="M9.14372835 1039.20071111L1020.26808889 1039.20071111l0-1048.576L9.14372835-9.37528889 9.14372835 1039.20071111z m252.77672107-711.53454649l1e-8-262.144 175.00150897 0 0 262.144L261.92044942 327.66616462zM942.48705138 702.1592576l0 262.14400001-178.89289103-1e-8 1e-8-262.144 178.89289102 0z m-256.66810311 0l0 262.144-171.11595236 0 0-262.144 171.11595236 0z m-248.89698987 0l0 262.144L261.92044943 964.3032576l-1e-8-262.144 175.00150898 0z m505.56509298-299.59563948L942.48705139 627.26180409l-178.89289104 0 0-224.69818596 178.89289103-1e-8z m-256.66810311 1e-8L685.81894827 627.26180409l-171.11595236 0 0-224.69818596 171.11595236 0z m-248.89698987 0L436.9219584 627.26180409 261.92044943 627.26180409l0-224.69818596 175.00150897 0z m505.56509298-337.04145352l0 262.14400001-178.89289102 0-1e-8-262.144 178.89289103-1e-8z m-256.66810311 1e-8l0 262.144-171.11595236 0 0-262.144 171.11595236 0z" fill="currentColor" p-id="2201"></path></svg>',v:'<svg t="1692084279720" class="icon" viewBox="0 0 1181 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="2344" xmlns:xlink="http://www.w3.org/1999/xlink" width="18.453125" height="16"><path d="M1142.15367111 0H39.38417778C7.99630222 0 0 8.27050667 0 39.38531555v945.2293689C0 1015.72949333 7.99516445 1024 39.38531555 1024h1102.76835556c31.39128889 0 39.38417778-8.27050667 39.38417778-39.38531555V39.38531555c0-31.11480889-7.99516445-39.38531555-39.38417778-39.38531555zM354.46328889 945.23050667l-276.992 3.26997333V749.568l276.992-1.25952v196.92202667z m0-275.69265778H78.76835555V472.61468445h275.69265778v196.92316444z m0-275.69152H78.76835555V236.30848h275.69265778v157.53671111z m393.84632889 551.38417778H433.23050667V748.30848h315.07683555v196.92202667z m0-275.69265778H433.23050667V472.61468445h315.07683555v196.92316444z m0-275.69152H433.23050667V236.30848h315.07683555v157.53671111z m354.46101333 551.38417778H827.07683555V748.30848h275.69265778v196.92202667z m0-275.69265778H827.07683555V472.61468445h275.69265778v196.92316444z m0-275.69152H827.07683555V236.30848h275.69265778v157.53671111z" fill="currentColor" p-id="2345"></path></svg>',l:'<svg t="1692084286647" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="2488" xmlns:xlink="http://www.w3.org/1999/xlink" width="16" height="16"><path d="M1058.13333333 0v1024H-34.13333333V0h1092.26666666zM460.8 563.2H68.26666667V921.6h392.53333333V563.2z m494.93333333 0H563.2V921.6h392.53333333V563.2zM460.8 102.4H68.26666667v358.4h392.53333333V102.4z" fill="currentColor" p-id="2489"></path></svg>',W:'<svg t="1692084293475" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="2632" xmlns:xlink="http://www.w3.org/1999/xlink" width="16" height="16"><path d="M1012.62222223 944.76190506a78.01904747 78.01904747 0 0 1-78.01904747 78.01904747H76.3936505a78.01904747 78.01904747 0 0 1-78.01904747-78.01904747V86.55238079a78.01904747 78.01904747 0 0 1 78.01904747-78.01904746h858.20952426a78.01904747 78.01904747 0 0 1 78.01904747 78.01904746v858.20952427zM466.4888889 554.66666666H76.3936505v390.0952384h390.0952384V554.66666666z m468.11428586 0H544.50793636v390.0952384h390.0952384V554.66666666zM466.4888889 86.55238079H76.3936505v390.0952384h390.0952384V86.55238079z m468.11428586 0H544.50793636v390.0952384h390.0952384V86.55238079z" fill="currentColor" p-id="2633"></path></svg>',N:'<svg t="1692084879007" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="968" xmlns:xlink="http://www.w3.org/1999/xlink" width="16" height="16"><path d="M512 332.57913685H49.39294151c-20.56031346 0-41.12062691-17.13359531-41.12062805-41.12062692V44.73474502c0-20.56031346 17.13359531-41.12062691 41.12062805-41.12062691H512c20.56031346 0 41.12062691 17.13359531 41.12062691 41.12062691v246.72376491c0 23.98703275-17.13359531 41.12062691-41.12062691 41.12062692zM90.51356843 250.33788188h380.36580466V85.85537308H90.51356843v164.4825088z m884.09349006 757.30488889h-925.21411698c-20.56031346 0-41.12062691-17.13359531-41.12062805-41.12062692v-246.72376491c0-20.56031346 17.13359531-41.12062691 41.12062805-41.12062691h921.78739883c20.56031346 0 41.12062691 17.13359531 41.12062691 41.12062691v246.72376491c0 23.98703275-17.13359531 41.12062691-37.69390876 41.12062692zM90.51356843 928.82823509h842.97286314v-164.48250994H90.51356843v164.48250994z" fill="currentColor" p-id="969"></path><path d="M974.60705849 1017.92292864h-925.21411698c-27.41375203 0-47.97406549-20.56031346-47.97406549-47.97406549v-246.72376491c0-27.41375203 20.56031346-47.97406549 47.97406549-47.97406549h921.78739883c27.41375203 0 47.97406549 20.56031346 47.97406435 47.97406549v246.72376491c3.42671929 23.98703275-20.56031346 47.97406549-44.5473462 47.97406549z m-925.21411698-325.53830173c-17.13359531 0-30.84047019 13.70687602-30.84047132 30.84047133v246.72376491c0 17.13359531 13.70687602 30.84047019 30.84047132 30.84047018h921.78739883c17.13359531 0 30.84047019-13.70687602 30.84047019-30.84047018v-246.72376491c0-17.13359531-13.70687602-30.84047019-30.84047019-30.84047133H49.39294151z m890.9469275 243.29704675h-856.67973802v-181.61610523h860.10645731v181.61610523h-3.42671929zM100.79372515 921.97479765h825.83926784V774.62588188H100.79372515v147.34891577z m411.20627485-582.54222223H49.39294151c-27.41375203 0-47.97406549-20.56031346-47.97406549-47.97406549V44.73474502c0-27.41375203 20.56031346-47.97406549 47.97406549-47.97406549H512c27.41375203 0 47.97406549 20.56031346 47.97406549 47.97406549v246.72376491c0 27.41375203-20.56031346 47.97406549-47.97406549 47.97406549zM49.39294151 13.89427484c-17.13359531 0-30.84047019 13.70687602-30.84047132 30.84047018v246.72376491c0 17.13359531 13.70687602 30.84047019 30.84047132 30.84047019H512c17.13359531 0 30.84047019-13.70687602 30.84047019-30.84047019V44.73474502c0-17.13359531-13.70687602-30.84047019-30.84047019-30.84047018H49.39294151zM481.15952981 260.61803974H83.66013099V79.00193451h397.49939882V260.61803974zM100.79372515 243.48444444h363.23220936V96.13552981H100.79372515v147.34891463z" fill="currentColor" p-id="970"></path><path d="M974.60705849 130.40271929H628.50844445c-6.85343744 0-10.28015673 3.42671929-10.28015674 10.28015672v58.25422223c0 6.85343744 3.42671929 10.28015673 10.28015674 10.28015673h304.97798712V466.2211766H546.26718947l27.41375204-20.56031345c3.42671929-3.42671929 6.85343744-10.28015673 6.85343744-17.13359531v-58.25422223c0-6.85343744-3.42671929-10.28015673-10.28015673-10.28015672-3.42671929 0-3.42671929 0-6.85343744 3.42671928L409.19843157 486.78149006c-10.28015673 6.85343744-10.28015673 20.56031346-3.42671928 27.41375203l3.42671928 3.42671816 157.62907136 130.21532045c3.42671929 3.42671929 10.28015673 3.42671929 13.70687602 0 0-3.42671929 3.42671929-3.42671929 3.42671929-6.85343744v-61.6809415c0-6.85343744-3.42671929-10.28015673-6.85343858-13.70687602l-20.56031345-17.13359417h421.48643157c20.56031346 0 41.12062691-17.13359531 41.12062691-41.12062805V168.09662691c-6.85343744-20.56031346-23.98703275-37.69390877-44.5473462-37.69390762z" fill="currentColor" p-id="971"></path><path d="M573.68094151 661.54415673c-3.42671929 0-6.85343744 0-10.28015673-3.42671929l-157.62907249-130.21531933-3.4267193-3.42671928c-3.42671929-6.85343744-6.85343744-13.70687602-6.85343744-20.56031346 0-6.85343744 3.42671929-13.70687602 10.28015674-20.5603146l157.62907249-126.78860117c3.42671929-3.42671929 6.85343744-3.42671929 10.28015673-3.42671815 10.28015673 0 17.13359531 6.85343744 17.13359417 17.13359416v58.25422223c0 10.28015673-3.42671929 17.13359531-10.28015673 23.98703275l-10.28015673 6.85343744H923.20627485v-239.87032634h-294.6978304c-10.28015673 0-17.13359531-6.85343744-17.13359531-17.13359416V140.68287601c0-10.28015673 6.85343744-17.13359531 17.13359531-17.13359531h346.09861404c27.41375203 0 47.97406549 20.56031346 47.97406549 47.9740655v335.81845732c0 27.41375203-20.56031346 47.97406549-47.97406549 47.97406549H577.10765966l3.42671929 3.42671929c6.85343744 6.85343744 10.28015673 13.70687602 10.28015673 20.56031346v61.6809415c0 3.42671929 0 6.85343744-3.42671815 10.28015674-3.42671929 6.85343744-10.28015673 10.28015673-13.70687602 10.28015673z m0-291.27111112l-157.6290725 126.78860117c-3.42671929 3.42671929-3.42671929 3.42671929-3.42671815 6.85343859s0 6.85343744 3.42671815 10.28015672l157.6290725 130.21532047h3.42671815v-61.68094151c0-3.42671929 0-6.85343744-3.42671815-10.28015673l-41.12062805-34.26718948h442.04674503c17.13359531 0 30.84047019-13.70687602 30.84047132-30.84047132V168.09662691c0-17.13359531-13.70687602-30.84047019-30.84047132-30.84047018H628.50844445v61.68094151h311.83142456v274.1375158H522.28015673l47.97406549-37.69390763c3.42671929-3.42671929 3.42671929-6.85343744 3.42671929-10.28015787v-54.82750293z" fill="currentColor" p-id="972"></path></svg>',D:'<svg viewBox="0 0 18 18">\n  <polygon class="ql-stroke" points="7 11 9 13 11 11 7 11"></polygon>\n  <polygon class="ql-stroke" points="7 7 9 5 11 7 7 7"></polygon>\n</svg>\n',U:'<svg viewbox="0 0 18 18"><g class="ql-fill ql-stroke ql-thin ql-transparent"><rect height="3" rx="0.5" ry="0.5" width="7" x="4.5" y="2.5"></rect><rect height="3" rx="0.5" ry="0.5" width="7" x="4.5" y="12.5"></rect></g><rect class="ql-fill ql-stroke ql-thin" height="3" rx="0.5" ry="0.5" width="7" x="8.5" y="7.5"></rect><polygon class="ql-fill ql-stroke ql-thin" points="4.5 11 2.5 9 4.5 7 4.5 11"></polygon><line class="ql-stroke" x1="6" x2="4" y1="9" y2="9"></line></svg>',E:'<svg viewbox="0 0 18 18"><g class="ql-fill ql-transparent"><rect height="10" rx="1" ry="1" width="4" x="12" y="2"></rect><rect height="10" rx="1" ry="1" width="4" x="2" y="2"></rect></g><path class="ql-fill" d="M11.354,4.146l-2-2a0.5,0.5,0,0,0-.707,0l-2,2A0.5,0.5,0,0,0,7,5H8V6a1,1,0,0,0,2,0V5h1A0.5,0.5,0,0,0,11.354,4.146Z"></path><rect class="ql-fill" height="8" rx="1" ry="1" width="4" x="7" y="8"></rect></svg>',J:'<svg viewbox="0 0 18 18"><polyline class="ql-even ql-stroke" points="5 7 3 9 5 11"></polyline><polyline class="ql-even ql-stroke" points="13 7 15 9 13 11"></polyline><line class="ql-stroke" x1="10" x2="8" y1="5" y2="13"></line></svg>',X:'<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M13 12.4316V7.8125C13 6.2592 14.2592 5 15.8125 5H40.1875C41.7408 5 43 6.2592 43 7.8125V32.1875C43 33.7408 41.7408 35 40.1875 35H35.5163" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M32.1875 13H7.8125C6.2592 13 5 14.2592 5 15.8125V40.1875C5 41.7408 6.2592 43 7.8125 43H32.1875C33.7408 43 35 41.7408 35 40.1875V15.8125C35 14.2592 33.7408 13 32.1875 13Z" fill="none" stroke="currentColor" stroke-width="4" stroke-linejoin="round"/></svg>',j:'<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M24 44C29.9601 44 26.3359 35.136 30 31C33.1264 27.4709 44 29.0856 44 24C44 12.9543 35.0457 4 24 4C12.9543 4 4 12.9543 4 24C4 35.0457 12.9543 44 24 44Z" fill="none" stroke="currentColor" stroke-width="4" stroke-linejoin="round"/><path d="M28 17C29.6569 17 31 15.6569 31 14C31 12.3431 29.6569 11 28 11C26.3431 11 25 12.3431 25 14C25 15.6569 26.3431 17 28 17Z" fill="none" stroke="currentColor" stroke-width="4" stroke-linejoin="round"/><path d="M16 21C17.6569 21 19 19.6569 19 18C19 16.3431 17.6569 15 16 15C14.3431 15 13 16.3431 13 18C13 19.6569 14.3431 21 16 21Z" fill="none" stroke="currentColor" stroke-width="4" stroke-linejoin="round"/><path d="M17 34C18.6569 34 20 32.6569 20 31C20 29.3431 18.6569 28 17 28C15.3431 28 14 29.3431 14 31C14 32.6569 15.3431 34 17 34Z" fill="none" stroke="currentColor" stroke-width="4" stroke-linejoin="round"/></svg>',h:'<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M4 42H44" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M31 4L7 28L13 34H21L41 14L31 4Z" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>',g:'<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M9 10V44H39V10H9Z" fill="none" stroke="currentColor" stroke-width="4" stroke-linejoin="round"/><path d="M20 20V33" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M28 20V33" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M4 10H44" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M16 10L19.289 4H28.7771L32 10H16Z" fill="none" stroke="currentColor" stroke-width="4" stroke-linejoin="round"/></svg>',e:'<svg width="18" height="18" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M36 18L24 30L12 18" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>',Z:'A cor \xe9 inv\xe1lida. Tente "#FF0000" ou "rgb(255,0,0)" ou "vermelho".',z:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",w:"Error handler must accept one Object or one Object and a StackTrace as arguments, and return a value of the returned future's type",d:"appearance:none;-webkit-appearance:none;width:28px;height:28px;min-width:28px;min-height:28px;margin:0;padding:3px;border:0;border-radius:2px;background:transparent;box-shadow:none;outline:none;display:inline-flex;align-items:center;justify-content:center;color:#444;font-size:18px;line-height:1;cursor:pointer;"}
var t=(function rtii(){var s=A.ax
return{Fq:s("d3"),d:s("aj"),Bd:s("hr"),uO:s("a0"),U:s("C"),sU:s("eo"),zI:s("jn"),hO:s("bO<@>"),j8:s("hx<fD,@>"),w:s("E<e,e>"),BV:s("E<e,@>"),hq:s("E<e,j>"),W:s("E<e,t<e>>"),M:s("al<e>"),tu:s("ay"),i:s("bP"),zs:s("cM"),zG:s("cN"),D:s("r"),mE:s("r()"),z6:s("r(a7,r,bh)"),no:s("r(e,e)"),ht:s("hA"),bV:s("zc"),uF:s("hC"),T:s("T"),f:s("bA"),BX:s("cq"),I:s("a7"),y:s("zd"),ya:s("cr"),ez:s("M<@>"),Ed:s("d8"),yt:s("aq"),BO:s("br"),o0:s("cs<@>"),gy:s("et<bK>"),uk:s("ex"),v1:s("ez<j>"),pN:s("zr"),mP:s("fn<@>"),rD:s("o<C>"),Y:s("o<@>"),uI:s("o<j>"),vs:s("w<aj>"),dV:s("w<a0>"),E:s("w<C>"),hF:s("w<ay>"),sa:s("w<fd>"),zM:s("w<aw>"),jY:s("w<hA>"),r:s("w<T>"),jp:s("w<x7>"),B:s("w<cq>"),yX:s("w<eq>"),wo:s("w<a7>"),kt:s("w<br>"),Cu:s("w<ct>"),yv:s("w<dJ>"),F8:s("w<jJ>"),fE:s("w<ew>"),h5:s("w<jK>"),sW:s("w<ex>"),wV:s("w<aE>"),Bv:s("w<cQ>"),ux:s("w<t<T>>"),tZ:s("w<t<e>>"),t6:s("w<t<@>>"),uw:s("w<t<j>>"),wx:s("w<F<C,j>>"),mW:s("w<F<T,a2>>"),sQ:s("w<F<T,j>>"),cs:s("w<B<e,@>>"),x:s("w<q>"),g9:s("w<fu>"),ua:s("w<cT>"),tl:s("w<J>"),t:s("w<aZ>"),v8:s("w<cz>"),a2:s("w<cA>"),ci:s("w<b5>"),eR:s("w<cU>"),bD:s("w<bY>"),un:s("w<+(bH,bZ?)>"),BZ:s("w<+(T,a2,a2)>"),nw:s("w<X>"),Ew:s("w<kk>"),D5:s("w<fB>"),s:s("w<e>"),k7:s("w<cV>"),xC:s("w<a6>"),zP:s("w<cj>"),yU:s("w<bi>"),BR:s("w<ag>"),yO:s("w<eI>"),zK:s("w<e3>"),Dk:s("w<fS>"),d5:s("w<e4>"),D0:s("w<eN>"),zE:s("w<bJ>"),hG:s("w<eP>"),Fa:s("w<kN>"),jw:s("w<kO>"),B7:s("w<kP>"),bd:s("w<e7>"),lx:s("w<c1>"),ha:s("w<dr>"),qo:s("w<e8>"),bo:s("w<kV>"),yd:s("w<ds>"),rk:s("w<dt>"),rT:s("w<cZ>"),aV:s("w<eb>"),zn:s("w<Q>"),ia:s("w<ec>"),ai:s("w<l5>"),th:s("w<l9>"),z3:s("w<la>"),kz:s("w<lc>"),n:s("w<@>"),X:s("w<j>"),Cf:s("w<J?>"),yH:s("w<e?>"),ee:s("w<r(a7,r,bh)>"),Be:s("hM"),m:s("am"),g:s("da"),yP:s("bS<@>"),eA:s("bT<fD,@>"),p:s("bD"),v9:s("aY"),at:s("aE"),ot:s("dS<@>"),ex:s("t<a0>"),xl:s("t<C>"),kQ:s("t<aw>"),u:s("t<T>"),wU:s("t<x7>"),o:s("t<cq>"),eO:s("t<br>"),Dc:s("t<ew>"),nx:s("t<am>"),xd:s("t<cQ>"),t1:s("t<F<T,j>>"),Dl:s("t<cT>"),tU:s("t<aZ>"),c:s("t<e>"),v_:s("t<aU>"),x7:s("t<a6>"),nc:s("t<bi>"),dF:s("t<ag>"),al:s("t<cE>"),AB:s("t<e3>"),gI:s("t<e8>"),bf:s("t<dt>"),tb:s("t<eb>"),j:s("t<@>"),L:s("t<j>"),AK:s("t<r(a7,r,bh)>"),ic:s("az"),mX:s("F<C,j>"),mz:s("F<T,a2>"),p2:s("F<T,j>"),Fv:s("F<a7,j>"),AT:s("F<e,e>"),dK:s("F<e,@>"),AC:s("F<@,@>"),fq:s("F<e,B<e,@>>"),Fp:s("F<e,~(@)>"),nv:s("F<C?,j>"),lB:s("F<aE?,j>"),Ec:s("fr<@,@>"),J:s("B<e,e>"),m0:s("B<e,x>"),P:s("B<e,@>"),pG:s("B<t3,az>"),G:s("B<@,@>"),qu:s("B<j,j>"),ml:s("B<a7,t<r(a7,r,bh)>>"),Bg:s("B<e,B<e,e>>"),cw:s("B<e,e?>"),D_:s("B<j,B<t3,az>>"),e:s("a1<e,e>"),sT:s("q"),qE:s("dT"),eJ:s("bV"),iT:s("eC"),dz:s("dc"),kH:s("cT"),b:s("ah"),K:s("J"),Q:s("aZ"),ty:s("z"),jG:s("cz"),Eh:s("cA"),l:s("ab"),F:s("G"),op:s("KM"),ep:s("+()"),kh:s("+next,rowspan(ag?,j)"),he:s("hW"),z0:s("X"),Dm:s("kl"),q6:s("hX<e>"),_:s("bh"),iq:s("fz<@>"),dO:s("cf<e>"),rz:s("cf<cX>"),qr:s("cf<bK>"),AH:s("dX"),N:s("e"),pj:s("e(cS)"),C:s("e(e)"),gr:s("e(e,e)"),of:s("fD"),ao:s("cV"),s3:s("aU"),o2:s("bF"),qj:s("bs"),Fc:s("aG"),hB:s("bG"),Z:s("a6"),hi:s("bZ"),yk:s("bH"),cB:s("cD"),ll:s("b7"),p4:s("c_"),wj:s("cW"),fR:s("b8"),qe:s("cj"),a:s("dk"),h1:s("b2"),H:s("ag"),qk:s("cE"),mo:s("cF"),iA:s("bI"),Bx:s("c0"),eH:s("ck"),bU:s("cG"),sg:s("at"),DQ:s("t3"),bs:s("dl"),uo:s("eK"),qF:s("e0"),AF:s("fO<@>"),eP:s("kG"),vY:s("an<e>"),d0:s("ae<T>"),A7:s("ae<aG>"),ja:s("ae<a6>"),q9:s("ae<bZ>"),fP:s("ae<b2>"),rL:s("ae<bI>"),kd:s("ae<cY>"),dd:s("ae<c1>"),mG:s("aQ<T>"),er:s("aQ<a6>"),og:s("aQ<bZ>"),DE:s("aQ<ag>"),bi:s("aQ<c1>"),r3:s("fP"),zY:s("kJ"),n_:s("fV"),k9:s("e5"),iV:s("kK"),tn:s("cX"),xD:s("eP"),r5:s("e6"),As:s("cY"),bj:s("h_"),rI:s("c1"),dB:s("e8"),h6:s("eR<e?>"),aH:s("ds"),CF:s("cZ"),EE:s("eb"),Dy:s("Q"),nT:s("ec"),hR:s("aN<@>"),gH:s("aN<e?>"),BT:s("eV<J?,J?>"),pJ:s("h3"),n2:s("cH<c1>"),v:s("x"),Ez:s("x(C)"),ik:s("x(T)"),Ac:s("x(cQ)"),bl:s("x(J)"),Ag:s("x(e)"),pR:s("a2"),z:s("@"),pF:s("@()"),oo:s("@(bD,G,bP)"),h_:s("@(J)"),nW:s("@(J,dX)"),S:s("j"),EU:s("j(j)"),g5:s("0&*"),tw:s("J*"),nG:s("aj?(e)"),q:s("T?"),hh:s("br?"),eZ:s("cs<ah>?"),A:s("am?"),p7:s("cw?"),ag:s("t<T>?"),k:s("t<cq>?"),DT:s("t<cA>?"),gR:s("t<e>?"),EL:s("t<cZ>?"),jS:s("t<@>?"),km:s("B<e,e>?"),h:s("B<e,@>?"),yq:s("B<@,@>?"),dy:s("J?"),tm:s("J?(aZ)"),kr:s("G?"),jT:s("kj?"),dR:s("e?"),tj:s("e(cS)?"),rb:s("bs?"),rM:s("bH?"),rd:s("c0?"),f7:s("eS<@,@>?"),Af:s("l8?"),CC:s("x()?"),fz:s("x(cQ)?"),DL:s("+endNode,endOffset,startNode,startOffset(a7,j,a7,j)?()?"),Cw:s("~(bA)?"),wg:s("~(@)?"),k4:s("~(e?)?"),fY:s("by"),jW:s("~"),R:s("~()"),r9:s("~(t<cq>,nf)"),gh:s("~(ab,G,t<@>)"),ef:s("~(C,j,j)"),O:s("~(bA)"),ma:s("~(e)"),iJ:s("~(e,@)"),a6:s("~(bF)"),V:s("~(@)"),xx:s("~(j,j)")}})();(function constants(){var s=hunkHelpers.makeConstList
B.cl=J.hK.prototype
B.a=J.w.prototype
B.d=J.hL.prototype
B.f=J.eA.prototype
B.b=J.dO.prototype
B.cm=J.da.prototype
B.cn=J.hN.prototype
B.u=A.eC.prototype
B.by=J.kf.prototype
B.ax=J.e0.prototype
B.c=new A.cK(0,"ord")
B.o=new A.cK(1,"bigOp")
B.j=new A.cK(2,"bin")
B.h=new A.cK(3,"rel")
B.A=new A.cK(4,"open")
B.y=new A.cK(5,"close")
B.aB=new A.cK(6,"punct")
B.aC=new A.cK(7,"functionName")
B.aD=new A.m4(0,"littleEndian")
B.bT=new A.ez(A.Jx(),t.v1)
B.bU=new A.ez(A.Jy(),t.v1)
B.bV=new A.lE()
B.aE=new A.hr()
B.nk=new A.ep(A.ax("ep<0&>"))
B.bX=new A.hD(A.ax("hD<0&>"))
B.nl=new A.nJ()
B.aF=new A.nI()
B.aG=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.bY=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.c2=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.bZ=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.c1=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.c0=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.c_=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.aH=function(hooks) { return hooks; }

B.q=new A.jW()
B.aI=new A.jZ()
B.k=new A.J()
B.c3=new A.kb()
B.c4=new A.pa()
B.m=new A.pE()
B.c5=new A.fI()
B.aJ=new A.kH()
B.c6=new A.kM()
B.I=new A.tX()
B.aK=new A.u9()
B.p=new A.lb()
B.R=new A.lh()
B.r=A.a(s([]),t.n)
B.e6=A.a(s([]),t.vs)
B.c7=new A.bp(B.r)
B.a4=new A.fe(!1)
B.c8=new A.fe(!0)
B.c9=new A.cr(0)
B.aL=new A.cr(1000)
B.aM=new A.cr(1e6)
B.a5=new A.bR(0,"text")
B.aN=new A.bR(1,"image")
B.ca=new A.bR(13,"tab")
B.S=new A.bR(17,"title")
B.a6=new A.bR(18,"list")
B.T=new A.bR(2,"table")
B.a7=new A.bR(3,"hyperlink")
B.a8=new A.bR(4,"superscript")
B.a9=new A.bR(5,"subscript")
B.cb=new A.bR(6,"separator")
B.aO=new A.bR(7,"pageBreak")
B.cc=new A.c9("Pacote OPC inv\xe1lido: [Content_Types].xml ausente.",null,null)
B.cd=new A.c9("Invalid ZIP archive: end of central directory not found.",null,null)
B.ce=new A.c9("Invalid ZIP archive: unexpected central directory header.",null,null)
B.cf=new A.c9("Invalid ZIP archive: local file header not found.",null,null)
B.cg=new A.c9("document.xml com <w:body> em formato n\xe3o suportado.",null,null)
B.ch=new A.c9("Pacote OPC sem relacionamento officeDocument.",null,null)
B.ci=new A.c9("document.xml sem <w:body>.",null,null)
B.cj=new A.hG(0,0,100)
B.ck=new A.dK(24,!0)
B.aP=new A.dN(null)
B.co=new A.nY(null)
B.cp=new A.nZ(null)
B.i=A.a(s([]),t.s)
B.e=A.a(s([]),t.x)
B.x=new A.q("comment","/\\*",null,"\\*/",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hr=new A.q("keyword","@[a-z-]+",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.i7=new A.q("selector-pseudo","::?[a-z][a-z0-9-]*(\\([^)]*\\))?",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hD=new A.q("selector-class","\\.[a-zA-Z0-9_-]+",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.fZ=new A.q("selector-id","#[a-zA-Z0-9_-]+",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hS=new A.q("selector-attr","\\[",null,"\\]","\\n",null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hp=new A.q("selector-tag","\\b(?:html|body|div|span|p|a|ul|ol|li|table|tr|td|th|input|button|select|option|label|form|img|h[1-6]|header|footer|nav|section|article|aside|main|pre|code|strong|em|blockquote)\\b",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hn=new A.q("attribute","\\b[a-zA-Z-]+(?=\\s*:)",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.ii=new A.q("meta","!important",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hf=new A.q("number","#[0-9a-fA-F]{3,8}\\b",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hB=new A.q("number","\\b(\\d+(\\.\\d*)?|\\.\\d+)(%|px|em|rem|ex|ch|vh|vw|vmin|vmax|cm|mm|in|pt|pc|deg|rad|turn|s|ms|fr)?",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.a0=new A.q(null,"\\\\[\\s\\S]",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!0)
B.J=A.a(s([B.a0]),t.x)
B.bm=new A.q(null,'"',null,'"',null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.bl=new A.q(null,"'",null,"'",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.eE=A.a(s([B.bm,B.bl]),t.x)
B.hz=new A.q("string",null,null,null,"\\n",null,null,B.J,B.eE,!1,!1,!1,!1,!1,!1,null,!1)
B.hl=new A.q("built_in","\\b(?:url|rgba?|hsla?|calc|var|linear-gradient|radial-gradient|translate[XYZ]?|rotate|scale|cubic-bezier)(?=\\()",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.dU=A.a(s([B.x,B.ii,B.hf,B.hB,B.hz,B.hl]),t.x)
B.hY=new A.q(null,":",null,"(?=[;}])",null,null,null,B.dU,null,!1,!1,!1,!1,!1,!1,null,!1)
B.d5=A.a(s([B.x,B.hn,B.hY]),t.x)
B.fX=new A.q(null,"\\{",null,"\\}",null,null,null,B.d5,null,!1,!1,!1,!1,!1,!1,null,!1)
B.f1=A.a(s([B.x,B.hr,B.i7,B.hD,B.fZ,B.hS,B.hp,B.fX]),t.x)
B.hc=new A.q(null,null,null,null,null,null,null,B.f1,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cq=new A.aY("css",B.i,B.hc,!0)
B.ap={keyword:0,type:1,literal:2,built_in:3}
B.e1=A.a(s(["add","all","alter","and","any","as","asc","begin","between","by","cascade","case","check","column","commit","constraint","create","cross","default","delete","desc","distinct","drop","else","end","exists","foreign","from","full","grant","group","having","if","in","index","inner","insert","into","is","join","key","left","like","limit","not","null","offset","on","or","order","outer","primary","references","returning","right","rollback","select","set","table","then","transaction","truncate","union","unique","update","using","values","view","when","where","with"]),t.s)
B.dN=A.a(s(["bigint","binary","bit","blob","boolean","char","date","datetime","decimal","double","float","int","integer","json","jsonb","numeric","real","serial","smallint","text","time","timestamp","uuid","varchar"]),t.s)
B.bd=A.a(s(["true","false","null"]),t.s)
B.dt=A.a(s(["avg","cast","coalesce","concat","count","current_date","current_timestamp","extract","lower","max","min","now","round","substring","sum","trim","upper"]),t.s)
B.fR=new A.E(B.ap,[B.e1,B.dN,B.bd,B.dt],t.W)
B.fW=new A.q("comment","--",null,"$",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.fU=new A.q(null,"''",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!0)
B.cJ=A.a(s([B.fU]),t.x)
B.hs=new A.q("string","'",null,"'",null,null,null,B.cJ,null,!1,!1,!1,!1,!1,!1,null,!1)
B.bq=new A.q("string",'"',null,'"',null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hA=new A.q("string","`",null,"`",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.ao=new A.q("number","\\b(\\d[\\d_]*(\\.[\\d_]*)?|\\.\\d[\\d_]*)([eE][-+]?\\d+)?",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hW=new A.q("variable","[@:]\\w+",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.ee=A.a(s([B.fW,B.x,B.hs,B.bq,B.hA,B.ao,B.hW]),t.x)
B.i4=new A.q(null,null,null,null,null,B.fR,null,B.ee,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cr=new A.aY("sql",B.i,B.i4,!0)
B.ez=A.a(s(["md","mkdown"]),t.s)
B.h6=new A.q("section","^#{1,6} .*$",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hi=new A.q("section","^.+\\n[=-]{2,}$",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.i8=new A.q(null,"^```[\\s\\S]*?^```",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.ip=new A.q(null,"`[^`\\n]*`",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.ik=new A.q(null,"^(?: {4}|\\t).*$",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.e_=A.a(s([B.i8,B.ip,B.ik]),t.x)
B.ib=new A.q("code",null,null,null,null,null,null,B.e,B.e_,!1,!1,!1,!1,!1,!1,null,!1)
B.hw=new A.q("quote","^>.*$",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hE=new A.q("bullet","^\\s*(?:[*+-]|\\d+\\.)\\s",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.i2=new A.q("strong","\\*\\*[^\\n]+?\\*\\*",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hN=new A.q("strong","__[^\\n]+?__",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hO=new A.q("emphasis","\\*[^\\s*][^\\n*]*?\\*",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.io=new A.q("emphasis","_[^\\s_][^\\n_]*?_",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.h2=new A.q("link","!?\\[[^\\]\\n]*\\]\\([^)\\n]*\\)",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.ig=new A.q("link","^\\[[^\\]\\n]*\\]:.*$",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hM=new A.q("strong","^(?:---|\\*\\*\\*|___)$",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cO=A.a(s([B.h6,B.hi,B.ib,B.hw,B.hE,B.i2,B.hN,B.hO,B.io,B.h2,B.ig,B.hM]),t.x)
B.h8=new A.q(null,null,null,null,null,null,null,B.cO,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cs=new A.aY("markdown",B.ez,B.h8,!1)
B.h7=new A.q(null,null,null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.ct=new A.aY("plain",B.i,B.h7,!1)
B.em=A.a(s(["c","cc","h","hpp","c++"]),t.s)
B.eZ=A.a(s(["alignas","alignof","and","asm","auto","break","case","catch","class","concept","const","consteval","constexpr","constinit","const_cast","continue","co_await","co_return","co_yield","decltype","default","delete","do","dynamic_cast","else","enum","explicit","export","extern","final","for","friend","goto","if","inline","mutable","namespace","new","noexcept","not","operator","or","override","private","protected","public","register","reinterpret_cast","requires","return","sizeof","static","static_assert","static_cast","struct","switch","template","this","thread_local","throw","try","typedef","typeid","typename","union","using","virtual","volatile","while","xor"]),t.s)
B.dL=A.a(s(["bool","char","char8_t","char16_t","char32_t","double","float","int","int8_t","int16_t","int32_t","int64_t","long","short","signed","size_t","unsigned","uint8_t","uint32_t","uint64_t","void","wchar_t"]),t.s)
B.eU=A.a(s(["true","false","nullptr","NULL"]),t.s)
B.eM=A.a(s(["std","string","wstring","vector","map","unordered_map","set","array","list","deque","pair","tuple","optional","variant","shared_ptr","unique_ptr","cout","cerr","cin","endl","printf","scanf","malloc","free","memcpy","strlen"]),t.s)
B.fS=new A.E(B.ap,[B.eZ,B.dL,B.eU,B.eM],t.W)
B.N=new A.q("comment","//",null,"$",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.bs=new A.q("meta","^[ \\t]*#\\s*\\w+",null,"$",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.L=new A.q("string",'"',null,'"',"\\n",null,null,B.J,null,!1,!1,!1,!1,!1,!1,null,!1)
B.M=new A.q("string","'",null,"'","\\n",null,null,B.J,null,!1,!1,!1,!1,!1,!1,null,!1)
B.B=new A.q("number","\\b(0[bB][01_]+|0[oO][0-7_]+|0[xX][a-fA-F0-9_]+|(\\d[\\d_]*(\\.[\\d_]*)?|\\.\\d[\\d_]*)([eE][-+]?\\d+)?)([uUlLfFdD]|[uU][lL]{1,2}|[lL]{1,2}[uU]?)?",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.ea=A.a(s(["class","struct","union","enum","namespace"]),t.s)
B.br=new A.q("title","[A-Za-z_]\\w*",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.af=A.a(s([B.br]),t.x)
B.hT=new A.q(null,null,B.ea,"[{;:<>=\\n]",null,null,null,B.af,null,!1,!1,!1,!0,!1,!1,null,!1)
B.df=A.a(s([B.N,B.x,B.bs,B.L,B.M,B.B,B.hT]),t.x)
B.h1=new A.q(null,null,null,null,null,B.fS,null,B.df,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cu=new A.aY("cpp",B.em,B.h1,!1)
B.eI=A.a(s(["py","gyp"]),t.s)
B.a2={keyword:0,literal:1,built_in:2}
B.cH=A.a(s(["and","as","assert","async","await","break","class","continue","def","del","elif","else","except","finally","for","from","global","if","import","in","is","lambda","match","nonlocal","not","or","pass","raise","return","try","while","with","yield"]),t.s)
B.eo=A.a(s(["True","False","None","NotImplemented","Ellipsis"]),t.s)
B.dO=A.a(s(["abs","all","any","bool","bytes","callable","chr","dict","dir","divmod","enumerate","eval","filter","float","format","frozenset","getattr","hasattr","hash","hex","id","input","int","isinstance","issubclass","iter","len","list","map","max","min","next","object","oct","open","ord","pow","print","property","range","repr","reversed","round","set","setattr","slice","sorted","staticmethod","str","sum","super","tuple","type","vars","zip","self"]),t.s)
B.fA=new A.E(B.a2,[B.cH,B.eo,B.dO],t.W)
B.a1=new A.q("comment","#",null,"$",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.fY=new A.q(null,'[uUbBrRfF]*"""',null,'"""',null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hQ=new A.q(null,"[uUbBrRfF]*'''",null,"'''",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hv=new A.q(null,'[uUbBrRfF]*"',null,'"',"\\n",null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.ij=new A.q(null,"[uUbBrRfF]*'",null,"'","\\n",null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.eB=A.a(s([B.fY,B.hQ,B.hv,B.ij]),t.x)
B.hG=new A.q("string",null,null,null,null,null,null,B.J,B.eB,!1,!1,!1,!1,!1,!1,null,!1)
B.i0=new A.q("meta","^[ \\t]*@[\\w.]+",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.e0=A.a(s(["def","class"]),t.s)
B.i5=new A.q(null,null,B.e0,"[:(\\n]",null,null,null,B.af,null,!1,!1,!1,!0,!1,!1,null,!1)
B.dr=A.a(s([B.a1,B.hG,B.i0,B.B,B.i5]),t.x)
B.hx=new A.q(null,null,null,null,null,B.fA,null,B.dr,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cv=new A.aY("python",B.eI,B.hx,!1)
B.ef=A.a(s(["csharp","c#"]),t.s)
B.bw={keyword:0,type:1,literal:2}
B.eD=A.a(s(["abstract","as","base","break","case","catch","checked","class","const","continue","default","delegate","do","else","enum","event","explicit","extern","finally","fixed","for","foreach","goto","if","implicit","in","init","interface","internal","is","lock","namespace","new","operator","out","override","params","private","protected","public","readonly","record","ref","return","sealed","sizeof","stackalloc","static","struct","switch","this","throw","try","typeof","unchecked","unsafe","using","virtual","void","volatile","while","async","await","get","set","value","var","when","where","yield","nameof","partial","global","from","select","group","into","orderby","join","let","on","equals","by","ascending","descending"]),t.s)
B.eF=A.a(s(["bool","byte","char","decimal","double","dynamic","float","int","long","object","sbyte","short","string","uint","ulong","ushort","Task","List","Dictionary","IEnumerable"]),t.s)
B.eC=A.a(s(["null","true","false","default"]),t.s)
B.f6=new A.E(B.bw,[B.eD,B.eF,B.eC],t.W)
B.i3=new A.q(null,'\\$?@"',null,'"',null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hg=new A.q(null,'\\$"',null,'"',"\\n",null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cL=A.a(s([B.i3,B.hg]),t.x)
B.hH=new A.q("string",null,null,null,null,null,null,B.J,B.cL,!1,!1,!1,!1,!1,!1,null,!1)
B.ia=new A.q("meta-string",'"',null,'"',null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cM=A.a(s([B.ia]),t.x)
B.hV=new A.q("meta","\\[[A-Za-z]",null,"\\]",null,null,null,B.cM,null,!0,!1,!1,!1,!1,!1,null,!1)
B.dB=A.a(s(["class","interface","struct","enum","record","namespace"]),t.s)
B.i6=new A.q(null,null,B.dB,"[{;:<\\n]",null,null,null,B.af,null,!1,!1,!1,!0,!1,!1,null,!1)
B.es=A.a(s([B.N,B.x,B.bs,B.hH,B.L,B.M,B.B,B.hV,B.i6]),t.x)
B.il=new A.q(null,null,null,null,null,B.f6,null,B.es,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cw=new A.aY("cs",B.ef,B.il,!1)
B.cP=A.a(s(["js","jsx","ts","typescript","mjs","cjs"]),t.s)
B.cS=A.a(s(["as","async","await","break","case","catch","class","const","continue","debugger","default","delete","do","else","enum","export","extends","finally","for","from","function","get","if","implements","import","in","instanceof","interface","let","new","of","package","private","protected","public","return","set","static","super","switch","this","throw","try","typeof","var","void","while","with","yield","readonly","declare","namespace","type","abstract","override","satisfies","keyof","infer","is"]),t.s)
B.eA=A.a(s(["true","false","null","undefined","NaN","Infinity"]),t.s)
B.cG=A.a(s(["Array","Boolean","Date","Error","Function","JSON","Map","Math","Number","Object","Promise","Proxy","RegExp","Set","String","Symbol","WeakMap","console","document","window","globalThis","require","module","exports","process","setTimeout","setInterval","clearTimeout","fetch","parseInt","parseFloat","isNaN","eval"]),t.s)
B.bi=new A.E(B.a2,[B.cS,B.eA,B.cG],t.W)
B.dP=A.a(s([B.ao]),t.x)
B.hu=new A.q("subst","\\$\\{",null,"\\}",null,B.bi,null,B.dP,null,!1,!1,!1,!1,!1,!1,null,!1)
B.en=A.a(s([B.a0,B.hu]),t.x)
B.hR=new A.q("string","`",null,"`",null,null,null,B.en,null,!1,!1,!1,!1,!1,!1,null,!1)
B.ed=A.a(s(["function"]),t.s)
B.bp=new A.q("title","[A-Za-z_$][\\w$]*",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cR=A.a(s([B.bp]),t.x)
B.ih=new A.q(null,null,B.ed,"[({;\\n]",null,null,null,B.cR,null,!1,!1,!1,!0,!1,!1,null,!1)
B.dV=A.a(s(["class","interface","enum"]),t.s)
B.bn=new A.q("keyword","\\b(?:extends|implements|permits)\\b",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.d7=A.a(s([B.bn,B.bp]),t.x)
B.h5=new A.q(null,null,B.dV,"[{;\\n]",null,null,null,B.d7,null,!1,!1,!1,!0,!1,!1,null,!1)
B.dw=A.a(s([B.N,B.x,B.hR,B.L,B.M,B.B,B.ih,B.h5]),t.x)
B.h0=new A.q(null,null,null,null,null,B.bi,null,B.dw,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cx=new A.aY("javascript",B.cP,B.h0,!1)
B.eL=A.a(s(["rb","gemspec","ruby"]),t.s)
B.eq=A.a(s(["alias","and","begin","break","case","class","def","defined?","do","each","else","elsif","end","ensure","for","if","in","module","next","not","or","redo","rescue","retry","return","self","super","then","throw","undef","unless","until","when","while","yield","lambda","proc","require","require_relative","include","extend","attr_accessor","attr_reader","attr_writer","private","protected","public","raise","new"]),t.s)
B.eT=A.a(s(["true","false","nil"]),t.s)
B.e9=A.a(s(["puts","print","p","gets","loop","format","Array","Hash","String"]),t.s)
B.fB=new A.E(B.a2,[B.eq,B.eT,B.e9],t.W)
B.hX=new A.q("comment","^=begin",null,"^=end",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hq=new A.q("subst","#\\{",null,"\\}",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.eV=A.a(s([B.a0,B.hq]),t.x)
B.hm=new A.q(null,"%[qQwWi]?\\(",null,"\\)",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.dG=A.a(s([B.bm,B.bl,B.hm]),t.x)
B.hj=new A.q("string",null,null,null,null,null,null,B.eV,B.dG,!1,!1,!1,!1,!1,!1,null,!1)
B.i_=new A.q("symbol",":[A-Za-z_]\\w*[?!=]?",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hJ=new A.q("variable","@{1,2}[A-Za-z_]\\w*",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hk=new A.q("variable","\\$[A-Za-z_]\\w*",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.dY=A.a(s(["class","module","def"]),t.s)
B.h9=new A.q("title","[A-Za-z_][\\w:.]*[?!=]?",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.du=A.a(s([B.h9]),t.x)
B.hL=new A.q(null,null,B.dY,"[\\n;(]",null,null,null,B.du,null,!1,!1,!1,!0,!1,!1,null,!1)
B.cN=A.a(s([B.a1,B.hX,B.hj,B.i_,B.hJ,B.hk,B.B,B.hL]),t.x)
B.hI=new A.q(null,null,null,null,null,B.fB,null,B.cN,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cy=new A.aY("ruby",B.eL,B.hI,!1)
B.cQ=A.a(s(["abstract","assert","break","case","catch","class","const","continue","default","do","else","enum","extends","final","finally","for","goto","if","implements","import","instanceof","interface","native","new","non-sealed","package","permits","private","protected","public","record","return","sealed","static","strictfp","super","switch","synchronized","this","throw","throws","transient","try","var","volatile","while","yield"]),t.s)
B.d8=A.a(s(["boolean","byte","char","double","float","int","long","short","void","String","Integer","Boolean","Long","Double","Object","List","Map","Set","ArrayList","HashMap","Optional","Stream"]),t.s)
B.f7=new A.E(B.bw,[B.cQ,B.d8,B.bd],t.W)
B.h4=new A.q("meta","@[A-Za-z]\\w*",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.dW=A.a(s(["class","interface","enum","record"]),t.s)
B.aQ=A.a(s([B.bn,B.br]),t.x)
B.ie=new A.q(null,null,B.dW,"[{<(\\n]",null,null,null,B.aQ,null,!1,!1,!1,!0,!1,!1,null,!1)
B.ej=A.a(s([B.N,B.x,B.L,B.M,B.B,B.h4,B.ie]),t.x)
B.h3=new A.q(null,null,null,null,null,B.f7,null,B.ej,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cz=new A.aY("java",B.i,B.h3,!1)
B.ei=A.a(s(["html","xhtml","svg"]),t.s)
B.im=new A.q("comment","<!--",null,"-->",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hy=new A.q("meta","<[!?]",null,">",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.i9=new A.q("symbol","&[a-zA-Z#][a-zA-Z0-9]*;",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.bo=new A.q("string","'",null,"'",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hh=new A.q("attr","[A-Za-z_:][A-Za-z0-9._:-]*",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.f0=A.a(s([B.bq,B.bo,B.hh]),t.x)
B.h_=new A.q("tag","</?[A-Za-z][A-Za-z0-9._:-]*",null,"/?>",null,null,null,B.f0,null,!1,!1,!1,!1,!1,!1,null,!1)
B.dc=A.a(s([B.im,B.hy,B.i9,B.h_]),t.x)
B.ht=new A.q(null,null,null,null,null,null,null,B.dc,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cA=new A.aY("xml",B.ei,B.ht,!0)
B.eH=A.a(s(["php8"]),t.s)
B.dd=A.a(s(["abstract","and","array","as","break","callable","case","catch","class","clone","const","continue","declare","default","do","echo","else","elseif","empty","enddeclare","endfor","endforeach","endif","endswitch","endwhile","enum","extends","final","finally","fn","for","foreach","function","global","goto","if","implements","include","include_once","instanceof","insteadof","interface","isset","list","match","namespace","new","or","print","private","protected","public","readonly","require","require_once","return","static","switch","throw","trait","try","unset","use","var","while","xor","yield"]),t.s)
B.er=A.a(s(["int","float","bool","string","void","iterable","object","mixed","never"]),t.s)
B.eO=A.a(s(["true","false","null","TRUE","FALSE","NULL"]),t.s)
B.eY=A.a(s(["array_map","array_filter","array_merge","array_keys","count","implode","explode","sprintf","printf","strlen","str_replace","json_encode","json_decode","var_dump","preg_match","preg_replace","in_array","is_array","isset","die","exit"]),t.s)
B.fT=new A.E(B.ap,[B.dd,B.er,B.eO,B.eY],t.W)
B.ho=new A.q("meta","<\\?(?:php|=)?|\\?>",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.ic=new A.q("variable","\\$+[A-Za-z_]\\w*",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.dX=A.a(s(["class","interface","trait","enum"]),t.s)
B.hZ=new A.q(null,null,B.dX,"[{;\\n]",null,null,null,B.aQ,null,!1,!1,!1,!0,!1,!1,null,!1)
B.dl=A.a(s([B.N,B.x,B.a1,B.ho,B.ic,B.L,B.M,B.B,B.hZ]),t.x)
B.hF=new A.q(null,null,null,null,null,B.fT,null,B.dl,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cB=new A.aY("php",B.eH,B.hF,!1)
B.eP=A.a(s(["sh","shell","zsh"]),t.s)
B.eg=A.a(s(["if","then","else","elif","fi","for","while","until","in","do","done","case","esac","function","select","time"]),t.s)
B.eS=A.a(s(["true","false"]),t.s)
B.de=A.a(s(["break","cd","continue","eval","exec","exit","export","getopts","hash","pwd","readonly","return","shift","test","trap","umask","unset","alias","bind","builtin","command","declare","echo","enable","help","let","local","logout","printf","read","shopt","source","type","typeset","ulimit","unalias","set","ls","cat","grep","sed","awk","mkdir","rm","cp","mv","git","npm","dart","flutter","sudo","curl","chmod"]),t.s)
B.fC=new A.E(B.a2,[B.eg,B.eS,B.de],t.W)
B.hK=new A.q(null,"\\$[\\w#!?*@-]+",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hP=new A.q(null,"\\$\\{",null,"\\}",null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.dK=A.a(s([B.hK,B.hP]),t.x)
B.bt=new A.q("variable",null,null,null,null,null,null,B.e,B.dK,!1,!1,!1,!1,!1,!1,null,!1)
B.d6=A.a(s([B.a0,B.bt]),t.x)
B.id=new A.q("string",'"',null,'"',null,null,null,B.d6,null,!1,!1,!1,!1,!1,!1,null,!1)
B.d3=A.a(s([B.a1,B.id,B.bo,B.bt,B.ao]),t.x)
B.i1=new A.q(null,null,null,null,null,B.fC,null,B.d3,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cC=new A.aY("bash",B.eP,B.i1,!1)
B.eG=A.a(s(["patch"]),t.s)
B.hd=new A.q(null,"^@@ .*? @@$",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.hb=new A.q(null,"^\\*\\*\\* .*? \\*\\*\\*\\*$",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.fV=new A.q(null,"^(?:diff --git|index |---|\\+\\+\\+|===).*$",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cZ=A.a(s([B.hd,B.hb,B.fV]),t.x)
B.hU=new A.q("meta",null,null,null,null,null,null,B.e,B.cZ,!1,!1,!1,!1,!1,!1,null,!1)
B.ha=new A.q("addition","^\\+.*$",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.he=new A.q("deletion","^-.*$",null,null,null,null,null,B.e,null,!1,!1,!1,!1,!1,!1,null,!1)
B.et=A.a(s([B.hU,B.ha,B.he]),t.x)
B.hC=new A.q(null,null,null,null,null,null,null,B.et,null,!1,!1,!1,!1,!1,!1,null,!1)
B.cD=new A.aY("diff",B.eG,B.hC,!1)
B.cE=new A.o9(!1)
B.bW=new A.ep(A.ax("ep<aZ>"))
B.cF=new A.dS(B.bW,A.ax("dS<aZ>"))
B.cI=A.a(s(["ql-video"]),t.s)
B.cK=A.a(s([0,0,32722,12287,65534,34815,65534,18431]),t.X)
B.U=A.a(s([0,0,65490,45055,65535,34815,65534,18431]),t.X)
B.aR=A.a(s([0,0,32754,11263,65534,34815,65534,18431]),t.X)
B.aS=A.a(s(["dashed","dotted","double","groove","inset","none","outset","ridge","solid"]),t.s)
B.jb=new A.ao(1000,"M")
B.jp=new A.ao(900,"CM")
B.jm=new A.ao(500,"D")
B.ji=new A.ao(400,"CD")
B.jc=new A.ao(100,"C")
B.jq=new A.ao(90,"XC")
B.jn=new A.ao(50,"L")
B.jj=new A.ao(40,"XL")
B.jd=new A.ao(10,"X")
B.jr=new A.ao(9,"IX")
B.jo=new A.ao(5,"V")
B.jl=new A.ao(4,"IV")
B.je=new A.ao(1,"I")
B.cT=A.a(s([B.jb,B.jp,B.jm,B.ji,B.jc,B.jq,B.jn,B.jj,B.jd,B.jr,B.jo,B.jl,B.je]),A.ax("w<+(j,e)>"))
B.cU=A.a(s(["A"]),t.s)
B.cV=A.a(s(["BLOCKQUOTE"]),t.s)
B.cW=A.a(s(["table-list"]),t.s)
B.cX=A.a(s(["BR"]),t.s)
B.cY=A.a(s(["Backspace","Delete"]),t.s)
B.aT=A.a(s(["cursor","inline","link","underline","strike","italic","bold","script","code"]),t.s)
B.d_=A.a(s(["CODE"]),t.s)
B.d0=A.a(s(["COL"]),t.s)
B.d1=A.a(s(["COLGROUP"]),t.s)
B.V=A.a(s(["DIV"]),t.s)
B.jw=new A.ba("black","#000000")
B.jt=new A.ba("dimGrey","#4d4d4d")
B.jB=new A.ba("grey","#808080")
B.jJ=new A.ba("lightGrey","#e6e6e6")
B.jg=new A.ba("white","#ffffff")
B.jx=new A.ba("red","#ff0000")
B.jF=new A.ba("orange","#ffa500")
B.ju=new A.ba("yellow","#ffff00")
B.js=new A.ba("lightGreen","#99e64d")
B.jk=new A.ba("green","#008000")
B.jf=new A.ba("aquamarine","#7fffd4")
B.jy=new A.ba("turquoise","#40e0d0")
B.jv=new A.ba("lightBlue","#4d99e6")
B.jE=new A.ba("blue","#0000ff")
B.jI=new A.ba("purple","#800080")
B.d2=A.a(s([B.jw,B.jt,B.jB,B.jJ,B.jg,B.jx,B.jF,B.ju,B.js,B.jk,B.jf,B.jy,B.jv,B.jE,B.jI]),A.ax("w<+describe,value(e,e)>"))
B.aa=A.a(s(["EM","I"]),t.s)
B.d4=A.a(s(["ql-table-header"]),t.s)
B.W=A.a(s([0,0,26624,1023,65534,2047,65534,2047]),t.X)
B.da=A.a(s(["IFRAME"]),t.s)
B.db=A.a(s(["IMG"]),t.s)
B.a3={header:0}
B.ey=A.a(s(["1","2","3",!1]),t.tl)
B.f5=new A.E(B.a3,[B.ey],A.ax("E<e,t<J>>"))
B.di=A.a(s([B.f5]),t.tl)
B.dR=A.a(s(["bold","italic","underline","link"]),t.tl)
B.bv={list:0}
B.fc=new A.E(B.bv,["ordered"],t.w)
B.fb=new A.E(B.bv,["bullet"],t.w)
B.dj=A.a(s([B.fc,B.fb]),t.tl)
B.j6={table:0}
B.fD=new A.E(B.j6,["3x3"],t.w)
B.dk=A.a(s([B.fD]),t.tl)
B.dZ=A.a(s(["clean"]),t.tl)
B.aU=A.a(s([B.di,B.dR,B.dj,B.dk,B.dZ]),A.ax("w<t<J>>"))
B.aV=A.a(s(["ql-code-block-container"]),t.s)
B.aW=A.a(s(["LI"]),t.s)
B.dQ=A.a(s(["bold","italic","link"]),t.n)
B.f3=new A.E(B.a3,[1],t.hq)
B.f4=new A.E(B.a3,[2],t.hq)
B.d9=A.a(s([B.f3,B.f4,"blockquote"]),t.n)
B.aX=A.a(s([B.dQ,B.d9]),t.t6)
B.dg=A.a(s([0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0,0,0]),t.X)
B.dh=A.a(s(["table-th-block"]),t.s)
B.aY=A.a(s([0,0,65490,12287,65535,34815,65534,18431]),t.X)
B.dm=A.a(s([16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15]),t.X)
B.dn=A.a(s(["#000000","#e60000","#ff9900","#ffff00","#008a00","#0066cc","#9933ff","#ffffff","#facccc","#ffebcc","#ffffcc","#cce8cc","#cce0f5","#ebd6ff","#bbbbbb","#f06666","#ffc266","#ffff66","#66b966","#66a3e0","#c285ff","#888888","#a10000","#b26b00","#b2b200","#006100","#0047b2","#6b24b2","#444444","#5c0000","#663d00","#666600","#003700","#002966","#3d1466"]),t.s)
B.dq=A.a(s(["http","https","mailto","tel","sms"]),t.s)
B.aZ=A.a(s(["OL"]),t.s)
B.ds=A.a(s(["selectionchange","mousedown","mouseup","click"]),t.s)
B.ab=A.a(s(["P"]),t.s)
B.b_=A.a(s(["alt","height","width","data-image-wrap","data-anchor","data-anchor-x","data-anchor-y"]),t.s)
B.dx=A.a(s(["ql-formula"]),t.s)
B.F=A.a(s(["SPAN"]),t.s)
B.ac=A.a(s(["STRONG","B"]),t.s)
B.dz=A.a(s(["SUB","SUP"]),t.s)
B.ad=A.a(s(["S","STRIKE"]),t.s)
B.dA=A.a(s(["bold","italic","underline","strike","size","color","background","font","list","header","align","link","image"]),t.s)
B.b0=A.a(s(["TABLE"]),t.s)
B.b1=A.a(s(["TBODY"]),t.s)
B.b2=A.a(s(["TD"]),t.s)
B.b3=A.a(s(["image/png","image/jpeg"]),t.s)
B.dC=A.a(s(["TEMPORARY"]),t.s)
B.dD=A.a(s(["TH"]),t.s)
B.dE=A.a(s(["THEAD"]),t.s)
B.ae=A.a(s(["TR"]),t.s)
B.dF=A.a(s(["U"]),t.s)
B.X=A.a(s([0,0,32776,33792,1,10240,0,0]),t.X)
B.dH=A.a(s(["nw","n","ne","e","se","s","sw","w"]),t.s)
B.dI=A.a(s(["aliceblue","antiquewhite","aqua","aquamarine","azure","beige","bisque","black","blanchedalmond","blue","blueviolet","brown","burlywood","cadetblue","chartreuse","chocolate","coral","cornflowerblue","cornsilk","crimson","currentcolor","cyan","darkblue","darkcyan","darkgoldenrod","darkgray","darkgreen","darkgrey","darkkhaki","darkmagenta","darkolivegreen","darkorange","darkorchid","darkred","darksalmon","darkseagreen","darkslateblue","darkslategray","darkslategrey","darkturquoise","darkviolet","deeppink","deepskyblue","dimgray","dimgrey","dodgerblue","firebrick","floralwhite","forestgreen","fuchsia","gainsboro","ghostwhite","gold","goldenrod","gray","green","greenyellow","grey","honeydew","hotpink","indianred","indigo","ivory","khaki","lavender","lavenderblush","lawngreen","lemonchiffon","lightblue","lightcoral","lightcyan","lightgoldenrodyellow","lightgray","lightgreen","lightgrey","lightpink","lightsalmon","lightseagreen","lightskyblue","lightslategray","lightslategrey","lightsteelblue","lightyellow","lime","limegreen","linen","magenta","maroon","mediumaquamarine","mediumblue","mediumorchid","mediumpurple","mediumseagreen","mediumslateblue","mediumspringgreen","mediumturquoise","mediumvioletred","midnightblue","mintcream","mistyrose","moccasin","navajowhite","navy","oldlace","olive","olivedrab","orange","orangered","orchid","palegoldenrod","palegreen","paleturquoise","palevioletred","papayawhip","peachpuff","peru","pink","plum","powderblue","purple","rebeccapurple","red","rosybrown","royalblue","saddlebrown","salmon","sandybrown","seagreen","seashell","sienna","silver","skyblue","slateblue","slategray","slategrey","snow","springgreen","steelblue","tan","teal","thistle","tomato","transparent","turquoise","violet","wheat","white","whitesmoke","yellow","yellowgreen"]),t.s)
B.b4=A.a(s([1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577]),t.X)
B.dJ=A.a(s(["ql-table-block"]),t.s)
B.jC=new A.h6("check","save")
B.jD=new A.h6("close","cancel")
B.dM=A.a(s([B.jC,B.jD]),A.ax("w<+icon,label(e,e)>"))
B.dS=A.a(s(["border","cellspacing","style","class"]),t.s)
B.dT=A.a(s(["border-style","border-color","border-width","background-color","width","height","padding","text-align","vertical-align"]),t.s)
B.b5=A.a(s(["colspan","rowspan"]),t.s)
B.b6=A.a(s(["ql-code-block"]),t.s)
B.ai=A.a(s([]),t.r)
B.ag=A.a(s([]),t.jp)
B.Y=A.a(s([]),t.B)
B.b7=A.a(s([]),t.yX)
B.e5=A.a(s([]),t.Cu)
B.ah=A.a(s([]),t.fE)
B.e7=A.a(s([]),t.sW)
B.e3=A.a(s([]),t.ux)
B.e2=A.a(s([]),t.bD)
B.G=A.a(s([]),t.xC)
B.Z=A.a(s([]),t.yU)
B.e4=A.a(s([]),A.ax("w<b2>"))
B.e8=A.a(s([]),t.BR)
B.b8=A.a(s([]),t.qo)
B.eb=A.a(s([!1,"center","right","justify"]),t.n)
B.ec=A.a(s([!1,"serif","monospace"]),t.n)
B.b9=A.a(s(["data-row","width","height","colspan","rowspan","style"]),t.s)
B.aj=A.a(s(["height","width"]),t.s)
B.ek=A.a(s(["ql-cursor"]),t.s)
B.el=A.a(s(["border-style","border-color","border-width","background-color","width","height","align"]),t.s)
B.ep=A.a(s(["ql-token"]),t.s)
B.eu=A.a(s(["link","image"]),t.s)
B.ew=A.a(s([0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13]),t.X)
B.ev=A.a(s([5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5]),t.X)
B.ex=A.a(s(["1","2","3",!1]),t.n)
B.ba=A.a(s([3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258]),t.X)
B.a_=A.a(s([0,0,24576,1023,65534,34815,65534,18431]),t.X)
B.eJ=A.a(s(["table-list-container"]),t.s)
B.mJ=new A.aU("plain","Plain")
B.mB=new A.aU("bash","Bash")
B.mz=new A.aU("cpp","C++")
B.mC=new A.aU("cs","C#")
B.mD=new A.aU("css","CSS")
B.mE=new A.aU("diff","Diff")
B.mA=new A.aU("xml","HTML/XML")
B.mF=new A.aU("java","Java")
B.mG=new A.aU("javascript","JavaScript")
B.mH=new A.aU("markdown","Markdown")
B.mI=new A.aU("php","PHP")
B.mK=new A.aU("python","Python")
B.mL=new A.aU("ruby","Ruby")
B.mM=new A.aU("sql","SQL")
B.bb=A.a(s([B.mJ,B.mB,B.mz,B.mC,B.mD,B.mE,B.mA,B.mF,B.mG,B.mH,B.mI,B.mK,B.mL,B.mM]),A.ax("w<aU>"))
B.eN=A.a(s([8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8]),t.X)
B.eQ=A.a(s(["small",!1,"large","huge"]),t.n)
B.bc=A.a(s(["border","cellspacing","style","data-class"]),t.s)
B.eR=A.a(s([!0,!1]),A.ax("w<x>"))
B.eX=A.a(s(["ql-table-temporary"]),t.s)
B.w=A.a(s(["H1","H2","H3","H4","H5","H6"]),t.s)
B.f_=A.a(s(["width"]),t.s)
B.f2=A.a(s(["margin-left","margin-right"]),t.s)
B.be=new A.F(null,0,t.nv)
B.al=new A.F(null,-1,t.nv)
B.bf=new A.F(null,-1,t.lB)
B.j3={scope:0}
B.f8=new A.E(B.j3,[2],t.BV)
B.iD={"\\alpha":0,"\\beta":1,"\\gamma":2,"\\delta":3,"\\epsilon":4,"\\varepsilon":5,"\\zeta":6,"\\eta":7,"\\theta":8,"\\vartheta":9,"\\iota":10,"\\kappa":11,"\\lambda":12,"\\mu":13,"\\nu":14,"\\xi":15,"\\pi":16,"\\varpi":17,"\\rho":18,"\\varrho":19,"\\sigma":20,"\\varsigma":21,"\\tau":22,"\\upsilon":23,"\\phi":24,"\\varphi":25,"\\chi":26,"\\psi":27,"\\omega":28,"\\Gamma":29,"\\Delta":30,"\\Theta":31,"\\Lambda":32,"\\Xi":33,"\\Pi":34,"\\Sigma":35,"\\Upsilon":36,"\\Phi":37,"\\Psi":38,"\\Omega":39,"\\pm":40,"\\mp":41,"\\times":42,"\\div":43,"\\cdot":44,"\\ast":45,"\\star":46,"\\circ":47,"\\bullet":48,"\\oplus":49,"\\ominus":50,"\\otimes":51,"\\oslash":52,"\\odot":53,"\\cap":54,"\\cup":55,"\\uplus":56,"\\sqcap":57,"\\sqcup":58,"\\vee":59,"\\lor":60,"\\wedge":61,"\\land":62,"\\setminus":63,"\\bmod":64,"\\leq":65,"\\le":66,"\\geq":67,"\\ge":68,"\\neq":69,"\\ne":70,"\\ll":71,"\\gg":72,"\\equiv":73,"\\sim":74,"\\simeq":75,"\\approx":76,"\\cong":77,"\\propto":78,"\\subset":79,"\\supset":80,"\\subseteq":81,"\\supseteq":82,"\\in":83,"\\ni":84,"\\notin":85,"\\perp":86,"\\parallel":87,"\\mid":88,"\\models":89,"\\prec":90,"\\succ":91,"\\doteq":92,"\\asymp":93,"\\leftarrow":94,"\\gets":95,"\\rightarrow":96,"\\to":97,"\\leftrightarrow":98,"\\Leftarrow":99,"\\Rightarrow":100,"\\Leftrightarrow":101,"\\iff":102,"\\implies":103,"\\mapsto":104,"\\uparrow":105,"\\downarrow":106,"\\updownarrow":107,"\\longrightarrow":108,"\\longleftarrow":109,"\\hookrightarrow":110,"\\sum":111,"\\prod":112,"\\coprod":113,"\\bigcup":114,"\\bigcap":115,"\\bigoplus":116,"\\bigotimes":117,"\\bigvee":118,"\\bigwedge":119,"\\int":120,"\\iint":121,"\\iiint":122,"\\oint":123,"\\infty":124,"\\partial":125,"\\nabla":126,"\\forall":127,"\\exists":128,"\\nexists":129,"\\neg":130,"\\lnot":131,"\\emptyset":132,"\\varnothing":133,"\\aleph":134,"\\hbar":135,"\\ell":136,"\\Re":137,"\\Im":138,"\\wp":139,"\\prime":140,"\\angle":141,"\\triangle":142,"\\square":143,"\\degree":144,"\\dots":145,"\\ldots":146,"\\cdots":147,"\\vdots":148,"\\ddots":149,"\\checkmark":150,"\\dagger":151,"\\ddagger":152,"\\%":153,"\\$":154,"\\#":155,"\\&":156,"\\_":157,"\\{":158,"\\}":159,"\\backslash":160,"\\lbrace":161,"\\rbrace":162,"\\langle":163,"\\rangle":164,"\\lceil":165,"\\rceil":166,"\\lfloor":167,"\\rfloor":168,"\\lvert":169,"\\rvert":170,"\\lVert":171,"\\rVert":172,"\\vert":173,"\\Vert":174}
B.lK=new A.n("\u03b1",B.c,!1)
B.kS=new A.n("\u03b2",B.c,!1)
B.m2=new A.n("\u03b3",B.c,!1)
B.kH=new A.n("\u03b4",B.c,!1)
B.ms=new A.n("\u03f5",B.c,!1)
B.lO=new A.n("\u03b5",B.c,!1)
B.l8=new A.n("\u03b6",B.c,!1)
B.lE=new A.n("\u03b7",B.c,!1)
B.lp=new A.n("\u03b8",B.c,!1)
B.kN=new A.n("\u03d1",B.c,!1)
B.ma=new A.n("\u03b9",B.c,!1)
B.lT=new A.n("\u03ba",B.c,!1)
B.mh=new A.n("\u03bb",B.c,!1)
B.me=new A.n("\u03bc",B.c,!1)
B.kh=new A.n("\u03bd",B.c,!1)
B.kO=new A.n("\u03be",B.c,!1)
B.ks=new A.n("\u03c0",B.c,!1)
B.mq=new A.n("\u03d6",B.c,!1)
B.l6=new A.n("\u03c1",B.c,!1)
B.lI=new A.n("\u03f1",B.c,!1)
B.lx=new A.n("\u03c3",B.c,!1)
B.kC=new A.n("\u03c2",B.c,!1)
B.l9=new A.n("\u03c4",B.c,!1)
B.l4=new A.n("\u03c5",B.c,!1)
B.kI=new A.n("\u03d5",B.c,!1)
B.m7=new A.n("\u03c6",B.c,!1)
B.lq=new A.n("\u03c7",B.c,!1)
B.lk=new A.n("\u03c8",B.c,!1)
B.ke=new A.n("\u03c9",B.c,!1)
B.kU=new A.n("\u0393",B.c,!1)
B.kD=new A.n("\u0394",B.c,!1)
B.la=new A.n("\u0398",B.c,!1)
B.lJ=new A.n("\u039b",B.c,!1)
B.l_=new A.n("\u039e",B.c,!1)
B.m3=new A.n("\u03a0",B.c,!1)
B.kr=new A.n("\u03a3",B.c,!1)
B.lV=new A.n("\u03a5",B.c,!1)
B.lr=new A.n("\u03a6",B.c,!1)
B.ki=new A.n("\u03a8",B.c,!1)
B.mt=new A.n("\u03a9",B.c,!1)
B.ky=new A.n("\xb1",B.j,!1)
B.lt=new A.n("\u2213",B.j,!1)
B.kY=new A.n("\xd7",B.j,!1)
B.lS=new A.n("\xf7",B.j,!1)
B.mg=new A.n("\u22c5",B.j,!1)
B.l1=new A.n("\u2217",B.j,!1)
B.mp=new A.n("\u22c6",B.j,!1)
B.kB=new A.n("\u2218",B.j,!1)
B.lP=new A.n("\u2219",B.j,!1)
B.mi=new A.n("\u2295",B.j,!1)
B.mf=new A.n("\u2296",B.j,!1)
B.kE=new A.n("\u2297",B.j,!1)
B.mm=new A.n("\u2298",B.j,!1)
B.kV=new A.n("\u2299",B.j,!1)
B.kk=new A.n("\u2229",B.j,!1)
B.lD=new A.n("\u222a",B.j,!1)
B.md=new A.n("\u228e",B.j,!1)
B.mr=new A.n("\u2293",B.j,!1)
B.lw=new A.n("\u2294",B.j,!1)
B.bK=new A.n("\u2228",B.j,!1)
B.bJ=new A.n("\u2227",B.j,!1)
B.mj=new A.n("\u2216",B.j,!1)
B.m8=new A.n("mod",B.j,!1)
B.bH=new A.n("\u2264",B.h,!1)
B.bL=new A.n("\u2265",B.h,!1)
B.bF=new A.n("\u2260",B.h,!1)
B.m5=new A.n("\u226a",B.h,!1)
B.km=new A.n("\u226b",B.h,!1)
B.kx=new A.n("\u2261",B.h,!1)
B.kZ=new A.n("\u223c",B.h,!1)
B.m6=new A.n("\u2243",B.h,!1)
B.l2=new A.n("\u2248",B.h,!1)
B.l0=new A.n("\u2245",B.h,!1)
B.l7=new A.n("\u221d",B.h,!1)
B.m9=new A.n("\u2282",B.h,!1)
B.mo=new A.n("\u2283",B.h,!1)
B.le=new A.n("\u2286",B.h,!1)
B.ku=new A.n("\u2287",B.h,!1)
B.kc=new A.n("\u2208",B.h,!1)
B.m_=new A.n("\u220b",B.h,!1)
B.kl=new A.n("\u2209",B.h,!1)
B.kK=new A.n("\u22a5",B.h,!1)
B.kG=new A.n("\u2225",B.h,!1)
B.lU=new A.n("\u2223",B.h,!1)
B.lc=new A.n("\u22a8",B.h,!1)
B.lL=new A.n("\u227a",B.h,!1)
B.kL=new A.n("\u227b",B.h,!1)
B.lh=new A.n("\u2250",B.h,!1)
B.kq=new A.n("\u224d",B.h,!1)
B.bM=new A.n("\u2190",B.h,!1)
B.bD=new A.n("\u2192",B.h,!1)
B.ko=new A.n("\u2194",B.h,!1)
B.lG=new A.n("\u21d0",B.h,!1)
B.kM=new A.n("\u21d2",B.h,!1)
B.kW=new A.n("\u21d4",B.h,!1)
B.kd=new A.n("\u27fa",B.h,!1)
B.kJ=new A.n("\u27f9",B.h,!1)
B.lQ=new A.n("\u21a6",B.h,!1)
B.mx=new A.n("\u2191",B.h,!1)
B.kt=new A.n("\u2193",B.h,!1)
B.ka=new A.n("\u2195",B.h,!1)
B.mu=new A.n("\u27f6",B.h,!1)
B.kf=new A.n("\u27f5",B.h,!1)
B.ln=new A.n("\u21aa",B.h,!1)
B.lz=new A.n("\u2211",B.o,!0)
B.kA=new A.n("\u220f",B.o,!0)
B.ly=new A.n("\u2210",B.o,!0)
B.lj=new A.n("\u22c3",B.o,!0)
B.lZ=new A.n("\u22c2",B.o,!0)
B.kT=new A.n("\u2a01",B.o,!0)
B.kw=new A.n("\u2a02",B.o,!0)
B.l3=new A.n("\u22c1",B.o,!0)
B.mc=new A.n("\u22c0",B.o,!0)
B.kP=new A.n("\u222b",B.o,!1)
B.lH=new A.n("\u222c",B.o,!1)
B.kg=new A.n("\u222d",B.o,!1)
B.l5=new A.n("\u222e",B.o,!1)
B.kF=new A.n("\u221e",B.c,!1)
B.kv=new A.n("\u2202",B.c,!1)
B.lg=new A.n("\u2207",B.c,!1)
B.ml=new A.n("\u2200",B.c,!1)
B.kR=new A.n("\u2203",B.c,!1)
B.lb=new A.n("\u2204",B.c,!1)
B.bN=new A.n("\xac",B.c,!1)
B.bE=new A.n("\u2205",B.c,!1)
B.mw=new A.n("\u2135",B.c,!1)
B.lM=new A.n("\u210f",B.c,!1)
B.mv=new A.n("\u2113",B.c,!1)
B.kQ=new A.n("\u211c",B.c,!1)
B.lm=new A.n("\u2111",B.c,!1)
B.lC=new A.n("\u2118",B.c,!1)
B.lo=new A.n("\u2032",B.c,!1)
B.kp=new A.n("\u2220",B.c,!1)
B.lR=new A.n("\u25b3",B.c,!1)
B.kX=new A.n("\u25a1",B.c,!1)
B.m0=new A.n("\xb0",B.c,!1)
B.bI=new A.n("\u2026",B.c,!1)
B.m4=new A.n("\u22ef",B.c,!1)
B.ld=new A.n("\u22ee",B.c,!1)
B.kz=new A.n("\u22f1",B.c,!1)
B.kb=new A.n("\u2713",B.c,!1)
B.lA=new A.n("\u2020",B.c,!1)
B.lY=new A.n("\u2021",B.c,!1)
B.lF=new A.n("%",B.c,!1)
B.k9=new A.n("$",B.c,!1)
B.lu=new A.n("#",B.c,!1)
B.lN=new A.n("&",B.c,!1)
B.lB=new A.n("_",B.c,!1)
B.bO=new A.n("{",B.A,!1)
B.bG=new A.n("}",B.y,!1)
B.lX=new A.n("\\",B.c,!1)
B.m1=new A.n("\u27e8",B.A,!1)
B.mb=new A.n("\u27e9",B.y,!1)
B.kj=new A.n("\u2308",B.A,!1)
B.lW=new A.n("\u2309",B.y,!1)
B.mn=new A.n("\u230a",B.A,!1)
B.mk=new A.n("\u230b",B.y,!1)
B.lf=new A.n("|",B.A,!1)
B.lv=new A.n("|",B.y,!1)
B.ls=new A.n("\u2016",B.A,!1)
B.li=new A.n("\u2016",B.y,!1)
B.kn=new A.n("|",B.c,!1)
B.ll=new A.n("\u2016",B.c,!1)
B.bg=new A.E(B.iD,[B.lK,B.kS,B.m2,B.kH,B.ms,B.lO,B.l8,B.lE,B.lp,B.kN,B.ma,B.lT,B.mh,B.me,B.kh,B.kO,B.ks,B.mq,B.l6,B.lI,B.lx,B.kC,B.l9,B.l4,B.kI,B.m7,B.lq,B.lk,B.ke,B.kU,B.kD,B.la,B.lJ,B.l_,B.m3,B.kr,B.lV,B.lr,B.ki,B.mt,B.ky,B.lt,B.kY,B.lS,B.mg,B.l1,B.mp,B.kB,B.lP,B.mi,B.mf,B.kE,B.mm,B.kV,B.kk,B.lD,B.md,B.mr,B.lw,B.bK,B.bK,B.bJ,B.bJ,B.mj,B.m8,B.bH,B.bH,B.bL,B.bL,B.bF,B.bF,B.m5,B.km,B.kx,B.kZ,B.m6,B.l2,B.l0,B.l7,B.m9,B.mo,B.le,B.ku,B.kc,B.m_,B.kl,B.kK,B.kG,B.lU,B.lc,B.lL,B.kL,B.lh,B.kq,B.bM,B.bM,B.bD,B.bD,B.ko,B.lG,B.kM,B.kW,B.kd,B.kJ,B.lQ,B.mx,B.kt,B.ka,B.mu,B.kf,B.ln,B.lz,B.kA,B.ly,B.lj,B.lZ,B.kT,B.kw,B.l3,B.mc,B.kP,B.lH,B.kg,B.l5,B.kF,B.kv,B.lg,B.ml,B.kR,B.lb,B.bN,B.bN,B.bE,B.bE,B.mw,B.lM,B.mv,B.kQ,B.lm,B.lC,B.lo,B.kp,B.lR,B.kX,B.m0,B.bI,B.bI,B.m4,B.ld,B.kz,B.kb,B.lA,B.lY,B.lF,B.k9,B.lu,B.lN,B.lB,B.bO,B.bG,B.lX,B.bO,B.bG,B.m1,B.mb,B.kj,B.lW,B.mn,B.mk,B.lf,B.lv,B.ls,B.li,B.kn,B.ll],A.ax("E<e,n>"))
B.is={arccos:0,arcsin:1,arctan:2,arg:3,cos:4,cosh:5,cot:6,coth:7,csc:8,deg:9,det:10,dim:11,exp:12,gcd:13,hom:14,inf:15,injlim:16,ker:17,lg:18,lim:19,liminf:20,limsup:21,ln:22,log:23,max:24,min:25,Pr:26,sec:27,sin:28,sinh:29,sup:30,tan:31,tanh:32}
B.f9=new A.E(B.is,[!1,!1,!1,!1,!1,!1,!1,!1,!1,!1,!0,!1,!1,!0,!1,!0,!0,!1,!1,!0,!0,!0,!1,!1,!0,!0,!0,!1,!1,!1,!0,!1,!1],A.ax("E<e,x>"))
B.iL={"\\mathrm":0,"\\mathbf":1,"\\bold":2,"\\boldsymbol":3,"\\mathit":4,"\\mathbb":5,"\\mathcal":6,"\\mathscr":7,"\\mathfrak":8,"\\mathsf":9,"\\mathtt":10}
B.fd=new A.E(B.iL,["normal","bold","bold","bold-italic","italic","double-struck","script","script","fraktur","sans-serif","monospace"],t.w)
B.iI={"row-insert-top":0,"row-insert-bottom":1,"column-insert-left":2,"column-insert-right":3,"row-remove":4,"column-remove":5,"arrow-merge":6,"arrows-split":7,"table-off":8}
B.fe=new A.E(B.iI,["row-insert-top","row-insert-bottom","column-insert-left","column-insert-right","row-remove","column-remove","arrow-merge","arrows-split","table-off"],t.w)
B.j_={"\\hat":0,"\\widehat":1,"\\check":2,"\\tilde":3,"\\widetilde":4,"\\acute":5,"\\grave":6,"\\dot":7,"\\ddot":8,"\\breve":9,"\\bar":10,"\\overline":11,"\\vec":12,"\\mathring":13,"\\overbrace":14,"\\overrightarrow":15,"\\overleftarrow":16}
B.ff=new A.E(B.j_,["^","^","\u02c7","~","~","\xb4","`","\u02d9","\xa8","\u02d8","\xaf","\xaf","\u2192","\u02da","\u23de","\u2192","\u2190"],t.w)
B.n={col:0,insColL:1,insColR:2,delCol:3,selCol:4,row:5,headerRow:6,insRowAbv:7,insRowBlw:8,delRow:9,selRow:10,mCells:11,sCell:12,tblProps:13,cellProps:14,insParaOTbl:15,insB4:16,insAft:17,copyTable:18,delTable:19,border:20,color:21,width:22,background:23,dims:24,height:25,padding:26,tblCellTxtAlm:27,alCellTxtL:28,alCellTxtC:29,alCellTxtR:30,jusfCellTxt:31,alCellTxtT:32,alCellTxtM:33,alCellTxtB:34,dimsAlm:35,alTblL:36,tblC:37,alTblR:38,save:39,cancel:40,colorMsg:41,dimsMsg:42,colorPicker:43,removeColor:44,black:45,dimGrey:46,grey:47,lightGrey:48,white:49,red:50,orange:51,yellow:52,lightGreen:53,green:54,aquamarine:55,turquoise:56,lightBlue:57,blue:58,purple:59}
B.fh=new A.E(B.n,["\u5217","\u5411\u5de6\u63d2\u5165\u5217","\u5411\u53f3\u63d2\u5165\u5217","\u5220\u9664\u5217","\u9009\u62e9\u5217","\u884c","\u6807\u9898\u884c","\u5728\u4e0a\u9762\u63d2\u5165\u884c","\u5728\u4e0b\u9762\u63d2\u5165\u884c","\u5220\u9664\u884c","\u9009\u62e9\u884c","\u5408\u5e76\u5355\u5143\u683c","\u62c6\u5206\u5355\u5143\u683c","\u8868\u683c\u5c5e\u6027","\u5355\u5143\u683c\u5c5e\u6027","\u5728\u8868\u683c\u5916\u63d2\u5165\u6bb5\u843d","\u5728\u8868\u683c\u524d\u9762\u63d2\u5165","\u5728\u8868\u683c\u540e\u9762\u63d2\u5165","\u590d\u5236\u8868\u683c","\u5220\u9664\u8868\u683c","\u8fb9\u6846","\u989c\u8272","\u5bbd\u5ea6","\u80cc\u666f","\u5c3a\u5bf8","\u9ad8\u5ea6","\u5185\u8fb9\u8ddd","\u5355\u5143\u683c\u6587\u672c\u5bf9\u9f50\u65b9\u5f0f","\u5de6\u5bf9\u9f50","\u6c34\u5e73\u5c45\u4e2d\u5bf9\u9f50","\u53f3\u5bf9\u9f50","\u4e24\u8fb9\u5bf9\u9f50","\u9876\u7aef\u5bf9\u9f50","\u5782\u76f4\u5c45\u4e2d\u5bf9\u9f50","\u5e95\u90e8\u5bf9\u9f50","\u5c3a\u5bf8\u548c\u5bf9\u9f50\u65b9\u5f0f","\u8868\u683c\u5de6\u5bf9\u9f50","\u8868\u683c\u5c45\u4e2d","\u8868\u683c\u53f3\u5bf9\u9f50","\u4fdd\u5b58","\u53d6\u6d88",'\u65e0\u6548\u989c\u8272\uff0c\u8bf7\u4f7f\u7528 "#FF0000" \u6216\u8005 "rgb(255,0,0)" \u6216\u8005 "red"','\u65e0\u6548\u503c\uff0c\u8bf7\u4f7f\u7528 "10px" \u6216\u8005 "2em" \u6216\u8005 "2%" \u6216\u8005 "2"',"\u989c\u8272\u9009\u62e9\u5668","\u5220\u9664\u989c\u8272","\u9ed1\u8272","\u6697\u7070\u8272","\u7070\u8272","\u6d45\u7070\u8272","\u767d\u8272","\u7ea2\u8272","\u6a59\u8272","\u9ec4\u8272","\u6d45\u7eff\u8272","\u7eff\u8272","\u6d77\u84dd\u8272","\u9752\u7eff\u8272","\u6d45\u84dd\u8272","\u84dd\u8272","\u7d2b\u8272"],t.w)
B.fi=new A.E(B.n,["Coluna","Inserir coluna \xe0 esquerda","Inserir coluna \xe0 direita","Eliminar coluna","Selecionar coluna","Linha","Linha de cabe\xe7alho","Inserir linha acima","Inserir linha abaixo","Eliminar linha","Selecionar linha","Unir c\xe9lulas","Dividir c\xe9lula","Propriedades da tabela","Propriedades da c\xe9lula","Inserir par\xe1grafo fora da tabela","Inserir antes","Inserir depois","Copiar tabela","Eliminar tabela","Borda","Cor","Largura","Cor de Fundo","Dimens\xf5es","Altura","Margem interna","Alinhamento do texto","Alinhar texto da c\xe9lula \xe0 esquerda","Alinhar texto da c\xe9lula ao centro","Alinhar texto da c\xe9lula \xe0 direita","Justificar texto da c\xe9lula","Alinhar texto da c\xe9lula no topo","Alinhar texto da c\xe9lula ao meio","Alinhar texto da c\xe9lula na parte inferior","Dimens\xf5es e alinhamento","Alinhar tabela \xe0 esquerda","Centrar tabela","Alinhar tabela \xe0 direita","Guardar","Cancelar",u.Z,'O valor \xe9 inv\xe1lido. Tente "10px" ou "2em" ou "2%" ou apenas "2".',"Selecionar cor","Remover cor","Preto","Cinzento escuro","Cinzento","Cinzento claro","Branco","Vermelho","Laranja","Amarelo","Verde claro","Verde","Azul marinho","Azul turquesa","Azul claro","Azul","Roxo"],t.w)
B.fj=new A.E(B.n,["S\xfctun","Sola s\xfctun ekle","Sa\u011fa s\xfctun ekle","S\xfctunu sil","S\xfctunu se\xe7","Sat\u0131r","Ba\u015fl\u0131k sat\u0131r\u0131","\xdcst\xfcne sat\u0131r ekle","Alt\u0131na sat\u0131r ekle","Sat\u0131r\u0131 sil","Sat\u0131r se\xe7","H\xfccreleri birle\u015ftir","H\xfccreyi b\xf6l","Tablo \xf6zellikleri","H\xfccre \xf6zellikleri","Tablo d\u0131\u015f\u0131nda paragraf ekle","\xd6ncesine ekle","Sonras\u0131na ekle","Tabloyu kopyala","Tabloyu sil","Kenarl\u0131k","Renk","Geni\u015flik","Arka plan","Boyutlar","Y\xfckseklik","Dolgu","Tablo h\xfccresi metin hizalamas\u0131","H\xfccre metnini sola hizala","H\xfccre metnini ortaya hizala","H\xfccre metnini sa\u011fa hizala","H\xfccre metnini yasla","H\xfccre metnini \xfcste hizala","H\xfccre metnini ortaya hizala","H\xfccre metnini alta hizala","Boyutlar ve hizalama","Tabloyu sola hizala","Tabloyu ortala","Tabloyu sa\u011fa hizala","Kaydet","\u0130ptal",'Renk ge\xe7ersiz. "#FF0000", "rgb(255,0,0)" veya "red" deneyin.','De\u011fer ge\xe7ersiz. "10px", "2em" veya "2%" veya sadece "2" deneyin.',"Renk se\xe7ici","Rengi kald\u0131r","Siyah","Koyu gri","Gri","A\xe7\u0131k gri","Beyaz","K\u0131rm\u0131z\u0131","Turuncu","Sar\u0131","A\xe7\u0131k ye\u015fil","Ye\u015fil","Akuamarin","Turkuaz","A\xe7\u0131k mavi","Mavi","Mor"],t.w)
B.fk=new A.E(B.n,["Spalte","Spalte links einf\xfcgen","Spalte rechts einf\xfcgen","Spalte l\xf6schen","Spalte ausw\xe4hlen","Zeile","Kopfzeile","Zeile oberhalb einf\xfcgen","Zeile unterhalb einf\xfcgen","Zeile l\xf6schen","Zeile ausw\xe4hlen","Zellen verbinden","Zelle teilen","Tabelleneingenschaften","Zelleneigenschaften","Absatz au\xdferhalb der Tabelle einf\xfcgen","Davor einf\xfcgen","Danach einf\xfcgen","Tabelle kopieren","Tabelle l\xf6schen","Rahmen","Farbe","Breite","Schattierung","Ma\xdfe","H\xf6he","Abstand","Ausrichtung","Zellentext links ausrichten","Zellentext mittig ausrichten","Zellentext rechts ausrichten","Zellentext Blocksatz","Zellentext oben ausrichten","Zellentext mittig ausrichten","Zellentext unten ausrichten","Ma\xdfe und Ausrichtung","Tabelle links ausrichten","Tabelle mittig ausrichten","Tabelle rechts ausrichten","Speichern","Abbrechen",'Die Farbe ist ung\xfcltig. Probiere "#FF0000", "rgb(255,0,0)" oder "red".','Der Wert ist ung\xfcltig. Probiere "10px", "2em" oder "2%" oder einfach "2".',"Farbw\xe4hler","Farbe entfernen","Schwarz","Dunkelgrau","Grau","Hellgrau","Wei\xdf","Rot","Orange","Gelb","Hellgr\xfcn","Gr\xfcn","Aquamarin","T\xfcrkis","Hellblau","Blau","Lila"],t.w)
B.fl=new A.E(B.n,["Sloupec","Vlo\u017eit sloupec vlevo","Vlo\u017eit sloupec vpravo","Smazat sloupec","Vybrat sloupec","\u0158\xe1dek","\u0158\xe1dek z\xe1hlav\xed","Vlo\u017eit \u0159\xe1dek nad","Vlo\u017eit \u0159\xe1dek pod","Smazat \u0159\xe1dek","Vybrat \u0159\xe1dek","Slou\u010dit bu\u0148ky","Rozd\u011blit bu\u0148ku","Vlastnosti tabulky","Vlastnosti bu\u0148ky","Vlo\u017eit odstavec mimo tabulku","Vlo\u017eit p\u0159ed","Vlo\u017eit za","Kop\xedrovat tabulku","Smazat tabulku","Okraj","Barva","\u0160\xed\u0159ka","Pozad\xed","Rozm\u011bry","V\xfd\u0161ka","Vnit\u0159n\xed okraj","Zarovn\xe1n\xed textu v bu\u0148ce","Zarovnat text vlevo","Zarovnat text na st\u0159ed","Zarovnat text vpravo","Zarovnat text do bloku","Zarovnat text nahoru","Zarovnat text na st\u0159ed (vertik\xe1ln\u011b)","Zarovnat text dol\u016f","Rozm\u011bry a zarovn\xe1n\xed","Zarovnat tabulku vlevo","Zarovnat tabulku na st\u0159ed","Zarovnat tabulku vpravo","Ulo\u017eit","Zru\u0161it",'Barva je neplatn\xe1. Zkuste nap\u0159. "#FF0000", "rgb(255,0,0)" nebo "red".','Hodnota je neplatn\xe1. Zkuste "10px", "2em" nebo "2%" nebo jednodu\u0161e "2".',"V\xfdb\u011br barvy","Odebrat barvu","\u010cern\xe1","Tmav\u011b \u0161ed\xe1","\u0160ed\xe1","Sv\u011btle \u0161ed\xe1","B\xedl\xe1","\u010cerven\xe1","Oran\u017eov\xe1","\u017dlut\xe1","Sv\u011btle zelen\xe1","Zelen\xe1","Akvamar\xednov\xe1","Tyrkysov\xe1","Sv\u011btle modr\xe1","Modr\xe1","Fialov\xe1"],t.w)
B.fm=new A.E(B.n,["Kolumn","Infoga kolumn till v\xe4nster","Infoga kolumn till h\xf6ger","Ta bort kolumn","Markera kolumn","Rad","Rubrikrad","Infoga rad ovanf\xf6r","Infoga rad nedanf\xf6r","Ta bort rad","Markera rad","Sammanfoga celler","Dela cell","Tabellinst\xe4llningar","Cellinst\xe4llningar","Infoga stycke utanf\xf6r tabellen","Infoga f\xf6re","Infoga efter","Kopiera tabell","Ta bort tabell","Kant","F\xe4rg","Bredd","Bakgrund","Dimensioner","H\xf6jd","Inre avst\xe5nd","Cellens textjustering","Justera text v\xe4nster","Centrera text","Justera text h\xf6ger","Justera text","Justera text upptill","Justera text i mitten","Justera text nederst","Dimensioner och justering","Justera tabell v\xe4nster","Centrera tabell","Justera tabell h\xf6ger","Spara","Avbryt",'F\xe4rgen \xe4r ogiltig. Testa "#FF0000" eller "rgb(255,0,0)" eller "red".','V\xe4rdet \xe4r ogiltigt. Testa "10px", "2em", "2%" eller bara "2".',"F\xe4rgval","Ta bort f\xe4rg","Svart","M\xf6rkgr\xe5","Gr\xe5","Ljusgr\xe5","Vit","R\xf6d","Orange","Gul","Ljusgr\xf6n","Gr\xf6n","Akvamarin","Turkos","Ljusbl\xe5","Bl\xe5","Lila"],t.w)
B.fn=new A.E(B.n,["Kolonne","Sett inn kolonne til venstre","Sett inn kolonne til h\xf8yre","Slett kolonne","Velg kolonne","Rad","Overskriftsrad","Sett inn rad over","Sett inn rad under","Slett rad","Velg rad","Sl\xe5 sammen celler","Del celle","Tabellegenskaper","Celleegenskaper","Sett inn avsnitt utenfor tabellen","Sett inn f\xf8r","Sett inn etter","Kopier tabell","Slett tabell","Ramme","Farge","Bredde","Bakgrunn","M\xe5l","H\xf8yde","Polstring","Justering","Venstrejuster celletekst","Sentrer celletekst","H\xf8yrejuster celletekst","Blokjuster celletekst","Toppjuster celletekst","Sentrer celletekst (loddrett)","Bunnjuster celletekst","M\xe5l og justering","Venstrejuster tabell","Sentrer tabell","H\xf8yrejuster tabell","Lagre","Avbryt",'Fargen er ugyldig. Pr\xf8v "#FF0000", "rgb(255,0,0)" eller "red".','Verdien er ugyldig. Pr\xf8v "10px", "2em" eller "2%" eller bare "2".',"Fargevelger","Fjern farge","Svart","M\xf8rkegr\xe5","Gr\xe5","Lysegr\xe5","Hvit","R\xf8d","Oransje","Gul","Lysegr\xf8nn","Gr\xf8nn","Akvamarin","Turkis","Lysebl\xe5","Bl\xe5","Lilla"],t.w)
B.fo=new A.E(B.n,["\u0421\u0442\u043e\u043b\u0431\u0435\u0446","\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044c \u0441\u0442\u043e\u043b\u0431\u0435\u0446 \u0441\u043b\u0435\u0432\u0430","\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044c \u0441\u0442\u043e\u043b\u0431\u0435\u0446 \u0441\u043f\u0440\u0430\u0432\u0430","\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u0441\u0442\u043e\u043b\u0431\u0435\u0446","\u0412\u044b\u0431\u0440\u0430\u0442\u044c \u0441\u0442\u043e\u043b\u0431\u0435\u0446","\u0421\u0442\u0440\u043e\u043a\u0430","\u0421\u0442\u0440\u043e\u043a\u0430 \u0437\u0430\u0433\u043e\u043b\u043e\u0432\u043a\u0430","\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044c \u0441\u0442\u0440\u043e\u043a\u0443 \u0441\u0432\u0435\u0440\u0445\u0443","\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044c \u0441\u0442\u0440\u043e\u043a\u0443 \u0441\u043d\u0438\u0437\u0443","\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u0441\u0442\u0440\u043e\u043a\u0443","\u0412\u044b\u0431\u0440\u0430\u0442\u044c \u0441\u0442\u0440\u043e\u043a\u0443","\u041e\u0431\u044a\u0435\u0434\u0438\u043d\u0438\u0442\u044c \u044f\u0447\u0435\u0439\u043a\u0438","\u0420\u0430\u0437\u0431\u0438\u0442\u044c \u044f\u0447\u0435\u0439\u043a\u0443","\u0421\u0432\u043e\u0439\u0441\u0442\u0432\u0430 \u0442\u0430\u0431\u043b\u0438\u0446\u044b","\u0421\u0432\u043e\u0439\u0441\u0442\u0432\u0430 \u044f\u0447\u0435\u0439\u043a\u0438","\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044c \u0430\u0431\u0437\u0430\u0446 \u0437\u0430 \u043f\u0440\u0435\u0434\u0435\u043b\u0430\u043c\u0438 \u0442\u0430\u0431\u043b\u0438\u0446\u044b","\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044c \u0430\u0431\u0437\u0430\u0446 \u043f\u0435\u0440\u0435\u0434","\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044c \u0430\u0431\u0437\u0430\u0446 \u043f\u043e\u0441\u043b\u0435","\u041a\u043e\u043f\u0438\u0440\u043e\u0432\u0430\u0442\u044c \u0442\u0430\u0431\u043b\u0438\u0446\u0443","\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u0442\u0430\u0431\u043b\u0438\u0446\u0443","\u041e\u0431\u0432\u043e\u0434\u043a\u0430","\u0426\u0432\u0435\u0442","\u0428\u0438\u0440\u0438\u043d\u0430","\u0424\u043e\u043d","\u0420\u0430\u0437\u043c\u0435\u0440\u044b","\u0412\u044b\u0441\u043e\u0442\u0430","\u041e\u0442\u0441\u0442\u0443\u043f","\u0412\u044b\u0440\u0430\u0432\u043d\u0438\u0432\u0430\u043d\u0438\u0435 \u0442\u0435\u043a\u0441\u0442\u0430 \u0432 \u044f\u0447\u0435\u0439\u043a\u0435 \u0442\u0430\u0431\u043b\u0438\u0446\u044b","\u0412\u044b\u0440\u043e\u0432\u043d\u044f\u0442\u044c \u0442\u0435\u043a\u0441\u0442 \u0432 \u044f\u0447\u0435\u0439\u043a\u0435 \u043f\u043e \u043b\u0435\u0432\u043e\u043c\u0443 \u043a\u0440\u0430\u044e","\u0412\u044b\u0440\u043e\u0432\u043d\u044f\u0442\u044c \u0442\u0435\u043a\u0441\u0442 \u0432 \u044f\u0447\u0435\u0439\u043a\u0435 \u043f\u043e \u0446\u0435\u043d\u0442\u0440\u0443","\u0412\u044b\u0440\u043e\u0432\u043d\u044f\u0442\u044c \u0442\u0435\u043a\u0441\u0442 \u0432 \u044f\u0447\u0435\u0439\u043a\u0435 \u043f\u043e \u043f\u0440\u0430\u0432\u043e\u043c\u0443 \u043a\u0440\u0430\u044e","\u0412\u044b\u0440\u043e\u0432\u043d\u044f\u0442\u044c \u0442\u0435\u043a\u0441\u0442 \u0432 \u044f\u0447\u0435\u0439\u043a\u0435 \u043f\u043e \u0448\u0438\u0440\u0438\u043d\u0435","\u0412\u044b\u0440\u043e\u0432\u043d\u044f\u0442\u044c \u0442\u0435\u043a\u0441\u0442 \u0432 \u044f\u0447\u0435\u0439\u043a\u0435 \u043f\u043e \u0432\u0435\u0440\u0445\u0443","\u0412\u044b\u0440\u043e\u0432\u043d\u044f\u0442\u044c \u0442\u0435\u043a\u0441\u0442 \u0432 \u044f\u0447\u0435\u0439\u043a\u0435 \u043f\u043e \u0441\u0435\u0440\u0435\u0434\u0438\u043d\u0435","\u0412\u044b\u0440\u043e\u0432\u043d\u044f\u0442\u044c \u0442\u0435\u043a\u0441\u0442 \u0432 \u044f\u0447\u0435\u0439\u043a\u0435 \u043f\u043e \u043d\u0438\u0437\u0443","\u0420\u0430\u0437\u043c\u0435\u0440\u044b \u0438 \u0432\u044b\u0440\u0430\u0432\u043d\u0438\u0432\u0430\u043d\u0438\u0435","\u0412\u044b\u0440\u043e\u0432\u043d\u044f\u0442\u044c \u0442\u0430\u0431\u043b\u0438\u0446\u0443 \u043f\u043e \u043b\u0435\u0432\u043e\u043c\u0443 \u043a\u0440\u0430\u044e","\u0426\u0435\u043d\u0442\u0440\u0438\u0440\u043e\u0432\u0430\u0442\u044c \u0442\u0430\u0431\u043b\u0438\u0446\u0443","\u0412\u044b\u0440\u043e\u0432\u043d\u044f\u0442\u044c \u0442\u0430\u0431\u043b\u0438\u0446\u0443 \u043f\u043e \u043f\u0440\u0430\u0432\u043e\u043c\u0443 \u043a\u0440\u0430\u044e","\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c","\u041e\u0442\u043c\u0435\u043d\u0438\u0442\u044c",'\u041d\u0435\u0432\u0435\u0440\u043d\u044b\u0439 \u0446\u0432\u0435\u0442. \u041f\u043e\u043f\u0440\u043e\u0431\u0443\u0439\u0442\u0435 "#FF0000", "rgb(255,0,0)" \u0438\u043b\u0438 "red".','\u041d\u0435\u0434\u043e\u043f\u0443\u0441\u0442\u0438\u043c\u043e\u0435 \u0437\u043d\u0430\u0447\u0435\u043d\u0438\u0435. \u041f\u043e\u043f\u0440\u043e\u0431\u0443\u0439\u0442\u0435 "10px", "2em" \u0438\u043b\u0438 "2%" \u0438\u043b\u0438 \u043f\u0440\u043e\u0441\u0442\u043e "2".',"\u0412\u044b\u0431\u043e\u0440 \u0446\u0432\u0435\u0442\u0430","\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u0446\u0432\u0435\u0442","\u0427\u0435\u0440\u043d\u044b\u0439","\u0422\u0435\u043c\u043d\u043e-\u0441\u0435\u0440\u044b\u0439","\u0421\u0435\u0440\u044b\u0439","\u0421\u0432\u0435\u0442\u043b\u043e-\u0441\u0435\u0440\u044b\u0439","\u0411\u0435\u043b\u044b\u0439","\u041a\u0440\u0430\u0441\u043d\u044b\u0439","\u041e\u0440\u0430\u043d\u0436\u0435\u0432\u044b\u0439","\u0416\u0435\u043b\u0442\u044b\u0439","\u0421\u0432\u0435\u0442\u043b\u043e-\u0437\u0435\u043b\u0435\u043d\u044b\u0439","\u0417\u0435\u043b\u0435\u043d\u044b\u0439","\u0410\u043a\u0432\u0430\u043c\u0430\u0440\u0438\u043d","\u0411\u0438\u0440\u044e\u0437\u043e\u0432\u044b\u0439","\u0421\u0432\u0435\u0442\u043b\u043e-\u0433\u043e\u043b\u0443\u0431\u043e\u0439","\u0421\u0438\u043d\u0438\u0439","\u0424\u0438\u043e\u043b\u0435\u0442\u043e\u0432\u044b\u0439"],t.w)
B.fp=new A.E(B.n,["Kolonne","Inds\xe6t kolonne til venstre","Inds\xe6t kolonne til h\xf8jre","Slet kolonne","V\xe6lg kolonne","R\xe6kke","Overskriftsr\xe6kke","Inds\xe6t r\xe6kke ovenfor","Inds\xe6t r\xe6kke nedenfor","Slet r\xe6kke","V\xe6lg r\xe6kke","Flet celler","Opdel celle","Tabellegenskaber","Celleegenskaber","Inds\xe6t afsnit uden for tabellen","Inds\xe6t f\xf8r","Inds\xe6t efter","Kopi\xe9r tabel","Slet tabel","Kant","Farve","Bredde","Baggrund","M\xe5l","H\xf8jde","Indre afstand","Justering","Venstrejuster celletekst","Centrer celletekst","H\xf8jrejuster celletekst","Juster celletekst","Topjuster celletekst","Centrer celletekst (lodret)","Bundjuster celletekst","M\xe5l og justering","Venstrejuster tabel","Centrer tabel","H\xf8jrejuster tabel","Gem","Annuller",'Farven er ugyldig. Pr\xf8v "#FF0000", "rgb(255,0,0)" eller "red".','V\xe6rdien er ugyldig. Pr\xf8v "10px", "2em" eller "2%" eller blot "2".',"Farvev\xe6lger","Fjern farve","Sort","M\xf8rkegr\xe5","Gr\xe5","Lysegr\xe5","Hvid","R\xf8d","Orange","Gul","Lysegr\xf8n","Gr\xf8n","Akvamarin","Turkis","Lysebl\xe5","Bl\xe5","Lilla"],t.w)
B.fq=new A.E(B.n,["Colonne","Ins\xe9rer colonne \xe0 gauche","Ins\xe9rer colonne \xe0 droite","Supprimer la colonne","S\xe9lectionner la colonne","Ligne","Ligne d'en-t\xeate","Ins\xe9rer ligne au-dessus","Ins\xe9rer ligne en dessous","Supprimer la ligne","S\xe9lectionner la ligne","Fusionner les cellules","Diviser la cellule","Propri\xe9t\xe9s du tableau","Propri\xe9t\xe9s de la cellule","Ins\xe9rer paragraphe en dehors du tableau","Ins\xe9rer avant","Ins\xe9rer apr\xe8s","Copier le tableau","Supprimer le tableau","Bordure","Couleur","Largeur","Arri\xe8re-plan","Dimensions","Hauteur","Marge int\xe9rieure","Alignement du texte de la cellule du tableau","Aligner le texte de la cellule \xe0 gauche","Aligner le texte de la cellule au centre","Aligner le texte de la cellule \xe0 droite","Justifier le texte de la cellule","Aligner le texte de la cellule en haut","Aligner le texte de la cellule au milieu","Aligner le texte de la cellule en bas","Dimensions et alignement","Aligner le tableau \xe0 gauche","Centrer le tableau","Aligner le tableau \xe0 droite","Enregistrer","Annuler",'La couleur est invalide. Essayez "#FF0000" ou "rgb(255,0,0)" ou "rouge".','La valeur est invalide. Essayez "10px" ou "2em" ou "2%" ou simplement "2".',"S\xe9lecteur de couleur","Supprimer la couleur","Noir","Gris fonc\xe9","Gris","Gris clair","Blanc","Rouge","Orange","Jaune","Vert clair","Vert","Aigue-marine","Turquoise","Bleu clair","Bleu","Violet"],t.w)
B.fr=new A.E(B.n,["Kolumna","Wstaw kolumn\u0119 z lewej","Wstaw kolumn\u0119 z prawej","Usu\u0144 kolumn\u0119","Wybierz kolumn\u0119","Wiersz","Wiersz nag\u0142\xf3wka","Wstaw wiersz powy\u017cej","Wstaw wiersz poni\u017cej","Usu\u0144 wiersz","Wybierz wiersz","Scal kom\xf3rki","Podziel kom\xf3rk\u0119","W\u0142a\u015bciwo\u015bci tabeli","W\u0142a\u015bciwo\u015bci kom\xf3rki","Wstaw akapit poza tabel\u0105","Wstaw przed","Wstaw po","Kopiuj tabel\u0119","Usu\u0144 tabel\u0119","Obramowanie","Kolor","Szeroko\u015b\u0107","T\u0142o","Wymiary","Wysoko\u015b\u0107","Margines wewn\u0119trzny","Wyr\xf3wnanie tekstu w kom\xf3rce tabeli","Wyr\xf3wnaj tekst w kom\xf3rce do lewej","Wyr\xf3wnaj tekst w kom\xf3rce do \u015brodka","Wyr\xf3wnaj tekst w kom\xf3rce do prawej","Wyjustuj tekst w kom\xf3rce","Wyr\xf3wnaj tekst w kom\xf3rce do g\xf3ry","Wyr\xf3wnaj tekst w kom\xf3rce do \u015brodka","Wyr\xf3wnaj tekst w kom\xf3rce do do\u0142u","Wymiary i wyr\xf3wnanie","Wyr\xf3wnaj tabel\u0119 do lewej","Wy\u015brodkuj tabel\u0119","Wyr\xf3wnaj tabel\u0119 do prawej","Zapisz","Anuluj",'Kolor jest nieprawid\u0142owy. Spr\xf3buj "#FF0000" lub "rgb(255,0,0)" lub "red".','Warto\u015b\u0107 jest nieprawid\u0142owa. Spr\xf3buj "10px" lub "2em" lub "2%" lub po prostu "2".',"Wyb\xf3r koloru","Usu\u0144 kolor","Czarny","Przyciemniony szary","Szary","Jasnoszary","Bia\u0142y","Czerwony","Pomara\u0144czowy","\u017b\xf3\u0142ty","Jasnozielony","Zielony","Akwamaryna","Turkusowy","Jasnoniebieski","Niebieski","Fioletowy"],t.w)
B.fs=new A.E(B.n,["\u6b04","\u5411\u5de6\u63d2\u5165\u6b04","\u5411\u53f3\u63d2\u5165\u6b04","\u522a\u9664\u6b04","\u9078\u53d6\u6b04","\u5217","\u6a19\u984c\u5217","\u5728\u4e0a\u65b9\u63d2\u5165\u5217","\u5728\u4e0b\u65b9\u63d2\u5165\u5217","\u522a\u9664\u5217","\u9078\u53d6\u5217","\u5408\u4f75\u5132\u5b58\u683c","\u62c6\u5206\u5132\u5b58\u683c","\u8868\u683c\u5c6c\u6027","\u5132\u5b58\u683c\u5c6c\u6027","\u5728\u8868\u683c\u5916\u63d2\u5165\u6bb5\u843d","\u5728\u8868\u683c\u524d\u63d2\u5165","\u5728\u8868\u683c\u5f8c\u63d2\u5165","\u8907\u88fd\u8868\u683c","\u522a\u9664\u8868\u683c","\u908a\u6846","\u984f\u8272","\u5bec\u5ea6","\u80cc\u666f","\u5c3a\u5bf8","\u9ad8\u5ea6","\u5167\u8ddd","\u5132\u5b58\u683c\u6587\u5b57\u5c0d\u9f4a\u65b9\u5f0f","\u5de6\u5c0d\u9f4a","\u6c34\u5e73\u7f6e\u4e2d","\u53f3\u5c0d\u9f4a","\u5de6\u53f3\u5c0d\u9f4a","\u9802\u7aef\u5c0d\u9f4a","\u5782\u76f4\u7f6e\u4e2d","\u5e95\u90e8\u5c0d\u9f4a","\u5c3a\u5bf8\u8207\u5c0d\u9f4a\u65b9\u5f0f","\u8868\u683c\u5de6\u5c0d\u9f4a","\u8868\u683c\u7f6e\u4e2d","\u8868\u683c\u53f3\u5c0d\u9f4a","\u5132\u5b58","\u53d6\u6d88",'\u7121\u6548\u7684\u984f\u8272\uff0c\u8acb\u4f7f\u7528 "#FF0000"\u3001"rgb(255,0,0)" \u6216 "red"','\u7121\u6548\u7684\u503c\uff0c\u8acb\u4f7f\u7528 "10px"\u3001"2em"\u3001"2%" \u6216 "2"',"\u984f\u8272\u9078\u64c7\u5668","\u79fb\u9664\u984f\u8272","\u9ed1\u8272","\u6df1\u7070\u8272","\u7070\u8272","\u6dfa\u7070\u8272","\u767d\u8272","\u7d05\u8272","\u6a58\u8272","\u9ec3\u8272","\u6dfa\u7da0\u8272","\u7da0\u8272","\u6d77\u85cd\u8272","\u9752\u7da0\u8272","\u6dfa\u85cd\u8272","\u85cd\u8272","\u7d2b\u8272"],t.w)
B.ft=new A.E(B.n,["\u5217","\u5de6\u306b\u5217\u3092\u633f\u5165","\u53f3\u306b\u5217\u3092\u633f\u5165","\u5217\u3092\u524a\u9664","\u5217\u3092\u9078\u629e","\u884c","\u30d8\u30c3\u30c0\u30fc\u884c","\u4e0a\u306b\u884c\u3092\u633f\u5165","\u4e0b\u306b\u884c\u3092\u633f\u5165","\u884c\u3092\u524a\u9664","\u884c\u3092\u9078\u629e","\u30bb\u30eb\u3092\u7d50\u5408","\u30bb\u30eb\u3092\u5206\u5272","\u30c6\u30fc\u30d6\u30eb\u306e\u30d7\u30ed\u30d1\u30c6\u30a3","\u30bb\u30eb\u306e\u30d7\u30ed\u30d1\u30c6\u30a3","\u30c6\u30fc\u30d6\u30eb\u5916\u306b\u6bb5\u843d\u3092\u633f\u5165","\u524d\u306b\u633f\u5165","\u5f8c\u306b\u633f\u5165","\u30c6\u30fc\u30d6\u30eb\u3092\u30b3\u30d4\u30fc","\u30c6\u30fc\u30d6\u30eb\u3092\u524a\u9664","\u67a0\u7dda","\u8272","\u5e45","\u80cc\u666f","\u30b5\u30a4\u30ba","\u9ad8\u3055","\u30d1\u30c7\u30a3\u30f3\u30b0","\u30bb\u30eb\u306e\u30c6\u30ad\u30b9\u30c8\u914d\u7f6e","\u30bb\u30eb\u306e\u30c6\u30ad\u30b9\u30c8\u3092\u5de6\u63c3\u3048","\u30bb\u30eb\u306e\u30c6\u30ad\u30b9\u30c8\u3092\u4e2d\u592e\u63c3\u3048","\u30bb\u30eb\u306e\u30c6\u30ad\u30b9\u30c8\u3092\u53f3\u63c3\u3048","\u30bb\u30eb\u306e\u30c6\u30ad\u30b9\u30c8\u3092\u4e21\u7aef\u63c3\u3048","\u30bb\u30eb\u306e\u30c6\u30ad\u30b9\u30c8\u3092\u4e0a\u63c3\u3048","\u30bb\u30eb\u306e\u30c6\u30ad\u30b9\u30c8\u3092\u4e2d\u592e\u63c3\u3048\uff08\u7e26\uff09","\u30bb\u30eb\u306e\u30c6\u30ad\u30b9\u30c8\u3092\u4e0b\u63c3\u3048","\u30b5\u30a4\u30ba\u3068\u914d\u7f6e","\u30c6\u30fc\u30d6\u30eb\u3092\u5de6\u63c3\u3048","\u30c6\u30fc\u30d6\u30eb\u3092\u4e2d\u592e\u63c3\u3048","\u30c6\u30fc\u30d6\u30eb\u3092\u53f3\u63c3\u3048","\u4fdd\u5b58","\u30ad\u30e3\u30f3\u30bb\u30eb",'\u8272\u304c\u7121\u52b9\u3067\u3059\u3002"#FF0000"\u3084"rgb(255,0,0)"\u3084"red"\u3092\u8a66\u3057\u3066\u304f\u3060\u3055\u3044\u3002','\u5024\u304c\u7121\u52b9\u3067\u3059\u3002"10px"\u3084"2em"\u3084"2%"\u307e\u305f\u306f\u5358\u306b"2"\u3092\u8a66\u3057\u3066\u304f\u3060\u3055\u3044\u3002',"\u30ab\u30e9\u30fc\u30d4\u30c3\u30ab\u30fc","\u8272\u3092\u524a\u9664","\u9ed2","\u30c0\u30fc\u30af\u30b0\u30ec\u30fc","\u30b0\u30ec\u30fc","\u30e9\u30a4\u30c8\u30b0\u30ec\u30fc","\u767d","\u8d64","\u30aa\u30ec\u30f3\u30b8","\u9ec4\u8272","\u30e9\u30a4\u30c8\u30b0\u30ea\u30fc\u30f3","\u7dd1","\u30a2\u30af\u30a2\u30de\u30ea\u30f3","\u30bf\u30fc\u30b3\u30a4\u30ba","\u30e9\u30a4\u30c8\u30d6\u30eb\u30fc","\u9752","\u7d2b"],t.w)
B.fu=new A.E(B.n,["Colonna","Inserisci colonna a sinistra","Inserisci colonna a destra","Elimina colonna","Seleziona colonna","Riga","Riga di intestazione","Inserisci riga sopra","Inserisci riga sotto","Elimina riga","Seleziona riga","Unisci celle","Dividi cella","Propriet\xe0 tabella","Propriet\xe0 cella","Inserisci paragrafo fuori dalla tabella","Inserisci prima","Inserisci dopo","Copia tabella","Elimina tabella","Bordo","Colore","Larghezza","Sfondo","Dimensioni","Altezza","Spaziatura interna","Allineamento testo cella","Allinea testo cella a sinistra","Allinea testo cella al centro","Allinea testo cella a destra","Giustifica testo cella","Allinea testo cella in alto","Allinea testo cella al centro verticale","Allinea testo cella in basso","Dimensioni e allineamento","Allinea tabella a sinistra","Centra tabella","Allinea tabella a destra","Salva","Annulla",'Il colore non \xe8 valido. Prova con "#FF0000", "rgb(255,0,0)" o "red".','Il valore non \xe8 valido. Prova con "10px", "2em", "2%" oppure semplicemente "2".',"Selettore colore","Rimuovi colore","Nero","Grigio scuro","Grigio","Grigio chiaro","Bianco","Rosso","Arancione","Giallo","Verde chiaro","Verde","Acquamarina","Turchese","Azzurro","Blu","Viola"],t.w)
B.fv=new A.E(B.n,["Coluna","Inserir coluna \xe0 esquerda","Inserir coluna \xe0 direita","Excluir coluna","Selecionar coluna","Linha","Linha de t\xedtulo","Inserir linha acima","Inserir linha abaixo","Excluir linha","Selecionar linha","Mesclar c\xe9lulas","Dividir c\xe9lula","Propriedades da tabela","Propriedades da c\xe9lula","Inserir par\xe1grafo fora da tabela","Inserir par\xe1grafo antes","Inserir par\xe1grafo depois","Copiar tabela","Excluir tabela","Borda","Cor","Largura","Fundo","Dimens\xf5es","Altura","Espa\xe7amento","Alinhamento do texto da c\xe9lula","Alinhar texto \xe0 esquerda","Centralizar texto","Alinhar texto \xe0 direita","Justificar texto","Alinhar texto ao topo","Alinhar texto ao meio","Alinhar texto \xe0 base","Dimens\xf5es e alinhamento","Alinhar tabela \xe0 esquerda","Centralizar tabela","Alinhar tabela \xe0 direita","Salvar","Cancelar",u.Z,'O valor \xe9 inv\xe1lido. Tente "10px" ou "2em" ou "2%" ou simplesmente "2".',"Seletor de cor","Remover cor","Preto","Cinza escuro","Cinza","Cinza claro","Branco","Vermelho","Laranja","Amarelo","Verde claro","Verde","\xc1gua-marinha","Turquesa","Azul claro","Azul","Roxo"],t.w)
B.fw=new A.E(B.n,["Column","Insert column left","Insert column right","Delete column","Select column","Row","Header row","Insert row above","Insert row below","Delete row","Select row","Merge cells","Split cell","Table properties","Cell properties","Insert paragraph outside the table","Insert before","Insert after","Copy table","Delete table","Border","Color","Width","Background","Dimensions","Height","Padding","Table cell text alignment","Align cell text to the left","Align cell text to the center","Align cell text to the right","Justify cell text","Align cell text to the top","Align cell text to the middle","Align cell text to the bottom","Dimensions and alignment","Align table to the left","Center table","Align table to the right","Save","Cancel",'The color is invalid. Try "#FF0000" or "rgb(255,0,0)" or "red".','The value is invalid. Try "10px" or "2em" or "2%" or simply "2".',"Color picker","Remove color","Black","Dim grey","Grey","Light grey","White","Red","Orange","Yellow","Light green","Green","Aquamarine","Turquoise","Light blue","Blue","Purple"],t.w)
B.iu={"align-bottom":0,"align-center":1,"align-justify":2,"align-left":3,"align-middle":4,"align-right":5,"align-top":6,cell:7,check:8,close:9,column:10,copy:11,delete:12,down:13,erase:14,merge:15,palette:16,row:17,table:18,wrap:19}
B.bh=new A.E(B.iu,['<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M6 36.3056H42" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M6 42H42" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M30 23L24 29L18 23V23" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M24 6V29" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>','<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M36 19H12" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M42 9H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M42 29H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M36 39H12" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>','<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M42 19H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M42 9H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M42 29H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M42 39H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>','<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M42 9H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M34 19H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M42 29H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M34 39H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>','<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18 36L24 30L30 36" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M23.9999 30.9998V43.9998" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M18 12L24 18L30 12" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M23.9999 17.0002V4.00022" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M6 24.0004H42" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>','<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M42 9H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M42 19H14" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M42 29H6" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M42 39H14" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>','<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M6 36.3056H42" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M6 42H42" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M30 12L24 6L18 12V12" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M24 6V29" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>',u.l,'<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M43 11L16.875 37L5 25.1818" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>','<svg width="16" height="16" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M8 8L40 40" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M8 40L40 8" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>',u.O,u.X,u.g,u.e,u.h,u.S,u.j,u.v,u.W,u.N],t.w)
B.iZ={"\\underline":0,"\\underbrace":1,"\\underrightarrow":2,"\\underleftarrow":3}
B.fx=new A.E(B.iZ,["_","\u23df","\u2192","\u2190"],t.w)
B.iw={bold:0,italic:1,underline:2,strike:3,blockquote:4,"code-block":5,link:6,image:7,video:8,formula:9,clean:10,"table:3x3":11,"table-row-above":12,"table-row-below":13,"table-column-left":14,"table-column-right":15,"table-delete-row":16,"table-delete-column":17,"table-delete":18,"list:ordered":19,"list:bullet":20,"list:check":21,"indent:-1":22,"indent:+1":23,"script:sub":24,"script:super":25,"direction:rtl":26}
B.fy=new A.E(B.iw,["Negrito","It\xe1lico","Sublinhado","Tachado","Cita\xe7\xe3o","Bloco de c\xf3digo","Inserir link","Inserir imagem","Inserir v\xeddeo","Inserir f\xf3rmula","Limpar formata\xe7\xe3o","Inserir tabela","Inserir linha acima","Inserir linha abaixo","Inserir coluna \xe0 esquerda","Inserir coluna \xe0 direita","Excluir linha","Excluir coluna","Excluir tabela","Lista numerada","Lista com marcadores","Lista de tarefas","Diminuir recuo","Aumentar recuo","Subscrito","Sobrescrito","Dire\xe7\xe3o da direita para a esquerda"],t.w)
B.iT={"\\,":0,"\\thinspace":1,"\\:":2,"\\medspace":3,"\\;":4,"\\thickspace":5,"\\!":6,"\\negthinspace":7,"\\ ":8,"\\enspace":9,"\\quad":10,"\\qquad":11}
B.fF=new A.E(B.iT,["0.167em","0.167em","0.222em","0.222em","0.278em","0.278em","-0.167em","-0.167em","0.25em","0.5em","1em","2em"],t.w)
B.bx={width:0,height:1}
B.fG=new A.E(B.bx,["100%","1px"],t.w)
B.fH=new A.E(B.bx,["1px","100%"],t.w)
B.iW={"border-style":0,"border-color":1,"border-width":2,"background-color":3,width:4,height:5,padding:6,"text-align":7,"vertical-align":8}
B.fI=new A.E(B.iW,["none","","","","","","","left","middle"],t.w)
B.v={}
B.bk=new A.E(B.v,[],A.ax("E<e,aj>"))
B.am=new A.E(B.v,[],A.ax("E<e,br>"))
B.fJ=new A.E(B.v,[],t.W)
B.H=new A.E(B.v,[],t.w)
B.fK=new A.E(B.v,[],A.ax("E<e,0&>"))
B.l=new A.E(B.v,[],t.BV)
B.bj=new A.E(B.v,[],A.ax("E<fD,@>"))
B.t=new A.E(B.v,[],A.ax("E<@,@>"))
B.iG={yellow:0,green:1,cyan:2,magenta:3,blue:4,red:5,darkBlue:6,darkCyan:7,darkGreen:8,darkMagenta:9,darkRed:10,darkYellow:11,darkGray:12,lightGray:13,black:14,white:15}
B.fL=new A.E(B.iG,["#FFFF00","#00FF00","#00FFFF","#FF00FF","#0000FF","#FF0000","#00008B","#008B8B","#006400","#8B008B","#8B0000","#808000","#A9A9A9","#D3D3D3","#000000","#FFFFFF"],t.w)
B.iU={matrix:0,pmatrix:1,bmatrix:2,Bmatrix:3,vmatrix:4,Vmatrix:5,cases:6,array:7,aligned:8,align:9,split:10,gathered:11,gather:12,smallmatrix:13}
B.K=A.a(s(["","","center"]),t.s)
B.eK=A.a(s(["(",")","center"]),t.s)
B.eh=A.a(s(["[","]","center"]),t.s)
B.dp=A.a(s(["{","}","center"]),t.s)
B.dy=A.a(s(["|","|","center"]),t.s)
B.eW=A.a(s(["\u2016","\u2016","center"]),t.s)
B.dv=A.a(s(["{","","left"]),t.s)
B.ak=A.a(s(["","","right left"]),t.s)
B.fM=new A.E(B.iU,[B.K,B.eK,B.eh,B.dp,B.dy,B.eW,B.dv,B.K,B.ak,B.ak,B.ak,B.K,B.K,B.K],t.W)
B.bu={inline:0,left:1,center:2,right:3}
B.jz=new A.ao("Em linha com o texto","float-none")
B.jA=new A.ao("Alinhar \xe0 esquerda com quebra de texto","float-left")
B.jh=new A.ao("Centralizar imagem","float-center")
B.jG=new A.ao("Alinhar \xe0 direita com quebra de texto","float-right")
B.fN=new A.E(B.bu,[B.jz,B.jA,B.jh,B.jG],A.ax("E<e,+(e,e)>"))
B.iS={display:0}
B.an=new A.E(B.iS,["none"],t.w)
B.iC={align:0,background:1,blockquote:2,bold:3,clean:4,code:5,"code-block":6,color:7,direction:8,formula:9,header:10,italic:11,image:12,indent:13,link:14,list:15,script:16,strike:17,table:18,underline:19,video:20,"table-row-above":21,"table-row-below":22,"table-column-left":23,"table-column-right":24,"table-delete-row":25,"table-delete-column":26,"table-delete":27,"table-merge":28,"table-split":29}
B.j2={"":0,center:1,right:2,justify:3}
B.fg=new A.E(B.j2,['<svg viewbox="0 0 18 18"><line class="ql-stroke" x1="3" x2="15" y1="9" y2="9"></line><line class="ql-stroke" x1="3" x2="13" y1="14" y2="14"></line><line class="ql-stroke" x1="3" x2="9" y1="4" y2="4"></line></svg>','<svg viewbox="0 0 18 18"><line class="ql-stroke" x1="15" x2="3" y1="9" y2="9"></line><line class="ql-stroke" x1="14" x2="4" y1="14" y2="14"></line><line class="ql-stroke" x1="12" x2="6" y1="4" y2="4"></line></svg>','<svg viewbox="0 0 18 18"><line class="ql-stroke" x1="15" x2="3" y1="9" y2="9"></line><line class="ql-stroke" x1="15" x2="5" y1="14" y2="14"></line><line class="ql-stroke" x1="15" x2="9" y1="4" y2="4"></line></svg>','<svg viewbox="0 0 18 18"><line class="ql-stroke" x1="15" x2="3" y1="9" y2="9"></line><line class="ql-stroke" x1="15" x2="3" y1="14" y2="14"></line><line class="ql-stroke" x1="15" x2="3" y1="4" y2="4"></line></svg>'],t.w)
B.iq={"":0,rtl:1}
B.fO=new A.E(B.iq,['<svg viewbox="0 0 18 18"><polygon class="ql-stroke ql-fill" points="3 11 5 9 3 7 3 11"></polygon><line class="ql-stroke ql-fill" x1="15" x2="11" y1="4" y2="4"></line><path class="ql-fill" d="M11,3a3,3,0,0,0,0,6h1V3H11Z"></path><rect class="ql-fill" height="11" width="1" x="11" y="4"></rect><rect class="ql-fill" height="11" width="1" x="13" y="4"></rect></svg>','<svg viewbox="0 0 18 18"><polygon class="ql-stroke ql-fill" points="15 12 13 10 15 8 15 12"></polygon><line class="ql-stroke ql-fill" x1="9" x2="5" y1="4" y2="4"></line><path class="ql-fill" d="M5,3A3,3,0,0,0,5,9H6V3H5Z"></path><rect class="ql-fill" height="11" width="1" x="5" y="4"></rect><rect class="ql-fill" height="11" width="1" x="7" y="4"></rect></svg>'],t.w)
B.iF={"1":0,"2":1,"3":2,"4":3,"5":4,"6":5}
B.fE=new A.E(B.iF,['<svg viewBox="0 0 18 18"><path class="ql-fill" d="M10,4V14a1,1,0,0,1-2,0V10H3v4a1,1,0,0,1-2,0V4A1,1,0,0,1,3,4V8H8V4a1,1,0,0,1,2,0Zm6.06787,9.209H14.98975V7.59863a.54085.54085,0,0,0-.605-.60547h-.62744a1.01119,1.01119,0,0,0-.748.29688L11.645,8.56641a.5435.5435,0,0,0-.022.8584l.28613.30762a.53861.53861,0,0,0,.84717.0332l.09912-.08789a1.2137,1.2137,0,0,0,.2417-.35254h.02246s-.01123.30859-.01123.60547V13.209H12.041a.54085.54085,0,0,0-.605.60547v.43945a.54085.54085,0,0,0,.605.60547h4.02686a.54085.54085,0,0,0,.605-.60547v-.43945A.54085.54085,0,0,0,16.06787,13.209Z"/></svg>','<svg viewBox="0 0 18 18"><path class="ql-fill" d="M16.73975,13.81445v.43945a.54085.54085,0,0,1-.605.60547H11.855a.58392.58392,0,0,1-.64893-.60547V14.0127c0-2.90527,3.39941-3.42187,3.39941-4.55469a.77675.77675,0,0,0-.84717-.78125,1.17684,1.17684,0,0,0-.83594.38477c-.2749.26367-.561.374-.85791.13184l-.4292-.34082c-.30811-.24219-.38525-.51758-.1543-.81445a2.97155,2.97155,0,0,1,2.45361-1.17676,2.45393,2.45393,0,0,1,2.68408,2.40918c0,2.45312-3.1792,2.92676-3.27832,3.93848h2.79443A.54085.54085,0,0,1,16.73975,13.81445ZM9,3A.99974.99974,0,0,0,8,4V8H3V4A1,1,0,0,0,1,4V14a1,1,0,0,0,2,0V10H8v4a1,1,0,0,0,2,0V4A.99974.99974,0,0,0,9,3Z"/></svg>','<svg viewBox="0 0 18 18"><path class="ql-fill" d="M16.65186,12.30664a2.6742,2.6742,0,0,1-2.915,2.68457,3.96592,3.96592,0,0,1-2.25537-.6709.56007.56007,0,0,1-.13232-.83594L11.64648,13c.209-.34082.48389-.36328.82471-.1543a2.32654,2.32654,0,0,0,1.12256.33008c.71484,0,1.12207-.35156,1.12207-.78125,0-.61523-.61621-.86816-1.46338-.86816H13.2085a.65159.65159,0,0,1-.68213-.41895l-.05518-.10937a.67114.67114,0,0,1,.14307-.78125l.71533-.86914a8.55289,8.55289,0,0,1,.68213-.7373V8.58887a3.93913,3.93913,0,0,1-.748.05469H11.9873a.54085.54085,0,0,1-.605-.60547V7.59863a.54085.54085,0,0,1,.605-.60547h3.75146a.53773.53773,0,0,1,.60547.59375v.17676a1.03723,1.03723,0,0,1-.27539.748L14.74854,10.0293A2.31132,2.31132,0,0,1,16.65186,12.30664ZM9,3A.99974.99974,0,0,0,8,4V8H3V4A1,1,0,0,0,1,4V14a1,1,0,0,0,2,0V10H8v4a1,1,0,0,0,2,0V4A.99974.99974,0,0,0,9,3Z"/></svg>','<svg viewBox="0 0 18 18"><path class="ql-fill" d="M10,4V14a1,1,0,0,1-2,0V10H3v4a1,1,0,0,1-2,0V4A1,1,0,0,1,3,4V8H8V4a1,1,0,0,1,2,0Zm7.05371,7.96582v.38477c0,.39648-.165.60547-.46191.60547h-.47314v1.29785a.54085.54085,0,0,1-.605.60547h-.69336a.54085.54085,0,0,1-.605-.60547V12.95605H11.333a.5412.5412,0,0,1-.60547-.60547v-.15332a1.199,1.199,0,0,1,.22021-.748l2.56348-4.05957a.7819.7819,0,0,1,.72607-.39648h1.27637a.54085.54085,0,0,1,.605.60547v3.7627h.33008A.54055.54055,0,0,1,17.05371,11.96582ZM14.28125,8.7207h-.022a4.18969,4.18969,0,0,1-.38525.81348l-1.188,1.80469v.02246h1.5293V9.60059A7.04058,7.04058,0,0,1,14.28125,8.7207Z"/></svg>','<svg viewBox="0 0 18 18"><path class="ql-fill" d="M16.74023,12.18555a2.75131,2.75131,0,0,1-2.91553,2.80566,3.908,3.908,0,0,1-2.25537-.68164.54809.54809,0,0,1-.13184-.8252L11.73438,13c.209-.34082.48389-.36328.8252-.1543a2.23757,2.23757,0,0,0,1.1001.33008,1.01827,1.01827,0,0,0,1.1001-.96777c0-.61621-.53906-.97949-1.25439-.97949a2.15554,2.15554,0,0,0-.64893.09961,1.15209,1.15209,0,0,1-.814.01074l-.12109-.04395a.64116.64116,0,0,1-.45117-.71484l.231-3.00391a.56666.56666,0,0,1,.62744-.583H15.541a.54085.54085,0,0,1,.605.60547v.43945a.54085.54085,0,0,1-.605.60547H13.41748l-.04395.72559a1.29306,1.29306,0,0,1-.04395.30859h.022a2.39776,2.39776,0,0,1,.57227-.07715A2.53266,2.53266,0,0,1,16.74023,12.18555ZM9,3A.99974.99974,0,0,0,8,4V8H3V4A1,1,0,0,0,1,4V14a1,1,0,0,0,2,0V10H8v4a1,1,0,0,0,2,0V4A.99974.99974,0,0,0,9,3Z"/></svg>','<svg viewBox="0 0 18 18"><path class="ql-fill" d="M14.51758,9.64453a1.85627,1.85627,0,0,0-1.24316.38477H13.252a1.73532,1.73532,0,0,1,1.72754-1.4082,2.66491,2.66491,0,0,1,.5498.06641c.35254.05469.57227.01074.70508-.40723l.16406-.5166a.53393.53393,0,0,0-.373-.75977,4.83723,4.83723,0,0,0-1.17773-.14258c-2.43164,0-3.7627,2.17773-3.7627,4.43359,0,2.47559,1.60645,3.69629,3.19043,3.69629A2.70585,2.70585,0,0,0,16.96,12.19727,2.43861,2.43861,0,0,0,14.51758,9.64453Zm-.23047,3.58691c-.67187,0-1.22168-.81445-1.22168-1.45215,0-.47363.30762-.583.72559-.583.96875,0,1.27734.59375,1.27734,1.12207A.82182.82182,0,0,1,14.28711,13.23145ZM10,4V14a1,1,0,0,1-2,0V10H3v4a1,1,0,0,1-2,0V4A1,1,0,0,1,3,4V8H8V4a1,1,0,0,1,2,0Z"/></svg>'],t.w)
B.iN={"+1":0,"-1":1}
B.fz=new A.E(B.iN,['<svg viewbox="0 0 18 18"><line class="ql-stroke" x1="3" x2="15" y1="14" y2="14"></line><line class="ql-stroke" x1="3" x2="15" y1="4" y2="4"></line><line class="ql-stroke" x1="9" x2="15" y1="9" y2="9"></line><polyline class="ql-fill ql-stroke" points="3 7 3 11 5 9 3 7"></polyline></svg>','<svg viewbox="0 0 18 18"><line class="ql-stroke" x1="3" x2="15" y1="14" y2="14"></line><line class="ql-stroke" x1="3" x2="15" y1="4" y2="4"></line><line class="ql-stroke" x1="9" x2="15" y1="9" y2="9"></line><polyline class="ql-stroke" points="5 7 5 11 3 9 5 7"></polyline></svg>'],t.w)
B.iy={bullet:0,check:1,ordered:2}
B.fa=new A.E(B.iy,['<svg viewbox="0 0 18 18"><line class="ql-stroke" x1="6" x2="15" y1="4" y2="4"></line><line class="ql-stroke" x1="6" x2="15" y1="9" y2="9"></line><line class="ql-stroke" x1="6" x2="15" y1="14" y2="14"></line><line class="ql-stroke" x1="3" x2="3" y1="4" y2="4"></line><line class="ql-stroke" x1="3" x2="3" y1="9" y2="9"></line><line class="ql-stroke" x1="3" x2="3" y1="14" y2="14"></line></svg>','<svg class="" viewbox="0 0 18 18"><line class="ql-stroke" x1="9" x2="15" y1="4" y2="4"></line><polyline class="ql-stroke" points="3 4 4 5 6 3"></polyline><line class="ql-stroke" x1="9" x2="15" y1="14" y2="14"></line><polyline class="ql-stroke" points="3 14 4 15 6 13"></polyline><line class="ql-stroke" x1="9" x2="15" y1="9" y2="9"></line><polyline class="ql-stroke" points="3 9 4 10 6 8"></polyline></svg>','<svg viewbox="0 0 18 18"><line class="ql-stroke" x1="7" x2="15" y1="4" y2="4"></line><line class="ql-stroke" x1="7" x2="15" y1="9" y2="9"></line><line class="ql-stroke" x1="7" x2="15" y1="14" y2="14"></line><line class="ql-stroke ql-thin" x1="2.5" x2="4.5" y1="5.5" y2="5.5"></line><path class="ql-fill" d="M3.5,6A0.5,0.5,0,0,1,3,5.5V3.085l-0.276.138A0.5,0.5,0,0,1,2.053,3c-0.124-.247-0.023-0.324.224-0.447l1-.5A0.5,0.5,0,0,1,4,2.5v3A0.5,0.5,0,0,1,3.5,6Z"></path><path class="ql-stroke ql-thin" d="M4.5,10.5h-2c0-.234,1.85-1.076,1.85-2.234A0.959,0.959,0,0,0,2.5,8.156"></path><path class="ql-stroke ql-thin" d="M2.5,14.846a0.959,0.959,0,0,0,1.85-.109A0.7,0.7,0,0,0,3.75,14a0.688,0.688,0,0,0,.6-0.736,0.959,0.959,0,0,0-1.85-.109"></path></svg>'],t.w)
B.j4={sub:0,"super":1}
B.fP=new A.E(B.j4,['<svg viewbox="0 0 18 18"><path class="ql-fill" d="M15.5,15H13.861a3.858,3.858,0,0,0,1.914-2.975,1.8,1.8,0,0,0-1.6-1.751A1.921,1.921,0,0,0,12.021,11.7a0.50013,0.50013,0,1,0,.957.291h0a0.914,0.914,0,0,1,1.053-.725,0.81,0.81,0,0,1,.744.762c0,1.076-1.16971,1.86982-1.93971,2.43082A1.45639,1.45639,0,0,0,12,15.5a0.5,0.5,0,0,0,.5.5h3A0.5,0.5,0,0,0,15.5,15Z"/><path class="ql-fill" d="M9.65,5.241a1,1,0,0,0-1.409.108L6,7.964,3.759,5.349A1,1,0,0,0,2.192,6.59178Q2.21541,6.6213,2.241,6.649L4.684,9.5,2.241,12.35A1,1,0,0,0,3.71,13.70722q0.02557-.02768.049-0.05722L6,11.036,8.241,13.65a1,1,0,1,0,1.567-1.24277Q9.78459,12.3777,9.759,12.35L7.316,9.5,9.759,6.651A1,1,0,0,0,9.65,5.241Z"/></svg>','<svg viewbox="0 0 18 18"><path class="ql-fill" d="M15.5,7H13.861a4.015,4.015,0,0,0,1.914-2.975,1.8,1.8,0,0,0-1.6-1.751A1.922,1.922,0,0,0,12.021,3.7a0.5,0.5,0,1,0,.957.291,0.917,0.917,0,0,1,1.053-.725,0.81,0.81,0,0,1,.744.762c0,1.077-1.164,1.925-1.934,2.486A1.423,1.423,0,0,0,12,7.5a0.5,0.5,0,0,0,.5.5h3A0.5,0.5,0,0,0,15.5,7Z"/><path class="ql-fill" d="M9.651,5.241a1,1,0,0,0-1.41.108L6,7.964,3.759,5.349a1,1,0,1,0-1.519,1.3L4.683,9.5,2.241,12.35a1,1,0,1,0,1.519,1.3L6,11.036,8.241,13.65a1,1,0,0,0,1.519-1.3L7.317,9.5,9.759,6.651A1,1,0,0,0,9.651,5.241Z"/></svg>'],t.w)
B.fQ=new A.E(B.iC,[B.fg,'<svg viewbox="0 0 18 18"><g class="ql-fill ql-color-label"><polygon points="6 6.868 6 6 5 6 5 7 5.942 7 6 6.868"></polygon><rect height="1" width="1" x="4" y="4"></rect><polygon points="6.817 5 6 5 6 6 6.38 6 6.817 5"></polygon><rect height="1" width="1" x="2" y="6"></rect><rect height="1" width="1" x="3" y="5"></rect><rect height="1" width="1" x="4" y="7"></rect><polygon points="4 11.439 4 11 3 11 3 12 3.755 12 4 11.439"></polygon><rect height="1" width="1" x="2" y="12"></rect><rect height="1" width="1" x="2" y="9"></rect><rect height="1" width="1" x="2" y="15"></rect><polygon points="4.63 10 4 10 4 11 4.192 11 4.63 10"></polygon><rect height="1" width="1" x="3" y="8"></rect><path d="M10.832,4.2L11,4.582V4H10.708A1.948,1.948,0,0,1,10.832,4.2Z"></path><path d="M7,4.582L7.168,4.2A1.929,1.929,0,0,1,7.292,4H7V4.582Z"></path><path d="M8,13H7.683l-0.351.8a1.933,1.933,0,0,1-.124.2H8V13Z"></path><rect height="1" width="1" x="12" y="2"></rect><rect height="1" width="1" x="11" y="3"></rect><path d="M9,3H8V3.282A1.985,1.985,0,0,1,9,3Z"></path><rect height="1" width="1" x="2" y="3"></rect><rect height="1" width="1" x="6" y="2"></rect><rect height="1" width="1" x="3" y="2"></rect><rect height="1" width="1" x="5" y="3"></rect><rect height="1" width="1" x="9" y="2"></rect><rect height="1" width="1" x="15" y="14"></rect><polygon points="13.447 10.174 13.469 10.225 13.472 10.232 13.808 11 14 11 14 10 13.37 10 13.447 10.174"></polygon><rect height="1" width="1" x="13" y="7"></rect><rect height="1" width="1" x="15" y="5"></rect><rect height="1" width="1" x="14" y="6"></rect><rect height="1" width="1" x="15" y="8"></rect><rect height="1" width="1" x="14" y="9"></rect><path d="M3.775,14H3v1H4V14.314A1.97,1.97,0,0,1,3.775,14Z"></path><rect height="1" width="1" x="14" y="3"></rect><polygon points="12 6.868 12 6 11.62 6 12 6.868"></polygon><rect height="1" width="1" x="15" y="2"></rect><rect height="1" width="1" x="12" y="5"></rect><rect height="1" width="1" x="13" y="4"></rect><polygon points="12.933 9 13 9 13 8 12.495 8 12.933 9"></polygon><rect height="1" width="1" x="9" y="14"></rect><rect height="1" width="1" x="8" y="15"></rect><path d="M6,14.926V15H7V14.316A1.993,1.993,0,0,1,6,14.926Z"></path><rect height="1" width="1" x="5" y="15"></rect><path d="M10.668,13.8L10.317,13H10v1h0.792A1.947,1.947,0,0,1,10.668,13.8Z"></path><rect height="1" width="1" x="11" y="15"></rect><path d="M14.332,12.2a1.99,1.99,0,0,1,.166.8H15V12H14.245Z"></path><rect height="1" width="1" x="14" y="15"></rect><rect height="1" width="1" x="15" y="11"></rect></g><polyline class="ql-stroke" points="5.5 13 9 5 12.5 13"></polyline><line class="ql-stroke" x1="11.63" x2="6.38" y1="11" y2="11"></line></svg>','<svg viewbox="0 0 18 18"><rect class="ql-fill ql-stroke" height="3" width="3" x="4" y="5"></rect><rect class="ql-fill ql-stroke" height="3" width="3" x="11" y="5"></rect><path class="ql-even ql-fill ql-stroke" d="M7,8c0,4.031-3,5-3,5"></path><path class="ql-even ql-fill ql-stroke" d="M14,8c0,4.031-3,5-3,5"></path></svg>','<svg viewbox="0 0 18 18"><path class="ql-stroke" d="M5,4H9.5A2.5,2.5,0,0,1,12,6.5v0A2.5,2.5,0,0,1,9.5,9H5A0,0,0,0,1,5,9V4A0,0,0,0,1,5,4Z"></path><path class="ql-stroke" d="M5,9h5.5A2.5,2.5,0,0,1,13,11.5v0A2.5,2.5,0,0,1,10.5,14H5a0,0,0,0,1,0,0V9A0,0,0,0,1,5,9Z"></path></svg>','<svg class="" viewbox="0 0 18 18"><line class="ql-stroke" x1="5" x2="13" y1="3" y2="3"></line><line class="ql-stroke" x1="6" x2="9.35" y1="12" y2="3"></line><line class="ql-stroke" x1="11" x2="15" y1="11" y2="15"></line><line class="ql-stroke" x1="15" x2="11" y1="11" y2="15"></line><rect class="ql-fill" height="1" rx="0.5" ry="0.5" width="7" x="2" y="14"></rect></svg>',u.J,u.J,'<svg viewbox="0 0 18 18"><line class="ql-color-label ql-stroke ql-transparent" x1="3" x2="15" y1="15" y2="15"></line><polyline class="ql-stroke" points="5.5 11 9 3 12.5 11"></polyline><line class="ql-stroke" x1="11.63" x2="6.38" y1="9" y2="9"></line></svg>',B.fO,'<svg viewbox="0 0 18 18"><path class="ql-fill" d="M11.759,2.482a2.561,2.561,0,0,0-3.53.607A7.656,7.656,0,0,0,6.8,6.2C6.109,9.188,5.275,14.677,4.15,14.927a1.545,1.545,0,0,0-1.3-.933A0.922,0.922,0,0,0,2,15.036S1.954,16,4.119,16s3.091-2.691,3.7-5.553c0.177-.826.36-1.726,0.554-2.6L8.775,6.2c0.381-1.421.807-2.521,1.306-2.676a1.014,1.014,0,0,0,1.02.56A0.966,0.966,0,0,0,11.759,2.482Z"></path><rect class="ql-fill" height="1.6" rx="0.8" ry="0.8" width="5" x="5.15" y="6.2"></rect><path class="ql-fill" d="M13.663,12.027a1.662,1.662,0,0,1,.266-0.276q0.193,0.069.456,0.138a2.1,2.1,0,0,0,.535.069,1.075,1.075,0,0,0,.767-0.3,1.044,1.044,0,0,0,.314-0.8,0.84,0.84,0,0,0-.238-0.619,0.8,0.8,0,0,0-.594-0.239,1.154,1.154,0,0,0-.781.3,4.607,4.607,0,0,0-.781,1q-0.091.15-.218,0.346l-0.246.38c-0.068-.288-0.137-0.582-0.212-0.885-0.459-1.847-2.494-.984-2.941-0.8-0.482.2-.353,0.647-0.094,0.529a0.869,0.869,0,0,1,1.281.585c0.217,0.751.377,1.436,0.527,2.038a5.688,5.688,0,0,1-.362.467,2.69,2.69,0,0,1-.264.271q-0.221-.08-0.471-0.147a2.029,2.029,0,0,0-.522-0.066,1.079,1.079,0,0,0-.768.3A1.058,1.058,0,0,0,9,15.131a0.82,0.82,0,0,0,.832.852,1.134,1.134,0,0,0,.787-0.3,5.11,5.11,0,0,0,.776-0.993q0.141-.219.215-0.34c0.046-.076.122-0.194,0.223-0.346a2.786,2.786,0,0,0,.918,1.726,2.582,2.582,0,0,0,2.376-.185c0.317-.181.212-0.565,0-0.494A0.807,0.807,0,0,1,14.176,15a5.159,5.159,0,0,1-.913-2.446l0,0Q13.487,12.24,13.663,12.027Z"></path></svg>',B.fE,'<svg viewbox="0 0 18 18"><line class="ql-stroke" x1="7" x2="13" y1="4" y2="4"></line><line class="ql-stroke" x1="5" x2="11" y1="14" y2="14"></line><line class="ql-stroke" x1="8" x2="10" y1="14" y2="4"></line></svg>','<svg viewbox="0 0 18 18"><rect class="ql-stroke" height="10" width="12" x="3" y="4"></rect><circle class="ql-fill" cx="6" cy="7" r="1"></circle><polyline class="ql-even ql-fill" points="5 12 5 11 7 9 8 10 11 7 13 9 13 12 5 12"></polyline></svg>',B.fz,'<svg viewbox="0 0 18 18"><line class="ql-stroke" x1="7" x2="11" y1="7" y2="11"></line><path class="ql-even ql-stroke" d="M8.9,4.577a3.476,3.476,0,0,1,.36,4.679A3.476,3.476,0,0,1,4.577,8.9C3.185,7.5,2.035,6.4,4.217,4.217S7.5,3.185,8.9,4.577Z"></path><path class="ql-even ql-stroke" d="M13.423,9.1a3.476,3.476,0,0,0-4.679-.36,3.476,3.476,0,0,0,.36,4.679c1.392,1.392,2.5,2.542,4.679.36S14.815,10.5,13.423,9.1Z"></path></svg>',B.fa,B.fP,'<svg viewbox="0 0 18 18"><line class="ql-stroke ql-thin" x1="15.5" x2="2.5" y1="8.5" y2="9.5"></line><path class="ql-fill" d="M9.007,8C6.542,7.791,6,7.519,6,6.5,6,5.792,7.283,5,9,5c1.571,0,2.765.679,2.969,1.309a1,1,0,0,0,1.9-.617C13.356,4.106,11.354,3,9,3,6.2,3,4,4.538,4,6.5a3.2,3.2,0,0,0,.5,1.843Z"></path><path class="ql-fill" d="M8.984,10C11.457,10.208,12,10.479,12,11.5c0,0.708-1.283,1.5-3,1.5-1.571,0-2.765-.679-2.969-1.309a1,1,0,1,0-1.9.617C4.644,13.894,6.646,15,9,15c2.8,0,5-1.538,5-3.5a3.2,3.2,0,0,0-.5-1.843Z"></path></svg>','<svg viewbox="0 0 18 18"><rect class="ql-stroke" height="12" width="12" x="3" y="3"></rect><rect class="ql-fill" height="2" width="3" x="5" y="5"></rect><rect class="ql-fill" height="2" width="4" x="9" y="5"></rect><g class="ql-fill ql-transparent"><rect height="2" width="3" x="5" y="8"></rect><rect height="2" width="4" x="9" y="8"></rect><rect height="2" width="3" x="5" y="11"></rect><rect height="2" width="4" x="9" y="11"></rect></g></svg>','<svg viewbox="0 0 18 18"><path class="ql-stroke" d="M5,3V9a4.012,4.012,0,0,0,4,4H9a4.012,4.012,0,0,0,4-4V3"></path><rect class="ql-fill" height="1" rx="0.5" ry="0.5" width="12" x="3" y="15"></rect></svg>','<svg viewbox="0 0 18 18"><rect class="ql-stroke" height="12" width="12" x="3" y="3"></rect><rect class="ql-fill" height="12" width="1" x="5" y="3"></rect><rect class="ql-fill" height="12" width="1" x="12" y="3"></rect><rect class="ql-fill" height="2" width="8" x="5" y="8"></rect><rect class="ql-fill" height="1" width="3" x="3" y="5"></rect><rect class="ql-fill" height="1" width="3" x="3" y="7"></rect><rect class="ql-fill" height="1" width="3" x="3" y="10"></rect><rect class="ql-fill" height="1" width="3" x="3" y="12"></rect><rect class="ql-fill" height="1" width="3" x="12" y="5"></rect><rect class="ql-fill" height="1" width="3" x="12" y="7"></rect><rect class="ql-fill" height="1" width="3" x="12" y="10"></rect><rect class="ql-fill" height="1" width="3" x="12" y="12"></rect></svg>',u.U,u.U,u.E,u.E,'<svg viewbox="0 0 18 18"><g class="ql-fill ql-stroke ql-thin ql-transparent"><rect height="3" rx="0.5" ry="0.5" width="7" x="4.5" y="2.5"></rect><rect height="3" rx="0.5" ry="0.5" width="7" x="4.5" y="12.5"></rect></g><rect class="ql-fill ql-stroke ql-thin" height="3" rx="0.5" ry="0.5" width="7" x="8.5" y="7.5"></rect><line class="ql-stroke ql-thin" x1="6.5" x2="3.5" y1="7.5" y2="10.5"></line><line class="ql-stroke ql-thin" x1="3.5" x2="6.5" y1="7.5" y2="10.5"></line></svg>','<svg viewbox="0 0 18 18"><g class="ql-fill ql-transparent"><rect height="10" rx="1" ry="1" width="4" x="2" y="6"></rect><rect height="10" rx="1" ry="1" width="4" x="12" y="6"></rect></g><rect class="ql-fill" height="8" rx="1" ry="1" width="4" x="7" y="2"></rect><path class="ql-fill" d="M9.707,13l1.146-1.146a0.5,0.5,0,0,0-.707-0.707L9,12.293,7.854,11.146a0.5,0.5,0,0,0-.707.707L8.293,13,7.146,14.146a0.5,0.5,0,1,0,.707.707L9,13.707l1.146,1.146a0.5,0.5,0,0,0,.707-0.707Z"></path></svg>','<svg viewbox="0 0 18 18"><path class="ql-fill" d="M15.707,7l1.146-1.146a0.5,0.5,0,1,0-.707-0.707L15,6.293,13.854,5.146a0.5,0.5,0,0,0-.707.707L14.293,7,13.146,8.146a0.5,0.5,0,1,0,.707.707L15,7.707l1.146,1.146a0.5,0.5,0,1,0,.707-0.707Z"></path><path class="ql-fill" d="M6,5H3A1,1,0,0,0,2,6V8A1,1,0,0,0,3,9H6V5Z"></path><path class="ql-fill" d="M10,5H7V9h3a1,1,0,0,0,1-1V6A1,1,0,0,0,10,5Z"></path><g class="ql-fill ql-transparent"><path d="M8,11h4V9a1,1,0,0,0-1-1H8v3Z"></path><path d="M7,11V8H4A1,1,0,0,0,3,9v2H7Z"></path><path d="M7,12H3v2a1,1,0,0,0,1,1H7V12Z"></path><path d="M8,12v3h3a1,1,0,0,0,1-1V12H8Z"></path><path d="M8,6h3a1,1,0,0,0,1-1V3a1,1,0,0,0-1-1H8V6Z"></path><path d="M4,6H7V2H4A1,1,0,0,0,3,3V5A1,1,0,0,0,4,6Z"></path></g></svg>','<svg viewbox="0 0 18 18"><rect class="ql-stroke" height="4" width="12" x="3" y="7"></rect><path class="ql-fill ql-transparent" d="M2,2V16H16V2H2ZM14,14H10V11H8v3H4V4H8V7h2V4h4V14Z"></path></svg>','<svg viewbox="0 0 18 18"><rect class="ql-stroke" height="4" width="12" x="3" y="7"></rect><path class="ql-fill ql-transparent" d="M2,2V16H16V2H2ZM14,14H10V11H8v3H4V4H8V7h2V4h4V14Z"></path><line class="ql-stroke" x1="12" x2="12" y1="11" y2="7"></line><line class="ql-stroke" x1="9" x2="9" y1="11" y2="7"></line><line class="ql-stroke" x1="6" x2="6" y1="11" y2="7"></line></svg>'],t.BV)
B.j9=new A.kh(0,"svg")
B.C=new A.kh(1,"tabler")
B.ja=new A.G(0,0)
B.bz=new A.ao(null,null)
B.jH=new A.ao(!0,null)
B.aq=new A.fx(1,"center")
B.ar=new A.fx(2,"right")
B.as=new A.fx(3,"alignment")
B.at=new A.fx(4,"justify")
B.jK=new A.al(B.bu,4,t.M)
B.j8={about:0,data:1,http:2,https:3,mailto:4,tel:5}
B.jL=new A.al(B.j8,6,t.M)
B.iX={"\\end":0}
B.jM=new A.al(B.iX,1,t.M)
B.iH={"w:sectPr":0}
B.jN=new A.al(B.iH,1,t.M)
B.j5={P:0,OL:1,UL:2}
B.bA=new A.al(B.j5,3,t.M)
B.az=new A.bK(7,"amp")
B.aA=new A.bK(8,"rowSep")
B.E=new A.bK(9,"eof")
B.jO=new A.et([B.az,B.aA,B.E],t.gy)
B.au=new A.et([B.E],t.gy)
B.iE={block:0,break:1,cursor:2,inline:3,scroll:4,text:5,"code-block-container":6,"list-container":7,"table-container":8,"table-body":9,"table-thead":10,"table-row":11,"table-th-row":12,"table-colgroup":13,"table-list-container":14}
B.jP=new A.al(B.iE,15,t.M)
B.j0={image:0,video:1,formula:2}
B.jQ=new A.al(B.j0,3,t.M)
B.ix={insertText:0,insertReplacementText:1}
B.jR=new A.al(B.ix,2,t.M)
B.iJ={TABLE:0}
B.jS=new A.al(B.iJ,1,t.M)
B.ir={"table-cell-block":0,"table-th-block":1,"table-header":2,"table-list":3}
B.jT=new A.al(B.ir,4,t.M)
B.j1={address:0,article:1,blockquote:2,canvas:3,dd:4,div:5,dl:6,dt:7,fieldset:8,figcaption:9,figure:10,footer:11,form:12,h1:13,h2:14,h3:15,h4:16,h5:17,h6:18,header:19,iframe:20,li:21,main:22,nav:23,ol:24,output:25,p:26,pre:27,section:28,table:29,td:30,tr:31,ul:32,video:33}
B.jU=new A.al(B.j1,34,t.M)
B.iB={"w:tcPr":0}
B.jV=new A.al(B.iB,1,t.M)
B.iv={"=":0,"<":1,">":2,":":3}
B.jW=new A.al(B.iv,4,t.M)
B.iQ={"\\binom":0,"\\dbinom":1,"\\tbinom":2}
B.jX=new A.al(B.iQ,3,t.M)
B.av=new A.al(B.v,0,t.M)
B.jY=new A.al(B.v,0,A.ax("al<cX>"))
B.iO={header:0,list:1,align:2,direction:3,indent:4}
B.bB=new A.al(B.iO,5,t.M)
B.Q=new A.bK(4,"close")
B.bC=new A.et([B.Q],t.gy)
B.iK={TD:0,TH:1}
B.jZ=new A.al(B.iK,2,t.M)
B.it={"\\right":0}
B.k_=new A.al(B.it,1,t.M)
B.iz={")":0,"]":1}
B.k0=new A.al(B.iz,2,t.M)
B.iR={"\\text":0,"\\textrm":1,"\\textnormal":2,"\\mbox":3}
B.k1=new A.al(B.iR,4,t.M)
B.iP={"\\frac":0,"\\dfrac":1,"\\tfrac":2,"\\cfrac":3}
B.k2=new A.al(B.iP,4,t.M)
B.iA={align:0,direction:1,indent:2,list:3,header:4,blockquote:5,"code-block":6,table:7}
B.k3=new A.al(B.iA,8,t.M)
B.iV={href:0,src:1,"xlink:href":2,action:3,formaction:4,poster:5,background:6,cite:7,data:8}
B.k4=new A.al(B.iV,9,t.M)
B.iY={"+":0,"-":1,"*":2,"/":3}
B.k5=new A.al(B.iY,4,t.M)
B.iM={"(":0,"[":1}
B.k6=new A.al(B.iM,2,t.M)
B.k7=new A.al(B.a3,1,t.M)
B.j7={SCRIPT:0,STYLE:1,LINK:2,META:3,BASE:4,TITLE:5,HEAD:6,OBJECT:7,EMBED:8,APPLET:9,NOSCRIPT:10}
B.k8=new A.al(B.j7,11,t.M)
B.my=new A.dh("call")
B.mN=new A.fF(null,null)
B.mO=new A.eG(null,null,null,!1)
B.mP=new A.kw(0,"all")
B.mQ=new A.kw(1,"empty")
B.aw=new A.ky(null,null,null,-1)
B.mR=new A.eI(0,"top")
B.mS=new A.eI(1,"right")
B.mT=new A.eI(2,"bottom")
B.mU=new A.eI(3,"left")
B.mV=new A.dZ(0,"first")
B.mW=new A.dZ(1,"second")
B.mX=new A.dZ(2,"third")
B.mY=new A.dZ(3,"fourth")
B.mZ=new A.dZ(4,"fifth")
B.n_=new A.dZ(5,"sixth")
B.n0=A.co("Kw")
B.n1=A.co("Kx")
B.n2=A.co("Dn")
B.n3=A.co("Do")
B.n4=A.co("Dx")
B.n5=A.co("Dy")
B.n6=A.co("Dz")
B.n7=A.co("am")
B.n8=A.co("J")
B.n9=A.co("EC")
B.na=A.co("xJ")
B.nb=A.co("ED")
B.nc=A.co("eK")
B.nd=new A.e2(B.b3,null)
B.ne=new A.td(!1)
B.nf=new A.eM(null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
B.ng=new A.eO(null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
B.z=new A.ik(0,"none")
B.O=new A.ik(1,"instruction")
B.bP=new A.ik(2,"result")
B.nh=new A.eX(0,"begin")
B.bQ=new A.eX(1,"end")
B.ni=new A.eX(2,"illegal")
B.D=new A.bK(0,"command")
B.P=new A.bK(1,"char")
B.nj=new A.bK(2,"number")
B.ay=new A.bK(3,"open")
B.bR=new A.bK(5,"sup")
B.bS=new A.bK(6,"sub")})();(function staticFields(){$.tY=null
$.c5=A.a([],t.tl)
$.zG=null
$.oO=0
$.cd=A.GZ()
$.yZ=null
$.yY=null
$.BJ=null
$.Bv=null
$.BW=null
$.vI=null
$.wi=null
$.yn=null
$.u8=A.a([],A.ax("w<t<J>?>"))
$.hb=null
$.iM=null
$.iN=null
$.y8=!1
$.aB=B.p
$.zQ=0
$.B7=!1
$.zL=A.b(t.N,t.z0)
$.zK=A.b(t.N,t.d)
$.oW=A.b(t.N,t.z)
$.xs=A.b(t.N,A.ax("@(ab,@)"))
$.hz=A.b(t.N,A.ax("jv"))
$.vz=A.l(["scope",4,"whitelist",A.a(["right","center","justify"],t.s)],t.N,t.z)
$.BF=A.l(["scope",2],t.N,t.z)
$.BD=A.l(["scope",2],t.N,t.z)
$.yi=A.l(["scope",4,"whitelist",A.a(["rtl"],t.s)],t.N,t.z)
$.BH=A.l(["scope",2,"whitelist",A.a(["serif","monospace"],t.s)],t.N,t.z)
$.I3=A.l(["scope",2,"whitelist",A.a(["small","large","huge"],t.s)],t.N,t.z)
$.JS=A.l(["scope",2,"whitelist",A.a(["10px","18px","32px"],t.s)],t.N,t.z)
$.Ep=A.a([],A.ax("w<x(C)>"))
$.xb=A.b(A.ax("+(e,~(bA))"),t.g)
$.Bg=0})();(function lazyInitializers(){var s=hunkHelpers.lazyFinal,r=hunkHelpers.lazy
s($,"KB","wU",()=>A.Ir("_$dart_dartClosure"))
s($,"KT","Ce",()=>A.dm(A.t5({
toString:function(){return"$receiver$"}})))
s($,"KU","Cf",()=>A.dm(A.t5({$method$:null,
toString:function(){return"$receiver$"}})))
s($,"KV","Cg",()=>A.dm(A.t5(null)))
s($,"KW","Ch",()=>A.dm(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(q){return q.message}}()))
s($,"KZ","Ck",()=>A.dm(A.t5(void 0)))
s($,"L_","Cl",()=>A.dm(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(q){return q.message}}()))
s($,"KY","Cj",()=>A.dm(A.Al(null)))
s($,"KX","Ci",()=>A.dm(function(){try{null.$method$}catch(q){return q.message}}()))
s($,"L1","Cn",()=>A.dm(A.Al(void 0)))
s($,"L0","Cm",()=>A.dm(function(){try{(void 0).$method$}catch(q){return q.message}}()))
s($,"L2","yG",()=>A.EX())
s($,"L9","Cr",()=>A.DP(4096))
s($,"L7","Cp",()=>new A.um().$0())
s($,"L8","Cq",()=>new A.ul().$0())
s($,"L3","Co",()=>A.DO(A.uE(A.a([-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-1,-2,-2,-2,-2,-2,62,-2,62,-2,63,52,53,54,55,56,57,58,59,60,61,-2,-2,-2,-1,-2,-2,-2,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,-2,-2,-2,-2,63,-2,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,-2,-2,-2,-2,-2],t.X))))
s($,"Ll","lw",()=>A.ls(B.n8))
s($,"KR","iZ",()=>{A.E3()
return $.oO})
s($,"Lu","CC",()=>A.G_())
s($,"Lh","Cu",()=>A.ns("quillEmitterDomBridge",t.v))
s($,"LE","yN",()=>new A.oU(A.ns("quillInstances",t.K)))
s($,"KL","lu",()=>A.l(["default",new A.oX()],t.N,A.ax("ck(ab,cG)")))
s($,"KC","yy",()=>A.Em(0))
r($,"Lq","yK",()=>A.D("[^a-zA-Z0-9]",!0,!1))
r($,"Lv","yL",()=>A.D("\\s",!0,!1))
r($,"Lp","yJ",()=>A.D("[\\r\\n]",!0,!1))
r($,"Lf","Cs",()=>A.D("\\n\\r?\\n$",!0,!1))
r($,"Lg","Ct",()=>A.D("^\\r?\\n\\r?\\n",!0,!1))
s($,"Kr","C5",()=>new A.j2("align","align",$.vz))
s($,"Ks","yw",()=>new A.j3("align","ql-align",$.vz))
s($,"Kt","yx",()=>new A.j4("align","text-align",$.vz))
s($,"Ku","C6",()=>new A.j6("background","ql-bg",$.BF))
s($,"Kv","wS",()=>new A.j8("background","background-color",$.BF))
s($,"Kz","C8",()=>new A.jk("color","ql-color",$.BD))
s($,"KA","wT",()=>new A.jm("color","color",$.BD))
s($,"KD","yz",()=>new A.js("direction","dir",$.yi))
s($,"KE","yA",()=>new A.jt("direction","ql-direction",$.yi))
s($,"KF","yB",()=>{var q="direction"
return new A.ju(q,q,$.yi)})
s($,"KG","yC",()=>new A.jB("font","ql-font",$.BH))
s($,"KH","yD",()=>new A.jC("font","font-family",$.BH))
s($,"KJ","Ca",()=>new A.jN("indent","ql-indent",A.l(["scope",4,"whitelist",A.a([1,2,3,4,5,6,7,8],t.X)],t.N,t.z)))
s($,"KO","yE",()=>new A.kp("size","ql-size",$.I3))
s($,"KP","yF",()=>new A.kq("size","font-size",$.JS))
s($,"LC","yM",()=>A.GE(A.a([B.ct,B.cC,B.cu,B.cw,B.cq,B.cD,B.cA,B.cz,B.cx,B.cs,B.cB,B.cv,B.cy,B.cr],A.ax("w<aY>"))))
s($,"Lk","Cw",()=>A.D("^[A-Za-z\u0370-\u03ff\u1f00-\u1fff\u2100-\u214f]$",!0,!1))
s($,"L5","yH",()=>A.D("[A-Za-z]",!0,!1))
s($,"L4","lv",()=>A.D("[0-9]",!0,!1))
s($,"L6","yI",()=>A.D("[ \\t\\r\\n]",!0,!1))
s($,"Li","wV",()=>A.ns("_clipboardAttributorsByName",A.ax("B<e,aj>")))
s($,"Kq","C4",()=>A.AW(A.a([$.C5(),$.yz()],t.vs)))
s($,"KN","Cc",()=>A.AW(A.a([$.yx(),$.wS(),$.wT(),$.yB(),$.yD(),$.yF()],t.vs)))
s($,"Ky","C7",()=>A.a([[3,A.HY()],[3,A.BA()],["br",A.HR()],[1,A.BA()],[1,A.HQ()],[1,A.HP()],[1,A.HW()],["li",A.HU()],["ol, ul",A.HV()],["pre",A.HS()],["tr",A.HX()],["b",A.lp("bold")],["strong",A.lp("bold")],["i",A.lp("italic")],["em",A.lp("italic")],["strike",A.lp("strike")],["style",A.HT()]],t.t6))
s($,"Ls","CB",()=>A.ns(null,t.v))
s($,"Lx","CD",()=>new A.oj())
s($,"KK","Cb",()=>{var q="Tab",p=null,o="Backspace",n="Enter",m="ArrowLeft",l="ArrowRight",k=t.s,j=t.N
return A.DI(A.l(["bold",A.yq("bold"),"italic",A.yq("italic"),"underline",A.yq("underline"),"indent",A.bz(!1,p,!1,p,A.a(["blockquote","indent","list"],k),A.J_(),q,!1,p,p,!1,p,p),"outdent",A.bz(!1,p,!1,p,A.a(["blockquote","indent","list"],k),A.J2(),q,!1,p,p,!0,p,p),"outdent backspace",A.bz(p,!0,p,p,A.a(["indent","list"],k),A.J3(),o,p,0,p,p,p,p),"indent code-block",A.BQ(!0),"outdent code-block",A.BQ(!1),"remove tab",A.bz(!1,!0,!1,p,p,A.J4(),q,!1,p,A.D("\\t$",!0,!1),!0,p,p),"tab",A.bz(!1,p,!1,p,p,A.J5(),q,!1,p,p,!1,p,p),"blockquote empty enter",A.bz(!1,!0,!1,!0,A.a(["blockquote"],k),A.IQ(),n,!1,p,p,!1,p,p),"list empty enter",A.bz(!1,!0,!1,!0,A.a(["list"],k),A.J1(),n,!1,p,p,!1,p,p),"checklist enter",A.bz(!1,!0,!1,p,A.l(["list","checked"],j,j),A.IR(),n,!1,p,p,!1,p,p),"header enter",A.bz(!1,!0,!1,p,A.a(["header"],k),A.IZ(),n,!1,p,p,!1,p,A.D("^$",!0,!1)),"table backspace",A.bz(!1,!0,!1,p,A.a(["table"],k),A.BP(),o,!1,0,p,!1,p,p),"table delete",A.bz(!1,!0,!1,p,A.a(["table"],k),A.BP(),"Delete",!1,p,p,!1,p,A.D("^$",!0,!1)),"table enter",A.bz(!1,p,!1,p,A.a(["table"],k),A.J7(),n,!1,p,p,p,p,p),"table tab",A.bz(!1,p,!1,p,A.a(["table"],k),A.J8(),q,!1,p,p,p,p,p),"list autofill",A.bz(!1,!0,!1,p,A.l(["code-block",!1,"blockquote",!1,"table",!1],j,t.v),A.J0()," ",!1,p,A.D("^\\s*?(\\d+\\.|-|\\*|\\[ ?\\]|\\[x\\])$",!0,!1),p,p,p),"code exit",A.bz(!1,!0,!1,p,A.a(["code-block"],k),A.IU(),n,!1,p,A.D("^$",!0,!1),!1,p,A.D("^\\s*$",!0,!1)),"embed left",A.wp(m,!1),"embed left shift",A.wp(m,!0),"embed right",A.wp(l,!1),"embed right shift",A.wp(l,!0),"table down",A.BR(!1),"table up",A.BR(!0)],j,t.z))})
s($,"LD","CF",()=>new A.oo(A.cc([A.Jz(),A.Iw()],A.ax("~(hC)"))))
s($,"Lr","CA",()=>A.D("font-weight:\\s*normal",!0,!1))
s($,"Ln","Cy",()=>A.D("\\bmso-list:[^;]*ignore",!1,!1))
s($,"Lm","Cx",()=>A.D("\\bmso-list:[^;]*\\bl(\\d+)",!1,!1))
s($,"Lo","Cz",()=>A.D("\\bmso-list:[^;]*\\blevel(\\d+)",!1,!1))
s($,"LI","lx",()=>new A.kC("code-token","hljs",B.f8))
s($,"LF","CG",()=>new A.jv(new A.wF(),new A.wG(),new A.wH()))
s($,"Ly","CE",()=>new A.ok())
s($,"KI","C9",()=>A.D('Symbol\\("([^"]*)"\\)',!0,!1))
s($,"LA","y",()=>{var q=new A.jF()
q.a=new A.hI()
return new A.ne(q)})
s($,"Lt","b0",()=>A.Ec())
s($,"Lj","Cv",()=>A.D("^\\S+@\\S+\\.\\S+$",!0,!1))
s($,"KQ","Cd",()=>B.a.ab(A.a(['<a class="ql-preview" rel="noopener noreferrer" target="_blank" href="about:blank"></a>','<input type="text" data-formula="e=mc^2" data-link="https://quilljs.com" data-video="Embed URL">','<a class="ql-action"></a>','<a class="ql-remove"></a>'],t.s),""))
s($,"LB","hn",()=>A.Y(B.fQ,t.N,t.z))
s($,"LG","yO",()=>{var q=t.N
return A.l(["align",A.l(["",A.aa("align-left"),"center",A.aa("align-center"),"right",A.aa("align-right"),"justify",A.aa("align-justified")],q,q),"background",A.aa("highlight"),"blockquote",A.aa("blockquote"),"bold",A.aa("bold"),"clean",A.aa("clear-formatting"),"code",A.aa("code"),"code-block",A.aa("code"),"color",A.aa("color-picker"),"direction",A.l(["",A.aa("text-direction-ltr"),"rtl",A.aa("text-direction-rtl")],q,q),"formula",A.aa("math-function"),"header",A.l(["1",A.aa("h-1"),"2",A.aa("h-2"),"3",A.aa("h-3"),"4",A.aa("h-4"),"5",A.aa("h-5"),"6",A.aa("h-6")],q,q),"italic",A.aa("italic"),"image",A.aa("photo"),"indent",A.l(["+1",A.aa("indent-increase"),"-1",A.aa("indent-decrease")],q,q),"link",A.aa("link"),"list",A.l(["bullet",A.aa("list"),"check",A.aa("list-check"),"ordered",A.aa("list-numbers")],q,q),"script",A.l(["sub",A.aa("subscript"),"super",A.aa("superscript")],q,q),"strike",A.aa("strikethrough"),"table",A.aa("table"),"table-row-above",A.aa("row-insert-top"),"table-row-below",A.aa("row-insert-bottom"),"table-column-left",A.aa("column-insert-left"),"table-column-right",A.aa("column-insert-right"),"table-delete-row",A.aa("row-remove"),"table-delete-column",A.aa("column-remove"),"table-delete",A.aa("table-off"),"underline",A.aa("underline"),"video",A.aa("video")],q,t.z)})})();(function nativeSupport(){!function(){var s=function(a){var m={}
m[a]=1
return Object.keys(hunkHelpers.convertToFastObject(m))[0]}
v.getIsolateTag=function(a){return s("___dart_"+a+v.isolateTag)}
var r="___dart_isolate_tags_"
var q=Object[r]||(Object[r]=Object.create(null))
var p="_ZxYxX"
for(var o=0;;o++){var n=s(p+"_"+o+"_")
if(!(n in q)){q[n]=1
v.isolateTag=n
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.dT,ArrayBufferView:A.hR,DataView:A.k2,Float32Array:A.k3,Float64Array:A.k4,Int16Array:A.k5,Int32Array:A.k6,Int8Array:A.k7,Uint16Array:A.k8,Uint32Array:A.k9,Uint8ClampedArray:A.hS,CanvasPixelArray:A.hS,Uint8Array:A.eC})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.bf.$nativeSuperclassTag="ArrayBufferView"
A.iq.$nativeSuperclassTag="ArrayBufferView"
A.ir.$nativeSuperclassTag="ArrayBufferView"
A.hQ.$nativeSuperclassTag="ArrayBufferView"
A.is.$nativeSuperclassTag="ArrayBufferView"
A.it.$nativeSuperclassTag="ArrayBufferView"
A.bV.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$1$1=function(a){return this(a)}
Function.prototype.$0=function(){return this()}
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$2$1=function(a){return this(a)}
Function.prototype.$1$0=function(){return this()}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$1$2=function(a,b){return this(a,b)}
Function.prototype.$2$0=function(){return this()}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var s=document.scripts
function onLoad(b){for(var q=0;q<s.length;++q){s[q].removeEventListener("load",onLoad,false)}a(b.target)}for(var r=0;r<s.length;++r){s[r].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var s=A.Jg
if(typeof dartMainRunner==="function"){dartMainRunner(s,[])}else{s([])}})})()
//# sourceMappingURL=bench_main.dart.js.map
