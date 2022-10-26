port module Editor exposing (..)

import Ace

import Browser
import Html exposing (Html, div, p, pre, text, button, input, label, br)
import Html.Attributes exposing (class, id, type_, value, for)
import Json.Decode as JD
import Json.Encode as JE
import Array
import Html exposing (b)
import Dict exposing (insert)

-- MAIN

main : Program String Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- PORTS
port toJS : String -> Cmd msg
port fromJS : (JE.Value -> msg) -> Sub msg

-- MODEL

type alias Model = 
  { content: String
  }

init : String -> ( Model, Cmd Msg )
init content =
  ( { content = content }
  , toJS content
  )

-- UPDATE

type Msg
  = OnAceChange Ace.Msg
  | Nop

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    OnAceChange ace_msg ->
      case ace_msg.action of
          Ace.Insert ->
            let new = insertAt (unlines ace_msg.lines) ace_msg.start.row ace_msg.start.col model.content
            in
              ( { model | content = new }
              , Cmd.none
              )

          Ace.Remove ->
            let new = removeFromTo ace_msg.start.row ace_msg.start.col ace_msg.end.row ace_msg.end.col model.content
            in
              ( { model | content = new }
              , Cmd.none
              )

    Nop ->
      ( { model | content = "failed..." }
      , Cmd.none
      )

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions _ =
    fromJS (\val ->
      Result.withDefault Nop
      <| Result.map OnAceChange
      <| JD.decodeValue Ace.changeDecoder val
    )


-- VIEW

view : Model -> Html Msg
view model =
  div [ id "main-container" ]
    [ div [ class "panel" ] <| viewParameters model
    , div [ id "editor"   ] []
    , div [ class "panel" ] <| viewPdfPreview model
    ]

viewParameters : Model -> List (Html Msg)
viewParameters model
  =  labeledInput "opt1" "radio" "Option 1" ++ [ br [] [] ]
  ++ labeledInput "opt2" "radio" "Option 2" ++ [ br [] [] ]
  ++ labeledInput "opt3" "radio" "Option 3" ++ [ br [] [] ]

labeledInput : String -> String -> String -> List (Html Msg)
labeledInput ident inpType val =
  [ input [ id ident, type_ inpType ] []
  , label [ for ident ] [ text val ]
  ]

viewPdfPreview : Model -> List (Html Msg)
viewPdfPreview _ =
  [ text "PDF Preview"
  , div [ id "preview" ] []
  ]

-- UTILS

takeDrop : Int -> List a -> ( List a, List a )
takeDrop i xs =
  ( List.take i xs, List.drop i xs )

unlines : List String -> String
unlines = String.join "\n"

insertAt : String -> Int -> Int -> String -> String
insertAt src row col trgt =
  case ( row, col ) of
    ( 0, _ ) ->
      let
        ( before, after ) = takeDrop col (String.toList trgt)
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
        ( before, after ) = takeDrop fromc (String.toList trgt)
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
