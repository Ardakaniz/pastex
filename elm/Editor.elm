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
    }
  , Cmd.batch
    [ aceCmd
    , Cmd.map OnPdfViewMsg pdfviewCmd
    , Ws.connectWith (Encode.string "World!") |> toJs
    ]
  )

-- UPDATE

type Msg
  = OnParamsMsg  Ui.Parameters.Msg
  | OnPdfViewMsg Ui.PdfView.Msg
  | OnChatMsg    
  | OnAceMsg     Ui.Ace.Msg -- Ace Ui has its own msg type
  | OnWsMsg      (Maybe String) Value
  | OnInvalidInterprop String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    OnParamsMsg paramsMsg ->
      noCmd { model | params = Ui.Parameters.update paramsMsg model.params }

    OnPdfViewMsg pdfViewMsg ->
      let
        ( pdfView, pdfViewCmd ) = Ui.PdfView.update pdfViewMsg model.pdfView              
      in
        ( { model | pdfView = pdfView }
        , Cmd.map OnPdfViewMsg pdfViewCmd
        )

    OnChatMsg ->
      ( model, Cmd.none )

    OnAceMsg aceMsg ->
      let
        new = Ui.Ace.update aceMsg model.ace 
      in
        noCmd { model | ace = new  }
      
    OnWsMsg tag content ->
      case tag of
        Just tag_ ->
          case tag_ of -- TODO
            "connected" -> noCmd model
            "closed"    -> noCmd model 
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
        Interprop.Ace         -> OnAceMsg (Ui.Ace.decodeChanges data.content)
        Interprop.WebSocket   -> OnWsMsg data.tag data.content
        Interprop.Invalid inv -> OnInvalidInterprop inv
    )

-- VIEW

view : Model -> Html Msg
view model =
  Html.div [ Attr.id "main-container" ]
    [ Html.map OnParamsMsg  <| lazy Ui.Parameters.view model.params
    , Html.map OnAceMsg     <| lazy (\_ -> Ui.Ace.view) ()
    , Html.map OnPdfViewMsg <| lazy Ui.PdfView.view model.pdfView
    , Html.map (\_ -> OnChatMsg) <| lazy (\_ -> Ui.Chat.view) ()
    ]