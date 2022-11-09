module Ace exposing
  ( Model
  , Msg
  , init
  , update
  , subscriptions
  , view
  , changeDecoder
  )

import Html exposing (Html, div)
import Html.Attributes exposing (id)

import Json.Encode exposing (Value)
import Json.Decode as JD

-- MODEL

type alias Model = 
  { content: String
  }

init : String -> Model
init content =
  { content = content }

-- UPDATE 

type Action
  = Insert
  | Remove
  | Invalid

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

invalid_msg : Msg
invalid_msg =
  { start  = { row = 0, col = 0 }
  , end    = { row = 0, col = 0 }
  , lines  = [ ]
  , action = Invalid
  }

update : Msg -> Model -> Model
update msg model =
  case msg.action of
    Insert ->
      let new = insertAt (unlines msg.lines) msg.start.row msg.start.col model.content
      in
        { model | content = new }

    Remove ->
      let new = removeFromTo msg.start.row msg.start.col msg.end.row msg.end.col model.content
      in
        { model | content = new }

    Invalid ->
      model
        
-- SUBSCRIPTIONS

subscriptions : (Value -> Msg)
subscriptions = \val ->
    JD.decodeValue changeDecoder val
      |> Result.withDefault invalid_msg

-- VIEW

view : Html Msg
view = div [ id "editor" ] []

-- UTILS

splitAt : Int -> List a -> ( List a, List a )
splitAt i xs =
  ( List.take i xs, List.drop i xs )

unlines : List String -> String
unlines = String.join "\n"

insertAt : String -> Int -> Int -> String -> String
insertAt src row col trgt =
  case ( row, col ) of
    ( 0, _ ) ->
      let
        ( before, after ) = splitAt col (String.toList trgt)
      in
        String.fromList before ++ src ++ String.fromList after

    ( _, _ ) ->
      case String.lines trgt of
        x :: xs -> x ++ "\n" ++ (insertAt src (row - 1) col (unlines xs))
        []      -> ""

removeFromTo : Int -> Int -> Int -> Int -> String -> String
removeFromTo fromr fromc tor toc trgt =
  case ( fromr, fromc, tor ) of
    ( 0, 0, 0 ) ->
      String.dropLeft toc trgt
    
    ( 0, 0, _ ) ->
      case String.lines trgt of
        x :: xs -> removeFromTo 0 0 (tor - 1) toc (unlines xs)
        []      -> ""

    ( 0, _, _ ) ->
      let
        ( before, after ) = splitAt fromc (String.toList trgt)
        new_toc =
          if tor == 0
          then toc - fromc
          else toc
      in
        String.fromList before ++ (removeFromTo 0 0 tor new_toc (String.fromList after)) 

    ( _, _, _ ) ->
      case String.lines trgt of
        x :: xs -> x ++ "\n" ++ (removeFromTo (fromr - 1) fromc (tor - 1) toc (unlines xs))
        []      -> ""


-- JSON DECODERS

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
