module Interprop.Websocket exposing
  (..
  )

import Interprop
import Json.Encode as Encode exposing (Value)

connectWith : Value -> Interprop.Msg
connectWith val =
  { type_   = Interprop.WebSocket
  , tag     = Just "connect"
  , content = val
  }

connect : Interprop.Msg
connect = connectWith Encode.null

send : Value -> Interprop.Msg
send val =
  { type_   = Interprop.WebSocket 
  , tag     = Just "send"
  , content = val
  }

sendObj : List (String, Value) -> Interprop.Msg
sendObj obj = Encode.object obj |> send

sendStr : String -> Interprop.Msg
sendStr str = Encode.string str |> send