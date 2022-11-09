module Parameters exposing
  ( Model
  , Msg
  , init
  , update
  , view
  )

import Html exposing (..)
import Html.Attributes exposing (..)
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
view model = div [ id "params", class "panel" ]
              [ div [ id "tabitems" ]
                  [ button (tabHtmlAttributes model FileTree)    [ text "Files" ]
                  , button (tabHtmlAttributes model LaTeXParams) [ text "LaTeX" ]
                  ]
              , div [ id "files"
                    , class "tabcontent"
                    , style "display" (tabDisplayValue model FileTree)
                    ]
                [ text "Files"

                ]

              , div [ id "latex"
                    , class "tabcontent"
                    , style "display" (tabDisplayValue model LaTeXParams)
                    ]
                [ input [ id "radio1", name "test", type_ "radio" ] [ ]
                , label [ for "radio1" ] [ text "Some option 1" ]
                , br    [ ] [ ]
                , input [ id "radio2", name "test", type_ "radio" ] [ ]
                , label [ for "radio2" ] [ text "Some option 2" ]
                , br    [ ] [ ]
                , br    [ ] [ ]
                , input [ id "checkbox1", name "test2", type_ "checkbox" ] [ ]
                , label [ for "checkbox1" ] [ text "Some option 100" ]
                , br    [ ] [ ]
                , input [ id "checkbox2", name "test2", type_ "checkbox" ] [ ]
                , label [ for "checkbox2" ] [ text "Some option 101" ]
                
                ]
              ]

tabHtmlAttributes : Model -> Tab -> List (Attribute Msg)
tabHtmlAttributes model tab =
  [ classList 
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