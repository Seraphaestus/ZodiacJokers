local mod = SMODS.current_mod
SMODS.Atlas{ key = "jokers", path = "jokers.png", px = 71, py = 95 }:register()
SMODS.Atlas{ key = "other", path = "other.png", px = 71, py = 95 }:register()
SMODS.Atlas{ key = "modicon", path = "icon.png", px = 32, py = 32 }:register()

SMODS.current_mod.optional_features = { post_trigger = true }

local Utils = SMODS.load_file("src/utils.lua")()
assert(Utils, "Failed to load " .. mod.prefix .. ":src/utils.lua")

amaryllis_zodiac_config = SMODS.current_mod.config
SMODS.current_mod.config_tab = function()
    return {n = G.UIT.ROOT, config = { align = "cm", padding = 0.05, colour = G.C.CLEAR }, nodes = {
        create_toggle({ label = "Enable Zodiac Deck", ref_value = "enable_deck", ref_table = amaryllis_zodiac_config }),
        create_toggle({ label = "Unlock all Zodiac Jokers", ref_value = "unlock_jokers", ref_table = amaryllis_zodiac_config }),
        create_toggle({ label = "Discover all Zodiac Jokers", ref_value = "discover_jokers", ref_table = amaryllis_zodiac_config }),
        {n = G.UIT.R, config = { padding = 0, align = "cm" }, nodes = {{
            n = G.UIT.T, config = { text = "Restart game to update settings", scale = 0.25, colour = G.C.INACTIVE, shadow = false }
        }}},
    }}
end

function reset_virgo_card()
    if not G.GAME.current_round.virgo_card then G.GAME.current_round.virgo_card = {} end
    G.GAME.current_round.virgo_card.rank = "Ace"
    G.GAME.current_round.virgo_card.suit = "Spades"
    G.GAME.current_round.virgo_card.id = 14
    local valid_virgo_cards = {}
    for k, v in ipairs(G.playing_cards) do
        if v.ability.effect ~= "Stone Card" then
            valid_virgo_cards[#valid_virgo_cards + 1] = v
        end
    end
    if valid_virgo_cards[1] then 
        local virgo_card = pseudorandom_element(valid_virgo_cards, pseudoseed("virgo" .. G.GAME.round_resets.ante))
        G.GAME.current_round.virgo_card.rank = virgo_card.base.value
        G.GAME.current_round.virgo_card.suit = virgo_card.base.suit
        G.GAME.current_round.virgo_card.id = virgo_card.base.id
    end
end

local function libra_get_balance(self, card)
    local output = {left = 0, right = 0, numbers_listed = 0}

    local index = Utils.find_index(G.jokers.cards, card)
    if index == nil then
        return output
    end
    
    for i = 1, #G.jokers.cards do
        if i ~= index then
            local side = (i < index) and "left" or "right"
            local desc = Utils.get_joker_desc(self, G.jokers.cards[i])
            desc = desc:gsub("[^-.0123456789]", " ") --Strip all characters from the descriptions except digits, - for negatives, and . for decimals
            local words = Utils.split(desc)
            for _, word in ipairs(words) do
                local number = tonumber(word)
                if number then
                    output[side] = output[side] + number
                    output.numbers_listed = output.numbers_listed + 1
                end
            end
        end
    end

    output.is_balanced = (output.left == output.right)
    output.is_approx_balanced = (math.abs(output.left - output.right) < 0.5)
    output.Xmult = math.max(output.numbers_listed, 1)

    return output
end

function incr_amaryllis_retriggered_rank(rank)
    if G.GAME.seeded or G.GAME.challenge then return end
    local stat = "c_amaryllis_retriggered_rank"
    if not G.PROFILES[G.SETTINGS.profile].career_stats[stat] then G.PROFILES[G.SETTINGS.profile].career_stats[stat] = {} end
    G.PROFILES[G.SETTINGS.profile].career_stats[stat][rank] = (G.PROFILES[G.SETTINGS.profile].career_stats[stat][rank] or 0) + 1
    G:save_settings()
end

-------------------------

SMODS.Joker{ -- Aries
    key = "aries",

    name = "Aries",
    loc_txt = {
        name = "Aries",
        text = {
            [1] = "Earn no {C:attention}interest{}",
            [2] = "At end of round, this Joker",
            [3] = "gains {C:money}$#1#{} of sell value per",
            [4] = "{C:money}$#2#{} of {C:attention}interest{} expected"
        },
        unlock = {
            [1] = "Have a Joker with at",
            [2] = "least {C:money,E:1}$20{} sell value"
        }
    },

    pos = { x = 0, y = 0 }, atlas = "jokers",

    config = {
        extra = {
            dollars_per = 2,
            interest_unit = 1,
            cancelling_interest = false,
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.dollars_per, card.ability.extra.interest_unit}}
    end,

    cost = 5, rarity = 2,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    
    update = function(self, card, dt)
        if G.STAGE == G.STAGES.RUN and card.area and card.area == G.jokers and not card.ability.extra.cancelling_interest and not G.GAME.modifiers.no_interest then
            G.GAME.modifiers.no_interest = true
            card.ability.extra.cancelling_interest = true
        end
    end,

    remove_from_deck = function(self, card, from_debuff)
        if card.ability.extra.cancelling_interest then
            G.GAME.modifiers.no_interest = false
            card.ability.extra.cancelling_interest = false
        end
    end,

    calc_dollar_bonus = function(self, card)
        local interest_earned = G.GAME.interest_amount * math.min(math.floor(G.GAME.dollars / 5), G.GAME.interest_cap / 5)
        card.ability.extra_value = (card.ability.extra_value or 0) + interest_earned
        card:set_cost()
        card_eval_status_text(card, "extra", nil, nil, nil, {message = localize("k_" .. mod.prefix .. "_up_by_interest"), colour = G.C.MONEY, delay = 1.0})
        return nil
    end,

    check_for_unlock = function(self, args)
        if args.type == "round_win" then
            for i = 1, #G.jokers.cards do
                if (G.jokers.cards[i].sell_cost or 0) >= 20 then return true end
            end
        end
    end,
}

SMODS.Joker{ -- Taurus
    key = "taurus",

    name = "Taurus",
    loc_txt = {
        name = "Taurus",
        text = {
            [1] = "This Joker gains {C:chips}+#2#{} Chips",
            [2] = "per {C:attention}consecutive{} {C:attention}Blind",
            [3] = "defeated in 1 hand",
            [4] = "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        },
        unlock = {
            [1] = "Win {C:attention,E:1}12{} consecutive",
            [2] = "rounds by playing",
            [3] = "only 1 hand",
        }
    },

    pos = { x = 1, y = 0 }, atlas = "jokers",

    config = {
        extra = {
            chips = 0,
            chips_mod = 25,
            animation = Utils.create_animation{
                sprite_pos = { x = 1, y = 0 },
                durations = {{min = 3, max = 6}, 0.1, 0.15, {min = 0.75, max = 1.5}, 0.25},
            }
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.chips, card.ability.extra.chips_mod}}
    end,

    cost = 6, rarity = 1,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    update = function(self, card, dt)
        if self.discovered or card.bypass_discovery_center then
            Utils.update_animation(self, card, dt, 1)
        end
    end,

    calculate = function(self, card, context)
        -- Add chips when evaluated
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        
        -- Increment or reset chips when blind completed
        elseif context.end_of_round and context.cardarea == G.jokers and not card.getting_sliced and not context.blueprint then
            if G.GAME.current_round.hands_played == 1 then
                card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chips_mod
                card_eval_status_text(card, "extra", nil, nil, nil, {message = localize{type="variable", key="a_chips", vars={card.ability.extra.chips}}, colour = G.C.CHIPS})
            
            elseif card.ability.extra.chips > 0 then
                card.ability.extra.chips = 0
                return {
                    card = card,
                    message = localize("k_reset")
                }
            end
        end
    end,

    check_for_unlock = function(self, args)
        if (G.PROFILES[G.SETTINGS.profile].career_stats.c_single_hand_round_streak or 0) >= 12 then
            return true
        end
    end,
}

SMODS.Joker{ -- Gemini
    key = "gemini",

    name = "Gemini",
    loc_txt = {
        name = "Gemini",
        text = {
            [1] = "After a plain {C:attention}consumable{}",
            [2] = "card is used, if you have no",
            [3] = "consumables, {C:green}#1# in #2#{} chance",
            [4] = "to create a {C:dark_edition}Negative{} copy",
            [5] = "{C:red}-#3#{} consumable slot",
        },
        unlock = {
            [1] = "Use the same consumable",
            [2] = "card twice in a row",
        }
    },

    pos = { x = 2, y = 0 }, atlas = "jokers",

    config = {
        extra = {
            odds = 2,
            slots_mod = 1,
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = { key = "e_negative_consumable", set = "Edition", config = {extra = 1}}
        return {vars = { ""..(G.GAME and G.GAME.probabilities.normal or 1), card.ability.extra.odds, card.ability.extra.slots_mod } }
    end,

    cost = 10, rarity = 3,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    add_to_deck = function(self, card, from_debuff)
        G.consumeables.config.card_limit = G.consumeables.config.card_limit - card.ability.extra.slots_mod
    end,

    remove_from_deck = function(self, card, from_debuff)
        G.consumeables.config.card_limit = G.consumeables.config.card_limit + card.ability.extra.slots_mod
    end,

    calculate = function(self, card, context)
        if context.using_consumeable and not context.consumeable.edition and
           pseudorandom("gemini_chance") < G.GAME.probabilities.normal / card.ability.extra.odds then
                G.E_MANAGER:add_event(Event({trigger = "after", func = (function()
                    if next(G.consumeables.cards) then return true end

                    local consumable = context.consumeable.config.center
                    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                    G.E_MANAGER:add_event(Event({func = (function()
                        G.E_MANAGER:add_event(Event({func = function()
                            local new_card = SMODS.create_card{ set = consumable.set, key = consumable.key, edition = "e_negative" }
                            new_card:add_to_deck()
                            G.consumeables:emplace(new_card)
                            G.GAME.consumeable_buffer = 0
                        return true end}))
                        card_eval_status_text(context.blueprint_card or card, "extra", nil, nil, nil, {message = localize("k_plus_" .. consumable.set:lower()), colour = G.C.SECONDARY_SET[consumable.set] or G.C.PURPLE})                       
                    return true end)}))
                return true end)}))
        end
    end,

    check_for_unlock = function(self, args)
        if args.type == "consumable_used_again" then
            return true
        end
    end,

}

SMODS.Joker{ -- Cancer
    key = "cancer",

    name = "Cancer",
    loc_txt = {
        name = "Cancer",
        text = {
            [1] = "Destroy {C:attention}1{} card from",
            [2] = "each discard and {X:purple,C:white} X#1# {}",
            [3] = "required chips of {C:attention}Blind{}",
        },
        unlock = {
            [1] = "Discard at least {C:attention,E:1}69{}",
            [2] = "cards in one run",
            [3] = "{C:inactive}(#1#)"
        }
    },

    pos = { x = 4, y = 0 }, atlas = "jokers",

    config = {
        extra = {
            blind_Xmult = 1.5,
            discard_idx = 0,
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = {card.ability.extra.blind_Xmult} }
    end,

    locked_loc_vars = function(self, info_queue, card)
        return { vars = {G.GAME.round_scores.cards_discarded.amt} }
    end,

    cost = 6, rarity = 3,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    calculate = function(self, card, context)
        if context.discard and not context.other_card.getting_sliced then
            local index = Utils.find_index(G.hand.highlighted, context.other_card)

            if index == 1 then
                --Select card to destroy from discard
                local to_destroy = #G.hand.highlighted == 1 and G.hand.highlighted[1] or pseudorandom_element(G.hand.highlighted, pseudoseed("cancer"))
                card.ability.extra.discard_idx = Utils.find_index(G.hand.highlighted, to_destroy)

                if card.ability.extra.discard_idx then
                    --Increase blind score
                    if G.GAME.blind then
                        Utils.ease_blind_chips({mult = card.ability.extra.blind_Xmult})
                        SMODS.juice_up_blind()
                        card_eval_status_text(context.blueprint_card or card, "extra", nil, nil, nil, {message = localize("k_" .. mod.prefix .. "_blind_increased"), colour = G.C.RED, delay = 1.0})                       
                    end

                    if #G.hand.highlighted > 1 then
                        -- Add extra pause to discard so player can see which card was destroyed
                        G.E_MANAGER:add_event(Event({trigger = "before", delay = 1 + 0.4 * #G.hand.highlighted, blockable = false, func = function() return true end }))
                    end
                end
            end

            if index == card.ability.extra.discard_idx then
                return { remove = true }
            end
        end
    end,

    check_for_unlock = function(self, args)
        if args.type == "discard_custom" and G.GAME.round_scores.cards_discarded.amt >= 69 then
            return true
        end
    end,
}

SMODS.Joker{ -- Leo
    key = "leo",

    name = "Leo",
    loc_txt = {
        name = "Leo",
        text = {
            [1] = "This Joker gains {X:mult,C:white} X#2# {} Mult for",
            [2] = "each time a Joker {C:attention}lists a hand",
            [3] = "that the played hand contains",
            [4] = "{C:inactive}(Currently {X:mult,C:white} X#1# {C:inactive} Mult)",
        },
        unlock = {
            [1] = "Win a run with multiple",
            [2] = "Jokers that list the",
            [3] = "same poker hand",
        }
    },

    pos = { x = 3, y = 0 }, atlas = "jokers",

    config = {
        extra = {
            Xmult = 1,
            Xmult_mod = 0.1,
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.Xmult_mod } }
    end,

    cost = 7, rarity = 2,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    calculate = function(self, card, context)
        --Apply xmult when evaluated
        if context.cardarea == G.jokers and context.joker_main then
            return { xmult = card.ability.extra.Xmult }
        
        --Scale when hand is played
        elseif context.before and context.cardarea == G.jokers and not context.blueprint then
            local hands = {}
            local hand_contains = {}
            for hand, data in pairs(context.poker_hands) do
                local hand_name = localize(hand, "poker_hands")
                hands[#hands + 1] = hand_name
                hand_contains[hand_name] = (next(data) ~= nil)
            end
            table.sort(hands, function(a, b) return #a > #b end) --Sorted hands means we can check, e.g. "Two Pair" before "Pair"

            local incr_count = 0
            for i = 1, #G.jokers.cards do
                local joker_desc = Utils.get_joker_desc(self, G.jokers.cards[i])
                --local display_hand
                for _, hand in ipairs(hands) do
                    --Count instances of the given hand in the description, then strip them out so they won't match further submatches
                    -- e.g. a Joker that lists "Two Pair" will only match Two Pair, Full House, etc., not Pair
                    local count
                    count, joker_desc = Utils.count_substrings(joker_desc, hand, true)
                    if count > 0 and hand_contains[hand] then  
                        incr_count = incr_count + count
                        --if not display_hand then display_hand = hand end
                    end
                end
                --if display_hand then
                --    card_eval_status_text(G.jokers.cards[i], "extra", nil, nil, nil, { message = display_hand, colour = G.C.RED })
                --end
            end

            if incr_count > 0 then
                card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_mod * incr_count
                return {
                    message = localize{type = "variable", key = "a_xmult", vars = {card.ability.extra.Xmult}},
                    colour = G.C.MULT,
                    card = card,
                    --delay = 1,
                }
            end
        end
    end,

    check_for_unlock = function(self, args)
        if args.type == "win_custom" then
            --See calculate function for comments
            local hands = {}
            for hand, _ in pairs(G.GAME.hands) do hands[hand] = 0 end
            table.sort(hands, function(a, b) return #a > #b end)

            for i = 1, #G.jokers.cards do
                local joker_desc = Utils.get_joker_desc(self, G.jokers.cards[i])
                for hand in pairs(hands) do
                    local count
                    count, joker_desc = Utils.count_substrings(joker_desc, hand, true)
                    if count > 0 then
                        hands[hand] = hands[hand] + 1
                        if hands[hand] > 1 then
                            return true
                        end
                    end
                end
            end
        end
    end,
}

SMODS.Joker{ -- Virgo
    key = "virgo",

    name = "Virgo",
    loc_txt = {
        name = "Virgo",
        text = {
            [1] = "{s:0.9,X:mult,C:white} X#1# {s:0.9} Mult, loses {s:0.9,X:mult,C:white} X#2# {s:0.9} Mult",
            [2] = "if the {C:attention}#3#{} of {V:1}#4#",
            [3] = "is drawn to hand",
            [4] =  "{s:0.8}Card changes every round",
        },
        unlock = {
            [1] = "Win a run with an",
            [2] = "equal number of each",
            [3] = "rank and of each suit"
        }
    },

    pos = { x = 5, y = 0 }, atlas = "jokers",

    config = {
        extra = {
            Xmult = 3,
            Xmult_mod = 0.15,
        }
    },

    loc_vars = function(self, info_queue, card)
        local virgo_card = G.GAME.current_round.virgo_card or { rank = "Ace", suit = "Spades", id = 14 }
        return {
            vars = {card.ability.extra.Xmult, card.ability.extra.Xmult_mod, localize(virgo_card.rank, "ranks"), localize(virgo_card.suit, "suits_plural"), colours = {G.C.SUITS[virgo_card.suit]}},
        }
    end,

    cost = 6, rarity = 2,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    calculate = function(self, card, context)
        --Apply xmult when evaluated
        if context.cardarea == G.jokers and context.joker_main then
            return { xmult = card.ability.extra.Xmult }
        
        --If matching card was drawn to hand, decrement xmult
        elseif context.amaryllis_card_placed and context.cardarea == G.hand and context.in_round and not context.blueprint then
            local card_placed = context.amaryllis_card_placed
            local virgo_card = G.GAME.current_round.virgo_card or { rank = "Ace", suit = "Spades", id = 14 }
            if card_placed:get_id() == virgo_card.id and card_placed:is_suit(virgo_card.suit) then
                card_placed:juice_up()
                
                if card.ability.extra.Xmult - card.ability.extra.Xmult_mod > 1 then
                    card.ability.extra.Xmult = card.ability.extra.Xmult - card.ability.extra.Xmult_mod
                    card_eval_status_text(card, "jokers", nil, nil, nil, { delay = 0.2, message = localize{type = "variable", key = "a_xmult_minus", vars = {card.ability.extra.Xmult_mod}}, colour = G.C.RED })
                else
                    --If xmult decreases below 1, remove joker
                    G.E_MANAGER:add_event(Event({func = function()
                        play_sound("tarot1")
                        card.T.r = -0.2
                        card:juice_up(0.3, 0.4)
                        card.states.drag.is = true
                        card.children.center.pinch.x = true
                        G.E_MANAGER:add_event(Event({trigger = "after", delay = 0.3, blockable = false, func = function()
                            G.jokers:remove_card(card)
                            card:remove()
                            card = nil
                        return true; end})) 
                    return true end }))
                end
            end
        end
    end,

    check_for_unlock = function(self, args)
        if args.type == "win_custom" then
            local rank_counts, suit_counts = {}, {}
            for _, card in ipairs(G.playing_cards) do
                rank_counts[card.base.value] = (rank_counts[card.base.value] or 0) + 1
                suit_counts[card.base.suit] = (suit_counts[card.base.suit] or 0) + 1
            end
            local rank_count, suit_count = rank_counts["Ace"], suit_counts["Spades"]
            for _, count in pairs(rank_counts) do if count ~= rank_count then return end end
            for _, count in pairs(suit_counts) do if count ~= suit_count then return end end
            return true
        end
    end,
}

SMODS.Joker{ -- Libra
    key = "libra",

    name = "Libra",
    loc_txt = {
        name = "Libra",
        text = {
            [1] = "{X:mult,C:white} X#2# {} Mult per {C:attention}listed number{} if",
            [2] = "the numbers listed on Jokers",
            [3] = "each side are {C:attention}balanced{}",
            [4] = "{C:inactive}(Currently {X:mult,C:white} X#1# {C:inactive})",
        },
        unlock = {
            [1] = "Defeat a Blind by",
            [2] = "scoring exactly the",
            [3] = "required amount",
        }
    },

    pos = { x = 6, y = 0 }, atlas = "jokers",

    config = {
        extra = {
            Xmult_per_number = 1,
        }
    },

    loc_vars = function(self, info_queue, card, recursive)
        local Xmult = recursive and 0 or 1
        local main_end = nil

        if card.area and card.area == G.jokers and not recursive then
            local balance = libra_get_balance(self, card)
            if not (balance.left == 0 and balance.right == 0) then
                if balance.is_approx_balanced then Xmult = balance.Xmult end

                local left_align, right_align = "cm", "cm"
                if not balance.is_balanced then
                    left_align = balance.left > balance.right and "bm" or "tm"
                    right_align = balance.right > balance.left and "bm" or "tm"
                end

                local symbol_color = mix_colours(balance.is_approx_balanced and G.C.GREEN or G.C.RED, G.C.JOKER_GREY, 0.8)
                local equality_symbol = balance.is_balanced and "=" or (
                                        balance.is_approx_balanced and "~=" or (
                                        balance.left < balance.right and "<" or ">"))

                local scales_height = balance.is_approx_balanced and 0.4 or 0.6
                
                main_end = {
                    {n = G.UIT.C, config = {align = "bm", minh = 0.4}, nodes = {
                        {n = G.UIT.R, config = {align = "m", padding = 0.1}, nodes = {
                            {n = G.UIT.C, config = {align = left_align, minh = scales_height}, nodes = {
                                {n = G.UIT.C, config = {align = "m", minw = 0.8, colour = G.C.JOKER_GREY, r = 0.05, padding = 0.06}, nodes = {
                                    {n = G.UIT.T, config = {text = ""..balance.left, colour = G.C.UI.TEXT_LIGHT, scale = 0.32 * 0.8}},
                                }},
                            }},
                            {n = G.UIT.C, config = {align = "cm", minh = scales_height}, nodes = {
                                {n = G.UIT.C, config = {align = "m", minw = 0.4, colour = symbol_color, r = 0.05, padding = 0.06}, nodes = {
                                    {n = G.UIT.T, config = {text = equality_symbol, colour = G.C.UI.TEXT_LIGHT, scale = 0.32}},
                                }},
                            }},
                            {n = G.UIT.C, config = {align = right_align, minh = scales_height}, nodes = {
                                {n = G.UIT.C, config = {align = "m", minw = 0.8, colour = G.C.JOKER_GREY, r = 0.05, padding = 0.06}, nodes = {
                                    {n = G.UIT.T, config = {text = ""..balance.right, colour = G.C.UI.TEXT_LIGHT, scale = 0.32 * 0.8}},
                                }},
                            }},
                        }}
                    }}
                }
            end
        end
        
        return { vars = { Xmult, card.ability.extra.Xmult_per_number }, main_end = main_end }
    end,

    cost = 7, rarity = 2,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    --Update sprite to match positional evaluation
    update = function(self, card, dt)
        if G.STAGE == G.STAGES.RUN and card.area and card.area == G.jokers then
            local balance = libra_get_balance(self, card)
            
            local sprite_pos = {x = 6, y = 0}
            if balance.is_approx_balanced then --pass
            elseif balance.left > balance.right then sprite_pos.y = 1
            elseif balance.left < balance.right then sprite_pos.y = 2 end

            if sprite_pos ~= card.children.center.sprite_pos then
                card.children.center:set_sprite_pos(sprite_pos)
            end
        end
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main then
            local balance = libra_get_balance(self, card)
            if balance.is_approx_balanced then
                return { xmult = balance.Xmult }
            end
        end
    end,

    check_for_unlock = function(self, args)
        if args.type == "round_win" and G.GAME.chips == G.GAME.blind.chips then
            return true
        end
    end,
}

SMODS.Joker{ -- Scorpio
    key = "scorpio",

    name = "Scorpio",
    loc_txt = {
        name = "Scorpio",
        text = {
            [1] = "Played cards change",
            [2] = "rank and suit after",
            [3] = "they are scored"
        },
        unlock = {
            [1] = "Use {C:tarot,E:1}Death{} at least {C:attention,E:1}13{}",
            [2] = "times across all runs",
            [3] = "{C:inactive}(#1#)"
        }
    },

    pos = { x = 7, y = 0 }, atlas = "jokers",

    cost = 6, rarity = 2,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    locked_loc_vars = function(self, info_queue, card)
        return { vars = {G.PROFILES[G.SETTINGS.profile].consumeable_usage.c_death and (G.PROFILES[G.SETTINGS.profile].consumeable_usage.c_death.count or 0) or 0} }
    end,

    calculate = function(self, card, context)
        if context.after then
            card_eval_status_text(card, "extra", nil, nil, nil, {message = localize("k_randomize"), colour = G.C.BLUE})
            G.E_MANAGER:add_event(Event({delay = 3.0, trigger = "before", func = function()
                for _, _card in ipairs(context.scoring_hand) do
                    local new_suit = _card.base.suit
                    local new_rank = _card.base.value
                    while new_suit == _card.base.suit do new_suit = pseudorandom_element(SMODS.Suits, pseudoseed("scorpio_suit")).key end
                    while new_rank == _card.base.value do new_rank = pseudorandom_element(SMODS.Ranks, pseudoseed("scorpio_rank")).key end
                    SMODS.change_base(_card, new_suit, new_rank)
                    _card:juice_up()
                end
            return true end }))
        end
    end,

    check_for_unlock = function(self, args)
        if args.type == "modify_deck" and 
        G.PROFILES[G.SETTINGS.profile].consumeable_usage.c_death and
        (G.PROFILES[G.SETTINGS.profile].consumeable_usage.c_death.count or 0) >= 13 then
                return true
        end
    end,
}

SMODS.Joker{ -- Sagittarius
    key = "sagittarius",

    name = "Sagittarius",
    loc_txt = {
        name = "Sagittarius",
        text = {
            [1] = "Copies ability",
            [2] = "of rightmost {C:attention}Joker",
            [3] = "{s:0.1}",
            [4] = "{s:0.9,C:attention}Jokers{s:0.9} are shuffled and",
            [5] = "{s:0.9}pinned at start of round",
        },
        unlock = {
            [1] = "Add {C:chips,E:1}300{} chips or more from",
            [2] = "{C:attention,E:1}Arrowhead{} in a single round",
        }
    },

    pos = { x = 8, y = 0 }, atlas = "jokers",

    config = {
        effect = "Copycat",
    },

    loc_vars = function(self, info_queue, card)
        card.ability.blueprint_compat_ui = card.ability.blueprint_compat_ui or ""
        card.ability.blueprint_compat_check = nil
        return {
            main_end = (card.area and card.area == G.jokers) and {
                {n=G.UIT.C, config={align = "bm", minh = 0.4}, nodes={
                    {n=G.UIT.C, config={ref_table = card, align = "m", colour = G.C.JOKER_GREY, r = 0.05, padding = 0.06, func = "blueprint_compat"}, nodes={
                        {n=G.UIT.T, config={ref_table = card.ability, ref_value = "blueprint_compat_ui",colour = G.C.UI.TEXT_LIGHT, scale = 0.32*0.8}},
                    }}
                }}
            } or nil
        }
    end,

    cost = 8, rarity = 3,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    add_to_deck = function(self, card, from_debuff)
        if not card.pinned then
            card:add_sticker(mod.prefix .. "_pinned", true)
        end
    end,

    update = function(self, card, dt)
        if G.STAGE == G.STAGES.RUN and card.area and card.area == G.jokers then
            local other_joker = G.jokers.cards[#G.jokers.cards]
            if other_joker and other_joker ~= card and other_joker.config.center.blueprint_compat then
                card.ability.blueprint_compat = "compatible"
            else
                card.ability.blueprint_compat = "incompatible"
            end
        end
    end,

    calculate = function(self, card, context)
        if not context.blueprint then
            -- Shuffle and pin Jokers on blind start
            if context.setting_blind and not card.getting_sliced then
                G.jokers:unhighlight_all()
                if #G.jokers.cards > 1 then
                    G.E_MANAGER:add_event(Event({delay = 0.2, trigger = "after", blocking = false, func = function()
                        -- Pin jokers
                        local to_shuffle = {}
                        local sort_ids = {}
                        for i = 1, #G.jokers.cards do
                            if not G.jokers.cards[i].pinned then
                                G.jokers.cards[i]:add_sticker(mod.prefix .. "_pinned", true)
                                G.jokers.cards[i].pinned_by_sagittarius = true
                                to_shuffle[#to_shuffle + 1] = G.jokers.cards[i]
                            end
                            sort_ids[#sort_ids + 1] = G.jokers.cards[i].sort_id
                        end
                        
                        -- Reassign sort IDs to Jokers (highest* goes to non-temp pinned, the rest to the rest)
                        -- *yeah it's fucking highest that gets sorted leftwards, jesus fucking christ
                        -- I'm going through non-trivial effort to preserve sort_id uniquity but idk if it even matters tbh
                        table.sort(sort_ids)
                        local idx = #sort_ids
                        for i = 1, #G.jokers.cards do
                            if not Utils.find_index(to_shuffle, G.jokers.cards[i]) then
                                G.jokers.cards[i].sort_id = sort_ids[idx]
                                idx = idx - 1
                            end
                        end
                        for i = 1, #G.jokers.cards do
                            if Utils.find_index(to_shuffle, G.jokers.cards[i]) then
                                G.jokers.cards[i].sort_id = sort_ids[idx]
                                idx = idx - 1
                            end
                        end

                        -- Shuffle sort IDs between the temp pinned jokers to shuffle them while pinned
                        local shuffle_jokers = function()
                            if #to_shuffle > 0 then
                                math.randomseed(pseudoseed("aajk"))
                                for i = #to_shuffle, 2, -1 do
                                    local j = math.random(i)
                                    to_shuffle[i].sort_id, to_shuffle[j].sort_id = to_shuffle[j].sort_id, to_shuffle[i].sort_id
                                end
                            end
                            G.jokers:set_ranks()
                        end
                        
                        G.E_MANAGER:add_event(Event({ func = function() shuffle_jokers(); play_sound("cardSlide1", 0.85); return true end })) 
                        delay(0.15)
                        G.E_MANAGER:add_event(Event({ func = function() shuffle_jokers(); play_sound("cardSlide1", 1.15); return true end })) 
                        delay(0.15)
                        G.E_MANAGER:add_event(Event({ func = function() shuffle_jokers(); play_sound("cardSlide1", 1); return true end }))

                    return true end }))
                end
            
            --Unpin Jokers at blind end
            elseif context.end_of_round and context.cardarea == G.jokers then
                for i = 1, #G.jokers.cards do
                    if G.jokers.cards[i].pinned_by_sagittarius then
                        G.jokers.cards[i]:remove_sticker(mod.prefix .. "_pinned")
                        G.jokers.cards[i].pinned_by_sagittarius = nil
                    end
                end
            end
        end

        local other_joker = G.jokers.cards[#G.jokers.cards]
        if other_joker and other_joker ~= card then
            context.blueprint = (context.blueprint and (context.blueprint + 1)) or 1
            context.blueprint_card = context.blueprint_card or card
            if context.blueprint > #G.jokers.cards + 1 then return end
            local other_joker_ret, trig = other_joker:calculate_joker(context)
            context.blueprint = nil; context.blueprint_card = nil
            if other_joker_ret == true then 
                return other_joker_ret 
            elseif other_joker_ret or trig then
                if not other_joker_ret then other_joker_ret = {} end
                other_joker_ret.card = context.blueprint_card or card
                other_joker_ret.colour = G.C.RED
                other_joker_ret.no_callback = true
                return other_joker_ret
            end
        end
    end,

    check_for_unlock = function(self, args)
        if args.type == "hand" and args.scoring_hand and G.jokers then
            local arrowhead_copies = 0
            local arrowhead_chips
            for i = 1, #G.jokers.cards do
                local joker = Utils.get_joker_ability(i)
                if joker.config.center.key == "j_arrowhead" then
                    arrowhead_copies = arrowhead_copies + 1
                    if not arrowhead_chips then arrowhead_chips = joker.ability.extra end
                end
            end
            if arrowhead_copies > 0 then
                local chips = 0
                for _, card in ipairs(args.scoring_hand) do
                    if card:is_suit("Spades") then
                        chips = chips + arrowhead_chips * arrowhead_copies
                        if chips >= 300 then return true end
                    end
                end
            end
        end
    end,
}

SMODS.Joker{ -- Capricorn
    key = "capricorn",

    name = "Capricorn",
    loc_txt = {
        name = "Capricorn",
        text = {
            [1] = "When any type of card is destroyed:",
            [2] = "{C:green}#1# in #2#{} chance to {C:attention}bring it back{}",
            [3] = "then {C:green}#1# in #3#{} chance to {C:attention}create a copy{}",
            [5] = "{C:inactive}(Must have room)",
        },
        unlock = {
            [1] = "Destroy a total",
            [2] = "of {C:attention,E:1}20{} Jokers",
            [3] = "{C:inactive}(#1#)"
        },
    },

    pos = { x = 9, y = 0 }, atlas = "jokers",

    config = {
        extra = {
            odds_1 = 2,
            odds_2 = 4,
        }
    },

    loc_vars = function(self, info_queue, card)
        local main_end
        if G.jokers and G.jokers.cards then
            for _, joker in ipairs(G.jokers.cards) do
                if joker.edition and joker.edition.negative and G.localization.descriptions.Other.remove_negative then 
                    main_end = {}
                    localize{type = "other", key = "remove_negative", nodes = main_end, vars = {}}
                    main_end = main_end[1]
                    break
                end
            end
        end
        return { vars = { ""..(G.GAME and G.GAME.probabilities.normal or 1), card.ability.extra.odds_1, card.ability.extra.odds_2 }, main_end = main_end }
    end,

    locked_loc_vars = function(self, info_queue, card)
        return { vars = {G.PROFILES[G.SETTINGS.profile].career_stats.c_amaryllis_jokers_destroyed or 0} }
    end,

    cost = 6, rarity = 2,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    calculate = function(self, card, context)
        if context.amaryllis_remove_card then
            if pseudorandom("capricorn_1") < G.GAME.probabilities.normal / card.ability.extra.odds_1 then
                local destroyed_card = context.amaryllis_remove_card
                local is_playing_card = destroyed_card.playing_card
                local copies = 1
                if pseudorandom("capricorn_2") < G.GAME.probabilities.normal / card.ability.extra.odds_2 then
                    copies = copies + 1
                end

                if not is_playing_card then
                    copies = math.min(copies, context.cardarea.config.card_limit - #context.cardarea.cards + 1) -- -(-1) to account for the destroyed base card
                end

                if copies > 0 then
                    for i = 1, copies do
                        G.E_MANAGER:add_event(Event({func = function()
                            if is_playing_card then G.playing_card = (G.playing_card and G.playing_card + 1) or 1 end
                            local copy = copy_card(destroyed_card, nil, nil, is_playing_card, destroyed_card.edition and destroyed_card.edition.negative)
                            copy:add_to_deck()
                            if is_playing_card then
                                G.deck.config.card_limit = G.deck.config.card_limit + 1
                                table.insert(G.playing_cards, copy)
                            end
                            context.cardarea:emplace(copy)

                            copy.states.visible = nil
                            G.E_MANAGER:add_event(Event({
                                func = function()
                                    copy:start_materialize()
                                    return true
                                end
                            })) 
                        
                        return true end }))
                    end

                    return { message = localize("k_duplicated_ex") }
                end
            end
        end
    end,

    check_for_unlock = function(self, args)
        if (G.PROFILES[G.SETTINGS.profile].career_stats.c_amaryllis_jokers_destroyed or 0) >= 20 then
            return true
        end
    end,
}

SMODS.Joker{ -- Aquarius
    key = "aquarius",

    name = "Aquarius",
    loc_txt = {
        name = "Aquarius",
        text = {
            [1] = "When {C:attention}Blind{} is selected,",
            [2] = "create {C:attention}1{} {C:attention}#1#{}",
            [3] = "{C:inactive}(Must have room)",
        },
        unlock = {
            [1] = "Retrigger at least 1 card",
            [2] = "of each rank across all runs",
        }
    },

    pos = { x = 10, y = 0 }, atlas = "jokers",

    config = {
        extra = {
            joker = "j_" .. mod.prefix .. "_spring_water",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[card.ability.extra.joker]
        return { vars = { localize{type = "name_text", key = card.ability.extra.joker, set = "Joker"} } }
    end,

    locked_loc_vars = function(self, info_queue, card)
        -- Collect ranks that have yet to be retriggered
        local stats = G.PROFILES[G.SETTINGS.profile].career_stats.c_amaryllis_retriggered_rank
        local remaining_ranks = {}
        for _, rank in pairs(SMODS.Ranks) do
            if not stats or (stats[rank.key] or 0) == 0 then remaining_ranks[#remaining_ranks + 1] = rank end
        end
        if not next(remaining_ranks) then return end

        -- Sort ranks in order and merge adjacent chains of numbers, e.g. "2, 3, 4, 5" -> "2-5"
        table.sort(remaining_ranks, function(a, b) return a.sort_nominal < b.sort_nominal end)
        remaining_ranks = Utils.prettify_consecutive_chains(remaining_ranks, {"Jack", "Queen", "King", "Ace"}, "key")
        remaining_ranks = table.concat(remaining_ranks, ", ")

        -- Append to description
        local main_end = {}
        localize{ type = "other", key = self.key .. "_locked_progress", nodes = main_end, vars = {remaining_ranks} }
        return { main_end = main_end[1] }
    end,

    cost = 6, rarity = 2,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    add_to_deck = function(self, card, from_debuff)
        if not from_debuff then G.GAME.pool_flags.amaryllis_aquarius_added = true end
    end,

    calculate = function(self, card, context)
        if context.setting_blind and not (context.blueprint_card or card).getting_sliced and
        #G.jokers.cards + G.GAME.joker_buffer < G.jokers.config.card_limit then
                G.GAME.joker_buffer = G.GAME.joker_buffer + 1
                G.E_MANAGER:add_event(Event({func = function()
                    local new_card = SMODS.add_card{key = "j_" .. mod.prefix .. "_spring_water", set = "Joker"}
                    
                    new_card.ability.extra_value = (new_card.ability.extra_value or 0) - 2
                    new_card:set_cost()

                    G.GAME.joker_buffer = 0
                return true end }))
        end
    end,

    check_for_unlock = function(self, args)
        if args.type == "chip_score" then --Context just happens after hand has been played and had a chance to update the stats
            local stats = G.PROFILES[G.SETTINGS.profile].career_stats.c_amaryllis_retriggered_rank
            if not stats then return end
            for _, rank in pairs(SMODS.Ranks) do
                if (stats[rank.key] or 0) == 0 then return end
            end
            return true
        end
    end,
}

local pisces = { --Pisces
    key = "pisces",

    name = "Pisces",
    loc_txt = {
        name = "Pisces",
        text = {
            [1] = "{X:mult,C:white} X#1# {} Mult",
            [2] = "May appear multiple times,",
            [3] = "copies {C:attention}merge{} into one Joker",
        },
        unlock = {
            [1] = "Have {C:attention,E:1}3{} or more copies",
            [2] = "of the same Joker",
            [3] = "{C:inactive}(including Blueprint, Brainstorm)"
        }
    },

    pos = { x = 11, y = 0 }, atlas = "jokers",

    config = {
        extra = {
            Xmult = 1,
            copies = 1,
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.Xmult}}
    end,

    cost = 6, rarity = 1,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    max_visual_copies = 8,

    load = function(self, card, card_table, other_card)
        if self.discovered or card.bypass_discovery_center then
            local sprite_pos = {x = 11, y = math.min(self.max_visual_copies, card_table.ability.extra.copies) - 1}
            if sprite_pos ~= card.children.center.sprite_pos then
                card.children.center:set_sprite_pos(sprite_pos)
            end
        end
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main then
            return { xmult = card.ability.extra.Xmult }

        elseif context.card_added and not context.blueprint and not card.getting_sliced then
            local new_card = context.card
            if new_card.config.center.set == "Joker" then
                local can_merge = false
                for _, key in ipairs({ "j_" .. mod.prefix .. "_pisces", "j_" .. mod.prefix .. "_pisces_2" }) do
                    if new_card.config.center.key == key then can_merge = true; break end
                end

                if can_merge then
                    card.ability.extra.Xmult = card.ability.extra.Xmult + new_card.ability.extra.Xmult
                    card.ability.extra.copies = card.ability.extra.copies + new_card.ability.extra.copies

                    local sprite_pos = {x = 11, y = math.min(self.max_visual_copies, card.ability.extra.copies) - 1}

                    if new_card.enhancement and not card.enhancement then card.enhancement = new_card.enhancement end
                    if new_card.edition and not card.edition then card.edition = new_card.edition end
                    if new_card.seal and not card.seal then card.seal = new_card.seal end

                    new_card.getting_sliced = true
                    G.E_MANAGER:add_event(Event({func = function()
                        card:juice_up(0.8, 0.8)
                        new_card:start_dissolve({G.C.RED}, nil, 1.6)

                        if sprite_pos ~= card.children.center.sprite_pos then card.children.center:set_sprite_pos(sprite_pos) end
                    return true end }))

                    return { delay = 0.2, message = localize("k_upgrade_ex") }
                end
            end
        end
    end,

    in_pool = function(self, args)
        return true, { allow_duplicates = true }
    end,

    check_for_unlock = function(self, args)
        if (args.type == "modify_jokers" or args.type == "hand") and G.jokers then
            local copies = {}
            for i = 1, #G.jokers.cards do
                local joker = Utils.get_joker_ability(i)
                copies[joker.config.center.key] = (copies[joker.config.center.key] or 0) + 1
                if copies[joker.config.center.key] >= 3 then return true end
            end
        end
    end,
}
-- Pisces has allow_duplicates, but it also has a second copy which doubles its chances of showing, only if player has Pisces and Showman
local pisces_2 = {}
for k, v in pairs(pisces) do pisces_2[k] = v end
pisces_2.key = pisces_2.key .. "_2"
pisces_2.no_collection = true
pisces_2.unlocked = true -- always unlocked so it doesn't show a duplicate unlock message. should only appear if player has pisces_1 anyway
pisces_2.discovered = true
pisces_2.in_pool = function(self, args)
    local _, pisces_1 = next(SMODS.find_card("j_" .. mod.prefix .. "_pisces"))
    local _, pisces_2 = next(SMODS.find_card("j_" .. mod.prefix .. "_pisces_2"))
    local _, showman = next(SMODS.find_card("j_ring_master"))
    return (pisces_1 or pisces_2) and showman, { allow_duplicates = (showman ~= nil) }
end
--Add Pisces
SMODS.Joker(pisces)
SMODS.Joker(pisces_2)


SMODS.Joker{ -- Spring Water
    key = "spring_water",
    generic_prefix = "j_amaryllis_generic_",

    name = "Spring Water",
    loc_txt = { name = "Spring Water", text = {} },

    pos = { x = 10, y = 1 }, atlas = "jokers",

    config = {
        extra = {
            rank = nil, rank_id = nil, type = nil,
            effect = nil, effect_amount = nil, effect_state = nil,
            condition = nil, condition_amount = nil,
        }
    },

    random_ability = {
        types = {
            if_scored = { weight = 3, buffs = {add_chips = 3, add_mult = 6, add_xmult = 3, destroy = -4} },
            when_scored = { weight = 2, buffs = -1 },
            held = { weight = 2, buffs = {add_chips = 1, add_mult = 2, add_xmult = -1}, conditions = { "chance", "first_time" } },
            discarded = { weight = 1, effects = { "money", "generate_tarot", "generate_planet", "generate_spectral", "destroy" }},
            in_deck = { weight = 1, buffs = -2, conditions = { "chance" }, effects = { "money", "generate_tarot", "generate_planet", "generate_spectral", "destroy" } }
        },
        conditions = {
            chance = { text_pos = "start", amount = 2 },
            first_time = {},
            at_least = { amount = 2, max = 5 },
            with_other = { amount = 1, max = 4 }
        },
        effects = {
            add_chips = { weight = 1, min = 15, max = 50 },
            add_mult = { weight = 1, min = 3, max = 15 },
            add_xmult = { weight = 1, min = 1.25, max = 2 },
            gain_chips = { weight = 0.65, buffs = -1, min = 4, max = 15 },
            gain_mult = { weight = 0.65, buffs = -1, min = 1, max = 5 },
            gain_xmult = { weight = 0.65, buffs = -1, min = 0.1, max = 0.5, conditions = { resets = { text_pos = "end" } } },
            money = { weight = 2, min = 1, max = 3 },
            generate_tarot = { weight = 0.35, buffs = -2, force_condition = true },
            generate_planet = { weight = 0.35, buffs = -1, force_condition = true },
            generate_spectral = { weight = 0.35, buffs = -3, force_condition = true },
            retrigger = { weight = 1, buffs = -1, min = 1, max = 2, prefix = "for_each_" },
            destroy = { weight = 1, buffs = -3, prefix = "for_each_" },
        }
    },

    get_dynamic_loc_target = function(self, card, desc_nodes, full_UI_table)
        if not (card and card.ability.extra.rank) then
            return { type = "other", key = self.key .. "_generic", nodes = desc_nodes, AUT = full_UI_table, vars = {} }
        end

        local presets, params = self.random_ability, card.ability.extra
        local vars = {
            params.rank, params.effect_amount, params.effect_state, params.condition_amount, ""..(G.GAME and G.GAME.probabilities.normal or 1),
            G.localization.misc.dictionary[self.generic_prefix .. (params.type == "discarded" and "discard" or "hand")],
            G.localization.misc.dictionary[self.generic_prefix .. (params.type == "discarded" and "discarded" or "played")],
            (params.type == "if_scored" or params.type == "when_scored") and G.localization.misc.dictionary[self.generic_prefix .. "scoring"] or "",
        }

        local localize_raw = function(key) return G.localization.misc.dictionary[self.generic_prefix .. key] end
        local description = {}
        if params.condition and presets.conditions[params.condition].text_pos == "start" then description[#description + 1] = localize_raw(params.condition) end
        description[#description + 1] = localize_raw(params.effect)
        if params.effect == "retrigger" and params.effect_amount > 1 then description[#description + 1] = localize_raw("retrigger_times") end
        description[#description + 1] = localize_raw((presets.effects[params.effect].prefix or "") .. params.type)
        
        if params.condition and not presets.conditions[params.condition].text_pos then description[#description + 1] = localize_raw(params.condition) end

        description = table.concat(description, " ")
        description = (description:gsub("^%l", string.upper)) -- Capitalize first letter
        description = Utils.split_multiline(description, 20)
        -- Add whole-line postscripts
        if params.condition and presets.conditions[params.condition].text_pos == "end" then description[#description + 1] = localize_raw(params.condition) end
        if params.effect_state then description[#description + 1] = localize_raw(params.effect:gsub("gain", "current")) end
        
        local center = { name = G.localization.descriptions.Other["j_" .. mod.prefix .. "_spring_water_generic"].name, text = description, text_parsed = {}, name_parsed = {} }
        for _, line in ipairs(center.text) do center.text_parsed[#center.text_parsed + 1] = loc_parse_string(line) end
        for _, line in ipairs(type(center.name) == "table" and center.name or {center.name}) do center.name_parsed[#center.name_parsed + 1] = loc_parse_string(line) end
        G.localization.descriptions.Other[self.generic_prefix .. "constructed"] = center

        return { type = "other", key = self.generic_prefix .. "constructed", nodes = desc_nodes, AUT = full_UI_table, vars = vars }
    end,

    generate_ui = function(self, info_queue, card, desc_nodes, specific_vars, full_UI_table)
        local target = self.get_dynamic_loc_target(self, card, desc_nodes, full_UI_table)

        if not card then card = self:create_fake_card() end
        if desc_nodes == full_UI_table.main and not full_UI_table.name then
            full_UI_table.name = localize{type = "name", set = "Other", key = target.key, nodes = full_UI_table.name, vars = target.vars}
        elseif desc_nodes ~= full_UI_table.main and not desc_nodes.name then
            desc_nodes.name = localize{type = "name_text", key = target.key, set = "Other"}
        end
        localize(target)

        G.localization.descriptions.Other[self.generic_prefix .. "constructed"] = nil
    end,

    cost = 6, rarity = 2,
    blueprint_compat = true,
    unlocked = true, discovered = amaryllis_zodiac_config.discover_jokers,
    yes_pool_flag = "amaryllis_aquarius_added",

    set_ability = function(self, card, initial, delay_sprites)
        if not card.ability.extra.rank then
            local valid_ranks = {}
            for _, other_card in ipairs(G.playing_cards) do
                if other_card.ability.effect ~= "Stone Card" then
                    valid_ranks[#valid_ranks + 1] = { rank = other_card.base.value, id = other_card.base.id }
                end
            end
            local rank = pseudorandom_element(next(valid_ranks) and valid_ranks or SMODS.Ranks, pseudoseed("spring_water_rank"))
            card.ability.extra.rank, card.ability.extra.rank_id = rank.key, rank.id

            local ability_type, effect_type
            ability_type, card.ability.extra.type = Utils.weighted_pseudorandom_element(self.random_ability.types, pseudoseed("spring_water_type"))

            local effects = self.random_ability.effects
            if ability_type.effects then
                effects = {}
                for _, effect in ipairs(ability_type.effects) do effects[effect] = self.random_ability.effects[effect] end
            end
            effect_type, card.ability.extra.effect = Utils.weighted_pseudorandom_element(effects, pseudoseed("spring_water_effect"))
            local is_xmult, is_gain = card.ability.extra.effect:sub(-5) == "xmult", card.ability.extra.effect:sub(1,4) == "gain"

            local quality = math.random()
            if effect_type.amounts then card.ability.extra.effect_amount = effect_type.amounts[math.ceil(#effect_type.amounts * quality)]
            elseif effect_type.min then card.ability.extra.effect_amount = effect_type.min + (effect_type.max - effect_type.min) * quality
            else card.ability.extra.effect_amount = 0 end
            if is_gain then card.ability.extra.effect_state = is_xmult and 1 or 0 end

            local conditions = {}
            if ability_type.conditions then
                for _, key in ipairs(ability_type.conditions) do conditions[key] = self.random_ability.conditions[key] end
            else
                for key, condition in pairs(self.random_ability.conditions) do conditions[key] = condition end
            end
            if effect_type.conditions then
                for key, condition in pairs(effect_type.conditions) do conditions[key] = condition end
            end
            local condition_type, condition = Utils.weighted_pseudorandom_element(conditions, pseudoseed("spring_water_condition"))

            local random_buffs = { -2, -1, -1, 0, 0, 0, 0, 0, 1, 1, 2 }
            local buffs = pseudorandom_element(random_buffs, pseudoseed("spring_water_buffs"))
            local add_buffs = function(data)
                if data and type(data) == "table" then 
                    for effect, _buffs in ipairs(data) do
                        if effect == params.effect then buffs = buffs + _buffs; break; end
                    end
                else buffs = buffs + (data or 0) end
            end
            add_buffs(ability_type.buffs)
            add_buffs(effect_type.buffs)
            
            if quality > 0.65 then buffs = buffs - 1 end
            if quality > 0.35 then buffs = buffs - 1 end

            math.randomseed(pseudoseed("spring_water_quality"))
            local force_condition = effect_type.force_condition or false
            while buffs ~= 0 do
                if buffs > 0 then --buff
                    if card.ability.extra.effect_amount then
                        if math.random() < 0.15 then --super buff with nerf
                            card.ability.extra.effect_amount = effect_type.max and (card.ability.extra.effect_amount + effect_type.max) or (card.ability.extra.effect_amount * 2)
                            buffs = -1
                            force_condition = true
                        else
                            card.ability.extra.effect_amount = card.ability.extra.effect_amount * (0.9 + (1.25 - 0.9) * math.random())
                        end
                    end
                    buffs = buffs - 1
                else --nerf
                    if not force_condition and math.random() < (card.ability.extra.effect_amount and 0.75 or 0.3) then
                        if card.ability.extra.effect_amount then
                            card.ability.extra.effect_amount = card.ability.extra.effect_amount * (0.75 + (1.15 - 0.75) * math.random())
                        end
                    else -- apply condition
                        if not card.ability.extra.condition then
                            card.ability.extra.condition = condition
                            card.ability.extra.condition_amount = condition_type and condition_type.amount
                        else -- worsen condition
                            card.ability.extra.condition_amount = math.min(condition_type and condition_type.max or 1000, (card.ability.extra.condition_amount or 0) + 1)
                        end
                        force_condition = false
                    end
                    buffs = buffs + 1
                end
            end

            local int_round = not is_xmult
            local round = function(f, int_round)
                return int_round and math.floor(f + 0.5) or math.floor(f * 20) * 0.05
            end
            card.ability.extra.effect_amount = math.max(effect_type.min or 0, round(card.ability.extra.effect_amount, int_round))
        end
    end,

    calculate = function(self, card, context)
        local params = card.ability.extra
        local triggered, to_match = false

        local is_context = {
            if_scored = context.final_scoring_step,
            when_scored = context.individual and context.cardarea == G.play,
            held = context.individual and context.cardarea == G.hand,
            discarded = context.discard,
            in_deck = context.end_of_round and context.cardarea == G.jokers, 
        }
        if params.effect == "retrigger" then
            is_context.if_scored = context.repetition and context.cardarea == G.play
            is_context.when_scored = context.repetition and context.cardarea == G.play
            is_context.held = context.repetition and context.cardarea == G.hand and (next(context.card_effects[1]) or #context.card_effects > 1)
        end

        if not is_context[params.type] then return end
        if params.type == "if_scored" then to_match = context.scoring_hand
        elseif params.type == "when_scored" or params.type == "held" then triggered = context.other_card:get_id() == params.rank_id
        elseif params.type == "discarded" then to_match = context.full_hand
        elseif params.type == "in_deck" then to_match = G.playing_cards
        else return end

        local matches = 0
        local trigger_on_match = (to_match ~= nil)
        to_match = to_match or (context.cardarea and context.cardarea.cards)
        if to_match then
            for _, other_card in ipairs(to_match) do
                if other_card:get_id() == params.rank_id then matches = matches + 1 end
            end
            if trigger_on_match then triggered = (matches > 0) end
        end
        if triggered and params.condition == "first_time" then
            triggered = (G.GAME.current_round[params.type == "discarded" and "discards_used" or "hands_played"] <= 0)
        end
        if triggered and params.condition == "chance" and (params.effect ~= "destroy" or params.type == "if_scored") then 
            triggered = pseudorandom("spring_water_chance") < G.GAME.probabilities.normal / params.condition_amount
        end
        if triggered and params.condition == "at_least" then
            triggered = matches >= params.condition_amount
        end
        if triggered and params.condition == "with_other" then
            triggered = matches < #to_match
        end
        
        if triggered then
            if params.effect == "add_chips" then return { chips = params.effect_amount }
            elseif params.effect == "add_mult" then return { mult = params.effect_amount }
            elseif params.effect == "add_xmult" then return { xmult = params.effect_amount }
            elseif params.effect == "gain_chips" or params.effect == "gain_mult" or params.effect == "gain_xmult" then
                params.effect_state = params.effect_state + params.effect_amount
                local key = params.effect:sub(6)
                return { message = localize{type = "variable", key = "a_" .. key, vars = { params.effect_state }}, colour = (key == "chips" and G.C.CHIPS or G.C.MULT), card = card }
            elseif params.effect == "money" then return { dollars = params.effect_amount }
            elseif params.effect == "generate_tarot" or params.effect == "generate_planet" or params.effect == "generate_spectral" then
                if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                    local key = params.effect:sub(10)
                    local set = (key:gsub("^%l", string.upper)) -- Capitalize first letter
                    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                    G.E_MANAGER:add_event(Event({trigger = "before", delay = 0.0, func = function()
                        local card = create_card(set, G.consumeables, nil, nil, nil, nil, nil, "spring_water")
                        card:add_to_deck()
                        G.consumeables:emplace(card)
                        G.GAME.consumeable_buffer = 0
                    return true end}))
                    return { message = localize("k_plus_" .. key), colour = G.C.SECONDARY_SET[set] }
                end
            elseif params.effect == "retrigger" then
                return { message = localize('k_again_ex'), repetitions = params.effect_amount, card = card }
            elseif params.effect == "destroy" then
                local to_destroy, ignore_match
                if params.type == "if_scored" then to_destroy = context.scoring_hand; ignore_match = true
                elseif params.type == "when_scored" then to_destroy = context.scoring_hand
                elseif params.type == "discarded" then to_destroy = G.hand.highlighted
                elseif params.type == "in_deck" then to_destroy = G.playing_cards
                elseif context.other_card then to_destroy = { context.other_card } end

                local cards_destroyed = {}
                for i = 1, #to_destroy do
                    local other_card = to_destroy[i]
                    if ignore_match or (other_card:get_id() == params.rank_id and 
                       (params.condition ~= "chance" or pseudorandom("spring_water_chance_" .. i) < G.GAME.probabilities.normal / params.condition_amount)) then
                            cards_destroyed[#cards_destroyed + 1] = other_card
                    end
                end
                Utils.destroy_cards(cards_destroyed)
            end
        end
        if context.joker_main then
            if params.effect == "gain_chips" then return { chips = params.effect_state }
            elseif params.effect == "gain_mult" then return { mult = params.effect_state }
            elseif params.effect == "gain_xmult" then return { xmult = params.effect_state } end
        end
        if params.condition == "resets" and context.end_of_round and context.cardarea == G.jokers then
            local is_xmult = params.effect:sub(-5) == "xmult"
            params.effect_state = is_xmult and 1 or 0
            return { message = localize("k_reset"), colour = G.C.RED }
        end
    end,
}


SMODS.Joker{ -- Ophiuchus
    key = "ophiuchus",

    name = "Ophiuchus",
    loc_txt = {
        name = "Ophiuchus",
        text = {
            [1] = "Gives {X:mult,C:white} X#1# {} Mult",
            [2] = "when Mult is added",
        },
        unlock = {
            [1] = "Win a run with {C:attention,E:1}3{} or",
            [2] = "more Sinful {C:inactive}(Suit){} Jokers",
        }
    },

    pos = { x = 0, y = 1 }, atlas = "jokers",

    config = {
        extra = {
            Xmult = 1.5,
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.Xmult}}
    end,

    locked_loc_vars = function(self, info_queue, card)
        local example_jokers = { "j_greedy_joker", "j_lusty_joker", "j_wrathful_joker", "j_gluttenous_joker" }
        local example_joker = pseudorandom_element(example_jokers, pseudoseed("ophiuchus"))
        info_queue[#info_queue + 1] = G.P_CENTERS[example_joker]
    end,

    cost = 8, rarity = 3,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    calculate = function(self, card, context)
        local effects, edition
        -- +Mult from cards played (Mult Cards, Holographic playing card)
        if context.individual and context.cardarea == G.play and context.other_card then effects = context.other_card.ability; edition = context.other_card.edition
        -- +Mult from Joker effects
        elseif context.post_trigger and context.other_ret and context.other_ret.jokers then effects = context.other_ret.jokers
        -- +Mult from Joker edition
        elseif context.other_joker and context.other_joker.edition then edition = context.other_joker.edition end

        local mult_added = 0
        if effects then mult_added = mult_added + (effects.mult or 0) + (effects.h_mult or 0) + (effects.mult_mod or 0) end
        if edition then mult_added = mult_added + (edition.mult or 0) + (edition.h_mult or 0) + (edition.mult_mod or 0) end
        if mult_added > 0 then return { xmult = card.ability.extra.Xmult, message_card = card } end
    end,

    check_for_unlock = function(self, args)
        if args.type == "win_custom" then
            local suit_joker_count = 0
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i].config.center.effect == "Suit Mult" then
                    suit_joker_count = suit_joker_count + 1
                    if suit_joker_count >= 3 then return true end
                end
            end
        end
    end,
}

SMODS.Joker{ -- Cetus
    key = "cetus",

    name = "Cetus",
    loc_txt = {
        name = "Cetus",
        text = {
            [1] = "Gains {C:mult}+#2#{} Mult per {C:money}$#3#{} lost",
            [2] = "{s:0.9,C:money}Cost{s:0.9} raises every {s:0.9,C:mult}#4#{s:0.9} Mult",
            [3] = "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
        unlock = {
            [1] = "Go more than",
            [2] = "{C:red,E:1}-$20{} in debt",
        }
    },

    pos = { x = 0, y = 2 }, atlas = "jokers",
    --display_size = { w = 80, h = 107 },

    config = {
        extra = {
            mult = 0,
            mult_mod = 1,
            mult_threshold = 10,

            dollars_spent = 0,
            dollars = 1,

            initialized = false,
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.mult, card.ability.extra.mult_mod, card.ability.extra.dollars, card.ability.extra.mult_threshold }}
    end,

    cost = 15, rarity = 2,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    unlocked = amaryllis_zodiac_config.unlock_jokers, discovered = amaryllis_zodiac_config.discover_jokers,

    set_sprites = function(self, card, front)
        G.E_MANAGER:add_event(Event({func = function()
            Utils.set_card_scale(card, 1 + card.ability.extra.mult * 0.005, true)
        return true end }))
    end,

    calculate = function(self, card, context)
        if context.amaryllis_money_changed and context.amaryllis_money_changed < 0 and not context.blueprint then
            local amount = -context.amaryllis_money_changed

            -- Skip the first proc if we think it's from purchasing itself
            if not initialized then
                initialized = true
                if amount == card.cost then return end
            end

            local mult_gained = 0
            for i = 1, amount do
                card.ability.extra.dollars_spent = card.ability.extra.dollars_spent + 1

                if card.ability.extra.dollars_spent == card.ability.extra.dollars then
                    card.ability.extra.dollars_spent = 0
                    
                    local threshold_progress = card.ability.extra.mult % card.ability.extra.mult_threshold
                    local passing_threshold = threshold_progress + card.ability.extra.mult_mod >= card.ability.extra.mult_threshold
                    if passing_threshold then
                        card.ability.extra.dollars = card.ability.extra.dollars + 1
                        card_eval_status_text(card, "extra", nil, nil, nil, {message = localize("k_" .. mod.prefix .. "_cost_up"), colour = G.C.GOLD})
                    end
                    
                    mult_gained = mult_gained + card.ability.extra.mult_mod
                    card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
                end
            end
            if mult_gained > 0 then
                card_eval_status_text(card, "extra", nil, nil, nil, {message = localize{type = "variable", key = "a_mult", vars = {mult_gained}}, colour = G.C.RED})
                Utils.set_card_scale(card, 1 + card.ability.extra.mult * 0.005)
            end
        
        elseif context.cardarea == G.jokers and context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,

    check_for_unlock = function(self, args)
        if args.type == "money" and G.GAME.dollars < -20 then
            return true
        end
    end,
}



if amaryllis_zodiac_config.enable_deck then
    SMODS.Back{
        name = "Amaryllis Zodiac Deck",
        key = "zodiac",  
        loc_txt = {      
            name = "Zodiac Deck",      
            text = {
                "Start each {C:attention}ante",
                "with a different",
                "{C:attention}eternal{} {C:purple,E:1}Zodiac Joker{}"
            }
        },

        pos = { x = 1, y = 0 }, atlas = "other",

        order = 16,
        unlocked = true, discovered = true,

        config = { consumables = { "c_ankh" } },

        apply = function(self, back)
            -- Add special zodiac joker
            G.GAME.joker_buffer = G.GAME.joker_buffer + 1
            G.E_MANAGER:add_event(Event({func = function()
                local zodiac_joker = Utils.add_special_zodiac_joker{no_collection = true}
                G.GAME.joker_buffer = 0
            return true end }))
        end,
        
        calculate = function(self, back, context)
            if context.end_of_round and G.GAME.blind.boss and context.game_over ~= nil then --game_over check just to filter ~6 "end_of_round" events into 1
                -- Remove previous special zodiac joker(s)
                local previous_joker
                local to_remove = {}
                for i = 1, #G.jokers.cards do
                    if G.jokers.cards[i].ability[mod.prefix .. "_special"] then   
                        previous_joker = G.jokers.cards[i].config.center.key
                        to_remove[#to_remove + 1] = G.jokers.cards[i]
                    end
                end
                local to_add = math.max(1, #to_remove)
                for _, joker in ipairs(to_remove) do joker:remove() end

                -- Add new special zodiac joker
                G.GAME.joker_buffer = G.GAME.joker_buffer + to_add
                G.E_MANAGER:add_event(Event({func = function()
                    for i = 1, to_add do
                        local zodiac_joker = Utils.add_special_zodiac_joker{previous = previous_joker, no_collection = true}
                        G.E_MANAGER:add_event(Event({func = function() zodiac_joker:juice_up() return true end }))
                    end
                    G.GAME.joker_buffer = 0
                return true end }))
            end
        end,
    }

    SMODS.Sticker{
        key = "special",
        name = "Special Zodiac",

        loc_txt = {
            name = "Zodiac Deck",
            text = {
                "Changes to new",
                "{C:purple,E:1}Zodiac Joker{} at",
                "end of ante",
            }
        },

        pos = { x = 2, y = 0 }, atlas = "other",
        badge_colour = HEX("715F52"),

        no_collection = true, default_compat = false,
    }
end



SMODS.Sticker{
    key = "pinned",
    name = "Pinned",

    pos = { x = 0, y = 0 }, atlas = "other",

    hide_badge = true, no_collection = true, default_compat = false,

    apply = function(self, card, val)
        card.ability[self.key] = val
        card.pinned = val
    end,

    -- Draw without the shiny overlay
    draw = function(self, card, layer)
        G.shared_stickers[self.key].role.draw_major = card
        G.shared_stickers[self.key]:draw_shader("dissolve", nil, nil, nil, card.children.center)
    end,
}