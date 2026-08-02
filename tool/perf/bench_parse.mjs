// Returns whether the `js-string` built-in is supported.
function detectJsStringBuiltins() {
  let bytes = [
    0,   97,  115, 109, 1,   0,   0,  0,   1,   4,   1,   96,  0,
    0,   2,   23,  1,   14,  119, 97, 115, 109, 58,  106, 115, 45,
    115, 116, 114, 105, 110, 103, 4,  99,  97,  115, 116, 0,   0
  ];
  return WebAssembly.validate(
    new Uint8Array(bytes), {builtins: ['js-string']});
}

// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = detectJsStringBuiltins()
      ? {builtins: ['js-string']} : {};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = detectJsStringBuiltins()
      ? {builtins: ['js-string']} : {};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  async instantiate(additionalImports, {loadDeferredWasm} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + js;
    }

    // Converts a Dart List to a JS array. Any Dart objects will be converted, but
    // this will be cheap for JSValues.
    function arrayFromDartList(constructor, list) {
      const exports = dartInstance.exports;
      const read = exports.$listRead;
      const length = exports.$listLength(list);
      const array = new constructor(length);
      for (let i = 0; i < length; i++) {
        array[i] = read(list, i);
      }
      return array;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {

      _13: x0 => x0.length,
      _15: (x0,x1) => x0[x1],
      _19: (x0,x1,x2) => new DataView(x0,x1,x2),
      _22: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _23: x0 => new Uint8Array(x0),
      _33: x0 => new Uint32Array(x0),
      _70: (decoder, codeUnits) => decoder.decode(codeUnits),
      _71: () => new TextDecoder("utf-8", {fatal: true}),
      _72: () => new TextDecoder("utf-8", {fatal: false}),
      _83: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _84: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _85: () => typeof dartUseDateNowForTicks !== "undefined",
      _86: () => 1000 * performance.now(),
      _87: () => Date.now(),
      _103: s => JSON.stringify(s),
      _104: s => printToConsole(s),
      _105: a => a.join(''),
      _106: (o, a, b) => o.replace(a, b),
      _107: (o, p, r) => o.split(p).join(r),
      _108: (s, t) => s.split(t),
      _109: s => s.toLowerCase(),
      _110: s => s.toUpperCase(),
      _111: s => s.trim(),
      _115: (s, p, i) => s.indexOf(p, i),
      _116: (s, p, i) => s.lastIndexOf(p, i),
      _117: (s) => s.replace(/\$/g, "$$$$"),
      _118: Object.is,
      _119: s => s.toUpperCase(),
      _120: s => s.toLowerCase(),
      _121: (a, i) => a.push(i),
      _132: a => a.length,
      _134: (a, i) => a[i],
      _135: (a, i, v) => a[i] = v,
      _138: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _139: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _140: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _141: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _142: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _143: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _144: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _147: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _148: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _151: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _153: o => o.buffer,
      _154: o => o.byteOffset,
      _155: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _156: (b, o) => new DataView(b, o),
      _157: (b, o, l) => new DataView(b, o, l),
      _158: Function.prototype.call.bind(DataView.prototype.getUint8),
      _160: Function.prototype.call.bind(DataView.prototype.getInt8),
      _162: Function.prototype.call.bind(DataView.prototype.getUint16),
      _164: Function.prototype.call.bind(DataView.prototype.getInt16),
      _166: Function.prototype.call.bind(DataView.prototype.getUint32),
      _168: Function.prototype.call.bind(DataView.prototype.getInt32),
      _174: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _176: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _199: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _201: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._201(f,arguments.length,x0) }),
      _202: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _204: (x0,x1) => x0.test(x1),
      _205: (x0,x1) => x0.exec(x1),
      _209: o => o === undefined,
      _228: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _231: o => o instanceof RegExp,
      _232: (l, r) => l === r,
      _233: o => o,
      _234: o => o,
      _235: o => o,
      _236: b => !!b,
      _237: o => o.length,
      _240: (o, i) => o[i],
      _241: f => f.dartFunction,
      _242: l => arrayFromDartList(Int8Array, l),
      _243: l => arrayFromDartList(Uint8Array, l),
      _244: l => arrayFromDartList(Uint8ClampedArray, l),
      _245: l => arrayFromDartList(Int16Array, l),
      _246: l => arrayFromDartList(Uint16Array, l),
      _247: l => arrayFromDartList(Int32Array, l),
      _248: l => arrayFromDartList(Uint32Array, l),
      _249: l => arrayFromDartList(Float32Array, l),
      _250: l => arrayFromDartList(Float64Array, l),
      _251: x0 => new ArrayBuffer(x0),
      _252: (data, length) => {
        const getValue = dartInstance.exports.$byteDataGetUint8;
        const view = new DataView(new ArrayBuffer(length));
        for (let i = 0; i < length; i++) {
          view.setUint8(i, getValue(data, i));
        }
        return view;
      },
      _253: l => arrayFromDartList(Array, l),
      _254: (s, length) => {
        if (length == 0) return '';
      
        const read = dartInstance.exports.$stringRead1;
        let result = '';
        let index = 0;
        const chunkLength = Math.min(length - index, 500);
        let array = new Array(chunkLength);
        while (index < length) {
          const newChunkLength = Math.min(length - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(s, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      _255: (s, length) => {
        if (length == 0) return '';
      
        const read = dartInstance.exports.$stringRead2;
        let result = '';
        let index = 0;
        const chunkLength = Math.min(length - index, 500);
        let array = new Array(chunkLength);
        while (index < length) {
          const newChunkLength = Math.min(length - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(s, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      _256: (s) => {
        let length = s.length;
        let range = 0;
        for (let i = 0; i < length; i++) {
          range |= s.codePointAt(i);
        }
        const exports = dartInstance.exports;
        if (range < 256) {
          if (length <= 10) {
            if (length == 1) {
              return exports.$stringAllocate1_1(s.codePointAt(0));
            }
            if (length == 2) {
              return exports.$stringAllocate1_2(s.codePointAt(0), s.codePointAt(1));
            }
            if (length == 3) {
              return exports.$stringAllocate1_3(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2));
            }
            if (length == 4) {
              return exports.$stringAllocate1_4(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3));
            }
            if (length == 5) {
              return exports.$stringAllocate1_5(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4));
            }
            if (length == 6) {
              return exports.$stringAllocate1_6(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5));
            }
            if (length == 7) {
              return exports.$stringAllocate1_7(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6));
            }
            if (length == 8) {
              return exports.$stringAllocate1_8(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7));
            }
            if (length == 9) {
              return exports.$stringAllocate1_9(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7), s.codePointAt(8));
            }
            if (length == 10) {
              return exports.$stringAllocate1_10(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7), s.codePointAt(8), s.codePointAt(9));
            }
          }
          const dartString = exports.$stringAllocate1(length);
          const write = exports.$stringWrite1;
          for (let i = 0; i < length; i++) {
            write(dartString, i, s.codePointAt(i));
          }
          return dartString;
        } else {
          const dartString = exports.$stringAllocate2(length);
          const write = exports.$stringWrite2;
          for (let i = 0; i < length; i++) {
            write(dartString, i, s.charCodeAt(i));
          }
          return dartString;
        }
      },
      _259: l => new Array(l),
      _260: () => globalThis,
      _263: (o, p) => o[p],
      _267: o => String(o),
      _269: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        return 17;
      },
      _270: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _271: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _274: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _283: x0 => x0.index,
      _289: x0 => x0.flags,
      _290: x0 => x0.multiline,
      _291: x0 => x0.ignoreCase,
      _292: x0 => x0.unicode,
      _293: x0 => x0.dotAll,
      _294: (x0,x1) => x0.lastIndex = x1,
      _297: (o, p, v) => o[p] = v,
      _299: v => v.toString(),
      _304: x0 => x0.random(),
      _305: x0 => x0.random(),
      _309: () => globalThis.Math,

    };

    const baseImports = {
      dart2wasm: dart2wasm,


      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
    };

    const deferredLibraryHelper = {
      "loadModule": async (moduleName) => {
        if (!loadDeferredWasm) {
          throw "No implementation of loadDeferredWasm provided.";
        }
        const source = await Promise.resolve(loadDeferredWasm(moduleName));
        const module = await ((source instanceof Response)
            ? WebAssembly.compileStreaming(source, this.builtins)
            : WebAssembly.compile(source, this.builtins));
        return await WebAssembly.instantiate(module, {
          ...baseImports,
          ...additionalImports,
          "wasm:js-string": jsStringPolyfill,
          "module0": dartInstance.exports,
        });
      },
    };

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      "deferredLibraryHelper": deferredLibraryHelper,
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}

