module Touch
    ( Touch, touches
    , taps
    ) where

{-| This is an early version of the touch library. It will likely grow to
include gestures that would be useful for both games and web-pages.

# Touches
@docs Touch, touches

# Gestures
@docs taps
-}

import Varying (Varying)
import Stream (Stream)
import Native.Touch
import Time (Time)

{-| Every `Touch` has `xy` coordinates. It also has an identifier
`id` to distinguish one touch from another.

A touch also keeps info about the initial point and time of contact:
`x0`, `y0`, and `t0`. This helps compute more complicated gestures
like taps, drags, and swipes which need to know about timing or direction.
-}
type alias Touch =
    { x : Int
    , y : Int
    , id : Int
    , x0 : Int
    , y0 : Int
    , t0 : Time
    }

{-| A list of ongoing touches. -}
touches : Varying (List Touch)
touches =
  Native.Touch.touches


{-| Triggers whenever the user taps the screen, showing the position of the
tap.
-}
taps : Stream (Int,Int)
taps =
  Native.Touch.taps

