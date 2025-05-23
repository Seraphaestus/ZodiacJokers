local mod_prefix = "amaryllis_zodiac"

local all_jokers = { "aries", "taurus", "gemini", "leo", "cancer", "virgo", "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces", "ophiuchus", "cetus", "spring_water" }
local zodiac_jokers = { "aries", "taurus", "gemini", "leo", "cancer", "virgo", "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces", "ophiuchus", "cetus" }



local find_index = function(_table, value)
    if not _table then return nil end
    for i, v in ipairs(_table) do
        if v == value then return i end
    end
    return nil
end

local get_joker_loc_vars = function(self, card)
    if card.config and card.config.center and card.config.center.loc_vars then
        return card.config.center.loc_vars(self, {}, card, true).vars or {}
    end

    card.loc_vars_return_only = true
    return card:generate_UIBox_ability_table()
end

local add_card_without_updating_collection = function(args)
    SMODS.amaryllis_bypass_unlock_card = true
    SMODS.amaryllis_bypass_discover_card = true
    local card = SMODS.add_card(args)
    SMODS.amaryllis_bypass_unlock_card = nil
    SMODS.amaryllis_bypass_discover_card = nil
    return card
end



return {
    all_jokers = all_jokers,

    find_index = find_index,

    split = function(_string, delimiter)
        if delimiter == nil then delimiter = "%s" end
        local output = {}
        for part in _string:gmatch("([^" .. delimiter .. "]+)") do
            table.insert(output, part)
        end
        return output
    end,

    count_substrings = function(str, substring, strip_matches)
        local count, idx, stripped_substring = 0, -1, ""
        while idx ~= nil do
            local prev_idx = idx
            idx = str:find(substring, idx + 1)
            if idx then count = count + 1 end
            if strip_matches then stripped_substring = stripped_substring .. str:sub(prev_idx == -1 and 1 or prev_idx + #substring, idx and idx - 1 or #str) end
        end
        return count, strip_matches and stripped_substring or substring
    end,

    prettify_consecutive_chains = function(table, abbreviate_strings, subkey)
        local output = {}
        local consecutive = {}
        for _, value in ipairs(table) do
            local text = subkey and value[subkey] or value
            local number = tonumber(text)
            local is_consecutive = number and number - 1 == consecutive[#consecutive]
            if find_index(abbreviate_strings, text) then text = text:sub(1, 1) end
            
            if number and is_consecutive then
                consecutive[#consecutive + 1] = number
            
            elseif not number or not is_consecutive then
                if next(consecutive) then
                    output[#output + 1] = "" .. consecutive[1]
                    if #consecutive > 1 then
                        output[#output] = output[#output] .. "-" .. consecutive[#consecutive]
                    end
                    consecutive = {}
                end
                
                if number then
                    consecutive[1] = number
                else
                    output[#output + 1] = text
                end
            end
        end
        return output
    end,

    get_joker_ability = function(idx)
        local joker
        local is_copying = true
        while is_copying do
            joker = G.jokers.cards[idx]
            if     joker.config.center.key == "j_blueprint"             and idx < #G.jokers.cards  then idx = idx + 1
            elseif joker.config.center.key == "j_brainstorm"            and idx ~= 1               then idx = 1
            elseif joker.config.center.key == "j_" .. mod_prefix .. "_sagittarius" and idx ~= #G.jokers.cards then idx = #G.jokers.cards
            else is_copying = false end
        end
        return joker
    end,

    add_jokers = function(jokers, edition)
        G.GAME.joker_buffer = G.GAME.joker_buffer + #jokers
        G.E_MANAGER:add_event(Event({func = function()
            for _, joker in pairs(jokers) do
                SMODS.add_card{key = joker, set = "Joker", no_edition = edition and nil or true, edition = edition}
            end
            G.GAME.joker_buffer = 0
        return true end }))
    end,

    add_special_zodiac_joker = function(args)
        local key = args.previous
        while key == args.previous do
            key = "j_" .. mod_prefix .. "_" .. pseudorandom_element(zodiac_jokers, pseudoseed(args.seed or "zodiac_deck"))
        end
        
        local stickers = {}
        if key ~= "j_" .. mod_prefix .. "_aries" then stickers[#stickers + 1] = "eternal" end

        local joker_args = {key = key, set = "Joker", no_edition = true, stickers = stickers, skip_materialize = previous}
        local card = args.no_collection and add_card_without_updating_collection(joker_args) or SMODS.add_card(joker_args)
        card:add_sticker(mod_prefix .. "_special", true)
        return card
    end,

    ease_blind_chips = function(config, instant)
        if not G.GAME.blind then return end
        if not type(config) == "table" then config = { add = config } end
        if (config.add or 0) == 0 and (config.mult or 1) == 1 then return end

        local function _mod(config)
            local score_UI = G.HUD_blind:get_UIE_by_ID("HUD_blind_count")

            local new_chips = (G.GAME.blind.chips + (config.add or 0)) * (config.mult or 1)
            if config.round or true then new_chips = math.floor(new_chips * 0.2) * 5 end -- Round down to the nearest 5
            if new_chips == G.GAME.blind.chips then return end
            
            local text = tostring(new_chips)
            local col = new_chips > G.GAME.blind.chips and G.C.RED or G.C.MONEY

            G.GAME.blind.chips = new_chips
            G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
            --score_UI.config.object:update()
            G.HUD:recalculate()
            
            attention_text({
                text = string.format(" %s ", text),
                scale = 1.0,
                hold = 0.7,
                cover = score_UI,
                cover_colour = col,
                align="cm",
                offset = { x = -0.2, y = 0 },
            })
            play_sound("card1", 1)
        end

        if instant then
            _mod(config)
        else
            G.E_MANAGER:add_event(Event({trigger = "immediate", func = function()
                _mod(config)
            return true end}))
        end
    end,

    get_joker_loc_vars = get_joker_loc_vars,

    get_joker_desc = function(self, card)
        if card.config == nil or card.config.center == nil then return "" end
        
        local output = ""
        local loc_target, vars

        if card.config.center.get_dynamic_loc_target then
            local loc = card.config.center.get_dynamic_loc_target(card.config.center, card)
            loc_target = G.localization.descriptions.Other[loc.key]
            vars = loc.vars
        else
            loc_target = G.localization.descriptions.Joker[card.config.center.key]
            vars = get_joker_loc_vars(self, card)
        end

        if loc_target then
            for _, lines in ipairs(loc_target.text_parsed) do
                local final_line = {}
                for _, part in ipairs(lines) do
                    for _, subpart in ipairs(part.strings) do
                        output = output .. (type(subpart) == "string" and subpart or vars[tonumber(subpart[1])] or "ERROR")
                    end
                    output = output .. " "
                end
            end
        end
        return output
    end,

    create_animation = function(args)
        assert(args.frames or args.durations, "Animation must have frame data (array of y positions in the atlas) or duration data (array of frame hold durations)")
        if not args.durations then
            args.durations = {}
            for i = 1, #args.frames do args.durations[i] = 1 end
        elseif not args.frames then
            args.frames = {}
            for i = 1, #args.durations do args.frames[i] = i - 1 end
        end

        return {
            sprite_pos = args.sprite_pos or { x = 0, y = 0 },
            frames = args.frames, durations = args.durations,
            random_seed = args.random_seed,
            t = 0, idx = 0,
        }
    end,
    update_animation = function(self, card, dt)
        local animation = card.ability.extra.animation
        animation.t = animation.t - dt / G.SETTINGS.GAMESPEED
        if animation.t <= 0 then
            animation.idx = animation.idx % #animation.frames + 1

            local next_duration = animation.durations[animation.idx]
            if type(next_duration) == "table" then
                next_duration = (next_duration.min or 0) + pseudorandom(animation.random_seed or "animation") * (next_duration.max or 1 - next_duration.min or 0) 
            end
            animation.t = next_duration

            card.children.center:set_sprite_pos({ x = animation.sprite_pos.x, y = animation.sprite_pos.y + animation.frames[animation.idx] })
        end
    end,

    set_card_scale = function(card, scale, initial, max_scale)
        scale = math.min(scale, max_scale or 2)
        print("Scale = " .. scale)

        local H, W = card.children.center.T.h, card.children.center.T.w
        print("H = " .. H)
        if card.ability.extra.scale and not initial then
            H = H / card.ability.extra.scale
            W = W / card.ability.extra.scale
            print("--Reverted H to " .. H)
        end
        
        card.ability.extra.scale = scale
        H = H * scale
        W = W * scale
        print("H *= scale = " .. H)

        if card.children.center.T.h == H and card.children.center.T.w == W then return end
        
        print("Set H")
        card.children.center.T.h = H
        card.children.center.T.w = W
        card:set_sprites(card.children.center)
    end,

    weighted_pseudorandom_element = function(_t, seed)
        if seed then math.randomseed(seed) end

        local total_weight = 0
        local keys = {}
        for k, v in pairs(_t) do
            keys[#keys+1] = {k = k, v = v}
            total_weight = total_weight + (v.weight or 1)
        end
        if keys[1] and keys[1].v and type(keys[1].v) == "table" and keys[1].v.sort_id then
            table.sort(keys, function (a, b) return a.v.sort_id < b.v.sort_id end)
        else
            table.sort(keys, function (a, b) return a.k < b.k end)
        end

        local rnd = math.random() * total_weight
        local cum_weight = 0
        for i = 1, #keys do
            cum_weight = cum_weight + (keys[i].v.weight or 1)
            if rnd <= cum_weight or i == #keys then
                return _t[keys[i].k], keys[i].k
            end
        end
    end,

    split_multiline = function(text, char_width)
        local visible_chars, is_visible, is_space, char = 0, true
        for i = 1, #text do
            char = text:sub(i, i)
            if is_visible and char == "{" then is_visible = false end
            if is_visible and char ~= "#" then visible_chars = visible_chars + 1 end
            if not is_visible and char == "}" then is_visible = true end 
        end
        
        char_width = math.min(char_width or 16, math.ceil(visible_chars * 0.5))
        local lines = {}
        local idx, prev_idx = 1, nil
        local total_visible_chars, partial_visible_chars = visible_chars, 0
        while idx < #text do
            prev_idx = idx
            --Increment idx until: we have passed [width + 1] visible characters; we arrive at a space
            visible_chars, is_visible, is_space, char = 0, true, false, nil
            while idx <= #text and not ((visible_chars > char_width - 2 and total_visible_chars - partial_visible_chars - visible_chars > char_width * 0.25) and is_space) do
                char = text:sub(idx, idx)
                idx = idx + 1
                is_space = (char == " ")
                if is_visible and char == "{" then is_visible = false end
                if is_visible and char ~= "#" then visible_chars = visible_chars + 1 end
                if not is_visible and char == "}" then is_visible = true end 
            end
            partial_visible_chars = partial_visible_chars + visible_chars
            --
            char_width = math.max(char_width, visible_chars)
            lines[#lines + 1] = text:sub(prev_idx, idx - 1)
            --Strip edges
            if lines[#lines]:sub(1, 1) == " " then lines[#lines] = lines[#lines]:sub(2) end
            if lines[#lines]:sub(-1) == " " then lines[#lines] = lines[#lines]:sub(1, -2) end
        end
        return lines
    end,

    destroy_cards = function(to_destroy)
        if not next(to_destroy) then return end

        for _, card in ipairs(to_destroy) do
            card[card.ability.name == "Glass Card" and "shattered" or "destroyed"] = true
        end

        for j = 1, #G.jokers.cards do
            eval_card(G.jokers.cards[j], { cardarea = G.jokers, remove_playing_cards = true, removed = to_destroy })
        end

        local glass_shattered = {}
        for _, card in ipairs(to_destroy) do
            if card.shattered then glass_shattered[#glass_shattered + 1] = card end
        end
        check_for_unlock{type = "shatter", shattered = glass_shattered}
        
        for i = 1, #to_destroy do
            G.E_MANAGER:add_event(Event({trigger = "after", delay = 1.0, func = function()
                if to_destroy[i].ability.name == "Glass Card" then to_destroy[i]:shatter() else to_destroy[i]:start_dissolve() end
            return true end }))
        end
    end,
}