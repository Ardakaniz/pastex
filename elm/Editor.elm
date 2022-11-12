module Editor exposing (..)

import Ui.Ace
import Ui.Chat
import Ui.Parameters
import Ui.PdfView
import Interprop exposing (toJs)
import Interprop.Websocket as Ws

import Browser
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Lazy exposing (lazy)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)

-- MAIN

main : Program String Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model = 
  { ace     : Ui.Ace.Model
  , params  : Ui.Parameters.Model
  , pdfView : Ui.PdfView.Model
  , chat    : Ui.Chat.Model
  }

init : String -> ( Model, Cmd Msg )
init original =
  let
    ( ace, aceCmd ) = Ui.Ace.init original
    ( pdfview, pdfviewCmd ) = Ui.PdfView.init 
  in
  ( { ace     = ace
    , params  = Ui.Parameters.init
    , pdfView = pdfview
    , chat    = Ui.Chat.init "You"
    }
  , Cmd.batch
      [ aceCmd
      , Cmd.map OnPdfViewMsg pdfviewCmd
      , Ws.connectWith (Encode.string "World!") |> toJs
      ]
  )

-- UPDATE

type Msg
  = OnAceMsg     Ui.Ace.Msg
  | OnChatMsg    Ui.Chat.Msg
  | OnParamsMsg  Ui.Parameters.Msg
  | OnPdfViewMsg Ui.PdfView.Msg
  | OnWsMsg      (Maybe String) Value
  | OnInvalidInterprop String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    OnAceMsg aceMsg ->
      let
        new = Ui.Ace.update aceMsg model.ace 
      in
        noCmd { model | ace = new }
    
    OnChatMsg chatMsg ->
      let
        ( new, chatCmd ) = Ui.Chat.update chatMsg model.chat
      in
        ( { model | chat = new }
        , Cmd.map OnChatMsg chatCmd
        )
    OnParamsMsg paramsMsg ->
      let
        ( new, paramsCmd ) = Ui.Parameters.update paramsMsg model.params
      in
        ( { model | params = new }
        , Cmd.map OnParamsMsg paramsCmd
        )

    OnPdfViewMsg pdfViewMsg ->
      let
        ( pdfView, pdfViewCmd ) = Ui.PdfView.update pdfViewMsg model.pdfView              
      in
        ( { model | pdfView = pdfView }
        , Cmd.map OnPdfViewMsg pdfViewCmd
        )
      
    OnWsMsg tag content ->
      case tag of
        Just tag_ ->
          case tag_ of -- TODO
            "connected" -> noCmd model
            "closed"    -> noCmd model 
            "chatMsg"   -> noCmd model -- Should NOT happen...
            _    -> noCmd model
        Nothing  -> noCmd model

    OnInvalidInterprop type_ -> ( model, Cmd.none )

noCmd : Model -> ( Model, Cmd msg )
noCmd model = ( model, Cmd.none )

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Interprop.fromJs
    (\data ->
      case data.type_ of
        Interprop.Ace       -> OnAceMsg (Ui.Ace.decodeChanges data.content)
        Interprop.WebSocket ->
          case data.tag of
            Just tag ->
              case tag of
                "chatMsg" -> 
                  OnChatMsg -- TODO: wrap into a function
                    <| Ui.Chat.OnRecv
                      ((Decode.decodeValue (Decode.field "usr" Decode.string) data.content) |> Result.withDefault "unkownn")
                      ((Decode.decodeValue (Decode.field "msg" Decode.string) data.content) |> Result.withDefault "invalid")

                _         -> OnWsMsg data.tag data.content
            Nothing       -> OnWsMsg data.tag data.content
          
        Interprop.Invalid inv -> OnInvalidInterprop inv
    )

-- VIEW

view : Model -> Html Msg
view model =
  Html.node "main" [ ]
    [ Html.div [ Attr.class "flex-below", Attr.class "side-panel" ]
        [ Html.map OnParamsMsg <| 
            lazy Ui.Parameters.view model.params
        , Html.div [ Attr.class "panel-sep" ] [ ]
        , Html.map OnChatMsg <|
            lazy Ui.Chat.view model.chat
        ] 
    , Html.map OnAceMsg     <| lazy (\_ -> Ui.Ace.view) ()
    , Html.div [ Attr.class "side-panel" ]
        [ Html.map OnPdfViewMsg <|
            lazy Ui.PdfView.view model.pdfView
        ]
    ]