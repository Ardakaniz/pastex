module Ui.Parameters exposing
  ( Model
  , Msg
  , init
  , update
  , view
  )

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick)

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

update : Msg -> Model -> Model
update msg model =
  case msg of
    SelectTab tab ->
      { model | selectedTab = tab }

-- VIEW

view : Model -> Html Msg
view model = Html.div [ Attr.id "params", Attr.class "panel", Attr.class "splitted_bot" ]
              [ Html.div [ Attr.id "tabitems" ]
                  [ Html.button (tabHtmlAttributes model FileTree)    [ Html.text "Files" ]
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