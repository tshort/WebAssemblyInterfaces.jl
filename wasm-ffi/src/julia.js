import Struct from './Struct';
import { types, parseType, Pointer, CustomType } from './types';
import { encode, decode } from './encoding';
import { assert, vslice, isNil, addStringFns, addArrayFns, makeIterable } from './misc';

// get the symbol for struct-data since we need access here
const DATA = (typeof Symbol !== 'undefined')
  ? Symbol.for('struct-data')
  : '__data';


const NOTHING = new CustomType(0);

function JuliaStruct32(fields = {}, opt = {}) {
  return new Struct(fields, {alignment:4});
}

function JuliaStruct64(fields = {}, opt = {}) {
  return new Struct(fields, {alignment:8});
}

function MallocArray32(typedef, ndims = 1, initialValues, dims) {
  const type = parseType(typedef);

  const Base = JuliaStruct32({
    ptr: types.pointer(type),
    length: 'uint32',
    size: ['uint32', ndims],
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
      this.size = [values.length];
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

function MallocArray64(typedef, ndims = 1, initialValues, dims) {
  const type = parseType(typedef);

  const Base = JuliaStruct64({
    ptr: types.pointer64(type),
    length: 'uint32',
    dummy1: 'uint32', 
    size: ['uint32', 2 * ndims],
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
      this.size = [values.length, 0];
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
          sz.push(0);
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

function Array32(typedef, ndims = 1, initialValues, dims) {
  const type = parseType(typedef);

  const Base = JuliaStruct32({
    ptr: types.pointer(type),
    length: 'uint32',
    flags:  'uint16',
    elsize: 'uint16',
    offset: 'uint32',
    size: ['uint32', ndims],
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

function Array64(typedef, ndims = 1, initialValues, dims) {
  const type = parseType(typedef);

  const Base = JuliaStruct64({
    ptr: types.pointer64(type),
    length: 'uint32',
    dummy: 'uint32',
    flags:  'uint16',
    elsize: 'uint16',
    offset: 'uint32',
    size: ['uint32', 2 * ndims],
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
          sz.push(0);
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


function JuliaTuple32(tupleTypes, values) {
  // This is copied from Rust's
  const fields = {};

  tupleTypes.forEach((type, i) => {
    fields[i] = parseType(type);
  });

  const Tuple = JuliaStruct32(fields);

  return (values)
    ? new Tuple(values)
    : Tuple;
}

function JuliaTuple64(tupleTypes, values) {
  // This is copied from Rust's
  const fields = {};

  tupleTypes.forEach((type, i) => {
    fields[i] = parseType(type);
  });

  const Tuple = JuliaStruct64(fields);

  return (values)
    ? new Tuple(values)
    : Tuple;
}
const julia32 = {
  MallocArray:  MallocArray32,
  Array:        Array32,
  Tuple:        JuliaTuple32,
  Struct:       JuliaStruct32,
  Pointer:      types.pointer,
};

const julia64 = {
  MallocArray:  MallocArray64,
  Array:        Array64,
  Tuple:        JuliaTuple64,
  Struct:       JuliaStruct64,
  Pointer:      types.pointer64,
};


export { julia32, julia64 };
