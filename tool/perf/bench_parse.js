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
if(a[b]!==t){A.kI(b)}a[b]=s}var r=a[b]
a[c]=function(){return r}
return r}}function makeConstList(a){a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var t=0;t<a.length;++t){convertToFastObject(a[t])}}var y=0
function instanceTearOffGetter(a,b){var t=null
return a?function(c){if(t===null)t=A.fK(b)
return new t(c,this)}:function(){if(t===null)t=A.fK(b)
return new t(this,null)}}function staticTearOffGetter(a){var t=null
return function(){if(t===null)t=A.fK(a).prototype
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
fN(a,b,c,d){return{i:a,p:b,e:c,x:d}},
f2(a){var t,s,r,q,p,o=a[v.dispatchPropertyName]
if(o==null)if($.fL==null){A.kr()
o=a[v.dispatchPropertyName]}if(o!=null){t=o.p
if(!1===t)return o.i
if(!0===t)return a
s=Object.getPrototypeOf(a)
if(t===s)return o.i
if(o.e===s)throw A.b(A.hl("Return interceptor for "+A.p(t(a,o))))}r=a.constructor
if(r==null)q=null
else{p=$.eN
if(p==null)p=$.eN=v.getIsolateTag("_$dart_js")
q=r[p]}if(q!=null)return q
q=A.kw(a)
if(q!=null)return q
if(typeof a=="function")return B.ad
t=Object.getPrototypeOf(a)
if(t==null)return B.K
if(t===Object.prototype)return B.K
if(typeof r=="function"){p=$.eN
if(p==null)p=$.eN=v.getIsolateTag("_$dart_js")
Object.defineProperty(r,p,{value:B.y,enumerable:false,writable:true,configurable:true})
return B.y}return B.y},
iB(a,b){if(a<0||a>4294967295)throw A.b(A.F(a,0,4294967295,"length",null))
return J.iC(new Array(a),b)},
iC(a,b){var t=A.d(a,b.h("h<0>"))
t.$flags=1
return t},
h3(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
iD(a,b){var t,s
for(t=a.length;b<t;){s=a.charCodeAt(b)
if(s!==32&&s!==13&&!J.h3(s))break;++b}return b},
iE(a,b){var t,s,r
for(t=a.length;b>0;b=s){s=b-1
if(!(s<t))return A.a(a,s)
r=a.charCodeAt(s)
if(r!==32&&r!==13&&!J.h3(r))break}return b},
b2(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.bN.prototype
return J.cR.prototype}if(typeof a=="string")return J.b6.prototype
if(a==null)return J.bO.prototype
if(typeof a=="boolean")return J.cQ.prototype
if(Array.isArray(a))return J.h.prototype
if(typeof a!="object"){if(typeof a=="function")return J.af.prototype
if(typeof a=="symbol")return J.b9.prototype
if(typeof a=="bigint")return J.b7.prototype
return a}if(a instanceof A.o)return a
return J.f2(a)},
by(a){if(typeof a=="string")return J.b6.prototype
if(a==null)return a
if(Array.isArray(a))return J.h.prototype
if(typeof a!="object"){if(typeof a=="function")return J.af.prototype
if(typeof a=="symbol")return J.b9.prototype
if(typeof a=="bigint")return J.b7.prototype
return a}if(a instanceof A.o)return a
return J.f2(a)},
i_(a){if(a==null)return a
if(Array.isArray(a))return J.h.prototype
if(typeof a!="object"){if(typeof a=="function")return J.af.prototype
if(typeof a=="symbol")return J.b9.prototype
if(typeof a=="bigint")return J.b7.prototype
return a}if(a instanceof A.o)return a
return J.f2(a)},
kk(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.af.prototype
if(typeof a=="symbol")return J.b9.prototype
if(typeof a=="bigint")return J.b7.prototype
return a}if(a instanceof A.o)return a
return J.f2(a)},
P(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.b2(a).R(a,b)},
bB(a,b,c){return J.kk(a).bC(a,b,c)},
fS(a,b){return J.i_(a).a_(a,b)},
B(a){return J.b2(a).gD(a)},
ik(a){return J.by(a).gA(a)},
H(a){return J.i_(a).gu(a)},
dF(a){return J.by(a).gt(a)},
il(a){return J.b2(a).gL(a)},
aG(a){return J.b2(a).p(a)},
cP:function cP(){},
cQ:function cQ(){},
bO:function bO(){},
bQ:function bQ(){},
as:function as(){},
d3:function d3(){},
c4:function c4(){},
af:function af(){},
b7:function b7(){},
b9:function b9(){},
h:function h(a){this.$ti=a},
dX:function dX(a){this.$ti=a},
bC:function bC(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
bP:function bP(){},
bN:function bN(){},
cR:function cR(){},
b6:function b6(){}},A={fi:function fi(){},
ip(a,b,c){if(b.h("n<0>").b(a))return new A.ck(a,b.h("@<0>").B(c).h("ck<1,2>"))
return new A.aH(a,b.h("@<0>").B(c).h("aH<1,2>"))},
ai(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
ep(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
fM(a){var t,s
for(t=$.X.length,s=0;s<t;++s)if(a===$.X[s])return!0
return!1},
fn(a,b,c,d){if(u.r.b(a))return new A.bL(a,b,c.h("@<0>").B(d).h("bL<1,2>"))
return new A.aR(a,b,c.h("@<0>").B(d).h("aR<1,2>"))},
fg(){return new A.c1("No element")},
bq:function bq(){},
bF:function bF(a,b){this.a=a
this.$ti=b},
aH:function aH(a,b){this.a=a
this.$ti=b},
ck:function ck(a,b){this.a=a
this.$ti=b},
aI:function aI(a,b){this.a=a
this.$ti=b},
dI:function dI(a,b){this.a=a
this.b=b},
dJ:function dJ(a,b){this.a=a
this.b=b},
bS:function bS(a){this.a=a},
en:function en(){},
n:function n(){},
J:function J(){},
aQ:function aQ(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aR:function aR(a,b,c){this.a=a
this.b=b
this.$ti=c},
bL:function bL(a,b,c){this.a=a
this.b=b
this.$ti=c},
aS:function aS(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
a3:function a3(a,b,c){this.a=a
this.b=b
this.$ti=c},
c6:function c6(a,b,c){this.a=a
this.b=b
this.$ti=c},
c7:function c7(a,b,c){this.a=a
this.b=b
this.$ti=c},
T:function T(a,b){this.a=a
this.$ti=b},
U:function U(a,b){this.a=a
this.$ti=b},
aL:function aL(){},
c_:function c_(a,b){this.a=a
this.$ti=b},
fb(){throw A.b(A.bd("Cannot modify unmodifiable Map"))},
i5(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
ld(a,b){var t
if(b!=null){t=b.x
if(t!=null)return t}return u.p.b(a)},
p(a){var t
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
t=J.aG(a)
return t},
d4(a){var t,s=$.hb
if(s==null)s=$.hb=Symbol("identityHashCode")
t=a[s]
if(t==null){t=Math.random()*0x3fffffff|0
a[s]=t}return t},
E(a,b){var t,s,r,q,p,o=null,n=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(n==null)return o
if(3>=n.length)return A.a(n,3)
t=n[3]
if(b==null){if(t!=null)return parseInt(a,10)
if(n[2]!=null)return parseInt(a,16)
return o}if(b<2||b>36)throw A.b(A.F(b,2,36,"radix",o))
if(b===10&&t!=null)return parseInt(a,10)
if(b<10||t==null){s=b<=10?47+b:86+b
r=n[1]
for(q=r.length,p=0;p<q;++p)if((r.charCodeAt(p)|32)>s)return o}return parseInt(a,b)},
hc(a){var t,s
if(!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(a))return null
t=parseFloat(a)
if(isNaN(t)){s=B.b.W(a)
if(s==="NaN"||s==="+NaN"||s==="-NaN")return t
return null}return t},
eg(a){return A.iL(a)},
iL(a){var t,s,r,q
if(a instanceof A.o)return A.M(A.cA(a),null)
t=J.b2(a)
if(t===B.ac||t===B.ae||u.ak.b(a)){s=B.B(a)
if(s!=="Object"&&s!=="")return s
r=a.constructor
if(typeof r=="function"){q=r.name
if(typeof q=="string"&&q!=="Object"&&q!=="")return q}}return A.M(A.cA(a),null)},
hd(a){if(a==null||typeof a=="number"||A.fI(a))return J.aG(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.ar)return a.p(0)
if(a instanceof A.am)return a.bA(!0)
return"Instance of '"+A.eg(a)+"'"},
iM(){return Date.now()},
iN(){var t,s
if($.eh!==0)return
$.eh=1000
if(typeof window=="undefined")return
t=window
if(t==null)return
if(!!t.dartUseDateNowForTicks)return
s=t.performance
if(s==null)return
if(typeof s.now!="function")return
$.eh=1e6
$.ei=new A.ef(s)},
iO(a,b,c){var t,s,r,q
if(c<=500&&b===0&&c===a.length)return String.fromCharCode.apply(null,a)
for(t=b,s="";t<c;t=r){r=t+500
q=r<c?r:c
s+=String.fromCharCode.apply(null,a.subarray(t,q))}return s},
i(a){var t
if(0<=a){if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){t=a-65536
return String.fromCharCode((B.c.aR(t,10)|55296)>>>0,t&1023|56320)}}throw A.b(A.F(a,0,1114111,null,null))},
a(a,b){if(a==null)J.dF(a)
throw A.b(A.f0(a,b))},
f0(a,b){var t,s="index"
if(!A.hO(b))return new A.ac(!0,b,s,null)
t=A.aD(J.dF(a))
if(b<0||b>=t)return A.h2(b,t,a,s)
return A.iS(b,s)},
hV(a){return new A.ac(!0,a,null,null)},
b(a){return A.i1(new Error(),a)},
i1(a,b){var t
if(b==null)b=new A.c2()
a.dartException=b
t=A.kJ
if("defineProperty" in Object){Object.defineProperty(a,"message",{get:t})
a.name=""}else a.toString=t
return a},
kJ(){return J.aG(this.dartException)},
a6(a){throw A.b(a)},
fP(a,b){throw A.i1(b,a)},
O(a,b,c){var t
if(b==null)b=0
if(c==null)c=0
t=Error()
A.fP(A.jJ(a,b,c),t)},
jJ(a,b,c){var t,s,r,q,p,o,n,m,l
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
return new A.c5("'"+t+"': Cannot "+p+" "+m+l+o)},
q(a){throw A.b(A.ad(a))},
aj(a){var t,s,r,q,p,o
a=A.i4(a.replace(String({}),"$receiver$"))
t=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(t==null)t=A.d([],u.s)
s=t.indexOf("\\$arguments\\$")
r=t.indexOf("\\$argumentsExpr\\$")
q=t.indexOf("\\$expr\\$")
p=t.indexOf("\\$method\\$")
o=t.indexOf("\\$receiver\\$")
return new A.eq(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),s,r,q,p,o)},
er(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(t){return t.message}}(a)},
hk(a){return function($expr$){try{$expr$.$method$}catch(t){return t.message}}(a)},
fj(a,b){var t=b==null,s=t?null:b.method
return new A.cT(a,s,t?null:b.receiver)},
kK(a){if(a==null)return new A.e7(a)
if(typeof a!=="object")return a
if("dartException" in a)return A.b3(a,a.dartException)
return A.ka(a)},
b3(a,b){if(u.x.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
ka(a){var t,s,r,q,p,o,n,m,l,k,j,i,h
if(!("message" in a))return a
t=a.message
if("number" in a&&typeof a.number=="number"){s=a.number
r=s&65535
if((B.c.aR(s,16)&8191)===10)switch(r){case 438:return A.b3(a,A.fj(A.p(t)+" (Error "+r+")",null))
case 445:case 5007:A.p(t)
return A.b3(a,new A.bY())}}if(a instanceof TypeError){q=$.i6()
p=$.i7()
o=$.i8()
n=$.i9()
m=$.ic()
l=$.id()
k=$.ib()
$.ia()
j=$.ig()
i=$.ie()
h=q.O(t)
if(h!=null)return A.b3(a,A.fj(A.bv(t),h))
else{h=p.O(t)
if(h!=null){h.method="call"
return A.b3(a,A.fj(A.bv(t),h))}else if(o.O(t)!=null||n.O(t)!=null||m.O(t)!=null||l.O(t)!=null||k.O(t)!=null||n.O(t)!=null||j.O(t)!=null||i.O(t)!=null){A.bv(t)
return A.b3(a,new A.bY())}}return A.b3(a,new A.de(typeof t=="string"?t:""))}if(a instanceof RangeError){if(typeof t=="string"&&t.indexOf("call stack")!==-1)return new A.c0()
t=function(b){try{return String(b)}catch(g){}return null}(a)
return A.b3(a,new A.ac(!1,null,null,typeof t=="string"?t.replace(/^RangeError:\s*/,""):t))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof t=="string"&&t==="too much recursion")return new A.c0()
return a},
f9(a){if(a==null)return J.B(a)
if(typeof a=="object")return A.d4(a)
return J.B(a)},
kh(a,b){var t,s,r,q=a.length
for(t=0;t<q;t=r){s=t+1
r=s+1
b.m(0,a[t],a[s])}return b},
ki(a,b){var t,s=a.length
for(t=0;t<s;++t)b.i(0,a[t])
return b},
iu(a1){var t,s,r,q,p,o,n,m,l,k,j=a1.co,i=a1.iS,h=a1.iI,g=a1.nDA,f=a1.aI,e=a1.fs,d=a1.cs,c=e[0],b=d[0],a=j[c],a0=a1.fT
a0.toString
t=i?Object.create(new A.da().constructor.prototype):Object.create(new A.b4(null,null).constructor.prototype)
t.$initialize=t.constructor
s=i?function static_tear_off(){this.$initialize()}:function tear_off(a2,a3){this.$initialize(a2,a3)}
t.constructor=s
s.prototype=t
t.$_name=c
t.$_target=a
r=!i
if(r)q=A.fY(c,a,h,g)
else{t.$static_name=c
q=a}t.$S=A.iq(a0,i,h)
t[b]=q
for(p=q,o=1;o<e.length;++o){n=e[o]
if(typeof n=="string"){m=j[n]
l=n
n=m}else l=""
k=d[o]
if(k!=null){if(r)n=A.fY(l,n,h,g)
t[k]=n}if(o===f)p=n}t.$C=p
t.$R=a1.rC
t.$D=a1.dV
return s},
iq(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.b("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.im)}throw A.b("Error in functionType of tearoff")},
ir(a,b,c,d){var t=A.fX
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,t)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,t)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,t)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,t)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,t)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,t)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,t)}},
fY(a,b,c,d){if(c)return A.it(a,b,d)
return A.ir(b.length,d,a,b)},
is(a,b,c,d){var t=A.fX,s=A.io
switch(b?-1:a){case 0:throw A.b(new A.d9("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,s,t)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,s,t)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,s,t)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,s,t)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,s,t)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,s,t)
default:return function(e,f,g){return function(){var r=[g(this)]
Array.prototype.push.apply(r,arguments)
return e.apply(f(this),r)}}(d,s,t)}},
it(a,b,c){var t,s
if($.fV==null)$.fV=A.fU("interceptor")
if($.fW==null)$.fW=A.fU("receiver")
t=b.length
s=A.is(t,c,a,b)
return s},
fK(a){return A.iu(a)},
im(a,b){return A.cy(v.typeUniverse,A.cA(a.a),b)},
fX(a){return a.a},
io(a){return a.b},
fU(a){var t,s,r,q=new A.b4("receiver","interceptor"),p=Object.getOwnPropertyNames(q)
p.$flags=1
t=p
for(p=t.length,s=0;s<p;++s){r=t[s]
if(q[r]===a)return r}throw A.b(A.fa("Field name "+a+" not found."))},
N(a){if(a==null)A.kb("boolean expression must not be null")
return a},
kb(a){throw A.b(new A.dv(a))},
le(a){throw A.b(new A.dw(a))},
kl(a){return v.getIsolateTag(a)},
lc(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
kw(a){var t,s,r,q,p,o=A.bv($.i0.$1(a)),n=$.f1[o]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.f6[o]
if(t!=null)return t
s=v.interceptorsByTag[o]
if(s==null){r=A.fE($.hU.$2(a,o))
if(r!=null){n=$.f1[r]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.f6[r]
if(t!=null)return t
s=v.interceptorsByTag[r]
o=r}}if(s==null)return null
t=s.prototype
q=o[0]
if(q==="!"){n=A.f8(t)
$.f1[o]=n
Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}if(q==="~"){$.f6[o]=t
return t}if(q==="-"){p=A.f8(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}if(q==="+")return A.i2(a,t)
if(q==="*")throw A.b(A.hl(o))
if(v.leafTags[o]===true){p=A.f8(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}else return A.i2(a,t)},
i2(a,b){var t=Object.getPrototypeOf(a)
Object.defineProperty(t,v.dispatchPropertyName,{value:J.fN(b,t,null,null),enumerable:false,writable:true,configurable:true})
return b},
f8(a){return J.fN(a,!1,null,!!a.$ib8)},
ky(a,b,c){var t=b.prototype
if(v.leafTags[a]===true)return A.f8(t)
else return J.fN(t,c,null,null)},
kr(){if(!0===$.fL)return
$.fL=!0
A.ks()},
ks(){var t,s,r,q,p,o,n,m
$.f1=Object.create(null)
$.f6=Object.create(null)
A.kq()
t=v.interceptorsByTag
s=Object.getOwnPropertyNames(t)
if(typeof window!="undefined"){window
r=function(){}
for(q=0;q<s.length;++q){p=s[q]
o=$.i3.$1(p)
if(o!=null){n=A.ky(p,t[p],o)
if(n!=null){Object.defineProperty(o,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
r.prototype=o}}}}for(q=0;q<s.length;++q){p=s[q]
if(/^[A-Za-z_]/.test(p)){m=t[p]
t["!"+p]=m
t["~"+p]=m
t["-"+p]=m
t["+"+p]=m
t["*"+p]=m}}},
kq(){var t,s,r,q,p,o,n=B.V()
n=A.bx(B.W,A.bx(B.X,A.bx(B.C,A.bx(B.C,A.bx(B.Y,A.bx(B.Z,A.bx(B.a_(B.B),n)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){t=dartNativeDispatchHooksTransformer
if(typeof t=="function")t=[t]
if(Array.isArray(t))for(s=0;s<t.length;++s){r=t[s]
if(typeof r=="function")n=r(n)||n}}q=n.getTag
p=n.getUnknownTag
o=n.prototypeForTag
$.i0=new A.f3(q)
$.hU=new A.f4(p)
$.i3=new A.f5(o)},
bx(a,b){return a(b)||b},
kf(a,b){var t=b.length,s=v.rttc[""+t+";"+a]
if(s==null)return null
if(t===0)return s
if(t===s.length)return s.apply(null,b)
return s(b)},
h4(a,b,c,d,e,f){var t=b?"m":"",s=c?"":"i",r=d?"u":"",q=e?"s":"",p=f?"g":"",o=function(g,h){try{return new RegExp(g,h)}catch(n){return n}}(a,t+s+r+q+p)
if(o instanceof RegExp)return o
throw A.b(A.dT("Illegal RegExp pattern ("+String(o)+")",a,null))},
kB(a,b,c){var t=a.indexOf(b,c)
return t>=0},
hZ(a){if(a.indexOf("$",0)>=0)return a.replace(/\$/g,"$$$$")
return a},
kD(a,b,c,d){var t=b.bl(a,d)
if(t==null)return a
return A.kF(a,t.b.index,t.gbE(),c)},
i4(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
fO(a,b,c){var t=A.kC(a,b,c)
return t},
kC(a,b,c){var t,s,r
if(b===""){if(a==="")return c
t=a.length
s=""+c
for(r=0;r<t;++r)s=s+a[r]+c
return s.charCodeAt(0)==0?s:s}if(a.indexOf(b,0)<0)return a
if(a.length<500||c.indexOf("$",0)>=0)return a.split(b).join(c)
return a.replace(new RegExp(A.i4(b),"g"),A.hZ(c))},
kE(a,b,c,d){return d===0?a.replace(b.b,A.hZ(c)):A.kD(a,b,c,d)},
kF(a,b,c,d){return a.substring(0,b)+d+a.substring(c)},
D:function D(a,b){this.a=a
this.b=b},
bu:function bu(a,b,c){this.a=a
this.b=b
this.c=c},
bG:function bG(){},
aJ:function aJ(a,b,c){this.a=a
this.b=b
this.$ti=c},
cp:function cp(a,b){this.a=a
this.$ti=b},
aZ:function aZ(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
bH:function bH(){},
ae:function ae(a,b,c){this.a=a
this.b=b
this.$ti=c},
ef:function ef(a){this.a=a},
eq:function eq(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
bY:function bY(){},
cT:function cT(a,b,c){this.a=a
this.b=b
this.c=c},
de:function de(a){this.a=a},
e7:function e7(a){this.a=a},
ar:function ar(){},
cD:function cD(){},
cE:function cE(){},
dc:function dc(){},
da:function da(){},
b4:function b4(a,b){this.a=a
this.b=b},
dw:function dw(a){this.a=a},
d9:function d9(a){this.a=a},
dv:function dv(a){this.a=a},
ag:function ag(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
dZ:function dZ(a){this.a=a},
dY:function dY(a){this.a=a},
e1:function e1(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
aP:function aP(a,b){this.a=a
this.$ti=b},
bT:function bT(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
f3:function f3(a){this.a=a},
f4:function f4(a){this.a=a},
f5:function f5(a){this.a=a},
am:function am(){},
bs:function bs(){},
bt:function bt(){},
cS:function cS(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
dA:function dA(a){this.b=a},
du:function du(a,b,c){this.a=a
this.b=b
this.c=c},
ci:function ci(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
fG(a){return a},
iI(a){return new Uint8Array(a)},
h9(a,b,c){return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
fF(a,b,c){if(a>>>0!==a||a>=c)throw A.b(A.f0(b,a))},
au:function au(){},
bV:function bV(){},
eW:function eW(a){this.a=a},
a7:function a7(){},
bU:function bU(){},
cY:function cY(){},
cZ:function cZ(){},
bW:function bW(){},
cr:function cr(){},
cs:function cs(){},
hg(a,b){var t=b.c
return t==null?b.c=A.fD(a,b.x,!0):t},
fr(a,b){var t=b.c
return t==null?b.c=A.cw(a,"h0",[b.x]):t},
hh(a){var t=a.w
if(t===6||t===7||t===8)return A.hh(a.x)
return t===12||t===13},
iW(a){return a.as},
aF(a){return A.dB(v.typeUniverse,a,!1)},
aE(a0,a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a1.w
switch(a){case 5:case 1:case 2:case 3:case 4:return a1
case 6:t=a1.x
s=A.aE(a0,t,a2,a3)
if(s===t)return a1
return A.hE(a0,s,!0)
case 7:t=a1.x
s=A.aE(a0,t,a2,a3)
if(s===t)return a1
return A.fD(a0,s,!0)
case 8:t=a1.x
s=A.aE(a0,t,a2,a3)
if(s===t)return a1
return A.hC(a0,s,!0)
case 9:r=a1.y
q=A.bw(a0,r,a2,a3)
if(q===r)return a1
return A.cw(a0,a1.x,q)
case 10:p=a1.x
o=A.aE(a0,p,a2,a3)
n=a1.y
m=A.bw(a0,n,a2,a3)
if(o===p&&m===n)return a1
return A.fB(a0,o,m)
case 11:l=a1.x
k=a1.y
j=A.bw(a0,k,a2,a3)
if(j===k)return a1
return A.hD(a0,l,j)
case 12:i=a1.x
h=A.aE(a0,i,a2,a3)
g=a1.y
f=A.k7(a0,g,a2,a3)
if(h===i&&f===g)return a1
return A.hB(a0,h,f)
case 13:e=a1.y
a3+=e.length
d=A.bw(a0,e,a2,a3)
p=a1.x
o=A.aE(a0,p,a2,a3)
if(d===e&&o===p)return a1
return A.fC(a0,o,d,!0)
case 14:c=a1.x
if(c<a3)return a1
b=a2[c-a3]
if(b==null)return a1
return b
default:throw A.b(A.cC("Attempted to substitute unexpected RTI kind "+a))}},
bw(a,b,c,d){var t,s,r,q,p=b.length,o=A.f_(p)
for(t=!1,s=0;s<p;++s){r=b[s]
q=A.aE(a,r,c,d)
if(q!==r)t=!0
o[s]=q}return t?o:b},
k8(a,b,c,d){var t,s,r,q,p,o,n=b.length,m=A.f_(n)
for(t=!1,s=0;s<n;s+=3){r=b[s]
q=b[s+1]
p=b[s+2]
o=A.aE(a,p,c,d)
if(o!==p)t=!0
m.splice(s,3,r,q,o)}return t?m:b},
k7(a,b,c,d){var t,s=b.a,r=A.bw(a,s,c,d),q=b.b,p=A.bw(a,q,c,d),o=b.c,n=A.k8(a,o,c,d)
if(r===s&&p===q&&n===o)return b
t=new A.dy()
t.a=r
t.b=p
t.c=n
return t},
d(a,b){a[v.arrayRti]=b
return a},
hW(a){var t=a.$S
if(t!=null){if(typeof t=="number")return A.kn(t)
return a.$S()}return null},
kt(a,b){var t
if(A.hh(b))if(a instanceof A.ar){t=A.hW(a)
if(t!=null)return t}return A.cA(a)},
cA(a){if(a instanceof A.o)return A.k(a)
if(Array.isArray(a))return A.a5(a)
return A.fH(J.b2(a))},
a5(a){var t=a[v.arrayRti],s=u.b
if(t==null)return s
if(t.constructor!==s.constructor)return s
return t},
k(a){var t=a.$ti
return t!=null?t:A.fH(a)},
fH(a){var t=a.constructor,s=t.$ccache
if(s!=null)return s
return A.jR(a,t)},
jR(a,b){var t=a instanceof A.ar?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,s=A.jw(v.typeUniverse,t.name)
b.$ccache=s
return s},
kn(a){var t,s=v.types,r=s[a]
if(typeof r=="string"){t=A.dB(v.typeUniverse,r,!1)
s[a]=t
return t}return r},
km(a){return A.b1(A.k(a))},
fJ(a){var t
if(a instanceof A.am)return A.kg(a.$r,a.aJ())
t=a instanceof A.ar?A.hW(a):null
if(t!=null)return t
if(u.dm.b(a))return J.il(a).a
if(Array.isArray(a))return A.a5(a)
return A.cA(a)},
b1(a){var t=a.r
return t==null?a.r=A.hK(a):t},
hK(a){var t,s,r=a.as,q=r.replace(/\*/g,"")
if(q===r)return a.r=new A.eU(a)
t=A.dB(v.typeUniverse,q,!0)
s=t.r
return s==null?t.r=A.hK(t):s},
kg(a,b){var t,s,r=b,q=r.length
if(q===0)return u.bQ
if(0>=q)return A.a(r,0)
t=A.cy(v.typeUniverse,A.fJ(r[0]),"@<0>")
for(s=1;s<q;++s){if(!(s<r.length))return A.a(r,s)
t=A.hF(v.typeUniverse,t,A.fJ(r[s]))}return A.cy(v.typeUniverse,t,a)},
dD(a){return A.b1(A.dB(v.typeUniverse,a,!1))},
jQ(a){var t,s,r,q,p,o,n=this
if(n===u.K)return A.ao(n,a,A.jW)
if(!A.aq(n))t=n===u._
else t=!0
if(t)return A.ao(n,a,A.k1)
t=n.w
if(t===7)return A.ao(n,a,A.jO)
if(t===1)return A.ao(n,a,A.hP)
s=t===6?n.x:n
r=s.w
if(r===8)return A.ao(n,a,A.jS)
if(s===u.S)q=A.hO
else if(s===u.i||s===u.H)q=A.jV
else if(s===u.N)q=A.k_
else q=s===u.w?A.fI:null
if(q!=null)return A.ao(n,a,q)
if(r===9){p=s.x
if(s.y.every(A.ku)){n.f="$i"+p
if(p==="r")return A.ao(n,a,A.jU)
return A.ao(n,a,A.k0)}}else if(r===11){o=A.kf(s.x,s.y)
return A.ao(n,a,o==null?A.hP:o)}return A.ao(n,a,A.jM)},
ao(a,b,c){a.b=c
return a.b(b)},
jP(a){var t,s=this,r=A.jL
if(!A.aq(s))t=s===u._
else t=!0
if(t)r=A.jD
else if(s===u.K)r=A.jC
else{t=A.cB(s)
if(t)r=A.jN}s.a=r
return s.a(a)},
dC(a){var t=a.w,s=!0
if(!A.aq(a))if(!(a===u._))if(!(a===u.A))if(t!==7)if(!(t===6&&A.dC(a.x)))s=t===8&&A.dC(a.x)||a===u.P||a===u.T
return s},
jM(a){var t=this
if(a==null)return A.dC(t)
return A.kv(v.typeUniverse,A.kt(a,t),t)},
jO(a){if(a==null)return!0
return this.x.b(a)},
k0(a){var t,s=this
if(a==null)return A.dC(s)
t=s.f
if(a instanceof A.o)return!!a[t]
return!!J.b2(a)[t]},
jU(a){var t,s=this
if(a==null)return A.dC(s)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
t=s.f
if(a instanceof A.o)return!!a[t]
return!!J.b2(a)[t]},
jL(a){var t=this
if(a==null){if(A.cB(t))return a}else if(t.b(a))return a
A.hL(a,t)},
jN(a){var t=this
if(a==null)return a
else if(t.b(a))return a
A.hL(a,t)},
hL(a,b){throw A.b(A.jn(A.hu(a,A.M(b,null))))},
hu(a,b){return A.bM(a)+": type '"+A.M(A.fJ(a),null)+"' is not a subtype of type '"+b+"'"},
jn(a){return new A.cu("TypeError: "+a)},
G(a,b){return new A.cu("TypeError: "+A.hu(a,b))},
jS(a){var t=this,s=t.w===6?t.x:t
return s.x.b(a)||A.fr(v.typeUniverse,s).b(a)},
jW(a){return a!=null},
jC(a){if(a!=null)return a
throw A.b(A.G(a,"Object"))},
k1(a){return!0},
jD(a){return a},
hP(a){return!1},
fI(a){return!0===a||!1===a},
l1(a){if(!0===a)return!0
if(!1===a)return!1
throw A.b(A.G(a,"bool"))},
l3(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.b(A.G(a,"bool"))},
l2(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.b(A.G(a,"bool?"))},
l4(a){if(typeof a=="number")return a
throw A.b(A.G(a,"double"))},
l6(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.G(a,"double"))},
l5(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.G(a,"double?"))},
hO(a){return typeof a=="number"&&Math.floor(a)===a},
aD(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.b(A.G(a,"int"))},
l7(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.b(A.G(a,"int"))},
hJ(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.b(A.G(a,"int?"))},
jV(a){return typeof a=="number"},
l8(a){if(typeof a=="number")return a
throw A.b(A.G(a,"num"))},
l9(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.G(a,"num"))},
jB(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.G(a,"num?"))},
k_(a){return typeof a=="string"},
bv(a){if(typeof a=="string")return a
throw A.b(A.G(a,"String"))},
la(a){if(typeof a=="string")return a
if(a==null)return a
throw A.b(A.G(a,"String"))},
fE(a){if(typeof a=="string")return a
if(a==null)return a
throw A.b(A.G(a,"String?"))},
hT(a,b){var t,s,r
for(t="",s="",r=0;r<a.length;++r,s=", ")t+=s+A.M(a[r],b)
return t},
k6(a,b){var t,s,r,q,p,o,n=a.x,m=a.y
if(""===n)return"("+A.hT(m,b)+")"
t=m.length
s=n.split(",")
r=s.length-t
for(q="(",p="",o=0;o<t;++o,p=", "){q+=p
if(r===0)q+="{"
q+=A.M(m[o],b)
if(r>=0)q+=" "+s[r];++r}return q+"})"},
hM(a3,a4,a5){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=", ",a2=null
if(a5!=null){t=a5.length
if(a4==null)a4=A.d([],u.s)
else a2=a4.length
s=a4.length
for(r=t;r>0;--r)B.a.i(a4,"T"+(s+r))
for(q=u.O,p=u._,o="<",n="",r=0;r<t;++r,n=a1){m=a4.length
l=m-1-r
if(!(l>=0))return A.a(a4,l)
o=o+n+a4[l]
k=a5[r]
j=k.w
if(!(j===2||j===3||j===4||j===5||k===q))m=k===p
else m=!0
if(!m)o+=" extends "+A.M(k,a4)}o+=">"}else o=""
q=a3.x
i=a3.y
h=i.a
g=h.length
f=i.b
e=f.length
d=i.c
c=d.length
b=A.M(q,a4)
for(a="",a0="",r=0;r<g;++r,a0=a1)a+=a0+A.M(h[r],a4)
if(e>0){a+=a0+"["
for(a0="",r=0;r<e;++r,a0=a1)a+=a0+A.M(f[r],a4)
a+="]"}if(c>0){a+=a0+"{"
for(a0="",r=0;r<c;r+=3,a0=a1){a+=a0
if(d[r+1])a+="required "
a+=A.M(d[r+2],a4)+" "+d[r]}a+="}"}if(a2!=null){a4.toString
a4.length=a2}return o+"("+a+") => "+b},
M(a,b){var t,s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6)return A.M(a.x,b)
if(m===7){t=a.x
s=A.M(t,b)
r=t.w
return(r===12||r===13?"("+s+")":s)+"?"}if(m===8)return"FutureOr<"+A.M(a.x,b)+">"
if(m===9){q=A.k9(a.x)
p=a.y
return p.length>0?q+("<"+A.hT(p,b)+">"):q}if(m===11)return A.k6(a,b)
if(m===12)return A.hM(a,b,null)
if(m===13)return A.hM(a.x,b,a.y)
if(m===14){o=a.x
n=b.length
o=n-1-o
if(!(o>=0&&o<n))return A.a(b,o)
return b[o]}return"?"},
k9(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
jx(a,b){var t=a.tR[b]
for(;typeof t=="string";)t=a.tR[t]
return t},
jw(a,b){var t,s,r,q,p,o=a.eT,n=o[b]
if(n==null)return A.dB(a,b,!1)
else if(typeof n=="number"){t=n
s=A.cx(a,5,"#")
r=A.f_(t)
for(q=0;q<t;++q)r[q]=s
p=A.cw(a,b,r)
o[b]=p
return p}else return n},
jv(a,b){return A.hH(a.tR,b)},
ju(a,b){return A.hH(a.eT,b)},
dB(a,b,c){var t,s=a.eC,r=s.get(b)
if(r!=null)return r
t=A.hy(A.hw(a,null,b,c))
s.set(b,t)
return t},
cy(a,b,c){var t,s,r=b.z
if(r==null)r=b.z=new Map()
t=r.get(c)
if(t!=null)return t
s=A.hy(A.hw(a,b,c,!0))
r.set(c,s)
return s},
hF(a,b,c){var t,s,r,q=b.Q
if(q==null)q=b.Q=new Map()
t=c.as
s=q.get(t)
if(s!=null)return s
r=A.fB(a,b,c.w===10?c.y:[c])
q.set(t,r)
return r},
an(a,b){b.a=A.jP
b.b=A.jQ
return b},
cx(a,b,c){var t,s,r=a.eC.get(c)
if(r!=null)return r
t=new A.Y(null,null)
t.w=b
t.as=c
s=A.an(a,t)
a.eC.set(c,s)
return s},
hE(a,b,c){var t,s=b.as+"*",r=a.eC.get(s)
if(r!=null)return r
t=A.js(a,b,s,c)
a.eC.set(s,t)
return t},
js(a,b,c,d){var t,s,r
if(d){t=b.w
if(!A.aq(b))s=b===u.P||b===u.T||t===7||t===6
else s=!0
if(s)return b}r=new A.Y(null,null)
r.w=6
r.x=b
r.as=c
return A.an(a,r)},
fD(a,b,c){var t,s=b.as+"?",r=a.eC.get(s)
if(r!=null)return r
t=A.jr(a,b,s,c)
a.eC.set(s,t)
return t},
jr(a,b,c,d){var t,s,r,q
if(d){t=b.w
s=!0
if(!A.aq(b))if(!(b===u.P||b===u.T))if(t!==7)s=t===8&&A.cB(b.x)
if(s)return b
else if(t===1||b===u.A)return u.P
else if(t===6){r=b.x
if(r.w===8&&A.cB(r.x))return r
else return A.hg(a,b)}}q=new A.Y(null,null)
q.w=7
q.x=b
q.as=c
return A.an(a,q)},
hC(a,b,c){var t,s=b.as+"/",r=a.eC.get(s)
if(r!=null)return r
t=A.jp(a,b,s,c)
a.eC.set(s,t)
return t},
jp(a,b,c,d){var t,s
if(d){t=b.w
if(A.aq(b)||b===u.K||b===u._)return b
else if(t===1)return A.cw(a,"h0",[b])
else if(b===u.P||b===u.T)return u.bG}s=new A.Y(null,null)
s.w=8
s.x=b
s.as=c
return A.an(a,s)},
jt(a,b){var t,s,r=""+b+"^",q=a.eC.get(r)
if(q!=null)return q
t=new A.Y(null,null)
t.w=14
t.x=b
t.as=r
s=A.an(a,t)
a.eC.set(r,s)
return s},
cv(a){var t,s,r,q=a.length
for(t="",s="",r=0;r<q;++r,s=",")t+=s+a[r].as
return t},
jo(a){var t,s,r,q,p,o=a.length
for(t="",s="",r=0;r<o;r+=3,s=","){q=a[r]
p=a[r+1]?"!":":"
t+=s+q+p+a[r+2].as}return t},
cw(a,b,c){var t,s,r,q=b
if(c.length>0)q+="<"+A.cv(c)+">"
t=a.eC.get(q)
if(t!=null)return t
s=new A.Y(null,null)
s.w=9
s.x=b
s.y=c
if(c.length>0)s.c=c[0]
s.as=q
r=A.an(a,s)
a.eC.set(q,r)
return r},
fB(a,b,c){var t,s,r,q,p,o
if(b.w===10){t=b.x
s=b.y.concat(c)}else{s=c
t=b}r=t.as+(";<"+A.cv(s)+">")
q=a.eC.get(r)
if(q!=null)return q
p=new A.Y(null,null)
p.w=10
p.x=t
p.y=s
p.as=r
o=A.an(a,p)
a.eC.set(r,o)
return o},
hD(a,b,c){var t,s,r="+"+(b+"("+A.cv(c)+")"),q=a.eC.get(r)
if(q!=null)return q
t=new A.Y(null,null)
t.w=11
t.x=b
t.y=c
t.as=r
s=A.an(a,t)
a.eC.set(r,s)
return s},
hB(a,b,c){var t,s,r,q,p,o=b.as,n=c.a,m=n.length,l=c.b,k=l.length,j=c.c,i=j.length,h="("+A.cv(n)
if(k>0){t=m>0?",":""
h+=t+"["+A.cv(l)+"]"}if(i>0){t=m>0?",":""
h+=t+"{"+A.jo(j)+"}"}s=o+(h+")")
r=a.eC.get(s)
if(r!=null)return r
q=new A.Y(null,null)
q.w=12
q.x=b
q.y=c
q.as=s
p=A.an(a,q)
a.eC.set(s,p)
return p},
fC(a,b,c,d){var t,s=b.as+("<"+A.cv(c)+">"),r=a.eC.get(s)
if(r!=null)return r
t=A.jq(a,b,c,s,d)
a.eC.set(s,t)
return t},
jq(a,b,c,d,e){var t,s,r,q,p,o,n,m
if(e){t=c.length
s=A.f_(t)
for(r=0,q=0;q<t;++q){p=c[q]
if(p.w===1){s[q]=p;++r}}if(r>0){o=A.aE(a,b,s,0)
n=A.bw(a,c,s,0)
return A.fC(a,o,n,c!==n)}}m=new A.Y(null,null)
m.w=13
m.x=b
m.y=c
m.as=d
return A.an(a,m)},
hw(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
hy(a){var t,s,r,q,p,o,n,m=a.r,l=a.s
for(t=m.length,s=0;s<t;){r=m.charCodeAt(s)
if(r>=48&&r<=57)s=A.ji(s+1,r,m,l)
else if((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124)s=A.hx(a,s,m,l,!1)
else if(r===46)s=A.hx(a,s,m,l,!0)
else{++s
switch(r){case 44:break
case 58:l.push(!1)
break
case 33:l.push(!0)
break
case 59:l.push(A.aC(a.u,a.e,l.pop()))
break
case 94:l.push(A.jt(a.u,l.pop()))
break
case 35:l.push(A.cx(a.u,5,"#"))
break
case 64:l.push(A.cx(a.u,2,"@"))
break
case 126:l.push(A.cx(a.u,3,"~"))
break
case 60:l.push(a.p)
a.p=l.length
break
case 62:A.jk(a,l)
break
case 38:A.jj(a,l)
break
case 42:q=a.u
l.push(A.hE(q,A.aC(q,a.e,l.pop()),a.n))
break
case 63:q=a.u
l.push(A.fD(q,A.aC(q,a.e,l.pop()),a.n))
break
case 47:q=a.u
l.push(A.hC(q,A.aC(q,a.e,l.pop()),a.n))
break
case 40:l.push(-3)
l.push(a.p)
a.p=l.length
break
case 41:A.jh(a,l)
break
case 91:l.push(a.p)
a.p=l.length
break
case 93:p=l.splice(a.p)
A.hz(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-1)
break
case 123:l.push(a.p)
a.p=l.length
break
case 125:p=l.splice(a.p)
A.jm(a.u,a.e,p)
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
return A.aC(a.u,a.e,n)},
ji(a,b,c,d){var t,s,r=b-48
for(t=c.length;a<t;++a){s=c.charCodeAt(a)
if(!(s>=48&&s<=57))break
r=r*10+(s-48)}d.push(r)
return a},
hx(a,b,c,d,e){var t,s,r,q,p,o,n=b+1
for(t=c.length;n<t;++n){s=c.charCodeAt(n)
if(s===46){if(e)break
e=!0}else{if(!((((s|32)>>>0)-97&65535)<26||s===95||s===36||s===124))r=s>=48&&s<=57
else r=!0
if(!r)break}}q=c.substring(b,n)
if(e){t=a.u
p=a.e
if(p.w===10)p=p.x
o=A.jx(t,p.x)[q]
if(o==null)A.a6('No "'+q+'" in "'+A.iW(p)+'"')
d.push(A.cy(t,p,o))}else d.push(q)
return n},
jk(a,b){var t,s=a.u,r=A.hv(a,b),q=b.pop()
if(typeof q=="string")b.push(A.cw(s,q,r))
else{t=A.aC(s,a.e,q)
switch(t.w){case 12:b.push(A.fC(s,t,r,a.n))
break
default:b.push(A.fB(s,t,r))
break}}},
jh(a,b){var t,s,r,q=a.u,p=b.pop(),o=null,n=null
if(typeof p=="number")switch(p){case-1:o=b.pop()
break
case-2:n=b.pop()
break
default:b.push(p)
break}else b.push(p)
t=A.hv(a,b)
p=b.pop()
switch(p){case-3:p=b.pop()
if(o==null)o=q.sEA
if(n==null)n=q.sEA
s=A.aC(q,a.e,p)
r=new A.dy()
r.a=t
r.b=o
r.c=n
b.push(A.hB(q,s,r))
return
case-4:b.push(A.hD(q,b.pop(),t))
return
default:throw A.b(A.cC("Unexpected state under `()`: "+A.p(p)))}},
jj(a,b){var t=b.pop()
if(0===t){b.push(A.cx(a.u,1,"0&"))
return}if(1===t){b.push(A.cx(a.u,4,"1&"))
return}throw A.b(A.cC("Unexpected extended operation "+A.p(t)))},
hv(a,b){var t=b.splice(a.p)
A.hz(a.u,a.e,t)
a.p=b.pop()
return t},
aC(a,b,c){if(typeof c=="string")return A.cw(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.jl(a,b,c)}else return c},
hz(a,b,c){var t,s=c.length
for(t=0;t<s;++t)c[t]=A.aC(a,b,c[t])},
jm(a,b,c){var t,s=c.length
for(t=2;t<s;t+=3)c[t]=A.aC(a,b,c[t])},
jl(a,b,c){var t,s,r=b.w
if(r===10){if(c===0)return b.x
t=b.y
s=t.length
if(c<=s)return t[c-1]
c-=s
b=b.x
r=b.w}else if(c===0)return b
if(r!==9)throw A.b(A.cC("Indexed base must be an interface type"))
t=b.y
if(c<=t.length)return t[c-1]
throw A.b(A.cC("Bad index "+c+" for "+b.p(0)))},
kv(a,b,c){var t,s=b.d
if(s==null)s=b.d=new Map()
t=s.get(c)
if(t==null){t=A.x(a,b,null,c,null,!1)?1:0
s.set(c,t)}if(0===t)return!1
if(1===t)return!0
return!0},
x(a,b,c,d,e,f){var t,s,r,q,p,o,n,m,l,k,j
if(b===d)return!0
if(!A.aq(d))t=d===u._
else t=!0
if(t)return!0
s=b.w
if(s===4)return!0
if(A.aq(b))return!1
t=b.w
if(t===1)return!0
r=s===14
if(r)if(A.x(a,c[b.x],c,d,e,!1))return!0
q=d.w
t=b===u.P||b===u.T
if(t){if(q===8)return A.x(a,b,c,d.x,e,!1)
return d===u.P||d===u.T||q===7||q===6}if(d===u.K){if(s===8)return A.x(a,b.x,c,d,e,!1)
if(s===6)return A.x(a,b.x,c,d,e,!1)
return s!==7}if(s===6)return A.x(a,b.x,c,d,e,!1)
if(q===6){t=A.hg(a,d)
return A.x(a,b,c,t,e,!1)}if(s===8){if(!A.x(a,b.x,c,d,e,!1))return!1
return A.x(a,A.fr(a,b),c,d,e,!1)}if(s===7){t=A.x(a,u.P,c,d,e,!1)
return t&&A.x(a,b.x,c,d,e,!1)}if(q===8){if(A.x(a,b,c,d.x,e,!1))return!0
return A.x(a,b,c,A.fr(a,d),e,!1)}if(q===7){t=A.x(a,b,c,u.P,e,!1)
return t||A.x(a,b,c,d.x,e,!1)}if(r)return!1
t=s!==12
if((!t||s===13)&&d===u.Z)return!0
p=s===11
if(p&&d===u.gT)return!0
if(q===13){if(b===u.V)return!0
if(s!==13)return!1
o=b.y
n=d.y
m=o.length
if(m!==n.length)return!1
c=c==null?o:o.concat(c)
e=e==null?n:n.concat(e)
for(l=0;l<m;++l){k=o[l]
j=n[l]
if(!A.x(a,k,c,j,e,!1)||!A.x(a,j,e,k,c,!1))return!1}return A.hN(a,b.x,c,d.x,e,!1)}if(q===12){if(b===u.V)return!0
if(t)return!1
return A.hN(a,b,c,d,e,!1)}if(s===9){if(q!==9)return!1
return A.jT(a,b,c,d,e,!1)}if(p&&q===11)return A.jX(a,b,c,d,e,!1)
return!1},
hN(a2,a3,a4,a5,a6,a7){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
if(!A.x(a2,a3.x,a4,a5.x,a6,!1))return!1
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
if(!A.x(a2,q[i],a6,h,a4,!1))return!1}for(i=0;i<n;++i){h=m[i]
if(!A.x(a2,q[p+i],a6,h,a4,!1))return!1}for(i=0;i<j;++i){h=m[n+i]
if(!A.x(a2,l[i],a6,h,a4,!1))return!1}g=t.c
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
if(!A.x(a2,f[b+2],a6,h,a4,!1))return!1
break}}for(;c<e;){if(g[c+1])return!1
c+=3}return!0},
jT(a,b,c,d,e,f){var t,s,r,q,p,o=b.x,n=d.x
for(;o!==n;){t=a.tR[o]
if(t==null)return!1
if(typeof t=="string"){o=t
continue}s=t[n]
if(s==null)return!1
r=s.length
q=r>0?new Array(r):v.typeUniverse.sEA
for(p=0;p<r;++p)q[p]=A.cy(a,b,s[p])
return A.hI(a,q,null,c,d.y,e,!1)}return A.hI(a,b.y,null,c,d.y,e,!1)},
hI(a,b,c,d,e,f,g){var t,s=b.length
for(t=0;t<s;++t)if(!A.x(a,b[t],d,e[t],f,!1))return!1
return!0},
jX(a,b,c,d,e,f){var t,s=b.y,r=d.y,q=s.length
if(q!==r.length)return!1
if(b.x!==d.x)return!1
for(t=0;t<q;++t)if(!A.x(a,s[t],c,r[t],e,!1))return!1
return!0},
cB(a){var t=a.w,s=!0
if(!(a===u.P||a===u.T))if(!A.aq(a))if(t!==7)if(!(t===6&&A.cB(a.x)))s=t===8&&A.cB(a.x)
return s},
ku(a){var t
if(!A.aq(a))t=a===u._
else t=!0
return t},
aq(a){var t=a.w
return t===2||t===3||t===4||t===5||a===u.O},
hH(a,b){var t,s,r=Object.keys(b),q=r.length
for(t=0;t<q;++t){s=r[t]
a[s]=b[s]}},
f_(a){return a>0?new Array(a):v.typeUniverse.sEA},
Y:function Y(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
dy:function dy(){this.c=this.b=this.a=null},
eU:function eU(a){this.a=a},
dx:function dx(){},
cu:function cu(a){this.a=a},
hA(a,b,c){return 0},
m:function m(a,b){var _=this
_.a=a
_.e=_.d=_.c=_.b=null
_.$ti=b},
b0:function b0(a,b){this.a=a
this.$ti=b},
h1(a,b,c,d,e){if(c==null)if(b==null){if(a==null)return new A.al(d.h("@<0>").B(e).h("al<1,2>"))
b=A.hY()}else{if(A.ke()===b&&A.kd()===a)return new A.co(d.h("@<0>").B(e).h("co<1,2>"))
if(a==null)a=A.hX()}else{if(b==null)b=A.hY()
if(a==null)a=A.hX()}return A.je(a,b,c,d,e)},
fx(a,b){var t=a[b]
return t===a?null:t},
fz(a,b,c){if(c==null)a[b]=a
else a[b]=c},
fy(){var t=Object.create(null)
A.fz(t,"<non-identifier-key>",t)
delete t["<non-identifier-key>"]
return t},
je(a,b,c,d,e){var t=c!=null?c:new A.eK(d)
return new A.cj(a,b,t,d.h("@<0>").B(e).h("cj<1,2>"))},
e2(a,b){return new A.ag(a.h("@<0>").B(b).h("ag<1,2>"))},
a1(a,b,c){return b.h("@<0>").B(c).h("h6<1,2>").a(A.kh(a,new A.ag(b.h("@<0>").B(c).h("ag<1,2>"))))},
y(a,b){return new A.ag(a.h("@<0>").B(b).h("ag<1,2>"))},
iF(a){return new A.b_(a.h("b_<0>"))},
iG(a,b){return b.h("h7<0>").a(A.ki(a,new A.b_(b.h("b_<0>"))))},
fA(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
jG(a,b){return J.P(a,b)},
jH(a){return J.B(a)},
cX(a,b,c){var t=A.e2(b,c)
a.T(0,new A.e3(t,b,c))
return t},
fm(a){var t,s={}
if(A.fM(a))return"{...}"
t=new A.z("")
try{B.a.i($.X,a)
t.a+="{"
s.a=!0
a.T(0,new A.e6(s,t))
t.a+="}"}finally{if(0>=$.X.length)return A.a($.X,-1)
$.X.pop()}s=t.a
return s.charCodeAt(0)==0?s:s},
al:function al(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
co:function co(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
cj:function cj(a,b,c,d){var _=this
_.f=a
_.r=b
_.w=c
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=d},
eK:function eK(a){this.a=a},
cm:function cm(a,b){this.a=a
this.$ti=b},
cn:function cn(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
b_:function b_(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
dz:function dz(a){this.a=a
this.b=null},
cq:function cq(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
e3:function e3(a,b,c){this.a=a
this.b=b
this.c=c},
a2:function a2(){},
j:function j(){},
e5:function e5(a){this.a=a},
e6:function e6(a,b){this.a=a
this.b=b},
a4:function a4(){},
ct:function ct(){},
jz(a,b,c){var t,s,r,q,p,o=c-b
if(o<=4096)t=$.ij()
else t=new Uint8Array(o)
for(s=a.length,r=0;r<o;++r){q=b+r
if(!(q<s))return A.a(a,q)
p=a[q]
if((p&255)!==p)p=255
t[r]=p}return t},
jy(a,b,c,d){var t=a?$.ii():$.ih()
if(t==null)return null
if(0===c&&d===b.length)return A.hG(t,b)
return A.hG(t,b.subarray(c,d))},
hG(a,b){var t,s
try{t=a.decode(b)
return t}catch(s){}return null},
jd(a,b,c,d,e,f,g,h){var t,s,r,q,p,o,n,m,l,k,j=h>>>2,i=3-(h&3)
for(t=b.length,s=a.length,r=f.$flags|0,q=c,p=0;q<d;++q){if(!(q<t))return A.a(b,q)
o=b[q]
p|=o
j=(j<<8|o)&16777215;--i
if(i===0){n=g+1
m=j>>>18&63
if(!(m<s))return A.a(a,m)
r&2&&A.O(f)
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
r&2&&A.O(f)
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
r&2&&A.O(f)
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
throw A.b(A.fT(b,"Not a byte value at index "+q+": 0x"+B.c.d8(b[q],16),null))},
h5(a,b,c){return new A.bR(a,b)},
jI(a){return a.aw()},
jf(a,b){return new A.eO(a,[],A.kc())},
jg(a,b,c){var t,s=new A.z(""),r=A.jf(s,b)
r.az(a)
t=s.a
return t.charCodeAt(0)==0?t:t},
jA(a){switch(a){case 65:return"Missing extension byte"
case 67:return"Unexpected extension byte"
case 69:return"Invalid UTF-8 byte"
case 71:return"Overlong encoding"
case 73:return"Out of unicode range"
case 75:return"Encoded surrogate"
case 77:return"Unfinished UTF-8 octet sequence"
default:return""}},
eZ:function eZ(){},
eY:function eY(){},
eV:function eV(){},
bE:function bE(){},
dG:function dG(){},
eJ:function eJ(a){this.a=0
this.b=a},
Q:function Q(){},
cG:function cG(){},
cI:function cI(){},
bR:function bR(a,b){this.a=a
this.b=b},
cV:function cV(a,b){this.a=a
this.b=b},
cU:function cU(){},
e_:function e_(a){this.b=a},
eP:function eP(){},
eQ:function eQ(a,b){this.a=a
this.b=b},
eO:function eO(a,b,c){this.c=a
this.a=b
this.b=c},
cW:function cW(){},
e0:function e0(a){this.a=a},
df:function df(){},
et:function et(a){this.a=a},
eX:function eX(a){this.a=a
this.b=16
this.c=0},
kp(a){return A.f9(a)},
fk(a,b,c,d){var t,s=J.iB(a,d)
if(a!==0&&b!=null)for(t=0;t<a;++t)s[t]=b
return s},
fl(a,b,c){var t,s,r=A.d([],c.h("h<0>"))
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.q)(a),++s)B.a.i(r,c.a(a[s]))
if(b)return r
r.$flags=1
return r},
e4(a,b,c){var t=A.iH(a,c)
return t},
iH(a,b){var t,s
if(Array.isArray(a))return A.d(a.slice(0),b.h("h<0>"))
t=A.d([],b.h("h<0>"))
for(s=J.H(a);s.n();)B.a.i(t,s.gq())
return t},
fs(a,b,c){var t,s
A.he(b,"start")
if(c!=null){t=c-b
if(t<0)throw A.b(A.F(c,b,null,"end",null))
if(t===0)return""}s=A.iY(a,b,c)
return s},
iY(a,b,c){var t=a.length
if(b>=t)return""
return A.iO(a,b,c==null||c>t?t:c)},
fq(a,b){return new A.cS(a,A.h4(a,!1,b,!1,!1,!1))},
ko(a,b){return a==null?b==null:a===b},
hj(a,b,c){var t=J.H(b)
if(!t.n())return a
if(c.length===0){do a+=A.p(t.gq())
while(t.n())}else{a+=A.p(t.gq())
for(;t.n();)a=a+c+A.p(t.gq())}return a},
bM(a){if(typeof a=="number"||A.fI(a)||a==null)return J.aG(a)
if(typeof a=="string")return JSON.stringify(a)
return A.hd(a)},
cC(a){return new A.bD(a)},
fa(a){return new A.ac(!1,null,null,a)},
fT(a,b,c){return new A.ac(!0,a,b,c)},
iS(a,b){return new A.bZ(null,null,!0,a,b,"Value not in range")},
F(a,b,c,d,e){return new A.bZ(b,c,!0,a,d,"Invalid value")},
iT(a,b,c,d){if(a<b||a>c)throw A.b(A.F(a,b,c,d,null))
return a},
d5(a,b,c){if(0>a||a>c)throw A.b(A.F(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.b(A.F(b,a,c,"end",null))
return b}return c},
he(a,b){if(a<0)throw A.b(A.F(a,0,null,b,null))
return a},
h2(a,b,c,d){return new A.cM(b,!0,a,d,"Index out of range")},
bd(a){return new A.c5(a)},
hl(a){return new A.dd(a)},
hi(a){return new A.c1(a)},
ad(a){return new A.cF(a)},
dT(a,b,c){return new A.a_(a,b,c)},
iA(a,b,c){var t,s
if(A.fM(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}t=A.d([],u.s)
B.a.i($.X,a)
try{A.k2(a,t)}finally{if(0>=$.X.length)return A.a($.X,-1)
$.X.pop()}s=A.hj(b,u.R.a(t),", ")+c
return s.charCodeAt(0)==0?s:s},
fh(a,b,c){var t,s
if(A.fM(a))return b+"..."+c
t=new A.z(b)
B.a.i($.X,a)
try{s=t
s.a=A.hj(s.a,a,", ")}finally{if(0>=$.X.length)return A.a($.X,-1)
$.X.pop()}t.a+=c
s=t.a
return s.charCodeAt(0)==0?s:s},
k2(a,b){var t,s,r,q,p,o,n,m=a.gu(a),l=0,k=0
while(!0){if(!(l<80||k<3))break
if(!m.n())return
t=A.p(m.gq())
B.a.i(b,t)
l+=t.length+2;++k}if(!m.n()){if(k<=5)return
if(0>=b.length)return A.a(b,-1)
s=b.pop()
if(0>=b.length)return A.a(b,-1)
r=b.pop()}else{q=m.gq();++k
if(!m.n()){if(k<=4){B.a.i(b,A.p(q))
return}s=A.p(q)
if(0>=b.length)return A.a(b,-1)
r=b.pop()
l+=s.length+2}else{p=m.gq();++k
for(;m.n();q=p,p=o){o=m.gq();++k
if(k>100){while(!0){if(!(l>75&&k>3))break
if(0>=b.length)return A.a(b,-1)
l-=b.pop().length+2;--k}B.a.i(b,"...")
return}}r=A.p(q)
s=A.p(p)
l+=s.length+r.length+4}}if(k>b.length+2){l+=5
n="..."}else n=null
while(!0){if(!(l>80&&b.length>3))break
if(0>=b.length)return A.a(b,-1)
l-=b.pop().length+2
if(n==null){l+=5
n="..."}}if(n!=null)B.a.i(b,n)
B.a.i(b,r)
B.a.i(b,s)},
h8(a,b,c,d,e){return new A.aI(a,b.h("@<0>").B(c).B(d).B(e).h("aI<1,2,3,4>"))},
d_(a,b,c,d){var t
if(B.f===c){t=J.B(a)
b=J.B(b)
return A.ep(A.ai(A.ai($.dE(),t),b))}if(B.f===d){t=J.B(a)
b=J.B(b)
c=J.B(c)
return A.ep(A.ai(A.ai(A.ai($.dE(),t),b),c))}t=J.B(a)
b=J.B(b)
c=J.B(c)
d=J.B(d)
d=A.ep(A.ai(A.ai(A.ai(A.ai($.dE(),t),b),c),d))
return d},
ha(a){var t,s=$.dE()
for(t=J.H(a);t.n();)s=A.ai(s,J.B(t.gq()))
return A.ep(s)},
eM:function eM(){},
t:function t(){},
bD:function bD(a){this.a=a},
c2:function c2(){},
ac:function ac(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
bZ:function bZ(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
cM:function cM(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
c5:function c5(a){this.a=a},
dd:function dd(a){this.a=a},
c1:function c1(a){this.a=a},
cF:function cF(a){this.a=a},
d0:function d0(){},
c0:function c0(){},
a_:function a_(a,b,c){this.a=a
this.b=b
this.c=c},
e:function e(){},
ah:function ah(a,b,c){this.a=a
this.b=b
this.$ti=c},
bX:function bX(){},
o:function o(){},
eo:function eo(){this.b=this.a=0},
z:function z(a){this.a=a},
aK:function aK(a){this.$ti=a},
b5:function b5(a,b){this.a=a
this.$ti=b},
at:function at(a,b){this.a=a
this.$ti=b},
W:function W(){},
bc:function bc(a,b){this.a=a
this.$ti=b},
br:function br(a,b,c){this.a=a
this.b=b
this.c=c},
ba:function ba(a,b,c){this.a=a
this.b=b
this.$ti=c},
bI:function bI(){},
iw(a){var t=A.a5(a),s=t.h("a3<1,S>")
return new A.cH(A.e4(new A.a3(a,t.h("S(1)").a(new A.dL(null)),s),!0,s.h("J.E")))},
cH:function cH(a){this.a=a},
dL:function dL(a){this.a=a},
dM:function dM(){},
k5(a){return a},
fo(a,b,c,d){return new A.S(a,b,c,d!=null?A.cX(d,u.N,u.z):null)},
iK(a,b){var t,s,r="insert",q="attributes",p="delete",o="retain",n=A.cX(a,u.N,u.z)
if(n.E(r)){t=n.k(0,r)
a=A.k5(t==null?u.K.a(t):t)
s=typeof a=="string"?a.length:1
return A.fo(r,s,a,u.k.a(n.k(0,q)))}else if(n.E(p))return A.fo(p,A.hJ(n.k(0,p)),"",null)
else if(n.E(o))return A.fo(o,A.hJ(n.k(0,o)),"",u.k.a(n.k(0,q)))
throw A.b(A.fT(a,"Invalid data for Delta operation.",null))},
S:function S(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ed:function ed(){},
dU:function dU(a){this.a=a},
u(a,b){var t=a==null?null:a.l(b)
return t==null?null:A.E(t,null)},
L(a){var t
if(a==null)return null
t=a.l("w:val")
if(t==null)return!0
return!(t==="0"||t==="false"||t==="none")},
j1(a){if(a==null)return null
return new A.eC(A.u(a,"w:before"),A.u(a,"w:after"),A.u(a,"w:line"),a.l("w:lineRule"))},
hm(a){var t
if(a==null)return null
t=A.u(a,"w:left")
if(t==null)t=A.u(a,"w:start")
if(A.u(a,"w:right")==null)A.u(a,"w:end")
return new A.ew(t,A.u(a,"w:firstLine"),A.u(a,"w:hanging"))},
fw(a){if(a==null)return null
a.l("w:val")
a.l("w:color")
return new A.eB(a.l("w:fill"))},
c9(a){var t,s
if(a==null)return null
t=a.l("w:val")
A.u(a,"w:sz")
s=a.l("w:color")
A.u(a,"w:space")
return new A.c8(t,s)},
fu(a){var t,s,r,q
if(a==null)return null
t=A.c9(a.j("w:top"))
s=a.j("w:left")
s=A.c9(s==null?a.j("w:start"):s)
r=A.c9(a.j("w:bottom"))
q=a.j("w:right")
return new A.eu(t,s,r,A.c9(q==null?a.j("w:end"):q),A.c9(a.j("w:insideH")),A.c9(a.j("w:insideV")))},
di(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=null,c="w:val"
if(a==null)return d
t=a.j("w:rFonts")
s=a.j("w:rStyle")
s=s==null?d:s.l(c)
r=t==null
q=r?d:t.l("w:ascii")
p=r?d:t.l("w:hAnsi")
r=r?d:t.l("w:cs")
o=A.L(a.j("w:b"))
n=A.L(a.j("w:i"))
m=a.j("w:u")
m=m==null?d:m.l(c)
l=A.L(a.j("w:strike"))
k=A.L(a.j("w:caps"))
j=A.L(a.j("w:smallCaps"))
i=A.u(a.j("w:sz"),c)
h=a.j("w:color")
h=h==null?d:h.l(c)
g=a.j("w:highlight")
g=g==null?d:g.l(c)
f=A.fw(a.j("w:shd"))
e=a.j("w:vertAlign")
return new A.aW(s,q,p,r,o,n,m,l,k,j,i,h,g,f,e==null?d:e.l(c))},
fv(a){var t,s,r,q,p,o,n,m,l,k=null,j="w:val"
if(a==null)return k
t=a.j("w:numPr")
if(t!=null){s=A.u(t.j("w:numId"),j)
r=A.u(t.j("w:ilvl"),j)
q=new A.ex(s,r==null?0:r)}else q=k
p=a.j("w:tabs")
if(p!=null){s=A.d([],u.fH)
for(r=p.K("w:tab"),o=r.$ti,r=new A.m(r.a(),o.h("m<1>")),o=o.c;r.n();){n=r.b
if(n==null)n=o.a(n)
n.l(j)
m=n.l("w:pos")
if(m!=null)A.E(m,k)
n.l("w:leader")
s.push(new A.dk())}l=s}else l=k
s=a.j("w:pStyle")
s=s==null?k:s.l(j)
r=a.j("w:jc")
r=r==null?k:r.l(j)
return new A.aU(s,q,r,A.j1(a.j("w:spacing")),A.hm(a.j("w:ind")),l,A.fw(a.j("w:shd")),A.fu(a.j("w:pBdr")),A.L(a.j("w:keepNext")),A.L(a.j("w:keepLines")),A.L(a.j("w:pageBreakBefore")),A.L(a.j("w:widowControl")),A.L(a.j("w:contextualSpacing")),A.u(a.j("w:outlineLvl"),j),A.di(a.j("w:rPr")))},
ht(a){if(a==null)return null
A.u(a,"w:w")
a.l("w:type")
return new A.eG()},
hs(a){var t,s,r
if(a==null)return null
t=a.j("w:tblStyle")
t=t==null?null:t.l("w:val")
A.ht(a.j("w:tblW"))
s=a.j("w:jc")
if(s!=null)s.l("w:val")
s=A.fu(a.j("w:tblBorders"))
A.u(a.j("w:tblInd"),"w:w")
r=a.j("w:tblLayout")
if(r!=null)r.l("w:type")
return new A.eE(t,s)},
j4(a){var t,s=a.j("w:trHeight"),r=A.u(s,"w:val")
if(s!=null)s.l("w:hRule")
t=A.L(a.j("w:tblHeader"))
A.L(a.j("w:cantSplit"))
return new A.eF(r,t===!0)},
j3(a){var t,s,r,q,p,o="w:val",n=a.j("w:vMerge")
A.ht(a.j("w:tcW"))
t=A.u(a.j("w:gridSpan"),o)
if(n==null)s=null
else{s=n.l(o)
if(s==null)s="continue"}r=A.fu(a.j("w:tcBorders"))
q=A.fw(a.j("w:shd"))
p=a.j("w:vAlign")
return new A.eD(t,s,r,q,p==null?null:p.l(o))},
j_(a){var t,s,r,q,p,o,n,m,l,k,j,i
if(a==null)return null
t=a.j("w:pgSz")
s=a.j("w:pgMar")
r=new A.eA(a)
q=A.u(t,"w:w")
p=A.u(t,"w:h")
if(t!=null)t.l("w:orient")
o=A.u(s,"w:top")
n=A.u(s,"w:right")
m=A.u(s,"w:bottom")
l=A.u(s,"w:left")
k=A.u(s,"w:header")
j=A.u(s,"w:footer")
A.u(s,"w:gutter")
A.L(a.j("w:titlePg"))
i=r.$1("w:headerReference")
r=r.$1("w:footerReference")
a.ah()
return new A.ez(q,p,o,n,m,l,k,j,i,r)},
j0(a){if(a==null)return B.a2
A.L(a.j("w:autoHyphenation"))
A.L(a.j("w:evenAndOddHeaders"))
A.u(a.j("w:defaultTabStop"),"w:val")
return new A.dj()},
eC:function eC(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ew:function ew(a,b,c){this.a=a
this.c=b
this.d=c},
dk:function dk(){},
eB:function eB(a){this.c=a},
c8:function c8(a,b){this.a=a
this.c=b},
eu:function eu(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
aW:function aW(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
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
ex:function ex(a,b){this.a=a
this.b=b},
aU:function aU(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
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
K:function K(){},
aa:function aa(a){this.a=a},
cd:function cd(){},
bf:function bf(a){this.a=a},
cb:function cb(){},
cc:function cc(a){this.b=a},
ca:function ca(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
bg:function bg(a){this.a=a},
bj:function bj(a){this.a=a},
bn:function bn(a){this.a=a},
bp:function bp(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.c=b
_.d=c
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h},
ax:function ax(){},
aV:function aV(a,b){this.a=a
this.b=b},
ey:function ey(){},
bi:function bi(a,b,c){this.a=a
this.b=b
this.c=c},
bo:function bo(a,b){this.a=a
this.b=b},
bm:function bm(a){this.a=a},
aw:function aw(){},
a9:function a9(a,b){this.a=a
this.b=b},
eG:function eG(){},
eE:function eE(a,b){this.a=a
this.d=b},
eF:function eF(a,b){this.a=a
this.c=b},
eD:function eD(a,b,c,d,e){var _=this
_.b=a
_.c=b
_.d=c
_.e=d
_.f=e},
dl:function dl(a,b){this.a=a
this.b=b},
dm:function dm(a,b){this.a=a
this.b=b},
aY:function aY(a,b,c){this.a=a
this.b=b
this.c=c},
bl:function bl(a){this.a=a},
bh:function bh(a,b){this.a=a
this.b=b},
ez:function ez(a,b,c,d,e,f,g,h,i,j){var _=this
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
eA:function eA(a){this.a=a},
ev:function ev(a,b){this.a=a
this.b=b},
dg:function dg(a,b){this.a=a
this.b=b},
dj:function dj(){},
ho(a){var t,s,r,q,p,o=null,n="w:val",m=a.l("w:ilvl")
m=A.E(m==null?"":m,o)
if(m==null)m=0
t=a.j("w:start")
t=t==null?o:t.l(n)
t=A.E(t==null?"":t,o)
if(t==null)t=1
s=a.j("w:numFmt")
s=s==null?o:s.l(n)
if(s==null)s="decimal"
r=a.j("w:lvlText")
r=r==null?o:r.l(n)
if(r==null)r=""
q=a.j("w:lvlJc")
if(q!=null)q.l(n)
q=a.j("w:pPr")
q=A.hm(q==null?o:q.j("w:ind"))
A.di(a.j("w:rPr"))
p=a.j("w:lvlRestart")
p=p==null?o:p.l(n)
A.E(p==null?"":p,o)
return new A.dh(m,t,s,r,q)},
hn(a,b){var t=a==null?A.y(u.S,u.e):a
return new A.ay(t,b==null?A.y(u.S,u.n):b)},
hp(a,b){return A.hn(a,b)},
iZ(a0){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=null,b="w:abstractNumId",a=A.cf()
A.cg(a0,new A.ab(a,A.d([],u.v)))
a=new A.T(a.b,u.C).ga3(0)
t=u.S
s=A.y(t,u.e)
for(r=a.K("w:abstractNum"),q=r.$ti,r=new A.m(r.a(),q.h("m<1>")),p=u.aV,q=q.c;r.n();){o=r.b
if(o==null)o=q.a(o)
n=o.l(b)
m=A.E(n==null?"":n,c)
if(m==null)continue
l=A.y(t,p)
for(n=o.K("w:lvl"),k=n.$ti,n=new A.m(n.a(),k.h("m<1>")),k=k.c;n.n();){j=n.b
i=A.ho(j==null?k.a(j):j)
l.m(0,i.a,i)}o=o.j("w:multiLevelType")
if(o!=null)o.l("w:val")
s.m(0,m,new A.be(l))}h=A.y(t,u.n)
for(a=a.K("w:num"),r=a.$ti,a=new A.m(a.a(),r.h("m<1>")),r=r.c;a.n();){q=a.b
if(q==null)q=r.a(q)
o=q.l("w:numId")
g=A.E(o==null?"":o,c)
o=q.j(b)
o=o==null?c:o.l("w:val")
f=A.E(o==null?"":o,c)
if(g==null||f==null)continue
e=A.y(t,p)
for(q=q.K("w:lvlOverride"),o=q.$ti,q=new A.m(q.a(),o.h("m<1>")),o=o.c;q.n();){n=q.b
d=(n==null?o.a(n):n).j("w:lvl")
if(d!=null){i=A.ho(d)
e.m(0,i.a,i)}}h.m(0,g,new A.bk(f,e))}return A.hn(s,h)},
kj(a,b){var t
switch(b){case"decimal":return""+a
case"decimalZero":t=""+a
return a<10?"0"+t:t
case"lowerLetter":return A.hQ(a).toLowerCase()
case"upperLetter":return A.hQ(a).toUpperCase()
case"lowerRoman":return A.hS(a).toLowerCase()
case"upperRoman":return A.hS(a)
case"bullet":return""
case"none":return""
default:return""+a}},
hQ(a){var t,s
for(t=a,s="";t>0;){--t
s+=A.i(65+B.c.bM(t,26))
t=B.c.an(t,26)}return new A.c_(A.d((s.charCodeAt(0)==0?s:s).split(""),u.s),u.bJ).aZ(0)},
hS(a){var t,s,r,q,p,o=new A.z("")
for(t=a,s=0;s<13;++s){r=B.ai[s]
q=r.a
p=r.b
for(;t>=q;){o.a+=p
t-=q}}r=o.a
return r.charCodeAt(0)==0?r:r},
iJ(a){var t,s=a.length
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
dh:function dh(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.f=e},
be:function be(a){this.c=a},
bk:function bk(a,b){this.b=a
this.c=b},
ay:function ay(a,b){this.a=a
this.b=b},
e8:function e8(a,b){this.a=a
this.b=b},
e9:function e9(){},
ea:function ea(a){this.a=a},
fZ(a,b,c,d,e){var t=B.b.M(b,"/")?B.b.C(b,1):b,s=a.a.a5(t)
return s==null?d.$0():c.$1(s)},
dN:function dN(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.x=e
_.y=f},
dO:function dO(a){this.a=a},
hq(a,b,c){return new A.az(c,b,a==null?A.y(u.N,u.U):a)},
hr(a,b,c){return A.hq(a,b,c)},
j2(a){var t,s,r,q,p,o,n,m,l,k,j=null,i="w:val",h="w:default",g=A.cf()
A.cg(a,new A.ab(g,A.d([],u.v)))
g=new A.T(g.b,u.C).ga3(0)
t=g.j("w:docDefaults")
if(t!=null){s=t.j("w:rPrDefault")
r=A.di(s==null?j:s.j("w:rPr"))
s=t.j("w:pPrDefault")
q=A.fv(s==null?j:s.j("w:pPr"))}else{q=j
r=q}p=A.y(u.N,u.U)
for(g=g.K("w:style"),s=g.$ti,g=new A.m(g.a(),s.h("m<1>")),s=s.c;g.n();){o=g.b
if(o==null)o=s.a(o)
n=o.l("w:styleId")
if(n==null)continue
m=o.l("w:type")
if(m==null)m="paragraph"
l=o.j("w:name")
if(l!=null)l.l(i)
l=o.j("w:basedOn")
l=l==null?j:l.l(i)
k=o.j("w:link")
if(k!=null)k.l(i)
k=o.l(h)==="1"||o.l(h)==="true"
p.m(0,n,new A.aX(n,m,l,k,A.fv(o.j("w:pPr")),A.di(o.j("w:rPr")),A.hs(o.j("w:tblPr"))))}return A.hq(p,q,r)},
aX:function aX(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.d=c
_.f=d
_.r=e
_.w=f
_.x=g},
az:function az(a,b,c){this.a=a
this.b=b
this.c=c},
iv(a){var t,s,r,q,p,o,n,m,l,k,j="ContentType",i=A.cf()
A.cg(a,new A.ab(i,A.d([],u.v)))
t=u.N
s=A.y(t,t)
t=A.y(t,t)
for(i=B.a.gu(new A.T(i.b,u.C).ga3(0).d),r=new A.U(i,u.y),q=u.X;r.n();){p=q.a(i.gq())
o=p.b
n=B.b.aW(o,":")
switch(n<0?o:B.b.C(o,n+1)){case"Default":m=p.l("Extension")
l=p.l(j)
if(m!=null&&l!=null)s.m(0,m.toLowerCase(),l)
break
case"Override":k=p.l("PartName")
l=p.l(j)
if(k!=null&&l!=null)t.m(0,k,l)
break}}return new A.dK(s,t)},
dK:function dK(a,b){this.a=a
this.b=b},
eb:function eb(a,b,c){this.a=a
this.b=b
this.c=c},
ec:function ec(){},
hf(){var t=A.d([],u.gb)
return new A.d8(t)},
iV(a){var t,s,r,q,p,o,n,m,l,k,j=A.cf()
A.cg(a,new A.ab(j,A.d([],u.v)))
t=A.hf()
for(j=B.a.gu(new A.T(j.b,u.C).ga3(0).d),s=new A.U(j,u.y),r=t.a,q=u.X;s.n();){p=q.a(j.gq())
o=p.b
n=B.b.aW(o,":")
if((n<0?o:B.b.C(o,n+1))!=="Relationship")continue
m=p.l("Id")
l=p.l("Type")
k=p.l("Target")
if(m==null||l==null||k==null)continue
B.a.i(r,new A.d7(m,l,k,p.l("TargetMode")==="External"))}return t},
d7:function d7(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
d8:function d8(a){this.a=a},
cf(){var t=A.d([],u.m)
return new A.dp(t)},
ak:function ak(){},
ch:function ch(a){this.b=a},
ce:function ce(a){this.b=a},
dn:function dn(a){this.b=a},
dq:function dq(a,b){this.b=a
this.c=b},
aA:function aA(a,b){this.a=a
this.b=b},
V:function V(a,b,c){this.b=a
this.c=b
this.d=c},
dp:function dp(a){this.b=a},
ab:function ab(a,b){this.a=a
this.b=b},
eL:function eL(){},
v(a,b,c){return new A.eH(A.j9(a,b,c),null,null)},
j9(a,b,c){var t=b.length,s=1,r=0,q=0
while(!0){if(!(q<c&&q<t))break
if(!(q<t))return A.a(b,q)
if(b.charCodeAt(q)===10){++s
r=q+1}++q}return a+" (linha "+s+", coluna "+(c-r+1)+")"},
cg(a,b){var t,s=a.length
if(s!==0){if(0>=s)return A.a(a,0)
s=a.charCodeAt(0)===65279}else s=!1
t=s?1:0
new A.ds(t===0?a:B.b.C(a,t),b).bu()},
ja(a){var t,s,r
for(t=a.length,s=0;s<t;++s){r=a.charCodeAt(s)
if(r===32||r===9||r===10||r===13)return s}return-1},
jb(a){var t,s,r,q,p,o,n=u.N,m=A.y(n,n)
for(n=A.fq("([A-Za-z]+)\\s*=\\s*(\"([^\"]*)\"|'([^']*)')",!0).cC(0,a),n=new A.ci(n.a,n.b,n.c),t=u.d;n.n();){s=n.d
r=(s==null?t.a(s):s).b
q=r.length
if(1>=q)return A.a(r,1)
p=r[1]
p.toString
if(3>=q)return A.a(r,3)
o=r[3]
if(o==null){if(4>=q)return A.a(r,4)
r=r[4]}else r=o
m.m(0,p,r==null?"":r)}return m},
aB:function aB(a,b){this.a=a
this.b=b},
dr:function dr(){},
eH:function eH(a,b,c){this.a=a
this.b=b
this.c=c},
ds:function ds(a,b){this.a=a
this.b=b
this.c=0},
cJ(a){var t=new A.dV()
t.bV(a)
return t},
dV:function dV(){this.a=$
this.b=0
this.c=2147483647},
dW:function dW(a,b,c,d){var _=this
_.a=a
_.b=null
_.c=b
_.e=_.d=0
_.r=c
_.w=d},
dH:function dH(a){this.b=a},
ff(a,b,c,d){var t,s,r=new A.cN(b)
if(d==null)d=0
if(c==null)c=a.length-d
t=a.length
if(d+c>t)c=t-d
s=u.gc.b(a)?a:new Uint8Array(A.fG(a))
t=J.bB(B.e.ga2(s),s.byteOffset+d,c)
r.b=t
r.d=t.length
return r},
cN:function cN(a){var _=this
_.b=null
_.c=0
_.d=$
_.a=a},
cO:function cO(){},
d1:function d1(a){this.b=0
this.c=a},
d2:function d2(){},
jc(b2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8=A.d([],u.bV),a9=A.y(u.N,u.S),b0=new A.eI(a8,a9,new Uint8Array(0)),b1=b2.length
if(b1===0)return b0
t=A.jK(b2)
if(t<0)throw A.b(B.a6)
s=A.hR(b2,t+10)
r=A.ap(b2,t+12)
q=A.ap(b2,t+16)
p=t+22
b0.c=new Uint8Array(A.fG(A.c3(b2,p,p+A.hR(b2,t+20))))
o=q+r
n=q
m=0
while(!0){if(!(m<s&&n<o))break
if(A.ap(b2,n)!==33639248)throw A.b(B.a7)
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
A.ap(b2,n+16)
j=A.ap(b2,n+20)
i=A.ap(b2,n+24)
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
b=A.ap(b2,n+42)
a=n+46
a0=a+((g|h<<8)>>>0)
a1=a0+((e|f<<8)>>>0)+((c|d<<8)>>>0)
a2=A.jF(b2,a,a0,(k&2048)!==0)
if(j===4294967295||i===4294967295||b===4294967295)throw A.b(A.bd("ZIP64 archives are not supported."))
if(A.ap(b2,b)!==67324752)throw A.b(B.a8)
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
if((k&8)!==0)a5=a4+4<=b1&&A.ap(b2,a4)===134695760?a4+16:a4+12
else a5=a4
a6=new A.dt()
A.c3(b2,b,a5)
A.c3(b2,n,a1)
a6.d=A.c3(b2,a3,a4)
a6.e=(l|p<<8)>>>0
a6.r=i
a7=a9.k(0,a2)
if(a7!=null)B.a.m(a8,a7,a6)
else{a9.m(0,a2,a8.length)
B.a.i(a8,a6)}++m
n=a1}return b0},
jK(a){var t,s=a.length,r=s>65558?s-65558:0
for(t=s-22;t>=r;--t)if(A.ap(a,t)===101010256)return t
return-1},
jF(a,b,c,d){var t,s,r=A.c3(a,b,c)
if(!d)return B.D.ad(r)
try{t=B.E.ad(r)
return t}catch(s){t=B.D.ad(r)
return t}},
hR(a,b){var t,s,r=a.length
if(!(b>=0&&b<r))return A.a(a,b)
t=a[b]
s=b+1
if(!(s<r))return A.a(a,s)
return(t|a[s]<<8)>>>0},
ap(a,b){var t,s,r,q,p=a.length
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
dt:function dt(){var _=this
_.d=null
_.e=8
_.r=0
_.w=null},
eI:function eI(a,b,c){this.a=a
this.b=b
this.c=c},
R:function R(a){this.b=a},
bb:function bb(a){this.b=a},
db:function db(a){this.b=a},
aT:function aT(a){this.b=a},
av:function av(a){this.b=a},
I(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t){return new A.aN(o,r,f,l,t,g,a,e,h,i,p,m,k,d,n,s,q,j)},
aN:function aN(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r){var _=this
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
_.cR=r},
cK:function cK(a){this.b=a},
cL:function cL(a,b,c,d){var _=this
_.x=a
_.y=b
_.z=c
_.dx=d},
aO:function aO(a,b){this.d=a
this.e=b},
fe(a,b){var t,s,r,q,p,o,n,m,l,k
if(a.e==null)a.e="wp:"+b
t=a.y1
if(t!=null)for(s=t.length,r=0;r<t.length;t.length===s||(0,A.q)(t),++r)A.fe(t[r],b)
q=a.k1
if(q!=null)for(s=q.length,r=0;r<q.length;q.length===s||(0,A.q)(q),++r)for(p=q[r].e,o=p.length,n=0;n<p.length;p.length===o||(0,A.q)(p),++n)for(m=p[n].z,l=m.length,k=0;k<m.length;m.length===l||(0,A.q)(m),++k)A.fe(m[k],b)},
fd(a){var t
$label0$0:{if("center"===a){t=B.u
break $label0$0}if("right"===a||"end"===a){t=B.v
break $label0$0}if("both"===a){t=B.w
break $label0$0}if("distribute"===a){t=B.x
break $label0$0}t=null
break $label0$0}return t},
bK(a,b){},
fc(a){if(a==null||a==="auto")return null
return"#"+A.p(a)},
h_(a){var t=a==null?null:a.c
if(t==null||t==="auto")return null
return"#"+A.p(t)},
iy(a){var t
$label0$0:{if(0===a){t=B.M
break $label0$0}if(1===a){t=B.O
break $label0$0}if(2===a){t=B.Q
break $label0$0}if(3===a){t=B.N
break $label0$0}if(4===a){t=B.L
break $label0$0}t=B.P
break $label0$0}return t},
ix(a){var t,s,r=a.b
if(r==null)return"\u2022"
t=A.E(r,16)
if(t==null)return"\u2022"
$label0$0:{if(61623===t){s="\u2022"
break $label0$0}if(61607===t){s="\u25a0"
break $label0$0}if(61551===t){s="\u25cb"
break $label0$0}if(61692===t){s="\u2713"
break $label0$0}if(61656===t){s="\u27a2"
break $label0$0}s=t>=61440&&t<=61695?"\u2022":A.i(t)
break $label0$0}return s},
bJ:function bJ(){},
dP:function dP(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
dR:function dR(a,b){this.a=a
this.b=b},
dS:function dS(){},
dQ:function dQ(){},
cl:function cl(a){this.b=a},
eR:function eR(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
eS:function eS(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
iR(a){var t,s,r={},q=A.d([],u.c7)
r.a=0
new A.el(r,q,new A.ej(q),new A.ek(q)).$2(a,B.r)
t=q.length===0?null:B.a.gH(q)
s=t==null?null:t.k(0,"insert")
if(typeof s!="string"||!B.b.bF(s,"\n"))B.a.i(q,A.a1(["insert","\n"],u.N,u.z))
return A.a1(["ops",q],u.N,u.z)},
fp(a,b){var t,s,r,q,p,o="table-cell-block",n="table-th-block",m="header",l="list",k="table-cell",j="table-th",i="align",h=b.k(0,o)
if(h==null)h=b.k(0,n)
t=h==null
s=!t
r=u.N
q=u.z
p=A.y(r,q)
if(b.E(m)&&t)p.m(0,m,b.k(0,m))
if(b.E(l)&&t)p.m(0,l,b.k(0,l))
if(b.E(m)&&s)p.m(0,"table-header",A.a1(["cellId",h,"value",b.k(0,m)],r,q))
else if(b.E(l)&&s)p.m(0,"table-list",A.a1(["cellId",h,"value",b.k(0,l)],r,q))
else if(b.E(o))p.m(0,o,b.k(0,o))
if(b.E(n)&&!b.E(m)&&!b.E(l))p.m(0,n,b.k(0,n))
if(b.E(k))p.m(0,k,b.k(0,k))
if(b.E(j))p.m(0,j,b.k(0,j))
if(a.ay===B.u)p.m(0,i,"center")
if(a.ay===B.v)p.m(0,i,"right")
t=a.ay
if(t===B.w||t===B.x)p.m(0,i,"justify")
return p},
iQ(a){switch(a){case B.M:return 1
case B.O:return 2
case B.Q:return 3
case B.N:return 4
case B.L:return 5
case B.P:return 6}},
iP(a){var t,s,r,q,p=a.a,o=a.$ti.h("4?"),n=o.a(p.k(0,"table-cell-block"))
if(n==null)n=o.a(p.k(0,"table-th-block"))
if(typeof n=="string"&&n.length!==0)return n
t=u.f
if(t.b(n))return A.fE(n.k(0,"cellId"))
s=o.a(p.k(0,"table-header"))
if(s==null)s=o.a(p.k(0,"table-list"))
if(t.b(s))return A.fE(s.k(0,"cellId"))
r=o.a(p.k(0,"table-cell"))
if(r==null)r=o.a(p.k(0,"table-th"))
if(t.b(r)){q=r.k(0,"data-row")
if(typeof q=="string")return"cell-"+q}return null},
ek:function ek(a){this.a=a},
ej:function ej(a){this.a=a},
el:function el(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
em:function em(){},
kx(){var t,s=new A.f7(),r=u.eH.a(self)
if(typeof s=="function")A.a6(A.fa("Attempting to rewrap a JS function."))
t=function(a,b){return function(c){return a(b,c,arguments.length)}}(A.jE,s)
t[$.fQ()]=s
r.benchParse=t
r.benchReady=!0},
f7:function f7(){},
c3(a,b,c){var t=a.BYTES_PER_ELEMENT
c=A.d5(b,c,B.c.bU(a.byteLength,t))
return J.bB(B.e.ga2(a),a.byteOffset+b*t,(c-b)*t)},
kI(a){A.fP(new A.bS("Field '"+a+"' has been assigned during initialization."),new Error())},
bA(){A.fP(new A.bS("Field '' has not been initialized."),new Error())},
jE(a,b,c){u.Z.a(a)
if(A.aD(c)>=1)return a.$1(b)
return a.$0()},
jZ(a){var t=a.b
return(t==null||t===B.l)&&a.c==="\n"},
jY(a){var t=a.b
return t===B.j||t===B.m||t===B.k},
k4(a){var t,s,r,q,p,o,n,m=null,l=A.d([],u.l)
for(t=a.length,s=m,r=0;r<a.length;a.length===t||(0,A.q)(a),++r,s=q){q=a[r]
p=q.b
if((p==null||p===B.l)&&q.c==="\n"){p=s!=null
if(p){o=s.b
o=o===B.j||o===B.m||o===B.k}else o=!1
if(o)continue
if(p){p=s.b
o=!((p==null||p===B.l)&&s.c==="\n")
p=o}else p=!1
q.ay=p?s.ay:m}B.a.i(l,q)}n=l.length===0?m:B.a.gH(l)
t=!1
if(n!=null)if(!A.jZ(n))if(!A.jY(n)){t=n.ay
t=t===B.u||t===B.v||t===B.w||t===B.x}if(t)B.a.i(l,A.I(m,m,m,m,m,m,m,m,m,m,n.ay,m,m,m,m,m,m,"\n",m,m))
return l},
j8(a){var t,s,r,q
if(!A.j6(a))return a
for(t=a.length,s=0,r="";s<t;++s){q=a.charCodeAt(s)
switch(q){case 38:r+="&amp;"
break
case 60:r+="&lt;"
break
case 62:r+="&gt;"
break
case 13:r+="&#xD;"
break
default:r+=A.i(q)}}return r.charCodeAt(0)==0?r:r},
j7(a){var t,s,r,q
if(!A.j5(a))return a
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
default:r+=A.i(q)}}return r.charCodeAt(0)==0?r:r},
j6(a){var t,s,r
for(t=a.length,s=0;s<t;++s){r=a.charCodeAt(s)
if(r===38||r===60||r===62||r===13)return!0}return!1},
j5(a){var t,s,r
for(t=a.length,s=0;s<t;++s){r=a.charCodeAt(s)
if(r===38||r===60||r===62||r===34||r===9||r===10||r===13)return!0}return!1}},B={}
var w=[A,J,B]
var $={}
A.fi.prototype={}
J.cP.prototype={
R(a,b){return a===b},
gD(a){return A.d4(a)},
p(a){return"Instance of '"+A.eg(a)+"'"},
gL(a){return A.b1(A.fH(this))}}
J.cQ.prototype={
p(a){return String(a)},
gD(a){return a?519018:218159},
gL(a){return A.b1(u.w)},
$iC:1,
$iA:1}
J.bO.prototype={
R(a,b){return null==b},
p(a){return"null"},
gD(a){return 0},
$iC:1}
J.bQ.prototype={$ia0:1}
J.as.prototype={
gD(a){return 0},
p(a){return String(a)}}
J.d3.prototype={}
J.c4.prototype={}
J.af.prototype={
p(a){var t=a[$.fQ()]
if(t==null)return this.bQ(a)
return"JavaScript function for "+J.aG(t)},
$iaM:1}
J.b7.prototype={
gD(a){return 0},
p(a){return String(a)}}
J.b9.prototype={
gD(a){return 0},
p(a){return String(a)}}
J.h.prototype={
i(a,b){A.a5(a).c.a(b)
a.$flags&1&&A.O(a,29)
a.push(b)},
Y(a,b){A.a5(a).h("e<1>").a(b)
a.$flags&1&&A.O(a,"addAll",2)
this.bY(a,b)
return},
bY(a,b){var t,s
u.b.a(b)
t=b.length
if(t===0)return
if(a===b)throw A.b(A.ad(a))
for(s=0;s<t;++s)a.push(b[s])},
cH(a){a.$flags&1&&A.O(a,"clear","clear")
a.length=0},
bG(a,b){var t,s=A.fk(a.length,"",!1,u.N)
for(t=0;t<a.length;++t)this.m(s,t,A.p(a[t]))
return s.join(b)},
cU(a,b,c,d){var t,s,r
d.a(b)
A.a5(a).B(d).h("1(1,2)").a(c)
t=a.length
for(s=b,r=0;r<t;++r){s=c.$2(s,a[r])
if(a.length!==t)throw A.b(A.ad(a))}return s},
a_(a,b){if(!(b>=0&&b<a.length))return A.a(a,b)
return a[b]},
bO(a,b,c){var t=a.length
if(b>t)throw A.b(A.F(b,0,t,"start",null))
if(c<b||c>t)throw A.b(A.F(c,b,t,"end",null))
if(b===c)return A.d([],A.a5(a))
return A.d(a.slice(b,c),A.a5(a))},
gH(a){var t=a.length
if(t>0)return a[t-1]
throw A.b(A.fg())},
gA(a){return a.length===0},
gae(a){return a.length!==0},
p(a){return A.fh(a,"[","]")},
gu(a){return new J.bC(a,a.length,A.a5(a).h("bC<1>"))},
gD(a){return A.d4(a)},
gt(a){return a.length},
k(a,b){if(!(b>=0&&b<a.length))throw A.b(A.f0(a,b))
return a[b]},
m(a,b,c){A.a5(a).c.a(c)
a.$flags&2&&A.O(a)
if(!(b>=0&&b<a.length))throw A.b(A.f0(a,b))
a[b]=c},
$in:1,
$ie:1,
$ir:1}
J.dX.prototype={}
J.bC.prototype={
gq(){var t=this.d
return t==null?this.$ti.c.a(t):t},
n(){var t,s=this,r=s.a,q=r.length
if(s.b!==q){r=A.q(r)
throw A.b(r)}t=s.c
if(t>=q){s.sbi(null)
return!1}s.sbi(r[t]);++s.c
return!0},
sbi(a){this.d=this.$ti.h("1?").a(a)},
$iw:1}
J.bP.prototype={
aU(a,b){var t
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){t=B.c.gaY(b)
if(this.gaY(a)===t)return 0
if(this.gaY(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gaY(a){return a===0?1/a<0:a<0},
cT(a){var t,s
if(a>=0){if(a<=2147483647)return a|0}else if(a>=-2147483648){t=a|0
return a===t?t:t-1}s=Math.floor(a)
if(isFinite(s))return s
throw A.b(A.bd(""+a+".floor()"))},
a1(a){if(a>0){if(a!==1/0)return Math.round(a)}else if(a>-1/0)return 0-Math.round(0-a)
throw A.b(A.bd(""+a+".round()"))},
d7(a){if(a<0)return-Math.round(-a)
else return Math.round(a)},
bD(a,b,c){if(B.c.aU(b,c)>0)throw A.b(A.hV(b))
if(this.aU(a,b)<0)return b
if(this.aU(a,c)>0)return c
return a},
d8(a,b){var t,s,r,q,p
if(b<2||b>36)throw A.b(A.F(b,2,36,"radix",null))
t=a.toString(b)
s=t.length
r=s-1
if(!(r>=0))return A.a(t,r)
if(t.charCodeAt(r)!==41)return t
q=/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(t)
if(q==null)A.a6(A.bd("Unexpected toString result: "+t))
s=q.length
if(1>=s)return A.a(q,1)
t=q[1]
if(3>=s)return A.a(q,3)
p=+q[3]
s=q[2]
if(s!=null){t+=s
p-=s.length}return t+B.b.b3("0",p)},
p(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gD(a){var t,s,r,q,p=a|0
if(a===p)return p&536870911
t=Math.abs(a)
s=Math.log(t)/0.6931471805599453|0
r=Math.pow(2,s)
q=t<1?t/r:r/t
return((q*9007199254740992|0)+(q*3542243181176521|0))*599197+s*1259&536870911},
bM(a,b){var t=a%b
if(t===0)return 0
if(t>0)return t
return t+b},
bU(a,b){if((a|0)===a)if(b>=1||b<-1)return a/b|0
return this.bz(a,b)},
an(a,b){return(a|0)===a?a/b|0:this.bz(a,b)},
bz(a,b){var t=a/b
if(t>=-2147483648&&t<=2147483647)return t|0
if(t>0){if(t!==1/0)return Math.floor(t)}else if(t>-1/0)return Math.ceil(t)
throw A.b(A.bd("Result of truncating division is "+A.p(t)+": "+A.p(a)+" ~/ "+b))},
ai(a,b){if(b<0)throw A.b(A.hV(b))
return b>31?0:a<<b>>>0},
cv(a,b){return b>31?0:a<<b>>>0},
aR(a,b){var t
if(a>0)t=this.aQ(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
aQ(a,b){return b>31?0:a>>>b},
gL(a){return A.b1(u.H)},
$icz:1,
$ibz:1}
J.bN.prototype={
gL(a){return A.b1(u.S)},
$iC:1,
$ic:1}
J.cR.prototype={
gL(a){return A.b1(u.i)},
$iC:1}
J.b6.prototype={
bF(a,b){var t=b.length,s=a.length
if(t>s)return!1
return b===this.C(a,s-t)},
aj(a,b,c){var t
if(c<0||c>a.length)throw A.b(A.F(c,0,a.length,null,null))
t=c+b.length
if(t>a.length)return!1
return b===a.substring(c,t)},
M(a,b){return this.aj(a,b,0)},
v(a,b,c){return a.substring(b,A.d5(b,c,a.length))},
C(a,b){return this.v(a,b,null)},
W(a){var t,s,r,q=a.trim(),p=q.length
if(p===0)return q
if(0>=p)return A.a(q,0)
if(q.charCodeAt(0)===133){t=J.iD(q,1)
if(t===p)return""}else t=0
s=p-1
if(!(s>=0))return A.a(q,s)
r=q.charCodeAt(s)===133?J.iE(q,s):p
if(t===0&&r===p)return q
return q.substring(t,r)},
b3(a,b){var t,s
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.b(B.a1)
for(t=a,s="";!0;){if((b&1)===1)s=t+s
b=b>>>1
if(b===0)break
t+=t}return s},
V(a,b,c){var t
if(c<0||c>a.length)throw A.b(A.F(c,0,a.length,null,null))
t=a.indexOf(b,c)
return t},
aW(a,b){return this.V(a,b,0)},
b_(a,b){var t=a.length,s=b.length
if(t+s>t)t-=s
return a.lastIndexOf(b,t)},
S(a,b){return A.kB(a,b,0)},
p(a){return a},
gD(a){var t,s,r
for(t=a.length,s=0,r=0;r<t;++r){s=s+a.charCodeAt(r)&536870911
s=s+((s&524287)<<10)&536870911
s^=s>>6}s=s+((s&67108863)<<3)&536870911
s^=s>>11
return s+((s&16383)<<15)&536870911},
gL(a){return A.b1(u.N)},
gt(a){return a.length},
$iC:1,
$iee:1,
$if:1}
A.bq.prototype={
gu(a){var t=this.a
return new A.bF(t.gu(t),A.k(this).h("bF<1,2>"))},
gt(a){var t=this.a
return t.gt(t)},
gA(a){var t=this.a
return t.gA(t)},
p(a){return this.a.p(0)}}
A.bF.prototype={
n(){return this.a.n()},
gq(){return this.$ti.y[1].a(this.a.gq())},
$iw:1}
A.aH.prototype={}
A.ck.prototype={$in:1}
A.aI.prototype={
aT(a,b,c){return new A.aI(this.a,this.$ti.h("@<1,2>").B(b).B(c).h("aI<1,2,3,4>"))},
k(a,b){return this.$ti.h("4?").a(this.a.k(0,b))},
m(a,b,c){var t=this.$ti
t.y[2].a(b)
t.y[3].a(c)
this.a.m(0,t.c.a(b),t.y[1].a(c))},
a6(a,b){return this.$ti.h("4?").a(this.a.a6(0,b))},
T(a,b){this.a.T(0,new A.dI(this,this.$ti.h("~(3,4)").a(b)))},
gJ(){var t=this.$ti
return A.ip(this.a.gJ(),t.c,t.y[2])},
gt(a){var t=this.a
return t.gt(t)},
gA(a){var t=this.a
return t.gA(t)},
au(a,b){this.a.au(0,new A.dJ(this,this.$ti.h("A(3,4)").a(b)))}}
A.dI.prototype={
$2(a,b){var t=this.a.$ti
t.c.a(a)
t.y[1].a(b)
this.b.$2(t.y[2].a(a),t.y[3].a(b))},
$S(){return this.a.$ti.h("~(1,2)")}}
A.dJ.prototype={
$2(a,b){var t=this.a.$ti
t.c.a(a)
t.y[1].a(b)
return this.b.$2(t.y[2].a(a),t.y[3].a(b))},
$S(){return this.a.$ti.h("A(1,2)")}}
A.bS.prototype={
p(a){return"LateInitializationError: "+this.a}}
A.en.prototype={}
A.n.prototype={}
A.J.prototype={
gu(a){var t=this
return new A.aQ(t,t.gt(t),A.k(t).h("aQ<J.E>"))},
gA(a){return this.gt(this)===0},
aZ(a){var t,s,r=this,q=r.gt(r)
for(t=0,s="";t<q;++t){s+=A.p(r.a_(0,t))
if(q!==r.gt(r))throw A.b(A.ad(r))}return s.charCodeAt(0)==0?s:s},
b0(a,b,c){var t=A.k(this)
return new A.a3(this,t.B(c).h("1(J.E)").a(b),t.h("@<J.E>").B(c).h("a3<1,2>"))}}
A.aQ.prototype={
gq(){var t=this.d
return t==null?this.$ti.c.a(t):t},
n(){var t,s=this,r=s.a,q=J.by(r),p=q.gt(r)
if(s.b!==p)throw A.b(A.ad(r))
t=s.c
if(t>=p){s.sa8(null)
return!1}s.sa8(q.a_(r,t));++s.c
return!0},
sa8(a){this.d=this.$ti.h("1?").a(a)},
$iw:1}
A.aR.prototype={
gu(a){return new A.aS(J.H(this.a),this.b,A.k(this).h("aS<1,2>"))},
gt(a){return J.dF(this.a)},
gA(a){return J.ik(this.a)}}
A.bL.prototype={$in:1}
A.aS.prototype={
n(){var t=this,s=t.b
if(s.n()){t.sa8(t.c.$1(s.gq()))
return!0}t.sa8(null)
return!1},
gq(){var t=this.a
return t==null?this.$ti.y[1].a(t):t},
sa8(a){this.a=this.$ti.h("2?").a(a)},
$iw:1}
A.a3.prototype={
gt(a){return J.dF(this.a)},
a_(a,b){return this.b.$1(J.fS(this.a,b))}}
A.c6.prototype={
gu(a){return new A.c7(J.H(this.a),this.b,this.$ti.h("c7<1>"))}}
A.c7.prototype={
n(){var t,s
for(t=this.a,s=this.b;t.n();)if(A.N(s.$1(t.gq())))return!0
return!1},
gq(){return this.a.gq()},
$iw:1}
A.T.prototype={
gu(a){return new A.U(J.H(this.a),this.$ti.h("U<1>"))}}
A.U.prototype={
n(){var t,s
for(t=this.a,s=this.$ti.c;t.n();)if(s.b(t.gq()))return!0
return!1},
gq(){return this.$ti.c.a(this.a.gq())},
$iw:1}
A.aL.prototype={}
A.c_.prototype={
gt(a){return this.a.length},
a_(a,b){var t=this.a
return J.fS(t,t.length-1-b)}}
A.D.prototype={$r:"+(1,2)",$s:1}
A.bu.prototype={$r:"+(1,2,3)",$s:2}
A.bG.prototype={
aT(a,b,c){var t=A.k(this)
return A.h8(this,t.c,t.y[1],b,c)},
gA(a){return this.gt(this)===0},
gae(a){return this.gt(this)!==0},
p(a){return A.fm(this)},
m(a,b,c){var t=A.k(this)
t.c.a(b)
t.y[1].a(c)
A.fb()},
a6(a,b){A.fb()},
au(a,b){A.k(this).h("A(1,2)").a(b)
A.fb()},
$il:1}
A.aJ.prototype={
gt(a){return this.b.length},
gbn(){var t=this.$keys
if(t==null){t=Object.keys(this.a)
this.$keys=t}return t},
E(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
k(a,b){if(!this.E(b))return null
return this.b[this.a[b]]},
T(a,b){var t,s,r,q
this.$ti.h("~(1,2)").a(b)
t=this.gbn()
s=this.b
for(r=t.length,q=0;q<r;++q)b.$2(t[q],s[q])},
gJ(){return new A.cp(this.gbn(),this.$ti.h("cp<1>"))}}
A.cp.prototype={
gt(a){return this.a.length},
gA(a){return 0===this.a.length},
gu(a){var t=this.a
return new A.aZ(t,t.length,this.$ti.h("aZ<1>"))}}
A.aZ.prototype={
gq(){var t=this.d
return t==null?this.$ti.c.a(t):t},
n(){var t=this,s=t.c
if(s>=t.b){t.sa9(null)
return!1}t.sa9(t.a[s]);++t.c
return!0},
sa9(a){this.d=this.$ti.h("1?").a(a)},
$iw:1}
A.bH.prototype={}
A.ae.prototype={
gt(a){return this.b},
gA(a){return this.b===0},
gu(a){var t,s=this,r=s.$keys
if(r==null){r=Object.keys(s.a)
s.$keys=r}t=r
return new A.aZ(t,t.length,s.$ti.h("aZ<1>"))},
S(a,b){if(typeof b!="string")return!1
if("__proto__"===b)return!1
return this.a.hasOwnProperty(b)}}
A.ef.prototype={
$0(){return B.d.cT(1000*this.a.now())},
$S:2}
A.eq.prototype={
O(a){var t,s,r=this,q=new RegExp(r.a).exec(a)
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
A.bY.prototype={
p(a){return"Null check operator used on a null value"}}
A.cT.prototype={
p(a){var t,s=this,r="NoSuchMethodError: method not found: '",q=s.b
if(q==null)return"NoSuchMethodError: "+s.a
t=s.c
if(t==null)return r+q+"' ("+s.a+")"
return r+q+"' on '"+t+"' ("+s.a+")"}}
A.de.prototype={
p(a){var t=this.a
return t.length===0?"Error":"Error: "+t}}
A.e7.prototype={
p(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.ar.prototype={
p(a){var t=this.constructor,s=t==null?null:t.name
return"Closure '"+A.i5(s==null?"unknown":s)+"'"},
$iaM:1,
gdf(){return this},
$C:"$1",
$R:1,
$D:null}
A.cD.prototype={$C:"$0",$R:0}
A.cE.prototype={$C:"$2",$R:2}
A.dc.prototype={}
A.da.prototype={
p(a){var t=this.$static_name
if(t==null)return"Closure of unknown static method"
return"Closure '"+A.i5(t)+"'"}}
A.b4.prototype={
R(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.b4))return!1
return this.$_target===b.$_target&&this.a===b.a},
gD(a){return(A.f9(this.a)^A.d4(this.$_target))>>>0},
p(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.eg(this.a)+"'")}}
A.dw.prototype={
p(a){return"Reading static variable '"+this.a+"' during its initialization"}}
A.d9.prototype={
p(a){return"RuntimeError: "+this.a}}
A.dv.prototype={
p(a){return"Assertion failed: "+A.bM(this.a)}}
A.ag.prototype={
gt(a){return this.a},
gA(a){return this.a===0},
gae(a){return this.a!==0},
gJ(){return new A.aP(this,A.k(this).h("aP<1>"))},
gda(){var t=A.k(this)
return A.fn(new A.aP(this,t.h("aP<1>")),new A.dZ(this),t.c,t.y[1])},
E(a){var t,s
if(typeof a=="string"){t=this.b
if(t==null)return!1
return t[a]!=null}else if(typeof a=="number"&&(a&0x3fffffff)===a){s=this.c
if(s==null)return!1
return s[a]!=null}else return this.cZ(a)},
cZ(a){var t=this.d
if(t==null)return!1
return this.ar(t[this.aq(a)],a)>=0},
Y(a,b){A.k(this).h("l<1,2>").a(b).T(0,new A.dY(this))},
k(a,b){var t,s,r,q,p=null
if(typeof b=="string"){t=this.b
if(t==null)return p
s=t[b]
r=s==null?p:s.b
return r}else if(typeof b=="number"&&(b&0x3fffffff)===b){q=this.c
if(q==null)return p
s=q[b]
r=s==null?p:s.b
return r}else return this.d_(b)},
d_(a){var t,s,r=this.d
if(r==null)return null
t=r[this.aq(a)]
s=this.ar(t,a)
if(s<0)return null
return t[s].b},
m(a,b,c){var t,s,r=this,q=A.k(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"){t=r.b
r.ba(t==null?r.b=r.aL():t,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){s=r.c
r.ba(s==null?r.c=r.aL():s,b,c)}else r.d1(b,c)},
d1(a,b){var t,s,r,q,p=this,o=A.k(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=p.aL()
s=p.aq(a)
r=t[s]
if(r==null)t[s]=[p.aM(a,b)]
else{q=p.ar(r,a)
if(q>=0)r[q].b=b
else r.push(p.aM(a,b))}},
d5(a,b){var t,s,r=this,q=A.k(r)
q.c.a(a)
q.h("2()").a(b)
if(r.E(a)){t=r.k(0,a)
return t==null?q.y[1].a(t):t}s=b.$0()
r.m(0,a,s)
return s},
a6(a,b){var t=this
if(typeof b=="string")return t.b9(t.b,b)
else if(typeof b=="number"&&(b&0x3fffffff)===b)return t.b9(t.c,b)
else return t.d0(b)},
d0(a){var t,s,r,q,p=this,o=p.d
if(o==null)return null
t=p.aq(a)
s=o[t]
r=p.ar(s,a)
if(r<0)return null
q=s.splice(r,1)[0]
p.bB(q)
if(s.length===0)delete o[t]
return q.b},
T(a,b){var t,s,r=this
A.k(r).h("~(1,2)").a(b)
t=r.e
s=r.r
for(;t!=null;){b.$2(t.a,t.b)
if(s!==r.r)throw A.b(A.ad(r))
t=t.c}},
ba(a,b,c){var t,s=A.k(this)
s.c.a(b)
s.y[1].a(c)
t=a[b]
if(t==null)a[b]=this.aM(b,c)
else t.b=c},
b9(a,b){var t
if(a==null)return null
t=a[b]
if(t==null)return null
this.bB(t)
delete a[b]
return t.b},
bp(){this.r=this.r+1&1073741823},
aM(a,b){var t=this,s=A.k(t),r=new A.e1(s.c.a(a),s.y[1].a(b))
if(t.e==null)t.e=t.f=r
else{s=t.f
s.toString
r.d=s
t.f=s.c=r}++t.a
t.bp()
return r},
bB(a){var t=this,s=a.d,r=a.c
if(s==null)t.e=r
else s.c=r
if(r==null)t.f=s
else r.d=s;--t.a
t.bp()},
aq(a){return J.B(a)&1073741823},
ar(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.P(a[s].a,b))return s
return-1},
p(a){return A.fm(this)},
aL(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
$ih6:1}
A.dZ.prototype={
$1(a){var t=this.a,s=A.k(t)
t=t.k(0,s.c.a(a))
return t==null?s.y[1].a(t):t},
$S(){return A.k(this.a).h("2(1)")}}
A.dY.prototype={
$2(a,b){var t=this.a,s=A.k(t)
t.m(0,s.c.a(a),s.y[1].a(b))},
$S(){return A.k(this.a).h("~(1,2)")}}
A.e1.prototype={}
A.aP.prototype={
gt(a){return this.a.a},
gA(a){return this.a.a===0},
gu(a){var t=this.a,s=new A.bT(t,t.r,this.$ti.h("bT<1>"))
s.c=t.e
return s}}
A.bT.prototype={
gq(){return this.d},
n(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.b(A.ad(r))
t=s.c
if(t==null){s.sa9(null)
return!1}else{s.sa9(t.a)
s.c=t.c
return!0}},
sa9(a){this.d=this.$ti.h("1?").a(a)},
$iw:1}
A.f3.prototype={
$1(a){return this.a(a)},
$S:3}
A.f4.prototype={
$2(a,b){return this.a(a,b)},
$S:7}
A.f5.prototype={
$1(a){return this.a(A.bv(a))},
$S:8}
A.am.prototype={
p(a){return this.bA(!1)},
bA(a){var t,s,r,q,p,o=this.cb(),n=this.aJ(),m=(a?""+"Record ":"")+"("
for(t=o.length,s="",r=0;r<t;++r,s=", "){m+=s
q=o[r]
if(typeof q=="string")m=m+q+": "
if(!(r<n.length))return A.a(n,r)
p=n[r]
m=a?m+A.hd(p):m+A.p(p)}m+=")"
return m.charCodeAt(0)==0?m:m},
cb(){var t,s=this.$s
for(;$.eT.length<=s;)B.a.i($.eT,null)
t=$.eT[s]
if(t==null){t=this.c_()
B.a.m($.eT,s,t)}return t},
c_(){var t,s,r,q=this.$r,p=q.indexOf("("),o=q.substring(1,p),n=q.substring(p),m=n==="()"?0:n.replace(/[^,]/g,"").length+1,l=A.d(new Array(m),u.G)
for(t=0;t<m;++t)l[t]=t
if(o!==""){s=o.split(",")
t=s.length
for(r=m;t>0;){--r;--t
B.a.m(l,r,s[t])}}l=A.fl(l,!1,u.K)
l.$flags=3
return l}}
A.bs.prototype={
aJ(){return[this.a,this.b]},
R(a,b){if(b==null)return!1
return b instanceof A.bs&&this.$s===b.$s&&J.P(this.a,b.a)&&J.P(this.b,b.b)},
gD(a){return A.d_(this.$s,this.a,this.b,B.f)}}
A.bt.prototype={
aJ(){return[this.a,this.b,this.c]},
R(a,b){var t=this
if(b==null)return!1
return b instanceof A.bt&&t.$s===b.$s&&J.P(t.a,b.a)&&J.P(t.b,b.b)&&J.P(t.c,b.c)},
gD(a){var t=this
return A.d_(t.$s,t.a,t.b,t.c)}}
A.cS.prototype={
p(a){return"RegExp/"+this.a+"/"+this.b.flags},
gcg(){var t=this,s=t.c
if(s!=null)return s
s=t.b
return t.c=A.h4(t.a,s.multiline,!s.ignoreCase,s.unicode,s.dotAll,!0)},
cD(a,b,c){var t=b.length
if(c>t)throw A.b(A.F(c,0,t,null,null))
return new A.du(this,b,c)},
cC(a,b){return this.cD(0,b,0)},
bl(a,b){var t,s=this.gcg()
if(s==null)s=u.K.a(s)
s.lastIndex=b
t=s.exec(a)
if(t==null)return null
return new A.dA(t)},
$iee:1,
$iiU:1}
A.dA.prototype={
gbE(){var t=this.b
return t.index+t[0].length},
$id6:1}
A.du.prototype={
gu(a){return new A.ci(this.a,this.b,this.c)}}
A.ci.prototype={
gq(){var t=this.d
return t==null?u.d.a(t):t},
n(){var t,s,r,q,p,o,n=this,m=n.b
if(m==null)return!1
t=n.c
s=m.length
if(t<=s){r=n.a
q=r.bl(m,t)
if(q!=null){n.d=q
p=q.gbE()
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
$iw:1}
A.au.prototype={
gL(a){return B.aQ},
bC(a,b,c){return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
$iC:1,
$iau:1}
A.bV.prototype={
ga2(a){if(((a.$flags|0)&2)!==0)return new A.eW(a.buffer)
else return a.buffer},
ce(a,b,c,d){var t=A.F(b,0,c,d,null)
throw A.b(t)},
bb(a,b,c,d){if(b>>>0!==b||b>c)this.ce(a,b,c,d)}}
A.eW.prototype={
bC(a,b,c){var t=A.h9(this.a,b,c)
t.$flags=3
return t}}
A.a7.prototype={
gt(a){return a.length},
$ib8:1}
A.bU.prototype={
b5(a,b,c,d,e){var t,s,r,q
u.hb.a(d)
a.$flags&2&&A.O(a,5)
t=a.length
this.bb(a,b,t,"start")
this.bb(a,c,t,"end")
if(b>c)A.a6(A.F(b,0,c,null,null))
s=c-b
if(e<0)A.a6(A.fa(e))
r=d.length
if(r-e<s)A.a6(A.hi("Not enough elements"))
q=e!==0||r!==s?d.subarray(e,e+s):d
a.set(q,b)
return},
b4(a,b,c,d){return this.b5(a,b,c,d,0)},
$in:1,
$ie:1,
$ir:1}
A.cY.prototype={
gL(a){return B.aR},
k(a,b){A.fF(b,a,a.length)
return a[b]},
$iC:1}
A.cZ.prototype={
gL(a){return B.aT},
k(a,b){A.fF(b,a,a.length)
return a[b]},
$iC:1,
$ift:1}
A.bW.prototype={
gL(a){return B.aU},
gt(a){return a.length},
k(a,b){A.fF(b,a,a.length)
return a[b]},
$iC:1,
$ies:1}
A.cr.prototype={}
A.cs.prototype={}
A.Y.prototype={
h(a){return A.cy(v.typeUniverse,this,a)},
B(a){return A.hF(v.typeUniverse,this,a)}}
A.dy.prototype={}
A.eU.prototype={
p(a){return A.M(this.a,null)}}
A.dx.prototype={
p(a){return this.a}}
A.cu.prototype={}
A.m.prototype={
gq(){var t=this.b
return t==null?this.$ti.c.a(t):t},
cu(a,b){var t,s,r
a=A.aD(a)
b=b
t=this.a
for(;!0;)try{s=t(this,a,b)
return s}catch(r){b=r
a=1}},
n(){var t,s,r,q,p=this,o=null,n=null,m=0
for(;!0;){t=p.d
if(t!=null)try{if(t.n()){p.saA(t.gq())
return!0}else p.saK(o)}catch(s){n=s
m=1
p.saK(o)}r=p.cu(m,n)
if(1===r)return!0
if(0===r){p.saA(o)
q=p.e
if(q==null||q.length===0){p.a=A.hA
return!1}if(0>=q.length)return A.a(q,-1)
p.a=q.pop()
m=0
n=null
continue}if(2===r){m=0
n=null
continue}if(3===r){n=p.c
p.c=null
q=p.e
if(q==null||q.length===0){p.saA(o)
p.a=A.hA
throw n
return!1}if(0>=q.length)return A.a(q,-1)
p.a=q.pop()
m=1
continue}throw A.b(A.hi("sync*"))}return!1},
cB(a){var t,s,r=this
if(a instanceof A.b0){t=a.a()
s=r.e
if(s==null)s=r.e=[]
B.a.i(s,r.a)
r.a=t
return 2}else{r.saK(J.H(a))
return 2}},
saA(a){this.b=this.$ti.h("1?").a(a)},
saK(a){this.d=this.$ti.h("w<1>?").a(a)},
$iw:1}
A.b0.prototype={
gu(a){return new A.m(this.a(),this.$ti.h("m<1>"))}}
A.al.prototype={
gt(a){return this.a},
gA(a){return this.a===0},
gJ(){return new A.cm(this,A.k(this).h("cm<1>"))},
k(a,b){var t,s,r
if(typeof b=="string"&&b!=="__proto__"){t=this.b
s=t==null?null:A.fx(t,b)
return s}else if(typeof b=="number"&&(b&1073741823)===b){r=this.c
s=r==null?null:A.fx(r,b)
return s}else return this.bm(b)},
bm(a){var t,s,r=this.d
if(r==null)return null
t=this.cc(r,a)
s=this.U(t,a)
return s<0?null:t[s+1]},
m(a,b,c){var t,s,r=this,q=A.k(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"&&b!=="__proto__"){t=r.b
r.bd(t==null?r.b=A.fy():t,b,c)}else if(typeof b=="number"&&(b&1073741823)===b){s=r.c
r.bd(s==null?r.c=A.fy():s,b,c)}else r.by(b,c)},
by(a,b){var t,s,r,q,p=this,o=A.k(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=A.fy()
s=p.ab(a)
r=t[s]
if(r==null){A.fz(t,s,[a,b]);++p.a
p.e=null}else{q=p.U(r,a)
if(q>=0)r[q+1]=b
else{r.push(a,b);++p.a
p.e=null}}},
a6(a,b){var t=this
if(typeof b=="string"&&b!=="__proto__")return t.bx(t.b,b)
else if(typeof b=="number"&&(b&1073741823)===b)return t.bx(t.c,b)
else return t.bw(b)},
bw(a){var t,s,r,q,p=this,o=p.d
if(o==null)return null
t=p.ab(a)
s=o[t]
r=p.U(s,a)
if(r<0)return null;--p.a
p.e=null
q=s.splice(r,2)[1]
if(0===s.length)delete o[t]
return q},
T(a,b){var t,s,r,q,p,o,n=this,m=A.k(n)
m.h("~(1,2)").a(b)
t=n.be()
for(s=t.length,r=m.c,m=m.y[1],q=0;q<s;++q){p=t[q]
r.a(p)
o=n.k(0,p)
b.$2(p,o==null?m.a(o):o)
if(t!==n.e)throw A.b(A.ad(n))}},
be(){var t,s,r,q,p,o,n,m,l,k,j=this,i=j.e
if(i!=null)return i
i=A.fk(j.a,null,!1,u.z)
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
bd(a,b,c){var t=A.k(this)
t.c.a(b)
t.y[1].a(c)
if(a[b]==null){++this.a
this.e=null}A.fz(a,b,c)},
bx(a,b){var t
if(a!=null&&a[b]!=null){t=A.k(this).y[1].a(A.fx(a,b))
delete a[b];--this.a
this.e=null
return t}else return null},
ab(a){return J.B(a)&1073741823},
cc(a,b){return a[this.ab(b)]},
U(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;s+=2)if(J.P(a[s],b))return s
return-1}}
A.co.prototype={
ab(a){return A.f9(a)&1073741823},
U(a,b){var t,s,r
if(a==null)return-1
t=a.length
for(s=0;s<t;s+=2){r=a[s]
if(r==null?b==null:r===b)return s}return-1}}
A.cj.prototype={
k(a,b){if(!A.N(this.w.$1(b)))return null
return this.bR(b)},
m(a,b,c){var t=this.$ti
this.bT(t.c.a(b),t.y[1].a(c))},
a6(a,b){if(!A.N(this.w.$1(b)))return null
return this.bS(b)},
ab(a){return this.r.$1(this.$ti.c.a(a))&1073741823},
U(a,b){var t,s,r,q
if(a==null)return-1
t=a.length
for(s=this.$ti.c,r=this.f,q=0;q<t;q+=2)if(A.N(r.$2(a[q],s.a(b))))return q
return-1}}
A.eK.prototype={
$1(a){return this.a.b(a)},
$S:9}
A.cm.prototype={
gt(a){return this.a.a},
gA(a){return this.a.a===0},
gu(a){var t=this.a
return new A.cn(t,t.be(),this.$ti.h("cn<1>"))}}
A.cn.prototype={
gq(){var t=this.d
return t==null?this.$ti.c.a(t):t},
n(){var t=this,s=t.b,r=t.c,q=t.a
if(s!==q.e)throw A.b(A.ad(q))
else if(r>=s.length){t.saa(null)
return!1}else{t.saa(s[r])
t.c=r+1
return!0}},
saa(a){this.d=this.$ti.h("1?").a(a)},
$iw:1}
A.b_.prototype={
gu(a){var t=this,s=new A.cq(t,t.r,t.$ti.h("cq<1>"))
s.c=t.e
return s},
gt(a){return this.a},
gA(a){return this.a===0},
S(a,b){var t,s
if(typeof b=="string"&&b!=="__proto__"){t=this.b
if(t==null)return!1
return u.o.a(t[b])!=null}else{s=this.c0(b)
return s}},
c0(a){var t=this.d
if(t==null)return!1
return this.U(t[J.B(a)&1073741823],a)>=0},
i(a,b){var t,s,r=this
r.$ti.c.a(b)
if(typeof b=="string"&&b!=="__proto__"){t=r.b
return r.bc(t==null?r.b=A.fA():t,b)}else if(typeof b=="number"&&(b&1073741823)===b){s=r.c
return r.bc(s==null?r.c=A.fA():s,b)}else return r.bX(b)},
bX(a){var t,s,r,q=this
q.$ti.c.a(a)
t=q.d
if(t==null)t=q.d=A.fA()
s=J.B(a)&1073741823
r=t[s]
if(r==null)t[s]=[q.aC(a)]
else{if(q.U(r,a)>=0)return!1
r.push(q.aC(a))}return!0},
bc(a,b){this.$ti.c.a(b)
if(u.o.a(a[b])!=null)return!1
a[b]=this.aC(b)
return!0},
aC(a){var t=this,s=new A.dz(t.$ti.c.a(a))
if(t.e==null)t.e=t.f=s
else t.f=t.f.b=s;++t.a
t.r=t.r+1&1073741823
return s},
U(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.P(a[s].a,b))return s
return-1},
$ih7:1}
A.dz.prototype={}
A.cq.prototype={
gq(){var t=this.d
return t==null?this.$ti.c.a(t):t},
n(){var t=this,s=t.c,r=t.a
if(t.b!==r.r)throw A.b(A.ad(r))
else if(s==null){t.saa(null)
return!1}else{t.saa(t.$ti.h("1?").a(s.a))
t.c=s.b
return!0}},
saa(a){this.d=this.$ti.h("1?").a(a)},
$iw:1}
A.e3.prototype={
$2(a,b){this.a.m(0,this.b.a(a),this.c.a(b))},
$S:10}
A.a2.prototype={
gu(a){return new A.aQ(a,a.length,A.cA(a).h("aQ<a2.E>"))},
a_(a,b){if(!(b>=0&&b<a.length))return A.a(a,b)
return a[b]},
gA(a){return a.length===0},
gae(a){return a.length!==0},
p(a){return A.fh(a,"[","]")}}
A.j.prototype={
aT(a,b,c){var t=A.k(this)
return A.h8(this,t.h("j.K"),t.h("j.V"),b,c)},
T(a,b){var t,s,r,q=A.k(this)
q.h("~(j.K,j.V)").a(b)
for(t=this.gJ(),t=t.gu(t),q=q.h("j.V");t.n();){s=t.gq()
r=this.k(0,s)
b.$2(s,r==null?q.a(r):r)}},
gcP(){return this.gJ().b0(0,new A.e5(this),A.k(this).h("ah<j.K,j.V>"))},
au(a,b){var t,s,r,q,p,o=this,n=A.k(o)
n.h("A(j.K,j.V)").a(b)
t=A.d([],n.h("h<j.K>"))
for(s=o.gJ(),s=s.gu(s),n=n.h("j.V");s.n();){r=s.gq()
q=o.k(0,r)
if(A.N(b.$2(r,q==null?n.a(q):q)))B.a.i(t,r)}for(n=t.length,p=0;p<t.length;t.length===n||(0,A.q)(t),++p)o.a6(0,t[p])},
gt(a){var t=this.gJ()
return t.gt(t)},
gA(a){var t=this.gJ()
return t.gA(t)},
p(a){return A.fm(this)},
$il:1}
A.e5.prototype={
$1(a){var t=this.a,s=A.k(t)
s.h("j.K").a(a)
t=t.k(0,a)
if(t==null)t=s.h("j.V").a(t)
return new A.ah(a,t,s.h("ah<j.K,j.V>"))},
$S(){return A.k(this.a).h("ah<j.K,j.V>(j.K)")}}
A.e6.prototype={
$2(a,b){var t,s=this.a
if(!s.a)this.b.a+=", "
s.a=!1
s=this.b
t=A.p(a)
t=s.a+=t
s.a=t+": "
t=A.p(b)
s.a+=t},
$S:4}
A.a4.prototype={
gA(a){return this.gt(this)===0},
p(a){return A.fh(this,"{","}")},
$in:1,
$ie:1,
$ia8:1}
A.ct.prototype={}
A.eZ.prototype={
$0(){var t,s
try{t=new TextDecoder("utf-8",{fatal:true})
return t}catch(s){}return null},
$S:5}
A.eY.prototype={
$0(){var t,s
try{t=new TextDecoder("utf-8",{fatal:false})
return t}catch(s){}return null},
$S:5}
A.eV.prototype={
ac(a){var t,s,r,q
u.L.a(a)
t=a.length
s=A.d5(0,null,t)
for(r=0;r<s;++r){if(!(r<t))return A.a(a,r)
q=a[r]
if((q&4294967040)!==0){if(!this.a)throw A.b(A.dT("Invalid value in input: "+q,null,null))
return this.c5(a,0,s)}}return A.fs(a,0,s)},
c5(a,b,c){var t,s,r,q
u.L.a(a)
for(t=a.length,s=b,r="";s<c;++s){if(!(s<t))return A.a(a,s)
q=a[s]
r+=A.i((q&4294967040)!==0?65533:q)}return r.charCodeAt(0)==0?r:r}}
A.bE.prototype={
gaV(){return B.T}}
A.dG.prototype={
ac(a){var t
u.L.a(a)
t=a.length
if(t===0)return""
t=new A.eJ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/").cO(a,0,t,!0)
t.toString
return A.fs(t,0,null)}}
A.eJ.prototype={
cO(a,b,c,d){var t,s,r,q,p
u.L.a(a)
t=this.a
s=(t&3)+(c-b)
r=B.c.an(s,3)
q=r*4
if(s-r*3>0)q+=4
p=new Uint8Array(q)
this.a=A.jd(this.b,a,b,c,!0,p,0,t)
if(q>0)return p
return null}}
A.Q.prototype={}
A.cG.prototype={}
A.cI.prototype={}
A.bR.prototype={
p(a){var t=A.bM(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+t}}
A.cV.prototype={
p(a){return"Cyclic error in JSON stringify"}}
A.cU.prototype={
cN(a,b){var t=A.jg(a,this.gaV().b,null)
return t},
gaV(){return B.af}}
A.e_.prototype={}
A.eP.prototype={
bK(a){var t,s,r,q,p,o,n=a.length
for(t=this.c,s=0,r=0;r<n;++r){q=a.charCodeAt(r)
if(q>92){if(q>=55296){p=q&64512
if(p===55296){o=r+1
o=!(o<n&&(a.charCodeAt(o)&64512)===56320)}else o=!1
if(!o)if(p===56320){p=r-1
p=!(p>=0&&(a.charCodeAt(p)&64512)===55296)}else p=!1
else p=!0
if(p){if(r>s)t.a+=B.b.v(a,s,r)
s=r+1
p=A.i(92)
t.a+=p
p=A.i(117)
t.a+=p
p=A.i(100)
t.a+=p
p=q>>>8&15
p=A.i(p<10?48+p:87+p)
t.a+=p
p=q>>>4&15
p=A.i(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.i(p<10?48+p:87+p)
t.a+=p}}continue}if(q<32){if(r>s)t.a+=B.b.v(a,s,r)
s=r+1
p=A.i(92)
t.a+=p
switch(q){case 8:p=A.i(98)
t.a+=p
break
case 9:p=A.i(116)
t.a+=p
break
case 10:p=A.i(110)
t.a+=p
break
case 12:p=A.i(102)
t.a+=p
break
case 13:p=A.i(114)
t.a+=p
break
default:p=A.i(117)
t.a+=p
p=A.i(48)
t.a+=p
p=A.i(48)
t.a+=p
p=q>>>4&15
p=A.i(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.i(p<10?48+p:87+p)
t.a+=p
break}}else if(q===34||q===92){if(r>s)t.a+=B.b.v(a,s,r)
s=r+1
p=A.i(92)
t.a+=p
p=A.i(q)
t.a+=p}}if(s===0)t.a+=a
else if(s<n)t.a+=B.b.v(a,s,n)},
aB(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(a==null?q==null:a===q)throw A.b(new A.cV(a,null))}B.a.i(t,a)},
az(a){var t,s,r,q,p=this
if(p.bJ(a))return
p.aB(a)
try{t=p.b.$1(a)
if(!p.bJ(t)){r=A.h5(a,null,p.gbv())
throw A.b(r)}r=p.a
if(0>=r.length)return A.a(r,-1)
r.pop()}catch(q){s=A.kK(q)
r=A.h5(a,s,p.gbv())
throw A.b(r)}},
bJ(a){var t,s,r,q=this
if(typeof a=="number"){if(!isFinite(a))return!1
t=q.c
s=B.d.p(a)
t.a+=s
return!0}else if(a===!0){q.c.a+="true"
return!0}else if(a===!1){q.c.a+="false"
return!0}else if(a==null){q.c.a+="null"
return!0}else if(typeof a=="string"){t=q.c
t.a+='"'
q.bK(a)
t.a+='"'
return!0}else if(u.j.b(a)){q.aB(a)
q.dc(a)
t=q.a
if(0>=t.length)return A.a(t,-1)
t.pop()
return!0}else if(u.f.b(a)){q.aB(a)
r=q.dd(a)
t=q.a
if(0>=t.length)return A.a(t,-1)
t.pop()
return r}else return!1},
dc(a){var t,s,r=this.c
r.a+="["
t=J.by(a)
if(t.gae(a)){this.az(t.k(a,0))
for(s=1;s<t.gt(a);++s){r.a+=","
this.az(t.k(a,s))}}r.a+="]"},
dd(a){var t,s,r,q,p,o,n=this,m={}
if(a.gA(a)){n.c.a+="{}"
return!0}t=a.gt(a)*2
s=A.fk(t,null,!1,u.O)
r=m.a=0
m.b=!0
a.T(0,new A.eQ(m,s))
if(!m.b)return!1
q=n.c
q.a+="{"
for(p='"';r<t;r+=2,p=',"'){q.a+=p
n.bK(A.bv(s[r]))
q.a+='":'
o=r+1
if(!(o<t))return A.a(s,o)
n.az(s[o])}q.a+="}"
return!0}}
A.eQ.prototype={
$2(a,b){var t,s
if(typeof a!="string")this.a.b=!1
t=this.b
s=this.a
B.a.m(t,s.a++,a)
B.a.m(t,s.a++,b)},
$S:4}
A.eO.prototype={
gbv(){var t=this.c.a
return t.charCodeAt(0)==0?t:t}}
A.cW.prototype={
ad(a){var t
u.L.a(a)
t=B.ag.ac(a)
return t}}
A.e0.prototype={}
A.df.prototype={
ad(a){u.L.a(a)
return B.aV.ac(a)}}
A.et.prototype={
ac(a){return new A.eX(this.a).c4(u.L.a(a),0,null,!0)}}
A.eX.prototype={
c4(a,b,c,d){var t,s,r,q,p,o,n,m=this
u.L.a(a)
t=A.d5(b,c,a.length)
if(b===t)return""
if(a instanceof Uint8Array){s=a
r=s
q=0}else{r=A.jz(a,b,t)
t-=b
q=b
b=0}if(t-b>=15){p=m.a
o=A.jy(p,r,b,t)
if(o!=null){if(!p)return o
if(o.indexOf("\ufffd")<0)return o}}o=m.aF(r,b,t,!0)
p=m.b
if((p&1)!==0){n=A.jA(p)
m.b=0
throw A.b(A.dT(n,a,q+m.c))}return o},
aF(a,b,c,d){var t,s,r=this
if(c-b>1000){t=B.c.an(b+c,2)
s=r.aF(a,b,t,!1)
if((r.b&1)!==0)return s
return s+r.aF(a,t,c,d)}return r.cJ(a,b,c,d)},
cJ(a,b,c,a0){var t,s,r,q,p,o,n,m,l=this,k="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHHHHHHHHIHHHJEEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBKCCCCCCCCCCCCDCLONNNMEEEEEEEEEEE",j=" \x000:XECCCCCN:lDb \x000:XECCCCCNvlDb \x000:XECCCCCN:lDb AAAAA\x00\x00\x00\x00\x00AAAAA00000AAAAA:::::AAAAAGG000AAAAA00KKKAAAAAG::::AAAAA:IIIIAAAAA000\x800AAAAA\x00\x00\x00\x00 AAAAA",i=65533,h=l.b,g=l.c,f=new A.z(""),e=b+1,d=a.length
if(!(b>=0&&b<d))return A.a(a,b)
t=a[b]
$label0$0:for(s=l.a;!0;){for(;!0;e=p){if(!(t>=0&&t<256))return A.a(k,t)
r=k.charCodeAt(t)&31
g=h<=32?t&61694>>>r:(t&63|g<<6)>>>0
q=h+r
if(!(q>=0&&q<144))return A.a(j,q)
h=j.charCodeAt(q)
if(h===0){q=A.i(g)
f.a+=q
if(e===c)break $label0$0
break}else if((h&1)!==0){if(s)switch(h){case 69:case 67:q=A.i(i)
f.a+=q
break
case 65:q=A.i(i)
f.a+=q;--e
break
default:q=A.i(i)
q=f.a+=q
f.a=q+A.i(i)
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
q=A.i(a[m])
f.a+=q}else{q=A.fs(a,e,o)
f.a+=q}if(o===c)break $label0$0
e=p}else e=p}if(a0&&h>32)if(s){d=A.i(i)
f.a+=d}else{l.b=77
l.c=c
return""}l.b=h
l.c=g
d=f.a
return d.charCodeAt(0)==0?d:d}}
A.eM.prototype={
p(a){return this.X()}}
A.t.prototype={}
A.bD.prototype={
p(a){var t=this.a
if(t!=null)return"Assertion failed: "+A.bM(t)
return"Assertion failed"}}
A.c2.prototype={}
A.ac.prototype={
gaH(){return"Invalid argument"+(!this.a?"(s)":"")},
gaG(){return""},
p(a){var t=this,s=t.c,r=s==null?"":" ("+s+")",q=t.d,p=q==null?"":": "+A.p(q),o=t.gaH()+r+p
if(!t.a)return o
return o+t.gaG()+": "+A.bM(t.gaX())},
gaX(){return this.b}}
A.bZ.prototype={
gaX(){return A.jB(this.b)},
gaH(){return"RangeError"},
gaG(){var t,s=this.e,r=this.f
if(s==null)t=r!=null?": Not less than or equal to "+A.p(r):""
else if(r==null)t=": Not greater than or equal to "+A.p(s)
else if(r>s)t=": Not in inclusive range "+A.p(s)+".."+A.p(r)
else t=r<s?": Valid value range is empty":": Only valid value is "+A.p(s)
return t}}
A.cM.prototype={
gaX(){return A.aD(this.b)},
gaH(){return"RangeError"},
gaG(){if(A.aD(this.b)<0)return": index must not be negative"
var t=this.f
if(t===0)return": no indices are valid"
return": index should be less than "+t},
gt(a){return this.f}}
A.c5.prototype={
p(a){return"Unsupported operation: "+this.a}}
A.dd.prototype={
p(a){return"UnimplementedError: "+this.a}}
A.c1.prototype={
p(a){return"Bad state: "+this.a}}
A.cF.prototype={
p(a){var t=this.a
if(t==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.bM(t)+"."}}
A.d0.prototype={
p(a){return"Out of Memory"},
$it:1}
A.c0.prototype={
p(a){return"Stack Overflow"},
$it:1}
A.a_.prototype={
p(a){var t,s,r,q,p,o,n,m,l,k,j,i=this.a,h=""!==i?"FormatException: "+i:"FormatException",g=this.c,f=this.b
if(typeof f=="string"){if(g!=null)t=g<0||g>f.length
else t=!1
if(t)g=null
if(g==null){if(f.length>78)f=B.b.v(f,0,75)+"..."
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
l=""}return h+m+B.b.v(f,j,k)+l+"\n"+B.b.b3(" ",g-j+m.length)+"^\n"}else return g!=null?h+(" (at offset "+A.p(g)+")"):h}}
A.e.prototype={
b0(a,b,c){var t=A.k(this)
return A.fn(this,t.B(c).h("1(e.E)").a(b),t.h("e.E"),c)},
aZ(a){var t,s,r,q=this.gu(this)
if(!q.n())return""
t=J.aG(q.gq())
if(!q.n())return t
s=new A.z(t)
r=t
do{r+=J.aG(q.gq())
s.a=r}while(q.n())
r=s.a
return r.charCodeAt(0)==0?r:r},
gt(a){var t,s=this.gu(this)
for(t=0;s.n();)++t
return t},
gA(a){return!this.gu(this).n()},
ga3(a){var t=this.gu(this)
if(!t.n())throw A.b(A.fg())
return t.gq()},
a_(a,b){var t,s
A.he(b,"index")
t=this.gu(this)
for(s=b;t.n();){if(s===0)return t.gq();--s}throw A.b(A.h2(b,b-s,this,"index"))},
p(a){return A.iA(this,"(",")")}}
A.ah.prototype={
p(a){return"MapEntry("+A.p(this.a)+": "+A.p(this.b)+")"}}
A.bX.prototype={
gD(a){return A.o.prototype.gD.call(this,0)},
p(a){return"null"}}
A.o.prototype={$io:1,
R(a,b){return this===b},
gD(a){return A.d4(this)},
p(a){return"Instance of '"+A.eg(this)+"'"},
gL(a){return A.km(this)},
toString(){return this.p(this)}}
A.eo.prototype={
gcM(){var t,s=this.b
if(s==null)s=$.ei.$0()
t=s-this.a
if($.fR()===1000)return t
return B.c.an(t,1000)}}
A.z.prototype={
gt(a){return this.a.length},
p(a){var t=this.a
return t.charCodeAt(0)==0?t:t},
$iiX:1}
A.aK.prototype={
F(a,b){return J.P(a,b)},
G(a){return J.B(a)},
$iZ:1}
A.b5.prototype={
F(a,b){var t,s,r,q=this.$ti.h("e<1>?")
q.a(a)
q.a(b)
if(a===b)return!0
t=J.H(a)
s=J.H(b)
for(q=this.a;!0;){r=t.n()
if(r!==s.n())return!1
if(!r)return!0
if(!q.F(t.gq(),s.gq()))return!1}},
G(a){var t,s,r
this.$ti.h("e<1>?").a(a)
for(t=J.H(a),s=this.a,r=0;t.n();){r=r+s.G(t.gq())&2147483647
r=r+(r<<10>>>0)&2147483647
r^=r>>>6}r=r+(r<<3>>>0)&2147483647
r^=r>>>11
return r+(r<<15>>>0)&2147483647},
$iZ:1}
A.at.prototype={
F(a,b){var t,s,r,q,p=this.$ti.h("r<1>?")
p.a(a)
p.a(b)
if(a===b)return!0
p=J.by(a)
t=p.gt(a)
s=J.by(b)
if(t!==s.gt(b))return!1
for(r=this.a,q=0;q<t;++q)if(!r.F(p.k(a,q),s.k(b,q)))return!1
return!0},
G(a){var t,s,r,q
this.$ti.h("r<1>?").a(a)
for(t=J.by(a),s=this.a,r=0,q=0;q<t.gt(a);++q){r=r+s.G(t.k(a,q))&2147483647
r=r+(r<<10>>>0)&2147483647
r^=r>>>6}r=r+(r<<3>>>0)&2147483647
r^=r>>>11
return r+(r<<15>>>0)&2147483647},
$iZ:1}
A.W.prototype={
F(a,b){var t,s,r,q,p=A.k(this),o=p.h("W.T?")
o.a(a)
o.a(b)
if(a===b)return!0
o=this.a
t=A.h1(p.h("A(W.E,W.E)").a(o.gcQ()),p.h("c(W.E)").a(o.gcW()),o.gd2(),p.h("W.E"),u.S)
for(p=J.H(a),s=0;p.n();){r=p.gq()
q=t.k(0,r)
t.m(0,r,(q==null?0:q)+1);++s}for(p=J.H(b);p.n();){r=p.gq()
q=t.k(0,r)
if(q==null||q===0)return!1
if(typeof q!=="number")return q.bN()
t.m(0,r,q-1);--s}return s===0},
G(a){var t,s,r
A.k(this).h("W.T?").a(a)
for(t=J.H(a),s=this.a,r=0;t.n();)r=r+s.G(t.gq())&2147483647
r=r+(r<<3>>>0)&2147483647
r^=r>>>11
return r+(r<<15>>>0)&2147483647},
$iZ:1}
A.bc.prototype={}
A.br.prototype={
gD(a){var t=this.a
return 3*t.a.G(this.b)+7*t.b.G(this.c)&2147483647},
R(a,b){var t
if(b==null)return!1
if(b instanceof A.br){t=this.a
t=t.a.F(this.b,b.b)&&t.b.F(this.c,b.c)}else t=!1
return t}}
A.ba.prototype={
F(a,b){var t,s,r,q,p=this.$ti.h("l<1,2>?")
p.a(a)
p.a(b)
if(a===b)return!0
if(a.gt(a)!==b.gt(b))return!1
t=A.h1(null,null,null,u.gA,u.S)
for(p=a.gJ(),p=p.gu(p);p.n();){s=p.gq()
r=new A.br(this,s,a.k(0,s))
q=t.k(0,r)
t.m(0,r,(q==null?0:q)+1)}for(p=b.gJ(),p=p.gu(p);p.n();){s=p.gq()
r=new A.br(this,s,b.k(0,s))
q=t.k(0,r)
if(q==null||q===0)return!1
if(typeof q!=="number")return q.bN()
t.m(0,r,q-1)}return!0},
G(a){var t,s,r,q,p,o,n,m=this.$ti
m.h("l<1,2>?").a(a)
for(t=a.gJ(),t=t.gu(t),s=this.a,r=this.b,m=m.y[1],q=0;t.n();){p=t.gq()
o=s.G(p)
n=a.k(0,p)
q=q+3*o+7*r.G(n==null?m.a(n):n)&2147483647}q=q+(q<<3>>>0)&2147483647
q^=q>>>11
return q+(q<<15>>>0)&2147483647},
$iZ:1}
A.bI.prototype={
F(a,b){var t,s=this
if(a instanceof A.a4)return b instanceof A.a4&&new A.bc(s,u.D).F(a,b)
t=u.f
if(t.b(a))return t.b(b)&&new A.ba(s,s,u.J).F(a,b)
t=u.j
if(t.b(a))return t.b(b)&&new A.at(s,u.I).F(a,b)
t=u.R
if(t.b(a))return t.b(b)&&new A.b5(s,u.c).F(a,b)
return J.P(a,b)},
G(a){var t=this
if(a instanceof A.a4)return new A.bc(t,u.D).G(a)
if(u.f.b(a))return new A.ba(t,t,u.J).G(a)
if(u.j.b(a))return new A.at(t,u.I).G(a)
if(u.R.b(a))return new A.b5(t,u.c).G(a)
return J.B(a)},
d3(a){return!0},
$iZ:1}
A.cH.prototype={
aw(){var t=A.fl(this.a,!0,u.W),s=A.a5(t),r=s.h("a3<1,l<f,@>>")
return A.e4(new A.a3(t,s.h("l<f,@>(1)").a(new A.dM()),r),!0,r.h("J.E"))},
gt(a){return this.a.length},
R(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.cH))return!1
return B.ah.F(this.a,b.a)},
gD(a){return A.ha(this.a)},
p(a){return B.a.bG(this.a,"\n")}}
A.dL.prototype={
$1(a){return A.iK(u.f.a(a),this.a)},
$S:12}
A.dM.prototype={
$1(a){return u.W.a(a).aw()},
$S:13}
A.S.prototype={
gaS(){var t=this.d
if(t==null)t=null
else t=A.cX(t,u.N,u.z)
return t},
aw(){var t=this,s=t.a,r=A.a1([s,s==="insert"?t.c:t.b],u.N,u.z)
if(t.d!=null)r.m(0,"attributes",t.gaS())
return r},
R(a,b){var t=this
if(b==null)return!1
if(t===b)return!0
if(!(b instanceof A.S))return!1
return t.a===b.a&&t.b==b.b&&B.A.F(t.c,b.c)&&t.cV(b)},
cV(a){var t=this.d,s=t==null?null:t.a===0
if(s!==!1){s=a.d
s=s==null?null:s.a===0
s=s!==!1}else s=!1
if(s)return!0
return B.A.F(t,a.d)},
gD(a){var t,s,r=this,q=r.d,p=q==null
if(!p)t=q.a!==0
else t=!1
if(t){s=A.ha((p?u.a.a(q):q).gcP().b0(0,new A.ed(),u.O))
q=r.a
return A.d_(q,q==="insert"?r.c:r.b,s,B.f)}q=r.a
return A.d_(q,q==="insert"?r.c:r.b,B.f,B.f)},
p(a){var t,s,r=this,q=r.gaS()==null?"":" + "+A.p(r.gaS()),p=r.a
if(p==="insert"){t=r.c
if(typeof t=="string"){t=A.fO(t,"\n","\u23ce")
s=t}else{t=J.aG(t)
s=t}}else s=A.p(r.b)
return p+"\u27e8 "+s+" \u27e9"+q},
gt(a){return this.b}}
A.ed.prototype={
$1(a){u.e1.a(a)
return A.d_(a.a,a.b,B.f,B.f)},
$S:14}
A.dU.prototype={
bs(a){var t=a.a
t=t==null?null:t.a
if(t==null){t=this.a.cK("paragraph")
t=t==null?null:t.a}return t},
b1(a){var t,s,r,q,p=this.a,o=p.b
if(o==null)o=B.aW
for(p=p.ap(this.bs(a)),t=p.length,s=0;s<p.length;p.length===t||(0,A.q)(p),++s){r=p[s].r
if(r!=null)o=o.a4(r)}q=a.a
return q!=null?o.a4(q):o},
a0(a,b){var t,s,r,q,p=this.a,o=p.a
if(o==null)o=B.aX
for(t=p.ap(this.bs(a)),s=t.length,r=0;r<t.length;t.length===s||(0,A.q)(t),++r){q=t[r].w
if(q!=null)o=o.a4(q)}t=b==null
if((t?null:b.a)!=null)for(p=p.ap(b.a),s=p.length,r=0;r<p.length;p.length===s||(0,A.q)(p),++r){q=p[r].w
if(q!=null)o=o.a4(q)}return!t?o.a4(b):o},
d6(a){var t,s,r,q,p=null,o=a.a,n=o==null,m=n?p:o.d
if(m!=null)return m
o=n?p:o.a
o=this.a.ap(o)
n=o.length
t=p
s=0
for(;s<n;++s){r=o[s].x
q=r==null?p:r.d
if(q!=null)t=q}return t}}
A.eC.prototype={}
A.ew.prototype={}
A.dk.prototype={}
A.eB.prototype={}
A.c8.prototype={}
A.eu.prototype={}
A.aW.prototype={
a4(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e=a.a
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
return new A.aW(e,t,s,r,q,p,o,n,m,l,k,j,i,h,g==null?f.ax:g)}}
A.ex.prototype={}
A.aU.prototype={
a4(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e=a.a
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
return new A.aU(e,t,s,r,q,p,o,n,m,l,k,j,i,h,g==null?f.ax:g)}}
A.K.prototype={}
A.aa.prototype={}
A.cd.prototype={}
A.bf.prototype={}
A.cb.prototype={}
A.cc.prototype={}
A.ca.prototype={}
A.bg.prototype={}
A.bj.prototype={}
A.bn.prototype={}
A.bp.prototype={}
A.ax.prototype={}
A.aV.prototype={
ga7(){var t=u.ap
return A.fn(new A.T(this.b,t),t.h("f(e.E)").a(new A.ey()),t.h("e.E"),u.N).aZ(0)}}
A.ey.prototype={
$1(a){return u.dH.a(a).a},
$S:15}
A.bi.prototype={}
A.bo.prototype={}
A.bm.prototype={}
A.aw.prototype={}
A.a9.prototype={}
A.eG.prototype={}
A.eE.prototype={}
A.eF.prototype={}
A.eD.prototype={}
A.dl.prototype={}
A.dm.prototype={}
A.aY.prototype={}
A.bl.prototype={}
A.bh.prototype={}
A.ez.prototype={}
A.eA.prototype={
$1(a){var t,s,r,q,p=A.d([],u.f_)
for(t=this.a.K(a),s=t.$ti,t=new A.m(t.a(),s.h("m<1>")),s=s.c;t.n();){r=t.b
if(r==null)r=s.a(r)
q=r.l("w:type")
if(q==null)q="default"
r=r.l("r:id")
p.push(new A.bh(q,r==null?"":r))}return p},
$S:16}
A.ev.prototype={}
A.dg.prototype={}
A.dj.prototype={}
A.dh.prototype={}
A.be.prototype={}
A.bk.prototype={}
A.ay.prototype={
af(a,b){var t,s,r=this.b.k(0,a)
if(r==null)return null
t=r.c.k(0,b)
if(t!=null)return t
s=this.a.k(0,r.b)
return s==null?null:s.c.k(0,b)}}
A.e8.prototype={
d4(a,b){var t,s,r,q,p,o,n,m,l=this.a,k=l.af(a,b)
if(k==null)return null
t=this.b.d5(a,new A.e9())
s=t.k(0,b)
t.m(0,b,(s==null?this.cz(a,b)-1:s)+1)
t.au(0,new A.ea(b))
if(k.c==="bullet")return A.iJ(k.d)
r=k.d
for(q=1;q<=9;++q){s="%"+q
if(!B.b.S(r,s))continue
p=q-1
o=t.k(0,p)
if(o==null){n=l.af(a,p)
n=n==null?null:n.b
o=n==null?1:n}t.m(0,p,o)
n=l.af(a,p)
m=n==null?null:n.c
n=A.kj(o,m==null?"decimal":m)
r=A.fO(r,s,n)}return r},
cz(a,b){var t=this.a.af(a,b)
t=t==null?null:t.b
return t==null?1:t}}
A.e9.prototype={
$0(){var t=u.S
return A.y(t,t)},
$S:17}
A.ea.prototype={
$2(a,b){A.aD(a)
A.aD(b)
return a>this.a},
$S:18}
A.dN.prototype={
cX(a,b){var t,s=this.a,r=s.ag(b).ao(a)
if(r==null||r.d)return null
t=s.av(b,r.c)
if(B.b.M(t,"/"))t=B.b.C(t,1)
return s.a.bI(t)},
cY(a,b){var t,s=this.a,r=s.ag(b).ao(a)
if(r==null||r.d)return null
t=s.av(b,r.c)
if(B.b.M(t,"/"))t=B.b.C(t,1)
return s.b.d9(t)}}
A.dO.prototype={
ct(b5){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2="word/settings.xml",b3=A.jc(b5),b4=b3.a5("[Content_Types].xml")
if(b4==null)A.a6(B.a5)
t=u.N
s=new A.eb(b3,A.iv(b4),A.y(t,u.at))
r=s.gbH()
q=b3.a5(B.b.M(r,"/")?B.b.C(r,1):r)
if(q==null)throw A.b(A.dT("Parte principal ausente: "+r,null,null))
p=A.cf()
o=u.v
A.cg(q,new A.ab(p,A.d([],o)))
n=u.C
m=new A.T(p.b,n).ga3(0).j("w:body")
if(m==null)throw A.b(B.ab)
l=B.b.aW(q,"<w:body>")
k=B.b.b_(q,"</w:body>")
if(l<0||k<0)throw A.b(B.a9)
B.b.v(q,0,l+8)
B.b.C(q,k)
j=A.j_(m.j("w:sectPr"))
i=this.aN(m,B.aG)
h=A.fZ(s,"word/styles.xml",A.kH(),A.kG(),u.fw)
g=A.fZ(s,"word/numbering.xml",A.kA(),A.kz(),u.eS)
f=b3.a5(B.b.M(b2,"/")?B.b.C(b2,1):b2)
if(f==null)p=null
else{p=A.cf()
A.cg(f,new A.ab(p,A.d([],o)))
p=new A.T(p.b,n).ga3(0)}A.j0(p)
p=u.cf
e=A.y(t,p)
d=A.y(t,p)
if(j!=null){c=s.ag(r)
for(t=[new A.bu(j.Q,e,"w:hdr"),new A.bu(j.as,d,"w:ftr")],p=u.m,b=this.a,a=0;a<2;++a){a0=t[a]
a1=a0.b
a2=a0.c
for(a0=J.H(a0.a);a0.n();){a3=a0.gq()
a4=a3.b
a5=c.ao(a4)
if(a5==null){B.a.i(b,"refer\xeancia de header/footer sem rel: "+a4)
continue}a6=s.av(r,a5.c)
a7=b3.a5(B.b.M(a6,"/")?B.b.C(a6,1):a6)
if(a7==null){B.a.i(b,"parte de header/footer ausente: "+a6)
continue}a4=A.d([],p)
a8=A.d([],o)
a9=a7.length
if(a9!==0){if(0>=a9)return A.a(a7,0)
a9=a7.charCodeAt(0)===65279}else a9=!1
b0=a9?1:0
a9=b0===0?a7:B.b.C(a7,b0)
new A.ds(a9,new A.ab(new A.dp(a4),a8)).bu()
b1=new A.T(a4,n).gu(0)
if(!b1.n())A.a6(A.fg())
a4=b1.gq()
a8=a4.b
if(a8!==a2)B.a.i(b,"raiz inesperada em "+a6+": "+a8)
a1.m(0,a3.a,new A.dg(a6,this.bt(a4)))}}}return new A.dN(s,new A.ev(i,j),h,g,e,d)},
aN(a,b){var t,s,r,q,p,o,n
u.cq.a(b)
t=A.d([],u.F)
for(s=B.a.gu(a.d),r=new A.U(s,u.y),q=this.a,p=u.X;r.n();){o=p.a(s.gq())
n=o.b
if(b.S(0,n))continue
$label0$1:{if("w:p"===n){B.a.i(t,this.cm(o))
break $label0$1}if("w:tbl"===n){B.a.i(t,this.cp(o))
break $label0$1}B.a.i(q,"bloco preservado: "+n)
o.P(new A.z(""))
B.a.i(t,new A.bl(n))}}return t},
bt(a){return this.aN(a,B.aJ)},
cm(a){var t,s,r,q,p,o,n,m,l,k,j,i,h=A.d([],u.fL)
for(t=B.a.gu(a.d),s=new A.U(t,u.y),r=u.X,q=u.f0,p=null;s.n();){o=r.a(t.gq())
n=o.b
if("w:pPr"===n){p=A.fv(o)
continue}if("w:r"===n){B.a.i(h,this.aO(o))
continue}if("w:hyperlink"===n){m=o.l("r:id")
l=o.l("w:anchor")
k=A.d([],q)
for(o=o.K("w:r"),j=o.$ti,o=new A.m(o.a(),j.h("m<1>")),j=j.c;o.n();){i=o.b
k.push(this.aO(i==null?j.a(i):i))}B.a.i(h,new A.bi(m,l,k))
continue}if("w:fldSimple"===n){m=o.l("w:instr")
if(m==null)m=""
l=A.d([],q)
for(o=o.K("w:r"),k=o.$ti,o=new A.m(o.a(),k.h("m<1>")),k=k.c;o.n();){j=o.b
l.push(this.aO(j==null?k.a(j):j))}B.a.i(h,new A.bo(m,l))
continue}o.P(new A.z(""))
B.a.i(h,new A.bm(n))}a.ah()
return new A.a9(p,h)},
aO(a){var t,s,r,q,p,o,n,m,l=A.d([],u.E)
for(t=B.a.gu(a.d),s=new A.U(t,u.y),r=u.X,q=null;s.n();){p=r.a(t.gq())
o=p.b
if("w:rPr"===o){q=A.di(p)
continue}if("w:t"===o){n=new A.z("")
p.ak(n)
p=n.a
B.a.i(l,new A.aa(p.charCodeAt(0)==0?p:p))
continue}if("w:tab"===o){B.a.i(l,new A.cd())
continue}if("w:br"===o){B.a.i(l,new A.bf(p.l("w:type")))
continue}if("w:cr"===o){B.a.i(l,new A.bf(null))
continue}if("w:noBreakHyphen"===o){B.a.i(l,new A.cb())
continue}if("w:softHyphen"===o)continue
if("w:sym"===o){p.l("w:font")
B.a.i(l,new A.cc(p.l("w:char")))
continue}if("w:drawing"===o){B.a.i(l,this.cj(p))
continue}if("w:fldChar"===o){p=p.l("w:fldCharType")
B.a.i(l,new A.bg(p==null?"begin":p))
continue}if("w:instrText"===o){n=new A.z("")
p.ak(n)
p=n.a
B.a.i(l,new A.bj(p.charCodeAt(0)==0?p:p))
continue}if("w:lastRenderedPageBreak"===o)continue
if("mc:AlternateContent"===o){m=this.cq(p)
if(m==null){p.P(new A.z(""))
p=new A.bn(o)}else p=m
B.a.i(l,p)
continue}p.P(new A.z(""))
B.a.i(l,new A.bn(o))}return new A.aV(q,l)},
cq(a0){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=null,d="wp:posOffset",c="a:srgbClr",b=a0.Z("wps:wsp"),a=b.$ti
b=new A.m(b.a(),a.h("m<1>"))
$loop$0:{if(b.n()){b=b.b
t=b==null?a.c.a(b):b
break $loop$0}else t=e}if(t==null)return e
b=t.Z("w:txbxContent")
a=b.$ti
b=new A.m(b.a(),a.h("m<1>"))
$loop$1:{if(b.n()){b=b.b
s=b==null?a.c.a(b):b
break $loop$1}else s=e}if(s==null)return e
b=a0.Z("wp:anchor")
a=b.$ti
b=new A.m(b.a(),a.h("m<1>"))
$loop$2:{if(b.n()){b=b.b
r=b==null?a.c.a(b):b
break $loop$2}else r=e}q=e
if(r!=null){p=r.j("wp:positionH")
b=p==null
if(!b){a=p.j("wp:align")
q=a==null?e:B.b.W(a.ga7())}if(b)b=e
else{b=p.j(d)
b=b==null?e:B.b.W(b.ga7())}A.E(b==null?"":b,e)
o=r.j("wp:positionV")
if(o==null)b=e
else{b=o.j(d)
b=b==null?e:B.b.W(b.ga7())}n=A.E(b==null?"":b,e)
m=r.j("wp:extent")
b=m==null
a=b?e:m.l("cx")
l=A.E(a==null?"":a,e)
b=b?e:m.l("cy")
k=A.E(b==null?"":b,e)}else{k=e
l=k
n=l}j=t.j("wps:spPr")
i=e
h=e
if(j!=null){g=j.j("a:ln")
b=g==null
a=b?e:g.l("w")
f=A.E(a==null?"":a,e)
if(!b){b=g.Z(c)
a=b.$ti
b=new A.m(b.a(),a.h("m<1>"))
$loop$3:{if(b.n()){b=b.b
i=(b==null?a.c.a(b):b).l("val")
break $loop$3}}}b=j.j("a:solidFill")
if(!(b==null)){b=b.j(c)
h=b==null?e:b.l("val")}}else f=e
b=this.bt(s)
a0.ah()
return new A.bp(q,n,l,k,f,i,h,b)},
cj(a){var t,s,r,q,p=null,o=a.j("wp:inline"),n=a.j("wp:anchor"),m=o==null,l=m?n:o,k=l==null?p:l.j("wp:extent")
for(t=a.Z("a:blip"),s=t.$ti,t=new A.m(t.a(),s.h("m<1>")),s=s.c,r=p;t.n();){q=t.b
if(q==null)q=s.a(q)
r=q.l("r:embed")
if(r==null)r=q.l("r:link")
if(r!=null)break}if(n!=null)B.a.i(this.a,"drawing flutuante (anchor) tratado como inline")
t=k==null
s=t?p:k.l("cx")
s=A.hc(s==null?"":s)
t=t?p:k.l("cy")
return new A.ca(r,s,A.hc(t==null?"":t),!m,a.ah())},
cp(a){var t,s,r,q,p,o,n,m,l,k=A.d([],u.t),j=A.d([],u.cB)
for(t=B.a.gu(a.d),s=new A.U(t,u.y),r=this.a,q=u.X,p=null;s.n();){o=q.a(t.gq())
n=o.b
if("w:tblPr"===n){p=A.hs(o)
continue}if("w:tblGrid"===n){for(o=o.K("w:gridCol"),m=o.$ti,o=new A.m(o.a(),m.h("m<1>")),m=m.c;o.n();){l=o.b
l=(l==null?m.a(l):l).l("w:w")
l=A.E(l==null?"":l,null)
B.a.i(k,l==null?0:l)}continue}if("w:tr"===n){B.a.i(j,this.cn(o))
continue}B.a.i(r,"filho de tabela ignorado: "+n)}a.ah()
return new A.aY(p,k,j)},
cn(a){var t,s,r,q,p,o,n,m,l,k=A.d([],u.cz)
for(t=B.a.gu(a.d),s=new A.U(t,u.y),r=this.a,q=u.X,p=null;s.n();){o=q.a(t.gq())
n=o.b
if("w:trPr"===n){p=A.j4(o)
continue}if("w:tc"===n){m=o.j("w:tcPr")
l=m!=null?A.j3(m):null
B.a.i(k,new A.dl(l,this.aN(o,B.aH)))
continue}if("w:tblPrEx"===n){B.a.i(r,"tblPrEx ignorado em linha de tabela")
continue}B.a.i(r,"filho de linha ignorado: "+n)}return new A.dm(p,k)}}
A.aX.prototype={}
A.az.prototype={
cK(a){var t,s,r
for(t=this.c.gda(),s=A.k(t),t=new A.aS(J.H(t.a),t.b,s.h("aS<1,2>")),s=s.y[1];t.n();){r=t.a
if(r==null)r=s.a(r)
if(r.f&&r.b===a)return r}return null},
ap(a){var t,s=A.d([],u.d5),r=A.iF(u.N),q=a==null?null:this.c.k(0,a),p=this.c,o=u.U,n=s.$flags|0
while(!0){if(!(q!=null&&r.i(0,q.a)))break
o.a(q)
n&1&&A.O(s,"insert",2)
s.splice(0,0,q)
t=q.d
q=t==null?null:p.k(0,t)}return s}}
A.dK.prototype={
d9(a){var t,s=B.b.M(a,"/")?a:"/"+a,r=this.b.k(0,s)
if(r!=null)return r
t=B.b.b_(s,".")
if(t<0)return null
return this.a.k(0,B.b.C(s,t+1).toLowerCase())}}
A.eb.prototype={
ag(a){var t,s,r,q,p,o,n,m
if(a==null)t="_rels/.rels"
else{s=B.b.M(a,"/")?B.b.C(a,1):a
r=B.b.b_(s,"/")
q=r<0
p=q?"":B.b.v(s,0,r+1)
s=q?s:B.b.C(s,r+1)
t=p+"_rels/"+s+".rels"}q=this.c
o=q.k(0,t)
if(o!=null)return o
n=this.a.a5(t)
m=n==null?A.hf():A.iV(n)
q.m(0,t,m)
return m},
av(a,b){var t,s,r,q,p,o,n
if(B.b.M(b,"/"))return B.b.C(b,1)
if(a==null)t=""
else{s=B.b.M(a,"/")?B.b.C(a,1):a
r=A.fq("[^/]+$",!0)
A.iT(0,0,s.length,"startIndex")
t=A.kE(s,r,"",0)}s=A.e4(new A.c6(A.d(t.split("/"),u.s),u.bB.a(new A.ec()),u.cc),!0,u.N)
for(r=b.split("/"),q=r.length,p=0;p<q;++p){o=r[p]
if(o===".."){n=s.length
if(n!==0){if(0>=n)return A.a(s,-1)
s.pop()}}else if(o!=="."&&o.length!==0)B.a.i(s,o)}return B.a.bG(s,"/")},
gbH(){var t=this.ag(null).cS("http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument")
if(t==null)throw A.b(B.aa)
return this.av(null,t.c)}}
A.ec.prototype={
$1(a){return A.bv(a).length!==0},
$S:19}
A.d7.prototype={
p(a){var t=this,s=t.d?", external":""
return"Relationship("+t.a+", "+t.b+", "+t.c+s+")"}}
A.d8.prototype={
ao(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(q.a===a)return q}return null},
cS(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(q.b===a)return q}return null}}
A.ak.prototype={
ah(){var t,s=new A.z("")
this.P(s)
t=s.a
return t.charCodeAt(0)==0?t:t}}
A.ch.prototype={
P(a){var t=A.j8(this.b)
a.a+=t
return null}}
A.ce.prototype={
P(a){var t=a.a+="<![CDATA["
t+=this.b
a.a=t
a.a=t+"]]>"}}
A.dn.prototype={
P(a){var t=a.a+="<!--"
t+=this.b
a.a=t
a.a=t+"-->"}}
A.dq.prototype={
P(a){var t=a.a+="<?"+this.b,s=this.c
if(s!=null&&s.length!==0)t=a.a=t+(" "+A.p(s))
a.a=t+"?>"}}
A.aA.prototype={
p(a){return this.a+'="'+this.b+'"'}}
A.V.prototype={
bW(a,b,c){var t,s
for(t=this.d.length,s=0;s<t;++s);},
l(a){var t,s,r,q
for(t=this.c,s=t.length,r=0;r<s;++r){q=t[r]
if(q.a===a)return q.b}return null},
j(a){var t,s,r,q
for(t=this.d,s=t.length,r=0;r<s;++r){q=t[r]
if(q instanceof A.V&&q.b===a)return q}return null},
K(a){return new A.b0(this.cG(a),u.Y)},
cG(a){var t=this
return function(){var s=a
var r=0,q=1,p,o,n,m,l
return function $async$K(b,c,d){if(c===1){p=d
r=q}while(true)switch(r){case 0:o=t.d,n=o.length,m=0
case 2:if(!(m<o.length)){r=4
break}l=o[m]
r=l instanceof A.V&&l.b===s?5:6
break
case 5:r=7
return b.b=l,1
case 7:case 6:case 3:o.length===n||(0,A.q)(o),++m
r=2
break
case 4:return 0
case 1:return b.c=p,3}}}},
Z(a){return new A.b0(this.cL(a),u.Y)},
cL(a){var t=this
return function(){var s=a
var r=0,q=1,p,o,n,m,l
return function $async$Z(b,c,d){if(c===1){p=d
r=q}while(true)switch(r){case 0:o=t.d,n=o.length,m=0
case 2:if(!(m<o.length)){r=4
break}l=o[m]
r=l instanceof A.V?5:6
break
case 5:r=l.b===s?7:8
break
case 7:r=9
return b.b=l,1
case 9:case 8:r=10
return b.cB(l.Z(s))
case 10:case 6:case 3:o.length===n||(0,A.q)(o),++m
r=2
break
case 4:return 0
case 1:return b.c=p,3}}}},
ga7(){var t,s=new A.z("")
this.ak(s)
t=s.a
return t.charCodeAt(0)==0?t:t},
ak(a){var t,s,r,q
for(t=this.d,s=t.length,r=0;r<t.length;t.length===s||(0,A.q)(t),++r){q=t[r]
if(q instanceof A.ch)a.a+=q.b
if(q instanceof A.ce)a.a+=q.b
if(q instanceof A.V)q.ak(a)}},
P(a){var t,s,r,q,p=a.a+="<",o=this.b
p=a.a=p+o
for(t=this.c,s=t.length,r=0;r<t.length;t.length===s||(0,A.q)(t),++r){q=t[r]
p+=" "
a.a=p
p+=q.a
a.a=p
a.a=p+'="'
p=A.j7(q.b)
p=a.a+=p
p+='"'
a.a=p}t=this.d
s=t.length
if(s===0){a.a=p+"/>"
return}a.a=p+">"
for(r=0;r<t.length;t.length===s||(0,A.q)(t),++r)t[r].P(a)
p=a.a+="</"
o=p+o
a.a=o
a.a=o+">"}}
A.dp.prototype={}
A.ab.prototype={
b6(a,b,c){var t,s,r,q
u.fb.a(b)
if(b.length===0)t=null
else{t=A.a5(b)
s=t.h("a3<1,aA>")
s=A.e4(new A.a3(b,t.h("aA(1)").a(new A.eL()),s),!0,s.h("J.E"))
t=s}s=t==null?A.d([],u.av):t
r=A.d([],u.m)
q=new A.V(a,s,r)
q.bW(a,t,null)
t=this.b
if(t.length===0)B.a.i(this.a.b,q)
else B.a.i(B.a.gH(t).d,q)
B.a.i(t,q)},
cF(a){var t=this.b
if(t.length===0)return
B.a.i(B.a.gH(t).d,new A.ch(a))},
cE(a){var t=this.b
if(t.length===0)return
B.a.i(B.a.gH(t).d,new A.ce(a))}}
A.eL.prototype={
$1(a){u.fN.a(a)
return new A.aA(a.a,a.b)},
$S:20}
A.aB.prototype={
p(a){return this.a+'="'+this.b+'"'}}
A.dr.prototype={}
A.eH.prototype={}
A.ds.prototype={
bu(){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=this,a1=a0.a,a2=a1.length
for(t=a0.b,s=t.a.b,r=t.b,q=0,p=!1;o=a0.c,o<a2;){if(!(o>=0))return A.a(a1,o)
if(a1.charCodeAt(o)===60){n=o+1
if(n>=a2)throw A.b(A.v("Documento termina dentro de tag",a1,o))
m=a1.charCodeAt(n)
if(m===47){l=a0.cl();--q
if(q<0)throw A.b(A.v("Tag de fechamento sem abertura: </"+l+">",a1,a0.c))
if(0>=r.length)return A.a(r,-1)
r.pop()}else if(m===33)if(B.b.aj(a1,"<!--",o)){n=o+4
k=B.b.V(a1,"-->",n)
if(k<0)A.a6(A.v("Coment\xe1rio n\xe3o terminado",a1,o))
j=new A.dn(B.b.v(a1,n,k))
if(r.length===0)B.a.i(s,j)
else B.a.i(B.a.gH(r).d,j)
a0.c=k+3}else if(B.b.aj(a1,"<![CDATA[",o)){if(q===0)throw A.b(A.v("CDATA fora do elemento raiz",a1,o))
n=o+9
k=B.b.V(a1,"]]>",n)
if(k<0)A.a6(A.v("CDATA n\xe3o terminado",a1,o))
t.cE(B.b.v(a1,n,k))
a0.c=k+3}else if(B.b.aj(a1,"<!DOCTYPE",o))a0.cw()
else throw A.b(A.v('Marca\xe7\xe3o "<!" desconhecida',a1,o))
else if(m===63){n=o+2
k=B.b.V(a1,"?>",n)
if(k<0)A.a6(A.v("Processing instruction n\xe3o terminada",a1,o))
i=B.b.v(a1,n,k)
a0.c=k+2
h=A.ja(i)
n=h<0
g=n?i:B.b.v(i,0,h)
f=n?null:B.b.W(B.b.C(i,h+1))
if(g.toLowerCase()==="xml"){if(o!==0)A.a6(A.v("Declara\xe7\xe3o XML fora do in\xedcio do documento",a1,a0.c))
e=A.jb(f==null?"":f)
e.k(0,"version")
e.k(0,"encoding")
e.k(0,"standalone")}else{j=new A.dq(g,f)
if(r.length===0)B.a.i(s,j)
else B.a.i(B.a.gH(r).d,j)}}else{if(q===0&&p)throw A.b(A.v("Mais de um elemento raiz no documento",a1,o))
if(!a0.co())++q
p=!0}}else{d=B.b.V(a1,"<",o)
k=d<0?a2:d
if(q>0){c=a0.c8(a1,o,k)
if(c.length!==0)t.cF(c)}else for(b=o;b<k;++b){if(!(b<a2))return A.a(a1,b)
a=a1.charCodeAt(b)
if(a!==32&&a!==9&&a!==10&&a!==13)throw A.b(A.v("Texto fora do elemento raiz",a1,b))}a0.c=k}}if(q!==0)throw A.b(A.v("Elemento n\xe3o fechado no fim do documento",a1,a2===0?0:a2-1))
if(!p)throw A.b(A.v("Documento sem elemento raiz",a1,0))},
co(){var t,s,r,q,p,o,n,m,l,k,j=this,i='Valor do atributo "',h=j.a,g=h.length,f=j.c,e=f+1,d=e
while(!0){if(d<g){if(!(d>=0))return A.a(h,d)
t=h.charCodeAt(d)
t=!(t===32||t===9||t===10||t===13||t===62||t===47||t===61)}else t=!1
if(!t)break;++d}if(d===e)throw A.b(A.v("Nome de elemento vazio",h,f))
s=B.b.v(h,e,d)
for(f=u.u,e=d,r=null;!0;){e=j.al(e)
if(e>=g)throw A.b(A.v("Tag n\xe3o terminada: <"+s,h,j.c))
if(!(e>=0))return A.a(h,e)
q=h.charCodeAt(e)
if(q===62){j.c=e+1
f=r==null?B.I:r
j.b.b6(s,f,!1)
return!1}if(q===47){f=e+1
if(f<g){if(!(f<g))return A.a(h,f)
f=h.charCodeAt(f)!==62}else f=!0
if(f)throw A.b(A.v('Esperado "/>" na tag <'+s,h,e))
j.c=e+2
f=j.b
f.b6(s,r==null?B.I:r,!0)
f=f.b
if(0>=f.length)return A.a(f,-1)
f.pop()
return!0}for(d=e;d<g;){p=h.charCodeAt(d)
if(p===61||p===32||p===9||p===10||p===13||p===62||p===47)break;++d}if(d===e)throw A.b(A.v("Caractere inesperado na tag <"+s,h,d))
o=B.b.v(h,e,d)
e=j.al(d)
if(e<g){if(!(e>=0&&e<g))return A.a(h,e)
t=h.charCodeAt(e)!==61}else t=!0
if(t)throw A.b(A.v('Atributo "'+o+'" sem "=" na tag <'+s,h,e))
e=j.al(e+1)
if(e>=g)throw A.b(A.v("Valor de atributo ausente",h,e-1))
if(!(e>=0))return A.a(h,e)
n=h.charCodeAt(e)
t=n===34
if(!t&&n!==39)throw A.b(A.v(i+o+'" sem aspas',h,e))
m=e+1
l=B.b.V(h,t?'"':"'",m)
if(l<0)throw A.b(A.v(i+o+'" n\xe3o terminado',h,e))
k=j.c7(h,m,l)
if(r==null){r=A.d([],f)
t=r}else t=r
B.a.i(t,new A.aB(o,k))
e=l+1}},
cl(){var t,s,r=this,q=r.a,p=q.length,o=r.c+2,n=o
while(!0){if(n<p){if(!(n>=0))return A.a(q,n)
t=q.charCodeAt(n)
t=!(t===32||t===9||t===10||t===13||t===62||t===47||t===61)}else t=!1
if(!t)break;++n}s=B.b.v(q,o,n)
o=r.al(n)
if(o<p){if(!(o>=0&&o<p))return A.a(q,o)
t=q.charCodeAt(o)!==62}else t=!0
if(t)throw A.b(A.v("Tag </"+s+" n\xe3o terminada",q,r.c))
r.c=o+1
return s},
cw(){var t,s,r,q=this,p=q.a,o=p.length,n=q.c+9
for(t=0;n<o;){if(!(n>=0))return A.a(p,n)
s=p.charCodeAt(n)
if(s===34||s===39){r=B.b.V(p,A.i(s),n+1)
if(r<0)break
n=r+1
continue}if(s===91)++t
if(s===93)--t
if(s===62&&t<=0){q.c=n+1
return}++n}throw A.b(A.v("DOCTYPE n\xe3o terminado",p,q.c))},
al(a){var t,s=this.a,r=s.length
for(;a<r;){if(!(a>=0))return A.a(s,a)
t=s.charCodeAt(a)
if(t!==32&&t!==9&&t!==10&&t!==13)break;++a}return a},
c8(a,b,c){var t,s,r,q,p,o=a.length,n=b
while(!0){if(!(n<c)){t=!1
break}if(!(n>=0&&n<o))return A.a(a,n)
s=a.charCodeAt(n)
if(s===38||s===13){t=!0
break}++n}if(!t)return B.b.v(a,b,c)
r=new A.z("")
for(n=b;n<c;){if(!(n>=0&&n<o))return A.a(a,n)
s=a.charCodeAt(n)
if(s===38)n=this.bj(a,n,c,r)
else if(s===13){q=A.i(10)
r.a+=q
p=n+1
if(p<c){if(!(p<o))return A.a(a,p)
q=a.charCodeAt(p)===10}else q=!1
n=(q?p:n)+1}else{q=A.i(s)
r.a+=q;++n}}o=r.a
return o.charCodeAt(0)==0?o:o},
c7(a,b,c){var t,s,r,q,p,o=a.length,n=b
while(!0){if(!(n<c)){t=!1
break}if(!(n>=0&&n<o))return A.a(a,n)
s=a.charCodeAt(n)
if(s===38||s===9||s===10||s===13){t=!0
break}++n}if(!t)return B.b.v(a,b,c)
r=new A.z("")
for(n=b;n<c;){if(!(n>=0&&n<o))return A.a(a,n)
s=a.charCodeAt(n)
if(s===38)n=this.bj(a,n,c,r)
else if(s===9||s===10||s===13){q=A.i(32)
r.a+=q
q=!1
if(s===13){p=n+1
if(p<c){if(!(p<o))return A.a(a,p)
q=a.charCodeAt(p)===10}}n=(q?n+1:n)+1}else{q=A.i(s)
r.a+=q;++n}}o=r.a
return o.charCodeAt(0)==0?o:o},
bj(a,b,c,d){var t,s,r,q,p,o,n=b+1,m=B.b.V(a,";",n)
if(m<0||m>=c||m-b>12)throw A.b(A.v("Refer\xeancia de entidade malformada",a,b))
t=a.length
if(!(n>=0&&n<t))return A.a(a,n)
if(a.charCodeAt(n)===35){s=b+2
if(!(s>=0&&s<t))return A.a(a,s)
r=a.charCodeAt(s)===120||a.charCodeAt(s)===88
if(r)t=b+3
else t=s
q=B.b.v(a,t,m)
p=A.E(q,r?16:10)
if(p==null)throw A.b(A.v("Refer\xeancia de caractere inv\xe1lida: &"+B.b.v(a,n,m)+";",a,b))
n=A.i(p)
d.a+=n
return m+1}o=B.b.v(a,n,m)
$label0$0:{if("amp"===o){n=A.i(38)
d.a+=n
break $label0$0}if("lt"===o){n=A.i(60)
d.a+=n
break $label0$0}if("gt"===o){n=A.i(62)
d.a+=n
break $label0$0}if("quot"===o){n=A.i(34)
d.a+=n
break $label0$0}if("apos"===o){n=A.i(39)
d.a+=n
break $label0$0}throw A.b(A.v("Entidade desconhecida: &"+o+";",a,b))}return m+1}}
A.dV.prototype={
bV(a){var t,s,r,q,p,o,n,m,l,k,j,i,h=this,g=a.length
for(t=0;t<g;++t){s=a[t]
if(s>h.b)h.b=s
if(s<h.c)h.c=s}s=h.b
r=B.c.ai(1,s)
q=h.a=new Uint32Array(r)
for(p=1,o=0,n=2;p<=s;){for(m=p<<16,t=0;t<g;++t)if(a[t]===p){for(l=o,k=0,j=0;j<p;++j){k=(k<<1|l&1)>>>0
l=l>>>1}for(i=(m|t)>>>0,j=k;j<r;j+=n){if(!(j>=0))return A.a(q,j)
q[j]=i}++o}++p
o=o<<1>>>0
n=n<<1>>>0}}}
A.dW.prototype={
gN(){var t=this.a
if(t==null)return t
t.d===$&&A.bA()
return t},
cd(){var t,s,r=this
r.e=r.d=0
if(r.gN()==null)return
while(!0){t=r.gN()
s=t.c
t=t.d
t===$&&A.bA()
if(!(s<t))break
if(!r.ci())return}},
ci(){var t,s,r,q=this,p=q.gN()
if(p!=null){t=p.c
s=p.d
s===$&&A.bA()
s=t>=s
t=s}else t=!0
if(t)return!1
r=q.I(3)
switch(B.c.aR(r,1)){case 0:if(q.cr()===-1)return!1
break
case 1:if(q.bk(q.r,q.w)===-1)return!1
break
case 2:if(q.ck()===-1)return!1
break
default:return!1}return(r&1)===0},
I(a){var t,s,r,q,p=this
if(a===0)return 0
for(;t=p.e,t<a;){t=p.gN()
s=t.c
t=t.d
t===$&&A.bA()
if(s>=t)return-1
t=p.gN()
s=t.b
s.toString
t=t.c++
if(!(t>=0&&t<s.length))return A.a(s,t)
r=s[t]
t=p.d
s=p.e
p.d=(t|B.c.ai(r,s))>>>0
p.e=s+8}s=p.d
q=B.c.cv(1,a)
p.d=B.c.aQ(s,a)
p.e=t-a
return(s&q-1)>>>0},
aP(a){var t,s,r,q,p,o,n,m=this,l=a.a
l===$&&A.bA()
t=a.b
for(;s=m.e,s<t;){s=m.gN()
r=s.c
s=s.d
s===$&&A.bA()
if(r>=s)return-1
s=m.gN()
r=s.b
r.toString
s=s.c++
if(!(s>=0&&s<r.length))return A.a(r,s)
q=r[s]
s=m.d
r=m.e
m.d=(s|B.c.ai(q,r))>>>0
m.e=r+8}r=m.d
p=(r&B.c.ai(1,t)-1)>>>0
if(!(p<l.length))return A.a(l,p)
o=l[p]
n=o>>>16
m.d=B.c.aQ(r,n)
m.e=s-n
return o&65535},
cr(){var t,s,r,q=this
q.e=q.d=0
t=q.I(16)
s=q.I(16)
if(t!==0&&t!==(s^65535)>>>0)return-1
if(t>q.gN().gt(0))return-1
s=q.gN()
r=s.bP(t,s.c)
s.c=s.c+r.gt(0)
q.c.de(r)
return 0},
ck(){var t,s,r,q,p,o,n,m,l,k,j=this,i=j.I(5)
if(i===-1)return-1
i+=257
if(i>288)return-1
t=j.I(5)
if(t===-1)return-1;++t
if(t>32)return-1
s=j.I(4)
if(s===-1)return-1
s+=4
if(s>19)return-1
r=new Uint8Array(19)
for(q=0;q<s;++q){p=j.I(3)
if(p===-1)return-1
o=B.ak[q]
if(!(o<19))return A.a(r,o)
r[o]=p}n=A.cJ(r)
o=i+t
m=new Uint8Array(o)
l=J.bB(B.e.ga2(m),0,i)
k=J.bB(B.e.ga2(m),i,t)
if(j.c6(o,n,m)===-1)return-1
return j.bk(A.cJ(l),A.cJ(k))},
bk(a,b){var t,s,r,q,p,o,n,m,l=this
for(t=l.c;!0;){s=l.aP(a)
if(s<0||s>285)return-1
if(s===256)break
if(s<256){if(t.b===t.c.length)t.c9()
r=t.c
q=t.b++
r.$flags&2&&A.O(r)
if(!(q>=0&&q<r.length))return A.a(r,q)
r[q]=s&255
continue}p=s-257
if(!(p>=0&&p<29))return A.a(B.J,p)
o=B.J[p]+l.I(B.aj[p])
n=l.aP(b)
if(n<0||n>29)return-1
if(!(n>=0&&n<30))return A.a(B.H,n)
m=B.H[n]+l.I(B.an[n])
for(r=-m;o>m;){t.b2(t.b7(r))
o-=m}if(o===m)t.b2(t.b7(r))
else t.b2(t.b8(r,o-m))}for(;t=l.e,t>=8;){l.e=t-8
t=l.gN()
r=--t.c
q=t.d
q===$&&A.bA()
t.scs(B.c.bD(r,0,q))}return 0},
c6(a,b,c){var t,s,r,q,p,o,n,m,l=this
for(t=0,s=0;s<a;){r=l.aP(b)
if(r===-1)return-1
q=0
switch(r){case 16:p=l.I(2)
if(p===-1)return-1
p+=3
for(o=c.$flags|0;n=p-1,p>0;p=n,s=m){m=s+1
o&2&&A.O(c)
if(!(s>=0&&s<c.length))return A.a(c,s)
c[s]=t}break
case 17:p=l.I(3)
if(p===-1)return-1
p+=3
for(o=c.$flags|0;n=p-1,p>0;p=n,s=m){m=s+1
o&2&&A.O(c)
if(!(s>=0&&s<c.length))return A.a(c,s)
c[s]=0}t=q
break
case 18:p=l.I(7)
if(p===-1)return-1
p+=11
for(o=c.$flags|0;n=p-1,p>0;p=n,s=m){m=s+1
o&2&&A.O(c)
if(!(s>=0&&s<c.length))return A.a(c,s)
c[s]=0}t=q
break
default:if(r<0||r>15)return-1
m=s+1
c.$flags&2&&A.O(c)
if(!(s>=0&&s<c.length))return A.a(c,s)
c[s]=r
s=m
t=r
break}}return 0}}
A.dH.prototype={
X(){return"ByteOrder."+this.b}}
A.cN.prototype={
gt(a){var t=this.b
return t==null?0:t.length-this.c},
bP(a,b){var t=this.b
if(t==null)return A.ff(A.d([],u.t),B.z,null,null)
return A.ff(t,this.a,a,b)},
scs(a){this.c=A.aD(a)}}
A.cO.prototype={}
A.d1.prototype={
b2(a){var t,s,r,q,p,o=this
u.L.a(a)
t=a.length
for(;s=o.b,r=s+t,q=o.c,p=q.length,r>p;)o.aI(r-p)
B.e.b4(q,s,r,a)
o.b+=t},
de(a){var t,s,r,q,p,o,n=this
while(!0){t=n.b
s=a.b
r=s==null
q=r?0:s.length-a.c
p=n.c
o=p.length
if(!(t+q>o))break
n.aI(t+(r?0:s.length-a.c)-o)}if(!r){s=a.gt(0)
r=a.b
r.toString
B.e.b5(p,t,t+s,r,a.c)}n.b=n.b+a.gt(0)},
b8(a,b){var t=this
if(a<0)a=t.b+a
if(b==null)b=t.b
else if(b<0)b=t.b+b
return J.bB(B.e.ga2(t.c),t.c.byteOffset+a,b-a)},
b7(a){return this.b8(a,null)},
aI(a){var t=a!=null?a>32768?a:32768:32768,s=this.c,r=s.length,q=new Uint8Array((r+t)*2)
B.e.b4(q,0,r,s)
this.c=q},
c9(){return this.aI(null)},
gt(a){return this.b}}
A.d2.prototype={}
A.dt.prototype={
gcI(){var t,s,r,q,p,o=this,n=o.w
if(n!=null)return n
t=o.d
t.toString
s=o.e
if(s===0)r=new Uint8Array(A.fG(t))
else if(s===8){s=o.r
q=A.cJ(B.ao)
p=A.cJ(B.am)
t=A.ff(t,B.z,null,null)
s=new A.d1(new Uint8Array(s))
new A.dW(t,s,q,p).cd()
r=J.bB(B.e.ga2(s.c),s.c.byteOffset,s.b)}else throw A.b(A.bd("ZIP compression method "+s+" is not supported."))
return o.w=r}}
A.eI.prototype={
bI(a){var t,s=this.b.k(0,a)
if(s==null)t=null
else{t=this.a
if(s>>>0!==s||s>=t.length)return A.a(t,s)
t=t[s]}return t==null?null:t.gcI()},
a5(a){var t=this.bI(a)
if(t==null)return null
return B.E.ad(A.c3(t,t.length>=3&&t[0]===239&&t[1]===187&&t[2]===191?3:0,null))}}
A.R.prototype={
X(){return"ElementType."+this.b}}
A.bb.prototype={
X(){return"RowFlex."+this.b}}
A.db.prototype={
X(){return"TableBorder."+this.b}}
A.aT.prototype={
X(){return"TdBorder."+this.b}}
A.av.prototype={
X(){return"TitleLevel."+this.b}}
A.aN.prototype={}
A.cK.prototype={}
A.cL.prototype={}
A.aO.prototype={}
A.bJ.prototype={}
A.dP.prototype={
ca(b2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0=null,b1="NUMPAGES"
for(t=b2.b,s=t.length,r=this.b,q=0;q<t.length;t.length===s||(0,A.q)(t),++q){p=t[q]
if(!(p instanceof A.a9))continue
o=new A.z("")
for(n=p.b,m=n.length,l=b0,k=!1,j=B.h,i="",h=0;h<n.length;n.length===m||(0,A.q)(n),++h){g=n[h]
f=g instanceof A.bo
e=f?g:b0
if(f){d=e.a.toUpperCase()
c=!0
if(B.b.S(d,b1)){o.a+="{pageCount}"
k=c}else if(B.b.S(d,"PAGE")){o.a+="{pageNo}"
k=c}else for(f=e.b,b=f.length,a=0;a<f.length;f.length===b||(0,A.q)(f),++a){a0=f[a]
a1=a0.ga7()
o.a+=a1
if(l==null)l=r.a0(p,a0.a)}continue}f=g instanceof A.aV
a0=f?g:b0
if(f){for(f=a0.b,b=f.length,a1=a0.a,a=0;a<f.length;f.length===b||(0,A.q)(f),++a){a2=f[a]
a3=a2 instanceof A.bg
a4=a3?a2:b0
if(a3){$label0$2:{a5=a4.a
if("begin"===a5){j=B.i
i=""
break $label0$2}if("separate"===a5){j=B.R
break $label0$2}d=i.toUpperCase()
c=!0
if(B.b.S(d,b1)){o.a+="{pageCount}"
k=c}else if(B.b.S(d,"PAGE")){o.a+="{pageNo}"
k=c}j=B.h}continue}a3=a2 instanceof A.bj
d=a3?a2:b0
if(a3){if(j===B.i)i+=d.a
continue}a3=a2 instanceof A.aa
a6=a3?a2:b0
if(a3){if(j===B.h){a3=a6.a
o.a+=a3
if(l==null)l=r.a0(p,a1)}continue}continue}continue}f=g instanceof A.bi
a7=f?g:b0
if(f){for(f=a7.c,b=f.length,a1=j===B.h,a=0;a<f.length;f.length===b||(0,A.q)(f),++a){a0=f[a]
if(a1){a3=a0.ga7()
o.a+=a3
if(l==null)l=r.a0(p,a0.a)}}continue}if(g instanceof A.bm)continue}if(!k)continue
a8=r.b1(p)
a9=l==null?r.a0(p,b0):l
t=o.a
t=t.charCodeAt(0)==0?t:t
B.a.i(this.d,'campos PAGE/NUMPAGES do rodap\xe9 renderizados dinamicamente (formato "'+t+'")')
s=A.fd(a8.c)
r=a9.z
r=r==null?b0:B.d.a1(r*2/3)
n=a9.b
if(n==null)n=a9.c
return new A.eR(t,s,r,n,A.fc(a9.Q),A.iG([p],u.eO))}return b0},
bf(a,b,c){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this,d=null
u.Q.a(a)
t=A.d([],u.l)
for(s=e.d,r=e.b,q=!0,p=0;p<a.length;++p){o=a[p]
n=t.length
$label0$0:{m=o instanceof A.a9
l=m?o:d
k=!1
if(m){j=r.b1(l)
if(!q)B.a.i(t,e.br(l,j))
B.a.Y(t,e.bg(l,j,b))
q=k
break $label0$0}m=o instanceof A.aY
i=m?o:d
if(m){if(!q)B.a.i(t,A.I(d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,"\n",d,d))
h=e.bh(i,b)
if(h!=null)B.a.i(t,h)
q=k
break $label0$0}m=o instanceof A.bl
g=m?o:d
if(m)B.a.i(s,"bloco preservado n\xe3o renderizado: "+g.a)}if(c)for(f=n;f<t.length;++f)A.fe(t[f],p)}return t},
aD(a,b){return this.bf(a,b,!1)},
c3(a,a0,a1){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=null
u.Q.a(a)
u.aI.a(a1)
t=A.d([],u.l)
for(s=a.length,r=c.d,q=c.b,p=!0,o=0;o<a.length;a.length===s||(0,A.q)(a),++o){n=a[o]
m=n instanceof A.a9
l=m?n:b
k=!1
if(m){j=q.b1(l)
if(!p)B.a.i(t,c.br(l,j))
i=c.bg(l,j,a0)
if(a1.S(0,l)){h=i.length
for(g=h-1;g>=0;--g)if(i[g].c==="\n"){h=g
break}i=B.a.bO(i,0,h)}B.a.Y(t,i)
p=k
continue}m=n instanceof A.aY
f=m?n:b
if(m){if(!p)B.a.i(t,A.I(b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,"\n",b,b))
e=c.bh(f,a0)
if(e!=null)B.a.i(t,e)
p=k
continue}m=n instanceof A.bl
d=m?n:b
if(m)B.a.i(r,"bloco de rodap\xe9 preservado n\xe3o renderizado: "+d.a)}if(t.length===0)B.a.i(t,A.I(b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,"",b,b))
return t},
cA(a){var t,s,r,q,p,o,n,m=null
u.g.a(a)
for(t=a.$flags|0,s=0,r=0;q=a.length,r<=q;++r){if(r!==q){if(!(r>=0&&r<q))return A.a(a,r)
p=a[r].c==="\n"}else p=!0
if(!p)continue
q=this.bo(a,s,r)
if(this.cf(B.b.W(A.fO(q,"\xa0"," ")))){if(s>0){q=s-1
if(!(q<a.length))return A.a(a,q)
q=a[q].c==="\n"}else q=!1
o=q?s-1:s
q=a.length
n=r<q?r+1:r
t&1&&A.O(a,18)
A.d5(o,n,q)
a.splice(o,n-o)
r=o-1
s=o
continue}s=r+1}if(q===0)B.a.i(a,A.I(m,m,m,m,m,m,m,m,m,m,m,m,m,m,m,m,m,"",m,m))},
bo(a,b,c){var t,s,r,q,p
u.g.a(a)
t=new A.z("")
for(s=b;s<c;++s){if(!(s>=0&&s<a.length))return A.a(a,s)
r=a[s]
q=r.b
if(q==null||q===B.o||q===B.p||q===B.n)t.a+=r.c
p=r.y1
if(p!=null){q=this.bo(p,0,p.length)
t.a+=q}}q=t.a
return q.charCodeAt(0)==0?q:q},
cf(a){var t
if(a.length===0)return!1
t=A.fq("^(?:P\xe1gina|Page)\\s+\\d+\\s*(?:\\||/|de|of)\\s*\\d+$",!1)
return t.b.test(a)},
br(a,b){var t,s=null,r=this.b.a0(a,s),q=r.z,p=A.fd(b.c),o=r.b
if(o==null)o=r.c
t=A.I(s,s,s,s,s,o,s,s,s,s,p,q==null?s:B.d.a1(q*2/3),s,s,s,s,s,"\n",s,s)
A.bK(t,this.bq(b))
return t},
bg(b0,b1,b2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=this,a4=null,a5=A.fd(b1.c),a6=a3.bq(b1),a7=u.l,a8=A.d([],a7),a9=b1.b
if(a9!=null){t=a9.a
t=t!=null&&t!==0}else t=!1
if(t){t=a9.a
t.toString
s=a3.c.d4(t,a9.b)
if(s!=null&&s.length!==0)B.a.i(a8,a3.am(A.p(s)+"\t",a3.b.a0(b0,a4),a5,a6))}for(t=b0.b,r=t.length,q=a3.d,p=a3.a.a,o=B.h,n=0;n<t.length;t.length===r||(0,A.q)(t),++n){m=t[n]
l=m instanceof A.aV
k=l?m:a4
if(l){o=a3.aE(b0,k,a8,o,a5,a6,b2)
continue}l=m instanceof A.bi
j=l?m:a4
if(l){i=A.d([],a7)
for(l=j.c,h=l.length,g=B.h,f=0;f<l.length;l.length===h||(0,A.q)(l),++f)g=a3.aE(b0,l[f],i,g,a4,a6,b2)
if(i.length===0)continue
l=j.a
if(l!=null){e=p.ag(b2).ao(l)
d=e!=null&&e.d?e.c:a4}else{l=j.b
d=l!=null?"#"+l:a4}c=A.I(a4,a4,a4,a4,a4,a4,a4,a4,a4,a4,a5,a4,a4,a4,B.n,a4,d==null?"":d,"",i,a4)
A.bK(c,a6)
B.a.i(a8,c)
continue}l=m instanceof A.bo
b=l?m:a4
if(l){B.a.i(q,"fldSimple com resultado em cache: "+B.b.W(b.a))
for(l=b.b,h=l.length,a=B.h,f=0;f<l.length;l.length===h||(0,A.q)(l),++f)a=a3.aE(b0,l[f],a8,a,a5,a6,b2)
continue}l=m instanceof A.bm
a0=l?m:a4
if(l)if(a0.a==="mc:AlternateContent")B.a.i(q,"text box (carimbo) preservado, sem render (placeholder na Fase 4.8)")}a1=b1.at
if(a1!=null&&a1>=0&&a8.length!==0){a2=A.I(a4,a4,a4,a4,a4,a4,a4,a4,a4,A.iy(a1),a5,a4,a4,a4,B.j,a4,a4,"",a8,a4)
A.bK(a2,a6)
return A.d([a2],a7)}return a8},
aE(a4,a5,a6,a7,a8,a9,b0){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=this,a3=null
u.g.a(a6)
t=a2.b.a0(a4,a5.a)
for(s=a5.b,r=s.length,q=a2.d,p=a2.e,o=u.cH,n=a7,m=0;m<s.length;s.length===r||(0,A.q)(s),++m){l=s[m]
k=l instanceof A.bg
j=k?l:a3
if(k){i=j.a
$label0$0:{if("begin"===i){k=B.i
break $label0$0}if("separate"===i){k=B.R
break $label0$0}k=B.h
break $label0$0}n=k
continue}k=l instanceof A.bj
h=k?l:a3
if(k){if(n===B.i)B.a.i(q,"campo com resultado em cache: "+B.b.W(h.a)+" (motor de campos na Fase 4.7)")
continue}k=l instanceof A.aa
g=k?l:a3
if(k){if(n!==B.i&&g.a.length!==0)B.a.i(a6,a2.am(g.a,t,a8,a9))
continue}if(l instanceof A.cd){f=A.I(a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a8,a3,a3,a3,B.a3,a3,a3,"",a3,a3)
A.bK(f,a9)
B.a.i(a6,f)
continue}k=l instanceof A.bf
e=k?l:a3
if(k){if(e.a==="page")B.a.i(a6,A.I(a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,B.G,a3,a3,"",a3,a3))
else{d=A.I(a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,a3,"\n",a3,a3)
A.bK(d,a9)
B.a.i(a6,d)}continue}if(l instanceof A.cb){B.a.i(a6,a2.am("\u2011",t,a8,a9))
continue}k=l instanceof A.cc
c=k?l:a3
if(k){B.a.i(a6,a2.am(A.ix(c),t,a8,a9))
continue}k=l instanceof A.ca
b=k?l:a3
if(k){a=a2.c2(b,b0)
if(a!=null)B.a.i(a6,a)
continue}k=l instanceof A.bp
a0=k?l:a3
if(k){B.a.i(q,"text box (carimbo) renderizado como caixa flutuante (edi\xe7\xe3o direta fica para F4.8)")
a2.aD(o.a(a0).x,b0)
B.a.i(p,new A.bJ())
continue}k=l instanceof A.bn
a1=k?l:a3
if(k){k=a1.a
if(k==="mc:AlternateContent"||k==="w:pict")B.a.i(q,"shape preservado, sem render (Fase 4.8): "+k)}}return n},
am(a,b,c,d){var t,s,r,q,p=null,o=b.z,n=b.r,m=b.as,l=m!=null?B.ap.k(0,m):A.h_(b.at)
m=b.x===!0?a.toUpperCase():a
t=b.b
if(t==null)t=b.c
s=o==null?p:B.d.a1(o*2/3)
r=n!=null&&n!=="none"?!0:p
q=A.I(b.e,p,p,p,A.fc(b.Q),t,p,l,b.f,p,c,s,b.w,p,p,r,p,m,p,p)
A.bK(q,d)
m=b.ax
if(m==="superscript")q.b=B.o
else if(m==="subscript")q.b=B.p
return q},
c2(a,b){var t,s,r,q,p,o=this,n=null,m=a.a
if(m==null){B.a.i(o.d,"drawing sem blip embed ignorado")
return n}t=o.a
s=t.cX(m,b)
if(s==null){B.a.i(o.d,"imagem n\xe3o encontrada para rel "+m+" de "+b)
return n}r=t.cY(m,b)
if(r==null)r="image/png"
if(!a.d)B.a.i(o.d,"imagem flutuante renderizada como inline (Fase 4)")
u.B.h("Q.S").a(s)
t=B.S.gaV().ac(s)
q=a.b
q=q==null?100:q/9525
p=a.c
p=p==null?100:p/9525
q=A.I(n,n,n,n,n,n,p,n,n,n,n,n,n,n,B.F,n,n,"data:"+r+";base64,"+t,n,q)
t=u.N
A.a1(["wpDrawing",a.e],t,t)
return q},
bh(b0,b1){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8=null,a9=b0.c
if(a9.length===0)return a8
t=A.d([],u.eU)
for(s=b0.b,r=s.length,q=0;q<s.length;s.length===r||(0,A.q)(s),++q)t.push(new A.cK(s[q]/15))
p=A.d([],u.gL)
for(s=a9.length,r=u.t,q=0;q<a9.length;a9.length===s||(0,A.q)(a9),++q){o=a9[q]
n=A.d([],r)
for(m=o.b,l=m.length,k=0,j=0;j<m.length;m.length===l||(0,A.q)(m),++j){i=m[j]
B.a.i(n,k)
h=i.a
h=h==null?a8:h.b
k+=h==null?1:h}B.a.i(p,n)}g=new A.dR(p,b0)
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
a1=this.c1(i.b,b1)
l=m?a8:a0.b
if(l==null)l=1
h=(m?a8:a0.c)==="restart"?g.$2(e,a):1
a2=A.h_(m?a8:a0.e)
a3=m?a8:a0.f
$label0$3:{if("center"===a3)break $label0$3
if("bottom"===a3)break $label0$3
if("top"===a3)break $label0$3
break $label0$3}this.bZ(m?a8:a0.d)
B.a.i(b,new A.cL(l,h,a1,a2))}if(b.length===0)continue
r=B.d.bD(c,20,1/0)
B.a.i(f,new A.aO(r,b))}if(f.length===0)return a8
a4=this.b.d6(b0)
a9=new A.dS()
if(a4!=null)a5=A.N(a9.$1(a4.a))||A.N(a9.$1(a4.c))||A.N(a9.$1(a4.b))||A.N(a9.$1(a4.d))||A.N(a9.$1(a4.e))||A.N(a9.$1(a4.f))
else a5=!1
if(a5){a9=a4.e
a6=a9==null?a4.a:a9
if(a6==null)a6=a4.b
a7=A.fc(a6==null?a8:a6.c)}else a7=a8
return A.I(a8,a7,a5?B.aK:B.aL,t,a8,a8,a8,a8,a8,a8,a8,a8,a8,f,B.k,a8,a8,"",a8,a8)},
c1(a,b){var t,s,r,q,p,o,n,m,l,k,j,i,h=null
u.Q.a(a)
t=A.d([],u.F)
for(s=a.length,r=this.d,q=0;q<a.length;a.length===s||(0,A.q)(a),++q){p=a[q]
if(p instanceof A.aY){B.a.i(r,"tabela aninhada achatada em c\xe9lula (n\xe3o suportada)")
for(o=p.c,n=o.length,m=0;m<o.length;o.length===n||(0,A.q)(o),++m)for(l=o[m].b,k=l.length,j=0;j<l.length;l.length===k||(0,A.q)(l),++j)B.a.Y(t,l[j].b)}else B.a.i(t,p)}i=this.aD(t,b)
if(i.length===0)B.a.i(i,A.I(h,h,h,h,h,h,h,h,h,h,h,h,h,h,h,h,h,"",h,h))
return i},
bZ(a){var t,s
if(a==null)return null
t=new A.dQ()
s=A.d([],u.gk)
if(A.N(t.$1(a.a)))s.push(B.aP)
if(A.N(t.$1(a.d)))s.push(B.aO)
if(A.N(t.$1(a.c)))s.push(B.aM)
if(A.N(t.$1(a.b)))s.push(B.aN)
return s.length===0?null:s},
bq(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=null,d=a.d,c=a.b
if(c!=null){t=c.a
t=t!=null&&t!==0}else t=!1
if(t){t=c.a
t.toString
t=this.a.d.af(t,c.b)
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
if(n!=null&&n>0)if(m==="atLeast"||m==="exact"){if(typeof n!=="number")return n.bL()
k=n/15
l=m}else{if(typeof n!=="number")return n.bL()
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
h=(h-(f?0:o))/15}return new A.eS(l,k,j,t,i,h)}}
A.dR.prototype={
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
$S:21}
A.dS.prototype={
$1(a){var t
if(a!=null){t=a.a
t=t!=null&&t!=="none"&&t!=="nil"}else t=!1
return t},
$S:6}
A.dQ.prototype={
$1(a){var t
if(a!=null){t=a.a
t=t!=null&&t!=="none"&&t!=="nil"}else t=!1
return t},
$S:6}
A.cl.prototype={
X(){return"_FieldState."+this.b}}
A.eR.prototype={}
A.eS.prototype={}
A.ek.prototype={
$2(a,b){var t,s,r
u.a.a(b)
if(a.length===0)return
t=u.N
s=u.z
r=A.y(t,s)
r.m(0,"insert",a)
if(b.a!==0)r.m(0,"attributes",A.cX(b,t,s))
B.a.i(this.a,r)},
$S:22}
A.ej.prototype={
$1(a){var t,s,r
u.a.a(a)
t=u.N
s=u.z
r=A.y(t,s)
r.m(0,"insert","\n")
if(a.gae(a))r.m(0,"attributes",A.cX(a,t,s))
B.a.i(this.a,r)},
$S:23}
A.el.prototype={
$2(b7,b8){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3=this,b4="insert",b5="link",b6="attributes"
u.g.a(b7)
u.a.a(b8)
$label0$1:for(t=b7.length,s=b3.d,r=b3.c,q=u.N,p=u.z,o=b3.b,n=b3.a,m=u.f,l=u.S,k=0;k<b7.length;b7.length===t||(0,A.q)(b7),++k){j=b7[k]
switch(j.b){case B.j:i=A.e2(q,p)
i.Y(0,b8)
h=j.cR
if(h!=null)i.m(0,"header",A.iQ(h))
h=j.y1
b3.$2(h==null?B.q:h,i)
if(o.length===0||!J.P(B.a.gH(o).k(0,b4),"\n"))r.$1(A.fp(j,i))
continue $label0$1
case B.m:i=A.e2(q,p)
i.Y(0,b8)
i.m(0,"list","bullet")
h=j.y1
b3.$2(h==null?B.q:h,i)
if(o.length===0||!J.P(B.a.gH(o).k(0,b4),"\n"))r.$1(A.fp(j,i))
continue $label0$1
case B.n:i=A.e2(q,p)
i.Y(0,b8)
h=j.y2
if(h!=null)i.m(0,b5,h)
h=j.y1
b3.$2(h==null?B.q:h,i)
continue $label0$1
case B.F:i=A.a1(["image",j.c],q,p)
h=A.y(q,p)
g=j.w
if(g!=null)h.m(0,"width",g)
g=j.x
if(g!=null)h.m(0,"height",g)
B.a.i(o,A.a1(["insert",i,"attributes",h],q,p))
continue $label0$1
case B.k:if(o.length!==0){f=B.a.gH(o).k(0,b4)
if(typeof f!="string"||!B.b.bF(f,"\n"))r.$1(B.r)}++n.a
e=j.k1
if(e==null)e=B.al
i=j.id
h=i==null
d=h?null:i.length
if(d==null)d=B.a.cU(e,0,new A.em(),l)
for(h=!h,c=0;c<d;++c){if(h&&c<i.length){if(!(c<i.length))return A.a(i,c)
b=i[c].b}else b=72
r.$1(A.a1(["table-col",A.a1(["width",""+B.d.a1(b)],q,p)],q,p))}for(a=0;a<e.length;){a0=e[a];++a
i=""+a
a1="row-t"+n.a+"-r"+i
for(h=a0.e,g=a0.d,c=0;c<h.length;){a2=h[c];++c
a3="cell-t"+n.a+"-r"+i+"-c"+c
a4=A.y(q,p)
a4.m(0,"data-row",a1)
a5=a2.x
if(a5>1)a4.m(0,"colspan",""+a5)
a5=a2.y
if(a5>1)a4.m(0,"rowspan",""+a5)
a4.m(0,"height",""+B.d.a1(g))
a5=a2.dx
if(a5!=null)a4.m(0,"style","background-color: "+a5)
a6=A.a1(["table-cell-block",a3,"table-cell",a4],q,p)
a7=o.length
b3.$2(a2.z,a6)
if(!(o.length>a7&&J.P(B.a.gH(o).k(0,b4),"\n")&&m.b(B.a.gH(o).k(0,b6))&&A.iP(m.a(B.a.gH(o).k(0,b6)).aT(0,q,p))===a3))r.$1(a6)}}continue $label0$1
case B.a4:case B.G:r.$1(B.r)
continue $label0$1
default:break}i=A.y(q,p)
if(b8.E(b5))i.m(0,b5,b8.k(0,b5))
if(j.y===!0)i.m(0,"bold",!0)
if(j.as===!0)i.m(0,"italic",!0)
if(j.at===!0)i.m(0,"underline",!0)
if(j.ax===!0)i.m(0,"strike",!0)
h=j.z
if(h!=null)i.m(0,"color",h)
h=j.Q
if(h!=null)i.m(0,"background",h)
h=j.f
if(h!=null)i.m(0,"font",h)
h=j.r
if(h!=null){a8=B.d.a1(h*0.75*2)/2
i.m(0,"size",(a8===B.d.d7(a8)?""+B.d.a1(a8):B.d.p(a8))+"pt")}if(j.b===B.o)i.m(0,"script","super")
if(j.b===B.p)i.m(0,"script","sub")
a9=A.fp(j,b8)
b0=j.c
for(h=b0.length,b1=0,b2=0;b2<h;++b2)if(b0[b2]==="\n"){s.$2(B.b.v(b0,b1,b2),i)
r.$1(a9)
b1=b2+1}s.$2(B.b.C(b0,b1),i)}},
$S:24}
A.em.prototype={
$2(a,b){var t,s,r,q
A.aD(a)
for(t=u.eL.a(b).e,s=t.length,r=0,q=0;q<s;++q)r+=t[q].x
return r>a?r:a},
$S:25}
A.f7.prototype={
$1(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f=null,e=A.h9(u.bZ.a(a),0,f),d=new A.eo()
$.fR()
t=$.ei.$0()
d.a=t
d.b=null
t=u.s
s=new A.dO(A.d([],t)).ct(e)
t=A.d([],t)
r=A.d([],u.c3)
q=u.S
p=new A.dP(s,new A.dU(s.c),new A.e8(s.d,A.y(q,u.bS)),t,r)
o=p.bf(s.b.a,s.a.gbH(),!0)
B.a.cH(r)
n=s.x
m=n.k(0,"default")
l=s.y.k(0,"default")
if(m!=null)p.aD(m.b,m.a)
A.fl(r,!0,u.q)
r=l==null
k=r?f:p.ca(l)
if(r)j=A.d([],u.l)
else{r=l.b
i=l.a
h=k==null?f:k.f
j=p.c3(r,i,h==null?B.aI:h)}if(k!=null)p.cA(j)
if(n.a>1)B.a.i(t,"headers first/even convertidos apenas como default (sele\xe7\xe3o por tipo na Fase 4.6)")
g=A.iw(u.j.a(A.iR(A.k4(o)).k(0,"ops")))
t=$.ei.$0()
d.b=t
return B.a0.cN(A.a1(["ops",g.aw().length,"parseMs",d.gcM()],u.N,q),f)},
$S:26};(function aliases(){var t=J.as.prototype
t.bQ=t.p
t=A.al.prototype
t.bR=t.bm
t.bT=t.by
t.bS=t.bw})();(function installTearOffs(){var t=hunkHelpers._static_0,s=hunkHelpers._static_2,r=hunkHelpers._static_1,q=hunkHelpers._instance_2u,p=hunkHelpers._instance_1u,o=hunkHelpers.installStaticTearOff
t(A,"k3","iM",2)
s(A,"hX","jG",0)
r(A,"hY","jH",1)
r(A,"kc","jI",3)
r(A,"ke","kp",1)
s(A,"kd","ko",0)
var n
q(n=A.bI.prototype,"gcQ","F",0)
p(n,"gcW","G",1)
p(n,"gd2","d3",11)
o(A,"kz",0,null,["$2$abstractNums$nums","$0"],["hp",function(){return A.hp(null,null)}],27,0)
r(A,"kA","iZ",28)
o(A,"kG",0,null,["$3$byId$docDefaultsParagraph$docDefaultsRun","$0"],["hr",function(){return A.hr(null,null,null)}],29,0)
r(A,"kH","j2",30)})();(function inheritance(){var t=hunkHelpers.mixin,s=hunkHelpers.inherit,r=hunkHelpers.inheritMany
s(A.o,null)
r(A.o,[A.fi,J.cP,J.bC,A.e,A.bF,A.j,A.ar,A.t,A.en,A.aQ,A.aS,A.c7,A.U,A.aL,A.am,A.bG,A.aZ,A.a4,A.eq,A.e7,A.e1,A.bT,A.cS,A.dA,A.ci,A.eW,A.Y,A.dy,A.eU,A.m,A.cn,A.dz,A.cq,A.a2,A.cG,A.Q,A.eJ,A.eP,A.eX,A.eM,A.d0,A.c0,A.a_,A.ah,A.bX,A.eo,A.z,A.aK,A.b5,A.at,A.W,A.br,A.ba,A.bI,A.cH,A.S,A.dU,A.eC,A.ew,A.dk,A.eB,A.c8,A.eu,A.aW,A.ex,A.aU,A.K,A.ax,A.aw,A.eG,A.eE,A.eF,A.eD,A.dl,A.dm,A.bh,A.ez,A.ev,A.dg,A.dj,A.dh,A.be,A.bk,A.ay,A.e8,A.dN,A.dO,A.aX,A.az,A.dK,A.eb,A.d7,A.d8,A.ak,A.aA,A.dp,A.dr,A.aB,A.ds,A.dV,A.dW,A.cO,A.d2,A.dt,A.eI,A.aN,A.cK,A.cL,A.aO,A.bJ,A.dP,A.eR,A.eS])
r(J.cP,[J.cQ,J.bO,J.bQ,J.b7,J.b9,J.bP,J.b6])
r(J.bQ,[J.as,J.h,A.au,A.bV])
r(J.as,[J.d3,J.c4,J.af])
s(J.dX,J.h)
r(J.bP,[J.bN,J.cR])
r(A.e,[A.bq,A.n,A.aR,A.c6,A.T,A.cp,A.du,A.b0])
s(A.aH,A.bq)
s(A.ck,A.aH)
r(A.j,[A.aI,A.ag,A.al])
r(A.ar,[A.cE,A.cD,A.dc,A.dZ,A.f3,A.f5,A.eK,A.e5,A.dL,A.dM,A.ed,A.ey,A.eA,A.ec,A.eL,A.dS,A.dQ,A.ej,A.f7])
r(A.cE,[A.dI,A.dJ,A.dY,A.f4,A.e3,A.e6,A.eQ,A.ea,A.dR,A.ek,A.el,A.em])
r(A.t,[A.bS,A.c2,A.cT,A.de,A.dw,A.d9,A.bD,A.dx,A.bR,A.ac,A.c5,A.dd,A.c1,A.cF])
r(A.n,[A.J,A.aP,A.cm])
s(A.bL,A.aR)
r(A.J,[A.a3,A.c_])
r(A.am,[A.bs,A.bt])
s(A.D,A.bs)
s(A.bu,A.bt)
s(A.aJ,A.bG)
r(A.a4,[A.bH,A.ct])
s(A.ae,A.bH)
r(A.cD,[A.ef,A.eZ,A.eY,A.e9])
s(A.bY,A.c2)
r(A.dc,[A.da,A.b4])
s(A.dv,A.bD)
s(A.a7,A.bV)
s(A.cr,A.a7)
s(A.cs,A.cr)
s(A.bU,A.cs)
r(A.bU,[A.cY,A.cZ,A.bW])
s(A.cu,A.dx)
r(A.al,[A.co,A.cj])
s(A.b_,A.ct)
r(A.cG,[A.eV,A.dG,A.e_,A.et])
r(A.Q,[A.bE,A.cI,A.cU])
s(A.cV,A.bR)
s(A.eO,A.eP)
r(A.cI,[A.cW,A.df])
s(A.e0,A.eV)
r(A.ac,[A.bZ,A.cM])
s(A.bc,A.W)
r(A.K,[A.aa,A.cd,A.bf,A.cb,A.cc,A.ca,A.bg,A.bj,A.bn,A.bp])
r(A.ax,[A.aV,A.bi,A.bo,A.bm])
r(A.aw,[A.a9,A.aY,A.bl])
r(A.ak,[A.ch,A.ce,A.dn,A.dq,A.V])
s(A.ab,A.dr)
s(A.eH,A.a_)
r(A.eM,[A.dH,A.R,A.bb,A.db,A.aT,A.av,A.cl])
s(A.cN,A.cO)
s(A.d1,A.d2)
t(A.cr,A.a2)
t(A.cs,A.aL)})()
var v={typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{c:"int",cz:"double",bz:"num",f:"String",A:"bool",bX:"Null",r:"List",o:"Object",l:"Map"},mangledNames:{},types:["A(o?,o?)","c(o?)","c()","@(@)","~(o?,o?)","@()","A(c8?)","@(@,f)","@(f)","A(@)","~(@,@)","A(o?)","S(@)","l<f,@>(S)","c(ah<f,@>)","f(aa)","r<bh>(f)","l<c,c>()","A(c,c)","A(f)","aA(aB)","c(c,c)","~(f,l<f,@>)","~(l<f,@>)","~(r<aN>,l<f,@>)","c(c,aO)","f(au)","ay({abstractNums:l<c,be>?,nums:l<c,bk>?})","ay(f)","az({byId:l<f,aX>?,docDefaultsParagraph:aU?,docDefaultsRun:aW?})","az(f)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;":(a,b)=>c=>c instanceof A.D&&a.b(c.a)&&b.b(c.b),"3;":(a,b,c)=>d=>d instanceof A.bu&&a.b(d.a)&&b.b(d.b)&&c.b(d.c)}}
A.jv(v.typeUniverse,JSON.parse('{"d3":"as","c4":"as","af":"as","cQ":{"A":[],"C":[]},"bO":{"C":[]},"bQ":{"a0":[]},"as":{"a0":[]},"h":{"r":["1"],"n":["1"],"a0":[],"e":["1"]},"dX":{"h":["1"],"r":["1"],"n":["1"],"a0":[],"e":["1"]},"bC":{"w":["1"]},"bP":{"cz":[],"bz":[]},"bN":{"cz":[],"c":[],"bz":[],"C":[]},"cR":{"cz":[],"bz":[],"C":[]},"b6":{"f":[],"ee":[],"C":[]},"bq":{"e":["2"]},"bF":{"w":["2"]},"aH":{"bq":["1","2"],"e":["2"],"e.E":"2"},"ck":{"aH":["1","2"],"bq":["1","2"],"n":["2"],"e":["2"],"e.E":"2"},"aI":{"j":["3","4"],"l":["3","4"],"j.K":"3","j.V":"4"},"bS":{"t":[]},"n":{"e":["1"]},"J":{"n":["1"],"e":["1"]},"aQ":{"w":["1"]},"aR":{"e":["2"],"e.E":"2"},"bL":{"aR":["1","2"],"n":["2"],"e":["2"],"e.E":"2"},"aS":{"w":["2"]},"a3":{"J":["2"],"n":["2"],"e":["2"],"J.E":"2","e.E":"2"},"c6":{"e":["1"],"e.E":"1"},"c7":{"w":["1"]},"T":{"e":["1"],"e.E":"1"},"U":{"w":["1"]},"c_":{"J":["1"],"n":["1"],"e":["1"],"J.E":"1","e.E":"1"},"D":{"bs":[],"am":[]},"bu":{"bt":[],"am":[]},"bG":{"l":["1","2"]},"aJ":{"bG":["1","2"],"l":["1","2"]},"cp":{"e":["1"],"e.E":"1"},"aZ":{"w":["1"]},"bH":{"a4":["1"],"a8":["1"],"n":["1"],"e":["1"]},"ae":{"bH":["1"],"a4":["1"],"a8":["1"],"n":["1"],"e":["1"]},"bY":{"t":[]},"cT":{"t":[]},"de":{"t":[]},"ar":{"aM":[]},"cD":{"aM":[]},"cE":{"aM":[]},"dc":{"aM":[]},"da":{"aM":[]},"b4":{"aM":[]},"dw":{"t":[]},"d9":{"t":[]},"dv":{"t":[]},"ag":{"j":["1","2"],"h6":["1","2"],"l":["1","2"],"j.K":"1","j.V":"2"},"aP":{"n":["1"],"e":["1"],"e.E":"1"},"bT":{"w":["1"]},"bs":{"am":[]},"bt":{"am":[]},"cS":{"iU":[],"ee":[]},"dA":{"d6":[]},"du":{"e":["d6"],"e.E":"d6"},"ci":{"w":["d6"]},"au":{"a0":[],"C":[]},"bV":{"a0":[]},"a7":{"b8":["1"],"a0":[]},"bU":{"a2":["c"],"a7":["c"],"r":["c"],"b8":["c"],"n":["c"],"a0":[],"e":["c"],"aL":["c"]},"cY":{"a2":["c"],"a7":["c"],"r":["c"],"b8":["c"],"n":["c"],"a0":[],"e":["c"],"aL":["c"],"C":[],"a2.E":"c"},"cZ":{"ft":[],"a2":["c"],"a7":["c"],"r":["c"],"b8":["c"],"n":["c"],"a0":[],"e":["c"],"aL":["c"],"C":[],"a2.E":"c"},"bW":{"es":[],"a2":["c"],"a7":["c"],"r":["c"],"b8":["c"],"n":["c"],"a0":[],"e":["c"],"aL":["c"],"C":[],"a2.E":"c"},"dx":{"t":[]},"cu":{"t":[]},"m":{"w":["1"]},"b0":{"e":["1"],"e.E":"1"},"al":{"j":["1","2"],"l":["1","2"],"j.K":"1","j.V":"2"},"co":{"al":["1","2"],"j":["1","2"],"l":["1","2"],"j.K":"1","j.V":"2"},"cj":{"al":["1","2"],"j":["1","2"],"l":["1","2"],"j.K":"1","j.V":"2"},"cm":{"n":["1"],"e":["1"],"e.E":"1"},"cn":{"w":["1"]},"b_":{"a4":["1"],"h7":["1"],"a8":["1"],"n":["1"],"e":["1"]},"cq":{"w":["1"]},"j":{"l":["1","2"]},"a4":{"a8":["1"],"n":["1"],"e":["1"]},"ct":{"a4":["1"],"a8":["1"],"n":["1"],"e":["1"]},"bE":{"Q":["r<c>","f"],"Q.S":"r<c>"},"cI":{"Q":["f","r<c>"]},"bR":{"t":[]},"cV":{"t":[]},"cU":{"Q":["o?","f"],"Q.S":"o?"},"cW":{"Q":["f","r<c>"],"Q.S":"f"},"df":{"Q":["f","r<c>"],"Q.S":"f"},"cz":{"bz":[]},"c":{"bz":[]},"r":{"n":["1"],"e":["1"]},"a8":{"n":["1"],"e":["1"]},"f":{"ee":[]},"bD":{"t":[]},"c2":{"t":[]},"ac":{"t":[]},"bZ":{"t":[]},"cM":{"t":[]},"c5":{"t":[]},"dd":{"t":[]},"c1":{"t":[]},"cF":{"t":[]},"d0":{"t":[]},"c0":{"t":[]},"z":{"iX":[]},"aK":{"Z":["1"]},"b5":{"Z":["e<1>"]},"at":{"Z":["r<1>"]},"W":{"Z":["2"]},"bc":{"W":["1","a8<1>"],"Z":["a8<1>"],"W.E":"1","W.T":"a8<1>"},"ba":{"Z":["l<1,2>"]},"bI":{"Z":["@"]},"aa":{"K":[]},"aV":{"ax":[]},"a9":{"aw":[]},"cd":{"K":[]},"bf":{"K":[]},"cb":{"K":[]},"cc":{"K":[]},"ca":{"K":[]},"bg":{"K":[]},"bj":{"K":[]},"bn":{"K":[]},"bp":{"K":[]},"bi":{"ax":[]},"bo":{"ax":[]},"bm":{"ax":[]},"aY":{"aw":[]},"bl":{"aw":[]},"V":{"ak":[]},"ch":{"ak":[]},"ce":{"ak":[]},"dn":{"ak":[]},"dq":{"ak":[]},"ab":{"dr":[]},"cN":{"cO":[]},"d1":{"d2":[]},"iz":{"r":["c"],"n":["c"],"e":["c"]},"es":{"r":["c"],"n":["c"],"e":["c"]},"ft":{"r":["c"],"n":["c"],"e":["c"]}}'))
A.ju(v.typeUniverse,JSON.parse('{"a7":1,"ct":1,"cG":2}'))
var u=(function rtii(){var t=A.aF
return{B:t("bE"),M:t("ae<f>"),q:t("bJ"),r:t("n<@>"),x:t("t"),Z:t("aM"),eL:t("aO"),c:t("b5<@>"),R:t("e<@>"),hb:t("e<c>"),c3:t("h<bJ>"),eU:t("h<cK>"),l:t("h<aN>"),an:t("h<cL>"),h:t("h<aO>"),gL:t("h<r<c>>"),c7:t("h<l<f,@>>"),G:t("h<o>"),gb:t("h<d7>"),s:t("h<f>"),gk:t("h<aT>"),F:t("h<aw>"),f_:t("h<bh>"),fL:t("h<ax>"),f0:t("h<aV>"),E:t("h<K>"),d5:t("h<aX>"),fH:t("h<dk>"),cz:t("h<dl>"),cB:t("h<dm>"),av:t("h<aA>"),v:t("h<V>"),m:t("h<ak>"),u:t("h<aB>"),bV:t("h<dt>"),b:t("h<@>"),t:t("h<c>"),T:t("bO"),eH:t("a0"),V:t("af"),p:t("b8<@>"),I:t("at<@>"),g:t("r<aN>"),Q:t("r<aw>"),fb:t("r<aB>"),j:t("r<@>"),L:t("r<c>"),e1:t("ah<f,@>"),J:t("ba<@,@>"),a:t("l<f,@>"),f:t("l<@,@>"),bS:t("l<c,c>"),bZ:t("au"),P:t("bX"),K:t("o"),W:t("S"),gT:t("kN"),bQ:t("+()"),d:t("d6"),at:t("d8"),bJ:t("c_<f>"),D:t("bc<@>"),cq:t("a8<f>"),aI:t("a8<a9>"),N:t("f"),dm:t("C"),gc:t("es"),ak:t("c4"),cc:t("c6<f>"),ap:t("T<aa>"),C:t("T<V>"),y:t("U<V>"),e:t("be"),cf:t("dg"),n:t("bk"),eS:t("ay"),aV:t("dh"),eO:t("a9"),U:t("aX"),fw:t("az"),dH:t("aa"),cH:t("bp"),X:t("V"),fN:t("aB"),gA:t("br"),Y:t("b0<V>"),w:t("A"),bB:t("A(f)"),i:t("cz"),z:t("@"),S:t("c"),A:t("0&*"),_:t("o*"),bG:t("h0<bX>?"),k:t("l<@,@>?"),O:t("o?"),o:t("dz?"),H:t("bz")}})();(function constants(){var t=hunkHelpers.makeConstList
B.ac=J.cP.prototype
B.a=J.h.prototype
B.c=J.bN.prototype
B.d=J.bP.prototype
B.b=J.b6.prototype
B.ad=J.af.prototype
B.ae=J.bQ.prototype
B.e=A.bW.prototype
B.K=J.d3.prototype
B.y=J.c4.prototype
B.z=new A.dH("littleEndian")
B.T=new A.dG()
B.S=new A.bE()
B.aY=new A.aK(A.aF("aK<0&>"))
B.A=new A.bI()
B.B=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.V=function() {
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
B.a_=function(getTagFallback) {
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
B.W=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.Z=function(hooks) {
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
B.Y=function(hooks) {
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
B.X=function(hooks) {
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
B.C=function(hooks) { return hooks; }

B.a0=new A.cU()
B.D=new A.cW()
B.a1=new A.d0()
B.f=new A.en()
B.E=new A.df()
B.a2=new A.dj()
B.l=new A.R("text")
B.F=new A.R("image")
B.a3=new A.R("tab")
B.j=new A.R("title")
B.m=new A.R("list")
B.k=new A.R("table")
B.n=new A.R("hyperlink")
B.o=new A.R("superscript")
B.p=new A.R("subscript")
B.a4=new A.R("separator")
B.G=new A.R("pageBreak")
B.a5=new A.a_("Pacote OPC inv\xe1lido: [Content_Types].xml ausente.",null,null)
B.a6=new A.a_("Invalid ZIP archive: end of central directory not found.",null,null)
B.a7=new A.a_("Invalid ZIP archive: unexpected central directory header.",null,null)
B.a8=new A.a_("Invalid ZIP archive: local file header not found.",null,null)
B.a9=new A.a_("document.xml com <w:body> em formato n\xe3o suportado.",null,null)
B.aa=new A.a_("Pacote OPC sem relacionamento officeDocument.",null,null)
B.ab=new A.a_("document.xml sem <w:body>.",null,null)
B.af=new A.e_(null)
B.ag=new A.e0(!1)
B.U=new A.aK(A.aF("aK<S>"))
B.ah=new A.at(B.U,A.aF("at<S>"))
B.at=new A.D(1000,"M")
B.aD=new A.D(900,"CM")
B.aA=new A.D(500,"D")
B.ax=new A.D(400,"CD")
B.au=new A.D(100,"C")
B.aE=new A.D(90,"XC")
B.aB=new A.D(50,"L")
B.ay=new A.D(40,"XL")
B.av=new A.D(10,"X")
B.aF=new A.D(9,"IX")
B.aC=new A.D(5,"V")
B.az=new A.D(4,"IV")
B.aw=new A.D(1,"I")
B.ai=A.d(t([B.at,B.aD,B.aA,B.ax,B.au,B.aE,B.aB,B.ay,B.av,B.aF,B.aC,B.az,B.aw]),A.aF("h<+(c,f)>"))
B.aj=A.d(t([0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0,0,0]),u.t)
B.ak=A.d(t([16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15]),u.t)
B.H=A.d(t([1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577]),u.t)
B.q=A.d(t([]),u.l)
B.al=A.d(t([]),u.h)
B.I=A.d(t([]),u.u)
B.an=A.d(t([0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13]),u.t)
B.am=A.d(t([5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5]),u.t)
B.J=A.d(t([3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258]),u.t)
B.ao=A.d(t([8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8]),u.t)
B.t={}
B.r=new A.aJ(B.t,[],A.aF("aJ<f,@>"))
B.ar={yellow:0,green:1,cyan:2,magenta:3,blue:4,red:5,darkBlue:6,darkCyan:7,darkGreen:8,darkMagenta:9,darkRed:10,darkYellow:11,darkGray:12,lightGray:13,black:14,white:15}
B.ap=new A.aJ(B.ar,["#FFFF00","#00FF00","#00FFFF","#FF00FF","#0000FF","#FF0000","#00008B","#008B8B","#006400","#8B008B","#8B0000","#808000","#A9A9A9","#D3D3D3","#000000","#FFFFFF"],A.aF("aJ<f,f>"))
B.u=new A.bb("center")
B.v=new A.bb("right")
B.w=new A.bb("alignment")
B.x=new A.bb("justify")
B.as={"w:sectPr":0}
B.aG=new A.ae(B.as,1,u.M)
B.aq={"w:tcPr":0}
B.aH=new A.ae(B.aq,1,u.M)
B.aJ=new A.ae(B.t,0,u.M)
B.aI=new A.ae(B.t,0,A.aF("ae<a9>"))
B.aK=new A.db("all")
B.aL=new A.db("empty")
B.aM=new A.aT("bottom")
B.aN=new A.aT("left")
B.aO=new A.aT("right")
B.aP=new A.aT("top")
B.L=new A.av("fifth")
B.M=new A.av("first")
B.N=new A.av("fourth")
B.O=new A.av("second")
B.P=new A.av("sixth")
B.Q=new A.av("third")
B.aQ=A.dD("kL")
B.aR=A.dD("iz")
B.aS=A.dD("o")
B.aT=A.dD("ft")
B.aU=A.dD("es")
B.aV=new A.et(!1)
B.aW=new A.aU(null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
B.aX=new A.aW(null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
B.h=new A.cl("none")
B.i=new A.cl("instruction")
B.R=new A.cl("result")})();(function staticFields(){$.eN=null
$.X=A.d([],u.G)
$.hb=null
$.eh=0
$.ei=A.k3()
$.fW=null
$.fV=null
$.i0=null
$.hU=null
$.i3=null
$.f1=null
$.f6=null
$.fL=null
$.eT=A.d([],A.aF("h<r<o>?>"))})();(function lazyInitializers(){var t=hunkHelpers.lazyFinal
t($,"kM","fQ",()=>A.kl("_$dart_dartClosure"))
t($,"kP","i6",()=>A.aj(A.er({
toString:function(){return"$receiver$"}})))
t($,"kQ","i7",()=>A.aj(A.er({$method$:null,
toString:function(){return"$receiver$"}})))
t($,"kR","i8",()=>A.aj(A.er(null)))
t($,"kS","i9",()=>A.aj(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"kV","ic",()=>A.aj(A.er(void 0)))
t($,"kW","id",()=>A.aj(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"kU","ib",()=>A.aj(A.hk(null)))
t($,"kT","ia",()=>A.aj(function(){try{null.$method$}catch(s){return s.message}}()))
t($,"kY","ig",()=>A.aj(A.hk(void 0)))
t($,"kX","ie",()=>A.aj(function(){try{(void 0).$method$}catch(s){return s.message}}()))
t($,"l0","ij",()=>A.iI(4096))
t($,"kZ","ih",()=>new A.eZ().$0())
t($,"l_","ii",()=>new A.eY().$0())
t($,"lb","dE",()=>A.f9(B.aS))
t($,"kO","fR",()=>{A.iN()
return $.eh})})();(function nativeSupport(){!function(){var t=function(a){var n={}
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
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.au,ArrayBufferView:A.bV,Int8Array:A.cY,Uint32Array:A.cZ,Uint8Array:A.bW})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,ArrayBufferView:false,Int8Array:true,Uint32Array:true,Uint8Array:false})
A.a7.$nativeSuperclassTag="ArrayBufferView"
A.cr.$nativeSuperclassTag="ArrayBufferView"
A.cs.$nativeSuperclassTag="ArrayBufferView"
A.bU.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$0=function(){return this()}
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$1$1=function(a){return this(a)}
Function.prototype.$2$0=function(){return this()}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var t=document.scripts
function onLoad(b){for(var r=0;r<t.length;++r){t[r].removeEventListener("load",onLoad,false)}a(b.target)}for(var s=0;s<t.length;++s){t[s].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var t=A.kx
if(typeof dartMainRunner==="function"){dartMainRunner(t,[])}else{t([])}})})()
//# sourceMappingURL=bench_parse.js.map
