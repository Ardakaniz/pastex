-- File architecture inspired from https://github.com/MattCheely/elm-port-examples/blob/master/websocket/app/elm/WebSocket.elm

port module Interprop exposing
  ( Type(..)
  , Msg
  , invalidMsg
  , aceMsg
  , toJs
  , fromJs
  )

import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)

-- PORTS

port fromElm : Value -> Cmd msg
port toElm : (Value -> msg) -> Sub msg

-- MSG

type Type
  = Ace
  | WebSocket
  | Invalid String

type alias Msg =
  { type_ : Type
  , tag   : Maybe String
  , content : Value
  }

invalidMsg : Maybe String -> Msg
invalidMsg inv =
  { type_   = Invalid <| Maybe.withDefault "by construction" inv
  , tag     = Nothing
  , content = Encode.null
  }

-- ACE SPECIFIC
-- Just because too few functions to have its own file

aceMsg : String -> Msg
aceMsg content =
  { type_   = Ace
  , tag     = Nothing
  , content = Encode.string content
  }

-- IO

toJs : Msg -> Cmd msg
toJs msg = encodeMsg msg |> fromElm

fromJs : (Msg -> msg) -> Sub msg
fromJs f = Sub.map f <| toElm decodeMsg

-- JSON

decodeMsg : Value -> Msg
decodeMsg val =
  case Decode.decodeValue msgDecoder val of
    Ok ok   -> ok
    Err err -> invalidMsg (Just <| Decode.errorToString err)

msgDecoder : Decoder Msg
msgDecoder =
  Decode.map3 Msg
    (Decode.field "type"    typeDecoder)
    (Decode.field "tag" Decode.string |> Decode.maybe)
    (Decode.field "content" Decode.value)

encodeMsg : Msg -> Value
encodeMsg msg = 
  Encode.object
    [ ("type", typeEncoder msg.type_)
    , ("tag"
      , case msg.tag of
          Just tag_ -> Encode.string tag_
          Nothing   -> Encode.null  
      )
    , ("content", msg.content)
    ]

typeDecoder : Decoder Type
typeDecoder =
  Decode.string
    |> Decode.map
        (\type_ ->
          case String.toLower type_ of
            "ace"       -> Ace
            "ws"        -> WebSocket
            _           -> Invalid type_
        )

typeEncoder : Type -> Value
typeEncoder type_ =
  Encode.string
    (case type_ of
        Ace         -> "ace"
        WebSocket   -> "ws"
        Invalid inv -> "[invalid] " ++ inv
    )