module Ui.Ace exposing
  ( Model
  , Msg
  , init
  , update
  , view
  , decodeChanges
  )

import Interprop exposing (aceMsg, toJs)

import Html exposing (Html, div)
import Html.Attributes exposing (id)

import Json.Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)

-- MODEL

type alias Model = 
  { source: String
  }

init : String -> ( Model, Cmd msg )
init source =
  ( { source = source }
  , aceMsg source |> toJs -- The initial source is considered as a server change (TMP maybe)
  )

-- UPDATE 

type Action
  = Insert
  | Remove
  | Invalid

type alias Pos =
  { row : Int
  , col : Int
  }

type alias SingleMsg =
  { start : Pos
  , end   : Pos
  , lines : List String
  , action : Action
  }

type alias Msg = List SingleMsg

invalidMsg : Msg
invalidMsg =
  { start  = { row = 0, col = 0 }
  , end    = { row = 0, col = 0 }
  , lines  = [ ]
  , action = Invalid
  }
  :: []

update : Msg -> Model -> Model
update msg model =
  List.foldl updateSingle model (compactMsg msg)

compactMsg : Msg -> Msg
compactMsg msgs =
  case msgs of
    []                     -> msgs
    msg :: []              -> msgs
    msg1 :: msg2 :: others ->
      let
        merge = (msg1.action == msg2.action)
      in
        if (msg1.end.row == msg2.start.row) && (msg1.end.col + 1 == msg2.start.col)
          then 
            (if merge
              then { start  = msg1.start
                   , end    = msg2.end
                   , lines  = [ String.concat (msg1.lines ++ msg2.lines) ]
                   , action = msg1.action
                   } 
              else msg1
            ) :: compactMsg others
          else
            msg1 :: msg2 :: compactMsg others
      

updateSingle : SingleMsg -> Model -> Model
updateSingle msg model =
  case msg.action of
        Insert ->
          let
            new = insertAt (unlines msg.lines) msg.start.row msg.start.col model.source
          in
            { model | source = new }

        Remove ->
          let
            new = removeFromTo msg.start.row msg.start.col msg.end.row msg.end.col model.source
          in
            { model | source = new }

        Invalid ->
          model

-- VIEW

view : Html Msg
view = div [ id "editor" ] []

-- UTILS
isBefore : Pos -> Pos -> Bool 
isBefore lhs rhs = 
  if lhs.row < rhs.row
    then True
    else
      if lhs.col < rhs.col
        then True
        else False

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

decodeChanges : Value -> Msg
decodeChanges val
  = Decode.decodeValue changeDecoder val
    |> Result.withDefault invalidMsg

-- JSON DECODERS

changeDecoder : Decoder Msg
changeDecoder = Decode.list singleChangeDecoder

singleChangeDecoder : Decoder SingleMsg
singleChangeDecoder =
  Decode.map4 SingleMsg
    (Decode.field "start"  posDecoder)
    (Decode.field "end"    posDecoder)
    (Decode.field "lines"  <| Decode.list Decode.string)
    (Decode.field "action" actionDecoder)

posDecoder : Decoder Pos
posDecoder =
  Decode.map2 Pos
    (Decode.field "row" Decode.int)
    (Decode.field "column" Decode.int)

actionDecoder : Decoder Action
actionDecoder =
  Decode.string
    |> Decode.andThen (\action ->
      case action of
        "insert" -> Decode.succeed Insert
        "remove" -> Decode.succeed Remove
        _        -> Decode.fail <| "Unknown action '" ++ action ++ "'"
      )
