Elm.Native.Signal = {};
Elm.Native.Signal.make = function(localRuntime) {

    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.Signal = localRuntime.Native.Signal || {};
    if (localRuntime.Native.Signal.values)
    {
        return localRuntime.Native.Signal.values;
    }

    var Utils = Elm.Native.Utils.make(localRuntime);

    function broadcastToKids(node, timestep, changed) {
        var kids = node.kids;
        for (var i = kids.length; i--; )
        {
            kids[i].recv(timestep, changed, node.id);
        }
    }


    // INPUTS

    function Input(base) {
        this.id = Utils.guid();
        this.value = base;
        this.kids = [];
        this.defaultNumberOfKids = 0;
        this.recv = function(timestep, eid, v) {
            var changed = eid === this.id;
            if (changed)
            {
                this.value = v;
            }
            broadcastToKids(this, timestep, changed);
            return changed;
        };
        localRuntime.inputs.push(this);
    }


    // MAPPING

    function LiftN(update, args) {
        this.id = Utils.guid();
        this.value = update();
        this.kids = [];

        var n = args.length;
        var count = 0;
        var isChanged = false;

        this.recv = function(timestep, changed, parentID) {
            ++count;
            if (changed)
            {
                isChanged = true;
            }
            if (count == n)
            {
                if (isChanged)
                {
                    this.value = update();
                }
                broadcastToKids(this, timestep, isChanged);
                isChanged = false;
                count = 0;
            }
        };
        for (var i = n; i--; )
        {
            args[i].kids.push(this);
        }
    }

    function map(func, a) {
        function update() {
            return func(a.value);
        }
        return new LiftN(update, [a]);
    }
    function map2(func, a, b) {
        function update() {
            return A2( func, a.value, b.value );
        }
        return new LiftN(update, [a,b]);
    }
    function map3(func, a, b, c) {
        function update() {
            return A3( func, a.value, b.value, c.value );
        }
        return new LiftN(update, [a,b,c]);
    }
    function map4(func, a, b, c, d) {
        function update() {
            return A4( func, a.value, b.value, c.value, d.value );
        }
        return new LiftN(update, [a,b,c,d]);
    }
    function map5(func, a, b, c, d, e) {
        function update() {
            return A5( func, a.value, b.value, c.value, d.value, e.value );
        }
        return new LiftN(update, [a,b,c,d,e]);
    }


    // FOLDING

    function Foldp(step, state, input) {
        this.id = Utils.guid();
        this.value = state;
        this.kids = [];

        this.recv = function(timestep, changed, parentID) {
            if (changed)
            {
                this.value = A2( step, input.value, this.value );
            }
            broadcastToKids(this, timestep, changed);
        };
        input.kids.push(this);
    }

    function foldp(step, state, input) {
        return new Foldp(step, state, input);
    }


    // FILTERING

    function DropIf(pred,base,input) {
        this.id = Utils.guid();
        this.value = pred(input.value) ? base : input.value;
        this.kids = [];
        this.recv = function(timestep, changed, parentID) {
            var chng = changed && !pred(input.value);
            if (chng)
            {
                this.value = input.value;
            }
            broadcastToKids(this, timestep, chng);
        };
        input.kids.push(this);
    }

    function dropIf(isBad, base, signal) {
        return new DropIf(isBad, base, signal);
    }

    function keepIf(isGood, base, signal) {
        function isBad(x) {
            return !isGood(x);
        }
        return new DropIf(isBad, base, signal);
    }


    function DropRepeats(input) {
        this.id = Utils.guid();
        this.value = input.value;
        this.kids = [];
        this.recv = function(timestep, changed, parentID) {
            var chng = changed && !Utils.eq(this.value,input.value);
            if (chng)
            {
                this.value = input.value;
            }
            broadcastToKids(this, timestep, chng);
        };
        input.kids.push(this);
    }

    function dropRepeats(signal) {
        return new DropRepeats(signal);
    }


    // TIME STUFF

    function Timestamp(input) {
        this.id = Utils.guid();
        this.value = Utils.Tuple2(localRuntime.timer.programStart, input.value);
        this.kids = [];
        this.recv = function(timestep, changed, parentID) {
            if (changed)
            {
                this.value = Utils.Tuple2(timestep, input.value);
            }
            broadcastToKids(this, timestep, changed);
        };
        input.kids.push(this);
    }

    function timestamp(input) {
        return new Timestamp(input);
    }

    function SampleOn(s1,s2) {
        this.id = Utils.guid();
        this.value = s2.value;
        this.kids = [];

        var count = 0;
        var isChanged = false;

        this.recv = function(timestep, changed, parentID) {
            if (parentID === s1.id)
            {
                isChanged = changed;
            }
            ++count;
            if (count == 2)
            {
                if (isChanged)
                {
                    this.value = s2.value;
                }
                broadcastToKids(this, timestep, isChanged);
                count = 0;
                isChanged = false;
            }
        };
        s1.kids.push(this);
        s2.kids.push(this);
    }

    function sampleOn(s1,s2) {
        return new SampleOn(s1,s2);
    }

    function delay(t,s) {
        var delayed = new Input(s.value);
        var firstEvent = true;
        function update(v) {
          if (firstEvent)
          {
              firstEvent = false;
              return;
          }
          setTimeout(function() {
              localRuntime.notify(delayed.id, v);
          }, t);
        }
        function first(a,b) { return a; }
        return new SampleOn(delayed, map2(F2(first), delayed, map(update,s)));
    }


    // MERGING

    function Merge(s1,s2) {
        this.id = Utils.guid();
        this.value = s1.value;
        this.kids = [];

        var next = null;
        var count = 0;
        var isChanged = false;

        this.recv = function(timestep, changed, parentID) {
            ++count;
            if (changed)
            {
                isChanged = true;
                if (parentID == s2.id && next === null)
                {
                    next = s2.value;
                }
                if (parentID == s1.id)
                {
                    next = s1.value;
                }
            }
  
            if (count == 2)
            {
                if (isChanged)
                {
                    this.value = next;
                    next = null;
                }
                broadcastToKids(this, timestep, isChanged);
                isChanged = false;
                count = 0;
            }
        };
        s1.kids.push(this);
        s2.kids.push(this);
    }

    function merge(s1,s2) {
        return new Merge(s1,s2);
    }


    // SIGNAL INPUTS

    function input(initialValue) {
        return new Input(initialValue);
    }

    function send(input, value) {
        return function() {
            localRuntime.notify(input.id, value);
        };
    }

    function subscribe(input) {
        return input;
    }


    return localRuntime.Native.Signal.values = {
        map: F2(map),
        map2: F3(map2),
        map3: F4(map3),
        map4: F5(map4),
        map5: F6(map5),
        foldp: F3(foldp),
        delay: F2(delay),
        merge: F2(merge),
        keepIf: F3(keepIf),
        dropIf: F3(dropIf),
        dropRepeats: dropRepeats,
        sampleOn: F2(sampleOn),
        timestamp: timestamp,
        input_: input,
        send: F2(send),
        subscribe: subscribe
    };
};
