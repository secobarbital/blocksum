import Dict exposing (Dict)
import Json.Decode as Decode
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http

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
  , ethBalances : Dict String Float
  }

-- UPDATE --

type Msg = AddAddress
  | DeleteAddress String
  | FetchEthPrice
  | ReceivedEthBalance String (Result Http.Error Int)
  | ReceivedEthPrice (Result Http.Error String)
  | TypeAddress String

update : Msg -> Model -> (Model, Cmd Msg)
update msg { ethPrice, ethAddresses, formAddress, ethBalances } =
  case msg of
    AddAddress ->
      (Model ethPrice (List.append ethAddresses [formAddress]) "" ethBalances, (fetchEthBalance formAddress))

    DeleteAddress address ->
      (Model ethPrice (List.filter ((/=) address) ethAddresses) formAddress ethBalances, Cmd.none)

    FetchEthPrice ->
      (Model ethPrice ethAddresses formAddress ethBalances, fetchEthPrice)

    TypeAddress address ->
      (Model ethPrice ethAddresses address ethBalances, Cmd.none)

    ReceivedEthBalance address (Ok weiBalance) ->
      let
        ethBalance =
          (toFloat weiBalance) / 1000000000000000000

        newBalances =
          Dict.insert address ethBalance ethBalances

      in
        (Model ethPrice ethAddresses formAddress newBalances, Cmd.none)

    ReceivedEthBalance address (Err error) ->
      case error of
        Http.BadPayload message response ->
          Debug.crash message

        _ ->
          Debug.crash "OTHER ERROR"

    ReceivedEthPrice (Ok price) ->
      (Model (Result.toMaybe (String.toFloat price)) ethAddresses formAddress ethBalances, Cmd.none)

    ReceivedEthPrice (Err _) ->
      (Model ethPrice ethAddresses formAddress ethBalances, Cmd.none)

-- VIEW --

formatPrice : Maybe Float -> String
formatPrice price =
  case price of
    Nothing ->
      "loading..."

    Just x ->
      toString x

formatAddress : Maybe Float -> Dict String Float -> String -> Html Msg
formatAddress price balances address =
  let
    balance =
      Dict.get address balances

    value =
      Maybe.map2 (*) balance price

  in
    tr []
      [ td [] [ text address ]
      , td [] [ text (toString balance) ]
      , td [] [ text (toString value) ]
      , td [] [ button [ onClick (DeleteAddress address) ] [ text "Delete" ] ]
      ]

formatAddresses : Maybe Float -> Dict String Float -> List String -> List (Html Msg)
formatAddresses price balances addresses =
  List.map (formatAddress price balances) addresses

view : Model -> Html Msg
view { ethPrice, ethAddresses, formAddress, ethBalances } =
  div []
    [ h1 [] [ text "Blocksum" ]
    , h2 [] [ text ("Price: " ++ (formatPrice ethPrice)) ]
    , table [] (formatAddresses ethPrice ethBalances ethAddresses)
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
  let
    url =
      "https://api.coinmarketcap.com/v1/ticker/ethereum/"

    request =
      Http.get url decodeEthPrice
  in
    Http.send ReceivedEthPrice request

decodeEthBalance : Decode.Decoder Int
decodeEthBalance =
  Decode.field "final_balance" Decode.int

fetchEthBalance : String -> Cmd Msg
fetchEthBalance address =
  let
    url =
      "https://api.blockcypher.com/v1/eth/main/addrs/" ++ address ++ "/balance"

    request =
      Http.get url decodeEthBalance

  in
    Http.send (ReceivedEthBalance address) request

init : (Model, Cmd Msg)
init =
  (Model Nothing [] "" Dict.empty, fetchEthPrice)
