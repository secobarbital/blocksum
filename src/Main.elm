import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode

main =
  Html.program
  { init = init
  , update = update
  , view = view
  , subscriptions = subscriptions
  }

-- MODEL --

type alias Model =
  { ethPrice : Maybe Float
  , ethAddresses : List String
  , formAddress : String
  }

-- UPDATE --

type Msg = AddAddress
  | TypeAddress String

update : Msg -> Model -> (Model, Cmd Msg)
update msg { ethPrice, ethAddresses, formAddress } =
  case msg of
    AddAddress ->
      (Model ethPrice (formAddress :: ethAddresses) "", Cmd.none)
    TypeAddress address ->
      (Model ethPrice ethAddresses address, Cmd.none)

-- VIEW --

formatPrice : Maybe Float -> String
formatPrice price =
  case price of
    Nothing ->
      "loading..."
    Just x ->
      toString x

formatAddress : String -> Html Msg
formatAddress address =
  li [] [ text address ]

view : Model -> Html Msg
view { ethPrice, ethAddresses, formAddress } =
  div []
    [ h1 [] [ text "Blocksum" ]
    , h2 [] [ text ("Price: " ++ (formatPrice ethPrice)) ]
    , ol [] (List.map formatAddress ethAddresses)
    , Html.form [ onSubmit AddAddress ]
      [ input [ name "address", value formAddress, onInput TypeAddress ] []
      , input [ type_ "submit", name "Submit" ] []
      ]
    ]

-- SUBSCRIPTIONS --

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- INIT --

init : (Model, Cmd Msg)
init =
  (Model Nothing [] "", Cmd.none)
