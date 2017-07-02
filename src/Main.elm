port module Main exposing (..)

import Dict exposing (Dict)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (usLocale)
import Json.Decode as Decode
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http

main : Program (Maybe SerializableModel) Model Msg
main =
  Html.programWithFlags
    { init = init
    , update = updateWithStorage
    , view = view
    , subscriptions = (always Sub.none)
    }

-- MODEL --

type alias Model =
  { ethPrice : Maybe Float
  , ethAddresses : List String
  , formAddress : String
  , ethBalances : Dict String Float
  }

type alias SerializableModel =
  { ethPrice : Maybe Float
  , ethAddresses : List String
  , formAddress : String
  , ethBalances : List (String, Float)
  }

emptyModel : Model
emptyModel =
  { ethPrice = Nothing
  , ethAddresses = []
  , formAddress = ""
  , ethBalances = Dict.empty
  }

serializeModel : Model -> SerializableModel
serializeModel model =
  { model | ethBalances = Dict.toList model.ethBalances }

deserializeModel : SerializableModel -> Model
deserializeModel model =
  { model | ethBalances = Dict.fromList model.ethBalances }

port setStorage : SerializableModel -> Cmd msg

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

init : Maybe SerializableModel -> (Model, Cmd Msg)
init savedModel =
  let
    model =
      savedModel
      |> Maybe.map deserializeModel
      |> Maybe.withDefault emptyModel
  in
    (model, fetchEthPrice)

-- UPDATE --

type Msg
  = AddAddress
  | DeleteAddress String
  | FetchEthPrice
  | ReceivedEthBalance String (Result Http.Error Int)
  | ReceivedEthPrice (Result Http.Error String)
  | TypeAddress String

getEthFromWei : Int -> Float
getEthFromWei wei =
  (toFloat wei) / 1000000000000000000

insertWeiBalance : String -> Int -> Dict String Float -> Dict String Float
insertWeiBalance address weiBalance ethBalances =
  Dict.insert address (getEthFromWei weiBalance) ethBalances

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    AddAddress ->
      let
        newAddresses = List.append model.ethAddresses [model.formAddress]
        newModel =
          { model |
              ethAddresses = newAddresses,
              formAddress = ""
          }
      in
        (newModel, fetchEthBalance model.formAddress)

    DeleteAddress address ->
      let
        newAddresses = List.filter ((/=) address) model.ethAddresses
        newModel = { model | ethAddresses = newAddresses }
      in
        (newModel, Cmd.none)

    FetchEthPrice ->
      (model, fetchEthPrice)

    TypeAddress address ->
      ({ model | formAddress = address }, Cmd.none)

    ReceivedEthBalance address (Ok weiBalance) ->
      let
        newBalances = insertWeiBalance address weiBalance model.ethBalances
        newModel = { model | ethBalances = newBalances }
      in
        (newModel, Cmd.none)

    ReceivedEthBalance address (Err error) ->
      case error of
        Http.BadPayload message response ->
          (model, Debug.crash ("BadPayload" ++ message))

        _ ->
          (model, Debug.crash ("Other error fetching balance for " ++ address))

    ReceivedEthPrice (Ok price) ->
      let
        newPrice = price
          |> String.toFloat
          |> Result.toMaybe
        newModel = { model | ethPrice = newPrice }
      in
        (newModel, Cmd.none)

    ReceivedEthPrice (Err _) ->
      (model, Debug.crash "Error fetching price")

updateWithStorage : Msg -> Model -> (Model, Cmd Msg)
updateWithStorage msg model =
  let
    (newModel, cmds) =
      update msg model

    serializableModel = serializeModel newModel
  in
    (newModel , Cmd.batch [ setStorage serializableModel, cmds ])

-- VIEW --

formatPrice : Maybe Float -> String
formatPrice price =
  case price of
    Nothing ->
      "loading..."

    Just x ->
      toString x

formatMaybeFloat : Maybe Float -> String
formatMaybeFloat f =
  Maybe.map (format usLocale) f
    |> Maybe.withDefault ""

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
      , td [] [ text (formatMaybeFloat balance) ]
      , td [] [ text (formatMaybeFloat value) ]
      , td [] [ button [ onClick (DeleteAddress address) ] [ text "Delete" ] ]
      ]

formatAddresses : Maybe Float -> Dict String Float -> List String -> List (Html Msg)
formatAddresses price balances addresses =
  List.map (formatAddress price balances) addresses

view : Model -> Html Msg
view { ethPrice, ethAddresses, formAddress, ethBalances } =
  div []
    [ h1 [] [ text "Blocksum" ]
    , h2 []
      [ text ("Price: " ++ (formatPrice ethPrice))
      , button [ onClick FetchEthPrice ] [ text "fetch" ]
      ]
    , table [] (formatAddresses ethPrice ethBalances ethAddresses)
    , Html.form [ onSubmit AddAddress ]
      [ input [ name "address", value formAddress, onInput TypeAddress ] []
      , input [ type_ "submit", name "Submit" ] []
      ]
    ]
