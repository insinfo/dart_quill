(function dartProgram(){function copyProperties(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
b[r]=a[r]}}function mixinPropertiesHard(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
if(!b.hasOwnProperty(r)){b[r]=a[r]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var t=function(){}
t.prototype={p:{}}
var s=new t()
if(!(Object.getPrototypeOf(s)&&Object.getPrototypeOf(s).p===t.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var r=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(r))return true}}catch(q){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var t=Object.create(b.prototype)
copyProperties(a.prototype,t)
a.prototype=t}}function inheritMany(a,b){for(var t=0;t<b.length;t++){inherit(b[t],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){var s=d()
if(a[b]!==t){A.mz(b)}a[b]=s}var r=a[b]
a[c]=function(){return r}
return r}}function makeConstList(a){a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var t=0;t<a.length;++t){convertToFastObject(a[t])}}var y=0
function instanceTearOffGetter(a,b){var t=null
return a?function(c){if(t===null)t=A.ib(b)
return new t(c,this)}:function(){if(t===null)t=A.ib(b)
return new t(this,null)}}function staticTearOffGetter(a){var t=null
return function(){if(t===null)t=A.ib(a).prototype
return t}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var t=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var s=staticTearOffGetter(t)
a[b]=s}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var t=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var s=instanceTearOffGetter(c,t)
a[b]=s}function setOrUpdateInterceptorsByTag(a){var t=v.interceptorsByTag
if(!t){v.interceptorsByTag=a
return}copyProperties(a,t)}function setOrUpdateLeafTags(a){var t=v.leafTags
if(!t){v.leafTags=a
return}copyProperties(a,t)}function updateTypes(a){var t=v.types
var s=t.length
t.push.apply(t,a)
return s}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var t=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},s=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:t(0,0,null,["$0"],0),_instance_1u:t(0,1,null,["$1"],0),_instance_2u:t(0,2,null,["$2"],0),_instance_0i:t(1,0,null,["$0"],0),_instance_1i:t(1,1,null,["$1"],0),_instance_2i:t(1,2,null,["$2"],0),_static_0:s(0,null,["$0"],0),_static_1:s(1,null,["$1"],0),_static_2:s(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
ii(a,b,c,d){return{i:a,p:b,e:c,x:d}},
hx(a){var t,s,r,q,p,o=a[v.dispatchPropertyName]
if(o==null)if($.ig==null){A.me()
o=a[v.dispatchPropertyName]}if(o!=null){t=o.p
if(!1===t)return o.i
if(!0===t)return a
s=Object.getPrototypeOf(a)
if(t===s)return o.i
if(o.e===s)throw A.c(A.iW("Return interceptor for "+A.i(t(a,o))))}r=a.constructor
if(r==null)q=null
else{p=$.hf
if(p==null)p=$.hf=v.getIsolateTag("_$dart_js")
q=r[p]}if(q!=null)return q
q=A.mk(a)
if(q!=null)return q
if(typeof a=="function")return B.ag
t=Object.getPrototypeOf(a)
if(t==null)return B.N
if(t===Object.prototype)return B.N
if(typeof r=="function"){p=$.hf
if(p==null)p=$.hf=v.getIsolateTag("_$dart_js")
Object.defineProperty(r,p,{value:B.B,enumerable:false,writable:true,configurable:true})
return B.B}return B.B},
iz(a,b){if(a<0||a>4294967295)throw A.c(A.N(a,0,4294967295,"length",null))
return J.kg(new Array(a),b)},
kg(a,b){var t=A.d(a,b.i("m<0>"))
t.$flags=1
return t},
kh(a,b){var t=u.e8
return J.jV(t.a(a),t.a(b))},
iB(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
kj(a,b){var t,s
for(t=a.length;b<t;){s=a.charCodeAt(b)
if(s!==32&&s!==13&&!J.iB(s))break;++b}return b},
kk(a,b){var t,s,r
for(t=a.length;b>0;b=s){s=b-1
if(!(s<t))return A.a(a,s)
r=a.charCodeAt(s)
if(r!==32&&r!==13&&!J.iB(r))break}return b},
b2(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.cc.prototype
return J.dz.prototype}if(typeof a=="string")return J.aR.prototype
if(a==null)return J.cd.prototype
if(typeof a=="boolean")return J.dy.prototype
if(Array.isArray(a))return J.m.prototype
if(typeof a!="object"){if(typeof a=="function")return J.aB.prototype
if(typeof a=="symbol")return J.bw.prototype
if(typeof a=="bigint")return J.bv.prototype
return a}if(a instanceof A.q)return a
return J.hx(a)},
aa(a){if(typeof a=="string")return J.aR.prototype
if(a==null)return a
if(Array.isArray(a))return J.m.prototype
if(typeof a!="object"){if(typeof a=="function")return J.aB.prototype
if(typeof a=="symbol")return J.bw.prototype
if(typeof a=="bigint")return J.bv.prototype
return a}if(a instanceof A.q)return a
return J.hx(a)},
id(a){if(a==null)return a
if(Array.isArray(a))return J.m.prototype
if(typeof a!="object"){if(typeof a=="function")return J.aB.prototype
if(typeof a=="symbol")return J.bw.prototype
if(typeof a=="bigint")return J.bv.prototype
return a}if(a instanceof A.q)return a
return J.hx(a)},
m6(a){if(typeof a=="number")return J.bu.prototype
if(typeof a=="string")return J.aR.prototype
if(a==null)return a
if(!(a instanceof A.q))return J.bd.prototype
return a},
m7(a){if(typeof a=="string")return J.aR.prototype
if(a==null)return a
if(!(a instanceof A.q))return J.bd.prototype
return a},
m8(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.aB.prototype
if(typeof a=="symbol")return J.bw.prototype
if(typeof a=="bigint")return J.bv.prototype
return a}if(a instanceof A.q)return a
return J.hx(a)},
H(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.b2(a).T(a,b)},
jT(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.mi(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.aa(a).h(a,b)},
jU(a,b){return J.m7(a).bd(a,b)},
bZ(a,b,c){return J.m8(a).c9(a,b,c)},
jV(a,b){return J.m6(a).ar(a,b)},
jW(a,b){return J.aa(a).A(a,b)},
eI(a,b){return J.id(a).K(a,b)},
M(a){return J.b2(a).gL(a)},
im(a){return J.aa(a).gB(a)},
jX(a){return J.aa(a).gD(a)},
J(a){return J.id(a).gv(a)},
ax(a){return J.aa(a).gp(a)},
jY(a){return J.b2(a).gM(a)},
io(a,b){return J.id(a).a_(a,b)},
x(a){return J.b2(a).t(a)},
dw:function dw(){},
dy:function dy(){},
cd:function cd(){},
cf:function cf(){},
aS:function aS(){},
dU:function dU(){},
bd:function bd(){},
aB:function aB(){},
bv:function bv(){},
bw:function bw(){},
m:function m(a){this.$ti=a},
f4:function f4(a){this.$ti=a},
b3:function b3(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
bu:function bu(){},
cc:function cc(){},
dz:function dz(){},
aR:function aR(){}},A={hO:function hO(){},
hH(a,b,c){if(b.i("h<0>").b(a))return new A.cN(a,b.i("@<0>").H(c).i("cN<1,2>"))
return new A.b4(a,b.i("@<0>").H(c).i("b4<1,2>"))},
aF(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
fB(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
ih(a){var t,s
for(t=$.ac.length,s=0;s<t;++s)if(a===$.ac[s])return!0
return!1},
fA(a,b,c,d){A.an(b,"start")
if(c!=null){A.an(c,"end")
if(b>c)A.aw(A.N(b,0,c,"start",null))}return new A.cw(a,b,c,d.i("cw<0>"))},
dH(a,b,c,d){if(u.V.b(a))return new A.c7(a,b,c.i("@<0>").H(d).i("c7<1,2>"))
return new A.bb(a,b,c.i("@<0>").H(d).i("bb<1,2>"))},
iR(a,b,c){var t="count"
if(u.V.b(a)){A.eJ(b,t,u.S)
A.an(b,t)
return new A.bs(a,b,c.i("bs<0>"))}A.eJ(b,t,u.S)
A.an(b,t)
return new A.aE(a,b,c.i("aE<0>"))},
f3(){return new A.bC("No element")},
ke(){return new A.bC("Too few elements")},
bR:function bR(){},
c1:function c1(a,b){this.a=a
this.$ti=b},
b4:function b4(a,b){this.a=a
this.$ti=b},
cN:function cN(a,b){this.a=a
this.$ti=b},
b5:function b5(a,b){this.a=a
this.$ti=b},
eM:function eM(a,b){this.a=a
this.b=b},
eN:function eN(a,b){this.a=a
this.b=b},
ch:function ch(a){this.a=a},
fz:function fz(){},
h:function h(){},
L:function L(){},
cw:function cw(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.$ti=d},
b9:function b9(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
bb:function bb(a,b,c){this.a=a
this.b=b
this.$ti=c},
c7:function c7(a,b,c){this.a=a
this.b=b
this.$ti=c},
ak:function ak(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
al:function al(a,b,c){this.a=a
this.b=b
this.$ti=c},
bE:function bE(a,b,c){this.a=a
this.b=b
this.$ti=c},
cA:function cA(a,b,c){this.a=a
this.b=b
this.$ti=c},
aE:function aE(a,b,c){this.a=a
this.b=b
this.$ti=c},
bs:function bs(a,b,c){this.a=a
this.b=b
this.$ti=c},
cu:function cu(a,b,c){this.a=a
this.b=b
this.$ti=c},
c8:function c8(a){this.$ti=a},
c9:function c9(a){this.$ti=a},
a6:function a6(a,b){this.a=a
this.$ti=b},
a7:function a7(a,b){this.a=a
this.$ti=b},
V:function V(){},
ct:function ct(a,b){this.a=a
this.$ti=b},
hI(){throw A.c(A.bD("Cannot modify unmodifiable Map"))},
jE(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
mi(a,b){var t
if(b!=null){t=b.x
if(t!=null)return t}return u.aU.b(a)},
i(a){var t
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
t=J.x(a)
return t},
dV(a){var t,s=$.iL
if(s==null)s=$.iL=Symbol("identityHashCode")
t=a[s]
if(t==null){t=Math.random()*0x3fffffff|0
a[s]=t}return t},
Q(a,b){var t,s,r,q,p,o=null,n=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(n==null)return o
if(3>=n.length)return A.a(n,3)
t=n[3]
if(b==null){if(t!=null)return parseInt(a,10)
if(n[2]!=null)return parseInt(a,16)
return o}if(b<2||b>36)throw A.c(A.N(b,2,36,"radix",o))
if(b===10&&t!=null)return parseInt(a,10)
if(b<10||t==null){s=b<=10?47+b:86+b
r=n[1]
for(q=r.length,p=0;p<q;++p)if((r.charCodeAt(p)|32)>s)return o}return parseInt(a,b)},
dW(a){var t,s
if(!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(a))return null
t=parseFloat(a)
if(isNaN(t)){s=B.b.I(a)
if(s==="NaN"||s==="+NaN"||s==="-NaN")return t
return null}return t},
ft(a){return A.kp(a)},
kp(a){var t,s,r,q
if(a instanceof A.q)return A.X(A.bp(a),null)
t=J.b2(a)
if(t===B.af||t===B.ah||u.ak.b(a)){s=B.E(a)
if(s!=="Object"&&s!=="")return s
r=a.constructor
if(typeof r=="function"){q=r.name
if(typeof q=="string"&&q!=="Object"&&q!=="")return q}}return A.X(A.bp(a),null)},
iM(a){if(a==null||typeof a=="number"||A.i8(a))return J.x(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.aP)return a.t(0)
if(a instanceof A.aJ)return a.c6(!0)
return"Instance of '"+A.ft(a)+"'"},
kq(){return Date.now()},
kr(){var t,s
if($.fu!==0)return
$.fu=1000
if(typeof window=="undefined")return
t=window
if(t==null)return
if(!!t.dartUseDateNowForTicks)return
s=t.performance
if(s==null)return
if(typeof s.now!="function")return
$.fu=1e6
$.dX=new A.fs(s)},
ks(a,b,c){var t,s,r,q
if(c<=500&&b===0&&c===a.length)return String.fromCharCode.apply(null,a)
for(t=b,s="";t<c;t=r){r=t+500
q=r<c?r:c
s+=String.fromCharCode.apply(null,a.subarray(t,q))}return s},
p(a){var t
if(0<=a){if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){t=a-65536
return String.fromCharCode((B.c.bc(t,10)|55296)>>>0,t&1023|56320)}}throw A.c(A.N(a,0,1114111,null,null))},
a(a,b){if(a==null)J.ax(a)
throw A.c(A.hv(a,b))},
hv(a,b){var t,s="index"
if(!A.i9(b))return new A.ay(!0,b,s,null)
t=A.af(J.ax(a))
if(b<0||b>=t)return A.f0(b,t,a,s)
return A.iN(b,s)},
jv(a){return new A.ay(!0,a,null,null)},
c(a){return A.jA(new Error(),a)},
jA(a,b){var t
if(b==null)b=new A.cx()
a.dartException=b
t=A.mA
if("defineProperty" in Object){Object.defineProperty(a,"message",{get:t})
a.name=""}else a.toString=t
return a},
mA(){return J.x(this.dartException)},
aw(a){throw A.c(a)},
ij(a,b){throw A.jA(b,a)},
T(a,b,c){var t
if(b==null)b=0
if(c==null)c=0
t=Error()
A.ij(A.lp(a,b,c),t)},
lp(a,b,c){var t,s,r,q,p,o,n,m,l
if(typeof b=="string")t=b
else{s="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
r=s.length
q=b
if(q>r){c=q/r|0
q%=r}t=s[q]}p=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
o=u.j.b(a)?"list":"ByteData"
n=a.$flags|0
m="a "
if((n&4)!==0)l="constant "
else if((n&2)!==0){l="unmodifiable "
m="an "}else l=(n&1)!==0?"fixed-length ":""
return new A.cz("'"+t+"': Cannot "+p+" "+m+l+o)},
l(a){throw A.c(A.Y(a))},
aG(a){var t,s,r,q,p,o
a=A.jD(a.replace(String({}),"$receiver$"))
t=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(t==null)t=A.d([],u.s)
s=t.indexOf("\\$arguments\\$")
r=t.indexOf("\\$argumentsExpr\\$")
q=t.indexOf("\\$expr\\$")
p=t.indexOf("\\$method\\$")
o=t.indexOf("\\$receiver\\$")
return new A.fR(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),s,r,q,p,o)},
fS(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(t){return t.message}}(a)},
iV(a){return function($expr$){try{$expr$.$method$}catch(t){return t.message}}(a)},
hP(a,b){var t=b==null,s=t?null:b.method
return new A.dA(a,s,t?null:b.receiver)},
jF(a){if(a==null)return new A.fk(a)
if(typeof a!=="object")return a
if("dartException" in a)return A.bq(a,a.dartException)
return A.lV(a)},
bq(a,b){if(u.bU.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
lV(a){var t,s,r,q,p,o,n,m,l,k,j,i,h
if(!("message" in a))return a
t=a.message
if("number" in a&&typeof a.number=="number"){s=a.number
r=s&65535
if((B.c.bc(s,16)&8191)===10)switch(r){case 438:return A.bq(a,A.hP(A.i(t)+" (Error "+r+")",null))
case 445:case 5007:A.i(t)
return A.bq(a,new A.co())}}if(a instanceof TypeError){q=$.jG()
p=$.jH()
o=$.jI()
n=$.jJ()
m=$.jM()
l=$.jN()
k=$.jL()
$.jK()
j=$.jP()
i=$.jO()
h=q.a2(t)
if(h!=null)return A.bq(a,A.hP(A.S(t),h))
else{h=p.a2(t)
if(h!=null){h.method="call"
return A.bq(a,A.hP(A.S(t),h))}else if(o.a2(t)!=null||n.a2(t)!=null||m.a2(t)!=null||l.a2(t)!=null||k.a2(t)!=null||n.a2(t)!=null||j.a2(t)!=null||i.a2(t)!=null){A.S(t)
return A.bq(a,new A.co())}}return A.bq(a,new A.ed(typeof t=="string"?t:""))}if(a instanceof RangeError){if(typeof t=="string"&&t.indexOf("call stack")!==-1)return new A.cv()
t=function(b){try{return String(b)}catch(g){}return null}(a)
return A.bq(a,new A.ay(!1,null,null,typeof t=="string"?t.replace(/^RangeError:\s*/,""):t))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof t=="string"&&t==="too much recursion")return new A.cv()
return a},
hE(a){if(a==null)return J.M(a)
if(typeof a=="object")return A.dV(a)
return J.M(a)},
m3(a,b){var t,s,r,q=a.length
for(t=0;t<q;t=r){s=t+1
r=s+1
b.n(0,a[t],a[s])}return b},
m4(a,b){var t,s=a.length
for(t=0;t<s;++t)b.j(0,a[t])
return b},
lz(a,b,c,d,e,f){u.Z.a(a)
switch(A.af(b)){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.c(A.cb("Unsupported number of arguments for wrapped closure"))},
lX(a,b){var t=a.$identity
if(!!t)return t
t=A.lY(a,b)
a.$identity=t
return t},
lY(a,b){var t
switch(b){case 0:t=a.$0
break
case 1:t=a.$1
break
case 2:t=a.$2
break
case 3:t=a.$3
break
case 4:t=a.$4
break
default:t=null}if(t!=null)return t.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.lz)},
k4(a1){var t,s,r,q,p,o,n,m,l,k,j=a1.co,i=a1.iS,h=a1.iI,g=a1.nDA,f=a1.aI,e=a1.fs,d=a1.cs,c=e[0],b=d[0],a=j[c],a0=a1.fT
a0.toString
t=i?Object.create(new A.e2().constructor.prototype):Object.create(new A.br(null,null).constructor.prototype)
t.$initialize=t.constructor
s=i?function static_tear_off(){this.$initialize()}:function tear_off(a2,a3){this.$initialize(a2,a3)}
t.constructor=s
s.prototype=t
t.$_name=c
t.$_target=a
r=!i
if(r)q=A.iu(c,a,h,g)
else{t.$static_name=c
q=a}t.$S=A.k0(a0,i,h)
t[b]=q
for(p=q,o=1;o<e.length;++o){n=e[o]
if(typeof n=="string"){m=j[n]
l=n
n=m}else l=""
k=d[o]
if(k!=null){if(r)n=A.iu(l,n,h,g)
t[k]=n}if(o===f)p=n}t.$C=p
t.$R=a1.rC
t.$D=a1.dV
return s},
k0(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.c("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.jZ)}throw A.c("Error in functionType of tearoff")},
k1(a,b,c,d){var t=A.it
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,t)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,t)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,t)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,t)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,t)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,t)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,t)}},
iu(a,b,c,d){if(c)return A.k3(a,b,d)
return A.k1(b.length,d,a,b)},
k2(a,b,c,d){var t=A.it,s=A.k_
switch(b?-1:a){case 0:throw A.c(new A.e_("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,s,t)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,s,t)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,s,t)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,s,t)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,s,t)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,s,t)
default:return function(e,f,g){return function(){var r=[g(this)]
Array.prototype.push.apply(r,arguments)
return e.apply(f(this),r)}}(d,s,t)}},
k3(a,b,c){var t,s
if($.ir==null)$.ir=A.iq("interceptor")
if($.is==null)$.is=A.iq("receiver")
t=b.length
s=A.k2(t,c,a,b)
return s},
ib(a){return A.k4(a)},
jZ(a,b){return A.d2(v.typeUniverse,A.bp(a.a),b)},
it(a){return a.a},
k_(a){return a.b},
iq(a){var t,s,r,q=new A.br("receiver","interceptor"),p=Object.getOwnPropertyNames(q)
p.$flags=1
t=p
for(p=t.length,s=0;s<p;++s){r=t[s]
if(q[r]===a)return r}throw A.c(A.hG("Field name "+a+" not found."))},
O(a){if(a==null)A.lW("boolean expression must not be null")
return a},
lW(a){throw A.c(new A.eu(a))},
n2(a){throw A.c(new A.ev(a))},
m9(a){return v.getIsolateTag(a)},
n1(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
mk(a){var t,s,r,q,p,o=A.S($.jz.$1(a)),n=$.hw[o]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.hB[o]
if(t!=null)return t
s=v.interceptorsByTag[o]
if(s==null){r=A.d3($.ju.$2(a,o))
if(r!=null){n=$.hw[r]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.hB[r]
if(t!=null)return t
s=v.interceptorsByTag[r]
o=r}}if(s==null)return null
t=s.prototype
q=o[0]
if(q==="!"){n=A.hD(t)
$.hw[o]=n
Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}if(q==="~"){$.hB[o]=t
return t}if(q==="-"){p=A.hD(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}if(q==="+")return A.jB(a,t)
if(q==="*")throw A.c(A.iW(o))
if(v.leafTags[o]===true){p=A.hD(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}else return A.jB(a,t)},
jB(a,b){var t=Object.getPrototypeOf(a)
Object.defineProperty(t,v.dispatchPropertyName,{value:J.ii(b,t,null,null),enumerable:false,writable:true,configurable:true})
return b},
hD(a){return J.ii(a,!1,null,!!a.$ia3)},
mm(a,b,c){var t=b.prototype
if(v.leafTags[a]===true)return A.hD(t)
else return J.ii(t,c,null,null)},
me(){if(!0===$.ig)return
$.ig=!0
A.mf()},
mf(){var t,s,r,q,p,o,n,m
$.hw=Object.create(null)
$.hB=Object.create(null)
A.md()
t=v.interceptorsByTag
s=Object.getOwnPropertyNames(t)
if(typeof window!="undefined"){window
r=function(){}
for(q=0;q<s.length;++q){p=s[q]
o=$.jC.$1(p)
if(o!=null){n=A.mm(p,t[p],o)
if(n!=null){Object.defineProperty(o,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
r.prototype=o}}}}for(q=0;q<s.length;++q){p=s[q]
if(/^[A-Za-z_]/.test(p)){m=t[p]
t["!"+p]=m
t["~"+p]=m
t["-"+p]=m
t["+"+p]=m
t["*"+p]=m}}},
md(){var t,s,r,q,p,o,n=B.Z()
n=A.bX(B.a_,A.bX(B.a0,A.bX(B.F,A.bX(B.F,A.bX(B.a1,A.bX(B.a2,A.bX(B.a3(B.E),n)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){t=dartNativeDispatchHooksTransformer
if(typeof t=="function")t=[t]
if(Array.isArray(t))for(s=0;s<t.length;++s){r=t[s]
if(typeof r=="function")n=r(n)||n}}q=n.getTag
p=n.getUnknownTag
o=n.prototypeForTag
$.jz=new A.hy(q)
$.ju=new A.hz(p)
$.jC=new A.hA(o)},
bX(a,b){return a(b)||b},
m1(a,b){var t=b.length,s=v.rttc[""+t+";"+a]
if(s==null)return null
if(t===0)return s
if(t===s.length)return s.apply(null,b)
return s(b)},
iC(a,b,c,d,e,f){var t=b?"m":"",s=c?"":"i",r=d?"u":"",q=e?"s":"",p=f?"g":"",o=function(g,h){try{return new RegExp(g,h)}catch(n){return n}}(a,t+s+r+q+p)
if(o instanceof RegExp)return o
throw A.c(A.dk("Illegal RegExp pattern ("+String(o)+")",a,null))},
mq(a,b,c){var t=a.indexOf(b,c)
return t>=0},
ic(a){if(a.indexOf("$",0)>=0)return a.replace(/\$/g,"$$$$")
return a},
mt(a,b,c,d){var t=b.bO(a,d)
if(t==null)return a
return A.mv(a,t.b.index,t.gaM(),c)},
jD(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
I(a,b,c){var t
if(typeof b=="string")return A.ms(a,b,c)
if(b instanceof A.ce){t=b.gbU()
t.lastIndex=0
return a.replace(t,A.ic(c))}return A.mr(a,b,c)},
mr(a,b,c){var t,s,r,q
for(t=J.jU(b,a),t=t.gv(t),s=0,r="";t.m();){q=t.gq()
r=r+a.substring(s,q.gbv())+c
s=q.gaM()}t=r+a.substring(s)
return t.charCodeAt(0)==0?t:t},
ms(a,b,c){var t,s,r
if(b===""){if(a==="")return c
t=a.length
s=""+c
for(r=0;r<t;++r)s=s+a[r]+c
return s.charCodeAt(0)==0?s:s}if(a.indexOf(b,0)<0)return a
if(a.length<500||c.indexOf("$",0)>=0)return a.split(b).join(c)
return a.replace(new RegExp(A.jD(b),"g"),A.ic(c))},
mu(a,b,c,d){return d===0?a.replace(b.b,A.ic(c)):A.mt(a,b,c,d)},
mv(a,b,c,d){return a.substring(0,b)+d+a.substring(c)},
R:function R(a,b){this.a=a
this.b=b},
bV:function bV(a,b,c){this.a=a
this.b=b
this.c=c},
c2:function c2(){},
ag:function ag(a,b,c){this.a=a
this.b=b
this.$ti=c},
bk:function bk(a,b){this.a=a
this.$ti=b},
bl:function bl(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
c3:function c3(){},
aA:function aA(a,b,c){this.a=a
this.b=b
this.$ti=c},
fs:function fs(a){this.a=a},
fR:function fR(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
co:function co(){},
dA:function dA(a,b,c){this.a=a
this.b=b
this.c=c},
ed:function ed(a){this.a=a},
fk:function fk(a){this.a=a},
aP:function aP(){},
db:function db(){},
dc:function dc(){},
e9:function e9(){},
e2:function e2(){},
br:function br(a,b){this.a=a
this.b=b},
ev:function ev(a){this.a=a},
e_:function e_(a){this.a=a},
eu:function eu(a){this.a=a},
aC:function aC(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
f6:function f6(a){this.a=a},
f5:function f5(a){this.a=a},
fc:function fc(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
aj:function aj(a,b){this.a=a
this.$ti=b},
ci:function ci(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
hy:function hy(a){this.a=a},
hz:function hz(a){this.a=a},
hA:function hA(a){this.a=a},
aJ:function aJ(){},
bT:function bT(){},
bU:function bU(){},
ce:function ce(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
eB:function eB(a){this.b=a},
et:function et(a,b,c){this.a=a
this.b=b
this.c=c},
cL:function cL(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
e5:function e5(a,b){this.a=a
this.c=b},
eC:function eC(a,b,c){this.a=a
this.b=b
this.c=c},
eD:function eD(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
i6(a){return a},
km(a){return new Uint8Array(a)},
iJ(a,b,c){return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
aL(a,b,c){if(a>>>0!==a||a>=c)throw A.c(A.hv(b,a))},
bz:function bz(){},
ck:function ck(){},
ho:function ho(a){this.a=a},
dI:function dI(){},
P:function P(){},
cj:function cj(){},
a4:function a4(){},
dJ:function dJ(){},
dK:function dK(){},
dL:function dL(){},
dM:function dM(){},
dN:function dN(){},
dO:function dO(){},
dP:function dP(){},
cl:function cl(){},
cm:function cm(){},
cU:function cU(){},
cV:function cV(){},
cW:function cW(){},
cX:function cX(){},
iP(a,b){var t=b.c
return t==null?b.c=A.i5(a,b.x,!0):t},
hU(a,b){var t=b.c
return t==null?b.c=A.d0(a,"ix",[b.x]):t},
iQ(a){var t=a.w
if(t===6||t===7||t===8)return A.iQ(a.x)
return t===12||t===13},
kz(a){return a.as},
ap(a){return A.eF(v.typeUniverse,a,!1)},
b1(a0,a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a1.w
switch(a){case 5:case 1:case 2:case 3:case 4:return a1
case 6:t=a1.x
s=A.b1(a0,t,a2,a3)
if(s===t)return a1
return A.je(a0,s,!0)
case 7:t=a1.x
s=A.b1(a0,t,a2,a3)
if(s===t)return a1
return A.i5(a0,s,!0)
case 8:t=a1.x
s=A.b1(a0,t,a2,a3)
if(s===t)return a1
return A.jc(a0,s,!0)
case 9:r=a1.y
q=A.bW(a0,r,a2,a3)
if(q===r)return a1
return A.d0(a0,a1.x,q)
case 10:p=a1.x
o=A.b1(a0,p,a2,a3)
n=a1.y
m=A.bW(a0,n,a2,a3)
if(o===p&&m===n)return a1
return A.i3(a0,o,m)
case 11:l=a1.x
k=a1.y
j=A.bW(a0,k,a2,a3)
if(j===k)return a1
return A.jd(a0,l,j)
case 12:i=a1.x
h=A.b1(a0,i,a2,a3)
g=a1.y
f=A.lS(a0,g,a2,a3)
if(h===i&&f===g)return a1
return A.jb(a0,h,f)
case 13:e=a1.y
a3+=e.length
d=A.bW(a0,e,a2,a3)
p=a1.x
o=A.b1(a0,p,a2,a3)
if(d===e&&o===p)return a1
return A.i4(a0,o,d,!0)
case 14:c=a1.x
if(c<a3)return a1
b=a2[c-a3]
if(b==null)return a1
return b
default:throw A.c(A.d6("Attempted to substitute unexpected RTI kind "+a))}},
bW(a,b,c,d){var t,s,r,q,p=b.length,o=A.hs(p)
for(t=!1,s=0;s<p;++s){r=b[s]
q=A.b1(a,r,c,d)
if(q!==r)t=!0
o[s]=q}return t?o:b},
lT(a,b,c,d){var t,s,r,q,p,o,n=b.length,m=A.hs(n)
for(t=!1,s=0;s<n;s+=3){r=b[s]
q=b[s+1]
p=b[s+2]
o=A.b1(a,p,c,d)
if(o!==p)t=!0
m.splice(s,3,r,q,o)}return t?m:b},
lS(a,b,c,d){var t,s=b.a,r=A.bW(a,s,c,d),q=b.b,p=A.bW(a,q,c,d),o=b.c,n=A.lT(a,o,c,d)
if(r===s&&p===q&&n===o)return b
t=new A.ex()
t.a=r
t.b=p
t.c=n
return t},
d(a,b){a[v.arrayRti]=b
return a},
jw(a){var t=a.$S
if(t!=null){if(typeof t=="number")return A.ma(t)
return a.$S()}return null},
mg(a,b){var t
if(A.iQ(b))if(a instanceof A.aP){t=A.jw(a)
if(t!=null)return t}return A.bp(a)},
bp(a){if(a instanceof A.q)return A.j(a)
if(Array.isArray(a))return A.U(a)
return A.i7(J.b2(a))},
U(a){var t=a[v.arrayRti],s=u.b
if(t==null)return s
if(t.constructor!==s.constructor)return s
return t},
j(a){var t=a.$ti
return t!=null?t:A.i7(a)},
i7(a){var t=a.constructor,s=t.$ccache
if(s!=null)return s
return A.lx(a,t)},
lx(a,b){var t=a instanceof A.aP?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,s=A.lb(v.typeUniverse,t.name)
b.$ccache=s
return s},
ma(a){var t,s=v.types,r=s[a]
if(typeof r=="string"){t=A.eF(v.typeUniverse,r,!1)
s[a]=t
return t}return r},
ie(a){return A.bo(A.j(a))},
ia(a){var t
if(a instanceof A.aJ)return A.m2(a.$r,a.b4())
t=a instanceof A.aP?A.jw(a):null
if(t!=null)return t
if(u.dm.b(a))return J.jY(a).a
if(Array.isArray(a))return A.U(a)
return A.bp(a)},
bo(a){var t=a.r
return t==null?a.r=A.jl(a):t},
jl(a){var t,s,r=a.as,q=r.replace(/\*/g,"")
if(q===r)return a.r=new A.eE(a)
t=A.eF(v.typeUniverse,q,!0)
s=t.r
return s==null?t.r=A.jl(t):s},
m2(a,b){var t,s,r=b,q=r.length
if(q===0)return u.bQ
if(0>=q)return A.a(r,0)
t=A.d2(v.typeUniverse,A.ia(r[0]),"@<0>")
for(s=1;s<q;++s){if(!(s<r.length))return A.a(r,s)
t=A.jf(v.typeUniverse,t,A.ia(r[s]))}return A.d2(v.typeUniverse,t,a)},
aq(a){return A.bo(A.eF(v.typeUniverse,a,!1))},
lw(a){var t,s,r,q,p,o,n=this
if(n===u.K)return A.aM(n,a,A.lE)
if(!A.aO(n))t=n===u._
else t=!0
if(t)return A.aM(n,a,A.lK)
t=n.w
if(t===7)return A.aM(n,a,A.lu)
if(t===1)return A.aM(n,a,A.jp)
s=t===6?n.x:n
r=s.w
if(r===8)return A.aM(n,a,A.lA)
if(s===u.S)q=A.i9
else if(s===u.i||s===u.H)q=A.lD
else if(s===u.N)q=A.lI
else q=s===u.B?A.i8:null
if(q!=null)return A.aM(n,a,q)
if(r===9){p=s.x
if(s.y.every(A.mh)){n.f="$i"+p
if(p==="k")return A.aM(n,a,A.lC)
return A.aM(n,a,A.lJ)}}else if(r===11){o=A.m1(s.x,s.y)
return A.aM(n,a,o==null?A.jp:o)}return A.aM(n,a,A.ls)},
aM(a,b,c){a.b=c
return a.b(b)},
lv(a){var t,s=this,r=A.lr
if(!A.aO(s))t=s===u._
else t=!0
if(t)r=A.lj
else if(s===u.K)r=A.li
else{t=A.d4(s)
if(t)r=A.lt}s.a=r
return s.a(a)},
eG(a){var t=a.w,s=!0
if(!A.aO(a))if(!(a===u._))if(!(a===u.A))if(t!==7)if(!(t===6&&A.eG(a.x)))s=t===8&&A.eG(a.x)||a===u.P||a===u.T
return s},
ls(a){var t=this
if(a==null)return A.eG(t)
return A.mj(v.typeUniverse,A.mg(a,t),t)},
lu(a){if(a==null)return!0
return this.x.b(a)},
lJ(a){var t,s=this
if(a==null)return A.eG(s)
t=s.f
if(a instanceof A.q)return!!a[t]
return!!J.b2(a)[t]},
lC(a){var t,s=this
if(a==null)return A.eG(s)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
t=s.f
if(a instanceof A.q)return!!a[t]
return!!J.b2(a)[t]},
lr(a){var t=this
if(a==null){if(A.d4(t))return a}else if(t.b(a))return a
A.jm(a,t)},
lt(a){var t=this
if(a==null)return a
else if(t.b(a))return a
A.jm(a,t)},
jm(a,b){throw A.c(A.l2(A.j4(a,A.X(b,null))))},
j4(a,b){return A.ca(a)+": type '"+A.X(A.ia(a),null)+"' is not a subtype of type '"+b+"'"},
l2(a){return new A.cZ("TypeError: "+a)},
W(a,b){return new A.cZ("TypeError: "+A.j4(a,b))},
lA(a){var t=this,s=t.w===6?t.x:t
return s.x.b(a)||A.hU(v.typeUniverse,s).b(a)},
lE(a){return a!=null},
li(a){if(a!=null)return a
throw A.c(A.W(a,"Object"))},
lK(a){return!0},
lj(a){return a},
jp(a){return!1},
i8(a){return!0===a||!1===a},
mT(a){if(!0===a)return!0
if(!1===a)return!1
throw A.c(A.W(a,"bool"))},
mV(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.c(A.W(a,"bool"))},
mU(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.c(A.W(a,"bool?"))},
lg(a){if(typeof a=="number")return a
throw A.c(A.W(a,"double"))},
mX(a){if(typeof a=="number")return a
if(a==null)return a
throw A.c(A.W(a,"double"))},
mW(a){if(typeof a=="number")return a
if(a==null)return a
throw A.c(A.W(a,"double?"))},
i9(a){return typeof a=="number"&&Math.floor(a)===a},
af(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.c(A.W(a,"int"))},
mY(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.c(A.W(a,"int"))},
jj(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.c(A.W(a,"int?"))},
lD(a){return typeof a=="number"},
jk(a){if(typeof a=="number")return a
throw A.c(A.W(a,"num"))},
mZ(a){if(typeof a=="number")return a
if(a==null)return a
throw A.c(A.W(a,"num"))},
lh(a){if(typeof a=="number")return a
if(a==null)return a
throw A.c(A.W(a,"num?"))},
lI(a){return typeof a=="string"},
S(a){if(typeof a=="string")return a
throw A.c(A.W(a,"String"))},
n_(a){if(typeof a=="string")return a
if(a==null)return a
throw A.c(A.W(a,"String"))},
d3(a){if(typeof a=="string")return a
if(a==null)return a
throw A.c(A.W(a,"String?"))},
jt(a,b){var t,s,r
for(t="",s="",r=0;r<a.length;++r,s=", ")t+=s+A.X(a[r],b)
return t},
lQ(a,b){var t,s,r,q,p,o,n=a.x,m=a.y
if(""===n)return"("+A.jt(m,b)+")"
t=m.length
s=n.split(",")
r=s.length-t
for(q="(",p="",o=0;o<t;++o,p=", "){q+=p
if(r===0)q+="{"
q+=A.X(m[o],b)
if(r>=0)q+=" "+s[r];++r}return q+"})"},
jn(a3,a4,a5){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=", ",a2=null
if(a5!=null){t=a5.length
if(a4==null)a4=A.d([],u.s)
else a2=a4.length
s=a4.length
for(r=t;r>0;--r)B.a.j(a4,"T"+(s+r))
for(q=u.O,p=u._,o="<",n="",r=0;r<t;++r,n=a1){m=a4.length
l=m-1-r
if(!(l>=0))return A.a(a4,l)
o=o+n+a4[l]
k=a5[r]
j=k.w
if(!(j===2||j===3||j===4||j===5||k===q))m=k===p
else m=!0
if(!m)o+=" extends "+A.X(k,a4)}o+=">"}else o=""
q=a3.x
i=a3.y
h=i.a
g=h.length
f=i.b
e=f.length
d=i.c
c=d.length
b=A.X(q,a4)
for(a="",a0="",r=0;r<g;++r,a0=a1)a+=a0+A.X(h[r],a4)
if(e>0){a+=a0+"["
for(a0="",r=0;r<e;++r,a0=a1)a+=a0+A.X(f[r],a4)
a+="]"}if(c>0){a+=a0+"{"
for(a0="",r=0;r<c;r+=3,a0=a1){a+=a0
if(d[r+1])a+="required "
a+=A.X(d[r+2],a4)+" "+d[r]}a+="}"}if(a2!=null){a4.toString
a4.length=a2}return o+"("+a+") => "+b},
X(a,b){var t,s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6)return A.X(a.x,b)
if(m===7){t=a.x
s=A.X(t,b)
r=t.w
return(r===12||r===13?"("+s+")":s)+"?"}if(m===8)return"FutureOr<"+A.X(a.x,b)+">"
if(m===9){q=A.lU(a.x)
p=a.y
return p.length>0?q+("<"+A.jt(p,b)+">"):q}if(m===11)return A.lQ(a,b)
if(m===12)return A.jn(a,b,null)
if(m===13)return A.jn(a.x,b,a.y)
if(m===14){o=a.x
n=b.length
o=n-1-o
if(!(o>=0&&o<n))return A.a(b,o)
return b[o]}return"?"},
lU(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
lc(a,b){var t=a.tR[b]
for(;typeof t=="string";)t=a.tR[t]
return t},
lb(a,b){var t,s,r,q,p,o=a.eT,n=o[b]
if(n==null)return A.eF(a,b,!1)
else if(typeof n=="number"){t=n
s=A.d1(a,5,"#")
r=A.hs(t)
for(q=0;q<t;++q)r[q]=s
p=A.d0(a,b,r)
o[b]=p
return p}else return n},
la(a,b){return A.jh(a.tR,b)},
l9(a,b){return A.jh(a.eT,b)},
eF(a,b,c){var t,s=a.eC,r=s.get(b)
if(r!=null)return r
t=A.j8(A.j6(a,null,b,c))
s.set(b,t)
return t},
d2(a,b,c){var t,s,r=b.z
if(r==null)r=b.z=new Map()
t=r.get(c)
if(t!=null)return t
s=A.j8(A.j6(a,b,c,!0))
r.set(c,s)
return s},
jf(a,b,c){var t,s,r,q=b.Q
if(q==null)q=b.Q=new Map()
t=c.as
s=q.get(t)
if(s!=null)return s
r=A.i3(a,b,c.w===10?c.y:[c])
q.set(t,r)
return r},
aK(a,b){b.a=A.lv
b.b=A.lw
return b},
d1(a,b,c){var t,s,r=a.eC.get(c)
if(r!=null)return r
t=new A.ad(null,null)
t.w=b
t.as=c
s=A.aK(a,t)
a.eC.set(c,s)
return s},
je(a,b,c){var t,s=b.as+"*",r=a.eC.get(s)
if(r!=null)return r
t=A.l7(a,b,s,c)
a.eC.set(s,t)
return t},
l7(a,b,c,d){var t,s,r
if(d){t=b.w
if(!A.aO(b))s=b===u.P||b===u.T||t===7||t===6
else s=!0
if(s)return b}r=new A.ad(null,null)
r.w=6
r.x=b
r.as=c
return A.aK(a,r)},
i5(a,b,c){var t,s=b.as+"?",r=a.eC.get(s)
if(r!=null)return r
t=A.l6(a,b,s,c)
a.eC.set(s,t)
return t},
l6(a,b,c,d){var t,s,r,q
if(d){t=b.w
s=!0
if(!A.aO(b))if(!(b===u.P||b===u.T))if(t!==7)s=t===8&&A.d4(b.x)
if(s)return b
else if(t===1||b===u.A)return u.P
else if(t===6){r=b.x
if(r.w===8&&A.d4(r.x))return r
else return A.iP(a,b)}}q=new A.ad(null,null)
q.w=7
q.x=b
q.as=c
return A.aK(a,q)},
jc(a,b,c){var t,s=b.as+"/",r=a.eC.get(s)
if(r!=null)return r
t=A.l4(a,b,s,c)
a.eC.set(s,t)
return t},
l4(a,b,c,d){var t,s
if(d){t=b.w
if(A.aO(b)||b===u.K||b===u._)return b
else if(t===1)return A.d0(a,"ix",[b])
else if(b===u.P||b===u.T)return u.eH}s=new A.ad(null,null)
s.w=8
s.x=b
s.as=c
return A.aK(a,s)},
l8(a,b){var t,s,r=""+b+"^",q=a.eC.get(r)
if(q!=null)return q
t=new A.ad(null,null)
t.w=14
t.x=b
t.as=r
s=A.aK(a,t)
a.eC.set(r,s)
return s},
d_(a){var t,s,r,q=a.length
for(t="",s="",r=0;r<q;++r,s=",")t+=s+a[r].as
return t},
l3(a){var t,s,r,q,p,o=a.length
for(t="",s="",r=0;r<o;r+=3,s=","){q=a[r]
p=a[r+1]?"!":":"
t+=s+q+p+a[r+2].as}return t},
d0(a,b,c){var t,s,r,q=b
if(c.length>0)q+="<"+A.d_(c)+">"
t=a.eC.get(q)
if(t!=null)return t
s=new A.ad(null,null)
s.w=9
s.x=b
s.y=c
if(c.length>0)s.c=c[0]
s.as=q
r=A.aK(a,s)
a.eC.set(q,r)
return r},
i3(a,b,c){var t,s,r,q,p,o
if(b.w===10){t=b.x
s=b.y.concat(c)}else{s=c
t=b}r=t.as+(";<"+A.d_(s)+">")
q=a.eC.get(r)
if(q!=null)return q
p=new A.ad(null,null)
p.w=10
p.x=t
p.y=s
p.as=r
o=A.aK(a,p)
a.eC.set(r,o)
return o},
jd(a,b,c){var t,s,r="+"+(b+"("+A.d_(c)+")"),q=a.eC.get(r)
if(q!=null)return q
t=new A.ad(null,null)
t.w=11
t.x=b
t.y=c
t.as=r
s=A.aK(a,t)
a.eC.set(r,s)
return s},
jb(a,b,c){var t,s,r,q,p,o=b.as,n=c.a,m=n.length,l=c.b,k=l.length,j=c.c,i=j.length,h="("+A.d_(n)
if(k>0){t=m>0?",":""
h+=t+"["+A.d_(l)+"]"}if(i>0){t=m>0?",":""
h+=t+"{"+A.l3(j)+"}"}s=o+(h+")")
r=a.eC.get(s)
if(r!=null)return r
q=new A.ad(null,null)
q.w=12
q.x=b
q.y=c
q.as=s
p=A.aK(a,q)
a.eC.set(s,p)
return p},
i4(a,b,c,d){var t,s=b.as+("<"+A.d_(c)+">"),r=a.eC.get(s)
if(r!=null)return r
t=A.l5(a,b,c,s,d)
a.eC.set(s,t)
return t},
l5(a,b,c,d,e){var t,s,r,q,p,o,n,m
if(e){t=c.length
s=A.hs(t)
for(r=0,q=0;q<t;++q){p=c[q]
if(p.w===1){s[q]=p;++r}}if(r>0){o=A.b1(a,b,s,0)
n=A.bW(a,c,s,0)
return A.i4(a,o,n,c!==n)}}m=new A.ad(null,null)
m.w=13
m.x=b
m.y=c
m.as=d
return A.aK(a,m)},
j6(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
j8(a){var t,s,r,q,p,o,n,m=a.r,l=a.s
for(t=m.length,s=0;s<t;){r=m.charCodeAt(s)
if(r>=48&&r<=57)s=A.kY(s+1,r,m,l)
else if((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124)s=A.j7(a,s,m,l,!1)
else if(r===46)s=A.j7(a,s,m,l,!0)
else{++s
switch(r){case 44:break
case 58:l.push(!1)
break
case 33:l.push(!0)
break
case 59:l.push(A.b0(a.u,a.e,l.pop()))
break
case 94:l.push(A.l8(a.u,l.pop()))
break
case 35:l.push(A.d1(a.u,5,"#"))
break
case 64:l.push(A.d1(a.u,2,"@"))
break
case 126:l.push(A.d1(a.u,3,"~"))
break
case 60:l.push(a.p)
a.p=l.length
break
case 62:A.l_(a,l)
break
case 38:A.kZ(a,l)
break
case 42:q=a.u
l.push(A.je(q,A.b0(q,a.e,l.pop()),a.n))
break
case 63:q=a.u
l.push(A.i5(q,A.b0(q,a.e,l.pop()),a.n))
break
case 47:q=a.u
l.push(A.jc(q,A.b0(q,a.e,l.pop()),a.n))
break
case 40:l.push(-3)
l.push(a.p)
a.p=l.length
break
case 41:A.kX(a,l)
break
case 91:l.push(a.p)
a.p=l.length
break
case 93:p=l.splice(a.p)
A.j9(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-1)
break
case 123:l.push(a.p)
a.p=l.length
break
case 125:p=l.splice(a.p)
A.l1(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-2)
break
case 43:o=m.indexOf("(",s)
l.push(m.substring(s,o))
l.push(-4)
l.push(a.p)
a.p=l.length
s=o+1
break
default:throw"Bad character "+r}}}n=l.pop()
return A.b0(a.u,a.e,n)},
kY(a,b,c,d){var t,s,r=b-48
for(t=c.length;a<t;++a){s=c.charCodeAt(a)
if(!(s>=48&&s<=57))break
r=r*10+(s-48)}d.push(r)
return a},
j7(a,b,c,d,e){var t,s,r,q,p,o,n=b+1
for(t=c.length;n<t;++n){s=c.charCodeAt(n)
if(s===46){if(e)break
e=!0}else{if(!((((s|32)>>>0)-97&65535)<26||s===95||s===36||s===124))r=s>=48&&s<=57
else r=!0
if(!r)break}}q=c.substring(b,n)
if(e){t=a.u
p=a.e
if(p.w===10)p=p.x
o=A.lc(t,p.x)[q]
if(o==null)A.aw('No "'+q+'" in "'+A.kz(p)+'"')
d.push(A.d2(t,p,o))}else d.push(q)
return n},
l_(a,b){var t,s=a.u,r=A.j5(a,b),q=b.pop()
if(typeof q=="string")b.push(A.d0(s,q,r))
else{t=A.b0(s,a.e,q)
switch(t.w){case 12:b.push(A.i4(s,t,r,a.n))
break
default:b.push(A.i3(s,t,r))
break}}},
kX(a,b){var t,s,r,q=a.u,p=b.pop(),o=null,n=null
if(typeof p=="number")switch(p){case-1:o=b.pop()
break
case-2:n=b.pop()
break
default:b.push(p)
break}else b.push(p)
t=A.j5(a,b)
p=b.pop()
switch(p){case-3:p=b.pop()
if(o==null)o=q.sEA
if(n==null)n=q.sEA
s=A.b0(q,a.e,p)
r=new A.ex()
r.a=t
r.b=o
r.c=n
b.push(A.jb(q,s,r))
return
case-4:b.push(A.jd(q,b.pop(),t))
return
default:throw A.c(A.d6("Unexpected state under `()`: "+A.i(p)))}},
kZ(a,b){var t=b.pop()
if(0===t){b.push(A.d1(a.u,1,"0&"))
return}if(1===t){b.push(A.d1(a.u,4,"1&"))
return}throw A.c(A.d6("Unexpected extended operation "+A.i(t)))},
j5(a,b){var t=b.splice(a.p)
A.j9(a.u,a.e,t)
a.p=b.pop()
return t},
b0(a,b,c){if(typeof c=="string")return A.d0(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.l0(a,b,c)}else return c},
j9(a,b,c){var t,s=c.length
for(t=0;t<s;++t)c[t]=A.b0(a,b,c[t])},
l1(a,b,c){var t,s=c.length
for(t=2;t<s;t+=3)c[t]=A.b0(a,b,c[t])},
l0(a,b,c){var t,s,r=b.w
if(r===10){if(c===0)return b.x
t=b.y
s=t.length
if(c<=s)return t[c-1]
c-=s
b=b.x
r=b.w}else if(c===0)return b
if(r!==9)throw A.c(A.d6("Indexed base must be an interface type"))
t=b.y
if(c<=t.length)return t[c-1]
throw A.c(A.d6("Bad index "+c+" for "+b.t(0)))},
mj(a,b,c){var t,s=b.d
if(s==null)s=b.d=new Map()
t=s.get(c)
if(t==null){t=A.G(a,b,null,c,null,!1)?1:0
s.set(c,t)}if(0===t)return!1
if(1===t)return!0
return!0},
G(a,b,c,d,e,f){var t,s,r,q,p,o,n,m,l,k,j
if(b===d)return!0
if(!A.aO(d))t=d===u._
else t=!0
if(t)return!0
s=b.w
if(s===4)return!0
if(A.aO(b))return!1
t=b.w
if(t===1)return!0
r=s===14
if(r)if(A.G(a,c[b.x],c,d,e,!1))return!0
q=d.w
t=b===u.P||b===u.T
if(t){if(q===8)return A.G(a,b,c,d.x,e,!1)
return d===u.P||d===u.T||q===7||q===6}if(d===u.K){if(s===8)return A.G(a,b.x,c,d,e,!1)
if(s===6)return A.G(a,b.x,c,d,e,!1)
return s!==7}if(s===6)return A.G(a,b.x,c,d,e,!1)
if(q===6){t=A.iP(a,d)
return A.G(a,b,c,t,e,!1)}if(s===8){if(!A.G(a,b.x,c,d,e,!1))return!1
return A.G(a,A.hU(a,b),c,d,e,!1)}if(s===7){t=A.G(a,u.P,c,d,e,!1)
return t&&A.G(a,b.x,c,d,e,!1)}if(q===8){if(A.G(a,b,c,d.x,e,!1))return!0
return A.G(a,b,c,A.hU(a,d),e,!1)}if(q===7){t=A.G(a,b,c,u.P,e,!1)
return t||A.G(a,b,c,d.x,e,!1)}if(r)return!1
t=s!==12
if((!t||s===13)&&d===u.Z)return!0
p=s===11
if(p&&d===u.gT)return!0
if(q===13){if(b===u.W)return!0
if(s!==13)return!1
o=b.y
n=d.y
m=o.length
if(m!==n.length)return!1
c=c==null?o:o.concat(c)
e=e==null?n:n.concat(e)
for(l=0;l<m;++l){k=o[l]
j=n[l]
if(!A.G(a,k,c,j,e,!1)||!A.G(a,j,e,k,c,!1))return!1}return A.jo(a,b.x,c,d.x,e,!1)}if(q===12){if(b===u.W)return!0
if(t)return!1
return A.jo(a,b,c,d,e,!1)}if(s===9){if(q!==9)return!1
return A.lB(a,b,c,d,e,!1)}if(p&&q===11)return A.lF(a,b,c,d,e,!1)
return!1},
jo(a2,a3,a4,a5,a6,a7){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
if(!A.G(a2,a3.x,a4,a5.x,a6,!1))return!1
t=a3.y
s=a5.y
r=t.a
q=s.a
p=r.length
o=q.length
if(p>o)return!1
n=o-p
m=t.b
l=s.b
k=m.length
j=l.length
if(p+k<o+j)return!1
for(i=0;i<p;++i){h=r[i]
if(!A.G(a2,q[i],a6,h,a4,!1))return!1}for(i=0;i<n;++i){h=m[i]
if(!A.G(a2,q[p+i],a6,h,a4,!1))return!1}for(i=0;i<j;++i){h=m[n+i]
if(!A.G(a2,l[i],a6,h,a4,!1))return!1}g=t.c
f=s.c
e=g.length
d=f.length
for(c=0,b=0;b<d;b+=3){a=f[b]
for(;!0;){if(c>=e)return!1
a0=g[c]
c+=3
if(a<a0)return!1
a1=g[c-2]
if(a0<a){if(a1)return!1
continue}h=f[b+1]
if(a1&&!h)return!1
h=g[c-1]
if(!A.G(a2,f[b+2],a6,h,a4,!1))return!1
break}}for(;c<e;){if(g[c+1])return!1
c+=3}return!0},
lB(a,b,c,d,e,f){var t,s,r,q,p,o=b.x,n=d.x
for(;o!==n;){t=a.tR[o]
if(t==null)return!1
if(typeof t=="string"){o=t
continue}s=t[n]
if(s==null)return!1
r=s.length
q=r>0?new Array(r):v.typeUniverse.sEA
for(p=0;p<r;++p)q[p]=A.d2(a,b,s[p])
return A.ji(a,q,null,c,d.y,e,!1)}return A.ji(a,b.y,null,c,d.y,e,!1)},
ji(a,b,c,d,e,f,g){var t,s=b.length
for(t=0;t<s;++t)if(!A.G(a,b[t],d,e[t],f,!1))return!1
return!0},
lF(a,b,c,d,e,f){var t,s=b.y,r=d.y,q=s.length
if(q!==r.length)return!1
if(b.x!==d.x)return!1
for(t=0;t<q;++t)if(!A.G(a,s[t],c,r[t],e,!1))return!1
return!0},
d4(a){var t=a.w,s=!0
if(!(a===u.P||a===u.T))if(!A.aO(a))if(t!==7)if(!(t===6&&A.d4(a.x)))s=t===8&&A.d4(a.x)
return s},
mh(a){var t
if(!A.aO(a))t=a===u._
else t=!0
return t},
aO(a){var t=a.w
return t===2||t===3||t===4||t===5||a===u.O},
jh(a,b){var t,s,r=Object.keys(b),q=r.length
for(t=0;t<q;++t){s=r[t]
a[s]=b[s]}},
hs(a){return a>0?new Array(a):v.typeUniverse.sEA},
ad:function ad(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
ex:function ex(){this.c=this.b=this.a=null},
eE:function eE(a){this.a=a},
ew:function ew(){},
cZ:function cZ(a){this.a=a},
ja(a,b,c){return 0},
t:function t(a,b){var _=this
_.a=a
_.e=_.d=_.c=_.b=null
_.$ti=b},
bn:function bn(a,b){this.a=a
this.$ti=b},
iy(a,b,c,d,e){if(c==null)if(b==null){if(a==null)return new A.aI(d.i("@<0>").H(e).i("aI<1,2>"))
b=A.jy()}else{if(A.m0()===b&&A.m_()===a)return new A.cQ(d.i("@<0>").H(e).i("cQ<1,2>"))
if(a==null)a=A.jx()}else{if(b==null)b=A.jy()
if(a==null)a=A.jx()}return A.kU(a,b,c,d,e)},
i_(a,b){var t=a[b]
return t===a?null:t},
i1(a,b,c){if(c==null)a[b]=a
else a[b]=c},
i0(){var t=Object.create(null)
A.i1(t,"<non-identifier-key>",t)
delete t["<non-identifier-key>"]
return t},
kU(a,b,c,d,e){var t=c!=null?c:new A.ha(d)
return new A.cM(a,b,t,d.i("@<0>").H(e).i("cM<1,2>"))},
fd(a,b){return new A.aC(a.i("@<0>").H(b).i("aC<1,2>"))},
F(a,b,c){return b.i("@<0>").H(c).i("iE<1,2>").a(A.m3(a,new A.aC(b.i("@<0>").H(c).i("aC<1,2>"))))},
u(a,b){return new A.aC(a.i("@<0>").H(b).i("aC<1,2>"))},
iG(a){return new A.bm(a.i("bm<0>"))},
kl(a,b){return b.i("iF<0>").a(A.m4(a,new A.bm(b.i("bm<0>"))))},
i2(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
lm(a,b){return J.H(a,b)},
ln(a){return J.M(a)},
dF(a,b,c){var t=A.fd(b,c)
a.S(0,new A.fe(t,b,c))
return t},
hR(a){var t,s={}
if(A.ih(a))return"{...}"
t=new A.D("")
try{B.a.j($.ac,a)
t.a+="{"
s.a=!0
a.S(0,new A.fj(s,t))
t.a+="}"}finally{if(0>=$.ac.length)return A.a($.ac,-1)
$.ac.pop()}s=t.a
return s.charCodeAt(0)==0?s:s},
aI:function aI(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
he:function he(a){this.a=a},
cQ:function cQ(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
cM:function cM(a,b,c,d){var _=this
_.f=a
_.r=b
_.w=c
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=d},
ha:function ha(a){this.a=a},
bj:function bj(a,b){this.a=a
this.$ti=b},
cP:function cP(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
bm:function bm(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
eA:function eA(a){this.a=a
this.b=null},
cR:function cR(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
fe:function fe(a,b,c){this.a=a
this.b=b
this.c=c},
y:function y(){},
o:function o(){},
fi:function fi(a){this.a=a},
fj:function fj(a,b){this.a=a
this.b=b},
cS:function cS(a,b){this.a=a
this.$ti=b},
cT:function cT(a,b,c){var _=this
_.a=a
_.b=b
_.c=null
_.$ti=c},
ao:function ao(){},
cY:function cY(){},
lO(a,b){var t,s,r,q=null
try{q=JSON.parse(a)}catch(s){t=A.jF(s)
r=A.dk(String(t),null,null)
throw A.c(r)}r=A.ht(q)
return r},
ht(a){var t
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.ey(a,Object.create(null))
for(t=0;t<a.length;++t)a[t]=A.ht(a[t])
return a},
le(a,b,c){var t,s,r,q,p,o=c-b
if(o<=4096)t=$.jS()
else t=new Uint8Array(o)
for(s=a.length,r=0;r<o;++r){q=b+r
if(!(q<s))return A.a(a,q)
p=a[q]
if((p&255)!==p)p=255
t[r]=p}return t},
ld(a,b,c,d){var t=a?$.jR():$.jQ()
if(t==null)return null
if(0===c&&d===b.length)return A.jg(t,b)
return A.jg(t,b.subarray(c,d))},
jg(a,b){var t,s
try{t=a.decode(b)
return t}catch(s){}return null},
kT(a,b,c,d,e,f,g,h){var t,s,r,q,p,o,n,m,l,k,j=h>>>2,i=3-(h&3)
for(t=b.length,s=a.length,r=f.$flags|0,q=c,p=0;q<d;++q){if(!(q<t))return A.a(b,q)
o=b[q]
p|=o
j=(j<<8|o)&16777215;--i
if(i===0){n=g+1
m=j>>>18&63
if(!(m<s))return A.a(a,m)
r&2&&A.T(f)
l=f.length
if(!(g<l))return A.a(f,g)
f[g]=a.charCodeAt(m)
g=n+1
m=j>>>12&63
if(!(m<s))return A.a(a,m)
if(!(n<l))return A.a(f,n)
f[n]=a.charCodeAt(m)
n=g+1
m=j>>>6&63
if(!(m<s))return A.a(a,m)
if(!(g<l))return A.a(f,g)
f[g]=a.charCodeAt(m)
g=n+1
m=j&63
if(!(m<s))return A.a(a,m)
if(!(n<l))return A.a(f,n)
f[n]=a.charCodeAt(m)
j=0
i=3}}if(p>=0&&p<=255){if(i<3){n=g+1
k=n+1
if(3-i===1){t=j>>>2&63
if(!(t<s))return A.a(a,t)
r&2&&A.T(f)
r=f.length
if(!(g<r))return A.a(f,g)
f[g]=a.charCodeAt(t)
t=j<<4&63
if(!(t<s))return A.a(a,t)
if(!(n<r))return A.a(f,n)
f[n]=a.charCodeAt(t)
g=k+1
if(!(k<r))return A.a(f,k)
f[k]=61
if(!(g<r))return A.a(f,g)
f[g]=61}else{t=j>>>10&63
if(!(t<s))return A.a(a,t)
r&2&&A.T(f)
r=f.length
if(!(g<r))return A.a(f,g)
f[g]=a.charCodeAt(t)
t=j>>>4&63
if(!(t<s))return A.a(a,t)
if(!(n<r))return A.a(f,n)
f[n]=a.charCodeAt(t)
g=k+1
t=j<<2&63
if(!(t<s))return A.a(a,t)
if(!(k<r))return A.a(f,k)
f[k]=a.charCodeAt(t)
if(!(g<r))return A.a(f,g)
f[g]=61}return 0}return(j<<2|3-i)>>>0}for(q=c;q<d;){if(!(q<t))return A.a(b,q)
o=b[q]
if(o>255)break;++q}if(!(q<t))return A.a(b,q)
throw A.c(A.ip(b,"Not a byte value at index "+q+": 0x"+B.c.e9(b[q],16),null))},
iD(a,b,c){return new A.cg(a,b)},
lo(a){return a.aB()},
kV(a,b){return new A.hh(a,[],A.lZ())},
kW(a,b,c){var t,s=new A.D(""),r=A.kV(s,b)
r.aU(a)
t=s.a
return t.charCodeAt(0)==0?t:t},
lf(a){switch(a){case 65:return"Missing extension byte"
case 67:return"Unexpected extension byte"
case 69:return"Invalid UTF-8 byte"
case 71:return"Overlong encoding"
case 73:return"Out of unicode range"
case 75:return"Encoded surrogate"
case 77:return"Unfinished UTF-8 octet sequence"
default:return""}},
ey:function ey(a,b){this.a=a
this.b=b
this.c=null},
hg:function hg(a){this.a=a},
ez:function ez(a){this.a=a},
hr:function hr(){},
hq:function hq(){},
hn:function hn(){},
c0:function c0(){},
eK:function eK(){},
h9:function h9(a){this.a=0
this.b=a},
a1:function a1(){},
dg:function dg(){},
di:function di(){},
cg:function cg(a,b){this.a=a
this.b=b},
dC:function dC(a,b){this.a=a
this.b=b},
dB:function dB(){},
f8:function f8(a){this.b=a},
f7:function f7(a){this.a=a},
hi:function hi(){},
hj:function hj(a,b){this.a=a
this.b=b},
hh:function hh(a,b,c){this.c=a
this.a=b
this.b=c},
dD:function dD(){},
f9:function f9(a){this.a=a},
ee:function ee(){},
fU:function fU(a){this.a=a},
hp:function hp(a){this.a=a
this.b=16
this.c=0},
mc(a){return A.hE(a)},
ff(a,b,c,d){var t,s=J.iz(a,d)
if(a!==0&&b!=null)for(t=0;t<a;++t)s[t]=b
return s},
hQ(a,b,c){var t,s,r=A.d([],c.i("m<0>"))
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.l)(a),++s)B.a.j(r,c.a(a[s]))
if(b)return r
r.$flags=1
return r},
ba(a,b,c){var t
if(b)return A.iH(a,c)
t=A.iH(a,c)
t.$flags=1
return t},
iH(a,b){var t,s
if(Array.isArray(a))return A.d(a.slice(0),b.i("m<0>"))
t=A.d([],b.i("m<0>"))
for(s=J.J(a);s.m();)B.a.j(t,s.gq())
return t},
hV(a,b,c){var t,s
A.an(b,"start")
if(c!=null){t=c-b
if(t<0)throw A.c(A.N(c,b,null,"end",null))
if(t===0)return""}s=A.kB(a,b,c)
return s},
kB(a,b,c){var t=a.length
if(b>=t)return""
return A.ks(a,b,c==null||c>t?t:c)},
cs(a,b){return new A.ce(a,A.iC(a,!1,b,!1,!1,!1))},
mb(a,b){return a==null?b==null:a===b},
iT(a,b,c){var t=J.J(b)
if(!t.m())return a
if(c.length===0){do a+=A.i(t.gq())
while(t.m())}else{a+=A.i(t.gq())
for(;t.m();)a=a+c+A.i(t.gq())}return a},
ca(a){if(typeof a=="number"||A.i8(a)||a==null)return J.x(a)
if(typeof a=="string")return JSON.stringify(a)
return A.iM(a)},
d6(a){return new A.c_(a)},
hG(a){return new A.ay(!1,null,null,a)},
ip(a,b,c){return new A.ay(!0,a,b,c)},
eJ(a,b,c){return a},
iN(a,b){return new A.cp(null,null,!0,a,b,"Value not in range")},
N(a,b,c,d,e){return new A.cp(b,c,!0,a,d,"Invalid value")},
kw(a,b,c,d){if(a<b||a>c)throw A.c(A.N(a,b,c,d,null))
return a},
cq(a,b,c){if(0>a||a>c)throw A.c(A.N(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.c(A.N(b,a,c,"end",null))
return b}return c},
an(a,b){if(a<0)throw A.c(A.N(a,0,null,b,null))
return a},
f0(a,b,c,d){return new A.ds(b,!0,a,d,"Index out of range")},
bD(a){return new A.cz(a)},
iW(a){return new A.ec(a)},
iS(a){return new A.bC(a)},
Y(a){return new A.df(a)},
cb(a){return new A.hd(a)},
dk(a,b,c){return new A.ai(a,b,c)},
kf(a,b,c){var t,s
if(A.ih(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}t=A.d([],u.s)
B.a.j($.ac,a)
try{A.lL(a,t)}finally{if(0>=$.ac.length)return A.a($.ac,-1)
$.ac.pop()}s=A.iT(b,u.R.a(t),", ")+c
return s.charCodeAt(0)==0?s:s},
hN(a,b,c){var t,s
if(A.ih(a))return b+"..."+c
t=new A.D(b)
B.a.j($.ac,a)
try{s=t
s.a=A.iT(s.a,a,", ")}finally{if(0>=$.ac.length)return A.a($.ac,-1)
$.ac.pop()}t.a+=c
s=t.a
return s.charCodeAt(0)==0?s:s},
lL(a,b){var t,s,r,q,p,o,n,m=a.gv(a),l=0,k=0
while(!0){if(!(l<80||k<3))break
if(!m.m())return
t=A.i(m.gq())
B.a.j(b,t)
l+=t.length+2;++k}if(!m.m()){if(k<=5)return
if(0>=b.length)return A.a(b,-1)
s=b.pop()
if(0>=b.length)return A.a(b,-1)
r=b.pop()}else{q=m.gq();++k
if(!m.m()){if(k<=4){B.a.j(b,A.i(q))
return}s=A.i(q)
if(0>=b.length)return A.a(b,-1)
r=b.pop()
l+=s.length+2}else{p=m.gq();++k
for(;m.m();q=p,p=o){o=m.gq();++k
if(k>100){while(!0){if(!(l>75&&k>3))break
if(0>=b.length)return A.a(b,-1)
l-=b.pop().length+2;--k}B.a.j(b,"...")
return}}r=A.i(q)
s=A.i(p)
l+=s.length+r.length+4}}if(k>b.length+2){l+=5
n="..."}else n=null
while(!0){if(!(l>80&&b.length>3))break
if(0>=b.length)return A.a(b,-1)
l-=b.pop().length+2
if(n==null){l+=5
n="..."}}if(n!=null)B.a.j(b,n)
B.a.j(b,r)
B.a.j(b,s)},
iI(a,b,c,d,e){return new A.b5(a,b.i("@<0>").H(c).H(d).H(e).i("b5<1,2,3,4>"))},
dQ(a,b,c,d){var t
if(B.f===c){t=J.M(a)
b=J.M(b)
return A.fB(A.aF(A.aF($.eH(),t),b))}if(B.f===d){t=J.M(a)
b=J.M(b)
c=J.M(c)
return A.fB(A.aF(A.aF(A.aF($.eH(),t),b),c))}t=J.M(a)
b=J.M(b)
c=J.M(c)
d=J.M(d)
d=A.fB(A.aF(A.aF(A.aF(A.aF($.eH(),t),b),c),d))
return d},
iK(a){var t,s=$.eH()
for(t=J.J(a);t.m();)s=A.aF(s,J.M(t.gq()))
return A.fB(s)},
hc:function hc(){},
A:function A(){},
c_:function c_(a){this.a=a},
cx:function cx(){},
ay:function ay(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
cp:function cp(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
ds:function ds(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
cz:function cz(a){this.a=a},
ec:function ec(a){this.a=a},
bC:function bC(a){this.a=a},
df:function df(a){this.a=a},
dR:function dR(){},
cv:function cv(){},
hd:function hd(a){this.a=a},
ai:function ai(a,b,c){this.a=a
this.b=b
this.c=c},
e:function e(){},
aD:function aD(a,b,c){this.a=a
this.b=b
this.$ti=c},
cn:function cn(){},
q:function q(){},
e3:function e3(){this.b=this.a=0},
D:function D(a){this.a=a},
b6:function b6(a){this.$ti=a},
bt:function bt(a,b){this.a=a
this.$ti=b},
aT:function aT(a,b){this.a=a
this.$ti=b},
a9:function a9(){},
bB:function bB(a,b){this.a=a
this.$ti=b},
bS:function bS(a,b,c){this.a=a
this.b=b
this.c=c},
bx:function bx(a,b,c){this.a=a
this.b=b
this.$ti=c},
c4:function c4(){},
d8:function d8(){},
dt:function dt(){},
f2:function f2(){},
eQ(a){var t,s,r=a.length
if(r===0)return!1
if(0>=r)return A.a(a,0)
t=a[0]
if(t!=="{"&&t!=="[")return!1
try{B.l.cb(a,null)
return!0}catch(s){return!1}},
eP:function eP(a,b,c){var _=this
_.a=!0
_.c=a
_.d=b
_.e=c},
ar:function ar(a,b,c,d,e,f,g,h){var _=this
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
fa:function fa(){},
z:function z(){},
d5:function d5(a,b){this.c=a
this.a=b},
d7:function d7(a){this.a=a},
d9:function d9(a){this.a=a},
da:function da(a){this.a=a},
dd:function dd(a){this.a=a},
de:function de(a){this.a=a},
dj:function dj(a){this.a=a},
dl:function dl(a){this.a=a},
dm:function dm(a,b){this.c=a
this.a=b},
dr:function dr(a){this.a=a},
dx:function dx(a){this.a=a},
dE:function dE(a){this.a=a},
fb:function fb(a){this.a=a},
dG:function dG(a){this.a=a},
fg:function fg(a){this.a=a},
fh:function fh(a){this.a=a},
e0:function e0(a,b){this.c=a
this.a=b},
e1:function e1(a){this.a=a},
e4:function e4(a){this.a=a},
e6:function e6(a){this.a=a},
fP:function fP(a,b){this.a=a
this.b=b},
fO:function fO(a,b){this.a=a
this.b=b},
ae(a){var t,s
if(a==null)return null
t=J.x(a)
if(t.length===0)return null
s=A.I(t,"&","&amp;")
s=A.I(s,"<","&lt;")
s=A.I(s,">","&gt;")
s=A.I(s,'"',"&quot;")
return A.I(s,"'","&#39;")},
iU(a,b){var t,s=B.b.I(b)
if(s.length===0)return a
t=B.b.I(a)
if(t.length===0)return b
return(B.b.aN(t,";")?t:t+";")+" "+s},
e7:function e7(a){this.a=a},
fC:function fC(a,b){this.a=a
this.b=b},
fM:function fM(){},
fN:function fN(){},
fF:function fF(a,b,c){this.a=a
this.b=b
this.c=c},
fH:function fH(a,b){this.a=a
this.b=b},
fI:function fI(a,b){this.a=a
this.b=b},
fD:function fD(a,b){this.a=a
this.b=b},
fE:function fE(a,b,c){this.a=a
this.b=b
this.c=c},
fG:function fG(a,b,c){this.a=a
this.b=b
this.c=c},
fJ:function fJ(a,b,c){this.a=a
this.b=b
this.c=c},
fK:function fK(){},
fL:function fL(a){this.a=a},
ea:function ea(a){this.a=a},
eb:function eb(a){this.a=a},
ef:function ef(a,b){this.c=a
this.a=b},
am:function am(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mp(a){var t,s,r,q,p,o,n=u.N,m=A.u(n,n)
if(B.b.I(a).length===0)return m
for(n=A.lR(a),t=n.length,s=0;s<n.length;n.length===t||(0,A.l)(n),++s){r=n[s]
q=B.b.aO(r,":")
if(q<=0)continue
p=B.b.I(B.b.C(r,0,q)).toLowerCase()
o=B.b.I(B.b.G(r,q+1))
if(p.length===0||o.length===0)continue
m.n(0,p,o)}return m},
lR(a){var t,s,r,q,p,o,n,m=A.d([],u.s)
for(t=a.length,s=0,r=null,q=0,p="";q<t;++q){o=a[q]
if(r!=null){p+=o
if(o===r)if(q!==0){n=q-1
if(!(n>=0))return A.a(a,n)
n=a[n]!==""}else n=!0
else n=!1
if(n)r=null
continue}switch(o){case'"':case"'":p+=o
r=o
break
case"(":++s
p+=o
break
case")":if(s>0)--s
p+=o
break
case";":if(s>0)p+=o
else{B.a.j(m,p.charCodeAt(0)==0?p:p)
p=""}break
default:p+=o}}if(p.length!==0)B.a.j(m,p.charCodeAt(0)==0?p:p)
t=u.U
return A.ba(new A.bE(m,u.bB.a(new A.hu()),t),!0,t.i("e.E"))},
mw(a){var t
if(a.a===0)return""
t=A.d([],u.s)
a.S(0,new A.hF(t))
return B.a.ae(t,"; ")+";"},
hu:function hu(){},
hF:function hF(a){this.a=a},
k6(a){var t=A.U(a),s=t.i("al<1,a5>")
return new A.dh(A.ba(new A.al(a,t.i("a5(1)").a(new A.eR(null)),s),!0,s.i("L.E")))},
dh:function dh(a){this.a=a},
eR:function eR(a){this.a=a},
eS:function eS(){},
lP(a){return a},
hS(a,b,c,d){return new A.a5(a,b,c,d!=null?A.dF(d,u.N,u.z):null)},
ko(a,b){var t,s,r="insert",q="attributes",p="delete",o="retain",n=A.dF(a,u.N,u.z)
if(n.u(r)){t=n.h(0,r)
a=A.lP(t==null?u.K.a(t):t)
s=typeof a=="string"?a.length:1
return A.hS(r,s,a,u.Y.a(n.h(0,q)))}else if(n.u(p))return A.hS(p,A.jj(n.h(0,p)),"",null)
else if(n.u(o))return A.hS(o,A.jj(n.h(0,o)),"",u.Y.a(n.h(0,q)))
throw A.c(A.ip(a,"Invalid data for Delta operation.",null))},
a5:function a5(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
fq:function fq(){},
eZ:function eZ(a){this.a=a},
B(a,b){var t=a==null?null:a.k(b)
return t==null?null:A.Q(t,null)},
a0(a){var t
if(a==null)return null
t=a.k("w:val")
if(t==null)return!0
return!(t==="0"||t==="false"||t==="none")},
kH(a){if(a==null)return null
return new A.h2(A.B(a,"w:before"),A.B(a,"w:after"),A.B(a,"w:line"),a.k("w:lineRule"))},
iX(a){var t
if(a==null)return null
t=A.B(a,"w:left")
if(t==null)t=A.B(a,"w:start")
if(A.B(a,"w:right")==null)A.B(a,"w:end")
return new A.fX(t,A.B(a,"w:firstLine"),A.B(a,"w:hanging"))},
hZ(a){if(a==null)return null
a.k("w:val")
a.k("w:color")
return new A.h1(a.k("w:fill"))},
cC(a){var t,s
if(a==null)return null
t=a.k("w:val")
A.B(a,"w:sz")
s=a.k("w:color")
A.B(a,"w:space")
return new A.cB(t,s)},
hX(a){var t,s,r,q
if(a==null)return null
t=A.cC(a.l("w:top"))
s=a.l("w:left")
s=A.cC(s==null?a.l("w:start"):s)
r=A.cC(a.l("w:bottom"))
q=a.l("w:right")
return new A.fV(t,s,r,A.cC(q==null?a.l("w:end"):q),A.cC(a.l("w:insideH")),A.cC(a.l("w:insideV")))},
ei(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=null,c="w:val"
if(a==null)return d
t=a.l("w:rFonts")
s=a.l("w:rStyle")
s=s==null?d:s.k(c)
r=t==null
q=r?d:t.k("w:ascii")
p=r?d:t.k("w:hAnsi")
r=r?d:t.k("w:cs")
o=A.a0(a.l("w:b"))
n=A.a0(a.l("w:i"))
m=a.l("w:u")
m=m==null?d:m.k(c)
l=A.a0(a.l("w:strike"))
k=A.a0(a.l("w:caps"))
j=A.a0(a.l("w:smallCaps"))
i=A.B(a.l("w:sz"),c)
h=a.l("w:color")
h=h==null?d:h.k(c)
g=a.l("w:highlight")
g=g==null?d:g.k(c)
f=A.hZ(a.l("w:shd"))
e=a.l("w:vertAlign")
return new A.bg(s,q,p,r,o,n,m,l,k,j,i,h,g,f,e==null?d:e.k(c))},
hY(a){var t,s,r,q,p,o,n,m,l,k=null,j="w:val"
if(a==null)return k
t=a.l("w:numPr")
if(t!=null){s=A.B(t.l("w:numId"),j)
r=A.B(t.l("w:ilvl"),j)
q=new A.fY(s,r==null?0:r)}else q=k
p=a.l("w:tabs")
if(p!=null){s=A.d([],u.fH)
for(r=p.X("w:tab"),o=r.$ti,r=new A.t(r.a(),o.i("t<1>")),o=o.c;r.m();){n=r.b
if(n==null)n=o.a(n)
n.k(j)
m=n.k("w:pos")
if(m!=null)A.Q(m,k)
n.k("w:leader")
s.push(new A.ek())}l=s}else l=k
s=a.l("w:pStyle")
s=s==null?k:s.k(j)
r=a.l("w:jc")
r=r==null?k:r.k(j)
return new A.be(s,q,r,A.kH(a.l("w:spacing")),A.iX(a.l("w:ind")),l,A.hZ(a.l("w:shd")),A.hX(a.l("w:pBdr")),A.a0(a.l("w:keepNext")),A.a0(a.l("w:keepLines")),A.a0(a.l("w:pageBreakBefore")),A.a0(a.l("w:widowControl")),A.a0(a.l("w:contextualSpacing")),A.B(a.l("w:outlineLvl"),j),A.ei(a.l("w:rPr")))},
j3(a){if(a==null)return null
A.B(a,"w:w")
a.k("w:type")
return new A.h6()},
j2(a){var t,s,r
if(a==null)return null
t=a.l("w:tblStyle")
t=t==null?null:t.k("w:val")
A.j3(a.l("w:tblW"))
s=a.l("w:jc")
if(s!=null)s.k("w:val")
s=A.hX(a.l("w:tblBorders"))
A.B(a.l("w:tblInd"),"w:w")
r=a.l("w:tblLayout")
if(r!=null)r.k("w:type")
return new A.h4(t,s)},
kK(a){var t,s=a.l("w:trHeight"),r=A.B(s,"w:val")
if(s!=null)s.k("w:hRule")
t=A.a0(a.l("w:tblHeader"))
A.a0(a.l("w:cantSplit"))
return new A.h5(r,t===!0)},
kJ(a){var t,s,r,q,p,o="w:val",n=a.l("w:vMerge")
A.j3(a.l("w:tcW"))
t=A.B(a.l("w:gridSpan"),o)
if(n==null)s=null
else{s=n.k(o)
if(s==null)s="continue"}r=A.hX(a.l("w:tcBorders"))
q=A.hZ(a.l("w:shd"))
p=a.l("w:vAlign")
return new A.h3(t,s,r,q,p==null?null:p.k(o))},
kF(a){var t,s,r,q,p,o,n,m,l,k,j,i
if(a==null)return null
t=a.l("w:pgSz")
s=a.l("w:pgMar")
r=new A.h0(a)
q=A.B(t,"w:w")
p=A.B(t,"w:h")
if(t!=null)t.k("w:orient")
o=A.B(s,"w:top")
n=A.B(s,"w:right")
m=A.B(s,"w:bottom")
l=A.B(s,"w:left")
k=A.B(s,"w:header")
j=A.B(s,"w:footer")
A.B(s,"w:gutter")
A.a0(a.l("w:titlePg"))
i=r.$1("w:headerReference")
r=r.$1("w:footerReference")
a.aC()
return new A.h_(q,p,o,n,m,l,k,j,i,r)},
kG(a){if(a==null)return B.a5
A.a0(a.l("w:autoHyphenation"))
A.a0(a.l("w:evenAndOddHeaders"))
A.B(a.l("w:defaultTabStop"),"w:val")
return new A.ej()},
h2:function h2(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
fX:function fX(a,b,c){this.a=a
this.c=b
this.d=c},
ek:function ek(){},
h1:function h1(a){this.c=a},
cB:function cB(a,b){this.a=a
this.c=b},
fV:function fV(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
bg:function bg(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
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
fY:function fY(a,b){this.a=a
this.b=b},
be:function be(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
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
a_:function a_(){},
au:function au(a){this.a=a},
cG:function cG(){},
bG:function bG(a){this.a=a},
cE:function cE(){},
cF:function cF(a){this.b=a},
cD:function cD(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
bH:function bH(a){this.a=a},
bK:function bK(a){this.a=a},
bO:function bO(a){this.a=a},
bQ:function bQ(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.c=b
_.d=c
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h},
aW:function aW(){},
bf:function bf(a,b){this.a=a
this.b=b},
fZ:function fZ(){},
bJ:function bJ(a,b,c){this.a=a
this.b=b
this.c=c},
bP:function bP(a,b){this.a=a
this.b=b},
bN:function bN(a){this.a=a},
aV:function aV(){},
at:function at(a,b){this.a=a
this.b=b},
h6:function h6(){},
h4:function h4(a,b){this.a=a
this.d=b},
h5:function h5(a,b){this.a=a
this.c=b},
h3:function h3(a,b,c,d,e){var _=this
_.b=a
_.c=b
_.d=c
_.e=d
_.f=e},
el:function el(a,b){this.a=a
this.b=b},
em:function em(a,b){this.a=a
this.b=b},
bi:function bi(a,b,c){this.a=a
this.b=b
this.c=c},
bM:function bM(a){this.a=a},
bI:function bI(a,b){this.a=a
this.b=b},
h_:function h_(a,b,c,d,e,f,g,h,i,j){var _=this
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
h0:function h0(a){this.a=a},
fW:function fW(a,b){this.a=a
this.b=b},
eg:function eg(a,b){this.a=a
this.b=b},
ej:function ej(){},
iZ(a){var t,s,r,q,p,o=null,n="w:val",m=a.k("w:ilvl")
m=A.Q(m==null?"":m,o)
if(m==null)m=0
t=a.l("w:start")
t=t==null?o:t.k(n)
t=A.Q(t==null?"":t,o)
if(t==null)t=1
s=a.l("w:numFmt")
s=s==null?o:s.k(n)
if(s==null)s="decimal"
r=a.l("w:lvlText")
r=r==null?o:r.k(n)
if(r==null)r=""
q=a.l("w:lvlJc")
if(q!=null)q.k(n)
q=a.l("w:pPr")
q=A.iX(q==null?o:q.l("w:ind"))
A.ei(a.l("w:rPr"))
p=a.l("w:lvlRestart")
p=p==null?o:p.k(n)
A.Q(p==null?"":p,o)
return new A.eh(m,t,s,r,q)},
iY(a,b){var t=a==null?A.u(u.S,u.r):a
return new A.aX(t,b==null?A.u(u.S,u.n):b)},
j_(a,b){return A.iY(a,b)},
kE(a0){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=null,b="w:abstractNumId",a=A.cI()
A.cJ(a0,new A.av(a,A.d([],u.v)))
a=new A.a6(a.b,u.C).gak(0)
t=u.S
s=A.u(t,u.r)
for(r=a.X("w:abstractNum"),q=r.$ti,r=new A.t(r.a(),q.i("t<1>")),p=u.aV,q=q.c;r.m();){o=r.b
if(o==null)o=q.a(o)
n=o.k(b)
m=A.Q(n==null?"":n,c)
if(m==null)continue
l=A.u(t,p)
for(n=o.X("w:lvl"),k=n.$ti,n=new A.t(n.a(),k.i("t<1>")),k=k.c;n.m();){j=n.b
i=A.iZ(j==null?k.a(j):j)
l.n(0,i.a,i)}o=o.l("w:multiLevelType")
if(o!=null)o.k("w:val")
s.n(0,m,new A.bF(l))}h=A.u(t,u.n)
for(a=a.X("w:num"),r=a.$ti,a=new A.t(a.a(),r.i("t<1>")),r=r.c;a.m();){q=a.b
if(q==null)q=r.a(q)
o=q.k("w:numId")
g=A.Q(o==null?"":o,c)
o=q.l(b)
o=o==null?c:o.k("w:val")
f=A.Q(o==null?"":o,c)
if(g==null||f==null)continue
e=A.u(t,p)
for(q=q.X("w:lvlOverride"),o=q.$ti,q=new A.t(q.a(),o.i("t<1>")),o=o.c;q.m();){n=q.b
d=(n==null?o.a(n):n).l("w:lvl")
if(d!=null){i=A.iZ(d)
e.n(0,i.a,i)}}h.n(0,g,new A.bL(f,e))}return A.iY(s,h)},
m5(a,b){var t
switch(b){case"decimal":return""+a
case"decimalZero":t=""+a
return a<10?"0"+t:t
case"lowerLetter":return A.jq(a).toLowerCase()
case"upperLetter":return A.jq(a).toUpperCase()
case"lowerRoman":return A.js(a).toLowerCase()
case"upperRoman":return A.js(a)
case"bullet":return""
case"none":return""
default:return""+a}},
jq(a){var t,s
for(t=a,s="";t>0;){--t
s+=A.p(65+B.c.ct(t,26))
t=B.c.aJ(t,26)}return new A.ct(A.d((s.charCodeAt(0)==0?s:s).split(""),u.s),u.bJ).bl(0)},
js(a){var t,s,r,q,p,o=new A.D("")
for(t=a,s=0;s<13;++s){r=B.am[s]
q=r.a
p=r.b
for(;t>=q;){o.a+=p
t-=q}}r=o.a
return r.charCodeAt(0)==0?r:r},
kn(a){var t,s=a.length
if(s===0)return"\u2022"
if(0>=s)return A.a(a,0)
t=a.charCodeAt(0)
$label0$0:{if(61623===t||183===t){s="\u2022"
break $label0$0}if(61607===t||167===t){s="\u25a0"
break $label0$0}if(61551===t||111===t){s="\u25cb"
break $label0$0}if(61692===t){s="\u2713"
break $label0$0}if(61656===t){s="\u27a2"
break $label0$0}s=a
break $label0$0}return s},
eh:function eh(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.f=e},
bF:function bF(a){this.c=a},
bL:function bL(a,b){this.b=a
this.c=b},
aX:function aX(a,b){this.a=a
this.b=b},
fl:function fl(a,b){this.a=a
this.b=b},
fm:function fm(){},
fn:function fn(a){this.a=a},
iv(a,b,c,d,e){var t=B.b.a0(b,"/")?B.b.G(b,1):b,s=a.a.am(t)
return s==null?d.$0():c.$1(s)},
eT:function eT(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.x=e
_.y=f},
eU:function eU(a){this.a=a},
j0(a,b,c){return new A.aY(c,b,a==null?A.u(u.N,u.w):a)},
j1(a,b,c){return A.j0(a,b,c)},
kI(a){var t,s,r,q,p,o,n,m,l,k,j=null,i="w:val",h="w:default",g=A.cI()
A.cJ(a,new A.av(g,A.d([],u.v)))
g=new A.a6(g.b,u.C).gak(0)
t=g.l("w:docDefaults")
if(t!=null){s=t.l("w:rPrDefault")
r=A.ei(s==null?j:s.l("w:rPr"))
s=t.l("w:pPrDefault")
q=A.hY(s==null?j:s.l("w:pPr"))}else{q=j
r=q}p=A.u(u.N,u.w)
for(g=g.X("w:style"),s=g.$ti,g=new A.t(g.a(),s.i("t<1>")),s=s.c;g.m();){o=g.b
if(o==null)o=s.a(o)
n=o.k("w:styleId")
if(n==null)continue
m=o.k("w:type")
if(m==null)m="paragraph"
l=o.l("w:name")
if(l!=null)l.k(i)
l=o.l("w:basedOn")
l=l==null?j:l.k(i)
k=o.l("w:link")
if(k!=null)k.k(i)
k=o.k(h)==="1"||o.k(h)==="true"
p.n(0,n,new A.bh(n,m,l,k,A.hY(o.l("w:pPr")),A.ei(o.l("w:rPr")),A.j2(o.l("w:tblPr"))))}return A.j0(p,q,r)},
bh:function bh(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.d=c
_.f=d
_.r=e
_.w=f
_.x=g},
aY:function aY(a,b,c){this.a=a
this.b=b
this.c=c},
k5(a){var t,s,r,q,p,o,n,m,l,k,j="ContentType",i=A.cI()
A.cJ(a,new A.av(i,A.d([],u.v)))
t=u.N
s=A.u(t,t)
t=A.u(t,t)
for(i=B.a.gv(new A.a6(i.b,u.C).gak(0).d),r=new A.a7(i,u.y),q=u.X;r.m();){p=q.a(i.gq())
o=p.b
n=B.b.aO(o,":")
switch(n<0?o:B.b.G(o,n+1)){case"Default":m=p.k("Extension")
l=p.k(j)
if(m!=null&&l!=null)s.n(0,m.toLowerCase(),l)
break
case"Override":k=p.k("PartName")
l=p.k(j)
if(k!=null&&l!=null)t.n(0,k,l)
break}}return new A.eO(s,t)},
eO:function eO(a,b){this.a=a
this.b=b},
fo:function fo(a,b,c){this.a=a
this.b=b
this.c=c},
fp:function fp(){},
iO(){var t=A.d([],u.gb)
return new A.dZ(t)},
ky(a){var t,s,r,q,p,o,n,m,l,k,j=A.cI()
A.cJ(a,new A.av(j,A.d([],u.v)))
t=A.iO()
for(j=B.a.gv(new A.a6(j.b,u.C).gak(0).d),s=new A.a7(j,u.y),r=t.a,q=u.X;s.m();){p=q.a(j.gq())
o=p.b
n=B.b.aO(o,":")
if((n<0?o:B.b.G(o,n+1))!=="Relationship")continue
m=p.k("Id")
l=p.k("Type")
k=p.k("Target")
if(m==null||l==null||k==null)continue
B.a.j(r,new A.dY(m,l,k,p.k("TargetMode")==="External"))}return t},
dY:function dY(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
dZ:function dZ(a){this.a=a},
cI(){var t=A.d([],u.m)
return new A.eo(t)},
aH:function aH(){},
cK:function cK(a){this.b=a},
cH:function cH(a){this.b=a},
en:function en(a){this.b=a},
ep:function ep(a,b){this.b=a
this.c=b},
aZ:function aZ(a,b){this.a=a
this.b=b},
a8:function a8(a,b,c){this.b=a
this.c=b
this.d=c},
eo:function eo(a){this.b=a},
av:function av(a,b){this.a=a
this.b=b},
hb:function hb(){},
E(a,b,c){return new A.h7(A.kP(a,b,c),null,null)},
kP(a,b,c){var t=b.length,s=1,r=0,q=0
while(!0){if(!(q<c&&q<t))break
if(!(q<t))return A.a(b,q)
if(b.charCodeAt(q)===10){++s
r=q+1}++q}return a+" (linha "+s+", coluna "+(c-r+1)+")"},
cJ(a,b){var t,s=a.length
if(s!==0){if(0>=s)return A.a(a,0)
s=a.charCodeAt(0)===65279}else s=!1
t=s?1:0
new A.er(t===0?a:B.b.G(a,t),b).bZ()},
kQ(a){var t,s,r
for(t=a.length,s=0;s<t;++s){r=a.charCodeAt(s)
if(r===32||r===9||r===10||r===13)return s}return-1},
kR(a){var t,s,r,q,p,o,n=u.N,m=A.u(n,n)
for(n=A.cs("([A-Za-z]+)\\s*=\\s*(\"([^\"]*)\"|'([^']*)')",!0).bd(0,a),n=new A.cL(n.a,n.b,n.c),t=u.q;n.m();){s=n.d
r=(s==null?t.a(s):s).b
q=r.length
if(1>=q)return A.a(r,1)
p=r[1]
p.toString
if(3>=q)return A.a(r,3)
o=r[3]
if(o==null){if(4>=q)return A.a(r,4)
r=r[4]}else r=o
m.n(0,p,r==null?"":r)}return m},
b_:function b_(a,b){this.a=a
this.b=b},
eq:function eq(){},
h7:function h7(a,b,c){this.a=a
this.b=b
this.c=c},
er:function er(a,b){this.a=a
this.b=b
this.c=0},
dn(a){var t=new A.f_()
t.cH(a)
return t},
f_:function f_(){this.a=$
this.b=0
this.c=2147483647},
f1:function f1(a,b,c,d){var _=this
_.a=a
_.b=null
_.c=b
_.e=_.d=0
_.r=c
_.w=d},
eL:function eL(a){this.b=a},
hM(a,b,c,d){var t,s,r=new A.du(b)
if(d==null)d=0
if(c==null)c=a.length-d
t=a.length
if(d+c>t)c=t-d
s=u.gc.b(a)?a:new Uint8Array(A.i6(a))
t=J.bZ(B.e.gai(s),s.byteOffset+d,c)
r.b=t
r.d=t.length
return r},
du:function du(a){var _=this
_.b=null
_.c=0
_.d=$
_.a=a},
dv:function dv(){},
dS:function dS(a){this.b=0
this.c=a},
dT:function dT(){},
kS(b2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8=A.d([],u.bV),a9=A.u(u.N,u.S),b0=new A.h8(a8,a9,new Uint8Array(0)),b1=b2.length
if(b1===0)return b0
t=A.lq(b2)
if(t<0)throw A.c(B.a9)
s=A.jr(b2,t+10)
r=A.aN(b2,t+12)
q=A.aN(b2,t+16)
p=t+22
b0.c=new Uint8Array(A.i6(A.cy(b2,p,p+A.jr(b2,t+20))))
o=q+r
n=q
m=0
while(!0){if(!(m<s&&n<o))break
if(A.aN(b2,n)!==33639248)throw A.c(B.aa)
p=n+8
if(!(p>=0&&p<b1))return A.a(b2,p)
l=b2[p];++p
if(!(p<b1))return A.a(b2,p)
k=l|b2[p]<<8
p=n+10
if(!(p>=0&&p<b1))return A.a(b2,p)
l=b2[p];++p
if(!(p<b1))return A.a(b2,p)
p=b2[p]
A.aN(b2,n+16)
j=A.aN(b2,n+20)
i=A.aN(b2,n+24)
h=n+28
if(!(h>=0&&h<b1))return A.a(b2,h)
g=b2[h];++h
if(!(h<b1))return A.a(b2,h)
h=b2[h]
f=n+30
if(!(f>=0&&f<b1))return A.a(b2,f)
e=b2[f];++f
if(!(f<b1))return A.a(b2,f)
f=b2[f]
d=n+32
if(!(d>=0&&d<b1))return A.a(b2,d)
c=b2[d];++d
if(!(d<b1))return A.a(b2,d)
d=b2[d]
b=A.aN(b2,n+42)
a=n+46
a0=a+((g|h<<8)>>>0)
a1=a0+((e|f<<8)>>>0)+((c|d<<8)>>>0)
a2=A.ll(b2,a,a0,(k&2048)!==0)
if(j===4294967295||i===4294967295||b===4294967295)throw A.c(A.bD("ZIP64 archives are not supported."))
if(A.aN(b2,b)!==67324752)throw A.c(B.ab)
h=b+26
if(!(h<b1))return A.a(b2,h)
g=b2[h];++h
if(!(h<b1))return A.a(b2,h)
h=b2[h]
f=b+28
if(!(f<b1))return A.a(b2,f)
e=b2[f];++f
if(!(f<b1))return A.a(b2,f)
a3=b+30+((g|h<<8)>>>0)+((e|b2[f]<<8)>>>0)
a4=a3+j
if((k&8)!==0)a5=a4+4<=b1&&A.aN(b2,a4)===134695760?a4+16:a4+12
else a5=a4
a6=new A.es()
A.cy(b2,b,a5)
A.cy(b2,n,a1)
a6.d=A.cy(b2,a3,a4)
a6.e=(l|p<<8)>>>0
a6.r=i
a7=a9.h(0,a2)
if(a7!=null)B.a.n(a8,a7,a6)
else{a9.n(0,a2,a8.length)
B.a.j(a8,a6)}++m
n=a1}return b0},
lq(a){var t,s=a.length,r=s>65558?s-65558:0
for(t=s-22;t>=r;--t)if(A.aN(a,t)===101010256)return t
return-1},
ll(a,b,c,d){var t,s,r=A.cy(a,b,c)
if(!d)return B.G.av(r)
try{t=B.H.av(r)
return t}catch(s){t=B.G.av(r)
return t}},
jr(a,b){var t,s,r=a.length
if(!(b>=0&&b<r))return A.a(a,b)
t=a[b]
s=b+1
if(!(s<r))return A.a(a,s)
return(t|a[s]<<8)>>>0},
aN(a,b){var t,s,r,q,p=a.length
if(!(b>=0&&b<p))return A.a(a,b)
t=a[b]
s=b+1
if(!(s<p))return A.a(a,s)
s=a[s]
r=b+2
if(!(r<p))return A.a(a,r)
r=a[r]
q=b+3
if(!(q<p))return A.a(a,q)
return(t|s<<8|r<<16|a[q]<<24)>>>0},
es:function es(){var _=this
_.d=null
_.e=8
_.r=0
_.w=null},
h8:function h8(a,b,c){this.a=a
this.b=b
this.c=c},
a2:function a2(a){this.b=a},
bA:function bA(a){this.b=a},
e8:function e8(a){this.b=a},
bc:function bc(a){this.b=a},
aU:function aU(a){this.b=a},
Z(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t){return new A.b7(o,r,f,l,t,g,a,e,h,i,p,m,k,d,n,s,q,j)},
b7:function b7(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r){var _=this
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
_.dP=r},
dp:function dp(a){this.b=a},
dq:function dq(a,b,c,d){var _=this
_.x=a
_.y=b
_.z=c
_.dx=d},
b8:function b8(a,b){this.d=a
this.e=b},
hL(a,b){var t,s,r,q,p,o,n,m,l,k
if(a.e==null)a.e="wp:"+b
t=a.y1
if(t!=null)for(s=t.length,r=0;r<t.length;t.length===s||(0,A.l)(t),++r)A.hL(t[r],b)
q=a.k1
if(q!=null)for(s=q.length,r=0;r<q.length;q.length===s||(0,A.l)(q),++r)for(p=q[r].e,o=p.length,n=0;n<p.length;p.length===o||(0,A.l)(p),++n)for(m=p[n].z,l=m.length,k=0;k<m.length;m.length===l||(0,A.l)(m),++k)A.hL(m[k],b)},
hK(a){var t
$label0$0:{if("center"===a){t=B.x
break $label0$0}if("right"===a||"end"===a){t=B.y
break $label0$0}if("both"===a){t=B.z
break $label0$0}if("distribute"===a){t=B.A
break $label0$0}t=null
break $label0$0}return t},
c6(a,b){},
hJ(a){if(a==null||a==="auto")return null
return"#"+A.i(a)},
iw(a){var t=a==null?null:a.c
if(t==null||t==="auto")return null
return"#"+A.i(t)},
k8(a){var t
$label0$0:{if(0===a){t=B.P
break $label0$0}if(1===a){t=B.R
break $label0$0}if(2===a){t=B.T
break $label0$0}if(3===a){t=B.Q
break $label0$0}if(4===a){t=B.O
break $label0$0}t=B.S
break $label0$0}return t},
k7(a){var t,s,r=a.b
if(r==null)return"\u2022"
t=A.Q(r,16)
if(t==null)return"\u2022"
$label0$0:{if(61623===t){s="\u2022"
break $label0$0}if(61607===t){s="\u25a0"
break $label0$0}if(61551===t){s="\u25cb"
break $label0$0}if(61692===t){s="\u2713"
break $label0$0}if(61656===t){s="\u27a2"
break $label0$0}s=t>=61440&&t<=61695?"\u2022":A.p(t)
break $label0$0}return s},
c5:function c5(){},
eV:function eV(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
eX:function eX(a,b){this.a=a
this.b=b},
eY:function eY(){},
eW:function eW(){},
cO:function cO(a){this.b=a},
hk:function hk(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
hl:function hl(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
kv(a){var t,s,r={},q=A.d([],u.d)
r.a=0
new A.fx(r,q,new A.fv(q),new A.fw(q)).$2(a,B.o)
t=q.length===0?null:B.a.gR(q)
s=t==null?null:t.h(0,"insert")
if(typeof s!="string"||!B.b.aN(s,"\n"))B.a.j(q,A.F(["insert","\n"],u.N,u.z))
return A.F(["ops",q],u.N,u.z)},
hT(a,b){var t,s,r,q,p,o="table-cell-block",n="table-th-block",m="header",l="list",k="table-cell",j="table-th",i="align",h=b.h(0,o)
if(h==null)h=b.h(0,n)
t=h==null
s=!t
r=u.N
q=u.z
p=A.u(r,q)
if(b.u(m)&&t)p.n(0,m,b.h(0,m))
if(b.u(l)&&t)p.n(0,l,b.h(0,l))
if(b.u(m)&&s)p.n(0,"table-header",A.F(["cellId",h,"value",b.h(0,m)],r,q))
else if(b.u(l)&&s)p.n(0,"table-list",A.F(["cellId",h,"value",b.h(0,l)],r,q))
else if(b.u(o))p.n(0,o,b.h(0,o))
if(b.u(n)&&!b.u(m)&&!b.u(l))p.n(0,n,b.h(0,n))
if(b.u(k))p.n(0,k,b.h(0,k))
if(b.u(j))p.n(0,j,b.h(0,j))
if(a.ay===B.x)p.n(0,i,"center")
if(a.ay===B.y)p.n(0,i,"right")
t=a.ay
if(t===B.z||t===B.A)p.n(0,i,"justify")
return p},
ku(a){switch(a){case B.P:return 1
case B.R:return 2
case B.T:return 3
case B.Q:return 4
case B.O:return 5
case B.S:return 6}},
kt(a){var t,s,r,q,p=a.a,o=a.$ti.i("4?"),n=o.a(p.h(0,"table-cell-block"))
if(n==null)n=o.a(p.h(0,"table-th-block"))
if(typeof n=="string"&&n.length!==0)return n
t=u.f
if(t.b(n))return A.d3(n.h(0,"cellId"))
s=o.a(p.h(0,"table-header"))
if(s==null)s=o.a(p.h(0,"table-list"))
if(t.b(s))return A.d3(s.h(0,"cellId"))
r=o.a(p.h(0,"table-cell"))
if(r==null)r=o.a(p.h(0,"table-th"))
if(t.b(r)){q=r.h(0,"data-row")
if(typeof q=="string")return"cell-"+q}return null},
fw:function fw(a){this.a=a},
fv:function fv(a){this.a=a},
fx:function fx(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
fy:function fy(){},
ml(){var t,s=new A.hC(),r=self,q=u.o,p=q.a(r.self)
if(typeof s=="function")A.aw(A.hG("Attempting to rewrap a JS function."))
t=function(a,b){return function(c){return a(b,c,arguments.length)}}(A.lk,s)
t[$.ik()]=s
p.onmessage=t
A.iA(q.a(r.self),"postMessage","ready",u.O)},
hC:function hC(){},
cy(a,b,c){var t=a.BYTES_PER_ELEMENT
c=A.cq(b,c,B.c.cG(a.byteLength,t))
return J.bZ(B.e.gai(a),a.byteOffset+b*t,(c-b)*t)},
mz(a){A.ij(new A.ch("Field '"+a+"' has been assigned during initialization."),new Error())},
bY(){A.ij(new A.ch("Field '' has not been initialized."),new Error())},
ki(a,b,c,d,e,f){var t=a[b](c)
return t},
iA(a,b,c,d){return d.a(A.ki(a,b,c,null,null,null))},
lk(a,b,c){u.Z.a(a)
if(A.af(c)>=1)return a.$1(b)
return a.$0()},
lH(a){var t=a.b
return(t==null||t===B.p)&&a.c==="\n"},
lG(a){var t=a.b
return t===B.m||t===B.q||t===B.n},
lN(a){var t,s,r,q,p,o,n,m=null,l=A.d([],u.l)
for(t=a.length,s=m,r=0;r<a.length;a.length===t||(0,A.l)(a),++r,s=q){q=a[r]
p=q.b
if((p==null||p===B.p)&&q.c==="\n"){p=s!=null
if(p){o=s.b
o=o===B.m||o===B.q||o===B.n}else o=!1
if(o)continue
if(p){p=s.b
o=!((p==null||p===B.p)&&s.c==="\n")
p=o}else p=!1
q.ay=p?s.ay:m}B.a.j(l,q)}n=l.length===0?m:B.a.gR(l)
t=!1
if(n!=null)if(!A.lH(n))if(!A.lG(n)){t=n.ay
t=t===B.x||t===B.y||t===B.z||t===B.A}if(t)B.a.j(l,A.Z(m,m,m,m,m,m,m,m,m,m,n.ay,m,m,m,m,m,m,"\n",m,m))
return l},
kO(a){var t,s,r,q
if(!A.kM(a))return a
for(t=a.length,s=0,r="";s<t;++s){q=a.charCodeAt(s)
switch(q){case 38:r+="&amp;"
break
case 60:r+="&lt;"
break
case 62:r+="&gt;"
break
case 13:r+="&#xD;"
break
default:r+=A.p(q)}}return r.charCodeAt(0)==0?r:r},
kN(a){var t,s,r,q
if(!A.kL(a))return a
for(t=a.length,s=0,r="";s<t;++s){q=a.charCodeAt(s)
switch(q){case 38:r+="&amp;"
break
case 60:r+="&lt;"
break
case 62:r+="&gt;"
break
case 34:r+="&quot;"
break
case 9:r+="&#x9;"
break
case 10:r+="&#xA;"
break
case 13:r+="&#xD;"
break
default:r+=A.p(q)}}return r.charCodeAt(0)==0?r:r},
kM(a){var t,s,r
for(t=a.length,s=0;s<t;++s){r=a.charCodeAt(s)
if(r===38||r===60||r===62||r===13)return!0}return!1},
kL(a){var t,s,r
for(t=a.length,s=0;s<t;++s){r=a.charCodeAt(s)
if(r===38||r===60||r===62||r===34||r===9||r===10||r===13)return!0}return!1}},B={}
var w=[A,J,B]
var $={}
A.hO.prototype={}
J.dw.prototype={
T(a,b){return a===b},
gL(a){return A.dV(a)},
t(a){return"Instance of '"+A.ft(a)+"'"},
gM(a){return A.bo(A.i7(this))}}
J.dy.prototype={
t(a){return String(a)},
gL(a){return a?519018:218159},
gM(a){return A.bo(u.B)},
$iw:1,
$iC:1}
J.cd.prototype={
T(a,b){return null==b},
t(a){return"null"},
gL(a){return 0},
$iw:1}
J.cf.prototype={$iK:1}
J.aS.prototype={
gL(a){return 0},
t(a){return String(a)}}
J.dU.prototype={}
J.bd.prototype={}
J.aB.prototype={
t(a){var t=a[$.ik()]
if(t==null)return this.cA(a)
return"JavaScript function for "+J.x(t)},
$iaQ:1}
J.bv.prototype={
gL(a){return 0},
t(a){return String(a)}}
J.bw.prototype={
gL(a){return 0},
t(a){return String(a)}}
J.m.prototype={
j(a,b){A.U(a).c.a(b)
a.$flags&1&&A.T(a,29)
a.push(b)},
dY(a,b,c){var t
A.U(a).c.a(c)
a.$flags&1&&A.T(a,"insert",2)
t=a.length
if(b>t)throw A.c(A.iN(b,null))
a.splice(b,0,c)},
aa(a,b){var t
A.U(a).i("e<1>").a(b)
a.$flags&1&&A.T(a,"addAll",2)
if(Array.isArray(b)){this.cK(a,b)
return}for(t=J.J(b);t.m();)a.push(t.gq())},
cK(a,b){var t,s
u.b.a(b)
t=b.length
if(t===0)return
if(a===b)throw A.c(A.Y(a))
for(s=0;s<t;++s)a.push(b[s])},
aj(a){a.$flags&1&&A.T(a,"clear","clear")
a.length=0},
ae(a,b){var t,s=A.ff(a.length,"",!1,u.N)
for(t=0;t<a.length;++t)this.n(s,t,A.i(a[t]))
return s.join(b)},
a_(a,b){return A.fA(a,b,null,A.U(a).c)},
dT(a,b,c,d){var t,s,r
d.a(b)
A.U(a).H(d).i("1(1,2)").a(c)
t=a.length
for(s=b,r=0;r<t;++r){s=c.$2(s,a[r])
if(a.length!==t)throw A.c(A.Y(a))}return s},
dR(a,b,c){var t,s,r,q=A.U(a)
q.i("C(1)").a(b)
q.i("1()?").a(c)
t=a.length
for(s=0;s<t;++s){r=a[s]
if(A.O(b.$1(r)))return r
if(a.length!==t)throw A.c(A.Y(a))}return c.$0()},
K(a,b){if(!(b>=0&&b<a.length))return A.a(a,b)
return a[b]},
cw(a,b,c){var t=a.length
if(b>t)throw A.c(A.N(b,0,t,"start",null))
if(c<b||c>t)throw A.c(A.N(c,b,t,"end",null))
if(b===c)return A.d([],A.U(a))
return A.d(a.slice(b,c),A.U(a))},
gR(a){var t=a.length
if(t>0)return a[t-1]
throw A.c(A.f3())},
cv(a,b){var t,s,r,q,p,o=A.U(a)
o.i("b(1,1)?").a(b)
a.$flags&2&&A.T(a,"sort")
t=a.length
if(t<2)return
if(b==null)b=J.ly()
if(t===2){s=a[0]
r=a[1]
o=b.$2(s,r)
if(typeof o!=="number")return o.ef()
if(o>0){a[0]=r
a[1]=s}return}q=0
if(o.c.b(null))for(p=0;p<a.length;++p)if(a[p]===void 0){a[p]=null;++q}a.sort(A.lX(b,2))
if(q>0)this.ds(a,q)},
cu(a){return this.cv(a,null)},
ds(a,b){var t,s=a.length
for(;t=s-1,s>0;s=t)if(a[t]===null){a[t]=void 0;--b
if(b===0)break}},
A(a,b){var t
for(t=0;t<a.length;++t)if(J.H(a[t],b))return!0
return!1},
gB(a){return a.length===0},
gD(a){return a.length!==0},
t(a){return A.hN(a,"[","]")},
gv(a){return new J.b3(a,a.length,A.U(a).i("b3<1>"))},
gL(a){return A.dV(a)},
gp(a){return a.length},
h(a,b){if(!(b>=0&&b<a.length))throw A.c(A.hv(a,b))
return a[b]},
n(a,b,c){A.U(a).c.a(c)
a.$flags&2&&A.T(a)
if(!(b>=0&&b<a.length))throw A.c(A.hv(a,b))
a[b]=c},
$ih:1,
$ie:1,
$ik:1}
J.f4.prototype={}
J.b3.prototype={
gq(){var t=this.d
return t==null?this.$ti.c.a(t):t},
m(){var t,s=this,r=s.a,q=r.length
if(s.b!==q){r=A.l(r)
throw A.c(r)}t=s.c
if(t>=q){s.sbL(null)
return!1}s.sbL(r[t]);++s.c
return!0},
sbL(a){this.d=this.$ti.i("1?").a(a)},
$iv:1}
J.bu.prototype={
ar(a,b){var t
A.jk(b)
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){t=this.gbk(b)
if(this.gbk(a)===t)return 0
if(this.gbk(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gbk(a){return a===0?1/a<0:a<0},
dS(a){var t,s
if(a>=0){if(a<=2147483647)return a|0}else if(a>=-2147483648){t=a|0
return a===t?t:t-1}s=Math.floor(a)
if(isFinite(s))return s
throw A.c(A.bD(""+a+".floor()"))},
ag(a){if(a>0){if(a!==1/0)return Math.round(a)}else if(a>-1/0)return 0-Math.round(0-a)
throw A.c(A.bD(""+a+".round()"))},
e8(a){if(a<0)return-Math.round(-a)
else return Math.round(a)},
ca(a,b,c){if(B.c.ar(b,c)>0)throw A.c(A.jv(b))
if(this.ar(a,b)<0)return b
if(this.ar(a,c)>0)return c
return a},
e9(a,b){var t,s,r,q,p
if(b<2||b>36)throw A.c(A.N(b,2,36,"radix",null))
t=a.toString(b)
s=t.length
r=s-1
if(!(r>=0))return A.a(t,r)
if(t.charCodeAt(r)!==41)return t
q=/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(t)
if(q==null)A.aw(A.bD("Unexpected toString result: "+t))
s=q.length
if(1>=s)return A.a(q,1)
t=q[1]
if(3>=s)return A.a(q,3)
p=+q[3]
s=q[2]
if(s!=null){t+=s
p-=s.length}return t+B.b.bt("0",p)},
t(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gL(a){var t,s,r,q,p=a|0
if(a===p)return p&536870911
t=Math.abs(a)
s=Math.log(t)/0.6931471805599453|0
r=Math.pow(2,s)
q=t<1?t/r:r/t
return((q*9007199254740992|0)+(q*3542243181176521|0))*599197+s*1259&536870911},
ct(a,b){var t=a%b
if(t===0)return 0
if(t>0)return t
return t+b},
cG(a,b){if((a|0)===a)if(b>=1||b<-1)return a/b|0
return this.c5(a,b)},
aJ(a,b){return(a|0)===a?a/b|0:this.c5(a,b)},
c5(a,b){var t=a/b
if(t>=-2147483648&&t<=2147483647)return t|0
if(t>0){if(t!==1/0)return Math.floor(t)}else if(t>-1/0)return Math.ceil(t)
throw A.c(A.bD("Result of truncating division is "+A.i(t)+": "+A.i(a)+" ~/ "+b))},
aE(a,b){if(b<0)throw A.c(A.jv(b))
return b>31?0:a<<b>>>0},
dv(a,b){return b>31?0:a<<b>>>0},
bc(a,b){var t
if(a>0)t=this.bb(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
bb(a,b){return b>31?0:a>>>b},
gM(a){return A.bo(u.H)},
$iaz:1,
$ir:1,
$iab:1}
J.cc.prototype={
gM(a){return A.bo(u.S)},
$iw:1,
$ib:1}
J.dz.prototype={
gM(a){return A.bo(u.i)},
$iw:1}
J.aR.prototype={
be(a,b,c){var t=b.length
if(c>t)throw A.c(A.N(c,0,t,null,null))
return new A.eC(b,a,c)},
bd(a,b){return this.be(a,b,0)},
aN(a,b){var t=b.length,s=a.length
if(t>s)return!1
return b===this.G(a,s-t)},
aF(a,b,c){var t
if(c<0||c>a.length)throw A.c(A.N(c,0,a.length,null,null))
t=c+b.length
if(t>a.length)return!1
return b===a.substring(c,t)},
a0(a,b){return this.aF(a,b,0)},
C(a,b,c){return a.substring(b,A.cq(b,c,a.length))},
G(a,b){return this.C(a,b,null)},
I(a){var t,s,r,q=a.trim(),p=q.length
if(p===0)return q
if(0>=p)return A.a(q,0)
if(q.charCodeAt(0)===133){t=J.kj(q,1)
if(t===p)return""}else t=0
s=p-1
if(!(s>=0))return A.a(q,s)
r=q.charCodeAt(s)===133?J.kk(q,s):p
if(t===0&&r===p)return q
return q.substring(t,r)},
bt(a,b){var t,s
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.c(B.a4)
for(t=a,s="";!0;){if((b&1)===1)s=t+s
b=b>>>1
if(b===0)break
t+=t}return s},
ab(a,b,c){var t
if(c<0||c>a.length)throw A.c(A.N(c,0,a.length,null,null))
t=a.indexOf(b,c)
return t},
aO(a,b){return this.ab(a,b,0)},
bm(a,b){var t=a.length,s=b.length
if(t+s>t)t-=s
return a.lastIndexOf(b,t)},
A(a,b){return A.mq(a,b,0)},
ar(a,b){var t
A.S(b)
if(a===b)t=0
else t=a<b?-1:1
return t},
t(a){return a},
gL(a){var t,s,r
for(t=a.length,s=0,r=0;r<t;++r){s=s+a.charCodeAt(r)&536870911
s=s+((s&524287)<<10)&536870911
s^=s>>6}s=s+((s&67108863)<<3)&536870911
s^=s>>11
return s+((s&16383)<<15)&536870911},
gM(a){return A.bo(u.N)},
gp(a){return a.length},
$iw:1,
$iaz:1,
$ifr:1,
$if:1}
A.bR.prototype={
gv(a){return new A.c1(J.J(this.ga9()),A.j(this).i("c1<1,2>"))},
gp(a){return J.ax(this.ga9())},
gB(a){return J.im(this.ga9())},
gD(a){return J.jX(this.ga9())},
a_(a,b){var t=A.j(this)
return A.hH(J.io(this.ga9(),b),t.c,t.y[1])},
K(a,b){return A.j(this).y[1].a(J.eI(this.ga9(),b))},
A(a,b){return J.jW(this.ga9(),b)},
t(a){return J.x(this.ga9())}}
A.c1.prototype={
m(){return this.a.m()},
gq(){return this.$ti.y[1].a(this.a.gq())},
$iv:1}
A.b4.prototype={
ga9(){return this.a}}
A.cN.prototype={$ih:1}
A.b5.prototype={
bg(a,b,c){return new A.b5(this.a,this.$ti.i("@<1,2>").H(b).H(c).i("b5<1,2,3,4>"))},
u(a){return this.a.u(a)},
h(a,b){return this.$ti.i("4?").a(this.a.h(0,b))},
n(a,b,c){var t=this.$ti
t.y[2].a(b)
t.y[3].a(c)
this.a.n(0,t.c.a(b),t.y[1].a(c))},
a3(a,b){return this.$ti.i("4?").a(this.a.a3(0,b))},
S(a,b){this.a.S(0,new A.eM(this,this.$ti.i("~(3,4)").a(b)))},
gJ(){var t=this.$ti
return A.hH(this.a.gJ(),t.c,t.y[2])},
gW(){var t=this.$ti
return A.hH(this.a.gW(),t.y[1],t.y[3])},
gp(a){var t=this.a
return t.gp(t)},
gB(a){var t=this.a
return t.gB(t)},
gD(a){var t=this.a
return t.gD(t)},
aS(a,b){this.a.aS(0,new A.eN(this,this.$ti.i("C(3,4)").a(b)))}}
A.eM.prototype={
$2(a,b){var t=this.a.$ti
t.c.a(a)
t.y[1].a(b)
this.b.$2(t.y[2].a(a),t.y[3].a(b))},
$S(){return this.a.$ti.i("~(1,2)")}}
A.eN.prototype={
$2(a,b){var t=this.a.$ti
t.c.a(a)
t.y[1].a(b)
return this.b.$2(t.y[2].a(a),t.y[3].a(b))},
$S(){return this.a.$ti.i("C(1,2)")}}
A.ch.prototype={
t(a){return"LateInitializationError: "+this.a}}
A.fz.prototype={}
A.h.prototype={}
A.L.prototype={
gv(a){var t=this
return new A.b9(t,t.gp(t),A.j(t).i("b9<L.E>"))},
gB(a){return this.gp(this)===0},
A(a,b){var t,s=this,r=s.gp(s)
for(t=0;t<r;++t){if(J.H(s.K(0,t),b))return!0
if(r!==s.gp(s))throw A.c(A.Y(s))}return!1},
bl(a){var t,s,r=this,q=r.gp(r)
for(t=0,s="";t<q;++t){s+=A.i(r.K(0,t))
if(q!==r.gp(r))throw A.c(A.Y(r))}return s.charCodeAt(0)==0?s:s},
bn(a,b,c){var t=A.j(this)
return new A.al(this,t.H(c).i("1(L.E)").a(b),t.i("@<L.E>").H(c).i("al<1,2>"))},
a_(a,b){return A.fA(this,b,null,A.j(this).i("L.E"))}}
A.cw.prototype={
gcX(){var t=J.ax(this.a),s=this.c
if(s==null||s>t)return t
return s},
gdz(){var t=J.ax(this.a),s=this.b
if(s>t)return t
return s},
gp(a){var t,s=J.ax(this.a),r=this.b
if(r>=s)return 0
t=this.c
if(t==null||t>=s)return s-r
if(typeof t!=="number")return t.by()
return t-r},
K(a,b){var t=this,s=t.gdz()+b
if(b<0||s>=t.gcX())throw A.c(A.f0(b,t.gp(0),t,"index"))
return J.eI(t.a,s)},
a_(a,b){var t,s,r=this
A.an(b,"count")
t=r.b+b
s=r.c
if(s!=null&&t>=s)return new A.c8(r.$ti.i("c8<1>"))
return A.fA(r.a,t,s,r.$ti.c)},
cl(a,b){var t,s,r,q=this,p=q.b,o=q.a,n=J.aa(o),m=n.gp(o),l=q.c
if(l!=null&&l<m)m=l
t=m-p
if(t<=0){o=J.iz(0,q.$ti.c)
return o}s=A.ff(t,n.K(o,p),!1,q.$ti.c)
for(r=1;r<t;++r){B.a.n(s,r,n.K(o,p+r))
if(n.gp(o)<m)throw A.c(A.Y(q))}return s}}
A.b9.prototype={
gq(){var t=this.d
return t==null?this.$ti.c.a(t):t},
m(){var t,s=this,r=s.a,q=J.aa(r),p=q.gp(r)
if(s.b!==p)throw A.c(A.Y(r))
t=s.c
if(t>=p){s.sao(null)
return!1}s.sao(q.K(r,t));++s.c
return!0},
sao(a){this.d=this.$ti.i("1?").a(a)},
$iv:1}
A.bb.prototype={
gv(a){return new A.ak(J.J(this.a),this.b,A.j(this).i("ak<1,2>"))},
gp(a){return J.ax(this.a)},
gB(a){return J.im(this.a)},
K(a,b){return this.b.$1(J.eI(this.a,b))}}
A.c7.prototype={$ih:1}
A.ak.prototype={
m(){var t=this,s=t.b
if(s.m()){t.sao(t.c.$1(s.gq()))
return!0}t.sao(null)
return!1},
gq(){var t=this.a
return t==null?this.$ti.y[1].a(t):t},
sao(a){this.a=this.$ti.i("2?").a(a)},
$iv:1}
A.al.prototype={
gp(a){return J.ax(this.a)},
K(a,b){return this.b.$1(J.eI(this.a,b))}}
A.bE.prototype={
gv(a){return new A.cA(J.J(this.a),this.b,this.$ti.i("cA<1>"))}}
A.cA.prototype={
m(){var t,s
for(t=this.a,s=this.b;t.m();)if(A.O(s.$1(t.gq())))return!0
return!1},
gq(){return this.a.gq()},
$iv:1}
A.aE.prototype={
a_(a,b){A.eJ(b,"count",u.S)
A.an(b,"count")
return new A.aE(this.a,this.b+b,A.j(this).i("aE<1>"))},
gv(a){return new A.cu(J.J(this.a),this.b,A.j(this).i("cu<1>"))}}
A.bs.prototype={
gp(a){var t=J.ax(this.a)-this.b
if(t>=0)return t
return 0},
a_(a,b){A.eJ(b,"count",u.S)
A.an(b,"count")
return new A.bs(this.a,this.b+b,this.$ti)},
$ih:1}
A.cu.prototype={
m(){var t,s
for(t=this.a,s=0;s<this.b;++s)t.m()
this.b=0
return t.m()},
gq(){return this.a.gq()},
$iv:1}
A.c8.prototype={
gv(a){return B.Y},
gB(a){return!0},
gp(a){return 0},
K(a,b){throw A.c(A.N(b,0,0,"index",null))},
A(a,b){return!1},
a_(a,b){A.an(b,"count")
return this}}
A.c9.prototype={
m(){return!1},
gq(){throw A.c(A.f3())},
$iv:1}
A.a6.prototype={
gv(a){return new A.a7(J.J(this.a),this.$ti.i("a7<1>"))}}
A.a7.prototype={
m(){var t,s
for(t=this.a,s=this.$ti.c;t.m();)if(s.b(t.gq()))return!0
return!1},
gq(){return this.$ti.c.a(this.a.gq())},
$iv:1}
A.V.prototype={}
A.ct.prototype={
gp(a){return J.ax(this.a)},
K(a,b){var t=this.a,s=J.aa(t)
return s.K(t,s.gp(t)-1-b)}}
A.R.prototype={$r:"+(1,2)",$s:1}
A.bV.prototype={$r:"+(1,2,3)",$s:2}
A.c2.prototype={
bg(a,b,c){var t=A.j(this)
return A.iI(this,t.c,t.y[1],b,c)},
gB(a){return this.gp(this)===0},
gD(a){return this.gp(this)!==0},
t(a){return A.hR(this)},
n(a,b,c){var t=A.j(this)
t.c.a(b)
t.y[1].a(c)
A.hI()},
a3(a,b){A.hI()},
aS(a,b){A.j(this).i("C(1,2)").a(b)
A.hI()},
$in:1}
A.ag.prototype={
gp(a){return this.b.length},
gbR(){var t=this.$keys
if(t==null){t=Object.keys(this.a)
this.$keys=t}return t},
u(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
h(a,b){if(!this.u(b))return null
return this.b[this.a[b]]},
S(a,b){var t,s,r,q
this.$ti.i("~(1,2)").a(b)
t=this.gbR()
s=this.b
for(r=t.length,q=0;q<r;++q)b.$2(t[q],s[q])},
gJ(){return new A.bk(this.gbR(),this.$ti.i("bk<1>"))},
gW(){return new A.bk(this.b,this.$ti.i("bk<2>"))}}
A.bk.prototype={
gp(a){return this.a.length},
gB(a){return 0===this.a.length},
gD(a){return 0!==this.a.length},
gv(a){var t=this.a
return new A.bl(t,t.length,this.$ti.i("bl<1>"))}}
A.bl.prototype={
gq(){var t=this.d
return t==null?this.$ti.c.a(t):t},
m(){var t=this,s=t.c
if(s>=t.b){t.sap(null)
return!1}t.sap(t.a[s]);++t.c
return!0},
sap(a){this.d=this.$ti.i("1?").a(a)},
$iv:1}
A.c3.prototype={}
A.aA.prototype={
gp(a){return this.b},
gB(a){return this.b===0},
gD(a){return this.b!==0},
gv(a){var t,s=this,r=s.$keys
if(r==null){r=Object.keys(s.a)
s.$keys=r}t=r
return new A.bl(t,t.length,s.$ti.i("bl<1>"))},
A(a,b){if(typeof b!="string")return!1
if("__proto__"===b)return!1
return this.a.hasOwnProperty(b)}}
A.fs.prototype={
$0(){return B.d.dS(1000*this.a.now())},
$S:10}
A.fR.prototype={
a2(a){var t,s,r=this,q=new RegExp(r.a).exec(a)
if(q==null)return null
t=Object.create(null)
s=r.b
if(s!==-1)t.arguments=q[s+1]
s=r.c
if(s!==-1)t.argumentsExpr=q[s+1]
s=r.d
if(s!==-1)t.expr=q[s+1]
s=r.e
if(s!==-1)t.method=q[s+1]
s=r.f
if(s!==-1)t.receiver=q[s+1]
return t}}
A.co.prototype={
t(a){return"Null check operator used on a null value"}}
A.dA.prototype={
t(a){var t,s=this,r="NoSuchMethodError: method not found: '",q=s.b
if(q==null)return"NoSuchMethodError: "+s.a
t=s.c
if(t==null)return r+q+"' ("+s.a+")"
return r+q+"' on '"+t+"' ("+s.a+")"}}
A.ed.prototype={
t(a){var t=this.a
return t.length===0?"Error":"Error: "+t}}
A.fk.prototype={
t(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.aP.prototype={
t(a){var t=this.constructor,s=t==null?null:t.name
return"Closure '"+A.jE(s==null?"unknown":s)+"'"},
$iaQ:1,
gee(){return this},
$C:"$1",
$R:1,
$D:null}
A.db.prototype={$C:"$0",$R:0}
A.dc.prototype={$C:"$2",$R:2}
A.e9.prototype={}
A.e2.prototype={
t(a){var t=this.$static_name
if(t==null)return"Closure of unknown static method"
return"Closure '"+A.jE(t)+"'"}}
A.br.prototype={
T(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.br))return!1
return this.$_target===b.$_target&&this.a===b.a},
gL(a){return(A.hE(this.a)^A.dV(this.$_target))>>>0},
t(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.ft(this.a)+"'")}}
A.ev.prototype={
t(a){return"Reading static variable '"+this.a+"' during its initialization"}}
A.e_.prototype={
t(a){return"RuntimeError: "+this.a}}
A.eu.prototype={
t(a){return"Assertion failed: "+A.ca(this.a)}}
A.aC.prototype={
gp(a){return this.a},
gB(a){return this.a===0},
gD(a){return this.a!==0},
gJ(){return new A.aj(this,A.j(this).i("aj<1>"))},
gW(){var t=A.j(this)
return A.dH(new A.aj(this,t.i("aj<1>")),new A.f6(this),t.c,t.y[1])},
u(a){var t,s
if(typeof a=="string"){t=this.b
if(t==null)return!1
return t[a]!=null}else if(typeof a=="number"&&(a&0x3fffffff)===a){s=this.c
if(s==null)return!1
return s[a]!=null}else return this.dZ(a)},
dZ(a){var t=this.d
if(t==null)return!1
return this.aQ(t[this.aP(a)],a)>=0},
aa(a,b){A.j(this).i("n<1,2>").a(b).S(0,new A.f5(this))},
h(a,b){var t,s,r,q,p=null
if(typeof b=="string"){t=this.b
if(t==null)return p
s=t[b]
r=s==null?p:s.b
return r}else if(typeof b=="number"&&(b&0x3fffffff)===b){q=this.c
if(q==null)return p
s=q[b]
r=s==null?p:s.b
return r}else return this.e_(b)},
e_(a){var t,s,r=this.d
if(r==null)return null
t=r[this.aP(a)]
s=this.aQ(t,a)
if(s<0)return null
return t[s].b},
n(a,b,c){var t,s,r=this,q=A.j(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"){t=r.b
r.bB(t==null?r.b=r.b6():t,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){s=r.c
r.bB(s==null?r.c=r.b6():s,b,c)}else r.e1(b,c)},
e1(a,b){var t,s,r,q,p=this,o=A.j(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=p.b6()
s=p.aP(a)
r=t[s]
if(r==null)t[s]=[p.aW(a,b)]
else{q=p.aQ(r,a)
if(q>=0)r[q].b=b
else r.push(p.aW(a,b))}},
e5(a,b){var t,s,r=this,q=A.j(r)
q.c.a(a)
q.i("2()").a(b)
if(r.u(a)){t=r.h(0,a)
return t==null?q.y[1].a(t):t}s=b.$0()
r.n(0,a,s)
return s},
a3(a,b){var t=this
if(typeof b=="string")return t.c2(t.b,b)
else if(typeof b=="number"&&(b&0x3fffffff)===b)return t.c2(t.c,b)
else return t.e0(b)},
e0(a){var t,s,r,q,p=this,o=p.d
if(o==null)return null
t=p.aP(a)
s=o[t]
r=p.aQ(s,a)
if(r<0)return null
q=s.splice(r,1)[0]
p.c7(q)
if(s.length===0)delete o[t]
return q.b},
S(a,b){var t,s,r=this
A.j(r).i("~(1,2)").a(b)
t=r.e
s=r.r
for(;t!=null;){b.$2(t.a,t.b)
if(s!==r.r)throw A.c(A.Y(r))
t=t.c}},
bB(a,b,c){var t,s=A.j(this)
s.c.a(b)
s.y[1].a(c)
t=a[b]
if(t==null)a[b]=this.aW(b,c)
else t.b=c},
c2(a,b){var t
if(a==null)return null
t=a[b]
if(t==null)return null
this.c7(t)
delete a[b]
return t.b},
bT(){this.r=this.r+1&1073741823},
aW(a,b){var t=this,s=A.j(t),r=new A.fc(s.c.a(a),s.y[1].a(b))
if(t.e==null)t.e=t.f=r
else{s=t.f
s.toString
r.d=s
t.f=s.c=r}++t.a
t.bT()
return r},
c7(a){var t=this,s=a.d,r=a.c
if(s==null)t.e=r
else s.c=r
if(r==null)t.f=s
else r.d=s;--t.a
t.bT()},
aP(a){return J.M(a)&1073741823},
aQ(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.H(a[s].a,b))return s
return-1},
t(a){return A.hR(this)},
b6(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
$iiE:1}
A.f6.prototype={
$1(a){var t=this.a,s=A.j(t)
t=t.h(0,s.c.a(a))
return t==null?s.y[1].a(t):t},
$S(){return A.j(this.a).i("2(1)")}}
A.f5.prototype={
$2(a,b){var t=this.a,s=A.j(t)
t.n(0,s.c.a(a),s.y[1].a(b))},
$S(){return A.j(this.a).i("~(1,2)")}}
A.fc.prototype={}
A.aj.prototype={
gp(a){return this.a.a},
gB(a){return this.a.a===0},
gv(a){var t=this.a,s=new A.ci(t,t.r,this.$ti.i("ci<1>"))
s.c=t.e
return s},
A(a,b){return this.a.u(b)}}
A.ci.prototype={
gq(){return this.d},
m(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.c(A.Y(r))
t=s.c
if(t==null){s.sap(null)
return!1}else{s.sap(t.a)
s.c=t.c
return!0}},
sap(a){this.d=this.$ti.i("1?").a(a)},
$iv:1}
A.hy.prototype={
$1(a){return this.a(a)},
$S:8}
A.hz.prototype={
$2(a,b){return this.a(a,b)},
$S:17}
A.hA.prototype={
$1(a){return this.a(A.S(a))},
$S:2}
A.aJ.prototype={
t(a){return this.c6(!1)},
c6(a){var t,s,r,q,p,o=this.d_(),n=this.b4(),m=(a?""+"Record ":"")+"("
for(t=o.length,s="",r=0;r<t;++r,s=", "){m+=s
q=o[r]
if(typeof q=="string")m=m+q+": "
if(!(r<n.length))return A.a(n,r)
p=n[r]
m=a?m+A.iM(p):m+A.i(p)}m+=")"
return m.charCodeAt(0)==0?m:m},
d_(){var t,s=this.$s
for(;$.hm.length<=s;)B.a.j($.hm,null)
t=$.hm[s]
if(t==null){t=this.cN()
B.a.n($.hm,s,t)}return t},
cN(){var t,s,r,q=this.$r,p=q.indexOf("("),o=q.substring(1,p),n=q.substring(p),m=n==="()"?0:n.replace(/[^,]/g,"").length+1,l=A.d(new Array(m),u.G)
for(t=0;t<m;++t)l[t]=t
if(o!==""){s=o.split(",")
t=s.length
for(r=m;t>0;){--r;--t
B.a.n(l,r,s[t])}}l=A.hQ(l,!1,u.K)
l.$flags=3
return l}}
A.bT.prototype={
b4(){return[this.a,this.b]},
T(a,b){if(b==null)return!1
return b instanceof A.bT&&this.$s===b.$s&&J.H(this.a,b.a)&&J.H(this.b,b.b)},
gL(a){return A.dQ(this.$s,this.a,this.b,B.f)}}
A.bU.prototype={
b4(){return[this.a,this.b,this.c]},
T(a,b){var t=this
if(b==null)return!1
return b instanceof A.bU&&t.$s===b.$s&&J.H(t.a,b.a)&&J.H(t.b,b.b)&&J.H(t.c,b.c)},
gL(a){var t=this
return A.dQ(t.$s,t.a,t.b,t.c)}}
A.ce.prototype={
t(a){return"RegExp/"+this.a+"/"+this.b.flags},
gbU(){var t=this,s=t.c
if(s!=null)return s
s=t.b
return t.c=A.iC(t.a,s.multiline,!s.ignoreCase,s.unicode,s.dotAll,!0)},
be(a,b,c){var t=b.length
if(c>t)throw A.c(A.N(c,0,t,null,null))
return new A.et(this,b,c)},
bd(a,b){return this.be(0,b,0)},
bO(a,b){var t,s=this.gbU()
if(s==null)s=u.K.a(s)
s.lastIndex=b
t=s.exec(a)
if(t==null)return null
return new A.eB(t)},
$ifr:1,
$ikx:1}
A.eB.prototype={
gbv(){return this.b.index},
gaM(){var t=this.b
return t.index+t[0].length},
$iby:1,
$icr:1}
A.et.prototype={
gv(a){return new A.cL(this.a,this.b,this.c)}}
A.cL.prototype={
gq(){var t=this.d
return t==null?u.q.a(t):t},
m(){var t,s,r,q,p,o,n=this,m=n.b
if(m==null)return!1
t=n.c
s=m.length
if(t<=s){r=n.a
q=r.bO(m,t)
if(q!=null){n.d=q
p=q.gaM()
if(q.b.index===p){t=!1
if(r.b.unicode){r=n.c
o=r+1
if(o<s){if(!(r>=0&&r<s))return A.a(m,r)
r=m.charCodeAt(r)
if(r>=55296&&r<=56319){if(!(o>=0))return A.a(m,o)
t=m.charCodeAt(o)
t=t>=56320&&t<=57343}}}p=(t?p+1:p)+1}n.c=p
return!0}}n.b=n.d=null
return!1},
$iv:1}
A.e5.prototype={
gaM(){return this.a+this.c.length},
$iby:1,
gbv(){return this.a}}
A.eC.prototype={
gv(a){return new A.eD(this.a,this.b,this.c)}}
A.eD.prototype={
m(){var t,s,r=this,q=r.c,p=r.b,o=p.length,n=r.a,m=n.length
if(q+o>m){r.d=null
return!1}t=n.indexOf(p,q)
if(t<0){r.c=m+1
r.d=null
return!1}s=t+o
r.d=new A.e5(t,p)
r.c=s===r.c?s+1:s
return!0},
gq(){var t=this.d
t.toString
return t},
$iv:1}
A.bz.prototype={
gM(a){return B.aV},
c9(a,b,c){return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
$iw:1,
$ibz:1}
A.ck.prototype={
gai(a){if(((a.$flags|0)&2)!==0)return new A.ho(a.buffer)
else return a.buffer},
d3(a,b,c,d){var t=A.N(b,0,c,d,null)
throw A.c(t)},
bE(a,b,c,d){if(b>>>0!==b||b>c)this.d3(a,b,c,d)}}
A.ho.prototype={
c9(a,b,c){var t=A.iJ(this.a,b,c)
t.$flags=3
return t}}
A.dI.prototype={
gM(a){return B.aW},
$iw:1}
A.P.prototype={
gp(a){return a.length},
du(a,b,c,d,e){var t,s,r=a.length
this.bE(a,b,r,"start")
this.bE(a,c,r,"end")
if(b>c)throw A.c(A.N(b,0,c,null,null))
t=c-b
if(e<0)throw A.c(A.hG(e))
s=d.length
if(s-e<t)throw A.c(A.iS("Not enough elements"))
if(e!==0||s!==t)d=d.subarray(e,e+t)
a.set(d,b)},
$ia3:1}
A.cj.prototype={
h(a,b){A.aL(b,a,a.length)
return a[b]},
n(a,b,c){A.lg(c)
a.$flags&2&&A.T(a)
A.aL(b,a,a.length)
a[b]=c},
$ih:1,
$ie:1,
$ik:1}
A.a4.prototype={
n(a,b,c){A.af(c)
a.$flags&2&&A.T(a)
A.aL(b,a,a.length)
a[b]=c},
aD(a,b,c,d,e){u.hb.a(d)
a.$flags&2&&A.T(a,5)
if(u.eB.b(d)){this.du(a,b,c,d,e)
return}this.cB(a,b,c,d,e)},
bu(a,b,c,d){return this.aD(a,b,c,d,0)},
$ih:1,
$ie:1,
$ik:1}
A.dJ.prototype={
gM(a){return B.aX},
$iw:1}
A.dK.prototype={
gM(a){return B.aY},
$iw:1}
A.dL.prototype={
gM(a){return B.aZ},
h(a,b){A.aL(b,a,a.length)
return a[b]},
$iw:1}
A.dM.prototype={
gM(a){return B.b_},
h(a,b){A.aL(b,a,a.length)
return a[b]},
$iw:1}
A.dN.prototype={
gM(a){return B.b0},
h(a,b){A.aL(b,a,a.length)
return a[b]},
$iw:1}
A.dO.prototype={
gM(a){return B.b2},
h(a,b){A.aL(b,a,a.length)
return a[b]},
$iw:1}
A.dP.prototype={
gM(a){return B.b3},
h(a,b){A.aL(b,a,a.length)
return a[b]},
$iw:1,
$ihW:1}
A.cl.prototype={
gM(a){return B.b4},
gp(a){return a.length},
h(a,b){A.aL(b,a,a.length)
return a[b]},
$iw:1}
A.cm.prototype={
gM(a){return B.b5},
gp(a){return a.length},
h(a,b){A.aL(b,a,a.length)
return a[b]},
$iw:1,
$ifT:1}
A.cU.prototype={}
A.cV.prototype={}
A.cW.prototype={}
A.cX.prototype={}
A.ad.prototype={
i(a){return A.d2(v.typeUniverse,this,a)},
H(a){return A.jf(v.typeUniverse,this,a)}}
A.ex.prototype={}
A.eE.prototype={
t(a){return A.X(this.a,null)},
$ifQ:1}
A.ew.prototype={
t(a){return this.a}}
A.cZ.prototype={}
A.t.prototype={
gq(){var t=this.b
return t==null?this.$ti.c.a(t):t},
dt(a,b){var t,s,r
a=A.af(a)
b=b
t=this.a
for(;!0;)try{s=t(this,a,b)
return s}catch(r){b=r
a=1}},
m(){var t,s,r,q,p=this,o=null,n=null,m=0
for(;!0;){t=p.d
if(t!=null)try{if(t.m()){p.saX(t.gq())
return!0}else p.sb5(o)}catch(s){n=s
m=1
p.sb5(o)}r=p.dt(m,n)
if(1===r)return!0
if(0===r){p.saX(o)
q=p.e
if(q==null||q.length===0){p.a=A.ja
return!1}if(0>=q.length)return A.a(q,-1)
p.a=q.pop()
m=0
n=null
continue}if(2===r){m=0
n=null
continue}if(3===r){n=p.c
p.c=null
q=p.e
if(q==null||q.length===0){p.saX(o)
p.a=A.ja
throw n
return!1}if(0>=q.length)return A.a(q,-1)
p.a=q.pop()
m=1
continue}throw A.c(A.iS("sync*"))}return!1},
dC(a){var t,s,r=this
if(a instanceof A.bn){t=a.a()
s=r.e
if(s==null)s=r.e=[]
B.a.j(s,r.a)
r.a=t
return 2}else{r.sb5(J.J(a))
return 2}},
saX(a){this.b=this.$ti.i("1?").a(a)},
sb5(a){this.d=this.$ti.i("v<1>?").a(a)},
$iv:1}
A.bn.prototype={
gv(a){return new A.t(this.a(),this.$ti.i("t<1>"))}}
A.aI.prototype={
gp(a){return this.a},
gB(a){return this.a===0},
gD(a){return this.a!==0},
gJ(){return new A.bj(this,A.j(this).i("bj<1>"))},
gW(){var t=A.j(this)
return A.dH(new A.bj(this,t.i("bj<1>")),new A.he(this),t.c,t.y[1])},
u(a){var t,s
if(a!=="__proto__"){t=this.b
return t==null?!1:t[a]!=null}else{s=this.bH(a)
return s}},
bH(a){var t=this.d
if(t==null)return!1
return this.a5(this.bQ(t,a),a)>=0},
h(a,b){var t,s,r
if(typeof b=="string"&&b!=="__proto__"){t=this.b
s=t==null?null:A.i_(t,b)
return s}else if(typeof b=="number"&&(b&1073741823)===b){r=this.c
s=r==null?null:A.i_(r,b)
return s}else return this.bP(b)},
bP(a){var t,s,r=this.d
if(r==null)return null
t=this.bQ(r,a)
s=this.a5(t,a)
return s<0?null:t[s+1]},
n(a,b,c){var t,s,r=this,q=A.j(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"&&b!=="__proto__"){t=r.b
r.bD(t==null?r.b=A.i0():t,b,c)}else if(typeof b=="number"&&(b&1073741823)===b){s=r.c
r.bD(s==null?r.c=A.i0():s,b,c)}else r.c4(b,c)},
c4(a,b){var t,s,r,q,p=this,o=A.j(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=A.i0()
s=p.aq(a)
r=t[s]
if(r==null){A.i1(t,s,[a,b]);++p.a
p.e=null}else{q=p.a5(r,a)
if(q>=0)r[q+1]=b
else{r.push(a,b);++p.a
p.e=null}}},
a3(a,b){var t=this
if(typeof b=="string"&&b!=="__proto__")return t.bG(t.b,b)
else if(typeof b=="number"&&(b&1073741823)===b)return t.bG(t.c,b)
else return t.c1(b)},
c1(a){var t,s,r,q,p=this,o=p.d
if(o==null)return null
t=p.aq(a)
s=o[t]
r=p.a5(s,a)
if(r<0)return null;--p.a
p.e=null
q=s.splice(r,2)[1]
if(0===s.length)delete o[t]
return q},
S(a,b){var t,s,r,q,p,o,n=this,m=A.j(n)
m.i("~(1,2)").a(b)
t=n.bF()
for(s=t.length,r=m.c,m=m.y[1],q=0;q<s;++q){p=t[q]
r.a(p)
o=n.h(0,p)
b.$2(p,o==null?m.a(o):o)
if(t!==n.e)throw A.c(A.Y(n))}},
bF(){var t,s,r,q,p,o,n,m,l,k,j=this,i=j.e
if(i!=null)return i
i=A.ff(j.a,null,!1,u.z)
t=j.b
s=0
if(t!=null){r=Object.getOwnPropertyNames(t)
q=r.length
for(p=0;p<q;++p){i[s]=r[p];++s}}o=j.c
if(o!=null){r=Object.getOwnPropertyNames(o)
q=r.length
for(p=0;p<q;++p){i[s]=+r[p];++s}}n=j.d
if(n!=null){r=Object.getOwnPropertyNames(n)
q=r.length
for(p=0;p<q;++p){m=n[r[p]]
l=m.length
for(k=0;k<l;k+=2){i[s]=m[k];++s}}}return j.e=i},
bD(a,b,c){var t=A.j(this)
t.c.a(b)
t.y[1].a(c)
if(a[b]==null){++this.a
this.e=null}A.i1(a,b,c)},
bG(a,b){var t
if(a!=null&&a[b]!=null){t=A.j(this).y[1].a(A.i_(a,b))
delete a[b];--this.a
this.e=null
return t}else return null},
aq(a){return J.M(a)&1073741823},
bQ(a,b){return a[this.aq(b)]},
a5(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;s+=2)if(J.H(a[s],b))return s
return-1}}
A.he.prototype={
$1(a){var t=this.a,s=A.j(t)
t=t.h(0,s.c.a(a))
return t==null?s.y[1].a(t):t},
$S(){return A.j(this.a).i("2(1)")}}
A.cQ.prototype={
aq(a){return A.hE(a)&1073741823},
a5(a,b){var t,s,r
if(a==null)return-1
t=a.length
for(s=0;s<t;s+=2){r=a[s]
if(r==null?b==null:r===b)return s}return-1}}
A.cM.prototype={
h(a,b){if(!A.O(this.w.$1(b)))return null
return this.cD(b)},
n(a,b,c){var t=this.$ti
this.cF(t.c.a(b),t.y[1].a(c))},
u(a){if(!A.O(this.w.$1(a)))return!1
return this.cC(a)},
a3(a,b){if(!A.O(this.w.$1(b)))return null
return this.cE(b)},
aq(a){return this.r.$1(this.$ti.c.a(a))&1073741823},
a5(a,b){var t,s,r,q
if(a==null)return-1
t=a.length
for(s=this.$ti.c,r=this.f,q=0;q<t;q+=2)if(A.O(r.$2(a[q],s.a(b))))return q
return-1}}
A.ha.prototype={
$1(a){return this.a.b(a)},
$S:13}
A.bj.prototype={
gp(a){return this.a.a},
gB(a){return this.a.a===0},
gD(a){return this.a.a!==0},
gv(a){var t=this.a
return new A.cP(t,t.bF(),this.$ti.i("cP<1>"))},
A(a,b){return this.a.u(b)}}
A.cP.prototype={
gq(){var t=this.d
return t==null?this.$ti.c.a(t):t},
m(){var t=this,s=t.b,r=t.c,q=t.a
if(s!==q.e)throw A.c(A.Y(q))
else if(r>=s.length){t.sa8(null)
return!1}else{t.sa8(s[r])
t.c=r+1
return!0}},
sa8(a){this.d=this.$ti.i("1?").a(a)},
$iv:1}
A.bm.prototype={
gv(a){var t=this,s=new A.cR(t,t.r,t.$ti.i("cR<1>"))
s.c=t.e
return s},
gp(a){return this.a},
gB(a){return this.a===0},
gD(a){return this.a!==0},
A(a,b){var t,s
if(typeof b=="string"&&b!=="__proto__"){t=this.b
if(t==null)return!1
return u.br.a(t[b])!=null}else{s=this.cO(b)
return s}},
cO(a){var t=this.d
if(t==null)return!1
return this.a5(t[J.M(a)&1073741823],a)>=0},
j(a,b){var t,s,r=this
r.$ti.c.a(b)
if(typeof b=="string"&&b!=="__proto__"){t=r.b
return r.bC(t==null?r.b=A.i2():t,b)}else if(typeof b=="number"&&(b&1073741823)===b){s=r.c
return r.bC(s==null?r.c=A.i2():s,b)}else return r.cJ(b)},
cJ(a){var t,s,r,q=this
q.$ti.c.a(a)
t=q.d
if(t==null)t=q.d=A.i2()
s=J.M(a)&1073741823
r=t[s]
if(r==null)t[s]=[q.b7(a)]
else{if(q.a5(r,a)>=0)return!1
r.push(q.b7(a))}return!0},
bC(a,b){this.$ti.c.a(b)
if(u.br.a(a[b])!=null)return!1
a[b]=this.b7(b)
return!0},
b7(a){var t=this,s=new A.eA(t.$ti.c.a(a))
if(t.e==null)t.e=t.f=s
else t.f=t.f.b=s;++t.a
t.r=t.r+1&1073741823
return s},
a5(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.H(a[s].a,b))return s
return-1},
$iiF:1}
A.eA.prototype={}
A.cR.prototype={
gq(){var t=this.d
return t==null?this.$ti.c.a(t):t},
m(){var t=this,s=t.c,r=t.a
if(t.b!==r.r)throw A.c(A.Y(r))
else if(s==null){t.sa8(null)
return!1}else{t.sa8(t.$ti.i("1?").a(s.a))
t.c=s.b
return!0}},
sa8(a){this.d=this.$ti.i("1?").a(a)},
$iv:1}
A.fe.prototype={
$2(a,b){this.a.n(0,this.b.a(a),this.c.a(b))},
$S:20}
A.y.prototype={
gv(a){return new A.b9(a,this.gp(a),A.bp(a).i("b9<y.E>"))},
K(a,b){return this.h(a,b)},
gB(a){return this.gp(a)===0},
gD(a){return!this.gB(a)},
A(a,b){var t,s=this.gp(a)
for(t=0;t<s;++t){if(J.H(this.h(a,t),b))return!0
if(s!==this.gp(a))throw A.c(A.Y(a))}return!1},
a_(a,b){return A.fA(a,b,null,A.bp(a).i("y.E"))},
aD(a,b,c,d,e){var t,s,r,q,p=A.bp(a)
p.i("e<y.E>").a(d)
A.cq(b,c,this.gp(a))
t=c-b
if(t===0)return
A.an(e,"skipCount")
if(p.i("k<y.E>").b(d)){s=e
r=d}else{r=J.io(d,e).cl(0,!1)
s=0}p=J.aa(r)
if(s+t>p.gp(r))throw A.c(A.ke())
if(s<b)for(q=t-1;q>=0;--q)this.n(a,b+q,p.h(r,s+q))
else for(q=0;q<t;++q)this.n(a,b+q,p.h(r,s+q))},
t(a){return A.hN(a,"[","]")}}
A.o.prototype={
bg(a,b,c){var t=A.j(this)
return A.iI(this,t.i("o.K"),t.i("o.V"),b,c)},
S(a,b){var t,s,r,q=A.j(this)
q.i("~(o.K,o.V)").a(b)
for(t=this.gJ(),t=t.gv(t),q=q.i("o.V");t.m();){s=t.gq()
r=this.h(0,s)
b.$2(s,r==null?q.a(r):r)}},
gdN(){return this.gJ().bn(0,new A.fi(this),A.j(this).i("aD<o.K,o.V>"))},
aS(a,b){var t,s,r,q,p,o=this,n=A.j(o)
n.i("C(o.K,o.V)").a(b)
t=A.d([],n.i("m<o.K>"))
for(s=o.gJ(),s=s.gv(s),n=n.i("o.V");s.m();){r=s.gq()
q=o.h(0,r)
if(A.O(b.$2(r,q==null?n.a(q):q)))B.a.j(t,r)}for(n=t.length,p=0;p<t.length;t.length===n||(0,A.l)(t),++p)o.a3(0,t[p])},
u(a){return this.gJ().A(0,a)},
gp(a){var t=this.gJ()
return t.gp(t)},
gB(a){var t=this.gJ()
return t.gB(t)},
gD(a){var t=this.gJ()
return t.gD(t)},
gW(){return new A.cS(this,A.j(this).i("cS<o.K,o.V>"))},
t(a){return A.hR(this)},
$in:1}
A.fi.prototype={
$1(a){var t=this.a,s=A.j(t)
s.i("o.K").a(a)
t=t.h(0,a)
if(t==null)t=s.i("o.V").a(t)
return new A.aD(a,t,s.i("aD<o.K,o.V>"))},
$S(){return A.j(this.a).i("aD<o.K,o.V>(o.K)")}}
A.fj.prototype={
$2(a,b){var t,s=this.a
if(!s.a)this.b.a+=", "
s.a=!1
s=this.b
t=A.i(a)
t=s.a+=t
s.a=t+": "
t=A.i(b)
s.a+=t},
$S:5}
A.cS.prototype={
gp(a){var t=this.a
return t.gp(t)},
gB(a){var t=this.a
return t.gB(t)},
gD(a){var t=this.a
return t.gD(t)},
gv(a){var t=this.a,s=t.gJ()
return new A.cT(s.gv(s),t,this.$ti.i("cT<1,2>"))}}
A.cT.prototype={
m(){var t=this,s=t.a
if(s.m()){t.sa8(t.b.h(0,s.gq()))
return!0}t.sa8(null)
return!1},
gq(){var t=this.c
return t==null?this.$ti.y[1].a(t):t},
sa8(a){this.c=this.$ti.i("2?").a(a)},
$iv:1}
A.ao.prototype={
gB(a){return this.gp(this)===0},
gD(a){return this.gp(this)!==0},
t(a){return A.hN(this,"{","}")},
a_(a,b){return A.iR(this,b,A.j(this).c)},
K(a,b){var t,s
A.an(b,"index")
t=this.gv(this)
for(s=b;t.m();){if(s===0)return t.gq();--s}throw A.c(A.f0(b,b-s,this,"index"))},
$ih:1,
$ie:1,
$ias:1}
A.cY.prototype={}
A.ey.prototype={
h(a,b){var t,s=this.b
if(s==null)return this.c.h(0,b)
else if(typeof b!="string")return null
else{t=s[b]
return typeof t=="undefined"?this.dm(b):t}},
gp(a){return this.b==null?this.c.a:this.ah().length},
gB(a){return this.gp(0)===0},
gD(a){return this.gp(0)>0},
gJ(){if(this.b==null){var t=this.c
return new A.aj(t,A.j(t).i("aj<1>"))}return new A.ez(this)},
gW(){var t=this
if(t.b==null)return t.c.gW()
return A.dH(t.ah(),new A.hg(t),u.N,u.z)},
n(a,b,c){var t,s,r=this
A.S(b)
if(r.b==null)r.c.n(0,b,c)
else if(r.u(b)){t=r.b
t[b]=c
s=r.a
if(s==null?t!=null:s!==t)s[b]=null}else r.c8().n(0,b,c)},
u(a){if(this.b==null)return this.c.u(a)
if(typeof a!="string")return!1
return Object.prototype.hasOwnProperty.call(this.a,a)},
a3(a,b){if(this.b!=null&&!this.u(b))return null
return this.c8().a3(0,b)},
S(a,b){var t,s,r,q,p=this
u.cA.a(b)
if(p.b==null)return p.c.S(0,b)
t=p.ah()
for(s=0;s<t.length;++s){r=t[s]
q=p.b[r]
if(typeof q=="undefined"){q=A.ht(p.a[r])
p.b[r]=q}b.$2(r,q)
if(t!==p.c)throw A.c(A.Y(p))}},
ah(){var t=u.bM.a(this.c)
if(t==null)t=this.c=A.d(Object.keys(this.a),u.s)
return t},
c8(){var t,s,r,q,p,o=this
if(o.b==null)return o.c
t=A.u(u.N,u.z)
s=o.ah()
for(r=0;q=s.length,r<q;++r){p=s[r]
t.n(0,p,o.h(0,p))}if(q===0)B.a.j(s,"")
else B.a.aj(s)
o.a=o.b=null
return o.c=t},
dm(a){var t
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
t=A.ht(this.a[a])
return this.b[a]=t}}
A.hg.prototype={
$1(a){return this.a.h(0,A.S(a))},
$S:2}
A.ez.prototype={
gp(a){return this.a.gp(0)},
K(a,b){var t=this.a
if(t.b==null)t=t.gJ().K(0,b)
else{t=t.ah()
if(!(b>=0&&b<t.length))return A.a(t,b)
t=t[b]}return t},
gv(a){var t=this.a
if(t.b==null){t=t.gJ()
t=t.gv(t)}else{t=t.ah()
t=new J.b3(t,t.length,A.U(t).i("b3<1>"))}return t},
A(a,b){return this.a.u(b)}}
A.hr.prototype={
$0(){var t,s
try{t=new TextDecoder("utf-8",{fatal:true})
return t}catch(s){}return null},
$S:7}
A.hq.prototype={
$0(){var t,s
try{t=new TextDecoder("utf-8",{fatal:false})
return t}catch(s){}return null},
$S:7}
A.hn.prototype={
au(a){var t,s,r,q
u.L.a(a)
t=a.length
s=A.cq(0,null,t)
for(r=0;r<s;++r){if(!(r<t))return A.a(a,r)
q=a[r]
if((q&4294967040)!==0){if(!this.a)throw A.c(A.dk("Invalid value in input: "+q,null,null))
return this.cT(a,0,s)}}return A.hV(a,0,s)},
cT(a,b,c){var t,s,r,q
u.L.a(a)
for(t=a.length,s=b,r="";s<c;++s){if(!(s<t))return A.a(a,s)
q=a[s]
r+=A.p((q&4294967040)!==0?65533:q)}return r.charCodeAt(0)==0?r:r}}
A.c0.prototype={
gbh(){return B.W}}
A.eK.prototype={
au(a){var t
u.L.a(a)
t=a.length
if(t===0)return""
t=new A.h9("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/").dM(a,0,t,!0)
t.toString
return A.hV(t,0,null)}}
A.h9.prototype={
dM(a,b,c,d){var t,s,r,q,p
u.L.a(a)
t=this.a
s=(t&3)+(c-b)
r=B.c.aJ(s,3)
q=r*4
if(s-r*3>0)q+=4
p=new Uint8Array(q)
this.a=A.kT(this.b,a,b,c,!0,p,0,t)
if(q>0)return p
return null}}
A.a1.prototype={}
A.dg.prototype={}
A.di.prototype={}
A.cg.prototype={
t(a){var t=A.ca(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+t}}
A.dC.prototype={
t(a){return"Cyclic error in JSON stringify"}}
A.dB.prototype={
cb(a,b){var t=A.lO(a,this.gdJ().a)
return t},
cd(a,b){var t=A.kW(a,this.gbh().b,null)
return t},
gbh(){return B.aj},
gdJ(){return B.ai}}
A.f8.prototype={}
A.f7.prototype={}
A.hi.prototype={
cq(a){var t,s,r,q,p,o,n=a.length
for(t=this.c,s=0,r=0;r<n;++r){q=a.charCodeAt(r)
if(q>92){if(q>=55296){p=q&64512
if(p===55296){o=r+1
o=!(o<n&&(a.charCodeAt(o)&64512)===56320)}else o=!1
if(!o)if(p===56320){p=r-1
p=!(p>=0&&(a.charCodeAt(p)&64512)===55296)}else p=!1
else p=!0
if(p){if(r>s)t.a+=B.b.C(a,s,r)
s=r+1
p=A.p(92)
t.a+=p
p=A.p(117)
t.a+=p
p=A.p(100)
t.a+=p
p=q>>>8&15
p=A.p(p<10?48+p:87+p)
t.a+=p
p=q>>>4&15
p=A.p(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.p(p<10?48+p:87+p)
t.a+=p}}continue}if(q<32){if(r>s)t.a+=B.b.C(a,s,r)
s=r+1
p=A.p(92)
t.a+=p
switch(q){case 8:p=A.p(98)
t.a+=p
break
case 9:p=A.p(116)
t.a+=p
break
case 10:p=A.p(110)
t.a+=p
break
case 12:p=A.p(102)
t.a+=p
break
case 13:p=A.p(114)
t.a+=p
break
default:p=A.p(117)
t.a+=p
p=A.p(48)
t.a+=p
p=A.p(48)
t.a+=p
p=q>>>4&15
p=A.p(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.p(p<10?48+p:87+p)
t.a+=p
break}}else if(q===34||q===92){if(r>s)t.a+=B.b.C(a,s,r)
s=r+1
p=A.p(92)
t.a+=p
p=A.p(q)
t.a+=p}}if(s===0)t.a+=a
else if(s<n)t.a+=B.b.C(a,s,n)},
aY(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(a==null?q==null:a===q)throw A.c(new A.dC(a,null))}B.a.j(t,a)},
aU(a){var t,s,r,q,p=this
if(p.cp(a))return
p.aY(a)
try{t=p.b.$1(a)
if(!p.cp(t)){r=A.iD(a,null,p.gc_())
throw A.c(r)}r=p.a
if(0>=r.length)return A.a(r,-1)
r.pop()}catch(q){s=A.jF(q)
r=A.iD(a,s,p.gc_())
throw A.c(r)}},
cp(a){var t,s,r,q=this
if(typeof a=="number"){if(!isFinite(a))return!1
t=q.c
s=B.d.t(a)
t.a+=s
return!0}else if(a===!0){q.c.a+="true"
return!0}else if(a===!1){q.c.a+="false"
return!0}else if(a==null){q.c.a+="null"
return!0}else if(typeof a=="string"){t=q.c
t.a+='"'
q.cq(a)
t.a+='"'
return!0}else if(u.j.b(a)){q.aY(a)
q.eb(a)
t=q.a
if(0>=t.length)return A.a(t,-1)
t.pop()
return!0}else if(u.f.b(a)){q.aY(a)
r=q.ec(a)
t=q.a
if(0>=t.length)return A.a(t,-1)
t.pop()
return r}else return!1},
eb(a){var t,s,r=this.c
r.a+="["
t=J.aa(a)
if(t.gD(a)){this.aU(t.h(a,0))
for(s=1;s<t.gp(a);++s){r.a+=","
this.aU(t.h(a,s))}}r.a+="]"},
ec(a){var t,s,r,q,p,o,n=this,m={}
if(a.gB(a)){n.c.a+="{}"
return!0}t=a.gp(a)*2
s=A.ff(t,null,!1,u.O)
r=m.a=0
m.b=!0
a.S(0,new A.hj(m,s))
if(!m.b)return!1
q=n.c
q.a+="{"
for(p='"';r<t;r+=2,p=',"'){q.a+=p
n.cq(A.S(s[r]))
q.a+='":'
o=r+1
if(!(o<t))return A.a(s,o)
n.aU(s[o])}q.a+="}"
return!0}}
A.hj.prototype={
$2(a,b){var t,s
if(typeof a!="string")this.a.b=!1
t=this.b
s=this.a
B.a.n(t,s.a++,a)
B.a.n(t,s.a++,b)},
$S:5}
A.hh.prototype={
gc_(){var t=this.c.a
return t.charCodeAt(0)==0?t:t}}
A.dD.prototype={
av(a){var t
u.L.a(a)
t=B.ak.au(a)
return t}}
A.f9.prototype={}
A.ee.prototype={
av(a){u.L.a(a)
return B.b6.au(a)}}
A.fU.prototype={
au(a){return new A.hp(this.a).cS(u.L.a(a),0,null,!0)}}
A.hp.prototype={
cS(a,b,c,d){var t,s,r,q,p,o,n,m=this
u.L.a(a)
t=A.cq(b,c,a.length)
if(b===t)return""
if(a instanceof Uint8Array){s=a
r=s
q=0}else{r=A.le(a,b,t)
t-=b
q=b
b=0}if(t-b>=15){p=m.a
o=A.ld(p,r,b,t)
if(o!=null){if(!p)return o
if(o.indexOf("\ufffd")<0)return o}}o=m.b0(r,b,t,!0)
p=m.b
if((p&1)!==0){n=A.lf(p)
m.b=0
throw A.c(A.dk(n,a,q+m.c))}return o},
b0(a,b,c,d){var t,s,r=this
if(c-b>1000){t=B.c.aJ(b+c,2)
s=r.b0(a,b,t,!1)
if((r.b&1)!==0)return s
return s+r.b0(a,t,c,d)}return r.dI(a,b,c,d)},
dI(a,b,c,a0){var t,s,r,q,p,o,n,m,l=this,k="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHHHHHHHHIHHHJEEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBKCCCCCCCCCCCCDCLONNNMEEEEEEEEEEE",j=" \x000:XECCCCCN:lDb \x000:XECCCCCNvlDb \x000:XECCCCCN:lDb AAAAA\x00\x00\x00\x00\x00AAAAA00000AAAAA:::::AAAAAGG000AAAAA00KKKAAAAAG::::AAAAA:IIIIAAAAA000\x800AAAAA\x00\x00\x00\x00 AAAAA",i=65533,h=l.b,g=l.c,f=new A.D(""),e=b+1,d=a.length
if(!(b>=0&&b<d))return A.a(a,b)
t=a[b]
$label0$0:for(s=l.a;!0;){for(;!0;e=p){if(!(t>=0&&t<256))return A.a(k,t)
r=k.charCodeAt(t)&31
g=h<=32?t&61694>>>r:(t&63|g<<6)>>>0
q=h+r
if(!(q>=0&&q<144))return A.a(j,q)
h=j.charCodeAt(q)
if(h===0){q=A.p(g)
f.a+=q
if(e===c)break $label0$0
break}else if((h&1)!==0){if(s)switch(h){case 69:case 67:q=A.p(i)
f.a+=q
break
case 65:q=A.p(i)
f.a+=q;--e
break
default:q=A.p(i)
q=f.a+=q
f.a=q+A.p(i)
break}else{l.b=h
l.c=e-1
return""}h=0}if(e===c)break $label0$0
p=e+1
if(!(e>=0&&e<d))return A.a(a,e)
t=a[e]}p=e+1
if(!(e>=0&&e<d))return A.a(a,e)
t=a[e]
if(t<128){while(!0){if(!(p<c)){o=c
break}n=p+1
if(!(p>=0&&p<d))return A.a(a,p)
t=a[p]
if(t>=128){o=n-1
p=n
break}p=n}if(o-e<20)for(m=e;m<o;++m){if(!(m<d))return A.a(a,m)
q=A.p(a[m])
f.a+=q}else{q=A.hV(a,e,o)
f.a+=q}if(o===c)break $label0$0
e=p}else e=p}if(a0&&h>32)if(s){d=A.p(i)
f.a+=d}else{l.b=77
l.c=c
return""}l.b=h
l.c=g
d=f.a
return d.charCodeAt(0)==0?d:d}}
A.hc.prototype={
t(a){return this.ac()}}
A.A.prototype={}
A.c_.prototype={
t(a){var t=this.a
if(t!=null)return"Assertion failed: "+A.ca(t)
return"Assertion failed"}}
A.cx.prototype={}
A.ay.prototype={
gb2(){return"Invalid argument"+(!this.a?"(s)":"")},
gb1(){return""},
t(a){var t=this,s=t.c,r=s==null?"":" ("+s+")",q=t.d,p=q==null?"":": "+A.i(q),o=t.gb2()+r+p
if(!t.a)return o
return o+t.gb1()+": "+A.ca(t.gbj())},
gbj(){return this.b}}
A.cp.prototype={
gbj(){return A.lh(this.b)},
gb2(){return"RangeError"},
gb1(){var t,s=this.e,r=this.f
if(s==null)t=r!=null?": Not less than or equal to "+A.i(r):""
else if(r==null)t=": Not greater than or equal to "+A.i(s)
else if(r>s)t=": Not in inclusive range "+A.i(s)+".."+A.i(r)
else t=r<s?": Valid value range is empty":": Only valid value is "+A.i(s)
return t}}
A.ds.prototype={
gbj(){return A.af(this.b)},
gb2(){return"RangeError"},
gb1(){if(A.af(this.b)<0)return": index must not be negative"
var t=this.f
if(t===0)return": no indices are valid"
return": index should be less than "+t},
gp(a){return this.f}}
A.cz.prototype={
t(a){return"Unsupported operation: "+this.a}}
A.ec.prototype={
t(a){return"UnimplementedError: "+this.a}}
A.bC.prototype={
t(a){return"Bad state: "+this.a}}
A.df.prototype={
t(a){var t=this.a
if(t==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.ca(t)+"."}}
A.dR.prototype={
t(a){return"Out of Memory"},
$iA:1}
A.cv.prototype={
t(a){return"Stack Overflow"},
$iA:1}
A.hd.prototype={
t(a){return"Exception: "+this.a}}
A.ai.prototype={
t(a){var t,s,r,q,p,o,n,m,l,k,j,i=this.a,h=""!==i?"FormatException: "+i:"FormatException",g=this.c,f=this.b
if(typeof f=="string"){if(g!=null)t=g<0||g>f.length
else t=!1
if(t)g=null
if(g==null){if(f.length>78)f=B.b.C(f,0,75)+"..."
return h+"\n"+f}for(s=f.length,r=1,q=0,p=!1,o=0;o<g;++o){if(!(o<s))return A.a(f,o)
n=f.charCodeAt(o)
if(n===10){if(q!==o||!p)++r
q=o+1
p=!1}else if(n===13){++r
q=o+1
p=!0}}h=r>1?h+(" (at line "+r+", character "+(g-q+1)+")\n"):h+(" (at character "+(g+1)+")\n")
for(o=g;o<s;++o){if(!(o>=0))return A.a(f,o)
n=f.charCodeAt(o)
if(n===10||n===13){s=o
break}}m=""
if(s-q>78){l="..."
if(g-q<75){k=q+75
j=q}else{if(s-g<75){j=s-75
k=s
l=""}else{j=g-36
k=g+36}m="..."}}else{k=s
j=q
l=""}return h+m+B.b.C(f,j,k)+l+"\n"+B.b.bt(" ",g-j+m.length)+"^\n"}else return g!=null?h+(" (at offset "+A.i(g)+")"):h}}
A.e.prototype={
bn(a,b,c){var t=A.j(this)
return A.dH(this,t.H(c).i("1(e.E)").a(b),t.i("e.E"),c)},
A(a,b){var t
for(t=this.gv(this);t.m();)if(J.H(t.gq(),b))return!0
return!1},
ae(a,b){var t,s,r=this.gv(this)
if(!r.m())return""
t=J.x(r.gq())
if(!r.m())return t
if(b.length===0){s=t
do s+=J.x(r.gq())
while(r.m())}else{s=t
do s=s+b+J.x(r.gq())
while(r.m())}return s.charCodeAt(0)==0?s:s},
bl(a){return this.ae(0,"")},
cl(a,b){return A.ba(this,b,A.j(this).i("e.E"))},
gp(a){var t,s=this.gv(this)
for(t=0;s.m();)++t
return t},
gB(a){return!this.gv(this).m()},
gD(a){return!this.gB(this)},
a_(a,b){return A.iR(this,b,A.j(this).i("e.E"))},
gak(a){var t=this.gv(this)
if(!t.m())throw A.c(A.f3())
return t.gq()},
K(a,b){var t,s
A.an(b,"index")
t=this.gv(this)
for(s=b;t.m();){if(s===0)return t.gq();--s}throw A.c(A.f0(b,b-s,this,"index"))},
t(a){return A.kf(this,"(",")")}}
A.aD.prototype={
t(a){return"MapEntry("+A.i(this.a)+": "+A.i(this.b)+")"}}
A.cn.prototype={
gL(a){return A.q.prototype.gL.call(this,0)},
t(a){return"null"}}
A.q.prototype={$iq:1,
T(a,b){return this===b},
gL(a){return A.dV(this)},
t(a){return"Instance of '"+A.ft(this)+"'"},
gM(a){return A.ie(this)},
toString(){return this.t(this)}}
A.e3.prototype={
gcc(){var t,s=this.b
if(s==null)s=$.dX.$0()
t=s-this.a
if($.il()===1000)return t
return B.c.aJ(t,1000)},
bw(){var t=this,s=t.b
if(s!=null){t.a=t.a+($.dX.$0()-s)
t.b=null}}}
A.D.prototype={
gp(a){return this.a.length},
t(a){var t=this.a
return t.charCodeAt(0)==0?t:t},
$ikA:1}
A.b6.prototype={
N(a,b){return J.H(a,b)},
O(a){return J.M(a)},
$iah:1}
A.bt.prototype={
N(a,b){var t,s,r,q=this.$ti.i("e<1>?")
q.a(a)
q.a(b)
if(a===b)return!0
t=J.J(a)
s=J.J(b)
for(q=this.a;!0;){r=t.m()
if(r!==s.m())return!1
if(!r)return!0
if(!q.N(t.gq(),s.gq()))return!1}},
O(a){var t,s,r
this.$ti.i("e<1>?").a(a)
for(t=J.J(a),s=this.a,r=0;t.m();){r=r+s.O(t.gq())&2147483647
r=r+(r<<10>>>0)&2147483647
r^=r>>>6}r=r+(r<<3>>>0)&2147483647
r^=r>>>11
return r+(r<<15>>>0)&2147483647},
$iah:1}
A.aT.prototype={
N(a,b){var t,s,r,q,p=this.$ti.i("k<1>?")
p.a(a)
p.a(b)
if(a===b)return!0
p=J.aa(a)
t=p.gp(a)
s=J.aa(b)
if(t!==s.gp(b))return!1
for(r=this.a,q=0;q<t;++q)if(!r.N(p.h(a,q),s.h(b,q)))return!1
return!0},
O(a){var t,s,r,q
this.$ti.i("k<1>?").a(a)
for(t=J.aa(a),s=this.a,r=0,q=0;q<t.gp(a);++q){r=r+s.O(t.h(a,q))&2147483647
r=r+(r<<10>>>0)&2147483647
r^=r>>>6}r=r+(r<<3>>>0)&2147483647
r^=r>>>11
return r+(r<<15>>>0)&2147483647},
$iah:1}
A.a9.prototype={
N(a,b){var t,s,r,q,p=A.j(this),o=p.i("a9.T?")
o.a(a)
o.a(b)
if(a===b)return!0
o=this.a
t=A.iy(p.i("C(a9.E,a9.E)").a(o.gdO()),p.i("b(a9.E)").a(o.gdV()),o.ge2(),p.i("a9.E"),u.S)
for(p=J.J(a),s=0;p.m();){r=p.gq()
q=t.h(0,r)
t.n(0,r,(q==null?0:q)+1);++s}for(p=J.J(b);p.m();){r=p.gq()
q=t.h(0,r)
if(q==null||q===0)return!1
if(typeof q!=="number")return q.by()
t.n(0,r,q-1);--s}return s===0},
O(a){var t,s,r
A.j(this).i("a9.T?").a(a)
for(t=J.J(a),s=this.a,r=0;t.m();)r=r+s.O(t.gq())&2147483647
r=r+(r<<3>>>0)&2147483647
r^=r>>>11
return r+(r<<15>>>0)&2147483647},
$iah:1}
A.bB.prototype={}
A.bS.prototype={
gL(a){var t=this.a
return 3*t.a.O(this.b)+7*t.b.O(this.c)&2147483647},
T(a,b){var t
if(b==null)return!1
if(b instanceof A.bS){t=this.a
t=t.a.N(this.b,b.b)&&t.b.N(this.c,b.c)}else t=!1
return t}}
A.bx.prototype={
N(a,b){var t,s,r,q,p=this.$ti.i("n<1,2>?")
p.a(a)
p.a(b)
if(a===b)return!0
if(a.gp(a)!==b.gp(b))return!1
t=A.iy(null,null,null,u.gA,u.S)
for(p=a.gJ(),p=p.gv(p);p.m();){s=p.gq()
r=new A.bS(this,s,a.h(0,s))
q=t.h(0,r)
t.n(0,r,(q==null?0:q)+1)}for(p=b.gJ(),p=p.gv(p);p.m();){s=p.gq()
r=new A.bS(this,s,b.h(0,s))
q=t.h(0,r)
if(q==null||q===0)return!1
if(typeof q!=="number")return q.by()
t.n(0,r,q-1)}return!0},
O(a){var t,s,r,q,p,o,n,m=this.$ti
m.i("n<1,2>?").a(a)
for(t=a.gJ(),t=t.gv(t),s=this.a,r=this.b,m=m.y[1],q=0;t.m();){p=t.gq()
o=s.O(p)
n=a.h(0,p)
q=q+3*o+7*r.O(n==null?m.a(n):n)&2147483647}q=q+(q<<3>>>0)&2147483647
q^=q>>>11
return q+(q<<15>>>0)&2147483647},
$iah:1}
A.c4.prototype={
N(a,b){var t,s=this
if(a instanceof A.ao)return b instanceof A.ao&&new A.bB(s,u.D).N(a,b)
t=u.f
if(t.b(a))return t.b(b)&&new A.bx(s,s,u.e).N(a,b)
t=u.j
if(t.b(a))return t.b(b)&&new A.aT(s,u.J).N(a,b)
t=u.R
if(t.b(a))return t.b(b)&&new A.bt(s,u.c).N(a,b)
return J.H(a,b)},
O(a){var t=this
if(a instanceof A.ao)return new A.bB(t,u.D).O(a)
if(u.f.b(a))return new A.bx(t,t,u.e).O(a)
if(u.j.b(a))return new A.aT(t,u.J).O(a)
if(u.R.b(a))return new A.bt(t,u.c).O(a)
return J.M(a)},
e3(a){return!0},
$iah:1}
A.d8.prototype={
gcm(){return 2},
bp(a1,a2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0
u.k.a(a2)
t=u.s
s=A.d(["{__buffer__}"],t)
r=A.ba(a2,!0,u.N)
B.a.aa(r,B.w.gJ())
for(q=r.length,p=0;p<r.length;r.length===q||(0,A.l)(r),++p)B.a.j(s,"{"+r[p]+"}")
for(q=this.a,o=q.length,p=0;p<q.length;q.length===o||(0,A.l)(q),++p){n=q[p]
m=this.aV(n)
k=n.a
l=k.a
j=m.a===l
i=m
h=""
while(!0){if(!(i!=null)){l=h
break}g=i.f
f=i.b
h+=g?f:i.d.P(f)
i.r=3
if(i.a===l||j){l=h
break}i=i.az()}e=A.d([l.charCodeAt(0)==0?l:l],t)
for(l=r.length,j=n.c,d=0;d<r.length;r.length===l||(0,A.l)(r),++d){c=r[d]
b=j.u(c)?j.h(0,c):null
if(B.w.u(c))B.a.j(e,B.w.h(0,c).$3(b,n,c).t(0))
else B.a.j(e,J.x(b))}for(a=a1,a0=0;a0<s.length;++a0){l=s[a0]
if(!(a0<e.length))return A.a(e,a0)
j=e[a0]
a=A.I(a,l,j)}k.y=a+"\n"
k.r=3}},
co(a){return this.bp(a,B.aq)},
aV(a){var t,s,r,q=a.a,p=q.a7()
for(t=q;p!=null;){if(p===q){p=p.a7()
continue}s=!0
if(!p.w)if(!p.x)s=A.eQ(p.b)&&!p.e
if(s)break
r=p.a7()
t=p
p=r}return t}}
A.dt.prototype={
gcm(){return 1},
Z(a,b){a.b=b
a.r=3
a.f=a.e=!0
this.aR(a)},
Y(a){var t,s,r,q,p,o,n
for(t=this.a,s=t.length,r=0;r<t.length;t.length===s||(0,A.l)(t),++r){q=t[r].a
p=q.cf(new A.f2())
if(p==null)throw A.c(A.cb("Unable to find a next element. Invalid DELTA on '"+q.U()+"'. Maybe your delta code does not end with a newline?"))
o=q.f
n=q.b
o=o?n:q.d.P(n)
p.z.n(0,q.a,o)}}}
A.f2.prototype={
$1(a){return!a.e},
$S:1}
A.eP.prototype={
F(a){var t=this.e.h(0,a.gcm())
t.toString
t=t.h(0,a.gci())
t.toString
t.n(0,A.ie(a),a)},
cs(){return this.c},
bs(a){var t
if(a>=0&&a<this.d.length){t=this.d
if(!(a>=0&&a<t.length))return A.a(t,a)
t=t[a]}else t=null
return t},
d9(a7){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=this,a5="<!-- <![CDATA[NEWLINE]]> -->",a6=A.d([],u.I)
for(t=J.J(a7),s=u.S,r=u.N,q=u.s,p=u.c9,o=u.f,n=u.z,m=0;t.m();){l=t.gq()
if(!o.b(l)||!l.u("insert"))continue
k=J.aa(l)
j=a4.dr(k.h(l,"insert"))
i=p.a(k.h(l,"attributes"))
if(i==null)i=A.u(r,n)
if(typeof j=="string"&&j===a5){k=A.d([],q)
B.a.j(a6,new A.ar(m,"",i,a4,!0,!0,A.u(s,r),k));++m
continue}h=a4.d8(j)
g=a4.dq(h)
k=g===h
f=!k
e=B.b.A(h,a5)
d=g.split(a5)
c=d.length
for(b=0;b<c;){a=d[b];++b
a0=b===c
a1=a0&&f
if(e)a2=!(a0&&k)
else a2=!1
a3=A.d([],q)
B.a.j(a6,new A.ar(m,a,i,a4,a1,a2,A.u(s,r),a3));++m}}return a6},
dr(a){if(typeof a=="string")return A.I(a,"\n","<!-- <![CDATA[NEWLINE]]> -->")
return a},
d8(a){if(typeof a=="string")return a
return B.l.cd(a,null)},
dq(a){if(B.b.aN(a,"<!-- <![CDATA[NEWLINE]]> -->"))return B.b.C(a,0,a.length-28)
return a},
c0(a,b){var t,s,r
for(t=this.e.h(0,b).gW(),s=A.j(t),t=new A.ak(J.J(t.a),t.b,s.i("ak<1,2>")),s=s.y[1];t.m();){r=t.a
for(r=(r==null?s.a(r):r).gW(),r=r.gv(r);r.m();)r.gq().E(a)}},
c3(a){var t,s,r
for(t=this.e.h(0,a).gW(),s=A.j(t),t=new A.ak(J.J(t.a),t.b,s.i("ak<1,2>")),s=s.y[1];t.m();){r=t.a
for(r=(r==null?s.a(r):r).gW(),r=r.gv(r);r.m();)r.gq().Y(this)}},
e6(){var t,s,r,q,p,o=this
o.sd5(o.d9(o.cs()))
for(t=o.d,s=t.length,r=0;r<t.length;t.length===s||(0,A.l)(t),++r){q=t[r]
o.c0(q,1)
o.c0(q,2)}o.c3(1)
o.c3(2)
for(t=o.d,s=t.length,r=0,p="";r<s;++r)p+=t[r].y
return p.charCodeAt(0)==0?p:p},
P(a){var t=A.I(a,"&","&amp;")
t=A.I(t,"<","&lt;")
t=A.I(t,">","&gt;")
t=A.I(t,'"',"&quot;")
return A.I(t,"'","&#39;")},
sd5(a){this.d=u.ds.a(a)}}
A.ar.prototype={
U(){var t=this.f,s=this.b
return t?s:this.d.P(s)},
br(a,b){var t=this.c
return t.u(a)?t.h(0,a):b},
k(a){return this.br(a,null)},
bi(a){var t
if(!A.eQ(this.b))return null
t=B.l.cb(this.b,null)
return u.f.b(t)&&t.u(a)?J.jT(t,a):null},
ck(){var t,s,r,q,p=this.z,o=A.j(p).i("aj<1>"),n=A.ba(new A.aj(p,o),!0,o.i("e.E"))
B.a.cu(n)
t=A.iG(u.N)
s=new A.D("")
for(o=n.length,r=0;r<n.length;n.length===o||(0,A.l)(n),++r){q=p.h(0,n[r])
if(q==null)continue
if(t.j(0,q))s.a+=q}p=s.a
return p.charCodeAt(0)==0?p:p},
d4(a,b,c){var t,s,r,q
u.f5.a(b)
u.E.a(c)
t=a.a
for(s=this.d;!0;){t=b.$1(t)
if(t>=0&&t<s.d.length){r=s.d
if(t>>>0!==t||t>=r.length)return A.a(r,t)
q=r[t]}else q=null
if(q==null)return null
if(A.O(c.$1(q)))return q}},
cf(a){var t=this
u.gF.a(a)
if(a==null)return t.d.bs(t.a+1)
return t.d4(t,new A.fa(),a)},
az(){return this.cf(null)},
a7(){var t=this.d.bs(this.a-1)
return t},
cn(a){var t,s,r,q,p
u.E.a(a)
t=this.a+1
for(s=this.d;!0;){r=s.d
q=r.length
if(t<q){if(!(t<q))return A.a(r,t)
p=r[t]}else p=null
if(p==null)break
if(!A.O(a.$1(p)))break;++t}}}
A.fa.prototype={
$1(a){return a+1},
$S:30}
A.z.prototype={
gci(){return 1},
a6(a,b){var t
u.a.a(b)
a.r=2
A.X(A.ie(this).a,null)
t=this.a
B.a.j(t,new A.am(a,this,b,t.length))},
aR(a){return this.a6(a,B.o)},
Y(a){}}
A.d5.prototype={
E(a){var t
if(a.r===3)return
if(a.k("table")!=null)return
if(a.k("list")!=null)return
t=a.k("align")
if(typeof t=="string"&&B.a.A(this.c,t)){this.a6(a,A.F(["alignment",t],u.N,u.z))
a.r=3}},
Y(a){var t,s,r,q,p,o,n="alignment"
for(t=this.a,s=t.length,r=this.c,q=0;q<t.length;t.length===s||(0,A.l)(t),++q){p=t[q].c
o=p.u(n)?p.h(0,n):null
if(typeof o!="string"||!B.a.A(r,o))throw A.c(A.cb('An unknown alignment "'+A.i(o)+'" has been detected.'))}this.bp('<p style="text-align: {alignment};">{__buffer__}</p>',A.d(["alignment"],u.s))}}
A.d7.prototype={
E(a){var t,s,r=a.k("background")
if(typeof r=="string"&&r.length!==0){t=a.d.P(r)
s=a.U()
this.Z(a,'<span style="background-color:'+t+'">'+s+"</span>")}}}
A.d9.prototype={
E(a){if(a.k("blockquote")!=null){this.aR(a)
a.r=3}},
Y(a){this.co("<blockquote>{__buffer__}</blockquote>")}}
A.da.prototype={
E(a){if(a.k("bold")!=null)this.Z(a,"<strong>"+a.U()+"</strong>")}}
A.dd.prototype={
E(a){if(a.k("code-block")!=null){this.aR(a)
a.r=3}},
Y(a){this.co("<pre><code>{__buffer__}</code></pre>")}}
A.de.prototype={
E(a){var t,s,r=a.k("color")
if(typeof r=="string"&&r.length!==0){t=a.d.P(r)
s=a.U()
this.Z(a,'<span style="color:'+t+'">'+s+"</span>")}}}
A.dj.prototype={
E(a){var t=a.k("font")
if(typeof t=="string"&&t.length!==0)this.Z(a,this.dD(t,a))},
dD(a,b){return'<span style="font-family: '+b.d.P(a)+';">'+b.U()+"</span>"}}
A.dl.prototype={
E(a){var t=a.bi("headerImage")
if(t!=null){this.a6(a,A.F(["url",t],u.N,u.z))
a.r=3}},
Y(a){var t,s,r,q,p=this.a,o=p.length
if(o===0)return
for(t=0;t<p.length;p.length===o||(0,A.l)(p),++t){s=p[t]
r=s.c
r=r.u("url")?r.h(0,"url"):null
q=r==null?null:J.x(r)
if(q==null)q=""
if(q.length!==0){r=s.a
r.y='<div class="ql-header-image" ><img src="'+a.P(q)+'" style="height: 60px;" alt="Cabe\xe7alho"></div>'
r.r=3}}}}
A.dm.prototype={
E(a){var t=a.k("header")
if(t!=null){this.a6(a,A.F(["heading",t],u.N,u.z))
a.r=3}},
Y(a){var t,s,r,q,p,o
for(t=this.a,s=t.length,r=this.c,q=0;q<t.length;t.length===s||(0,A.l)(t),++q){p=t[q].c
o=p.u("heading")?p.h(0,"heading"):null
if(!A.i9(o)||!B.a.A(r,o))throw A.c(A.cb('An unknown heading level "'+A.i(o)+'" has been detected.'))}this.bp("<h{heading}>{__buffer__}</h{heading}>",A.d(["heading"],u.s))}}
A.dr.prototype={
E(a){var t,s,r,q,p,o,n=a.bi("image")
if(n!=null){t=a.k("width")
s=t!=null?'width="'+a.d.P(J.x(t))+'"':""
r=a.k("height")
q=r!=null?'height="'+a.d.P(J.x(r))+'"':""
p=a.d.P(J.x(n))
p=A.I('<img src="{src}" {width} {height} alt="" class="img-responsive img-fluid" />',"{src}",p)
p=A.I(p,"{width}",s)
o=A.I(p,"{height}",q)
p=A.cs("\\s+",!0)
this.Z(a,A.I(o,p," "))}}}
A.dx.prototype={
E(a){if(a.k("italic")!=null)this.Z(a,"<em>"+a.U()+"</em>")}}
A.dE.prototype={
E(a){var t,s,r,q="link",p={},o=a.k(q)
if(o!=null){t=u.N
s=A.u(t,t)
t=a.a7()
if(!J.H(t==null?null:t.k(q),o)){t=""+'<a href="{link}" target="_blank">'
s.n(0,"{link}",a.d.P(J.x(o)))}else t=""
t+="{text}"
s.n(0,"{text}",a.U())
r=a.az()
if(!J.H(r==null?null:r.k(q),o))t+="</a>"
p.a=t.charCodeAt(0)==0?t:t
s.S(0,new A.fb(p))
this.Z(a,p.a)}}}
A.fb.prototype={
$2(a,b){var t,s
A.S(a)
A.S(b)
t=this.a
s=t.a
t.a=A.I(s,a,b)},
$S:9}
A.dG.prototype={
E(a){var t=a.k("list")
if(t!=null){this.a6(a,A.F(["type",t],u.N,u.z))
a.r=3}},
Y(a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2="type"
for(t=this.a,s=t.length,r=u.s,q=u.f,p=!1,o=null,n=0;n<t.length;t.length===s||(0,A.l)(t),++n,o=c){m={}
l=t[n]
k=this.aV(l)
j=k.b.length===0&&k.z.a===0
i=""
if(!j){for(h=l.a.a,g=k;g!=null;){f=g.f
e=g.b
i+=f?e:g.d.P(e)
g.r=3
if(g.a===h)break
g=g.az()}j=!1}m.a=!1
h=l.a
h.cn(new A.fg(m))
d=m.a
c=this.d0(l)
if(p&&o!=null&&o!==c){f=""+("</"+A.i(o)+">\n")
p=!1}else f=""
e=l.c
b=e.u(a2)?e.h(0,a2):null
a=A.S(q.b(b)?b.h(0,a2):J.x(b))
a0=B.a.A(A.d(["checked","unchecked"],r),a)
if(!p){f+="<"+c
f=(a0?f+' class="list-unstyled"':f)+">\n"
p=!0}a1=m.b=0
h.cn(new A.fh(m))
e=h.c
if(e.u("indent"))a1=e.h(0,"indent")
if(j)i=f+"<li></li>"
else{f+="<li>"
if(a0){f+='<input type="checkbox" disabled'
if(a==="checked")f+=" checked"
i=f+("><label>"+(i.charCodeAt(0)==0?i:i)+"</label>")}else i=f+(i.charCodeAt(0)==0?i:i)
f=m.b
A.jk(a1)
if(f>a1)i+="<"+c+">\n"
else if(f<a1){i+="</li></"+c+"></li>\n"
if(a1-f>1)i+="</"+c+"></li>\n"}else i+="</li>\n"}if(d||l.b.a.length-1===l.d){i+="</"+c+">\n"
p=!1}h.y=i.charCodeAt(0)==0?i:i
h.r=3}},
d0(a){var t=this.d1(a)
if(t==="ordered")return"ol"
if(B.a.A(A.d(["bullet","checked","unchecked"],u.s),t))return"ul"
throw A.c(A.cb('The provided list type "'+t+'" is not a known list type (ordered or bullet).'))},
d1(a){var t=a.cg("type")
return A.S(u.f.b(t)?t.h(0,"type"):J.x(t))}}
A.fg.prototype={
$1(a){var t
if(a.k("list")!=null)return!1
t=!0
if(!a.w)if(!a.x)t=A.eQ(a.b)&&!a.e
if(t)this.a.a=!0
return!0},
$S:1}
A.fh.prototype={
$1(a){var t=a.br("indent",0)
if(a.k("list")!=null){this.a.b=A.af(t)
return!1}return!0},
$S:1}
A.e0.prototype={
E(a){var t,s=a.k("script")
if(s!=null){t=J.x(s)
if(!B.a.A(this.c,t))A.aw(A.cb('An unknown script tag "'+t+'" has been detected.'))
if(t==="super")t="sup"
this.Z(a,"<"+t+">"+a.U()+"</"+t+">")}}}
A.e1.prototype={
E(a){var t,s=a.k("size")
if(s==null)return
t=this.d7(s)
if(t.length===0)return
this.Z(a,'<span style="font-size:'+t+';">'+a.U()+"</span>")},
d7(a){var t,s,r,q=J.x(a),p=B.b.I(q).toLowerCase()
if(p.length===0)return""
t=A.cs("^\\d+(\\.\\d+)?(pt|px|em|rem|%)$",!0)
if(t.b.test(p))return p
s=B.b.I(p)
r=A.Q(s,null)
if(r==null)r=A.dW(s)
if(r!=null)return A.i(r)+"pt"
return""}}
A.e4.prototype={
E(a){if(a.k("strike")!=null)this.Z(a,"<del>"+a.U()+"</del>")}}
A.e6.prototype={
E(a){var t,s,r,q=a.k("table")
if(q!=null){t=a.a7()
s=t==null
r=s?null:t.U()
if(r==null)r=""
this.a6(a,A.F(["row",q,"text",r,"align",a.k("align")],u.N,u.z))
if(!s)t.e=!0
if(!s)t.r=3
a.r=3}},
Y(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g=null,f={},e=this.a
if(e.length===0)return
t=new A.D("")
f.a=!1
s=new A.fP(f,t)
for(r=g,q=!1,p=0,o="";p<e.length;++p){n=e[p]
o=n.c
m=o.u("row")?o.h(0,"row"):g
l=m==null?g:J.x(m)
if(l==null)l=""
m=o.u("text")?o.h(0,"text"):g
k=J.x(m==null?"":m)
j=o.u("align")?o.h(0,"align"):g
i=typeof j=="string"&&j.length!==0?' style="text-align:'+A.i(j)+';border:1px solid #000;padding:6px;"':' style="border:1px solid #000;padding:6px;"'
if(!f.a)s.$0()
if(!q){t.a+="<tr>"
r=l
q=!0}else if(r!==l){t.a+="</tr>\n<tr>"
r=l}o="<td"+i+">"+k+"</td>"
o=t.a+=o
n.a.r=3}if(q)t.a=o+"</tr>\n"
new A.fO(f,t).$0()
h=B.a.gR(e)
e=t.a
h.a.y=e.charCodeAt(0)==0?e:e}}
A.fP.prototype={
$0(){this.b.a+='<table style="border-collapse:collapse;width:100%;">\n'
this.a.a=!0},
$S:0}
A.fO.prototype={
$0(){var t=this.a
if(t.a){this.b.a+="</table>\n"
t.a=!1}},
$S:0}
A.e7.prototype={
E(a1){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=null,a0=a1.k("table-temporary")
if(a0!=null){this.a6(a1,A.F(["kind","table-start","table",a0],u.N,u.z))
a1.r=3
return}t=a1.k("table-col")
if(t!=null){this.a6(a1,A.F(["kind","col","width",u.f.b(t)?t.h(0,"width"):a],u.N,u.z))
a1.r=3
return}s=a1.k("table-cell")
if(s==null)return
r=a1.k("table-header")
q=a1.k("table-list")
p=a1.k("table-list-container")
o=a1.k("table-cell-block")
n=o==null?a:J.x(o)
if(n==null&&u.f.b(r)){o=r.h(0,"cellId")
n=o==null?a:J.x(o)}if(n==null&&u.f.b(p)){o=p.h(0,"cellId")
n=o==null?a:J.x(o)}if(n==null)n="line-"+a1.a
m=new A.fC(s,p)
l=a1.a7()
while(!0){o=!1
if(l!=null)if(!l.w)if(!l.x)o=!(A.eQ(l.b)&&!l.e)
if(!o)break
l.r=3
l=l.a7()}o=u.f
if(o.b(r)){k=A.Q(A.i(r.h(0,"value")),a)
if(k==null)k=2
j="header"}else{j=q!=null?"list":"p"
k=0}o=o.b(s)
if(o){i=s.h(0,"data-row")
h=i==null?s.h(0,"row"):i}else h=s
i=h==null?a:J.x(h)
if(i==null)i=""
g=q==null?a:J.x(q)
f=m.$1("width")
e=m.$1("rowspan")
d=m.$1("colspan")
c=m.$1("style")
if(o){o=s.h(0,"class")
if(o==null)o=s.h(0,"data-class")}else o=a
b=a1.k("align")
if(b==null){b=a1.a7()
b=b==null?a:b.k("align")}this.a6(a1,A.F(["kind","cell-block","row",i,"cellId",n,"block",j,"headerLevel",k,"listType",g,"width",f,"rowspan",e,"colspan",d,"style",c,"class",o,"align",b],u.N,u.z))
a1.r=3},
cM(a){var t,s,r,q,p,o=this.aV(a),n=new A.D("")
for(t=a.a.a,s=o;s!=null;){if(!s.e){r=s.ck()
r=n.a+=r
q=s.f
p=s.b
n.a=r+(q?p:s.d.P(p))}if(s.a===t)break
s=s.az()}t=n.a
return t.charCodeAt(0)==0?t:t},
Y(b0){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=null,a5="width",a6="headerLevel",a7="listType",a8={},a9=this.a
if(a9.length===0)return
a8.a=a8.b=null
a8.c=B.i
a8.d=!1
t=A.d([],u.s)
a8.e=a8.f=null
a8.r=a8.w=a8.x=!1
a8.y=null
s=A.d([],u.d)
r=new A.fM()
q=new A.fF(a8,new A.fN(),t)
p=new A.fH(a8,s)
o=new A.fD(a8,p)
n=new A.fE(a8,q,o)
m=new A.fG(a8,t,s)
l=new A.fJ(a8,t,r)
for(k=a9.length,j=u.N,i=u.z,h=u.Y,g=0;g<a9.length;a9.length===k||(0,A.l)(a9),++g){f=a9[g]
e=f.c
d=e.u("kind")?e.h(0,"kind"):a4
c=J.b2(d)
if(c.T(d,"table-start")){if(a8.b!=null){n.$0()
m.$0()}b=h.a(e.u("table")?e.h(0,"table"):a4)
l.$2(b==null?B.i:b,f)
f.a.r=3}else if(c.T(d,"col")){if(a8.b==null)l.$2(B.i,f)
if(!a8.d)B.a.dR(a9,new A.fK(),new A.fL(f))
B.a.j(t,r.$1(e.u(a5)?e.h(0,a5):a4))
f.a.r=3}else if(c.T(d,"cell-block")){if(a8.b==null)l.$2(B.i,f)
q.$0()
if(!a8.w){a8.b.a+="<tbody>\n"
a8.w=!0}a=A.d3(e.u("row")?e.h(0,"row"):a4)
if(a==null)a=""
a0=A.d3(e.u("cellId")?e.h(0,"cellId"):a4)
if(a0==null)a0=""
if(!a8.x||a8.f!==a){o.$0()
a8.b.a+="<tr>"
a8.x=!0
a8.f=a}if(!a8.r||a8.e!==a0){p.$0()
a8.r=!0
a8.e=a0
c=e.u(a5)?e.h(0,a5):a4
a1=e.u("rowspan")?e.h(0,"rowspan"):a4
a2=e.u("colspan")?e.h(0,"colspan"):a4
a3=e.u("style")?e.h(0,"style"):a4
a8.y=A.F(["width",c,"rowspan",a1,"colspan",a2,"style",a3,"class",e.u("class")?e.h(0,"class"):a4],i,i)}c=e.u("block")?e.h(0,"block"):a4
if(c==null)c="p"
a1=e.u(a6)?e.h(0,a6):a4
if(a1==null)a1=0
a2=e.u(a7)?e.h(0,a7):a4
e=e.u("align")?e.h(0,"align"):a4
B.a.j(s,A.F(["block",c,"headerLevel",a1,"listType",a2,"align",e,"text",this.cM(f)],j,i))
f.a.r=3}}if(a8.b!=null){n.$0()
m.$0()}}}
A.fC.prototype={
$1(a){var t=this.a,s=u.f,r=s.b(t)?t.h(0,a):null
if(r!=null)return r
t=this.b
return s.b(t)?t.h(0,a):null},
$S:2}
A.fM.prototype={
$1(a){var t=a==null?null:B.b.I(J.x(a))
if(t==null)t=""
if(t.length===0)return""
return A.dW(t)!=null?t+"px":t},
$S:15}
A.fN.prototype={
$1(a){var t
if(a==null||B.b.I(a).length===0)return null
t=A.cs("[a-zA-Z%]+",!0)
return A.dW(B.b.I(A.I(a,t,"")))},
$S:16}
A.fF.prototype={
$0(){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=null,a="width",a0="margin-left",a1=this.a
if(a1.d||a1.b==null)return
a1.d=!0
t=a1.c
s=t.h(0,"data-class")
r=A.ae(s==null?t.h(0,"class"):s)
q=A.ae(t.h(0,"border"))
p=A.ae(t.h(0,"cellspacing"))
o=A.ae(t.h(0,"style"))
o=o==null?b:B.b.I(o)
n=A.mp(o==null?"":o)
if(n.u(a)){m=this.b.$1(n.h(0,a))
if(m!=null&&m>600){n.a3(0,a)
n.n(0,a,"100%")}}if(n.u(a0))n.a3(0,a0)
s=this.c
if(s.length!==0)n.n(0,"table-layout","fixed")
l=A.ae(A.mw(n))
k=(r==null?b:r.length!==0)===!0?' class="'+A.i(r)+'"':""
j=(q==null?b:q.length!==0)===!0?' border="'+A.i(q)+'"':""
i=(p==null?b:p.length!==0)===!0?' cellspacing="'+A.i(p)+'"':""
h=A.iU("border-collapse: collapse;",l==null?"":l)
g=a1.b
f="<table"+k+j+i+' style="'+h+'">\n'
f=g.a+=f
e=s.length
if(e!==0){g.a=f+"<colgroup>"
for(d=0;d<s.length;s.length===e||(0,A.l)(s),++d){c=s[d]
g=a1.b
g.toString
f=c.length===0?"<col>":'<col style="width:'+A.i(A.ae(c))+';">'
g.a+=f}a1.b.a+="</colgroup>\n"}},
$S:0}
A.fH.prototype={
$0(){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5=null,a6="text",a7={},a8=this.a
if(!a8.r||a8.b==null)return
t=a8.y
if(t==null)t=B.i
s=A.ae(t.h(0,"width"))
r=A.ae(t.h(0,"colspan"))
q=A.ae(t.h(0,"rowspan"))
p=A.ae(t.h(0,"class"))
o=A.ae(t.h(0,"style"))
n=this.b
m=n.length
if(m===1){if(0>=m)return A.a(n,0)
l=J.H(n[0].h(0,"block"),"p")}else l=!1
if(l){if(0>=n.length)return A.a(n,0)
k=A.S(n[0].h(0,a6))
if(0>=n.length)return A.a(n,0)
j=A.ae(n[0].h(0,"align"))
i=(j==null?a5:j.length!==0)===!0?"text-align:"+A.i(j)+";":""}else{h=new A.D("")
a7.a=null
g=new A.fI(a7,h)
for(m=n.length,f=0;f<n.length;n.length===m||(0,A.l)(n),++f){e=n[f]
j=A.ae(e.h(0,"align"))
d=(j==null?a5:j.length!==0)===!0?' style="text-align:'+A.i(j)+';"':""
switch(e.h(0,"block")){case"list":c=J.H(e.h(0,"listType"),"ordered")?"ordered":"bullet"
if(a7.a!==c){g.$0()
b=c==="ordered"?"<ol>":"<ul>"
h.a+=b
a7.a=c}b="<li"+d+">"+A.i(e.h(0,a6))+"</li>"
h.a+=b
break
case"header":g.$0()
a=A.af(e.h(0,"headerLevel"))
b=""+(a<1||a>6?2:a)
b="<h"+b+d+">"+A.i(e.h(0,a6))+"</h"+b+">"
h.a+=b
break
default:g.$0()
b="<p"+d+">"+A.i(e.h(0,a6))+"</p>"
h.a+=b}}g.$0()
m=h.a
k=m.charCodeAt(0)==0?m:m
i=""}a0=A.iU("border:1px solid #000;padding:6px;",o==null?"":o)
a1=(s==null?a5:s.length!==0)===!0?' width="'+A.i(s)+'"':""
a2=(r==null?a5:r.length!==0)===!0?' colspan="'+A.i(r)+'"':""
a3=(q==null?a5:q.length!==0)===!0?' rowspan="'+A.i(q)+'"':""
a4=(p==null?a5:p.length!==0)===!0?' class="'+A.i(p)+'"':""
m=a8.b
b="<td"+a1+a2+a3+a4+(' style="'+i+a0+'"')+">"+k+"</td>"
m.a+=b
B.a.aj(n)
a8.y=null
a8.r=!1
a8.e=null},
$S:0}
A.fI.prototype={
$0(){var t,s=this.a,r=s.a
if(r!=null){t=this.b
r=r==="ordered"?"</ol>":"</ul>"
t.a+=r
s.a=null}},
$S:0}
A.fD.prototype={
$0(){this.b.$0()
var t=this.a
if(t.x){t.b.a+="</tr>\n"
t.x=!1}},
$S:0}
A.fE.prototype={
$0(){var t=this.a
if(t.b!=null){this.b.$0()
this.c.$0()
if(t.w){t.b.a+="</tbody>\n"
t.w=!1}t.b.a+="</table>\n"}},
$S:0}
A.fG.prototype={
$0(){var t,s=this.a,r=s.a
if(r!=null&&s.b!=null){r=r.a
t=s.b.a
r.y=t.charCodeAt(0)==0?t:t
r.r=3}s.a=s.b=null
s.c=B.i
s.d=!1
B.a.aj(this.b)
s.e=s.f=null
s.r=s.w=s.x=!1
s.y=null
B.a.aj(this.c)},
$S:0}
A.fJ.prototype={
$2(a,b){var t,s,r,q,p=this.a
p.b=new A.D("")
p.a=b
p.c=a
p.d=!1
t=this.b
B.a.aj(t)
s=a.h(0,"col-widths")
if(u.j.b(s))for(r=J.J(s),q=this.c;r.m();)B.a.j(t,q.$1(r.gq()))
p.x=p.w=!1
p.e=p.f=null},
$S:12}
A.fK.prototype={
$1(a){return J.H(u.ao.a(a).cg("kind"),"col")},
$S:18}
A.fL.prototype={
$0(){return this.a},
$S:19}
A.ea.prototype={
gci(){return 2},
E(a){if(a.r!==3)this.aR(a)},
Y(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f="</p>\n"
for(t=this.a,s=t.length,r=u.s,q=u.k,p=!1,o=0;o<t.length;t.length===s||(0,A.l)(t),++o){n=t[o].a
if(n.r!==3){m=n.c
m=!m.gD(m)&&!n.e}else m=!1
if(m){n.r=3
l=n.az()
k=n.a7()
j=A.d([],r)
i=!1
if(!p){B.a.j(q.a(j),"<p>")
p=!0}if(n.b.length===0&&n.z.a===0)m="<br>"
else{m=n.ck()
h=n.f
g=n.b
m+=h?g:n.d.P(g)}B.a.j(j,m)
if(p&&l!=null&&!l.e){B.a.j(q.a(j),f)
p=i}else if(p&&l==null){B.a.j(q.a(j),f)
p=i}else if(p&&k!=null&&k.e&&n.w){B.a.j(q.a(j),f)
p=i}else if(n.b.length===0&&n.z.a===0&&l!=null&&l.r!==3){B.a.j(q.a(j),"</p>\n<p>")
p=!0}else if(p&&n.w){B.a.j(q.a(j),f)
p=i}if(l!=null&&l.e&&!p&&!n.w){B.a.j(q.a(j),"<p>")
p=!0}n.y=B.a.ae(j,"")}}}}
A.eb.prototype={
E(a){if(a.k("underline")!=null)this.Z(a,"<u>"+a.U()+"</u>")}}
A.ef.prototype={
E(a){var t,s,r=a.bi("video")
if(r!=null){t=a.d.P(J.x(r))
t=A.I('<div class="embed-responsive embed-responsive-16by9"><iframe class="embed-responsive-item" src="{url}" frameborder="0" allow="{allow}" allowfullscreen></iframe></div>\n',"{url}",t)
s=B.a.ae(this.c,"; ")
a.y=A.I(t,"{allow}",s)
a.r=3}}}
A.am.prototype={
cg(a){var t=this.c
return t.u(a)?t.h(0,a):null}}
A.hu.prototype={
$1(a){return B.b.I(A.S(a)).length!==0},
$S:11}
A.hF.prototype={
$2(a,b){B.a.j(this.a,A.S(a)+": "+A.S(b))},
$S:9}
A.dh.prototype={
aB(){var t=A.hQ(this.a,!0,u.p),s=A.U(t),r=s.i("al<1,n<f,@>>")
return A.ba(new A.al(t,s.i("n<f,@>(1)").a(new A.eS()),r),!0,r.i("L.E"))},
gp(a){return this.a.length},
T(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.dh))return!1
return B.al.N(this.a,b.a)},
gL(a){return A.iK(this.a)},
t(a){return B.a.ae(this.a,"\n")}}
A.eR.prototype={
$1(a){return A.ko(u.f.a(a),this.a)},
$S:21}
A.eS.prototype={
$1(a){return u.p.a(a).aB()},
$S:22}
A.a5.prototype={
gbf(){var t=this.d
if(t==null)t=null
else t=A.dF(t,u.N,u.z)
return t},
aB(){var t=this,s=t.a,r=A.F([s,s==="insert"?t.c:t.b],u.N,u.z)
if(t.d!=null)r.n(0,"attributes",t.gbf())
return r},
T(a,b){var t=this
if(b==null)return!1
if(t===b)return!0
if(!(b instanceof A.a5))return!1
return t.a===b.a&&t.b==b.b&&B.D.N(t.c,b.c)&&t.dU(b)},
dU(a){var t=this.d,s=t==null?null:t.a===0
if(s!==!1){s=a.d
s=s==null?null:s.a===0
s=s!==!1}else s=!1
if(s)return!0
return B.D.N(t,a.d)},
gL(a){var t,s,r=this,q=r.d,p=q==null
if(!p)t=q.a!==0
else t=!1
if(t){s=A.iK((p?u.a.a(q):q).gdN().bn(0,new A.fq(),u.O))
q=r.a
return A.dQ(q,q==="insert"?r.c:r.b,s,B.f)}q=r.a
return A.dQ(q,q==="insert"?r.c:r.b,B.f,B.f)},
t(a){var t,s,r=this,q=r.gbf()==null?"":" + "+A.i(r.gbf()),p=r.a
if(p==="insert"){t=r.c
if(typeof t=="string"){t=A.I(t,"\n","\u23ce")
s=t}else{t=J.x(t)
s=t}}else s=A.i(r.b)
return p+"\u27e8 "+s+" \u27e9"+q},
gp(a){return this.b}}
A.fq.prototype={
$1(a){u.e1.a(a)
return A.dQ(a.a,a.b,B.f,B.f)},
$S:23}
A.eZ.prototype={
bX(a){var t=a.a
t=t==null?null:t.a
if(t==null){t=this.a.dK("paragraph")
t=t==null?null:t.a}return t},
bo(a){var t,s,r,q,p=this.a,o=p.b
if(o==null)o=B.b7
for(p=p.aL(this.bX(a)),t=p.length,s=0;s<p.length;p.length===t||(0,A.l)(p),++s){r=p[s].r
if(r!=null)o=o.al(r)}q=a.a
return q!=null?o.al(q):o},
af(a,b){var t,s,r,q,p=this.a,o=p.a
if(o==null)o=B.b8
for(t=p.aL(this.bX(a)),s=t.length,r=0;r<t.length;t.length===s||(0,A.l)(t),++r){q=t[r].w
if(q!=null)o=o.al(q)}t=b==null
if((t?null:b.a)!=null)for(p=p.aL(b.a),s=p.length,r=0;r<p.length;p.length===s||(0,A.l)(p),++r){q=p[r].w
if(q!=null)o=o.al(q)}return!t?o.al(b):o},
e7(a){var t,s,r,q,p=null,o=a.a,n=o==null,m=n?p:o.d
if(m!=null)return m
o=n?p:o.a
o=this.a.aL(o)
n=o.length
t=p
s=0
for(;s<n;++s){r=o[s].x
q=r==null?p:r.d
if(q!=null)t=q}return t}}
A.h2.prototype={}
A.fX.prototype={}
A.ek.prototype={}
A.h1.prototype={}
A.cB.prototype={}
A.fV.prototype={}
A.bg.prototype={
al(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e=a.a
if(e==null)e=f.a
t=a.b
if(t==null)t=f.b
s=a.c
if(s==null)s=f.c
r=a.d
if(r==null)r=f.d
q=a.e
if(q==null)q=f.e
p=a.f
if(p==null)p=f.f
o=a.r
if(o==null)o=f.r
n=a.w
if(n==null)n=f.w
m=a.x
if(m==null)m=f.x
l=a.y
if(l==null)l=f.y
k=a.z
if(k==null)k=f.z
j=a.Q
if(j==null)j=f.Q
i=a.as
if(i==null)i=f.as
h=a.at
if(h==null)h=f.at
g=a.ax
return new A.bg(e,t,s,r,q,p,o,n,m,l,k,j,i,h,g==null?f.ax:g)}}
A.fY.prototype={}
A.be.prototype={
al(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e=a.a
if(e==null)e=f.a
t=a.b
if(t==null)t=f.b
s=a.c
if(s==null)s=f.c
r=a.d
if(r==null)r=f.d
q=a.e
if(q==null)q=f.e
p=a.f
if(p==null)p=f.f
o=a.r
if(o==null)o=f.r
n=a.w
if(n==null)n=f.w
m=a.x
if(m==null)m=f.x
l=a.y
if(l==null)l=f.y
k=a.z
if(k==null)k=f.z
j=a.Q
if(j==null)j=f.Q
i=a.as
if(i==null)i=f.as
h=a.at
if(h==null)h=f.at
g=a.ax
return new A.be(e,t,s,r,q,p,o,n,m,l,k,j,i,h,g==null?f.ax:g)}}
A.a_.prototype={}
A.au.prototype={}
A.cG.prototype={}
A.bG.prototype={}
A.cE.prototype={}
A.cF.prototype={}
A.cD.prototype={}
A.bH.prototype={}
A.bK.prototype={}
A.bO.prototype={}
A.bQ.prototype={}
A.aW.prototype={}
A.bf.prototype={
gan(){var t=u.ap
return A.dH(new A.a6(this.b,t),t.i("f(e.E)").a(new A.fZ()),t.i("e.E"),u.N).bl(0)}}
A.fZ.prototype={
$1(a){return u.dH.a(a).a},
$S:24}
A.bJ.prototype={}
A.bP.prototype={}
A.bN.prototype={}
A.aV.prototype={}
A.at.prototype={}
A.h6.prototype={}
A.h4.prototype={}
A.h5.prototype={}
A.h3.prototype={}
A.el.prototype={}
A.em.prototype={}
A.bi.prototype={}
A.bM.prototype={}
A.bI.prototype={}
A.h_.prototype={}
A.h0.prototype={
$1(a){var t,s,r,q,p=A.d([],u.f_)
for(t=this.a.X(a),s=t.$ti,t=new A.t(t.a(),s.i("t<1>")),s=s.c;t.m();){r=t.b
if(r==null)r=s.a(r)
q=r.k("w:type")
if(q==null)q="default"
r=r.k("r:id")
p.push(new A.bI(q,r==null?"":r))}return p},
$S:25}
A.fW.prototype={}
A.eg.prototype={}
A.ej.prototype={}
A.eh.prototype={}
A.bF.prototype={}
A.bL.prototype={}
A.aX.prototype={
aw(a,b){var t,s,r=this.b.h(0,a)
if(r==null)return null
t=r.c.h(0,b)
if(t!=null)return t
s=this.a.h(0,r.b)
return s==null?null:s.c.h(0,b)}}
A.fl.prototype={
e4(a,b){var t,s,r,q,p,o,n,m,l=this.a,k=l.aw(a,b)
if(k==null)return null
t=this.b.e5(a,new A.fm())
s=t.h(0,b)
t.n(0,b,(s==null?this.dA(a,b)-1:s)+1)
t.aS(0,new A.fn(b))
if(k.c==="bullet")return A.kn(k.d)
r=k.d
for(q=1;q<=9;++q){s="%"+q
if(!B.b.A(r,s))continue
p=q-1
o=t.h(0,p)
if(o==null){n=l.aw(a,p)
n=n==null?null:n.b
o=n==null?1:n}t.n(0,p,o)
n=l.aw(a,p)
m=n==null?null:n.c
n=A.m5(o,m==null?"decimal":m)
r=A.I(r,s,n)}return r},
dA(a,b){var t=this.a.aw(a,b)
t=t==null?null:t.b
return t==null?1:t}}
A.fm.prototype={
$0(){var t=u.S
return A.u(t,t)},
$S:40}
A.fn.prototype={
$2(a,b){A.af(a)
A.af(b)
return a>this.a},
$S:39}
A.eT.prototype={
dW(a,b){var t,s=this.a,r=s.aA(b).aK(a)
if(r==null||r.d)return null
t=s.aT(b,r.c)
if(B.b.a0(t,"/"))t=B.b.G(t,1)
return s.a.cj(t)},
dX(a,b){var t,s=this.a,r=s.aA(b).aK(a)
if(r==null||r.d)return null
t=s.aT(b,r.c)
if(B.b.a0(t,"/"))t=B.b.G(t,1)
return s.b.ea(t)}}
A.eU.prototype={
dn(b5){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2="word/settings.xml",b3=A.kS(b5),b4=b3.am("[Content_Types].xml")
if(b4==null)A.aw(B.a8)
t=u.N
s=new A.fo(b3,A.k5(b4),A.u(t,u.at))
r=s.gce()
q=b3.am(B.b.a0(r,"/")?B.b.G(r,1):r)
if(q==null)throw A.c(A.dk("Parte principal ausente: "+r,null,null))
p=A.cI()
o=u.v
A.cJ(q,new A.av(p,A.d([],o)))
n=u.C
m=new A.a6(p.b,n).gak(0).l("w:body")
if(m==null)throw A.c(B.ae)
l=B.b.aO(q,"<w:body>")
k=B.b.bm(q,"</w:body>")
if(l<0||k<0)throw A.c(B.ac)
B.b.C(q,0,l+8)
B.b.G(q,k)
j=A.kF(m.l("w:sectPr"))
i=this.b8(m,B.aL)
h=A.iv(s,"word/styles.xml",A.my(),A.mx(),u.fw)
g=A.iv(s,"word/numbering.xml",A.mo(),A.mn(),u.eS)
f=b3.am(B.b.a0(b2,"/")?B.b.G(b2,1):b2)
if(f==null)p=null
else{p=A.cI()
A.cJ(f,new A.av(p,A.d([],o)))
p=new A.a6(p.b,n).gak(0)}A.kG(p)
p=u.cf
e=A.u(t,p)
d=A.u(t,p)
if(j!=null){c=s.aA(r)
for(t=[new A.bV(j.Q,e,"w:hdr"),new A.bV(j.as,d,"w:ftr")],p=u.m,b=this.a,a=0;a<2;++a){a0=t[a]
a1=a0.b
a2=a0.c
for(a0=J.J(a0.a);a0.m();){a3=a0.gq()
a4=a3.b
a5=c.aK(a4)
if(a5==null){B.a.j(b,"refer\xeancia de header/footer sem rel: "+a4)
continue}a6=s.aT(r,a5.c)
a7=b3.am(B.b.a0(a6,"/")?B.b.G(a6,1):a6)
if(a7==null){B.a.j(b,"parte de header/footer ausente: "+a6)
continue}a4=A.d([],p)
a8=A.d([],o)
a9=a7.length
if(a9!==0){if(0>=a9)return A.a(a7,0)
a9=a7.charCodeAt(0)===65279}else a9=!1
b0=a9?1:0
a9=b0===0?a7:B.b.G(a7,b0)
new A.er(a9,new A.av(new A.eo(a4),a8)).bZ()
b1=new A.a6(a4,n).gv(0)
if(!b1.m())A.aw(A.f3())
a4=b1.gq()
a8=a4.b
if(a8!==a2)B.a.j(b,"raiz inesperada em "+a6+": "+a8)
a1.n(0,a3.a,new A.eg(a6,this.bY(a4)))}}}return new A.eT(s,new A.fW(i,j),h,g,e,d)},
b8(a,b){var t,s,r,q,p,o,n
u.cq.a(b)
t=A.d([],u.F)
for(s=B.a.gv(a.d),r=new A.a7(s,u.y),q=this.a,p=u.X;r.m();){o=p.a(s.gq())
n=o.b
if(b.A(0,n))continue
$label0$1:{if("w:p"===n){B.a.j(t,this.df(o))
break $label0$1}if("w:tbl"===n){B.a.j(t,this.di(o))
break $label0$1}B.a.j(q,"bloco preservado: "+n)
o.a4(new A.D(""))
B.a.j(t,new A.bM(n))}}return t},
bY(a){return this.b8(a,B.aO)},
df(a){var t,s,r,q,p,o,n,m,l,k,j,i,h=A.d([],u.fL)
for(t=B.a.gv(a.d),s=new A.a7(t,u.y),r=u.X,q=u.f0,p=null;s.m();){o=r.a(t.gq())
n=o.b
if("w:pPr"===n){p=A.hY(o)
continue}if("w:r"===n){B.a.j(h,this.b9(o))
continue}if("w:hyperlink"===n){m=o.k("r:id")
l=o.k("w:anchor")
k=A.d([],q)
for(o=o.X("w:r"),j=o.$ti,o=new A.t(o.a(),j.i("t<1>")),j=j.c;o.m();){i=o.b
k.push(this.b9(i==null?j.a(i):i))}B.a.j(h,new A.bJ(m,l,k))
continue}if("w:fldSimple"===n){m=o.k("w:instr")
if(m==null)m=""
l=A.d([],q)
for(o=o.X("w:r"),k=o.$ti,o=new A.t(o.a(),k.i("t<1>")),k=k.c;o.m();){j=o.b
l.push(this.b9(j==null?k.a(j):j))}B.a.j(h,new A.bP(m,l))
continue}o.a4(new A.D(""))
B.a.j(h,new A.bN(n))}a.aC()
return new A.at(p,h)},
b9(a){var t,s,r,q,p,o,n,m,l=A.d([],u.gK)
for(t=B.a.gv(a.d),s=new A.a7(t,u.y),r=u.X,q=null;s.m();){p=r.a(t.gq())
o=p.b
if("w:rPr"===o){q=A.ei(p)
continue}if("w:t"===o){n=new A.D("")
p.aG(n)
p=n.a
B.a.j(l,new A.au(p.charCodeAt(0)==0?p:p))
continue}if("w:tab"===o){B.a.j(l,new A.cG())
continue}if("w:br"===o){B.a.j(l,new A.bG(p.k("w:type")))
continue}if("w:cr"===o){B.a.j(l,new A.bG(null))
continue}if("w:noBreakHyphen"===o){B.a.j(l,new A.cE())
continue}if("w:softHyphen"===o)continue
if("w:sym"===o){p.k("w:font")
B.a.j(l,new A.cF(p.k("w:char")))
continue}if("w:drawing"===o){B.a.j(l,this.dc(p))
continue}if("w:fldChar"===o){p=p.k("w:fldCharType")
B.a.j(l,new A.bH(p==null?"begin":p))
continue}if("w:instrText"===o){n=new A.D("")
p.aG(n)
p=n.a
B.a.j(l,new A.bK(p.charCodeAt(0)==0?p:p))
continue}if("w:lastRenderedPageBreak"===o)continue
if("mc:AlternateContent"===o){m=this.dj(p)
if(m==null){p.a4(new A.D(""))
p=new A.bO(o)}else p=m
B.a.j(l,p)
continue}p.a4(new A.D(""))
B.a.j(l,new A.bO(o))}return new A.bf(q,l)},
dj(a0){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=null,d="wp:posOffset",c="a:srgbClr",b=a0.ad("wps:wsp"),a=b.$ti
b=new A.t(b.a(),a.i("t<1>"))
$loop$0:{if(b.m()){b=b.b
t=b==null?a.c.a(b):b
break $loop$0}else t=e}if(t==null)return e
b=t.ad("w:txbxContent")
a=b.$ti
b=new A.t(b.a(),a.i("t<1>"))
$loop$1:{if(b.m()){b=b.b
s=b==null?a.c.a(b):b
break $loop$1}else s=e}if(s==null)return e
b=a0.ad("wp:anchor")
a=b.$ti
b=new A.t(b.a(),a.i("t<1>"))
$loop$2:{if(b.m()){b=b.b
r=b==null?a.c.a(b):b
break $loop$2}else r=e}q=e
if(r!=null){p=r.l("wp:positionH")
b=p==null
if(!b){a=p.l("wp:align")
q=a==null?e:B.b.I(a.gan())}if(b)b=e
else{b=p.l(d)
b=b==null?e:B.b.I(b.gan())}A.Q(b==null?"":b,e)
o=r.l("wp:positionV")
if(o==null)b=e
else{b=o.l(d)
b=b==null?e:B.b.I(b.gan())}n=A.Q(b==null?"":b,e)
m=r.l("wp:extent")
b=m==null
a=b?e:m.k("cx")
l=A.Q(a==null?"":a,e)
b=b?e:m.k("cy")
k=A.Q(b==null?"":b,e)}else{k=e
l=k
n=l}j=t.l("wps:spPr")
i=e
h=e
if(j!=null){g=j.l("a:ln")
b=g==null
a=b?e:g.k("w")
f=A.Q(a==null?"":a,e)
if(!b){b=g.ad(c)
a=b.$ti
b=new A.t(b.a(),a.i("t<1>"))
$loop$3:{if(b.m()){b=b.b
i=(b==null?a.c.a(b):b).k("val")
break $loop$3}}}b=j.l("a:solidFill")
if(!(b==null)){b=b.l(c)
h=b==null?e:b.k("val")}}else f=e
b=this.bY(s)
a0.aC()
return new A.bQ(q,n,l,k,f,i,h,b)},
dc(a){var t,s,r,q,p=null,o=a.l("wp:inline"),n=a.l("wp:anchor"),m=o==null,l=m?n:o,k=l==null?p:l.l("wp:extent")
for(t=a.ad("a:blip"),s=t.$ti,t=new A.t(t.a(),s.i("t<1>")),s=s.c,r=p;t.m();){q=t.b
if(q==null)q=s.a(q)
r=q.k("r:embed")
if(r==null)r=q.k("r:link")
if(r!=null)break}if(n!=null)B.a.j(this.a,"drawing flutuante (anchor) tratado como inline")
t=k==null
s=t?p:k.k("cx")
s=A.dW(s==null?"":s)
t=t?p:k.k("cy")
return new A.cD(r,s,A.dW(t==null?"":t),!m,a.aC())},
di(a){var t,s,r,q,p,o,n,m,l,k=A.d([],u.t),j=A.d([],u.cB)
for(t=B.a.gv(a.d),s=new A.a7(t,u.y),r=this.a,q=u.X,p=null;s.m();){o=q.a(t.gq())
n=o.b
if("w:tblPr"===n){p=A.j2(o)
continue}if("w:tblGrid"===n){for(o=o.X("w:gridCol"),m=o.$ti,o=new A.t(o.a(),m.i("t<1>")),m=m.c;o.m();){l=o.b
l=(l==null?m.a(l):l).k("w:w")
l=A.Q(l==null?"":l,null)
B.a.j(k,l==null?0:l)}continue}if("w:tr"===n){B.a.j(j,this.dg(o))
continue}B.a.j(r,"filho de tabela ignorado: "+n)}a.aC()
return new A.bi(p,k,j)},
dg(a){var t,s,r,q,p,o,n,m,l,k=A.d([],u.cz)
for(t=B.a.gv(a.d),s=new A.a7(t,u.y),r=this.a,q=u.X,p=null;s.m();){o=q.a(t.gq())
n=o.b
if("w:trPr"===n){p=A.kK(o)
continue}if("w:tc"===n){m=o.l("w:tcPr")
l=m!=null?A.kJ(m):null
B.a.j(k,new A.el(l,this.b8(o,B.aM)))
continue}if("w:tblPrEx"===n){B.a.j(r,"tblPrEx ignorado em linha de tabela")
continue}B.a.j(r,"filho de linha ignorado: "+n)}return new A.em(p,k)}}
A.bh.prototype={}
A.aY.prototype={
dK(a){var t,s,r
for(t=this.c.gW(),s=A.j(t),t=new A.ak(J.J(t.a),t.b,s.i("ak<1,2>")),s=s.y[1];t.m();){r=t.a
if(r==null)r=s.a(r)
if(r.f&&r.b===a)return r}return null},
aL(a){var t,s=A.d([],u.d5),r=A.iG(u.N),q=a==null?null:this.c.h(0,a),p=this.c
while(!0){if(!(q!=null&&r.j(0,q.a)))break
B.a.dY(s,0,q)
t=q.d
q=t==null?null:p.h(0,t)}return s}}
A.eO.prototype={
ea(a){var t,s=B.b.a0(a,"/")?a:"/"+a,r=this.b.h(0,s)
if(r!=null)return r
t=B.b.bm(s,".")
if(t<0)return null
return this.a.h(0,B.b.G(s,t+1).toLowerCase())}}
A.fo.prototype={
aA(a){var t,s,r,q,p,o,n,m
if(a==null)t="_rels/.rels"
else{s=B.b.a0(a,"/")?B.b.G(a,1):a
r=B.b.bm(s,"/")
q=r<0
p=q?"":B.b.C(s,0,r+1)
s=q?s:B.b.G(s,r+1)
t=p+"_rels/"+s+".rels"}q=this.c
o=q.h(0,t)
if(o!=null)return o
n=this.a.am(t)
m=n==null?A.iO():A.ky(n)
q.n(0,t,m)
return m},
aT(a,b){var t,s,r,q,p,o,n
if(B.b.a0(b,"/"))return B.b.G(b,1)
if(a==null)t=""
else{s=B.b.a0(a,"/")?B.b.G(a,1):a
r=A.cs("[^/]+$",!0)
A.kw(0,0,s.length,"startIndex")
t=A.mu(s,r,"",0)}s=A.ba(new A.bE(A.d(t.split("/"),u.s),u.bB.a(new A.fp()),u.U),!0,u.N)
for(r=b.split("/"),q=r.length,p=0;p<q;++p){o=r[p]
if(o===".."){n=s.length
if(n!==0){if(0>=n)return A.a(s,-1)
s.pop()}}else if(o!=="."&&o.length!==0)B.a.j(s,o)}return B.a.ae(s,"/")},
gce(){var t=this.aA(null).dQ("http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument")
if(t==null)throw A.c(B.ad)
return this.aT(null,t.c)}}
A.fp.prototype={
$1(a){return A.S(a).length!==0},
$S:11}
A.dY.prototype={
t(a){var t=this,s=t.d?", external":""
return"Relationship("+t.a+", "+t.b+", "+t.c+s+")"}}
A.dZ.prototype={
aK(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(q.a===a)return q}return null},
dQ(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(q.b===a)return q}return null}}
A.aH.prototype={
aC(){var t,s=new A.D("")
this.a4(s)
t=s.a
return t.charCodeAt(0)==0?t:t}}
A.cK.prototype={
a4(a){var t=A.kO(this.b)
a.a+=t
return null}}
A.cH.prototype={
a4(a){var t=a.a+="<![CDATA["
t+=this.b
a.a=t
a.a=t+"]]>"}}
A.en.prototype={
a4(a){var t=a.a+="<!--"
t+=this.b
a.a=t
a.a=t+"-->"}}
A.ep.prototype={
a4(a){var t=a.a+="<?"+this.b,s=this.c
if(s!=null&&s.length!==0)t=a.a=t+(" "+A.i(s))
a.a=t+"?>"}}
A.aZ.prototype={
t(a){return this.a+'="'+this.b+'"'}}
A.a8.prototype={
cI(a,b,c){var t,s
for(t=this.d.length,s=0;s<t;++s);},
k(a){var t,s,r,q
for(t=this.c,s=t.length,r=0;r<s;++r){q=t[r]
if(q.a===a)return q.b}return null},
l(a){var t,s,r,q
for(t=this.d,s=t.length,r=0;r<s;++r){q=t[r]
if(q instanceof A.a8&&q.b===a)return q}return null},
X(a){return new A.bn(this.dG(a),u.x)},
dG(a){var t=this
return function(){var s=a
var r=0,q=1,p,o,n,m,l
return function $async$X(b,c,d){if(c===1){p=d
r=q}while(true)switch(r){case 0:o=t.d,n=o.length,m=0
case 2:if(!(m<o.length)){r=4
break}l=o[m]
r=l instanceof A.a8&&l.b===s?5:6
break
case 5:r=7
return b.b=l,1
case 7:case 6:case 3:o.length===n||(0,A.l)(o),++m
r=2
break
case 4:return 0
case 1:return b.c=p,3}}}},
ad(a){return new A.bn(this.dL(a),u.x)},
dL(a){var t=this
return function(){var s=a
var r=0,q=1,p,o,n,m,l
return function $async$ad(b,c,d){if(c===1){p=d
r=q}while(true)switch(r){case 0:o=t.d,n=o.length,m=0
case 2:if(!(m<o.length)){r=4
break}l=o[m]
r=l instanceof A.a8?5:6
break
case 5:r=l.b===s?7:8
break
case 7:r=9
return b.b=l,1
case 9:case 8:r=10
return b.dC(l.ad(s))
case 10:case 6:case 3:o.length===n||(0,A.l)(o),++m
r=2
break
case 4:return 0
case 1:return b.c=p,3}}}},
gan(){var t,s=new A.D("")
this.aG(s)
t=s.a
return t.charCodeAt(0)==0?t:t},
aG(a){var t,s,r,q
for(t=this.d,s=t.length,r=0;r<t.length;t.length===s||(0,A.l)(t),++r){q=t[r]
if(q instanceof A.cK)a.a+=q.b
if(q instanceof A.cH)a.a+=q.b
if(q instanceof A.a8)q.aG(a)}},
a4(a){var t,s,r,q,p=a.a+="<",o=this.b
p=a.a=p+o
for(t=this.c,s=t.length,r=0;r<t.length;t.length===s||(0,A.l)(t),++r){q=t[r]
p+=" "
a.a=p
p+=q.a
a.a=p
a.a=p+'="'
p=A.kN(q.b)
p=a.a+=p
p+='"'
a.a=p}t=this.d
s=t.length
if(s===0){a.a=p+"/>"
return}a.a=p+">"
for(r=0;r<t.length;t.length===s||(0,A.l)(t),++r)t[r].a4(a)
p=a.a+="</"
o=p+o
a.a=o
a.a=o+">"}}
A.eo.prototype={}
A.av.prototype={
bx(a,b,c){var t,s,r,q
u.fb.a(b)
if(b.length===0)t=null
else{t=A.U(b)
s=t.i("al<1,aZ>")
s=A.ba(new A.al(b,t.i("aZ(1)").a(new A.hb()),s),!0,s.i("L.E"))
t=s}s=t==null?A.d([],u.av):t
r=A.d([],u.m)
q=new A.a8(a,s,r)
q.cI(a,t,null)
t=this.b
if(t.length===0)B.a.j(this.a.b,q)
else B.a.j(B.a.gR(t).d,q)
B.a.j(t,q)},
dF(a){var t=this.b
if(t.length===0)return
B.a.j(B.a.gR(t).d,new A.cK(a))},
dE(a){var t=this.b
if(t.length===0)return
B.a.j(B.a.gR(t).d,new A.cH(a))}}
A.hb.prototype={
$1(a){u.fN.a(a)
return new A.aZ(a.a,a.b)},
$S:28}
A.b_.prototype={
t(a){return this.a+'="'+this.b+'"'}}
A.eq.prototype={}
A.h7.prototype={}
A.er.prototype={
bZ(){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=this,a1=a0.a,a2=a1.length
for(t=a0.b,s=t.a.b,r=t.b,q=0,p=!1;o=a0.c,o<a2;){if(!(o>=0))return A.a(a1,o)
if(a1.charCodeAt(o)===60){n=o+1
if(n>=a2)throw A.c(A.E("Documento termina dentro de tag",a1,o))
m=a1.charCodeAt(n)
if(m===47){l=a0.de();--q
if(q<0)throw A.c(A.E("Tag de fechamento sem abertura: </"+l+">",a1,a0.c))
if(0>=r.length)return A.a(r,-1)
r.pop()}else if(m===33)if(B.b.aF(a1,"<!--",o)){n=o+4
k=B.b.ab(a1,"-->",n)
if(k<0)A.aw(A.E("Coment\xe1rio n\xe3o terminado",a1,o))
j=new A.en(B.b.C(a1,n,k))
if(r.length===0)B.a.j(s,j)
else B.a.j(B.a.gR(r).d,j)
a0.c=k+3}else if(B.b.aF(a1,"<![CDATA[",o)){if(q===0)throw A.c(A.E("CDATA fora do elemento raiz",a1,o))
n=o+9
k=B.b.ab(a1,"]]>",n)
if(k<0)A.aw(A.E("CDATA n\xe3o terminado",a1,o))
t.dE(B.b.C(a1,n,k))
a0.c=k+3}else if(B.b.aF(a1,"<!DOCTYPE",o))a0.dw()
else throw A.c(A.E('Marca\xe7\xe3o "<!" desconhecida',a1,o))
else if(m===63){n=o+2
k=B.b.ab(a1,"?>",n)
if(k<0)A.aw(A.E("Processing instruction n\xe3o terminada",a1,o))
i=B.b.C(a1,n,k)
a0.c=k+2
h=A.kQ(i)
n=h<0
g=n?i:B.b.C(i,0,h)
f=n?null:B.b.I(B.b.G(i,h+1))
if(g.toLowerCase()==="xml"){if(o!==0)A.aw(A.E("Declara\xe7\xe3o XML fora do in\xedcio do documento",a1,a0.c))
e=A.kR(f==null?"":f)
e.h(0,"version")
e.h(0,"encoding")
e.h(0,"standalone")}else{j=new A.ep(g,f)
if(r.length===0)B.a.j(s,j)
else B.a.j(B.a.gR(r).d,j)}}else{if(q===0&&p)throw A.c(A.E("Mais de um elemento raiz no documento",a1,o))
if(!a0.dh())++q
p=!0}}else{d=B.b.ab(a1,"<",o)
k=d<0?a2:d
if(q>0){c=a0.cW(a1,o,k)
if(c.length!==0)t.dF(c)}else for(b=o;b<k;++b){if(!(b<a2))return A.a(a1,b)
a=a1.charCodeAt(b)
if(a!==32&&a!==9&&a!==10&&a!==13)throw A.c(A.E("Texto fora do elemento raiz",a1,b))}a0.c=k}}if(q!==0)throw A.c(A.E("Elemento n\xe3o fechado no fim do documento",a1,a2===0?0:a2-1))
if(!p)throw A.c(A.E("Documento sem elemento raiz",a1,0))},
dh(){var t,s,r,q,p,o,n,m,l,k,j=this,i='Valor do atributo "',h=j.a,g=h.length,f=j.c,e=f+1,d=e
while(!0){if(d<g){if(!(d>=0))return A.a(h,d)
t=h.charCodeAt(d)
t=!(t===32||t===9||t===10||t===13||t===62||t===47||t===61)}else t=!1
if(!t)break;++d}if(d===e)throw A.c(A.E("Nome de elemento vazio",h,f))
s=B.b.C(h,e,d)
for(f=u.u,e=d,r=null;!0;){e=j.aH(e)
if(e>=g)throw A.c(A.E("Tag n\xe3o terminada: <"+s,h,j.c))
if(!(e>=0))return A.a(h,e)
q=h.charCodeAt(e)
if(q===62){j.c=e+1
f=r==null?B.L:r
j.b.bx(s,f,!1)
return!1}if(q===47){f=e+1
if(f<g){if(!(f<g))return A.a(h,f)
f=h.charCodeAt(f)!==62}else f=!0
if(f)throw A.c(A.E('Esperado "/>" na tag <'+s,h,e))
j.c=e+2
f=j.b
f.bx(s,r==null?B.L:r,!0)
f=f.b
if(0>=f.length)return A.a(f,-1)
f.pop()
return!0}for(d=e;d<g;){p=h.charCodeAt(d)
if(p===61||p===32||p===9||p===10||p===13||p===62||p===47)break;++d}if(d===e)throw A.c(A.E("Caractere inesperado na tag <"+s,h,d))
o=B.b.C(h,e,d)
e=j.aH(d)
if(e<g){if(!(e>=0&&e<g))return A.a(h,e)
t=h.charCodeAt(e)!==61}else t=!0
if(t)throw A.c(A.E('Atributo "'+o+'" sem "=" na tag <'+s,h,e))
e=j.aH(e+1)
if(e>=g)throw A.c(A.E("Valor de atributo ausente",h,e-1))
if(!(e>=0))return A.a(h,e)
n=h.charCodeAt(e)
t=n===34
if(!t&&n!==39)throw A.c(A.E(i+o+'" sem aspas',h,e))
m=e+1
l=B.b.ab(h,t?'"':"'",m)
if(l<0)throw A.c(A.E(i+o+'" n\xe3o terminado',h,e))
k=j.cV(h,m,l)
if(r==null){r=A.d([],f)
t=r}else t=r
B.a.j(t,new A.b_(o,k))
e=l+1}},
de(){var t,s,r=this,q=r.a,p=q.length,o=r.c+2,n=o
while(!0){if(n<p){if(!(n>=0))return A.a(q,n)
t=q.charCodeAt(n)
t=!(t===32||t===9||t===10||t===13||t===62||t===47||t===61)}else t=!1
if(!t)break;++n}s=B.b.C(q,o,n)
o=r.aH(n)
if(o<p){if(!(o>=0&&o<p))return A.a(q,o)
t=q.charCodeAt(o)!==62}else t=!0
if(t)throw A.c(A.E("Tag </"+s+" n\xe3o terminada",q,r.c))
r.c=o+1
return s},
dw(){var t,s,r,q=this,p=q.a,o=p.length,n=q.c+9
for(t=0;n<o;){if(!(n>=0))return A.a(p,n)
s=p.charCodeAt(n)
if(s===34||s===39){r=B.b.ab(p,A.p(s),n+1)
if(r<0)break
n=r+1
continue}if(s===91)++t
if(s===93)--t
if(s===62&&t<=0){q.c=n+1
return}++n}throw A.c(A.E("DOCTYPE n\xe3o terminado",p,q.c))},
aH(a){var t,s=this.a,r=s.length
for(;a<r;){if(!(a>=0))return A.a(s,a)
t=s.charCodeAt(a)
if(t!==32&&t!==9&&t!==10&&t!==13)break;++a}return a},
cW(a,b,c){var t,s,r,q,p,o=a.length,n=b
while(!0){if(!(n<c)){t=!1
break}if(!(n>=0&&n<o))return A.a(a,n)
s=a.charCodeAt(n)
if(s===38||s===13){t=!0
break}++n}if(!t)return B.b.C(a,b,c)
r=new A.D("")
for(n=b;n<c;){if(!(n>=0&&n<o))return A.a(a,n)
s=a.charCodeAt(n)
if(s===38)n=this.bM(a,n,c,r)
else if(s===13){q=A.p(10)
r.a+=q
p=n+1
if(p<c){if(!(p<o))return A.a(a,p)
q=a.charCodeAt(p)===10}else q=!1
n=(q?p:n)+1}else{q=A.p(s)
r.a+=q;++n}}o=r.a
return o.charCodeAt(0)==0?o:o},
cV(a,b,c){var t,s,r,q,p,o=a.length,n=b
while(!0){if(!(n<c)){t=!1
break}if(!(n>=0&&n<o))return A.a(a,n)
s=a.charCodeAt(n)
if(s===38||s===9||s===10||s===13){t=!0
break}++n}if(!t)return B.b.C(a,b,c)
r=new A.D("")
for(n=b;n<c;){if(!(n>=0&&n<o))return A.a(a,n)
s=a.charCodeAt(n)
if(s===38)n=this.bM(a,n,c,r)
else if(s===9||s===10||s===13){q=A.p(32)
r.a+=q
q=!1
if(s===13){p=n+1
if(p<c){if(!(p<o))return A.a(a,p)
q=a.charCodeAt(p)===10}}n=(q?n+1:n)+1}else{q=A.p(s)
r.a+=q;++n}}o=r.a
return o.charCodeAt(0)==0?o:o},
bM(a,b,c,d){var t,s,r,q,p,o,n=b+1,m=B.b.ab(a,";",n)
if(m<0||m>=c||m-b>12)throw A.c(A.E("Refer\xeancia de entidade malformada",a,b))
t=a.length
if(!(n>=0&&n<t))return A.a(a,n)
if(a.charCodeAt(n)===35){s=b+2
if(!(s>=0&&s<t))return A.a(a,s)
r=a.charCodeAt(s)===120||a.charCodeAt(s)===88
if(r)t=b+3
else t=s
q=B.b.C(a,t,m)
p=A.Q(q,r?16:10)
if(p==null)throw A.c(A.E("Refer\xeancia de caractere inv\xe1lida: &"+B.b.C(a,n,m)+";",a,b))
n=A.p(p)
d.a+=n
return m+1}o=B.b.C(a,n,m)
$label0$0:{if("amp"===o){n=A.p(38)
d.a+=n
break $label0$0}if("lt"===o){n=A.p(60)
d.a+=n
break $label0$0}if("gt"===o){n=A.p(62)
d.a+=n
break $label0$0}if("quot"===o){n=A.p(34)
d.a+=n
break $label0$0}if("apos"===o){n=A.p(39)
d.a+=n
break $label0$0}throw A.c(A.E("Entidade desconhecida: &"+o+";",a,b))}return m+1}}
A.f_.prototype={
cH(a){var t,s,r,q,p,o,n,m,l,k,j,i,h=this,g=a.length
for(t=0;t<g;++t){s=a[t]
if(s>h.b)h.b=s
if(s<h.c)h.c=s}s=h.b
r=B.c.aE(1,s)
q=h.a=new Uint32Array(r)
for(p=1,o=0,n=2;p<=s;){for(m=p<<16,t=0;t<g;++t)if(a[t]===p){for(l=o,k=0,j=0;j<p;++j){k=(k<<1|l&1)>>>0
l=l>>>1}for(i=(m|t)>>>0,j=k;j<r;j+=n){if(!(j>=0))return A.a(q,j)
q[j]=i}++o}++p
o=o<<1>>>0
n=n<<1>>>0}}}
A.f1.prototype={
ga1(){var t=this.a
if(t==null)return t
t.d===$&&A.bY()
return t},
d2(){var t,s,r=this
r.e=r.d=0
if(r.ga1()==null)return
while(!0){t=r.ga1()
s=t.c
t=t.d
t===$&&A.bY()
if(!(s<t))break
if(!r.da())return}},
da(){var t,s,r,q=this,p=q.ga1()
if(p!=null){t=p.c
s=p.d
s===$&&A.bY()
s=t>=s
t=s}else t=!0
if(t)return!1
r=q.V(3)
switch(B.c.bc(r,1)){case 0:if(q.dk()===-1)return!1
break
case 1:if(q.bN(q.r,q.w)===-1)return!1
break
case 2:if(q.dd()===-1)return!1
break
default:return!1}return(r&1)===0},
V(a){var t,s,r,q,p=this
if(a===0)return 0
for(;t=p.e,t<a;){t=p.ga1()
s=t.c
t=t.d
t===$&&A.bY()
if(s>=t)return-1
t=p.ga1()
s=t.b
s.toString
t=t.c++
if(!(t>=0&&t<s.length))return A.a(s,t)
r=s[t]
t=p.d
s=p.e
p.d=(t|B.c.aE(r,s))>>>0
p.e=s+8}s=p.d
q=B.c.dv(1,a)
p.d=B.c.bb(s,a)
p.e=t-a
return(s&q-1)>>>0},
ba(a){var t,s,r,q,p,o,n,m=this,l=a.a
l===$&&A.bY()
t=a.b
for(;s=m.e,s<t;){s=m.ga1()
r=s.c
s=s.d
s===$&&A.bY()
if(r>=s)return-1
s=m.ga1()
r=s.b
r.toString
s=s.c++
if(!(s>=0&&s<r.length))return A.a(r,s)
q=r[s]
s=m.d
r=m.e
m.d=(s|B.c.aE(q,r))>>>0
m.e=r+8}r=m.d
p=(r&B.c.aE(1,t)-1)>>>0
if(!(p<l.length))return A.a(l,p)
o=l[p]
n=o>>>16
m.d=B.c.bb(r,n)
m.e=s-n
return o&65535},
dk(){var t,s,r,q=this
q.e=q.d=0
t=q.V(16)
s=q.V(16)
if(t!==0&&t!==(s^65535)>>>0)return-1
if(t>q.ga1().gp(0))return-1
s=q.ga1()
r=s.cz(t,s.c)
s.c=s.c+r.gp(0)
q.c.ed(r)
return 0},
dd(){var t,s,r,q,p,o,n,m,l,k,j=this,i=j.V(5)
if(i===-1)return-1
i+=257
if(i>288)return-1
t=j.V(5)
if(t===-1)return-1;++t
if(t>32)return-1
s=j.V(4)
if(s===-1)return-1
s+=4
if(s>19)return-1
r=new Uint8Array(19)
for(q=0;q<s;++q){p=j.V(3)
if(p===-1)return-1
o=B.ao[q]
if(!(o<19))return A.a(r,o)
r[o]=p}n=A.dn(r)
o=i+t
m=new Uint8Array(o)
l=J.bZ(B.e.gai(m),0,i)
k=J.bZ(B.e.gai(m),i,t)
if(j.cU(o,n,m)===-1)return-1
return j.bN(A.dn(l),A.dn(k))},
bN(a,b){var t,s,r,q,p,o,n,m,l=this
for(t=l.c;!0;){s=l.ba(a)
if(s<0||s>285)return-1
if(s===256)break
if(s<256){if(t.b===t.c.length)t.cY()
r=t.c
q=t.b++
r.$flags&2&&A.T(r)
if(!(q>=0&&q<r.length))return A.a(r,q)
r[q]=s&255
continue}p=s-257
if(!(p>=0&&p<29))return A.a(B.M,p)
o=B.M[p]+l.V(B.an[p])
n=l.ba(b)
if(n<0||n>29)return-1
if(!(n>=0&&n<30))return A.a(B.K,n)
m=B.K[n]+l.V(B.as[n])
for(r=-m;o>m;){t.bq(t.bz(r))
o-=m}if(o===m)t.bq(t.bz(r))
else t.bq(t.bA(r,o-m))}for(;t=l.e,t>=8;){l.e=t-8
t=l.ga1()
r=--t.c
q=t.d
q===$&&A.bY()
t.sdl(B.c.ca(r,0,q))}return 0},
cU(a,b,c){var t,s,r,q,p,o,n,m,l=this
for(t=0,s=0;s<a;){r=l.ba(b)
if(r===-1)return-1
q=0
switch(r){case 16:p=l.V(2)
if(p===-1)return-1
p+=3
for(o=c.$flags|0;n=p-1,p>0;p=n,s=m){m=s+1
o&2&&A.T(c)
if(!(s>=0&&s<c.length))return A.a(c,s)
c[s]=t}break
case 17:p=l.V(3)
if(p===-1)return-1
p+=3
for(o=c.$flags|0;n=p-1,p>0;p=n,s=m){m=s+1
o&2&&A.T(c)
if(!(s>=0&&s<c.length))return A.a(c,s)
c[s]=0}t=q
break
case 18:p=l.V(7)
if(p===-1)return-1
p+=11
for(o=c.$flags|0;n=p-1,p>0;p=n,s=m){m=s+1
o&2&&A.T(c)
if(!(s>=0&&s<c.length))return A.a(c,s)
c[s]=0}t=q
break
default:if(r<0||r>15)return-1
m=s+1
c.$flags&2&&A.T(c)
if(!(s>=0&&s<c.length))return A.a(c,s)
c[s]=r
s=m
t=r
break}}return 0}}
A.eL.prototype={
ac(){return"ByteOrder."+this.b}}
A.du.prototype={
gp(a){var t=this.b
return t==null?0:t.length-this.c},
cz(a,b){var t=this.b
if(t==null)return A.hM(A.d([],u.t),B.C,null,null)
return A.hM(t,this.a,a,b)},
sdl(a){this.c=A.af(a)}}
A.dv.prototype={}
A.dS.prototype={
bq(a){var t,s,r,q,p,o=this
u.L.a(a)
t=a.length
for(;s=o.b,r=s+t,q=o.c,p=q.length,r>p;)o.b3(r-p)
B.e.bu(q,s,r,a)
o.b+=t},
ed(a){var t,s,r,q,p,o,n=this
while(!0){t=n.b
s=a.b
r=s==null
q=r?0:s.length-a.c
p=n.c
o=p.length
if(!(t+q>o))break
n.b3(t+(r?0:s.length-a.c)-o)}if(!r){s=a.gp(0)
r=a.b
r.toString
B.e.aD(p,t,t+s,r,a.c)}n.b=n.b+a.gp(0)},
bA(a,b){var t=this
if(a<0)a=t.b+a
if(b==null)b=t.b
else if(b<0)b=t.b+b
return J.bZ(B.e.gai(t.c),t.c.byteOffset+a,b-a)},
bz(a){return this.bA(a,null)},
b3(a){var t=a!=null?a>32768?a:32768:32768,s=this.c,r=s.length,q=new Uint8Array((r+t)*2)
B.e.bu(q,0,r,s)
this.c=q},
cY(){return this.b3(null)},
gp(a){return this.b}}
A.dT.prototype={}
A.es.prototype={
gdH(){var t,s,r,q,p,o=this,n=o.w
if(n!=null)return n
t=o.d
t.toString
s=o.e
if(s===0)r=new Uint8Array(A.i6(t))
else if(s===8){s=o.r
q=A.dn(B.at)
p=A.dn(B.ar)
t=A.hM(t,B.C,null,null)
s=new A.dS(new Uint8Array(s))
new A.f1(t,s,q,p).d2()
r=J.bZ(B.e.gai(s.c),s.c.byteOffset,s.b)}else throw A.c(A.bD("ZIP compression method "+s+" is not supported."))
return o.w=r}}
A.h8.prototype={
cj(a){var t,s=this.b.h(0,a)
if(s==null)t=null
else{t=this.a
if(s>>>0!==s||s>=t.length)return A.a(t,s)
t=t[s]}return t==null?null:t.gdH()},
am(a){var t=this.cj(a)
if(t==null)return null
return B.H.av(A.cy(t,t.length>=3&&t[0]===239&&t[1]===187&&t[2]===191?3:0,null))}}
A.a2.prototype={
ac(){return"ElementType."+this.b}}
A.bA.prototype={
ac(){return"RowFlex."+this.b}}
A.e8.prototype={
ac(){return"TableBorder."+this.b}}
A.bc.prototype={
ac(){return"TdBorder."+this.b}}
A.aU.prototype={
ac(){return"TitleLevel."+this.b}}
A.b7.prototype={}
A.dp.prototype={}
A.dq.prototype={}
A.b8.prototype={}
A.c5.prototype={}
A.eV.prototype={
cZ(b2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0=null,b1="NUMPAGES"
for(t=b2.b,s=t.length,r=this.b,q=0;q<t.length;t.length===s||(0,A.l)(t),++q){p=t[q]
if(!(p instanceof A.at))continue
o=new A.D("")
for(n=p.b,m=n.length,l=b0,k=!1,j=B.h,i="",h=0;h<n.length;n.length===m||(0,A.l)(n),++h){g=n[h]
f=g instanceof A.bP
e=f?g:b0
if(f){d=e.a.toUpperCase()
c=!0
if(B.b.A(d,b1)){o.a+="{pageCount}"
k=c}else if(B.b.A(d,"PAGE")){o.a+="{pageNo}"
k=c}else for(f=e.b,b=f.length,a=0;a<f.length;f.length===b||(0,A.l)(f),++a){a0=f[a]
a1=a0.gan()
o.a+=a1
if(l==null)l=r.af(p,a0.a)}continue}f=g instanceof A.bf
a0=f?g:b0
if(f){for(f=a0.b,b=f.length,a1=a0.a,a=0;a<f.length;f.length===b||(0,A.l)(f),++a){a2=f[a]
a3=a2 instanceof A.bH
a4=a3?a2:b0
if(a3){$label0$2:{a5=a4.a
if("begin"===a5){j=B.k
i=""
break $label0$2}if("separate"===a5){j=B.U
break $label0$2}d=i.toUpperCase()
c=!0
if(B.b.A(d,b1)){o.a+="{pageCount}"
k=c}else if(B.b.A(d,"PAGE")){o.a+="{pageNo}"
k=c}j=B.h}continue}a3=a2 instanceof A.bK
d=a3?a2:b0
if(a3){if(j===B.k)i+=d.a
continue}a3=a2 instanceof A.au
a6=a3?a2:b0
if(a3){if(j===B.h){a3=a6.a
o.a+=a3
if(l==null)l=r.af(p,a1)}continue}continue}continue}f=g instanceof A.bJ
a7=f?g:b0
if(f){for(f=a7.c,b=f.length,a1=j===B.h,a=0;a<f.length;f.length===b||(0,A.l)(f),++a){a0=f[a]
if(a1){a3=a0.gan()
o.a+=a3
if(l==null)l=r.af(p,a0.a)}}continue}if(g instanceof A.bN)continue}if(!k)continue
a8=r.bo(p)
a9=l==null?r.af(p,b0):l
t=o.a
t=t.charCodeAt(0)==0?t:t
B.a.j(this.d,'campos PAGE/NUMPAGES do rodap\xe9 renderizados dinamicamente (formato "'+t+'")')
s=A.hK(a8.c)
r=a9.z
r=r==null?b0:B.d.ag(r*2/3)
n=a9.b
if(n==null)n=a9.c
return new A.hk(t,s,r,n,A.hJ(a9.Q),A.kl([p],u.eO))}return b0},
bI(a,b,c){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this,d=null
u.Q.a(a)
t=A.d([],u.l)
for(s=e.d,r=e.b,q=!0,p=0;p<a.length;++p){o=a[p]
n=t.length
$label0$0:{m=o instanceof A.at
l=m?o:d
k=!1
if(m){j=r.bo(l)
if(!q)B.a.j(t,e.bW(l,j))
B.a.aa(t,e.bJ(l,j,b))
q=k
break $label0$0}m=o instanceof A.bi
i=m?o:d
if(m){if(!q)B.a.j(t,A.Z(d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,"\n",d,d))
h=e.bK(i,b)
if(h!=null)B.a.j(t,h)
q=k
break $label0$0}m=o instanceof A.bM
g=m?o:d
if(m)B.a.j(s,"bloco preservado n\xe3o renderizado: "+g.a)}if(c)for(f=n;f<t.length;++f)A.hL(t[f],p)}return t},
aZ(a,b){return this.bI(a,b,!1)},
cR(a,a0,a1){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=null
u.Q.a(a)
u.aI.a(a1)
t=A.d([],u.l)
for(s=a.length,r=c.d,q=c.b,p=!0,o=0;o<a.length;a.length===s||(0,A.l)(a),++o){n=a[o]
m=n instanceof A.at
l=m?n:b
k=!1
if(m){j=q.bo(l)
if(!p)B.a.j(t,c.bW(l,j))
i=c.bJ(l,j,a0)
if(a1.A(0,l)){h=i.length
for(g=h-1;g>=0;--g)if(i[g].c==="\n"){h=g
break}i=B.a.cw(i,0,h)}B.a.aa(t,i)
p=k
continue}m=n instanceof A.bi
f=m?n:b
if(m){if(!p)B.a.j(t,A.Z(b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,"\n",b,b))
e=c.bK(f,a0)
if(e!=null)B.a.j(t,e)
p=k
continue}m=n instanceof A.bM
d=m?n:b
if(m)B.a.j(r,"bloco de rodap\xe9 preservado n\xe3o renderizado: "+d.a)}if(t.length===0)B.a.j(t,A.Z(b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,"",b,b))
return t},
dB(a){var t,s,r,q,p,o,n,m=null
u.g.a(a)
for(t=a.$flags|0,s=0,r=0;q=a.length,r<=q;++r){if(r!==q){if(!(r>=0&&r<q))return A.a(a,r)
p=a[r].c==="\n"}else p=!0
if(!p)continue
q=this.bS(a,s,r)
if(this.d6(B.b.I(A.I(q,"\xa0"," ")))){if(s>0){q=s-1
if(!(q<a.length))return A.a(a,q)
q=a[q].c==="\n"}else q=!1
o=q?s-1:s
q=a.length
n=r<q?r+1:r
t&1&&A.T(a,18)
A.cq(o,n,q)
a.splice(o,n-o)
r=o-1
s=o
continue}s=r+1}if(q===0)B.a.j(a,A.Z(m,m,m,m,m,m,m,m,m,m,m,m,m,m,m,m,m,"",m,m))},
bS(a,b,c){var t,s,r,q,p
u.g.a(a)
t=new A.D("")
for(s=b;s<c;++s){if(!(s>=0&&s<a.length))return A.a(a,s)
r=a[s]
q=r.b
if(q==null||q===B.t||q===B.u||q===B.r)t.a+=r.c
p=r.y1
if(p!=null){q=this.bS(p,0,p.length)
t.a+=q}}q=t.a
return q.charCodeAt(0)==0?q:q},
d6(a){var t
if(a.length===0)return!1
t=A.cs("^(?:P\xe1gina|Page)\\s+\\d+\\s*(?:\\||/|de|of)\\s*\\d+$",!1)
return t.b.test(a)},
bW(a,b){var t,s=null,r=this.b.af(a,s),q=r.z,p=A.hK(b.c),o=r.b
if(o==null)o=r.c
t=A.Z(s,s,s,s,s,o,s,s,s,s,p,q==null?s:B.d.ag(q*2/3),s,s,s,s,s,"\n",s,s)
A.c6(t,this.bV(b))
return t},
bJ(b0,b1,b2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=this,a4=null,a5=A.hK(b1.c),a6=a3.bV(b1),a7=u.l,a8=A.d([],a7),a9=b1.b
if(a9!=null){t=a9.a
t=t!=null&&t!==0}else t=!1
if(t){t=a9.a
t.toString
s=a3.c.e4(t,a9.b)
if(s!=null&&s.length!==0)B.a.j(a8,a3.aI(A.i(s)+"\t",a3.b.af(b0,a4),a5,a6))}for(t=b0.b,r=t.length,q=a3.d,p=a3.a.a,o=B.h,n=0;n<t.length;t.length===r||(0,A.l)(t),++n){m=t[n]
l=m instanceof A.bf
k=l?m:a4
if(l){o=a3.b_(b0,k,a8,o,a5,a6,b2)
continue}l=m instanceof A.bJ
j=l?m:a4
if(l){i=A.d([],a7)
for(l=j.c,h=l.length,g=B.h,f=0;f<l.length;l.length===h||(0,A.l)(l),++f)g=a3.b_(b0,l[f],i,g,a4,a6,b2)
if(i.length===0)continue
l=j.a
if(l!=null){e=p.aA(b2).aK(l)
d=e!=null&&e.d?e.c:a4}else{l=j.b
d=l!=null?"#"+l:a4}c=A.Z(a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a5,a4,a4,a4,B.r,a4,d==null?"":d,"",i,a4)
A.c6(c,a6)
B.a.j(a8,c)
continue}l=m instanceof A.bP
b=l?m:a4
if(l){B.a.j(q,"fldSimple com resultado em cache: "+B.b.I(b.a))
for(l=b.b,h=l.length,a=B.h,f=0;f<l.length;l.length===h||(0,A.l)(l),++f)a=a3.b_(b0,l[f],a8,a,a5,a6,b2)
continue}l=m instanceof A.bN
a0=l?m:a4
if(l)if(a0.a==="mc:AlternateContent")B.a.j(q,"text box (carimbo) preservado, sem render (placeholder na Fase 4.8)")}a1=b1.at
if(a1!=null&&a1>=0&&a8.length!==0){a2=A.Z(a4,a4,a4,a4,a4,a4,a4,a4,a4,A.k8(a1),a5,a4,a4,a4,B.m,a4,a4,"",a8,a4)
A.c6(a2,a6)
return A.d([a2],a7)}return a8},
b_(a4,a5,a6,a7,a8,a9,b0){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=this,a3=null
u.g.a(a6)
t=a2.b.af(a4,a5.a)
for(s=a5.b,r=s.length,q=a2.d,p=a2.e,o=u.cH,n=a7,m=0;m<s.length;s.length===r||(0,A.l)(s),++m){l=s[m]
k=l instanceof A.bH
j=k?l:a3
if(k){i=j.a
$label0$0:{if("begin"===i){k=B.k
break $label0$0}if("separate"===i){k=B.U
break $label0$0}k=B.h
break $label0$0}n=k
continue}k=l instanceof A.bK
h=k?l:a3
if(k){if(n===B.k)B.a.j(q,"campo com resultado em cache: "+B.b.I(h.a)+" (motor de campos na Fase 4.7)")
continue}k=l instanceof A.au
g=k?l:a3
if(k){if(n!==B.k&&g.a.length!==0)B.a.j(a6,a2.aI(g.a,t,a8,a9))
continue}if(l instanceof A.cG){f=A.Z(a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a8,a3,a3,a3,B.a6,a3,a3,"",a3,a3)
A.c6(f,a9)
B.a.j(a6,f)
continue}k=l instanceof A.bG
e=k?l:a3
if(k){if(e.a==="page")B.a.j(a6,A.Z(a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,B.J,a3,a3,"",a3,a3))
else{d=A.Z(a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,"\n",a3,a3)
A.c6(d,a9)
B.a.j(a6,d)}continue}if(l instanceof A.cE){B.a.j(a6,a2.aI("\u2011",t,a8,a9))
continue}k=l instanceof A.cF
c=k?l:a3
if(k){B.a.j(a6,a2.aI(A.k7(c),t,a8,a9))
continue}k=l instanceof A.cD
b=k?l:a3
if(k){a=a2.cQ(b,b0)
if(a!=null)B.a.j(a6,a)
continue}k=l instanceof A.bQ
a0=k?l:a3
if(k){B.a.j(q,"text box (carimbo) renderizado como caixa flutuante (edi\xe7\xe3o direta fica para F4.8)")
a2.aZ(o.a(a0).x,b0)
B.a.j(p,new A.c5())
continue}k=l instanceof A.bO
a1=k?l:a3
if(k){k=a1.a
if(k==="mc:AlternateContent"||k==="w:pict")B.a.j(q,"shape preservado, sem render (Fase 4.8): "+k)}}return n},
aI(a,b,c,d){var t,s,r,q,p=null,o=b.z,n=b.r,m=b.as,l=m!=null?B.au.h(0,m):A.iw(b.at)
m=b.x===!0?a.toUpperCase():a
t=b.b
if(t==null)t=b.c
s=o==null?p:B.d.ag(o*2/3)
r=n!=null&&n!=="none"?!0:p
q=A.Z(b.e,p,p,p,A.hJ(b.Q),t,p,l,b.f,p,c,s,b.w,p,p,r,p,m,p,p)
A.c6(q,d)
m=b.ax
if(m==="superscript")q.b=B.t
else if(m==="subscript")q.b=B.u
return q},
cQ(a,b){var t,s,r,q,p,o=this,n=null,m=a.a
if(m==null){B.a.j(o.d,"drawing sem blip embed ignorado")
return n}t=o.a
s=t.dW(m,b)
if(s==null){B.a.j(o.d,"imagem n\xe3o encontrada para rel "+m+" de "+b)
return n}r=t.dX(m,b)
if(r==null)r="image/png"
if(!a.d)B.a.j(o.d,"imagem flutuante renderizada como inline (Fase 4)")
u.aM.i("a1.S").a(s)
t=B.V.gbh().au(s)
q=a.b
q=q==null?100:q/9525
p=a.c
p=p==null?100:p/9525
q=A.Z(n,n,n,n,n,n,p,n,n,n,n,n,n,n,B.I,n,n,"data:"+r+";base64,"+t,n,q)
t=u.N
A.F(["wpDrawing",a.e],t,t)
return q},
bK(b0,b1){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8=null,a9=b0.c
if(a9.length===0)return a8
t=A.d([],u.eU)
for(s=b0.b,r=s.length,q=0;q<s.length;s.length===r||(0,A.l)(s),++q)t.push(new A.dp(s[q]/15))
p=A.d([],u.gL)
for(s=a9.length,r=u.t,q=0;q<a9.length;a9.length===s||(0,A.l)(a9),++q){o=a9[q]
n=A.d([],r)
for(m=o.b,l=m.length,k=0,j=0;j<m.length;m.length===l||(0,A.l)(m),++j){i=m[j]
B.a.j(n,k)
h=i.a
h=h==null?a8:h.b
k+=h==null?1:h}B.a.j(p,n)}g=new A.eX(p,b0)
f=A.d([],u.h)
for(s=u.an,e=0;e<a9.length;++e){o=a9[e]
d=o.a
if((d==null?a8:d.a)!=null){r=d.a
r.toString
c=r/15}else c=40
b=A.d([],s)
for(r=o.b,a=0;a<r.length;++a){i=r[a]
a0=i.a
m=a0==null
if((m?a8:a0.c)==="continue")continue
a1=this.cP(i.b,b1)
l=m?a8:a0.b
if(l==null)l=1
h=(m?a8:a0.c)==="restart"?g.$2(e,a):1
a2=A.iw(m?a8:a0.e)
a3=m?a8:a0.f
$label0$3:{if("center"===a3)break $label0$3
if("bottom"===a3)break $label0$3
if("top"===a3)break $label0$3
break $label0$3}this.cL(m?a8:a0.d)
B.a.j(b,new A.dq(l,h,a1,a2))}if(b.length===0)continue
r=B.d.ca(c,20,1/0)
B.a.j(f,new A.b8(r,b))}if(f.length===0)return a8
a4=this.b.e7(b0)
a9=new A.eY()
if(a4!=null)a5=A.O(a9.$1(a4.a))||A.O(a9.$1(a4.c))||A.O(a9.$1(a4.b))||A.O(a9.$1(a4.d))||A.O(a9.$1(a4.e))||A.O(a9.$1(a4.f))
else a5=!1
if(a5){a9=a4.e
a6=a9==null?a4.a:a9
if(a6==null)a6=a4.b
a7=A.hJ(a6==null?a8:a6.c)}else a7=a8
return A.Z(a8,a7,a5?B.aP:B.aQ,t,a8,a8,a8,a8,a8,a8,a8,a8,a8,f,B.n,a8,a8,"",a8,a8)},
cP(a,b){var t,s,r,q,p,o,n,m,l,k,j,i,h=null
u.Q.a(a)
t=A.d([],u.F)
for(s=a.length,r=this.d,q=0;q<a.length;a.length===s||(0,A.l)(a),++q){p=a[q]
if(p instanceof A.bi){B.a.j(r,"tabela aninhada achatada em c\xe9lula (n\xe3o suportada)")
for(o=p.c,n=o.length,m=0;m<o.length;o.length===n||(0,A.l)(o),++m)for(l=o[m].b,k=l.length,j=0;j<l.length;l.length===k||(0,A.l)(l),++j)B.a.aa(t,l[j].b)}else B.a.j(t,p)}i=this.aZ(t,b)
if(i.length===0)B.a.j(i,A.Z(h,h,h,h,h,h,h,h,h,h,h,h,h,h,h,h,h,"",h,h))
return i},
cL(a){var t,s
if(a==null)return null
t=new A.eW()
s=A.d([],u.gk)
if(A.O(t.$1(a.a)))s.push(B.aU)
if(A.O(t.$1(a.d)))s.push(B.aT)
if(A.O(t.$1(a.c)))s.push(B.aR)
if(A.O(t.$1(a.b)))s.push(B.aS)
return s.length===0?null:s},
bV(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=null,d=a.d,c=a.b
if(c!=null){t=c.a
t=t!=null&&t!==0}else t=!1
if(t){t=c.a
t.toString
t=this.a.d.aw(t,c.b)
s=t==null?e:t.f}else s=e
r=a.e
t=r==null
q=t?e:r.a
if(q==null)q=s==null?e:s.a
p=t?e:r.c
if(p==null)p=s==null?e:s.c
o=t?e:r.d
if(o==null)o=s==null?e:s.d
t=d==null
n=t?e:d.c
m=t?e:d.d
if(m==null)m="auto"
l="auto"
if(n!=null&&n>0)if(m==="atLeast"||m==="exact"){if(typeof n!=="number")return n.cr()
k=n/15
l=m}else{if(typeof n!=="number")return n.cr()
k=n/240}else k=1
if((t?e:d.a)==null)j=e
else{j=d.a
j.toString
j/=15}if((t?e:d.b)==null)t=e
else{t=d.b
t.toString
t/=15}i=q==null?e:q/15
h=p==null
g=h?0:p
f=o==null
if(g-(f?0:o)===0)h=e
else{h=h?0:p
h=(h-(f?0:o))/15}return new A.hl(l,k,j,t,i,h)}}
A.eX.prototype={
$2(a,b){var t,s,r,q,p,o,n,m,l,k,j=this.a,i=j.length
if(!(a<i))return A.a(j,a)
t=j[a]
if(!(b<t.length))return A.a(t,b)
s=t[b]
for(r=a+1,t=this.b.c,q=t.length,p=1;r<q;++r){o=t[r].b
m=o.length
l=0
while(!0){if(!(l<m)){n=!1
break}c$0:{if(!(r<i))return A.a(j,r)
k=j[r]
if(!(l<k.length))return A.a(k,l)
if(k[l]!==s)break c$0
m=o[l].a
n=(m==null?null:m.c)==="continue"
if(n)++p
break}++l}if(!n)break}return p},
$S:29}
A.eY.prototype={
$1(a){var t
if(a!=null){t=a.a
t=t!=null&&t!=="none"&&t!=="nil"}else t=!1
return t},
$S:6}
A.eW.prototype={
$1(a){var t
if(a!=null){t=a.a
t=t!=null&&t!=="none"&&t!=="nil"}else t=!1
return t},
$S:6}
A.cO.prototype={
ac(){return"_FieldState."+this.b}}
A.hk.prototype={}
A.hl.prototype={}
A.fw.prototype={
$2(a,b){var t,s,r
u.a.a(b)
if(a.length===0)return
t=u.N
s=u.z
r=A.u(t,s)
r.n(0,"insert",a)
if(b.a!==0)r.n(0,"attributes",A.dF(b,t,s))
B.a.j(this.a,r)},
$S:31}
A.fv.prototype={
$1(a){var t,s,r
u.a.a(a)
t=u.N
s=u.z
r=A.u(t,s)
r.n(0,"insert","\n")
if(a.gD(a))r.n(0,"attributes",A.dF(a,t,s))
B.a.j(this.a,r)},
$S:32}
A.fx.prototype={
$2(b7,b8){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3=this,b4="insert",b5="link",b6="attributes"
u.g.a(b7)
u.a.a(b8)
$label0$1:for(t=b7.length,s=b3.d,r=b3.c,q=u.N,p=u.z,o=b3.b,n=b3.a,m=u.f,l=u.S,k=0;k<b7.length;b7.length===t||(0,A.l)(b7),++k){j=b7[k]
switch(j.b){case B.m:i=A.fd(q,p)
i.aa(0,b8)
h=j.dP
if(h!=null)i.n(0,"header",A.ku(h))
h=j.y1
b3.$2(h==null?B.v:h,i)
if(o.length===0||!J.H(B.a.gR(o).h(0,b4),"\n"))r.$1(A.hT(j,i))
continue $label0$1
case B.q:i=A.fd(q,p)
i.aa(0,b8)
i.n(0,"list","bullet")
h=j.y1
b3.$2(h==null?B.v:h,i)
if(o.length===0||!J.H(B.a.gR(o).h(0,b4),"\n"))r.$1(A.hT(j,i))
continue $label0$1
case B.r:i=A.fd(q,p)
i.aa(0,b8)
h=j.y2
if(h!=null)i.n(0,b5,h)
h=j.y1
b3.$2(h==null?B.v:h,i)
continue $label0$1
case B.I:i=A.F(["image",j.c],q,p)
h=A.u(q,p)
g=j.w
if(g!=null)h.n(0,"width",g)
g=j.x
if(g!=null)h.n(0,"height",g)
B.a.j(o,A.F(["insert",i,"attributes",h],q,p))
continue $label0$1
case B.n:if(o.length!==0){f=B.a.gR(o).h(0,b4)
if(typeof f!="string"||!B.b.aN(f,"\n"))r.$1(B.o)}++n.a
e=j.k1
if(e==null)e=B.ap
i=j.id
h=i==null
d=h?null:i.length
if(d==null)d=B.a.dT(e,0,new A.fy(),l)
for(h=!h,c=0;c<d;++c){if(h&&c<i.length){if(!(c<i.length))return A.a(i,c)
b=i[c].b}else b=72
r.$1(A.F(["table-col",A.F(["width",""+B.d.ag(b)],q,p)],q,p))}for(a=0;a<e.length;){a0=e[a];++a
i=""+a
a1="row-t"+n.a+"-r"+i
for(h=a0.e,g=a0.d,c=0;c<h.length;){a2=h[c];++c
a3="cell-t"+n.a+"-r"+i+"-c"+c
a4=A.u(q,p)
a4.n(0,"data-row",a1)
a5=a2.x
if(a5>1)a4.n(0,"colspan",""+a5)
a5=a2.y
if(a5>1)a4.n(0,"rowspan",""+a5)
a4.n(0,"height",""+B.d.ag(g))
a5=a2.dx
if(a5!=null)a4.n(0,"style","background-color: "+a5)
a6=A.F(["table-cell-block",a3,"table-cell",a4],q,p)
a7=o.length
b3.$2(a2.z,a6)
if(!(o.length>a7&&J.H(B.a.gR(o).h(0,b4),"\n")&&m.b(B.a.gR(o).h(0,b6))&&A.kt(m.a(B.a.gR(o).h(0,b6)).bg(0,q,p))===a3))r.$1(a6)}}continue $label0$1
case B.a7:case B.J:r.$1(B.o)
continue $label0$1
default:break}i=A.u(q,p)
if(b8.u(b5))i.n(0,b5,b8.h(0,b5))
if(j.y===!0)i.n(0,"bold",!0)
if(j.as===!0)i.n(0,"italic",!0)
if(j.at===!0)i.n(0,"underline",!0)
if(j.ax===!0)i.n(0,"strike",!0)
h=j.z
if(h!=null)i.n(0,"color",h)
h=j.Q
if(h!=null)i.n(0,"background",h)
h=j.f
if(h!=null)i.n(0,"font",h)
h=j.r
if(h!=null){a8=B.d.ag(h*0.75*2)/2
i.n(0,"size",(a8===B.d.e8(a8)?""+B.d.ag(a8):B.d.t(a8))+"pt")}if(j.b===B.t)i.n(0,"script","super")
if(j.b===B.u)i.n(0,"script","sub")
a9=A.hT(j,b8)
b0=j.c
for(h=b0.length,b1=0,b2=0;b2<h;++b2)if(b0[b2]==="\n"){s.$2(B.b.C(b0,b1,b2),i)
r.$1(a9)
b1=b2+1}s.$2(B.b.G(b0,b1),i)}},
$S:33}
A.fy.prototype={
$2(a,b){var t,s,r,q
A.af(a)
for(t=u.eL.a(b).e,s=t.length,r=0,q=0;q<s;++q)r+=t[q].x
return r>a?r:a},
$S:34}
A.hC.prototype={
$1(a7){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=null,a3=u.o,a4=a3.a(a3.a(a7).data),a5=A.d3(a4.mode),a6=a5==null?a2:a5
if(a6==null)a6="delta"
t=A.iJ(u.bZ.a(a4.buffer),0,a2)
s=new A.e3()
$.il()
s.bw()
a5=u.s
r=new A.eU(A.d([],a5)).dn(t)
q=A.d([],a5)
p=A.d([],u.c3)
o=u.S
n=new A.eV(r,new A.eZ(r.c),new A.fl(r.d,A.u(o,u.bS)),q,p)
m=n.bI(r.b.a,r.a.gce(),!0)
B.a.aj(p)
l=r.x
k=l.h(0,"default")
j=r.y.h(0,"default")
if(k!=null)n.aZ(k.b,k.a)
A.hQ(p,!0,u.he)
p=j==null
i=p?a2:n.cZ(j)
if(p)h=A.d([],u.l)
else{p=j.b
g=j.a
f=i==null?a2:i.f
h=n.cR(p,g,f==null?B.aN:f)}if(i!=null)n.dB(h)
if(l.a>1)B.a.j(q,"headers first/even convertidos apenas como default (sele\xe7\xe3o por tipo na Fase 4.6)")
e=A.k6(u.j.a(A.kv(A.lN(m)).h(0,"ops")))
if(s.b==null)s.b=$.dX.$0()
if(a6==="html"){d=new A.e3()
d.bw()
q=u.dd
p=u.g9
n=u.c6
c=new A.eP(e.aB(),A.d([],u.I),A.F([1,A.F([1,A.u(q,p),2,A.u(q,p)],o,n),2,A.F([1,A.u(q,p),2,A.u(q,p)],o,n)],o,u.cb))
q=u.d_
c.F(new A.dr(A.d([],q)))
c.F(new A.dl(A.d([],q)))
c.F(new A.da(A.d([],q)))
c.F(new A.dx(A.d([],q)))
c.F(new A.de(A.d([],q)))
c.F(new A.d7(A.d([],q)))
c.F(new A.dj(A.d([],q)))
c.F(new A.e1(A.d([],q)))
c.F(new A.dE(A.d([],q)))
c.F(new A.ef(A.d(["accelerometer","autoplay","encrypted-media","gyroscope","picture-in-picture"],a5),A.d([],q)))
c.F(new A.e4(A.d([],q)))
c.F(new A.eb(A.d([],q)))
c.F(new A.dm(A.d([1,2,3,4,5,6],u.t),A.d([],q)))
c.F(new A.dd(A.d([],q)))
c.F(new A.dG(A.d([],q)))
c.F(new A.d9(A.d([],q)))
c.F(new A.e0(A.d(["super","sub"],a5),A.d([],q)))
c.F(new A.e6(A.d([],q)))
c.F(new A.e7(A.d([],q)))
c.F(new A.d5(A.d(["center","right","justify","left"],a5),A.d([],q)))
c.F(new A.ea(A.d([],q)))
c.a=!0
b=c.e6()
if(d.b==null)d.b=$.dX.$0()
a=d.gcc()
a0=b}else{a0=B.l.cd(e.aB(),a2)
a=0}a1={}
a1.mode=a6
a1.payload=a0
a1.parseMs=s.gcc()
a1.toHtmlMs=a
A.iA(a3.a(self.self),"postMessage",a1,u.O)},
$S:35};(function aliases(){var t=J.aS.prototype
t.cA=t.t
t=A.aI.prototype
t.cC=t.bH
t.cD=t.bP
t.cF=t.c4
t.cE=t.c1
t=A.y.prototype
t.cB=t.aD})();(function installTearOffs(){var t=hunkHelpers._static_2,s=hunkHelpers._static_0,r=hunkHelpers._static_1,q=hunkHelpers._instance_2u,p=hunkHelpers._instance_1u,o=hunkHelpers.installStaticTearOff
t(J,"ly","kh",36)
s(A,"lM","kq",10)
t(A,"jx","lm",3)
r(A,"jy","ln",4)
r(A,"lZ","lo",8)
r(A,"m0","mc",4)
t(A,"m_","mb",3)
var n
q(n=A.c4.prototype,"gdO","N",3)
p(n,"gdV","O",4)
p(n,"ge2","e3",14)
o(A,"mn",0,null,["$2$abstractNums$nums","$0"],["j_",function(){return A.j_(null,null)}],37,0)
r(A,"mo","kE",38)
o(A,"mx",0,null,["$3$byId$docDefaultsParagraph$docDefaultsRun","$0"],["j1",function(){return A.j1(null,null,null)}],27,0)
r(A,"my","kI",26)})();(function inheritance(){var t=hunkHelpers.mixin,s=hunkHelpers.inherit,r=hunkHelpers.inheritMany
s(A.q,null)
r(A.q,[A.hO,J.dw,J.b3,A.e,A.c1,A.o,A.aP,A.A,A.fz,A.b9,A.ak,A.cA,A.cu,A.c9,A.a7,A.V,A.aJ,A.c2,A.bl,A.ao,A.fR,A.fk,A.fc,A.ci,A.ce,A.eB,A.cL,A.e5,A.eD,A.ho,A.ad,A.ex,A.eE,A.t,A.cP,A.eA,A.cR,A.y,A.cT,A.dg,A.a1,A.h9,A.hi,A.hp,A.hc,A.dR,A.cv,A.hd,A.ai,A.aD,A.cn,A.e3,A.D,A.b6,A.bt,A.aT,A.a9,A.bS,A.bx,A.c4,A.z,A.eP,A.ar,A.am,A.dh,A.a5,A.eZ,A.h2,A.fX,A.ek,A.h1,A.cB,A.fV,A.bg,A.fY,A.be,A.a_,A.aW,A.aV,A.h6,A.h4,A.h5,A.h3,A.el,A.em,A.bI,A.h_,A.fW,A.eg,A.ej,A.eh,A.bF,A.bL,A.aX,A.fl,A.eT,A.eU,A.bh,A.aY,A.eO,A.fo,A.dY,A.dZ,A.aH,A.aZ,A.eo,A.eq,A.b_,A.er,A.f_,A.f1,A.dv,A.dT,A.es,A.h8,A.b7,A.dp,A.dq,A.b8,A.c5,A.eV,A.hk,A.hl])
r(J.dw,[J.dy,J.cd,J.cf,J.bv,J.bw,J.bu,J.aR])
r(J.cf,[J.aS,J.m,A.bz,A.ck])
r(J.aS,[J.dU,J.bd,J.aB])
s(J.f4,J.m)
r(J.bu,[J.cc,J.dz])
r(A.e,[A.bR,A.h,A.bb,A.bE,A.aE,A.a6,A.bk,A.et,A.eC,A.bn])
s(A.b4,A.bR)
s(A.cN,A.b4)
r(A.o,[A.b5,A.aC,A.aI,A.ey])
r(A.aP,[A.dc,A.db,A.e9,A.f6,A.hy,A.hA,A.he,A.ha,A.fi,A.hg,A.f2,A.fa,A.fg,A.fh,A.fC,A.fM,A.fN,A.fK,A.hu,A.eR,A.eS,A.fq,A.fZ,A.h0,A.fp,A.hb,A.eY,A.eW,A.fv,A.hC])
r(A.dc,[A.eM,A.eN,A.f5,A.hz,A.fe,A.fj,A.hj,A.fb,A.fJ,A.hF,A.fn,A.eX,A.fw,A.fx,A.fy])
r(A.A,[A.ch,A.cx,A.dA,A.ed,A.ev,A.e_,A.c_,A.ew,A.cg,A.ay,A.cz,A.ec,A.bC,A.df])
r(A.h,[A.L,A.c8,A.aj,A.bj,A.cS])
r(A.L,[A.cw,A.al,A.ct,A.ez])
s(A.c7,A.bb)
s(A.bs,A.aE)
r(A.aJ,[A.bT,A.bU])
s(A.R,A.bT)
s(A.bV,A.bU)
s(A.ag,A.c2)
r(A.ao,[A.c3,A.cY])
s(A.aA,A.c3)
r(A.db,[A.fs,A.hr,A.hq,A.fP,A.fO,A.fF,A.fH,A.fI,A.fD,A.fE,A.fG,A.fL,A.fm])
s(A.co,A.cx)
r(A.e9,[A.e2,A.br])
s(A.eu,A.c_)
r(A.ck,[A.dI,A.P])
r(A.P,[A.cU,A.cW])
s(A.cV,A.cU)
s(A.cj,A.cV)
s(A.cX,A.cW)
s(A.a4,A.cX)
r(A.cj,[A.dJ,A.dK])
r(A.a4,[A.dL,A.dM,A.dN,A.dO,A.dP,A.cl,A.cm])
s(A.cZ,A.ew)
r(A.aI,[A.cQ,A.cM])
s(A.bm,A.cY)
r(A.dg,[A.hn,A.eK,A.f8,A.f7,A.fU])
r(A.a1,[A.c0,A.di,A.dB])
s(A.dC,A.cg)
s(A.hh,A.hi)
r(A.di,[A.dD,A.ee])
s(A.f9,A.hn)
r(A.ay,[A.cp,A.ds])
s(A.bB,A.a9)
r(A.z,[A.d8,A.dt])
r(A.d8,[A.d5,A.d9,A.dd,A.dl,A.dm,A.dG,A.e6,A.e7,A.ea,A.ef])
r(A.dt,[A.d7,A.da,A.de,A.dj,A.dr,A.dx,A.dE,A.e0,A.e1,A.e4,A.eb])
r(A.a_,[A.au,A.cG,A.bG,A.cE,A.cF,A.cD,A.bH,A.bK,A.bO,A.bQ])
r(A.aW,[A.bf,A.bJ,A.bP,A.bN])
r(A.aV,[A.at,A.bi,A.bM])
r(A.aH,[A.cK,A.cH,A.en,A.ep,A.a8])
s(A.av,A.eq)
s(A.h7,A.ai)
r(A.hc,[A.eL,A.a2,A.bA,A.e8,A.bc,A.aU,A.cO])
s(A.du,A.dv)
s(A.dS,A.dT)
t(A.cU,A.y)
t(A.cV,A.V)
t(A.cW,A.y)
t(A.cX,A.V)})()
var v={typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{b:"int",r:"double",ab:"num",f:"String",C:"bool",cn:"Null",k:"List",q:"Object",n:"Map"},mangledNames:{},types:["~()","C(ar)","@(f)","C(q?,q?)","b(q?)","~(q?,q?)","C(cB?)","@()","@(@)","~(f,f)","b()","C(f)","~(n<@,@>,am)","C(@)","C(q?)","f(@)","r?(f?)","@(@,f)","C(am)","am()","~(@,@)","a5(@)","n<f,@>(a5)","b(aD<f,@>)","f(au)","k<bI>(f)","aY(f)","aY({byId:n<f,bh>?,docDefaultsParagraph:be?,docDefaultsRun:bg?})","aZ(b_)","b(b,b)","b(b)","~(f,n<f,@>)","~(n<f,@>)","~(k<b7>,n<f,@>)","b(b,b8)","~(K)","b(@,@)","aX({abstractNums:n<b,bF>?,nums:n<b,bL>?})","aX(f)","C(b,b)","n<b,b>()"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;":(a,b)=>c=>c instanceof A.R&&a.b(c.a)&&b.b(c.b),"3;":(a,b,c)=>d=>d instanceof A.bV&&a.b(d.a)&&b.b(d.b)&&c.b(d.c)}}
A.la(v.typeUniverse,JSON.parse('{"dU":"aS","bd":"aS","aB":"aS","dy":{"C":[],"w":[]},"cd":{"w":[]},"cf":{"K":[]},"aS":{"K":[]},"m":{"k":["1"],"h":["1"],"K":[],"e":["1"]},"f4":{"m":["1"],"k":["1"],"h":["1"],"K":[],"e":["1"]},"b3":{"v":["1"]},"bu":{"r":[],"ab":[],"az":["ab"]},"cc":{"r":[],"b":[],"ab":[],"az":["ab"],"w":[]},"dz":{"r":[],"ab":[],"az":["ab"],"w":[]},"aR":{"f":[],"az":["f"],"fr":[],"w":[]},"bR":{"e":["2"]},"c1":{"v":["2"]},"b4":{"bR":["1","2"],"e":["2"],"e.E":"2"},"cN":{"b4":["1","2"],"bR":["1","2"],"h":["2"],"e":["2"],"e.E":"2"},"b5":{"o":["3","4"],"n":["3","4"],"o.K":"3","o.V":"4"},"ch":{"A":[]},"h":{"e":["1"]},"L":{"h":["1"],"e":["1"]},"cw":{"L":["1"],"h":["1"],"e":["1"],"e.E":"1","L.E":"1"},"b9":{"v":["1"]},"bb":{"e":["2"],"e.E":"2"},"c7":{"bb":["1","2"],"h":["2"],"e":["2"],"e.E":"2"},"ak":{"v":["2"]},"al":{"L":["2"],"h":["2"],"e":["2"],"e.E":"2","L.E":"2"},"bE":{"e":["1"],"e.E":"1"},"cA":{"v":["1"]},"aE":{"e":["1"],"e.E":"1"},"bs":{"aE":["1"],"h":["1"],"e":["1"],"e.E":"1"},"cu":{"v":["1"]},"c8":{"h":["1"],"e":["1"],"e.E":"1"},"c9":{"v":["1"]},"a6":{"e":["1"],"e.E":"1"},"a7":{"v":["1"]},"ct":{"L":["1"],"h":["1"],"e":["1"],"e.E":"1","L.E":"1"},"R":{"bT":[],"aJ":[]},"bV":{"bU":[],"aJ":[]},"c2":{"n":["1","2"]},"ag":{"c2":["1","2"],"n":["1","2"]},"bk":{"e":["1"],"e.E":"1"},"bl":{"v":["1"]},"c3":{"ao":["1"],"as":["1"],"h":["1"],"e":["1"]},"aA":{"c3":["1"],"ao":["1"],"as":["1"],"h":["1"],"e":["1"]},"co":{"A":[]},"dA":{"A":[]},"ed":{"A":[]},"aP":{"aQ":[]},"db":{"aQ":[]},"dc":{"aQ":[]},"e9":{"aQ":[]},"e2":{"aQ":[]},"br":{"aQ":[]},"ev":{"A":[]},"e_":{"A":[]},"eu":{"A":[]},"aC":{"o":["1","2"],"iE":["1","2"],"n":["1","2"],"o.K":"1","o.V":"2"},"aj":{"h":["1"],"e":["1"],"e.E":"1"},"ci":{"v":["1"]},"bT":{"aJ":[]},"bU":{"aJ":[]},"ce":{"kx":[],"fr":[]},"eB":{"cr":[],"by":[]},"et":{"e":["cr"],"e.E":"cr"},"cL":{"v":["cr"]},"e5":{"by":[]},"eC":{"e":["by"],"e.E":"by"},"eD":{"v":["by"]},"bz":{"K":[],"w":[]},"ck":{"K":[]},"dI":{"K":[],"w":[]},"P":{"a3":["1"],"K":[]},"cj":{"y":["r"],"P":["r"],"k":["r"],"a3":["r"],"h":["r"],"K":[],"e":["r"],"V":["r"]},"a4":{"y":["b"],"P":["b"],"k":["b"],"a3":["b"],"h":["b"],"K":[],"e":["b"],"V":["b"]},"dJ":{"y":["r"],"P":["r"],"k":["r"],"a3":["r"],"h":["r"],"K":[],"e":["r"],"V":["r"],"w":[],"y.E":"r"},"dK":{"y":["r"],"P":["r"],"k":["r"],"a3":["r"],"h":["r"],"K":[],"e":["r"],"V":["r"],"w":[],"y.E":"r"},"dL":{"a4":[],"y":["b"],"P":["b"],"k":["b"],"a3":["b"],"h":["b"],"K":[],"e":["b"],"V":["b"],"w":[],"y.E":"b"},"dM":{"a4":[],"y":["b"],"P":["b"],"k":["b"],"a3":["b"],"h":["b"],"K":[],"e":["b"],"V":["b"],"w":[],"y.E":"b"},"dN":{"a4":[],"y":["b"],"P":["b"],"k":["b"],"a3":["b"],"h":["b"],"K":[],"e":["b"],"V":["b"],"w":[],"y.E":"b"},"dO":{"a4":[],"y":["b"],"P":["b"],"k":["b"],"a3":["b"],"h":["b"],"K":[],"e":["b"],"V":["b"],"w":[],"y.E":"b"},"dP":{"a4":[],"hW":[],"y":["b"],"P":["b"],"k":["b"],"a3":["b"],"h":["b"],"K":[],"e":["b"],"V":["b"],"w":[],"y.E":"b"},"cl":{"a4":[],"y":["b"],"P":["b"],"k":["b"],"a3":["b"],"h":["b"],"K":[],"e":["b"],"V":["b"],"w":[],"y.E":"b"},"cm":{"a4":[],"fT":[],"y":["b"],"P":["b"],"k":["b"],"a3":["b"],"h":["b"],"K":[],"e":["b"],"V":["b"],"w":[],"y.E":"b"},"eE":{"fQ":[]},"ew":{"A":[]},"cZ":{"A":[]},"t":{"v":["1"]},"bn":{"e":["1"],"e.E":"1"},"aI":{"o":["1","2"],"n":["1","2"],"o.K":"1","o.V":"2"},"cQ":{"aI":["1","2"],"o":["1","2"],"n":["1","2"],"o.K":"1","o.V":"2"},"cM":{"aI":["1","2"],"o":["1","2"],"n":["1","2"],"o.K":"1","o.V":"2"},"bj":{"h":["1"],"e":["1"],"e.E":"1"},"cP":{"v":["1"]},"bm":{"ao":["1"],"iF":["1"],"as":["1"],"h":["1"],"e":["1"]},"cR":{"v":["1"]},"o":{"n":["1","2"]},"cS":{"h":["2"],"e":["2"],"e.E":"2"},"cT":{"v":["2"]},"ao":{"as":["1"],"h":["1"],"e":["1"]},"cY":{"ao":["1"],"as":["1"],"h":["1"],"e":["1"]},"ey":{"o":["f","@"],"n":["f","@"],"o.K":"f","o.V":"@"},"ez":{"L":["f"],"h":["f"],"e":["f"],"e.E":"f","L.E":"f"},"c0":{"a1":["k<b>","f"],"a1.S":"k<b>"},"di":{"a1":["f","k<b>"]},"cg":{"A":[]},"dC":{"A":[]},"dB":{"a1":["q?","f"],"a1.S":"q?"},"dD":{"a1":["f","k<b>"],"a1.S":"f"},"ee":{"a1":["f","k<b>"],"a1.S":"f"},"r":{"ab":[],"az":["ab"]},"b":{"ab":[],"az":["ab"]},"k":{"h":["1"],"e":["1"]},"ab":{"az":["ab"]},"cr":{"by":[]},"as":{"h":["1"],"e":["1"]},"f":{"az":["f"],"fr":[]},"c_":{"A":[]},"cx":{"A":[]},"ay":{"A":[]},"cp":{"A":[]},"ds":{"A":[]},"cz":{"A":[]},"ec":{"A":[]},"bC":{"A":[]},"df":{"A":[]},"dR":{"A":[]},"cv":{"A":[]},"D":{"kA":[]},"b6":{"ah":["1"]},"bt":{"ah":["e<1>"]},"aT":{"ah":["k<1>"]},"a9":{"ah":["2"]},"bB":{"a9":["1","as<1>"],"ah":["as<1>"],"a9.E":"1","a9.T":"as<1>"},"bx":{"ah":["n<1,2>"]},"c4":{"ah":["@"]},"d8":{"z":[]},"dt":{"z":[]},"d5":{"z":[]},"d7":{"z":[]},"d9":{"z":[]},"da":{"z":[]},"dd":{"z":[]},"de":{"z":[]},"dj":{"z":[]},"dl":{"z":[]},"dm":{"z":[]},"dr":{"z":[]},"dx":{"z":[]},"dE":{"z":[]},"dG":{"z":[]},"e0":{"z":[]},"e1":{"z":[]},"e4":{"z":[]},"e6":{"z":[]},"e7":{"z":[]},"ea":{"z":[]},"eb":{"z":[]},"ef":{"z":[]},"au":{"a_":[]},"bf":{"aW":[]},"at":{"aV":[]},"cG":{"a_":[]},"bG":{"a_":[]},"cE":{"a_":[]},"cF":{"a_":[]},"cD":{"a_":[]},"bH":{"a_":[]},"bK":{"a_":[]},"bO":{"a_":[]},"bQ":{"a_":[]},"bJ":{"aW":[]},"bP":{"aW":[]},"bN":{"aW":[]},"bi":{"aV":[]},"bM":{"aV":[]},"a8":{"aH":[]},"cK":{"aH":[]},"cH":{"aH":[]},"en":{"aH":[]},"ep":{"aH":[]},"av":{"eq":[]},"du":{"dv":[]},"dS":{"dT":[]},"kd":{"k":["b"],"h":["b"],"e":["b"]},"fT":{"k":["b"],"h":["b"],"e":["b"]},"kD":{"k":["b"],"h":["b"],"e":["b"]},"kb":{"k":["b"],"h":["b"],"e":["b"]},"kC":{"k":["b"],"h":["b"],"e":["b"]},"kc":{"k":["b"],"h":["b"],"e":["b"]},"hW":{"k":["b"],"h":["b"],"e":["b"]},"k9":{"k":["r"],"h":["r"],"e":["r"]},"ka":{"k":["r"],"h":["r"],"e":["r"]}}'))
A.l9(v.typeUniverse,JSON.parse('{"P":1,"cY":1,"dg":2}'))
var u=(function rtii(){var t=A.ap
return{aM:t("c0"),e8:t("az<@>"),M:t("aA<f>"),he:t("c5"),V:t("h<@>"),bU:t("A"),Z:t("aQ"),eL:t("b8"),c:t("bt<@>"),R:t("e<@>"),hb:t("e<b>"),c3:t("m<c5>"),eU:t("m<dp>"),l:t("m<b7>"),an:t("m<dq>"),h:t("m<b8>"),I:t("m<ar>"),gL:t("m<k<b>>"),d:t("m<n<f,@>>"),G:t("m<q>"),d_:t("m<am>"),gb:t("m<dY>"),s:t("m<f>"),gk:t("m<bc>"),F:t("m<aV>"),f_:t("m<bI>"),fL:t("m<aW>"),f0:t("m<bf>"),gK:t("m<a_>"),d5:t("m<bh>"),fH:t("m<ek>"),cz:t("m<el>"),cB:t("m<em>"),av:t("m<aZ>"),v:t("m<a8>"),m:t("m<aH>"),u:t("m<b_>"),bV:t("m<es>"),b:t("m<@>"),t:t("m<b>"),T:t("cd"),o:t("K"),W:t("aB"),aU:t("a3<@>"),J:t("aT<@>"),g:t("k<b7>"),ds:t("k<ar>"),k:t("k<f>"),Q:t("k<aV>"),fb:t("k<b_>"),j:t("k<@>"),L:t("k<b>"),g9:t("z"),e1:t("aD<f,@>"),e:t("bx<@,@>"),a:t("n<f,@>"),c6:t("n<fQ,z>"),f:t("n<@,@>"),bS:t("n<b,b>"),cb:t("n<b,n<fQ,z>>"),bZ:t("bz"),eB:t("a4"),P:t("cn"),K:t("q"),p:t("a5"),ao:t("am"),gT:t("mE"),bQ:t("+()"),q:t("cr"),at:t("dZ"),bJ:t("ct<f>"),D:t("bB<@>"),cq:t("as<f>"),aI:t("as<at>"),N:t("f"),dm:t("w"),dd:t("fQ"),gc:t("fT"),ak:t("bd"),U:t("bE<f>"),ap:t("a6<au>"),C:t("a6<a8>"),y:t("a7<a8>"),r:t("bF"),cf:t("eg"),n:t("bL"),eS:t("aX"),aV:t("eh"),eO:t("at"),w:t("bh"),fw:t("aY"),dH:t("au"),cH:t("bQ"),X:t("a8"),fN:t("b_"),gA:t("bS"),x:t("bn<a8>"),B:t("C"),E:t("C(ar)"),bB:t("C(f)"),i:t("r"),z:t("@"),S:t("b"),f5:t("b(b)"),A:t("0&*"),_:t("q*"),eH:t("ix<cn>?"),bM:t("k<@>?"),c9:t("n<f,@>?"),Y:t("n<@,@>?"),O:t("q?"),br:t("eA?"),gF:t("C(ar)?"),H:t("ab"),cA:t("~(f,@)")}})();(function constants(){var t=hunkHelpers.makeConstList
B.af=J.dw.prototype
B.a=J.m.prototype
B.c=J.cc.prototype
B.d=J.bu.prototype
B.b=J.aR.prototype
B.ag=J.aB.prototype
B.ah=J.cf.prototype
B.e=A.cm.prototype
B.N=J.dU.prototype
B.B=J.bd.prototype
B.C=new A.eL("littleEndian")
B.W=new A.eK()
B.V=new A.c0()
B.b9=new A.b6(A.ap("b6<0&>"))
B.D=new A.c4()
B.Y=new A.c9(A.ap("c9<0&>"))
B.E=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.Z=function() {
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
B.a3=function(getTagFallback) {
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
B.a_=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.a2=function(hooks) {
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
B.a1=function(hooks) {
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
B.a0=function(hooks) {
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
B.F=function(hooks) { return hooks; }

B.l=new A.dB()
B.G=new A.dD()
B.a4=new A.dR()
B.f=new A.fz()
B.H=new A.ee()
B.a5=new A.ej()
B.p=new A.a2("text")
B.I=new A.a2("image")
B.a6=new A.a2("tab")
B.m=new A.a2("title")
B.q=new A.a2("list")
B.n=new A.a2("table")
B.r=new A.a2("hyperlink")
B.t=new A.a2("superscript")
B.u=new A.a2("subscript")
B.a7=new A.a2("separator")
B.J=new A.a2("pageBreak")
B.a8=new A.ai("Pacote OPC inv\xe1lido: [Content_Types].xml ausente.",null,null)
B.a9=new A.ai("Invalid ZIP archive: end of central directory not found.",null,null)
B.aa=new A.ai("Invalid ZIP archive: unexpected central directory header.",null,null)
B.ab=new A.ai("Invalid ZIP archive: local file header not found.",null,null)
B.ac=new A.ai("document.xml com <w:body> em formato n\xe3o suportado.",null,null)
B.ad=new A.ai("Pacote OPC sem relacionamento officeDocument.",null,null)
B.ae=new A.ai("document.xml sem <w:body>.",null,null)
B.ai=new A.f7(null)
B.aj=new A.f8(null)
B.ak=new A.f9(!1)
B.X=new A.b6(A.ap("b6<a5>"))
B.al=new A.aT(B.X,A.ap("aT<a5>"))
B.ay=new A.R(1000,"M")
B.aI=new A.R(900,"CM")
B.aF=new A.R(500,"D")
B.aC=new A.R(400,"CD")
B.az=new A.R(100,"C")
B.aJ=new A.R(90,"XC")
B.aG=new A.R(50,"L")
B.aD=new A.R(40,"XL")
B.aA=new A.R(10,"X")
B.aK=new A.R(9,"IX")
B.aH=new A.R(5,"V")
B.aE=new A.R(4,"IV")
B.aB=new A.R(1,"I")
B.am=A.d(t([B.ay,B.aI,B.aF,B.aC,B.az,B.aJ,B.aG,B.aD,B.aA,B.aK,B.aH,B.aE,B.aB]),A.ap("m<+(b,f)>"))
B.an=A.d(t([0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0,0,0]),u.t)
B.ao=A.d(t([16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15]),u.t)
B.K=A.d(t([1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577]),u.t)
B.v=A.d(t([]),u.l)
B.ap=A.d(t([]),u.h)
B.aq=A.d(t([]),u.s)
B.L=A.d(t([]),u.u)
B.as=A.d(t([0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13]),u.t)
B.ar=A.d(t([5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5]),u.t)
B.M=A.d(t([3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258]),u.t)
B.at=A.d(t([8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8]),u.t)
B.j={}
B.w=new A.ag(B.j,[],A.ap("ag<f,aQ>"))
B.o=new A.ag(B.j,[],A.ap("ag<f,@>"))
B.i=new A.ag(B.j,[],A.ap("ag<@,@>"))
B.aw={yellow:0,green:1,cyan:2,magenta:3,blue:4,red:5,darkBlue:6,darkCyan:7,darkGreen:8,darkMagenta:9,darkRed:10,darkYellow:11,darkGray:12,lightGray:13,black:14,white:15}
B.au=new A.ag(B.aw,["#FFFF00","#00FF00","#00FFFF","#FF00FF","#0000FF","#FF0000","#00008B","#008B8B","#006400","#8B008B","#8B0000","#808000","#A9A9A9","#D3D3D3","#000000","#FFFFFF"],A.ap("ag<f,f>"))
B.x=new A.bA("center")
B.y=new A.bA("right")
B.z=new A.bA("alignment")
B.A=new A.bA("justify")
B.ax={"w:sectPr":0}
B.aL=new A.aA(B.ax,1,u.M)
B.av={"w:tcPr":0}
B.aM=new A.aA(B.av,1,u.M)
B.aO=new A.aA(B.j,0,u.M)
B.aN=new A.aA(B.j,0,A.ap("aA<at>"))
B.aP=new A.e8("all")
B.aQ=new A.e8("empty")
B.aR=new A.bc("bottom")
B.aS=new A.bc("left")
B.aT=new A.bc("right")
B.aU=new A.bc("top")
B.O=new A.aU("fifth")
B.P=new A.aU("first")
B.Q=new A.aU("fourth")
B.R=new A.aU("second")
B.S=new A.aU("sixth")
B.T=new A.aU("third")
B.aV=A.aq("mB")
B.aW=A.aq("mC")
B.aX=A.aq("k9")
B.aY=A.aq("ka")
B.aZ=A.aq("kb")
B.b_=A.aq("kc")
B.b0=A.aq("kd")
B.b1=A.aq("q")
B.b2=A.aq("kC")
B.b3=A.aq("hW")
B.b4=A.aq("kD")
B.b5=A.aq("fT")
B.b6=new A.fU(!1)
B.b7=new A.be(null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
B.b8=new A.bg(null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
B.h=new A.cO("none")
B.k=new A.cO("instruction")
B.U=new A.cO("result")})();(function staticFields(){$.hf=null
$.ac=A.d([],u.G)
$.iL=null
$.fu=0
$.dX=A.lM()
$.is=null
$.ir=null
$.jz=null
$.ju=null
$.jC=null
$.hw=null
$.hB=null
$.ig=null
$.hm=A.d([],A.ap("m<k<q>?>"))})();(function lazyInitializers(){var t=hunkHelpers.lazyFinal
t($,"mD","ik",()=>A.m9("_$dart_dartClosure"))
t($,"mG","jG",()=>A.aG(A.fS({
toString:function(){return"$receiver$"}})))
t($,"mH","jH",()=>A.aG(A.fS({$method$:null,
toString:function(){return"$receiver$"}})))
t($,"mI","jI",()=>A.aG(A.fS(null)))
t($,"mJ","jJ",()=>A.aG(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"mM","jM",()=>A.aG(A.fS(void 0)))
t($,"mN","jN",()=>A.aG(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"mL","jL",()=>A.aG(A.iV(null)))
t($,"mK","jK",()=>A.aG(function(){try{null.$method$}catch(s){return s.message}}()))
t($,"mP","jP",()=>A.aG(A.iV(void 0)))
t($,"mO","jO",()=>A.aG(function(){try{(void 0).$method$}catch(s){return s.message}}()))
t($,"mS","jS",()=>A.km(4096))
t($,"mQ","jQ",()=>new A.hr().$0())
t($,"mR","jR",()=>new A.hq().$0())
t($,"n0","eH",()=>A.hE(B.b1))
t($,"mF","il",()=>{A.kr()
return $.fu})})();(function nativeSupport(){!function(){var t=function(a){var n={}
n[a]=1
return Object.keys(hunkHelpers.convertToFastObject(n))[0]}
v.getIsolateTag=function(a){return t("___dart_"+a+v.isolateTag)}
var s="___dart_isolate_tags_"
var r=Object[s]||(Object[s]=Object.create(null))
var q="_ZxYxX"
for(var p=0;;p++){var o=t(q+"_"+p+"_")
if(!(o in r)){r[o]=1
v.isolateTag=o
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.bz,ArrayBufferView:A.ck,DataView:A.dI,Float32Array:A.dJ,Float64Array:A.dK,Int16Array:A.dL,Int32Array:A.dM,Int8Array:A.dN,Uint16Array:A.dO,Uint32Array:A.dP,Uint8ClampedArray:A.cl,CanvasPixelArray:A.cl,Uint8Array:A.cm})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.P.$nativeSuperclassTag="ArrayBufferView"
A.cU.$nativeSuperclassTag="ArrayBufferView"
A.cV.$nativeSuperclassTag="ArrayBufferView"
A.cj.$nativeSuperclassTag="ArrayBufferView"
A.cW.$nativeSuperclassTag="ArrayBufferView"
A.cX.$nativeSuperclassTag="ArrayBufferView"
A.a4.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$0=function(){return this()}
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$1$1=function(a){return this(a)}
Function.prototype.$2$0=function(){return this()}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var t=document.scripts
function onLoad(b){for(var r=0;r<t.length;++r){t[r].removeEventListener("load",onLoad,false)}a(b.target)}for(var s=0;s<t.length;++s){t[s].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var t=A.ml
if(typeof dartMainRunner==="function"){dartMainRunner(t,[])}else{t([])}})})()
//# sourceMappingURL=worker_parse.js.map
