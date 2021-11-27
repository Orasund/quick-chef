module Backend exposing (..)

import Bridge exposing (ToBackend(..))
import Config
import Data.Base as Base
import Data.Chef as Chef
import Data.Dish as Dish
import Data.Ingredient as Ingredient exposing (Ingredient)
import Data.Property as Property
import Dict
import Gen.Msg
import Html exposing (a)
import Lamdera exposing (ClientId, SessionId)
import Random exposing (Generator)
import Random.List
import Set
import Set.Any as AnySet
import Task
import Types exposing (BackendModel, BackendMsg(..), ToFrontend(..))


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \m -> Sub.none
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { chef =
            { startWith = Nothing
            , include = []
            , exclude = []
            , bases = ( Base.rice, [] )
            }
      , seed = Random.initialSeed 42
      , avaiableIngredients =
            [ Ingredient.new "Erbsen" [ Property.vegetable, Property.beans ]
            , Ingredient.new "Thunfish" [ Property.fish ]
            , Ingredient.new "Linsen" [ Property.beans ]
            , Ingredient.new "Roten Bohnen" [ Property.carb, Property.beans ]
            , Ingredient.new "Ei" [ Property.carb ]
            , Ingredient.new "Brokkoli" [ Property.vegetable ]
            , Ingredient.new "Mais" [ Property.vegetable ]
            , Ingredient.new "Pilze" [ Property.carb ]
            , Ingredient.new "Tomaten" [ Property.vegetable ]
            , Ingredient.new "Salat" [ Property.vegetable ]
            , Ingredient.new "Feta" [ Property.sauce ]
            , Ingredient.new "Pesto" [ Property.sauce ]
            , Ingredient.new "Sauerrahm" [ Property.sauce ]
            , Ingredient.new "Tofu" [ Property.carb ]
            ]
                |> List.map (\ingredients -> ( ingredients.name, ingredients ))
                |> Dict.fromList
      }
    , Random.independentSeed |> Random.generate NewSeed
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        NewSeed seed ->
            ( { model | seed = seed }, Cmd.none )


syncIngredients : ClientId -> Model -> Cmd msg
syncIngredients clientId model =
    model.avaiableIngredients
        |> GotIngredientList
        |> Lamdera.sendToFrontend clientId


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        RemoveIngredient ingredient ->
            let
                newModel =
                    { model
                        | avaiableIngredients = model.avaiableIngredients |> Dict.remove ingredient
                    }
            in
            ( newModel
            , syncIngredients clientId newModel
            )

        SyncIngredients ->
            ( model
            , syncIngredients clientId model
            )

        StartCooking ->
            case Chef.list of
                head :: tail ->
                    let
                        ( chef, seed ) =
                            model.seed
                                |> Random.step
                                    (tail
                                        |> Random.uniform head
                                    )
                    in
                    ( { model | seed = seed }
                    , model.avaiableIngredients
                        |> NewChef chef
                        |> Lamdera.sendToFrontend clientId
                    )

                [] ->
                    ( model
                    , NoDishFound
                        |> Lamdera.sendToFrontend clientId
                    )
