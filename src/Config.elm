module Config exposing (maxIngredients, palette, title)

import Color
import Widget.Material as Material exposing (Palette, defaultPalette)


maxIngredients : Int
maxIngredients =
    3


palette : Palette
palette =
    { defaultPalette
        | primary = Color.rgb255 36 25 9
    }


title : String
title =
    "Quick Chef"
