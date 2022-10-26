module Ace exposing (Action(..), Pos, Msg, changeDecoder)

import Json.Encode exposing (Value)
import Json.Decode as JD

type Action
  = Insert
  | Remove

type alias Pos =
  { row : Int
  , col : Int
  }

type alias Msg =
  { start : Pos
  , end   : Pos
  , lines : List String
  , action : Action
  }

-- Json Decoders
changeDecoder : JD.Decoder Msg
changeDecoder =
  JD.map4 Msg
    (JD.field "start"  posDecoder)
    (JD.field "end"    posDecoder)
    (JD.field "lines"  <| JD.list JD.string)
    (JD.field "action" actionDecoder)

posDecoder : JD.Decoder Pos
posDecoder =
  JD.map2 Pos
    (JD.field "row" JD.int)
    (JD.field "column" JD.int)

actionDecoder : JD.Decoder Action
actionDecoder =
  JD.string
    |> JD.andThen (\action ->
      case action of
        "insert" -> JD.succeed Insert
        "remove" -> JD.succeed Remove
        _        -> JD.fail <| "Unknown action '" ++ action ++ "'"
      )
