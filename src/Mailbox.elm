module Mailbox
    ( Mailbox
    , redirect
    , send
    ) where
{-| A way to send messages to a `Stream`.
-}

import Promise (Promise)


type Mailbox a =
    Mailbox (a -> Promise () ())


{-|
-}
redirect : (b -> a) -> Mailbox a -> Mailbox b
redirect f (Mailbox send) =
    Mailbox (\x -> send (f x))


{-|
-}
send : Mailbox a -> a -> Promise x ()
send (Mailbox actuallySend) value =
    actuallySend value
