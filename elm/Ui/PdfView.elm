module Ui.PdfView exposing
  ( Model
  , Msg(..)
  , init
  , update
  , view
  )

import Http
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick)

-- MODEL

type Status
  = Loading
  | Fetching
  | Fetched
  | Compiling

type alias Model =
  { status : Status
  }

init : ( Model, Cmd Msg )
init =
  ( { status = Loading
    }
  , fetch
  )

-- UPDATE

type Msg
  = OnStartFetching
  | OnFetchComplete (Result Http.Error ())

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    OnStartFetching ->
      ( model
      , fetch
      )

    OnFetchComplete _ ->
      ( { model | status = Fetched } 
      , Cmd.none
      ) 

fetch : Cmd Msg
fetch =
  Http.get
    { url = "view"
    , expect = Http.expectWhatever OnFetchComplete
    }

-- VIEW

view : Model -> Html Msg
view model = Html.div [ Attr.id "pdfview", Attr.class "panel" ]
              [ Html.h3  [ ] [ Html.text "PDF Preview" ]
              , Html.button [ Attr.id "compile_btn", onClick OnStartFetching ] [ Html.text "Compile..." ]
              , Html.div [ Attr.id "loading_msg"] [ Html.text (statusToStr model.status) ]
              , Html.div [ Attr.id "preview", Attr.style "display" "none" ] [ ]
              ]

statusToStr : Status -> String
statusToStr status =
  case status of
    Loading   -> "Loading..."
    Fetching  -> "Loading..."
    Fetched   -> "Complete."
    Compiling -> "Compiling..."