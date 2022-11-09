port module Editor exposing (..)

import Ace

import Browser
import Html exposing (Html, div, p, pre, text, button, input, label, iframe, br)
import Html.Attributes exposing (class, id, type_, value, for, src)
import Html.Lazy exposing (lazy)
import Json.Encode exposing (Value)

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
port fromJS : (Value -> msg) -> Sub msg

-- MODEL

type alias Model = 
  { ace : Ace.Model
  }

init : String -> ( Model, Cmd Msg )
init content =
  ( { ace = Ace.init content }
  , toJS content
  )

-- UPDATE

type Msg
  = OnAce Ace.Msg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    OnAce aceMsg ->
      ( { model | ace = Ace.update aceMsg model.ace }
      , Cmd.none
      )

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Ace.subscriptions >> OnAce |> fromJS

-- VIEW

view : Model -> Html Msg
view model =
  div [ id "main-container" ]
    [ div [ class "panel" ] <| viewParameters model
    , Html.map OnAce <| lazy (\_ -> Ace.view) ()
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
  , div [ id "preview" ] [ p [] [ text "Loading..." ] ]
  ]