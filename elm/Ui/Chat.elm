module Ui.Chat exposing
  ( Model
  , Msg(..)
  , init
  , update
  , view
  )

import Interprop exposing (toJs)
import Interprop.Websocket as Ws

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Evt
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)

-- MODEL

type alias Model =
  { usrId : String
  , input : String
  , messages : List (String, String)
  }

init : String -> Model
init id =
  { usrId = id
  , input = ""
  , messages = []
  }

-- UPDATE

type Msg
  = OnSend
  | OnInputChanged String
  | OnRecv String String -- usrName usrMsg

update : Msg -> Model -> ( Model, Cmd msg )
update msg model = 
  case msg of
      OnSend ->
        ( { model | input = "" }
        , Ws.sendObj
            [ ("usr", Encode.string model.usrId)
            , ("msg", Encode.string model.input)
            ]
              |> toJs
        )

      OnInputChanged new ->
        ( { model | input = new }
        , Cmd.none
        )

      OnRecv usrName usrMsg ->
        ( { model | messages = model.messages ++ [(usrName, usrMsg)] }
        , Cmd.none
        )

-- VIEW

view : Model -> Html Msg
view model =
  Html.div
    [ Attr.id "chat"
    , Attr.class "extend"
    , Attr.class "flex-below"
    ]
    [ Html.div [ Attr.id "chatcontent", Attr.class "extend" ]
        (List.map (\entry -> Html.div [ Attr.class "chatmsg" ] (formatMsg entry)) model.messages)
    , Html.input
        [ Attr.type_ "text"
        , Attr.placeholder "Type a message here..."
        , Evt.onInput OnInputChanged
        , Evt.on "keydown" <|
            if String.isEmpty model.input
              then Decode.fail "empty input"
              else ifIsEnter OnSend
        , Attr.value model.input
        ]
        [ ]      
    ]

-- UTILS

formatMsg : (String, String) -> List (Html msg)
formatMsg entry =
  case entry of
    (usrName, usrMsg) ->
      [ Html.span [ Attr.style "font-weight" "bold" ] [ Html.text usrName ]
      , Html.text ": "
      , Html.span [ ] [ Html.text usrMsg ]
      ]


ifIsEnter : msg -> Decoder msg
ifIsEnter msg =
  Decode.field "key" Decode.string
    |> Decode.andThen (\key -> if key == "Enter" then Decode.succeed msg else Decode.fail "invalid key" )