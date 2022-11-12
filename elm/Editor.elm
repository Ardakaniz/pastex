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
import Html.Events as Evt
import Html.Lazy exposing (lazy)
import Json.Decode as Decode exposing (Decoder)
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
  { ace            : Ui.Ace.Model
  , params         : Ui.Parameters.Model
  , pdfView        : Ui.PdfView.Model
  , chat           : Ui.Chat.Model
  , leftPanelSep   : LeftPanelSep
  , viewportHeight : Int
  }

type alias LeftPanelSep =
  { grabbed : Bool
  , pos     : ( Float, String ) -- ( value, unit ) 
  , bounds  : ( Float, Float )  -- ( lower, upper )
  }

init : String -> ( Model, Cmd Msg )
init original =
  let
    ( ace, aceCmd ) = Ui.Ace.init original
    ( pdfview, pdfviewCmd ) = Ui.PdfView.init 
  in
  ( { ace     = ace
    , params  = Ui.Parameters.init "50vh"
    , pdfView = pdfview
    , chat    = Ui.Chat.init "You" "50vh"
    , leftPanelSep =
        { grabbed = False
        , pos     = (50.0, "vh")
        , bounds  = (20.0, 70.0)
        }
    , viewportHeight  = 967
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
  | OnGrabLeftPanelSep Bool -- grabbed or released?
  | OnMoveLeftPanelSep Float 

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

    OnInvalidInterprop type_ ->
      noCmd model

    OnGrabLeftPanelSep grabbed ->
      let
        leftPanelSep = model.leftPanelSep 
      in
        noCmd { model
              | leftPanelSep = { leftPanelSep | grabbed = grabbed }
              }

    OnMoveLeftPanelSep y ->
      let 
        leftPanelSep   = model.leftPanelSep
        bounds         = leftPanelSep.bounds
        boundsStricter = Tuple.mapBoth (\l -> l * 0.5) (\u -> u * 1.25) bounds
        (newMsg, newHeight)
          = compare3 y boundsStricter
              (Just (OnParamsMsg Ui.Parameters.Hide), Ui.Parameters.tabItemsHeight)
              (compare3 y bounds
                (Just (OnParamsMsg Ui.Parameters.Show), posAsVh <| Tuple.first bounds)
                (Nothing,                               posAsVh <| y)
                (Just (OnChatMsg Ui.Chat.Show),         posAsVh <| Tuple.second bounds)
              )
              (Just (OnChatMsg Ui.Chat.Hide), (99.5, "vh"))
        ( newModel, newCmd )  = 
          case newMsg of
            Just m  -> update m model
            Nothing -> noCmd model
        ( params, paramsCmd ) =
          Ui.Parameters.update (Ui.Parameters.OnDivHeightChange (posToStr newHeight)) newModel.params
        ( chat,   chatCmd )   =
          Ui.Chat.update (Ui.Chat.OnDivHeightChange (subPos newHeight Ui.Parameters.tabItemsHeight)) newModel.chat
      in
        ( { model
          | params          = params
          , chat            = chat
          , leftPanelSep    = { leftPanelSep | pos = newHeight }
          }
        , Cmd.batch [ paramsCmd, chatCmd ]
        )

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
                    <| (Decode.decodeValue
                        (Decode.map2 Ui.Chat.OnRecv
                          (Decode.field "usr" Decode.string)
                          (Decode.field "msg" Decode.string)
                        )
                        data.content
                          |>  Result.withDefault (Ui.Chat.OnInvalidRecv data.content)
                        )
                _         -> OnWsMsg data.tag data.content
            Nothing       -> OnWsMsg data.tag data.content
          
        Interprop.Invalid inv -> OnInvalidInterprop inv
    )

-- VIEW

view : Model -> Html Msg
view model =
  Html.node "main" [ ]
    [ Html.div 
          [ Attr.class "flex-below"
          , Attr.class "side-panel"
          , Attr.style "user-select" -- Prevent selection when grabbing
              (if model.leftPanelSep.grabbed
                then "none"
                else "auto"
              )
          , Evt.onMouseUp (OnGrabLeftPanelSep False)
          , Evt.on "mousemove" <|
              if not model.leftPanelSep.grabbed
                then Decode.fail "not grabbed"
                else Decode.map (leftPanelSepMoved model) getMouseClientY
          ]
        [ Html.map OnParamsMsg <| 
            lazy Ui.Parameters.view model.params
        , Html.div 
            [ Attr.class "panel-sep"
            , Attr.style "top" (posToStr model.leftPanelSep.pos)
            , Evt.onMouseDown (OnGrabLeftPanelSep True)
            ] [ ]
        , Html.map OnChatMsg <|
            lazy Ui.Chat.view model.chat
        ] 
    , Html.map OnAceMsg     <| lazy (\_ -> Ui.Ace.view) ()
    , Html.div [ Attr.class "side-panel" ]
        [ Html.map OnPdfViewMsg <|
            lazy Ui.PdfView.view model.pdfView
        ]
    ]

-- UTILS

subPos : ( Float, String ) -> ( Float, String ) -> String
subPos lhs rhs =
  "calc(" ++ posToStr lhs ++ "-" ++ posToStr rhs ++ ")"

posAsVh : Float -> ( Float, String )
posAsVh val = (val, "vh")

posToStr : ( Float, String ) -> String
posToStr pos =
  case pos of
    (val, unit) -> String.fromFloat val ++ unit

compare3 : comparable -> (comparable, comparable) -> a -> a -> a -> a
compare3 x bounds ifMin ifBetween ifMax =
  let
    ( lower, upper ) = bounds
  in
    if x < lower
      then ifMin
      else 
        if x > upper
          then ifMax
          else ifBetween

leftPanelSepMoved : Model -> Float -> Msg
leftPanelSepMoved model y =
  OnMoveLeftPanelSep
    <| 100.0 * (y / (toFloat model.viewportHeight))

getMouseClientY : Decoder Float
getMouseClientY =
  Decode.field "clientY" Decode.int
    |> Decode.map toFloat