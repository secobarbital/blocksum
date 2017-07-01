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
  | DeleteAddress String
  | FetchEthPrice
  | ReceivedEthPrice (Result Http.Error String)
  | TypeAddress String

update : Msg -> Model -> (Model, Cmd Msg)
update msg { ethPrice, ethAddresses, formAddress } =
  case msg of
    AddAddress ->
      (Model ethPrice (List.append ethAddresses [formAddress]) "", Cmd.none)

    DeleteAddress address ->
      (Model ethPrice (List.filter ((/=) address) ethAddresses) formAddress, Cmd.none)

    FetchEthPrice ->
      (Model ethPrice ethAddresses formAddress, fetchEthPrice)

    TypeAddress address ->
      (Model ethPrice ethAddresses address, Cmd.none)

    ReceivedEthPrice (Ok price) ->
      (Model (Result.toMaybe (String.toFloat price)) ethAddresses formAddress, Cmd.none)

    ReceivedEthPrice (Err _) ->
      (Model ethPrice ethAddresses formAddress, Cmd.none)

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
  li []
    [ span [] [ text address ]
    , button [ onClick (DeleteAddress address) ] [ text "Delete" ]
    ]

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

decodeEthPrice : Decode.Decoder String
decodeEthPrice =
  Decode.at [ "0", "price_usd" ] Decode.string

fetchEthPrice : Cmd Msg
fetchEthPrice =
  Http.send ReceivedEthPrice (Http.get "https://api.coinmarketcap.com/v1/ticker/ethereum/" decodeEthPrice)

init : (Model, Cmd Msg)
init =
  (Model Nothing [] "", fetchEthPrice)
