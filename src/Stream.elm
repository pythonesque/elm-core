module Stream
    ( Stream
    , map
    , merge, mergeMany
    , fold
    , filter, filterMap, dropWhen, dropRepeats
    , sample
    , never
    ) where

{-| Streams of events. Many interactions with the world can be formulated as
streams of events: mouse clicks, responses from servers, key presses, etc.

This library provides the basic building blocks for routing these streams of
events to your application logic.
-}

import Debug
import List
import Mailbox (Mailbox)
import Native.Reactive
import Reactive
import Reactive (Varying)
import Signal


type alias Input a =
    { mailbox : Mailbox a
    , stream : Stream a
    }


type alias Stream a = Reactive.Stream a


map : (a -> b) -> Stream a -> Stream b
map =
  Native.Reactive.streamMap


toVarying : a -> Stream a -> Varying a
toVarying =
  Native.Reactive.streamToVarying


fromVarying : Varying a -> (a, Stream a)
fromVarying =
  Native.Reactive.varyingToStream


{-| Merge two streams into one. This function is extremely useful for bringing
together lots of different streams to feed into a `fold`.

    type Action = MouseMove (Int,Int) | TimeDelta Float

    actions : Stream Action
    actions =
        merge
            (map MouseMove Mouse.position)
            (map TimeDelta (fps 40))

If an event comes from either of the incoming streams, it flows out the
outgoing stream. If an event comes on both streams at the same time, the left
event wins (i.e., the right event is discarded).
-}
merge : Stream a -> Stream a -> Stream a
merge =
  Native.Reactive.merge


{-| Merge many streams into one. This is useful when you are merging more than
two streams. When multiple events come in at the same time, the left-most
event wins, just like with `merge`.

    type Action = MouseMove (Int,Int) | TimeDelta Float | Click

    actions : Stream Action
    actions =
        mergeMany
            [ map MouseMove Mouse.position
            , map TimeDelta (fps 40)
            , map (always Click) Mouse.clicks
            ]
-}
mergeMany : List (Stream a) -> Stream a
mergeMany streams =
  case List.reverse signals of
    last :: rest ->
        List.foldl merge last rest

    _ ->
        Debug.crash "Signal.mergeMany needs a non-empty list."



{-| Create a past-dependent value. Each update from the incoming stream will
be used to step the state forward. The outgoing varying represents the current
state.

    clickCount : Varying Int
    clickCount =
        fold (\click total -> total + 1) 0 Mouse.clicks

    timeSoFar : Stream Time
    timeSoFar =
        fold (+) 0 (fps 40)

So `clickCount` updates on each mouse click, incrementing by one. `timeSoFar`
is the time the program has been running, updated 40 times a second.
-}
fold : (a -> b -> b) -> b -> Stream a -> Varying b
fold =
  Native.Reactive.fold


{-| Filter out some events. The given function decides whether we should
keep an update. The following example only keeps even numbers.

    numbers : Stream Int

    isEven : Int -> Bool

    evens : Stream Int
    evens =
        filter isEven numbers
-}
filter : (a -> Bool) -> Stream a -> Stream a
filter isOk stream =
  filterMap (\v -> if isOk v then Just v else Nothing) stream


filterMap : (a -> Maybe b) -> Stream a -> Stream b
filterMap =
  Native.Reactive.filterMap


dropWhen : Varying Bool -> Stream a -> Stream a



{-| Drop events that are structurally equal to the previous event.

    numbers : Signal Int

    noDups : Signal Int
    noDups =
        dropRepeats numbers

    --  numbers => 0 0 3 3 5 5 5 4 ...
    --  noDups  => 0   3   5     4 ...

The stream should not be a stream of functions, or a record that contains a
function (you'll get a runtime error since functions cannot be equated).
-}
dropRepeats : Stream a -> Stream a
dropRepeats =
  Native.Reactive.dropRepeats


{-| Sample the varying value only when we get an event on the incoming stream.
For example, the following will give a stream of click positions.

    clickPositions : Stream (Int,Int)
    clickPositions =
      sample Mouse.position Mouse.clicks
-}
sample : Varying value -> Stream a -> Stream value



never : Stream a
never =
  Native.Reactive.never


{-| Add a timestamp to any signal. Timestamps increase monotonically. When you
create `(timestamp Mouse.x)`, an initial timestamp is produced. The timestamp
updates whenever `Mouse.x` updates.

Timestamp updates are tied to individual events, so
`(timestamp Mouse.x)` and `(timestamp Mouse.y)` will always have the same
timestamp because they rely on the same underlying event (`Mouse.position`).
-}
timestamp : Stream a -> Stream (Time, a)
timestamp =
  Native.Reactive.timestamp


{-| Delay a signal by a certain amount of time. So `(delay second Mouse.clicks)`
will update one second later than any mouse click.
-}
delay : Time -> Stream a -> Stream a
delay =
  Native.Reactive.delay
