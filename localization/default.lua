return {
    descriptions = {
        Back = {
            b_zodiac = {
                name="Syzygy Deck",
                text={
                    "Start run with",
                    "{C:tarot,T:v_tarot_merchant}#1#{},",
                    "{C:planet,T:v_planet_merchant}#2#{},",
                    "and {C:attention,T:v_overstock_norm}#3#",
                }
            }
        },
        Other = {
            j_amaryllis_zodiac_aquarius_locked_progress = {
                name = "n",
                text = {
                    "{C:inactive}(Remaining: #1#)",
                }
            },

            j_amaryllis_zodiac_spring_water_generic = {
                name = "Spring Water",
                text = {
                    "When this Joker is created,",
                    "it gets a random ability",
                    "around a {C:attention}specific rank"
                }
            },

            pinned_left = {
                name = "Pinned",
                text = {
                    "This Joker stays",
                    "pinned to the left",
                    "and can't be moved",
                }
            },
        }
    },
    misc = {
        dictionary = {
            k_amaryllis_zodiac_randomize = "Randomized",
            k_amaryllis_zodiac_cost_up = "Cost Up",
            k_amaryllis_zodiac_blind_increased = "Score Up",
            k_amaryllis_zodiac_up_by_interest = "+Interest",


            j_amaryllis_generic_hand = "hand", j_amaryllis_generic_played = "played",
            j_amaryllis_generic_discard = "discard", j_amaryllis_generic_discarded = "discarded",
            j_amaryllis_generic_scoring = "scoring ",
            
            j_amaryllis_generic_add_chips = "{C:chips}+#2#{} Chips",
            j_amaryllis_generic_add_mult = "{C:mult}+#2#{} Mult",
            j_amaryllis_generic_add_xmult = "{X:mult,C:white}X#2#{} Mult",
            j_amaryllis_generic_gain_chips = "gain {C:chips}+#2#{} Chips",
            j_amaryllis_generic_gain_mult = "gain {C:mult}+#2#{} Mult",
            j_amaryllis_generic_gain_xmult = "gain {X:mult,C:white}X#2#{} Mult",
            j_amaryllis_generic_money = "earn {C:money}$#2#{}",
            j_amaryllis_generic_generate_tarot = "create a random {C:tarot}Tarot{} card",
            j_amaryllis_generic_generate_planet = "create a random {C:planet}Planet{} card",
            j_amaryllis_generic_generate_spectral = "create a random {C:spectral}Spectral{} card",
            j_amaryllis_generic_retrigger = "retrigger",
            j_amaryllis_generic_retrigger_times = "{C:attention}#2#{} additional times",
            j_amaryllis_generic_destroy = "destroy",

            j_amaryllis_generic_if_scored = "when played hand has a scoring {C:attention}#1#{}",
            j_amaryllis_generic_when_scored = "when each played {C:attention}#1#{} is scored",
            j_amaryllis_generic_held = "for each {C:attention}#1#{} held in hand",
            j_amaryllis_generic_discarded = "for each discarded {C:attention}#1#{}",
            j_amaryllis_generic_in_deck = "for each {C:attention}#1#{} in your full deck at end of round",

            j_amaryllis_generic_for_each_if_scored = "played hands containing a scoring {C:attention}#1#{}",
            j_amaryllis_generic_for_each_when_scored = "each scored {C:attention}#1#{}",
            j_amaryllis_generic_for_each_held = "each held in hand {C:attention}#1#{}",
            j_amaryllis_generic_for_each_discarded = "each discarded {C:attention}#1#{}",
            j_amaryllis_generic_for_each_in_deck = "each {C:attention}#1#{} in your full deck at end of round",

            j_amaryllis_generic_chance = "{C:green}#5# in #4#{} chance to",
            j_amaryllis_generic_first_time = "on the first #6# of round",
            j_amaryllis_generic_at_least = "if #6# has {C:attention}#4#{} or more {C:attention}#1#s{}",
            j_amaryllis_generic_with_other = "if #6# has a #8#card of any other rank",
            j_amaryllis_generic_resets = "{s:0.9}Resets when Blind is defeated{}",

            j_amaryllis_generic_current_chips = "{C:inactive}(Currently {C:chips}+#3#{C:inactive} Chips)",
            j_amaryllis_generic_current_mult = "{C:inactive}(Currently {C:mult}+#3#{C:inactive} Mult)",
            j_amaryllis_generic_current_xmult = "{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)",
        },
        labels = {
            amaryllis_zodiac_special = "Zodiac Deck",
        }
    }
}