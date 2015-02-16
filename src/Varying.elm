module Varying
    ( Varying
    , map, map2, map3, map4, map5
    , (<~), (~)
    , smooth, smoothByReference
    , constant
    , timeOfUpdate
    ) where

{-| A *varying* value is a value that changes over time. For example, we can
think of the mouse position as a pair of numbers that is changing over time,
whenever the user moves the mouse.

    Mouse.position : Varying (Int,Int)

Another varying value is the `Element` or `Html` we want to show on screen.

    main : Varying Html

As the `Html` changes, the user sees different things on screen automatically.


# Mapping
@docs map, map2, map3, map4, map5

# Fancy Mapping
@docs (<~), (~)

# Smoothing
@docs smooth, smoothByReference

# Constant Varying
@docs constant

-}

import Basics (fst, snd, not)
import Debug
import List
import Native.Reactive
import Reactive
import Reactive (Varying)


{-| Create a varying value that never changes. This can be useful if you need
to pass a combination of varyings and normal values to a function:

    map3 view Window.dimensions Mouse.position (constant initialModel)
-}
constant : a -> Varying a
constant value =
  fromStream value Stream.never


fromStream : a -> Stream a -> Varying a
fromStream =
  Native.Reactive.streamToVarying


toStream : Varying a -> (a, Stream a)
toStream =
  Native.Reactive.varyingToStream


{-| Apply a function to a varying value.

    mouseIsUp : Varying Bool
    mouseIsUp =
        map not Mouse.isDown

    main : Varying Element
    main =
        map toElement Mouse.position
-}
map : (a -> result) -> Varying a -> Varying result
map =
  Native.Reactive.varyingMap


{-| Apply a function to the current value of two varying values. The function
is reevaluated whenever *either* varying changes. In the following example, we
figure out the `aspectRatio` of the window by combining the current width and
height.

    ratio : Int -> Int -> Float
    ratio width height =
        toFloat width / toFloat height

    aspectRatio : Varying Float
    aspectRatio =
        map2 ratio Window.width Window.height
-}
map2 : (a -> b -> result) -> Varying a -> Varying b -> Varying result
map2 func a b =
  func <~ a ~ b


map3 : (a -> b -> c -> result) -> Varying a -> Varying b -> Varying c -> Varying result
map3 func a b c =
  func <~ a ~ b ~ c


map4 : (a -> b -> c -> d -> result) -> Varying a -> Varying b -> Varying c -> Varying d -> Varying result
map4 func a b c d =
  func <~ a ~ b ~ c ~ d


map5 : (a -> b -> c -> d -> e -> result) -> Varying a -> Varying b -> Varying c -> Varying d -> Varying e -> Varying result
map5 func a b c d e =
  func <~ a ~ b ~ c ~ d ~ e


{-| Suppress updates to a varying when the new value is referentially equal to
the previous value. Since all values in Elm are immutable, we know that the
value at a specific reference is the same forever. If we see two values at the
same reference, we can know they are structurally equal without crawling the
values at all. This is super fast!

So `smooth` is useful specifically when you want to efficiently drop redundant
updates and do not mind if some structurally equal values make it through.

    model : Varying Model

    main : Varying Html
    main =
      map view (smooth model)

Note: structurally equal values *can* make it through this. For example,
updating a field to be the same value as before.
-}
smooth : Varying a -> Varying a
smooth =
  smoothWith (==)


smoothByReference : Varying a -> Varying a
smoothByReference =
  smoothWith Native.Utils.refEq


{-| An alias for `map`. A prettier way to apply a function to the current value
of a signal.

    main : Varying Html
    main =
      view <~ model

    model : Varying Model

    view : Model -> Html
-}
(<~) : (a -> b) -> Varying a -> Varying b
(<~) =
  map


{-| Intended to be paired with the `(<~)` operator, this makes it possible for
many varying values to flow into a function. Think of it as a fancy alias for
`mapN`. For example, the following declarations are equivalent:

    main : Varying Element
    main =
      scene <~ Window.dimensions ~ Mouse.position

    main : Varying Element
    main =
      map2 scene Window.dimensions Mouse.position

You can use this pattern for as many signals as you want by using `(~)` a bunch
of times, so you can go higher than `map5` if you need to.
-}
(~) : Varying (a -> b) -> Varying a -> Varying b
(~) =
  Native.Reactive.apply

