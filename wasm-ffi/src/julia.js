import Struct from './Struct';
import { types, parseType, Pointer, CustomType } from './types';
import { encode, decode } from './encoding';
import { assert, vslice, isNil, addStringFns, addArrayFns, makeIterable } from './misc';

// get the symbol for struct-data since we need access here
const DATA = (typeof Symbol !== 'undefined')
  ? Symbol.for('struct-data')
  : '__data';

const isJulia32 = DATA.isJulia32;

const JLInt = isJulia32 ? 'int32' : 'int64';

const NOTHING = new CustomType(0);

function jlintvalue(x) {
  return isJulia32 ? x : new Int32Array([x, 0]);
}

function jlpointer(type) {
  return isJulia32 ? types.pointer(type) : types.pointer64(type);
}

function MallocArray(typedef, ndims = 1, initialValues, dims) {
  const type = parseType(typedef);

  const Base = new Struct({
    ptr: jlpointer(type),
    length: 'uint32',
    dummy1: isJulia32 ? NOTHING : 'uint32', 
    size: ['uint32', isJulia32 ? ndims : 2 * ndims],
    /* values */
  });

  Object.defineProperty(Base.prototype, 'values', {
    enumerable: true,

    get() {
      const memory = this[DATA].view.buffer;
      const wrapper = this[DATA].wrapper;

      const arrayType = parseType([type, this.length]);
      const view = new DataView(memory, this.ptr.ref(), arrayType.width);

      return arrayType.read(view, wrapper);
    },

    set(values) {
      this.ptr = new Pointer([type, values.length], values);
      this.length = values.length;
      this.size = isJulia32 ? [values.length] : [values.length, 0];
    },
  });

  addArrayFns(Base);
  makeIterable(Base);

  class MArray extends Base {
    constructor(values) {
      super();
      if (values) {
        this.values = values;
        var sz = [];
        if (!dims) dims = [values.length];
        for (let i = 0; i < ndims; i++) {
          sz.push(dims[i]);
          if (!isJulia32) sz.push(0);
        }
        this.size = sz;
      }
    }

    free() {
      super.free(true); // free ptr data
    }
  }

  return (initialValues)
    ? new MArray(initialValues)
    : MArray;
}

function Array(typedef, ndims = 1, initialValues, dims) {
  const type = parseType(typedef);

  const Base = new Struct({
    ptr: jlpointer(type),
    length: 'uint32',
    dummy: isJulia32 ? NOTHING : 'uint32',
    flags:  'uint16',
    elsize: 'uint16',
    offset: 'uint32',
    size: ['uint32', isJulia32 ? ndims : 2 * ndims],
    /* values */
  });

  Object.defineProperty(Base.prototype, 'values', {
    enumerable: true,

    get() {
      const memory = this[DATA].view.buffer;
      const wrapper = this[DATA].wrapper;

      const arrayType = parseType([type, this.length]);
      const view = new DataView(memory, this.ptr.ref(), arrayType.width);

      return arrayType.read(view, wrapper);
    },

    set(values) {
      this.ptr = new Pointer([type, values.length], values);
      this.length = values.length;
      this.flags = ndims * 4;
      this.elsize = type.width;
      this.offset = 0;
    },
  });

  addArrayFns(Base);
  makeIterable(Base);

  class Array extends Base {
    constructor(values) {
      super();
      if (values) {
        this.values = values;
        var sz = [];
        if (!dims) dims = [values.length];
        for (let i = 0; i < ndims; i++) {
          sz.push(dims[i]);
          if (!isJulia32) sz.push(0);
        }
        this.size = sz;
      }
    }

    free() {
      super.free(true); // free ptr data
    }
  }

  return (initialValues)
    ? new Array(initialValues)
    : Array;
}

function JuliaTuple(tupleTypes, values) {
  // This is copied from Rust's
  const fields = {};

  tupleTypes.forEach((type, i) => {
    fields[i] = parseType(type);
  });

  const Tuple = new Struct(fields);

  return (values)
    ? new Tuple(values)
    : Tuple;
}

const julia = {
  MallocArray:  MallocArray,
  Array:        Array,
  Tuple:        JuliaTuple,
  Int:          JLInt,
  pointer:      jlpointer,
};


export default julia;
