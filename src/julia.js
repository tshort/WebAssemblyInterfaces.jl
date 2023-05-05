import Struct from './Struct';
import { types, parseType, Pointer } from './types';
import { encode, decode } from './encoding';
import { assert, vslice, isNil, addStringFns, addArrayFns, makeIterable } from './misc';


// get the symbol for struct-data since we need access here
const DATA = (typeof Symbol !== 'undefined')
  ? Symbol.for('struct-data')
  : '__data';

function MallocArray64(typedef, n, initialValues) {
  const type = parseType(typedef);

  const Base = new Struct({
    ptr: ffi.types.pointer64(type),
    length: 'uint64',
    size: ['uint64', n],
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
      this.cap = values.length;
    },
  });

  addArrayFns(Base);
  makeIterable(Base);

  class Vector extends Base {
    constructor(values) {
      super();
      if (values) this.values = values;
    }

    free() {
      super.free(true); // free ptr data
    }
  }

  return (initialValues)
    ? new Vector(initialValues)
    : Vector;
}

const julia = {
  MallocArray64:  MallocArray64,

};


export default julia;
