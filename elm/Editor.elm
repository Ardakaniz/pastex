port module Editor exposing (..)

import Ace
import Parameters as Params
import PdfView

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
  { ace     : Ace.Model
  , params  : Params.Model
  , pdfView : PdfView.Model
  }

init : String -> ( Model, Cmd Msg )
init content =
  ( { ace     = Ace.init content
    , params  = Params.init
    , pdfView = PdfView.init
    }
  , toJS content
  )

-- UPDATE

type Msg
  = OnAce     Ace.Msg
  | OnParams  Params.Msg
  | OnPdfView PdfView.Msg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    OnAce aceMsg ->
      ( { model | ace = Ace.update aceMsg model.ace }
      , Cmd.none
      )

    OnParams paramsMsg ->
      ( { model | params = Params.update paramsMsg model.params }
      , Cmd.none
      )

    OnPdfView pdfViewMsg ->
      ( { model | pdfView = PdfView.update pdfViewMsg model.pdfView }
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
    [ Html.map OnParams  <| lazy Params.view model.params
    , Html.map OnAce     <| lazy (\_ -> Ace.view) ()
    , Html.map OnPdfView <| lazy PdfView.view model.pdfView
    ]