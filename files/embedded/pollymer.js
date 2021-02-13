"format global";
(function(global) {

  var defined = {};

  // indexOf polyfill for IE8
  var indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++)
      if (this[i] === item)
        return i;
    return -1;
  }

  var getOwnPropertyDescriptor = true;
  try {
    Object.getOwnPropertyDescriptor({ a: 0 }, 'a');
  }
  catch(e) {
    getOwnPropertyDescriptor = false;
  }

  var defineProperty;
  (function () {
    try {
      if (!!Object.defineProperty({}, 'a', {}))
        defineProperty = Object.defineProperty;
    }
    catch (e) {
      defineProperty = function(obj, prop, opt) {
        try {
          obj[prop] = opt.value || opt.get.call(obj);
        }
        catch(e) {}
      }
    }
  })();

  function register(name, deps, declare) {
    if (arguments.length === 4)
      return registerDynamic.apply(this, arguments);
    doRegister(name, {
      declarative: true,
      deps: deps,
      declare: declare
    });
  }

  function registerDynamic(name, deps, executingRequire, execute) {
    doRegister(name, {
      declarative: false,
      deps: deps,
      executingRequire: executingRequire,
      execute: execute
    });
  }

  function doRegister(name, entry) {
    entry.name = name;

    // we never overwrite an existing define
    if (!(name in defined))
      defined[name] = entry;

    // we have to normalize dependencies
    // (assume dependencies are normalized for now)
    // entry.normalizedDeps = entry.deps.map(normalize);
    entry.normalizedDeps = entry.deps;
  }


  function buildGroups(entry, groups) {
    groups[entry.groupIndex] = groups[entry.groupIndex] || [];

    if (indexOf.call(groups[entry.groupIndex], entry) != -1)
      return;

    groups[entry.groupIndex].push(entry);

    for (var i = 0, l = entry.normalizedDeps.length; i < l; i++) {
      var depName = entry.normalizedDeps[i];
      var depEntry = defined[depName];

      // not in the registry means already linked / ES6
      if (!depEntry || depEntry.evaluated)
        continue;

      // now we know the entry is in our unlinked linkage group
      var depGroupIndex = entry.groupIndex + (depEntry.declarative != entry.declarative);

      // the group index of an entry is always the maximum
      if (depEntry.groupIndex === undefined || depEntry.groupIndex < depGroupIndex) {

        // if already in a group, remove from the old group
        if (depEntry.groupIndex !== undefined) {
          groups[depEntry.groupIndex].splice(indexOf.call(groups[depEntry.groupIndex], depEntry), 1);

          // if the old group is empty, then we have a mixed depndency cycle
          if (groups[depEntry.groupIndex].length == 0)
            throw new TypeError("Mixed dependency cycle detected");
        }

        depEntry.groupIndex = depGroupIndex;
      }

      buildGroups(depEntry, groups);
    }
  }

  function link(name) {
    var startEntry = defined[name];

    startEntry.groupIndex = 0;

    var groups = [];

    buildGroups(startEntry, groups);

    var curGroupDeclarative = !!startEntry.declarative == groups.length % 2;
    for (var i = groups.length - 1; i >= 0; i--) {
      var group = groups[i];
      for (var j = 0; j < group.length; j++) {
        var entry = group[j];

        // link each group
        if (curGroupDeclarative)
          linkDeclarativeModule(entry);
        else
          linkDynamicModule(entry);
      }
      curGroupDeclarative = !curGroupDeclarative;
    }
  }

  // module binding records
  var moduleRecords = {};
  function getOrCreateModuleRecord(name) {
    return moduleRecords[name] || (moduleRecords[name] = {
      name: name,
      dependencies: [],
      exports: {}, // start from an empty module and extend
      importers: []
    })
  }

  function linkDeclarativeModule(entry) {
    // only link if already not already started linking (stops at circular)
    if (entry.module)
      return;

    var module = entry.module = getOrCreateModuleRecord(entry.name);
    var exports = entry.module.exports;

    var declaration = entry.declare.call(global, function(name, value) {
      module.locked = true;

      if (typeof name == 'object') {
        for (var p in name)
          exports[p] = name[p];
      }
      else {
        exports[name] = value;
      }

      for (var i = 0, l = module.importers.length; i < l; i++) {
        var importerModule = module.importers[i];
        if (!importerModule.locked) {
          for (var j = 0; j < importerModule.dependencies.length; ++j) {
            if (importerModule.dependencies[j] === module) {
              importerModule.setters[j](exports);
            }
          }
        }
      }

      module.locked = false;
      return value;
    });

    module.setters = declaration.setters;
    module.execute = declaration.execute;

    // now link all the module dependencies
    for (var i = 0, l = entry.normalizedDeps.length; i < l; i++) {
      var depName = entry.normalizedDeps[i];
      var depEntry = defined[depName];
      var depModule = moduleRecords[depName];

      // work out how to set depExports based on scenarios...
      var depExports;

      if (depModule) {
        depExports = depModule.exports;
      }
      else if (depEntry && !depEntry.declarative) {
        depExports = depEntry.esModule;
      }
      // in the module registry
      else if (!depEntry) {
        depExports = load(depName);
      }
      // we have an entry -> link
      else {
        linkDeclarativeModule(depEntry);
        depModule = depEntry.module;
        depExports = depModule.exports;
      }

      // only declarative modules have dynamic bindings
      if (depModule && depModule.importers) {
        depModule.importers.push(module);
        module.dependencies.push(depModule);
      }
      else
        module.dependencies.push(null);

      // run the setter for this dependency
      if (module.setters[i])
        module.setters[i](depExports);
    }
  }

  // An analog to loader.get covering execution of all three layers (real declarative, simulated declarative, simulated dynamic)
  function getModule(name) {
    var exports;
    var entry = defined[name];

    if (!entry) {
      exports = load(name);
      if (!exports)
        throw new Error("Unable to load dependency " + name + ".");
    }

    else {
      if (entry.declarative)
        ensureEvaluated(name, []);

      else if (!entry.evaluated)
        linkDynamicModule(entry);

      exports = entry.module.exports;
    }

    if ((!entry || entry.declarative) && exports && exports.__useDefault)
      return exports['default'];

    return exports;
  }

  function linkDynamicModule(entry) {
    if (entry.module)
      return;

    var exports = {};

    var module = entry.module = { exports: exports, id: entry.name };

    // AMD requires execute the tree first
    if (!entry.executingRequire) {
      for (var i = 0, l = entry.normalizedDeps.length; i < l; i++) {
        var depName = entry.normalizedDeps[i];
        var depEntry = defined[depName];
        if (depEntry)
          linkDynamicModule(depEntry);
      }
    }

    // now execute
    entry.evaluated = true;
    var output = entry.execute.call(global, function(name) {
      for (var i = 0, l = entry.deps.length; i < l; i++) {
        if (entry.deps[i] != name)
          continue;
        return getModule(entry.normalizedDeps[i]);
      }
      throw new TypeError('Module ' + name + ' not declared as a dependency.');
    }, exports, module);

    if (output)
      module.exports = output;

    // create the esModule object, which allows ES6 named imports of dynamics
    exports = module.exports;

    if (exports && exports.__esModule) {
      entry.esModule = exports;
    }
    else {
      entry.esModule = {};

      // don't trigger getters/setters in environments that support them
      if ((typeof exports == 'object' || typeof exports == 'function') && exports !== global) {
        if (getOwnPropertyDescriptor) {
          var d;
          for (var p in exports)
            if (d = Object.getOwnPropertyDescriptor(exports, p))
              defineProperty(entry.esModule, p, d);
        }
        else {
          var hasOwnProperty = exports && exports.hasOwnProperty;
          for (var p in exports) {
            if (!hasOwnProperty || exports.hasOwnProperty(p))
              entry.esModule[p] = exports[p];
          }
         }
       }
      entry.esModule['default'] = exports;
      defineProperty(entry.esModule, '__useDefault', {
        value: true
      });
    }
  }

  /*
   * Given a module, and the list of modules for this current branch,
   *  ensure that each of the dependencies of this module is evaluated
   *  (unless one is a circular dependency already in the list of seen
   *  modules, in which case we execute it)
   *
   * Then we evaluate the module itself depth-first left to right
   * execution to match ES6 modules
   */
  function ensureEvaluated(moduleName, seen) {
    var entry = defined[moduleName];

    // if already seen, that means it's an already-evaluated non circular dependency
    if (!entry || entry.evaluated || !entry.declarative)
      return;

    // this only applies to declarative modules which late-execute

    seen.push(moduleName);

    for (var i = 0, l = entry.normalizedDeps.length; i < l; i++) {
      var depName = entry.normalizedDeps[i];
      if (indexOf.call(seen, depName) == -1) {
        if (!defined[depName])
          load(depName);
        else
          ensureEvaluated(depName, seen);
      }
    }

    if (entry.evaluated)
      return;

    entry.evaluated = true;
    entry.module.execute.call(global);
  }

  // magical execution function
  var modules = {};
  function load(name) {
    if (modules[name])
      return modules[name];

    // node core modules
    if (name.substr(0, 6) == '@node/')
      return require(name.substr(6));

    var entry = defined[name];

    // first we check if this module has already been defined in the registry
    if (!entry)
      throw "Module " + name + " not present.";

    // recursively ensure that the module and all its
    // dependencies are linked (with dependency group handling)
    link(name);

    // now handle dependency execution in correct order
    ensureEvaluated(name, []);

    // remove from the registry
    defined[name] = undefined;

    // exported modules get __esModule defined for interop
    if (entry.declarative)
      defineProperty(entry.module.exports, '__esModule', { value: true });

    // return the defined module object
    return modules[name] = entry.declarative ? entry.module.exports : entry.esModule;
  };

  return function(mains, depNames, declare) {
    return function(formatDetect) {
      formatDetect(function(deps) {
        var System = {
          _nodeRequire: typeof require != 'undefined' && require.resolve && typeof process != 'undefined' && require,
          register: register,
          registerDynamic: registerDynamic,
          get: load,
          set: function(name, module) {
            modules[name] = module;
          },
          newModule: function(module) {
            return module;
          }
        };
        System.set('@empty', {});

        // register external dependencies
        for (var i = 0; i < depNames.length; i++) (function(depName, dep) {
          if (dep && dep.__esModule)
            System.register(depName, [], function(_export) {
              return {
                setters: [],
                execute: function() {
                  for (var p in dep)
                    if (p != '__esModule' && !(typeof p == 'object' && p + '' == 'Module'))
                      _export(p, dep[p]);
                }
              };
            });
          else
            System.registerDynamic(depName, [], false, function() {
              return dep;
            });
        })(depNames[i], arguments[i]);

        // register modules in this bundle
        declare(System);

        // load mains
        var firstLoad = load(mains[0]);
        if (mains.length > 1)
          for (var i = 1; i < mains.length; i++)
            load(mains[i]);

        if (firstLoad.__useDefault)
          return firstLoad['default'];
        else
          return firstLoad;
      });
    };
  };

})(typeof self != 'undefined' ? self : global)
/* (['mainModule'], ['external-dep'], function(____DOLLAR______System) {
  System.register(...);
})
(function(factory) {
  if (typeof define && define.amd)
    define(['external-dep'], factory);
  // etc UMD / module pattern
})*/

(['1'], [], function(____DOLLAR______System) {

____DOLLAR______System.register('2', [], function (_export) {
    'use strict';

    var global, console, consoleInfo, consoleError;
    return {
        setters: [],
        execute: function () {
            if (!Function.prototype.bind) {
                Function.prototype.bind = function (oThis) {
                    if (typeof this !== 'function') {
                        // closest thing possible to the ECMAScript 5
                        // internal IsCallable function
                        throw new TypeError('Function.prototype.bind - what is trying to be bound is not callable');
                    }

                    var aArgs = Array.prototype.slice.call(arguments, 1),
                        fToBind = this,
                        fNOP = function fNOP() {},
                        fBound = function fBound() {
                        return fToBind.apply(this instanceof fNOP ? this : oThis, aArgs.concat(Array.prototype.slice.call(arguments)));
                    };

                    if (this.prototype) {
                        // native functions don't have a prototype
                        fNOP.prototype = this.prototype;
                    }
                    fBound.prototype = new fNOP();

                    return fBound;
                };
            }

            global = typeof window !== 'undefined' ? window : undefined;
            console = global.console || {};

            if (console["log"] !== 'function') {
                console["log"] = function () {};
            }

            if (typeof console["info"] !== 'function') {
                console["info"] = console["log"];
            }

            if (typeof console["error"] !== 'function') {
                console["error"] = console["log"];
            }

            consoleInfo = function(_){}; // console.info.bind(console);

            _export('consoleInfo', consoleInfo);

            consoleError = function(_){}; console.error.bind(console);

            _export('consoleError', consoleError);
        }
    };
});
____DOLLAR______System.registerDynamic("3", ["4", "5"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var forOf = ____DOLLAR______require('4'),
      classof = ____DOLLAR______require('5');
  module.exports = function(NAME) {
    return function toJSON() {
      if (classof(this) != NAME)
        throw TypeError(NAME + "#toJSON isn't generic");
      var arr = [];
      forOf(this, false, arr.push, arr);
      return arr;
    };
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("6", ["7", "3"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var ____DOLLAR____export = ____DOLLAR______require('7');
  ____DOLLAR____export(____DOLLAR____export.P, 'Map', {toJSON: ____DOLLAR______require('3')('Map')});
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("8", ["9", "a", "7", "b", "c", "d", "4", "e", "f", "10", "11"], true, function(____DOLLAR______require, exports, module) {
  "use strict";
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var ____DOLLAR____ = ____DOLLAR______require('9'),
      global = ____DOLLAR______require('a'),
      ____DOLLAR____export = ____DOLLAR______require('7'),
      fails = ____DOLLAR______require('b'),
      hide = ____DOLLAR______require('c'),
      redefineAll = ____DOLLAR______require('d'),
      forOf = ____DOLLAR______require('4'),
      strictNew = ____DOLLAR______require('e'),
      isObject = ____DOLLAR______require('f'),
      setToStringTag = ____DOLLAR______require('10'),
      DESCRIPTORS = ____DOLLAR______require('11');
  module.exports = function(NAME, wrapper, methods, common, IS_MAP, IS_WEAK) {
    var Base = global[NAME],
        C = Base,
        ADDER = IS_MAP ? 'set' : 'add',
        proto = C && C.prototype,
        O = {};
    if (!DESCRIPTORS || typeof C != 'function' || !(IS_WEAK || proto.forEach && !fails(function() {
      new C().entries().next();
    }))) {
      C = common.getConstructor(wrapper, NAME, IS_MAP, ADDER);
      redefineAll(C.prototype, methods);
    } else {
      C = wrapper(function(target, iterable) {
        strictNew(target, C, NAME);
        target._c = new Base;
        if (iterable != undefined)
          forOf(iterable, IS_MAP, target[ADDER], target);
      });
      ____DOLLAR____.each.call('add,clear,delete,forEach,get,has,set,keys,values,entries'.split(','), function(KEY) {
        var IS_ADDER = KEY == 'add' || KEY == 'set';
        if (KEY in proto && !(IS_WEAK && KEY == 'clear'))
          hide(C.prototype, KEY, function(a, b) {
            if (!IS_ADDER && IS_WEAK && !isObject(a))
              return KEY == 'get' ? undefined : false;
            var result = this._c[KEY](a === 0 ? 0 : a, b);
            return IS_ADDER ? this : result;
          });
      });
      if ('size' in proto)
        ____DOLLAR____.setDesc(C.prototype, 'size', {get: function() {
            return this._c.size;
          }});
    }
    setToStringTag(C, NAME);
    O[NAME] = C;
    ____DOLLAR____export(____DOLLAR____export.G + ____DOLLAR____export.W + ____DOLLAR____export.F, O);
    if (!IS_WEAK)
      common.setStrong(C, NAME, IS_MAP);
    return C;
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("12", ["13", "9", "11", "14"], true, function(____DOLLAR______require, exports, module) {
  "use strict";
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var core = ____DOLLAR______require('13'),
      ____DOLLAR____ = ____DOLLAR______require('9'),
      DESCRIPTORS = ____DOLLAR______require('11'),
      SPECIES = ____DOLLAR______require('14')('species');
  module.exports = function(KEY) {
    var C = core[KEY];
    if (DESCRIPTORS && C && !C[SPECIES])
      ____DOLLAR____.setDesc(C, SPECIES, {
        configurable: true,
        get: function() {
          return this;
        }
      });
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("5", ["15", "14"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var cof = ____DOLLAR______require('15'),
      TAG = ____DOLLAR______require('14')('toStringTag'),
      ARG = cof(function() {
        return arguments;
      }()) == 'Arguments';
  module.exports = function(it) {
    var O,
        T,
        B;
    return it === undefined ? 'Undefined' : it === null ? 'Null' : typeof(T = (O = Object(it))[TAG]) == 'string' ? T : ARG ? cof(O) : (B = cof(O)) == 'Object' && typeof O.callee == 'function' ? 'Arguments' : B;
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("16", ["5", "14", "17", "13"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var classof = ____DOLLAR______require('5'),
      ITERATOR = ____DOLLAR______require('14')('iterator'),
      Iterators = ____DOLLAR______require('17');
  module.exports = ____DOLLAR______require('13').getIteratorMethod = function(it) {
    if (it != undefined)
      return it[ITERATOR] || it['@@iterator'] || Iterators[classof(it)];
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("18", ["19"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var toInteger = ____DOLLAR______require('19'),
      min = Math.min;
  module.exports = function(it) {
    return it > 0 ? min(toInteger(it), 0x1fffffffffffff) : 0;
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("1a", ["17", "14"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var Iterators = ____DOLLAR______require('17'),
      ITERATOR = ____DOLLAR______require('14')('iterator'),
      ArrayProto = Array.prototype;
  module.exports = function(it) {
    return it !== undefined && (Iterators.Array === it || ArrayProto[ITERATOR] === it);
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("f", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = function(it) {
    return typeof it === 'object' ? it !== null : typeof it === 'function';
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("1b", ["f"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var isObject = ____DOLLAR______require('f');
  module.exports = function(it) {
    if (!isObject(it))
      throw TypeError(it + ' is not an object!');
    return it;
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("1c", ["1b"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var anObject = ____DOLLAR______require('1b');
  module.exports = function(iterator, fn, value, entries) {
    try {
      return entries ? fn(anObject(value)[0], value[1]) : fn(value);
    } catch (e) {
      var ret = iterator['return'];
      if (ret !== undefined)
        anObject(ret.call(iterator));
      throw e;
    }
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("4", ["1d", "1c", "1a", "1b", "18", "16"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var ctx = ____DOLLAR______require('1d'),
      call = ____DOLLAR______require('1c'),
      isArrayIter = ____DOLLAR______require('1a'),
      anObject = ____DOLLAR______require('1b'),
      toLength = ____DOLLAR______require('18'),
      getIterFn = ____DOLLAR______require('16');
  module.exports = function(iterable, entries, fn, that) {
    var iterFn = getIterFn(iterable),
        f = ctx(fn, that, entries ? 2 : 1),
        index = 0,
        length,
        step,
        iterator;
    if (typeof iterFn != 'function')
      throw TypeError(iterable + ' is not iterable!');
    if (isArrayIter(iterFn))
      for (length = toLength(iterable.length); length > index; index++) {
        entries ? f(anObject(step = iterable[index])[0], step[1]) : f(iterable[index]);
      }
    else
      for (iterator = iterFn.call(iterable); !(step = iterator.next()).done; ) {
        call(iterator, f, step.value, entries);
      }
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("e", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = function(it, Constructor, name) {
    if (!(it instanceof Constructor))
      throw TypeError(name + ": use the 'new' operator!");
    return it;
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("d", ["1e"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var redefine = ____DOLLAR______require('1e');
  module.exports = function(target, src) {
    for (var key in src)
      redefine(target, key, src[key]);
    return target;
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("1f", ["9", "c", "d", "1d", "e", "20", "4", "21", "22", "23", "24", "f", "12", "11"], true, function(____DOLLAR______require, exports, module) {
  "use strict";
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var ____DOLLAR____ = ____DOLLAR______require('9'),
      hide = ____DOLLAR______require('c'),
      redefineAll = ____DOLLAR______require('d'),
      ctx = ____DOLLAR______require('1d'),
      strictNew = ____DOLLAR______require('e'),
      defined = ____DOLLAR______require('20'),
      forOf = ____DOLLAR______require('4'),
      ____DOLLAR____iterDefine = ____DOLLAR______require('21'),
      step = ____DOLLAR______require('22'),
      ID = ____DOLLAR______require('23')('id'),
      ____DOLLAR____has = ____DOLLAR______require('24'),
      isObject = ____DOLLAR______require('f'),
      setSpecies = ____DOLLAR______require('12'),
      DESCRIPTORS = ____DOLLAR______require('11'),
      isExtensible = Object.isExtensible || isObject,
      SIZE = DESCRIPTORS ? '_s' : 'size',
      id = 0;
  var fastKey = function(it, create) {
    if (!isObject(it))
      return typeof it == 'symbol' ? it : (typeof it == 'string' ? 'S' : 'P') + it;
    if (!____DOLLAR____has(it, ID)) {
      if (!isExtensible(it))
        return 'F';
      if (!create)
        return 'E';
      hide(it, ID, ++id);
    }
    return 'O' + it[ID];
  };
  var getEntry = function(that, key) {
    var index = fastKey(key),
        entry;
    if (index !== 'F')
      return that._i[index];
    for (entry = that._f; entry; entry = entry.n) {
      if (entry.k == key)
        return entry;
    }
  };
  module.exports = {
    getConstructor: function(wrapper, NAME, IS_MAP, ADDER) {
      var C = wrapper(function(that, iterable) {
        strictNew(that, C, NAME);
        that._i = ____DOLLAR____.create(null);
        that._f = undefined;
        that._l = undefined;
        that[SIZE] = 0;
        if (iterable != undefined)
          forOf(iterable, IS_MAP, that[ADDER], that);
      });
      redefineAll(C.prototype, {
        clear: function clear() {
          for (var that = this,
              data = that._i,
              entry = that._f; entry; entry = entry.n) {
            entry.r = true;
            if (entry.p)
              entry.p = entry.p.n = undefined;
            delete data[entry.i];
          }
          that._f = that._l = undefined;
          that[SIZE] = 0;
        },
        'delete': function(key) {
          var that = this,
              entry = getEntry(that, key);
          if (entry) {
            var next = entry.n,
                prev = entry.p;
            delete that._i[entry.i];
            entry.r = true;
            if (prev)
              prev.n = next;
            if (next)
              next.p = prev;
            if (that._f == entry)
              that._f = next;
            if (that._l == entry)
              that._l = prev;
            that[SIZE]--;
          }
          return !!entry;
        },
        forEach: function forEach(callbackfn) {
          var f = ctx(callbackfn, arguments.length > 1 ? arguments[1] : undefined, 3),
              entry;
          while (entry = entry ? entry.n : this._f) {
            f(entry.v, entry.k, this);
            while (entry && entry.r)
              entry = entry.p;
          }
        },
        has: function has(key) {
          return !!getEntry(this, key);
        }
      });
      if (DESCRIPTORS)
        ____DOLLAR____.setDesc(C.prototype, 'size', {get: function() {
            return defined(this[SIZE]);
          }});
      return C;
    },
    def: function(that, key, value) {
      var entry = getEntry(that, key),
          prev,
          index;
      if (entry) {
        entry.v = value;
      } else {
        that._l = entry = {
          i: index = fastKey(key, true),
          k: key,
          v: value,
          p: prev = that._l,
          n: undefined,
          r: false
        };
        if (!that._f)
          that._f = entry;
        if (prev)
          prev.n = entry;
        that[SIZE]++;
        if (index !== 'F')
          that._i[index] = entry;
      }
      return that;
    },
    getEntry: getEntry,
    setStrong: function(C, NAME, IS_MAP) {
      ____DOLLAR____iterDefine(C, NAME, function(iterated, kind) {
        this._t = iterated;
        this._k = kind;
        this._l = undefined;
      }, function() {
        var that = this,
            kind = that._k,
            entry = that._l;
        while (entry && entry.r)
          entry = entry.p;
        if (!that._t || !(that._l = entry = entry ? entry.n : that._t._f)) {
          that._t = undefined;
          return step(1);
        }
        if (kind == 'keys')
          return step(0, entry.k);
        if (kind == 'values')
          return step(0, entry.v);
        return step(0, [entry.k, entry.v]);
      }, IS_MAP ? 'entries' : 'values', !IS_MAP, true);
      setSpecies(NAME);
    }
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("25", ["1f", "8"], true, function(____DOLLAR______require, exports, module) {
  "use strict";
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var strong = ____DOLLAR______require('1f');
  ____DOLLAR______require('8')('Map', function(get) {
    return function Map() {
      return get(this, arguments.length > 0 ? arguments[0] : undefined);
    };
  }, {
    get: function get(key) {
      var entry = strong.getEntry(this, key);
      return entry && entry.v;
    },
    set: function set(key, value) {
      return strong.def(this, key === 0 ? 0 : key, value);
    }
  }, strong, true);
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("15", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var toString = {}.toString;
  module.exports = function(it) {
    return toString.call(it).slice(8, -1);
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("26", ["15"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var cof = ____DOLLAR______require('15');
  module.exports = Object('z').propertyIsEnumerable(0) ? Object : function(it) {
    return cof(it) == 'String' ? it.split('') : Object(it);
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("27", ["26", "20"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var IObject = ____DOLLAR______require('26'),
      defined = ____DOLLAR______require('20');
  module.exports = function(it) {
    return IObject(defined(it));
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("22", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = function(done, value) {
    return {
      value: value,
      done: !!done
    };
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("28", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = function() {};
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("29", ["28", "22", "17", "27", "21"], true, function(____DOLLAR______require, exports, module) {
  "use strict";
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var addToUnscopables = ____DOLLAR______require('28'),
      step = ____DOLLAR______require('22'),
      Iterators = ____DOLLAR______require('17'),
      toIObject = ____DOLLAR______require('27');
  module.exports = ____DOLLAR______require('21')(Array, 'Array', function(iterated, kind) {
    this._t = toIObject(iterated);
    this._i = 0;
    this._k = kind;
  }, function() {
    var O = this._t,
        kind = this._k,
        index = this._i++;
    if (!O || index >= O.length) {
      this._t = undefined;
      return step(1);
    }
    if (kind == 'keys')
      return step(0, index);
    if (kind == 'values')
      return step(0, O[index]);
    return step(0, [index, O[index]]);
  }, 'values');
  Iterators.Arguments = Iterators.Array;
  addToUnscopables('keys');
  addToUnscopables('values');
  addToUnscopables('entries');
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("2a", ["29", "17"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  ____DOLLAR______require('29');
  var Iterators = ____DOLLAR______require('17');
  Iterators.NodeList = Iterators.HTMLCollection = Iterators.Array;
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("23", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var id = 0,
      px = Math.random();
  module.exports = function(key) {
    return 'Symbol('.concat(key === undefined ? '' : key, ')_', (++id + px).toString(36));
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("2b", ["a"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var global = ____DOLLAR______require('a'),
      SHARED = '__core-js_shared__',
      store = global[SHARED] || (global[SHARED] = {});
  module.exports = function(key) {
    return store[key] || (store[key] = {});
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("14", ["2b", "23", "a"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var store = ____DOLLAR______require('2b')('wks'),
      uid = ____DOLLAR______require('23'),
      Symbol = ____DOLLAR______require('a').Symbol;
  module.exports = function(name) {
    return store[name] || (store[name] = Symbol && Symbol[name] || (Symbol || uid)('Symbol.' + name));
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("10", ["9", "24", "14"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var def = ____DOLLAR______require('9').setDesc,
      has = ____DOLLAR______require('24'),
      TAG = ____DOLLAR______require('14')('toStringTag');
  module.exports = function(it, tag, stat) {
    if (it && !has(it = stat ? it : it.prototype, TAG))
      def(it, TAG, {
        configurable: true,
        value: tag
      });
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("2c", ["9", "2d", "10", "c", "14"], true, function(____DOLLAR______require, exports, module) {
  "use strict";
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var ____DOLLAR____ = ____DOLLAR______require('9'),
      descriptor = ____DOLLAR______require('2d'),
      setToStringTag = ____DOLLAR______require('10'),
      IteratorPrototype = {};
  ____DOLLAR______require('c')(IteratorPrototype, ____DOLLAR______require('14')('iterator'), function() {
    return this;
  });
  module.exports = function(Constructor, NAME, next) {
    Constructor.prototype = ____DOLLAR____.create(IteratorPrototype, {next: descriptor(1, next)});
    setToStringTag(Constructor, NAME + ' Iterator');
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("17", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = {};
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("24", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var hasOwnProperty = {}.hasOwnProperty;
  module.exports = function(it, key) {
    return hasOwnProperty.call(it, key);
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("b", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = function(exec) {
    try {
      return !!exec();
    } catch (e) {
      return true;
    }
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("11", ["b"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = !____DOLLAR______require('b')(function() {
    return Object.defineProperty({}, 'a', {get: function() {
        return 7;
      }}).a != 7;
  });
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("2d", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = function(bitmap, value) {
    return {
      enumerable: !(bitmap & 1),
      configurable: !(bitmap & 2),
      writable: !(bitmap & 4),
      value: value
    };
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("c", ["9", "2d", "11"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var ____DOLLAR____ = ____DOLLAR______require('9'),
      createDesc = ____DOLLAR______require('2d');
  module.exports = ____DOLLAR______require('11') ? function(object, key, value) {
    return ____DOLLAR____.setDesc(object, key, createDesc(1, value));
  } : function(object, key, value) {
    object[key] = value;
    return object;
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("1e", ["c"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = ____DOLLAR______require('c');
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("2e", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = function(it) {
    if (typeof it != 'function')
      throw TypeError(it + ' is not a function!');
    return it;
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("1d", ["2e"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var aFunction = ____DOLLAR______require('2e');
  module.exports = function(fn, that, length) {
    aFunction(fn);
    if (that === undefined)
      return fn;
    switch (length) {
      case 1:
        return function(a) {
          return fn.call(that, a);
        };
      case 2:
        return function(a, b) {
          return fn.call(that, a, b);
        };
      case 3:
        return function(a, b, c) {
          return fn.call(that, a, b, c);
        };
    }
    return function() {
      return fn.apply(that, arguments);
    };
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("13", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var core = module.exports = {version: '1.2.6'};
  if (typeof __e == 'number')
    __e = core;
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("a", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var global = module.exports = typeof window != 'undefined' && window.Math == Math ? window : typeof self != 'undefined' && self.Math == Math ? self : Function('return this')();
  if (typeof __g == 'number')
    __g = global;
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("7", ["a", "13", "1d"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var global = ____DOLLAR______require('a'),
      core = ____DOLLAR______require('13'),
      ctx = ____DOLLAR______require('1d'),
      PROTOTYPE = 'prototype';
  var ____DOLLAR____export = function(type, name, source) {
    var IS_FORCED = type & ____DOLLAR____export.F,
        IS_GLOBAL = type & ____DOLLAR____export.G,
        IS_STATIC = type & ____DOLLAR____export.S,
        IS_PROTO = type & ____DOLLAR____export.P,
        IS_BIND = type & ____DOLLAR____export.B,
        IS_WRAP = type & ____DOLLAR____export.W,
        exports = IS_GLOBAL ? core : core[name] || (core[name] = {}),
        target = IS_GLOBAL ? global : IS_STATIC ? global[name] : (global[name] || {})[PROTOTYPE],
        key,
        own,
        out;
    if (IS_GLOBAL)
      source = name;
    for (key in source) {
      own = !IS_FORCED && target && key in target;
      if (own && key in exports)
        continue;
      out = own ? target[key] : source[key];
      exports[key] = IS_GLOBAL && typeof target[key] != 'function' ? source[key] : IS_BIND && own ? ctx(out, global) : IS_WRAP && target[key] == out ? (function(C) {
        var F = function(param) {
          return this instanceof C ? new C(param) : C(param);
        };
        F[PROTOTYPE] = C[PROTOTYPE];
        return F;
      })(out) : IS_PROTO && typeof out == 'function' ? ctx(Function.call, out) : out;
      if (IS_PROTO)
        (exports[PROTOTYPE] || (exports[PROTOTYPE] = {}))[key] = out;
    }
  };
  ____DOLLAR____export.F = 1;
  ____DOLLAR____export.G = 2;
  ____DOLLAR____export.S = 4;
  ____DOLLAR____export.P = 8;
  ____DOLLAR____export.B = 16;
  ____DOLLAR____export.W = 32;
  module.exports = ____DOLLAR____export;
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("2f", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = true;
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("21", ["2f", "7", "1e", "c", "24", "17", "2c", "10", "9", "14"], true, function(____DOLLAR______require, exports, module) {
  "use strict";
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var LIBRARY = ____DOLLAR______require('2f'),
      ____DOLLAR____export = ____DOLLAR______require('7'),
      redefine = ____DOLLAR______require('1e'),
      hide = ____DOLLAR______require('c'),
      has = ____DOLLAR______require('24'),
      Iterators = ____DOLLAR______require('17'),
      ____DOLLAR____iterCreate = ____DOLLAR______require('2c'),
      setToStringTag = ____DOLLAR______require('10'),
      getProto = ____DOLLAR______require('9').getProto,
      ITERATOR = ____DOLLAR______require('14')('iterator'),
      BUGGY = !([].keys && 'next' in [].keys()),
      FF_ITERATOR = '@@iterator',
      KEYS = 'keys',
      VALUES = 'values';
  var returnThis = function() {
    return this;
  };
  module.exports = function(Base, NAME, Constructor, next, DEFAULT, IS_SET, FORCED) {
    ____DOLLAR____iterCreate(Constructor, NAME, next);
    var getMethod = function(kind) {
      if (!BUGGY && kind in proto)
        return proto[kind];
      switch (kind) {
        case KEYS:
          return function keys() {
            return new Constructor(this, kind);
          };
        case VALUES:
          return function values() {
            return new Constructor(this, kind);
          };
      }
      return function entries() {
        return new Constructor(this, kind);
      };
    };
    var TAG = NAME + ' Iterator',
        DEF_VALUES = DEFAULT == VALUES,
        VALUES_BUG = false,
        proto = Base.prototype,
        ____DOLLAR____native = proto[ITERATOR] || proto[FF_ITERATOR] || DEFAULT && proto[DEFAULT],
        ____DOLLAR____default = ____DOLLAR____native || getMethod(DEFAULT),
        methods,
        key;
    if (____DOLLAR____native) {
      var IteratorPrototype = getProto(____DOLLAR____default.call(new Base));
      setToStringTag(IteratorPrototype, TAG, true);
      if (!LIBRARY && has(proto, FF_ITERATOR))
        hide(IteratorPrototype, ITERATOR, returnThis);
      if (DEF_VALUES && ____DOLLAR____native.name !== VALUES) {
        VALUES_BUG = true;
        ____DOLLAR____default = function values() {
          return ____DOLLAR____native.call(this);
        };
      }
    }
    if ((!LIBRARY || FORCED) && (BUGGY || VALUES_BUG || !proto[ITERATOR])) {
      hide(proto, ITERATOR, ____DOLLAR____default);
    }
    Iterators[NAME] = ____DOLLAR____default;
    Iterators[TAG] = returnThis;
    if (DEFAULT) {
      methods = {
        values: DEF_VALUES ? ____DOLLAR____default : getMethod(VALUES),
        keys: IS_SET ? ____DOLLAR____default : getMethod(KEYS),
        entries: !DEF_VALUES ? ____DOLLAR____default : getMethod('entries')
      };
      if (FORCED)
        for (key in methods) {
          if (!(key in proto))
            redefine(proto, key, methods[key]);
        }
      else
        ____DOLLAR____export(____DOLLAR____export.P + ____DOLLAR____export.F * (BUGGY || VALUES_BUG), NAME, methods);
    }
    return methods;
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("20", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = function(it) {
    if (it == undefined)
      throw TypeError("Can't call method on  " + it);
    return it;
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("19", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var ceil = Math.ceil,
      floor = Math.floor;
  module.exports = function(it) {
    return isNaN(it = +it) ? 0 : (it > 0 ? floor : ceil)(it);
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("30", ["19", "20"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var toInteger = ____DOLLAR______require('19'),
      defined = ____DOLLAR______require('20');
  module.exports = function(TO_STRING) {
    return function(that, pos) {
      var s = String(defined(that)),
          i = toInteger(pos),
          l = s.length,
          a,
          b;
      if (i < 0 || i >= l)
        return TO_STRING ? '' : undefined;
      a = s.charCodeAt(i);
      return a < 0xd800 || a > 0xdbff || i + 1 === l || (b = s.charCodeAt(i + 1)) < 0xdc00 || b > 0xdfff ? TO_STRING ? s.charAt(i) : a : TO_STRING ? s.slice(i, i + 2) : (a - 0xd800 << 10) + (b - 0xdc00) + 0x10000;
    };
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("31", ["30", "21"], true, function(____DOLLAR______require, exports, module) {
  "use strict";
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var ____DOLLAR____at = ____DOLLAR______require('30')(true);
  ____DOLLAR______require('21')(String, 'String', function(iterated) {
    this._t = String(iterated);
    this._i = 0;
  }, function() {
    var O = this._t,
        index = this._i,
        point;
    if (index >= O.length)
      return {
        value: undefined,
        done: true
      };
    point = ____DOLLAR____at(O, index);
    this._i += point.length;
    return {
      value: point,
      done: false
    };
  });
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("32", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  "format cjs";
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("33", ["32", "31", "2a", "25", "6", "13"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  ____DOLLAR______require('32');
  ____DOLLAR______require('31');
  ____DOLLAR______require('2a');
  ____DOLLAR______require('25');
  ____DOLLAR______require('6');
  module.exports = ____DOLLAR______require('13').Map;
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("34", ["33"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = {
    "default": ____DOLLAR______require('33'),
    __esModule: true
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.register("35", ["34", "36", "37"], function (_export) {
    var _Map, _createClass, _classCallCheck, Events;

    return {
        setters: [function (_3) {
            _Map = _3["default"];
        }, function (_) {
            _createClass = _["default"];
        }, function (_2) {
            _classCallCheck = _2["default"];
        }],
        execute: function () {
            "use strict";

            Events = (function () {
                function Events() {
                    _classCallCheck(this, Events);

                    this._events = new _Map();
                }

                _createClass(Events, [{
                    key: "on",
                    value: function on(type, handler) {
                        var _this = this;

                        var currentHandlers = this._events.get(type) || [];
                        var handlers = currentHandlers.concat([handler]);
                        this._events.set(type, handlers);
                        return function () {
                            return _this.off(type, handler);
                        };
                    }
                }, {
                    key: "off",
                    value: function off(type, handler) {
                        if (typeof handler !== "undefined") {
                            if (this._events.has(type)) {
                                var currentHandlers = this._events.get(type);
                                this._events.set(type, currentHandlers.filter(function (item) {
                                    return item !== handler;
                                }));
                            }
                        } else {
                            this._events["delete"](type);
                        }
                    }
                }, {
                    key: "trigger",
                    value: function trigger(type, obj) {
                        for (var _len = arguments.length, args = Array(_len > 2 ? _len - 2 : 0), _key = 2; _key < _len; _key++) {
                            args[_key - 2] = arguments[_key];
                        }

                        if (this._events.has(type)) {
                            this._events.get(type).forEach(function (handler) {
                                return handler.call.apply(handler, [obj].concat(args));
                            });
                        }
                    }
                }]);

                return Events;
            })();

            _export("default", Events);
        }
    };
});
____DOLLAR______System.register("38", [], function (_export) {
    "use strict";

    return {
        setters: [],
        execute: function () {
            _export("default", {
                "TransportError": 0,
                "TimeoutError": 1
            });
        }
    };
});
____DOLLAR______System.register("39", [], function (_export) {
    "use strict";

    return {
        setters: [],
        execute: function () {
            _export("default", {
                "Auto": 0,
                "Xhr": 1,
                "Jsonp": 2
            });
        }
    };
});
____DOLLAR______System.registerDynamic("37", [], true, function(____DOLLAR______require, exports, module) {
  "use strict";
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  exports["default"] = function(instance, Constructor) {
    if (!(instance instanceof Constructor)) {
      throw new TypeError("Cannot call a class as a function");
    }
  };
  exports.__esModule = true;
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("9", [], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var ____DOLLAR____Object = Object;
  module.exports = {
    create: ____DOLLAR____Object.create,
    getProto: ____DOLLAR____Object.getPrototypeOf,
    isEnum: {}.propertyIsEnumerable,
    getDesc: ____DOLLAR____Object.getOwnPropertyDescriptor,
    setDesc: ____DOLLAR____Object.defineProperty,
    setDescs: ____DOLLAR____Object.defineProperties,
    getKeys: ____DOLLAR____Object.keys,
    getNames: ____DOLLAR____Object.getOwnPropertyNames,
    getSymbols: ____DOLLAR____Object.getOwnPropertySymbols,
    each: [].forEach
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("3a", ["9"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var ____DOLLAR____ = ____DOLLAR______require('9');
  module.exports = function defineProperty(it, key, desc) {
    return ____DOLLAR____.setDesc(it, key, desc);
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("3b", ["3a"], true, function(____DOLLAR______require, exports, module) {
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  module.exports = {
    "default": ____DOLLAR______require('3a'),
    __esModule: true
  };
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.registerDynamic("36", ["3b"], true, function(____DOLLAR______require, exports, module) {
  "use strict";
  ;
  var global = this,
      __define = global.define;
  global.define = undefined;
  var _Object____DOLLAR____defineProperty = ____DOLLAR______require('3b')["default"];
  exports["default"] = (function() {
    function defineProperties(target, props) {
      for (var i = 0; i < props.length; i++) {
        var descriptor = props[i];
        descriptor.enumerable = descriptor.enumerable || false;
        descriptor.configurable = true;
        if ("value" in descriptor)
          descriptor.writable = true;
        _Object____DOLLAR____defineProperty(target, descriptor.key, descriptor);
      }
    }
    return function(Constructor, protoProps, staticProps) {
      if (protoProps)
        defineProperties(Constructor.prototype, protoProps);
      if (staticProps)
        defineProperties(Constructor, staticProps);
      return Constructor;
    };
  })();
  exports.__esModule = true;
  global.define = __define;
  return module.exports;
});

____DOLLAR______System.register('3c', ['2', '35', '36', '37', '38', '39'], function (_export) {
    var consoleInfo, consoleError, Events, _createClass, _classCallCheck, ErrorTypes, TransportTypes, global, emptyMethod, checkForErrorCode, parseResponseHeaders, jsonpGuid, addJsonpScriptToDom, removeJsonpScriptFromDom, corsAvailable, sameOrigin, chooseTransport, Request;

    return {
        setters: [function (_6) {
            consoleInfo = _6.consoleInfo;
            consoleError = _6.consoleError;
        }, function (_5) {
            Events = _5['default'];
        }, function (_) {
            _createClass = _['default'];
        }, function (_2) {
            _classCallCheck = _2['default'];
        }, function (_4) {
            ErrorTypes = _4['default'];
        }, function (_3) {
            TransportTypes = _3['default'];
        }],
        execute: function () {

            // Global object (window in browsers)

            'use strict';

            global = typeof window !== 'undefined' ? window : undefined;

            // Create one instance of an empty method to be used where necessary

            emptyMethod = function emptyMethod() {};

            // Utility to determine whether an HTTP code should be treated as an error

            checkForErrorCode = function checkForErrorCode(codesStr, code) {
                var parts = codesStr.split(',');
                for (var i = 0; i < parts.length; i++) {
                    var part = parts[i];
                    var index = part.indexOf('-');
                    if (index >= 0) {
                        // part is a range
                        var min = parseInt(part.substring(0, index), 10);
                        var max = parseInt(part.substring(index + 1), 10);
                        if (code >= min && code <= max) {
                            return true;
                        }
                    } else {
                        // part is a single value
                        var val = parseInt(part, 10);
                        if (code == val) {
                            return true;
                        }
                    }
                }
                return false;
            };

            // Response Header Parsing

            parseResponseHeaders = function parseResponseHeaders(headerStr) {
                var headers = {};
                if (!headerStr) {
                    return headers;
                }
                var headerPairs = headerStr.split('\r\n');
                for (var i = 0; i < headerPairs.length; i++) {
                    var headerPair = headerPairs[i];
                    // IE sometimes puts a newline at the start of header names
                    if (headerPair[0] == '\n') {
                        headerPair = headerPair.substring(1);
                    }
                    var index = headerPair.indexOf(': ');
                    if (index > 0) {
                        var key = headerPair.substring(0, index);
                        headers[key] = headerPair.substring(index + 2);
                    }
                }
                return headers;
            };

            // JSONP-related utility functions

            jsonpGuid = "D3DDFE2A-6E6D-47A7-8F3B-0A4A8E71A796";

            addJsonpScriptToDom = function addJsonpScriptToDom(src, scriptId) {
                var script = global.document.createElement("script");
                script.type = "text/javascript";
                script.id = scriptId;
                script.src = src;

                var head = global.document.getElementsByTagName("head")[0];
                head.appendChild(script);
            };

            removeJsonpScriptFromDom = function removeJsonpScriptFromDom(scriptId) {
                var script = global.document.getElementById(scriptId);
                script.parentNode.removeChild(script);
            };

            // CORS detection

            corsAvailable = "withCredentials" in new global.XMLHttpRequest();

            // Transport Selection

            sameOrigin = function sameOrigin(url) {
                var loc = global.location;
                var a = global.document.createElement('a');
                a.href = url;
                return !a.hostname || a.hostname == loc.hostname && a.port == loc.port && a.protocol == loc.protocol;
            };

            chooseTransport = function chooseTransport(transportType, url) {
                var transport;
                if (transportType == TransportTypes.Auto) {
                    if (corsAvailable || sameOrigin(url)) {
                        transport = TransportTypes.Xhr;
                    } else {
                        transport = TransportTypes.Jsonp;
                    }
                } else {
                    switch (transportType) {
                        case TransportTypes.Xhr:
                            transport = TransportTypes.Xhr;
                            break;
                        case TransportTypes.Jsonp:
                            transport = TransportTypes.Jsonp;
                            break;
                        default:
                            transport = null;
                    }
                }
                return transport;
            };

            // Pollymer.Request has callback members:
            // on('finished', int code, object result, object headers)
            // on('error', int reason)

            Request = (function () {
                function Request() {
                    _classCallCheck(this, Request);

                    this._events = new Events();
                    this._tries = 0;
                    this._delayNext = false;
                    this._retryTime = 0;
                    this._timer = null;
                    this._jsonp = null;

                    this._xhr = null;
                    this._method = null;
                    this._url = null;
                    this._headers = null;
                    this._body = null;
                    this._transport = null;

                    this.transport = TransportTypes.Auto;
                    this.rawResponse = false;
                    this.maxTries = 1;
                    this.maxDelay = 1000;
                    this.recurring = false;
                    this.withCredentials = false;
                    this.timeout = 60000;
                    this.errorCodes = '500-599';

                    this.lastRequest = null;

                    if (arguments.length > 0) {
                        var config = arguments[0];
                        if ("transport" in config) {
                            this.transport = config.transport;
                        }
                        if ("rawResponse" in config) {
                            this.rawResponse = config.rawResponse;
                        }
                        if ("maxTries" in config) {
                            this.maxTries = config.maxTries;
                        }
                        if ("maxDelay" in config) {
                            this.maxDelay = config.maxDelay;
                        }
                        if ("recurring" in config) {
                            this.recurring = config.recurring;
                        }
                        if ("withCredentials" in config) {
                            this.withCredentials = config.withCredentials;
                        }
                        if ("timeout" in config) {
                            this.timeout = config.timeout;
                        }
                        if ("errorCodes" in config) {
                            this.errorCodes = config.errorCodes;
                        }
                    }
                }

                _createClass(Request, [{
                    key: 'start',
                    value: function start(method, url, headers, body) {
                        if (this._timer != null) {
                            consoleError("pollymer: start() called on a Request object that is currently running.");
                            return;
                        }

                        this._method = method;
                        this._url = url;
                        this._headers = headers;
                        this._body = body;
                        this._start();
                    }
                }, {
                    key: '_start',
                    value: function _start() {
                        this._tries = 0;

                        var delayTime;
                        if (this._delayNext) {
                            this._delayNext = false;
                            delayTime = Math.floor(Math.random() * this.maxDelay);
                            consoleInfo("pollymer: polling again in " + delayTime + "ms");
                        } else {
                            delayTime = 0; // always queue the call, to prevent browser "busy"
                        }

                        this._initiate(delayTime);
                    }
                }, {
                    key: 'retry',
                    value: function retry() {
                        if (this._tries == 0) {
                            consoleError("pollymer: retry() called on a Request object that has never been started.");
                            return;
                        }
                        if (this._timer != null) {
                            consoleError("pollymer: retry() called on a Request object that is currently running.");
                            return;
                        }
                        this._retry();
                    }
                }, {
                    key: '_retry',
                    value: function _retry() {
                        if (this._tries === 1) {
                            this._retryTime = 1;
                        } else if (this._tries < 8) {
                            this._retryTime = this._retryTime * 2;
                        }

                        var delayTime = this._retryTime * 1000;
                        delayTime += Math.floor(Math.random() * this.maxDelay);
                        consoleInfo("pollymer: trying again in " + delayTime + "ms");

                        this._initiate(delayTime);
                    }
                }, {
                    key: '_initiate',
                    value: function _initiate(delayMsecs) {
                        var self = this;
                        self.lastRequest = null;
                        self._timer = setTimeout(function () {
                            self._startConnect();
                        }, delayMsecs);
                    }
                }, {
                    key: '_startConnect',
                    value: function _startConnect() {
                        var self = this;
                        this._timer = setTimeout(function () {
                            self._timeout();
                        }, this.timeout);

                        this._tries++;

                        var method = this._method;
                        var url = typeof this._url == "function" ? this._url() : this._url;
                        var headers = this._headers;
                        var body = this._body;

                        // Create a copy of the transport because we don't want
                        // to give public access to it (changing it between now and
                        // cleanup would be a no-no)
                        this._transport = chooseTransport(this.transport, url);

                        self.lastRequest = {
                            method: method,
                            uri: url,
                            headers: headers,
                            body: body,
                            transport: this._transport
                        };

                        switch (this._transport) {
                            case TransportTypes.Xhr:
                                consoleInfo("pollymer: Using XHR transport.");
                                this._xhr = this._startXhr(method, url, headers, body);
                                break;
                            case TransportTypes.Jsonp:
                                consoleInfo("pollymer: Using JSONP transport.");
                                this._jsonp = this._startJsonp(method, url, headers, body);
                                break;
                            default:
                                consoleError("pollymer: Invalid transport.");
                                break;
                        }
                    }
                }, {
                    key: '_cleanupConnect',
                    value: function _cleanupConnect(abort) {
                        clearTimeout(this._timer);
                        this._timer = null;

                        switch (this._transport) {
                            case TransportTypes.Xhr:
                                consoleInfo("pollymer: XHR cleanup");
                                this._cleanupXhr(this._xhr, abort);
                                this._xhr = null;
                                break;
                            case TransportTypes.Jsonp:
                                consoleInfo("pollymer: json-p " + this._jsonp.id + " cleanup");
                                this._cleanupJsonp(this._jsonp, abort);
                                this._jsonp = null;
                                break;
                        }
                    }
                }, {
                    key: 'abort',
                    value: function abort() {
                        this._cleanupConnect(true);
                    }
                }, {
                    key: 'on',
                    value: function on(type, handler) {
                        return this._events.on(type, handler);
                    }
                }, {
                    key: 'off',
                    value: function off(type, handler) {
                        this._events.off(type, handler);
                    }
                }, {
                    key: '_startXhr',
                    value: function _startXhr(method, url, headers, body) {
                        var xhr = new global.XMLHttpRequest();

                        // If header has Authorization, and cors is available, then set the
                        // withCredentials flag.
                        if (this.withCredentials && corsAvailable) {
                            xhr.withCredentials = true;
                        }

                        var self = this;
                        xhr.onreadystatechange = function () {
                            self._xhrCallback();
                        };
                        xhr.open(method, url, true);

                        for (var key in headers) {
                            if (headers.hasOwnProperty(key)) {
                                xhr.setRequestHeader(key, headers[key]);
                            }
                        }

                        xhr.send(body);

                        consoleInfo("pollymer: XHR start " + url);

                        return xhr;
                    }
                }, {
                    key: '_cleanupXhr',
                    value: function _cleanupXhr(xhr, abort) {
                        if (xhr != null) {
                            xhr.onreadystatechange = emptyMethod;
                            if (abort) {
                                xhr.abort();
                            }
                        }
                    }
                }, {
                    key: '_xhrCallback',
                    value: function _xhrCallback() {
                        var xhr = this._xhr;
                        if (xhr != null && xhr.readyState === 4) {
                            consoleInfo("pollymer: XHR finished");

                            var code = xhr.status;
                            var reason = xhr.statusText;
                            var headers = parseResponseHeaders(xhr.getAllResponseHeaders());
                            var body = xhr.responseText;

                            this._handleResponse(code, reason, headers, body);
                        }
                    }
                }, {
                    key: '_getJsonpCallbacks',
                    value: function _getJsonpCallbacks() {
                        // Jsonp mode means we are safe to use window
                        // (Jsonp only makes sense in the context of a DOM anyway)
                        if (!(jsonpGuid in global)) {
                            global[jsonpGuid] = {
                                id: 0,
                                requests: {},
                                getJsonpCallback: function getJsonpCallback(id) {
                                    var cb;
                                    var requests = this.requests;
                                    if (id in this.requests) {
                                        cb = function (result) {
                                            requests[id]._jsonpCallback(result);
                                        };
                                    } else {
                                        consoleInfo("no callback with id " + id);
                                        cb = emptyMethod;
                                    }
                                    return cb;
                                },
                                addJsonpCallback: function addJsonpCallback(id, obj) {
                                    this.requests[id] = obj;
                                },
                                removeJsonpCallback: function removeJsonpCallback(id) {
                                    delete this.requests[id];
                                },
                                newCallbackInfo: function newCallbackInfo() {
                                    var callbackInfo = {
                                        id: "cb-" + this.id,
                                        scriptId: "pd-jsonp-script-" + this.id
                                    };
                                    this.id++;
                                    return callbackInfo;
                                }
                            };
                        }

                        return global[jsonpGuid];
                    }
                }, {
                    key: '_startJsonp',
                    value: function _startJsonp(method, url, headers, body) {
                        var jsonpCallbacks = this._getJsonpCallbacks();
                        var jsonp = jsonpCallbacks.newCallbackInfo();

                        var paramList = ["callback=" + encodeURIComponent('window["' + jsonpGuid + '"].getJsonpCallback("' + jsonp.id + '")')];

                        if (method != "GET") {
                            paramList.push("_method=" + encodeURIComponent(method));
                        }
                        if (headers) {
                            paramList.push("_headers=" + encodeURIComponent(JSON.stringify(headers)));
                        }
                        if (body) {
                            paramList.push("_body=" + encodeURIComponent(body));
                        }
                        var params = paramList.join("&");

                        var src = url.indexOf("?") != -1 ? url + "&" + params : url + "?" + params;

                        jsonpCallbacks.addJsonpCallback(jsonp.id, this);
                        addJsonpScriptToDom(src, jsonp.scriptId);

                        consoleInfo("pollymer: json-p start " + jsonp.id + " " + src);

                        return jsonp;
                    }
                }, {
                    key: '_cleanupJsonp',
                    value: function _cleanupJsonp(jsonp, abort) {
                        var jsonpCallbacks = this._getJsonpCallbacks();

                        if (jsonp != null) {
                            jsonpCallbacks.removeJsonpCallback(jsonp.id);
                            removeJsonpScriptFromDom(jsonp.scriptId);
                        }
                    }
                }, {
                    key: '_jsonpCallback',
                    value: function _jsonpCallback(result) {
                        consoleInfo("pollymer: json-p " + this._jsonp.id + " finished");

                        var code = "code" in result ? result.code : 0;
                        var reason = "reason" in result ? result.reason : null;
                        var headers = "headers" in result ? result.headers : {};
                        var body = "body" in result ? result.body : null;

                        this._handleResponse(code, reason, headers, body);
                    }
                }, {
                    key: '_handleResponse',
                    value: function _handleResponse(code, reason, headers, body) {
                        this._cleanupConnect();

                        if ((code == 0 || checkForErrorCode(this.errorCodes, code)) && (this.maxTries == -1 || this._tries < this.maxTries)) {
                            this._retry();
                        } else {
                            if (code > 0) {
                                var result;
                                if (this.rawResponse) {
                                    result = body;
                                } else {
                                    try {
                                        result = JSON.parse(body);
                                    } catch (e) {
                                        result = body;
                                    }
                                }
                                this._finished(code, result, headers);
                                if (this.recurring && code >= 200 && code < 300) {
                                    this._start();
                                }
                            } else {
                                this._error(ErrorTypes.TransportError);
                            }
                        }
                    }
                }, {
                    key: '_timeout',
                    value: function _timeout() {
                        this._cleanupConnect(true);

                        if (this.maxTries == -1 || this._tries < this.maxTries) {
                            this._retry();
                        } else {
                            this._error(ErrorTypes.TimeoutError);
                        }
                    }
                }, {
                    key: '_finished',
                    value: function _finished(code, result, headers) {
                        this._delayNext = true;
                        this._events.trigger('finished', this, code, result, headers);
                    }
                }, {
                    key: '_error',
                    value: function _error(reason) {
                        this._delayNext = true;
                        this._events.trigger('error', this, reason);
                    }
                }]);

                return Request;
            })();

            _export('default', Request);
        }
    };
});
____DOLLAR______System.register('3d', ['38', '39', '3c'], function (_export) {
  'use strict';

  var ErrorTypes, TransportTypes, Request;
  return {
    setters: [function (_) {
      ErrorTypes = _['default'];
    }, function (_2) {
      TransportTypes = _2['default'];
    }, function (_c) {
      Request = _c['default'];
    }],
    execute: function () {
      _export('default', { Request: Request, ErrorTypes: ErrorTypes, TransportTypes: TransportTypes });
    }
  };
});
____DOLLAR______System.register('1', ['3d'], function (_export) {
  'use strict';

  var Pollymer;
  return {
    setters: [function (_d) {
      Pollymer = _d['default'];
    }],
    execute: function () {

      window.Pollymer = Pollymer;
    }
  };
});
})
(function(factory) {
  factory();
});