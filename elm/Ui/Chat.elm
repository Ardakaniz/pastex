module Ui.Chat exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr

view : Html msg
view =
  Html.div [ Attr.id "chat", Attr.class "panel" ]
    [ Html.input [ Attr.type_ "text", Attr.placeholder "Type a message here..." ] [ ]
    ]