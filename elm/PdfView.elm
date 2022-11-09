module PdfView exposing
  ( Model
  , Msg
  , init
  , update
  , view
  )

import Html exposing (Html, h3, div, p, text, object)
import Html.Attributes exposing (id, class, attribute, type_, style)

-- MODEL

type alias Model =
  { 
  }

init : Model
init = { }

-- UPDATE

type Msg
  = Nop

update : Msg -> Model -> Model
update _ model =
  model

-- VIEW

view : Model -> Html Msg
view _ = div [ id "pdfview", class "panel" ]
        [ h3  [ ] [ text "PDF Preview" ]
        , div [ id "loading_msg"] [ text "Loading..." ]
        , div [ id "preview", style "display" "none" ] [ ]
        ]