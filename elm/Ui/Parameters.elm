module Ui.Parameters exposing
  ( Model
  , Msg
  , init
  , update
  , view
  )

import Interprop exposing (toJs)
import Interprop.Websocket as Ws

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick)

import Json.Encode

-- TYPES

type Tab
  = LaTeXParams
  | FileTree

-- MODEL

type alias Model =
  { selectedTab : Tab
  }

init : Model
init = { selectedTab = LaTeXParams }

-- UPDATE

type Msg
  = SelectTab Tab
  | Ping -- easter egg

update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
  case msg of
    SelectTab tab ->
      ( { model | selectedTab = tab }
      , Cmd.none
      )

    Ping ->
      ( model
      , Ws.sendObj
          [ ("usr", Json.Encode.string "PP")
          , ("msg", Json.Encode.string "ping")
          ]
            |> toJs
      )

-- VIEW

view : Model -> Html Msg
view model = Html.div [ Attr.id "params" ]
              [ Html.div [ Attr.id "tabitems" ]
                  [ Html.img
                      [ Attr.id "pastex_icon"
                      , Attr.class "tabitem"
                      , Attr.src "/static/favicon.ico"
                      , Attr.width 24
                      , Attr.height 24
                      , onClick Ping
                      ] [ ]
                  , Html.button (tabHtmlAttributes model FileTree)    [ Html.text "Files" ]
                  , Html.button (tabHtmlAttributes model LaTeXParams) [ Html.text "LaTeX" ]
                  ]
              , Html.div [ Attr.id "files"
                    , Attr.class "tabcontent"
                    , Attr.style "display" (tabDisplayValue model FileTree)
                    ]
                [ Html.text "Files"

                ]

              , Html.div [ Attr.id "latex"
                    , Attr.class "tabcontent"
                    , Attr.style "display" (tabDisplayValue model LaTeXParams)
                    ]
                [ Html.input [ Attr.id "radio1", Attr.name "test", Attr.type_ "radio" ] [ ]
                , Html.label [ Attr.for "radio1" ] [ Html.text "Some option 1" ]
                , Html.br    [ ] [ ]
                , Html.input [ Attr.id "radio2", Attr.name "test", Attr.type_ "radio" ] [ ]
                , Html.label [ Attr.for "radio2" ] [ Html.text "Some option 2" ]
                , Html.br    [ ] [ ]
                , Html.br    [ ] [ ]
                , Html.input [ Attr.id "checkbox1", Attr.name "test2", Attr.type_ "checkbox" ] [ ]
                , Html.label [ Attr.for "checkbox1" ] [ Html.text "Some option 100" ]
                , Html.br    [ ] [ ]
                , Html.input [ Attr.id "checkbox2", Attr.name "test2", Attr.type_ "checkbox" ] [ ]
                , Html.label [ Attr.for "checkbox2" ] [ Html.text "Some option 101" ]
                
                ]
              ]

tabHtmlAttributes : Model -> Tab -> List (Html.Attribute Msg)
tabHtmlAttributes model tab =
  [ Attr.classList 
      [ ("tabitem", True)
      , ("active", isTabActive model tab)
      ]
  , onClick (SelectTab tab)
  ]

isTabActive : Model -> Tab -> Bool
isTabActive model tab = tab == model.selectedTab

tabDisplayValue : Model -> Tab -> String
tabDisplayValue model tab =
  if isTabActive model tab
    then "block"
    else "none"