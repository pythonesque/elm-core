module Time
    ( Time, millisecond, second, minute, hour
    , inMilliseconds, inSeconds, inMinutes, inHours
    , fps, fpsWhen
    , start, ticks, now, every
    ) where

{-| Library for working with time.

# Units
@docs Time, millisecond, second, minute, hour,
      inMilliseconds, inSeconds, inMinutes, inHours

# Tell Time
@docs start, ticks, now, every, everyWhen

# Frames Per Second
@docs fps, fpsWhen

-}

import Basics (..)
import Native.Time


{-| Type alias to make it clearer when you are working with time values.
Using the `Time` constants instead of raw numbers is very highly recommended.
-}
type alias Time = Float


{-| Units of time, making it easier to specify things like a half-second
`(500 * milliseconds)` without remembering Elm&rsquo;s underlying units of time.
-}
millisecond : Time
millisecond =
  1


second : Time
second =
  1000 * millisecond


minute : Time
minute =
  60 * second


hour : Time
hour =
  60 * minute


inMilliseconds : Time -> Float
inMilliseconds t =
  t


inSeconds : Time -> Float
inSeconds t =
  t / second


inMinutes : Time -> Float
inMinutes t =
  t / minute


inHours : Time -> Float
inHours t =
  t / hour


{-| Takes desired number of frames per second (FPS). The result is a stream
of time deltas that update as quickly as possible until it reaches the desired
FPS. A time delta is the time between the last frame and the current frame.

Note: Calling `fps 30` twice gives two independently running timers.
-}
fps : number -> Stream Time
fps n =
  fpsWhen n (Varying.constant True)


{-| Same as the `fps` function, but you can turn it on and off. Allows you
to do brief animations based on user input without major inefficiencies.
Think of it as an optimized version of the following.

    fpsWhen desiredFrameRate isOn =
        Stream.keepWhen isOn (fps desiredFrameRate)
-}
fpsWhen : number -> Varying Bool -> Stream Time
fpsWhen =
  Native.Time.fpsWhen


start : Time
start =
  Native.Time.start


now : Promise x Time
now =
  Native.Time.now


{-| Takes a time interval `t`. The resulting stream is the current time,
updated every `t`.

Note: Calling `ticks minute` twice gives two independently running
timers.
-}
ticks : Time -> Stream Time
ticks =
  Native.Time.every
