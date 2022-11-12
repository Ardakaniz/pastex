module Ui.Parameters exposing
  ( Model
  , Msg(..)
  , init
  , update
  , view
  , tabItemsHeight
  )

import Interprop exposing (toJs)
import Interprop.Websocket as Ws

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick)

import Json.Encode
import Debug exposing (toString)
import String exposing (fromFloat)

-- EXT. CONSTANTS
tabItemsHeight : ( Float, String )
tabItemsHeight = ( 48.0, "px" )

-- TYPES

type Tab
  = LaTeXParams
  | FileTree

-- MODEL

type alias Model =
  { selectedTab   : Tab
  , show          : Bool
  , divHeight     : String
  }

init : String -> Model
init h =
  { selectedTab = LaTeXParams
  , show        = True
  , divHeight   = h
  }

-- UPDATE

type Msg
  = SelectTab Tab
  | Show
  | Hide
  | OnDivHeightChange String
  | Ping -- easter egg

update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
  case msg of
    SelectTab tab ->
      ( { model | selectedTab = tab }
      , Cmd.none
      )

    Show ->
      ( { model | show = True }
      , Cmd.none
      )

    Hide ->
      ( { model | show = False }
      , Cmd.none
      )

    OnDivHeightChange h ->
      ( { model | divHeight = h }
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
view model =
  Html.div
    [ Attr.id "params"
    , Attr.style "height" <| model.divHeight
    ]
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
    , Html.div
          [ Attr.id "files"
          , Attr.class "tabcontent"
          , conditionalDisplay (isTabActive model FileTree && model.show)
          ]
        [ Html.text "Files"

        ]

    , Html.div
          [ Attr.id "latex"
          , Attr.class "tabcontent"
          , conditionalDisplay (isTabActive model LaTeXParams && model.show)
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
isTabActive model tab =
  tab == model.selectedTab

conditionalDisplay : Bool -> Html.Attribute msg
conditionalDisplay b =
  Attr.style "display"
    <| if b
         then "block"
         else "none" 

lengthAsVh : Float -> String
lengthAsVh h = String.fromFloat h ++ "vh"