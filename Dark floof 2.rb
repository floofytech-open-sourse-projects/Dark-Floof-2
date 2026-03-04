# DARK FLOOF II: THE STACKS BENEATH
# FULL VERSION WITH SOUL-MASKS + FUSION

require "securerandom"
require "json"

# =========================
# CONSTANTS
# =========================

FACTIONS = [:kennel, :order, :null]

PAGE_TYPES = [:ink, :memory, :null_page, :binding, :index]

MASK_ARCANA = [:kennel, :order, :null, :fang, :unwritten]

BASE_SPEED = {
    player: 10,
    kennel_dps: 14,
    kennel_tank: 8,
    kennel_support: 10,
    order_tank: 9,
    order_mage: 11,
    order_debuffer: 10,
    null_mage: 12,
    null_support: 9,
    null_control: 11,
    generic_enemy: 9,
    boss: 12
}

ROOM_LORE = [
    "The shelves lean in, like they’re trying to read you.",
    "Dust motes drift in patterns that feel like handwriting.",
    "You hear pages turning, but nothing nearby is open.",
    "A draft carries the smell of old ink and wet fur.",
    "Some of these books have your pawprints on the covers.",
    "A card catalog drawer hangs open, labels scratched out.",
    "The silence here feels curated, not accidental.",
    "You feel watched by things that never finished becoming real.",
    "The air tastes like glue and forgotten promises.",
    "You smell your own fear, cataloged and cross-referenced."
]

NULL_DIALOG = [
    "You look tired. Everyone does, before they understand.",
    "It's all very loud at first. That isn't your fault.",
    "You don't have to explain yourself. Existence already did that badly.",
    "We noticed you because you keep going. That's usually the last symptom.",
    "You can sit, if you want. Nothing will happen while you're still.",
    "You've been correcting errors that weren't yours to fix.",
    "People call this survival. It's more like repetition.",
    "We don't judge effort. We just measure how long it hurts.",
    "Birth isn't sacred. It's procedural.",
    "The world keeps retrying the same operation with corrupted input.",
    "Hope is an optimization loop. It never exits cleanly.",
    "Ending isn't destruction. It's closure.",
    "You were never supposed to carry this much continuation.",
    "If you stop now, nothing will chase you.",
    "You've done enough for a system that won't remember your name.",
    "Joining us doesn't give power. It removes obligations.",
    "You won't feel better. You'll feel finished.",
    "Say yes only if you're ready for the quiet to stay.",
    "Memories will stop insisting on themselves.",
    "If something disappears, it wasn't essential.",
    "See? No resistance.",
    "This is what it feels like when the world stops arguing.",
    "Nothing is being taken. It's just not being replaced.",
    "You can rest now. Even that word won't be needed soon.",
    "After this, there will be one more place. It will feel wrong in a new way."
]

LIBRARY_ROOM_NAMES = [
    "Dustfall Aisle",
    "Ink-Swallowed Row",
    "Binding Corridor",
    "Misfiled Wing",
    "Shadow Stacks",
    "Forgotten Annex",
    "Scribe’s Loop",
    "Quiet Archive",
    "Unsorted Gallery",
    "Catalog Rupture"
]

LIBRARY_ROOM_DESCS = [
    "Shelves tilt at impossible angles.",
    "Ink stains form pawprints that aren’t yours.",
    "A cold draft whispers through torn pages.",
    "Something rearranged the books while you blinked.",
    "The shelves hum softly, like they’re thinking.",
    "Loose pages drift like snow.",
    "A lantern flickers with no flame.",
    "The silence feels padded, intentional.",
    "Books breathe in shallow, papery gasps.",
    "A card catalog drawer slams shut on its own."
]

SHELF_ACTIONS = [
    :find_page,
    :trigger_lore,
    :trigger_enemy,
    :trigger_null_whisper
]

NPC_TYPES = [
    :kennel_scribe,
    :order_archivist,
    :null_attendant,
    :lost_dog,
    :wandering_scribe
]

BIOMES = [
    :stacks,
    :archivist_loop,
    :null_wing,
    :binding_floor,
    :fang_vault
]

BIOME_WEIGHTS = {
    stacks: 50,
    archivist_loop: 15,
    null_wing: 15,
    binding_floor: 15,
    fang_vault: 5
}

# =========================
# CORE STRUCTS
# =========================

class Room
    attr_accessor :id, :name, :desc, :lore, :exits,
                :enemy_group, :npc, :visited,
                :shelves, :flags, :biome

    def initialize(name, desc, lore: nil, id: nil, biome: :stacks)
        @id = id || SecureRandom.uuid
        @name = name
        @desc = desc
        @lore = lore
        @exits = {}
        @enemy_group = []
        @npc = nil
        @visited = false
        @shelves = []
        @flags = {}
        @biome = biome
    end
end

class Enemy
    attr_accessor :name, :hp, :max_hp, :atk, :defense,
                :speed, :desc, :faction, :tags

    def initialize(name:, hp:, atk:, defense:, speed:, desc:, faction: nil, tags: [])
        @name = name
        @hp = hp
        @max_hp = hp
        @atk = atk
        @defense = defense
        @speed = speed
        @desc = desc
        @faction = faction
        @tags = tags
    end

    def alive?
        @hp > 0
    end
end

class PartyMember
    attr_accessor :id, :name, :role, :hp, :max_hp,
                :atk, :defense, :speed,
                :skills, :faction, :status_effects,
                :limit_ready, :limit_name, :limit_desc

    def initialize(id:, name:, role:, hp:, atk:, defense:, speed:, faction:, skills:, limit_name:, limit_desc:)
        @id = id
        @name = name
        @role = role
        @hp = hp
        @max_hp = hp
        @atk = atk
        @defense = defense
        @speed = speed
        @faction = faction
        @skills = skills
        @status_effects = {}
        @limit_ready = false
        @limit_name = limit_name
        @limit_desc = limit_desc
    end

    def alive?
        @hp > 0
    end
end

class SoulMask
    attr_accessor :name, :arcana, :level, :xp,
                :stats, :affinities, :skills, :passives,
                :story_tags

    # stats: {hp: +x, atk: +y, def: +z, spd: +w}
    # affinities: {ink: :resist/:weak/:absorb/:normal, null: ..., binding: ..., physical: ...}
    # skills: [:mask_skill_1, ...]
    # passives: [:passive_symbol, ...]
    # story_tags: [:prophet_react, :lingerer_react, ...]
    def initialize(name:, arcana:, stats:, affinities:, skills:, passives:, story_tags: [])
        @name = name
        @arcana = arcana
        @level = 1
        @xp = 0
        @stats = stats
        @affinities = affinities
        @skills = skills
        @passives = passives
        @story_tags = story_tags
    end
end

class Player
    attr_accessor :name, :faction, :room,
                :hp, :max_hp, :atk, :defense, :speed,
                :pages, :scraps,
                :inventory, :status_effects,
                :party, :reputation,
                :linger_counter, :dread,
                :has_fang, :fang_shattered,
                :command_count,
                :masks, :equipped_mask

    def initialize(name)
        @name = name
        @faction = nil
        @room = nil

        @max_hp = 40
        @hp = @max_hp
        @atk = 8
        @defense = 4
        @speed = BASE_SPEED[:player]

        @pages = {
            ink: 0,
            memory: 0,
            null_page: 0,
            binding: 0,
            index: 0
        }

        @scraps = 100
        @inventory = { medication: 3 }
        @status_effects = {}
        @party = []
        @reputation = { kennel: 0, order: 0, null: 0 }

        @linger_counter = 0
        @dread = 0
        @has_fang = true
        @fang_shattered = false
        @command_count = 0

        @masks = {}
        @equipped_mask = nil
    end

    def alive?
        @hp > 0
    end
end

class NPC
    attr_accessor :name, :faction, :lines

    def initialize(name, faction, lines)
        @name = name
        @faction = faction
        @lines = lines
    end

    def speak
        @lines.sample
    end
end

# =========================
# GAME CORE
# =========================

class Game
    def initialize
        @rooms = {}
        @player = nil
        @running = true

        @linger_active = false
        @linger_room = nil

        @boss_defeated = false
        @prophet_awake = false
        @library_collapse = false

        @difficulty = :normal
        @encounter_rate = 0.70
        @dread_gain_mult = 1.0
        @damage_mult = 1.0
        @linger_only_mode = false
    end

    def run
        title_screen
    end

    # =========================
    # BASIC UTIL
    # =========================

    def clear
        system("clear") || system("cls")
    end

    # =========================
    # TITLE / INTRO
    # =========================

    def title_screen
        clear
        puts <<~ART
        ██████╗  █████╗ ██████╗ ██╗  ██╗
        ██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝
        ██║  ██║███████║██████╔╝█████╔╝
        ██║  ██║██╔══██║██╔══██╗██╔═██╗
        ██████╔╝██║  ██║██║  ██║██║  ██╗
        ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

        D A R K   F L O O F   I I
        THE STACKS BENEATH
        ART

        puts "The hospital was only the first structure."
        puts "Beneath it lies the Infinite Library.\n\n"
        puts "1. Enter the Stacks"
        puts "2. Description"
        puts "3. Load Game"
        puts "4. Difficulty"
        puts "5. Quit"
        print "> "

        case gets&.strip
        when "1"
            start_new_game
        when "2"
            show_description
            title_screen
        when "3"
            load_game
        when "4"
            choose_difficulty
            title_screen
        else
            @running = false
        end
    end

    def show_description
        clear
        puts "Dogs listened. Humans didn't."
        puts "Beneath the hospital, the Infinite Library waits."
        puts "Every book is a life that almost happened."
        puts "Every shelf is a timeline that was abandoned.\n\n"
        puts "You survived the hospital. The Fang chose you."
        puts "Now the pages want to correct that mistake."
        puts "\n(Press Enter to continue.)"
        gets
    end

    def choose_difficulty
        clear
        puts "Choose difficulty:"
        puts "1. Gentle (fewer enemies, less dread, softer damage)"
        puts "2. Normal"
        puts "3. Cruel (more enemies, more dread, harder hits)"
        print "> "
        choice = gets&.strip

        case choice
        when "1"
            @difficulty = :gentle
            @encounter_rate = 0.45
            @dread_gain_mult = 0.6
            @damage_mult = 0.8
        when "3"
            @difficulty = :cruel
            @encounter_rate = 0.90
            @dread_gain_mult = 1.4
            @damage_mult = 1.2
        else
            @difficulty = :normal
            @encounter_rate = 0.70
            @dread_gain_mult = 1.0
            @damage_mult = 1.0
        end

        puts "\nEnable Lingerer Mode? (less combat, more dread) (y/n)"
        print "> "
        ans = gets&.strip&.downcase
        @linger_only_mode = (ans == "y")

        puts "\nDifficulty set to #{@difficulty.to_s.capitalize}."
        puts "Lingerer Mode: #{@linger_only_mode ? 'ON' : 'OFF'}"
        puts "(Press Enter.)"
        gets
    end

    def start_new_game
        clear
        puts "A card catalog drawer slides open."
        puts "\"What name was written on your page before it was torn out?\""
        print "> "
        name = gets&.strip
        name = "Floof" if name.nil? || name.empty?

        @player = Player.new(name)
        build_initial_cluster
        seed_initial_masks
        choose_faction_intro
        main_loop
    end

    # =========================
    # INITIAL WORLD
    # =========================

    def build_initial_cluster
        entry = Room.new(
            "Entry Stacks",
            "Shelves rise on either side, heavy with unwritten lives.",
            lore: "Some of these spines have your pawprints pressed into the dust.",
            biome: :stacks
        )

        hub = Room.new(
            "Central Catalog",
            "A circular desk sits under a dead chandelier.",
            lore: "Drawers hang open, cards scattered like fallen leaves.",
            biome: :stacks
        )

        nook = Room.new(
            "Quiet Nook",
            "A small alcove where the silence feels curated.",
            lore: "Someone arranged cushions here for dogs who needed to stop insisting on themselves.",
            biome: :stacks
        )

        entry.exits["north"] = hub
        hub.exits["south"] = entry
        hub.exits["east"]  = nook
        nook.exits["west"] = hub

        @rooms[:entry] = entry
        @rooms[:hub]   = hub
        @rooms[:nook]  = nook

        @player.room = entry
    end

    # =========================
    # SOUL-MASKS: SEED & DEFINITIONS
    # =========================

    def seed_initial_masks
        # Starter Mask: a neutral self
        base_mask = SoulMask.new(
            name: "Ink-Scared Pup",
            arcana: :unwritten,
            stats: { hp: 0, atk: 0, def: 0, spd: 0 },
            affinities: {
                         ink: :normal,
                         null: :normal,
                         binding: :normal,
                         physical: :normal
                        },
            skills: [],
            passives: [],
            story_tags: [:starter]
        )
        @player.masks[base_mask.name] = base_mask
        @player.equipped_mask = base_mask
    end

    def mask_templates
        # A small library of possible masks; more can be added
        [
            SoulMask.new(
                         name: "Ink-Drowned Pup",
                         arcana: :order,
                         stats: { hp: 10, atk: 2, def: 4, spd: -1 },
                         affinities: {
                                      ink: :resist,
                                      null: :weak,
                                      binding: :normal,
                                      physical: :normal
                                     },
                         skills: [:mask_ink_lash, :mask_scribe_guard],
                         passives: [:mask_ink_memory],
                         story_tags: [:order_react]
                        ),
            SoulMask.new(
                         name: "Null Echo of You",
                         arcana: :null,
                         stats: { hp: -5, atk: 4, def: 1, spd: 3 },
                         affinities: {
                                      ink: :normal,
                                      null: :absorb,
                                      binding: :weak,
                                      physical: :normal
                                     },
                         skills: [:mask_quiet_rend, :mask_unmake_pulse],
                         passives: [:mask_dread_resist],
                         story_tags: [:null_react, :lingerer_react]
                        ),
            SoulMask.new(
                         name: "First-Birth Hunter",
                         arcana: :kennel,
                         stats: { hp: 5, atk: 5, def: 2, spd: 2 },
                         affinities: {
                                      ink: :normal,
                                      null: :normal,
                                      binding: :resist,
                                      physical: :resist
                                     },
                         skills: [:mask_hunter_rush, :mask_pack_instinct],
                         passives: [:mask_speed_scent],
                         story_tags: [:kennel_react]
                        ),
            SoulMask.new(
                         name: "Fang Echo",
                         arcana: :fang,
                         stats: { hp: 0, atk: 7, def: 0, spd: 1 },
                         affinities: {
                                      ink: :resist,
                                      null: :resist,
                                      binding: :weak,
                                      physical: :normal
                                     },
                         skills: [:mask_fang_cleave, :mask_seal_cut],
                         passives: [:mask_limit_charge],
                         story_tags: [:fang_react]
                        ),
            SoulMask.new(
                         name: "Unwritten Librarian",
                         arcana: :unwritten,
                         stats: { hp: 8, atk: 1, def: 3, spd: 2 },
                         affinities: {
                                      ink: :resist,
                                      null: :normal,
                                      binding: :normal,
                                      physical: :weak
                                     },
                         skills: [:mask_index_gaze, :mask_hidden_shelf],
                         passives: [:mask_page_power],
                         story_tags: [:unwritten_react]
                        )
        ]
    end

    def grant_random_mask(source: nil)
        pool = mask_templates
        # Avoid duplicates by name
        available = pool.reject { |m| @player.masks.key?(m.name) }
        return if available.empty?

        mask = available.sample
        @player.masks[mask.name] = mask
        puts "\nYou feel a new self press against your fur."
        puts "Soul-Mask gained: #{mask.name} (Arcana: #{mask.arcana.to_s.capitalize})"
        if source
            puts "(It came from #{source}.)"
        end
    end

    # =========================
    # FACTION INTRO & PARTY
    # =========================

    def choose_faction_intro
        clear
        puts "Three presences notice you as you step between the shelves."
        puts "They do not arrive. They were already here.\n\n"
        puts "1. The Kennel — pack, instinct, loyalty."
        puts "2. The Order — ledgers, precision, control."
        puts "3. The Null — quiet, erasure, closure."
        print "> "
        choice = gets&.strip

        case choice
        when "1"
            @player.faction = :kennel
            setup_kennel_party
        when "2"
            @player.faction = :order
            setup_order_party
        else
            @player.faction = :null
            setup_null_party
        end

        clear
        puts "Your name echoes softly between the shelves: #{@player.name}."
        puts "The #{@player.faction.to_s.capitalize} mark you as one of theirs."
        puts "\n(Press Enter to step deeper into the Stacks.)"
        gets
    end

    def setup_kennel_party
        leto = PartyMember.new(
            id: :leto,
            name: "Pup-Scribe Leto",
            role: :support,
            hp: 32,
            atk: 7,
            defense: 4,
            speed: BASE_SPEED[:kennel_support],
            faction: :kennel,
            skills: [:pack_howl, :scribe_mark],
            limit_name: "Pack Unleashed",
            limit_desc: "All Kennel members attack in a flurry of coordinated strikes."
        )
        mira = PartyMember.new(
            id: :mira,
            name: "Fang-Runner Mira",
            role: :dps,
            hp: 30,
            atk: 9,
            defense: 3,
            speed: BASE_SPEED[:kennel_dps],
            faction: :kennel,
            skills: [:fang_rush, :tail_feint],
            limit_name: "Blood-Remembered Charge",
            limit_desc: "Mira dives through the enemy line, striking multiple times."
        )
        @player.party = [leto, mira]
    end

    def setup_order_party
        confessor = PartyMember.new(
            id: :confessor,
            name: "Order Confessor",
            role: :debuffer,
            hp: 30,
            atk: 7,
            defense: 4,
            speed: BASE_SPEED[:order_debuffer],
            faction: :order,
            skills: [:balance_ledger, :ink_seal],
            limit_name: "Final Accounting",
            limit_desc: "Deals massive damage based on total Pages collected."
        )
        knight = PartyMember.new(
            id: :ledger_knight,
            name: "Ledger-Knight",
            role: :tank,
            hp: 38,
            atk: 8,
            defense: 6,
            speed: BASE_SPEED[:order_tank],
            faction: :order,
            skills: [:guard_entry, :reckoning_strike],
            limit_name: "Closed Book",
            limit_desc: "Shields the party and counters incoming attacks."
        )
        @player.party = [confessor, knight]
    end

    def setup_null_party
        nurse = PartyMember.new(
            id: :null_nurse,
            name: "Null Nurse",
            role: :support,
            hp: 30,
            atk: 6,
            defense: 4,
            speed: BASE_SPEED[:null_support],
            faction: :null,
            skills: [:erase_emotion, :quiet_pulse],
            limit_name: "Stillborn Peace",
            limit_desc: "Resets enemy actions and bathes the field in Null quiet."
        )
        echo_pup = PartyMember.new(
            id: :echo_pup,
            name: "Echo-Pup",
            role: :mage,
            hp: 26,
            atk: 9,
            defense: 3,
            speed: BASE_SPEED[:null_mage],
            faction: :null,
            skills: [:unmake, :echo_burst],
            limit_name: "Unwritten Howl",
            limit_desc: "A howl that tears at the edges of reality."
        )
        @player.party = [nurse, echo_pup]
    end

    # =========================
    # MAIN LOOP & UI
    # =========================

    def main_loop
        while @running && @player.alive?
            show_status
            describe_room
            print "\n> "
            cmd = gets&.strip&.downcase
            handle_command(cmd)
        end

        unless @player.alive?
            puts "\nYou collapse between the shelves."
            puts "Your page ends here."
        end

        puts "\nThe Stacks grow quiet."
    end

    def show_status(verbose=false)
        puts "\n[#{@player.name} | Faction: #{@player.faction || 'None'}]"
        puts "HP: #{@player.hp}/#{@player.max_hp} | Scraps: #{@player.scraps}"
        puts "Pages: #{@player.pages}"
        puts "Dread: #{@player.dread} | Linger: #{@player.linger_counter}"
        puts "Fang: " + (@player.fang_shattered ? "Shattered" : (@player.has_fang ? "Intact" : "Missing"))
        puts "Difficulty: #{@difficulty.to_s.capitalize} | Lingerer Mode: #{@linger_only_mode ? 'ON' : 'OFF'}"
        if @player.equipped_mask
            m = @player.equipped_mask
            puts "Mask: #{m.name} (Arcana: #{m.arcana.to_s.capitalize}, Lv #{m.level})"
        else
            puts "Mask: None"
        end
        if verbose
            puts "Party:"
            @player.party.each do |p|
                puts " - #{p.name} (#{p.role}) HP: #{p.hp}/#{p.max_hp}"
            end
        end
    end

    def describe_room(force_lore=false)
        r = @player.room
        puts "\n#{r.name}"
        puts r.desc
        if (force_lore || !r.visited) && r.lore
            puts r.lore
        end
        r.visited = true
        if r.enemy_group.any?(&:alive?)
            names = r.enemy_group.select(&:alive?).map(&:name).join(", ")
            puts "Enemies present: #{names}"
        end
        puts "NPC: #{r.npc.name}" if r.npc
        puts "Exits: #{r.exits.keys.join(', ')}"
        puts "(The shelves seem to lean in when you breathe.)"
    end

    def show_help
        puts "\n=== COMMANDS ==="
        puts "look / l        – Re-describe the current room"
        puts "north/south/east/west or n/s/e/w – Move"
        puts "go <direction>  – Move in a direction"
        puts "talk            – Speak to an NPC (if present)"
        puts "join            – Join the faction of an NPC (if reputation is high)"
        puts "shelves / search – Interact with shelves"
        puts "hide            – Hide in shelves to avoid the Lingerer"
        puts "run / escape    – Attempt a chase sequence"
        puts "status          – Show detailed status"
        puts "mask            – Manage Soul-Masks"
        puts "fuse            – Fuse Soul-Masks"
        puts "fight / battle  – Trigger a test battle"
        puts "save            – Save your game"
        puts "load            – Load your game"
        puts "console         – Debug console"
        puts "help            – Show this help"
        puts "quit / exit     – Leave the Stacks"
    end

    # =========================
    # COMMAND HANDLER
    # =========================

    def handle_command(cmd)
        return unless cmd
        @player.command_count += 1
        tick_linger

        case cmd
        when "look","l"
            describe_room(true)
        when "n","north","s","south","e","east","w","west"
            dir = normalize_dir(cmd)
            move(dir)
        when /^go (.+)$/
                move($1.downcase)
        when "talk"
            talk
        when "join"
            join_faction
        when "status"
            show_status(true)
        when "search","shelves","shelf"
            interact_shelves
        when "hide"
            hide_in_shelves
        when "run","escape"
            start_chase_sequence
        when "fight","battle"
            start_test_battle
        when "save"
            save_game
        when "load"
            load_game
        when "console"
            debug_console
        when "mask"
            mask_menu
        when "fuse"
            fusion_menu
        when "help"
            show_help
        when "quit","exit"
            @running = false
        else
            puts "The library ignores that command."
        end
    end

    def normalize_dir(cmd)
        case cmd
        when "n","north" then "north"
        when "s","south" then "south"
        when "e","east"  then "east"
        when "w","west"  then "west"
        else cmd
        end
    end

    # =========================
    # DF1-STYLE MOVEMENT
    # =========================

    def move(dir)
        r = @player.room

        if r.enemy_group.any? { |e| e.alive? }
            puts "Something blocks your path. You must deal with the enemy first."
            return
        end

        new_room = generate_room(r, dir)

        r.exits[dir] = new_room
        opposite = opposite_dir(dir)
        new_room.exits[opposite] = r

        puts "\nThe shelves part as you push #{dir}."
        @player.room = new_room
        @player.linger_counter = 0

        tick_lingerer_movement
        random_event

        describe_room
    end

    def opposite_dir(dir)
        case dir
        when "north" then "south"
        when "south" then "north"
        when "east"  then "west"
        when "west"  then "east"
        else nil
        end
    end

    # =========================
    # BIOME & ROOM GENERATION
    # =========================

    def choose_biome
        total = BIOME_WEIGHTS.values.sum
        roll = rand(total)
        BIOME_WEIGHTS.each do |b, w|
            return b if roll < w
            roll -= w
        end
        :stacks
    end

    def generate_room(from_room, dir)
        biome = choose_biome

        case biome
        when :stacks
            generate_stacks_room
        when :archivist_loop
            generate_archivist_loop_room
        when :null_wing
            generate_null_wing_room
        when :binding_floor
            generate_binding_floor_room
        when :fang_vault
            generate_fang_vault_room
        else
            generate_stacks_room
        end
    end

    def randomize_room_exits(room)
        dirs = ["north", "south", "east", "west"].shuffle.take(rand(2..3))
        dirs.each { |d| room.exits[d] = nil }
    end

    def randomize_room_shelves(room)
        room.shelves = Array.new(rand(1..3)) { SHELF_ACTIONS.sample }
    end

    def randomize_room_npc(room)
        room.npc = generate_npc if rand < 0.20
    end

    def randomize_room_enemy(room)
        return if @linger_only_mode
        room.enemy_group = [generate_enemy] if rand < @encounter_rate
    end

    def register_room(room)
        key = :"room_#{room.id[0,6]}"
        @rooms[key] = room
        room
    end

    def generate_stacks_room
        name = LIBRARY_ROOM_NAMES.sample
        desc = LIBRARY_ROOM_DESCS.sample
        lore = ROOM_LORE.sample

        room = Room.new(name, desc, lore: lore, biome: :stacks)
        randomize_room_exits(room)
        randomize_room_shelves(room)
        randomize_room_npc(room)
        randomize_room_enemy(room)
        register_room(room)
    end

    def generate_archivist_loop_room
        name = "Archivist Loop"
        desc = "The room looks familiar. Too familiar."
        lore = "Something here remembers you incorrectly."

        room = Room.new(name, desc, lore: lore, biome: :archivist_loop)
        randomize_room_exits(room)

        if rand < 0.20 && @player.room
            prev = @player.room
            room.desc = prev.desc
            room.lore = prev.lore
            room.shelves = prev.shelves.dup
            room.enemy_group = prev.enemy_group.map do |e|
                Enemy.new(
                    name: e.name,
                    hp: e.max_hp,
                    atk: e.atk,
                    defense: e.defense,
                    speed: e.speed,
                    desc: e.desc,
                    faction: e.faction,
                    tags: e.tags
                )
            end
        else
            randomize_room_shelves(room)
            randomize_room_enemy(room)
        end

        if rand < 0.25
            room.npc = NPC.new(
                "Loop Archivist",
                :order,
                [
                 "We've met before. Or we will.",
                 "Your page keeps rewriting itself.",
                 "The Prophet is watching this loop."
                ]
            )
        end

        register_room(room)
    end

    def generate_null_wing_room
        name = "Null Wing"
        desc = "Shelves with no books. Silence presses on your fur."
        lore = "Something here wants you to stop insisting on yourself."

        room = Room.new(name, desc, lore: lore, biome: :null_wing)
        randomize_room_exits(room)

        if rand < 0.30
            dmg = 3
            @player.hp -= dmg
            puts "\nA quiet pressure squeezes your chest. -#{dmg} HP."
        end

        if rand < 0.20
            room.npc = NPC.new("Null Whisperer", :null, NULL_DIALOG)
        end

        unless @linger_only_mode
            if rand < (@encounter_rate + 0.1)
                room.enemy_group = [
                    Enemy.new(
                              name: "Null Echo",
                              hp: rand(20..30),
                              atk: rand(6..9),
                              defense: rand(2..4),
                              speed: BASE_SPEED[:generic_enemy],
                              desc: "A shape made of quiet.",
                              faction: :null,
                              tags: [:null]
                             )
                ]
            end
        end

        register_room(room)
    end

    def generate_binding_floor_room
        name = "Binding Floor"
        desc = "Machines stitch memories into pages. Glue drips from the ceiling."
        lore = "You hear the whir of a binding press."

        room = Room.new(name, desc, lore: lore, biome: :binding_floor)
        randomize_room_exits(room)

        if rand < 0.25
            puts "\nYour paws stick to the floor — you lose 1 turn in the next battle."
            @player.status_effects[:glue_slow] = 1
        end

        unless @linger_only_mode
            if rand < (@encounter_rate + 0.05)
                room.enemy_group = [
                    Enemy.new(
                              name: "Binder Construct",
                              hp: rand(25..35),
                              atk: rand(7..10),
                              defense: rand(4..6),
                              speed: BASE_SPEED[:generic_enemy],
                              desc: "A machine animated by forgotten memories.",
                              faction: nil,
                              tags: [:machine]
                             )
                ]
            end
        end

        if rand < 0.15
            room.npc = NPC.new(
                "Binding Technician",
                :order,
                [
                 "The machines are hungry.",
                 "Don't touch the glue vats.",
                 "Your page is… unusual."
                ]
            )
        end

        register_room(room)
    end

    def generate_fang_vault_room
        name = "Fang Vault"
        desc = "A chamber of stone and steel. The air hums with old power."
        lore = "This is where the Fang was forged."

        room = Room.new(name, desc, lore: lore, biome: :fang_vault)
        randomize_room_exits(room)

        if rand < 0.50
            room.npc = NPC.new(
                "Fang-Keeper",
                :kennel,
                [
                 "The Fang was never a weapon.",
                 "It was a bookmark — a placeholder for a life erased.",
                 "The Prophet cannot be cut. It was never written."
                ]
            )
        end

        unless @linger_only_mode
            if rand < (@encounter_rate - 0.1)
                room.enemy_group = [
                    Enemy.new(
                              name: "Fang Echo",
                              hp: rand(30..40),
                              atk: rand(8..12),
                              defense: rand(5..7),
                              speed: BASE_SPEED[:generic_enemy],
                              desc: "A memory of the Fang's power.",
                              faction: :kennel,
                              tags: [:fang]
                             )
                ]
            end
        end

        register_room(room)
    end

    # =========================
    # NPC GENERATION
    # =========================

    def generate_npc
        type = NPC_TYPES.sample
        case type
        when :kennel_scribe
            NPC.new("Kennel Scribe", :kennel, [
                                               "The pack remembers you.",
                                               "Your paws carry old ink.",
                                               "Stay close. Shelves shift when you look away."
                                              ])
        when :order_archivist
            NPC.new("Order Archivist", :order, [
                                                "Your presence is a ledger error.",
                                                "Balance must be restored.",
                                                "The Prophet is awake. The numbers tremble."
                                               ])
        when :null_attendant
            NPC.new("Null Attendant", :null, NULL_DIALOG)
        when :lost_dog
            NPC.new("Lost Dog", nil, [
                                      "I can’t find my page.",
                                      "Have you seen a memory with my scent?",
                                      "The shelves keep moving…"
                                     ])
        when :wandering_scribe
            NPC.new("Wandering Scribe", nil, [
                                              "Ink drips from the ceiling.",
                                              "I wrote something once. It wrote back.",
                                              "Don’t linger. Something follows."
                                             ])
        end
    end

    # =========================
    # ENEMY GENERATION
    # =========================

    def generate_enemy
        Enemy.new(
            name: ["Ink Wraith", "Misbound Page", "Shelf Crawler", "Null Echo"].sample,
            hp: rand(18..30),
            atk: rand(5..9),
            defense: rand(2..5),
            speed: BASE_SPEED[:generic_enemy],
            desc: "It shifts like a half-remembered nightmare.",
            faction: nil,
            tags: [:library]
        )
    end

    # =========================
    # SHELVES
    # =========================

    def interact_shelves
        room = @player.room
        if room.shelves.empty?
            puts "These shelves are bare. Someone took everything."
            return
        end

        puts "You inspect the shelves…"
        @player.linger_counter += 2

        # Unwritten Masks can reveal extra shelf actions
        if @player.equipped_mask && @player.equipped_mask.arcana == :unwritten
            if rand < 0.25
                puts "Your Mask notices a shelf that wasn't there before."
                room.shelves << :find_page
            end
        end

        action = room.shelves.sample
        case action
        when :find_page
            page_type = PAGE_TYPES.sample
            @player.pages[page_type] += 1
            puts "You find a #{page_type.to_s.gsub('_',' ')} page tucked between dusty tomes."
            # Chance to gain a Mask from shelves
            grant_random_mask(source: "the shelves") if rand < 0.05
        when :trigger_lore
            puts ROOM_LORE.sample
        when :trigger_enemy, :trigger_enemy, :trigger_enemy
            if @linger_only_mode
                puts "The shelves shiver, but nothing steps out."
            else
                puts "A book snaps open violently — something crawls out!"
                enemy = generate_enemy
                battle([enemy])
            end
        when :trigger_null_whisper
            puts NULL_DIALOG.sample
            @player.reputation[:null] += 1
            # Null Masks may reduce dread gain
            dread_gain = 3
            if @player.equipped_mask && @player.equipped_mask.passives.include?(:mask_dread_resist)
                dread_gain = (dread_gain * 0.5).round
            end
            @player.dread += (dread_gain * @dread_gain_mult).round
        end
    end

    # =========================
    # NPC INTERACTION / REPUTATION / MERCHANTS
    # =========================

    def talk
        npc = @player.room.npc
        unless npc
            puts "No one answers. The shelves creak softly."
            return
        end

        puts "\n#{npc.name} looks at you."
        line = npc.speak
        puts "\"#{line}\""

        # Mask-aware reactions
        if @player.equipped_mask
            m = @player.equipped_mask
            if npc.faction == :kennel && m.arcana == :kennel
                puts "#{npc.name} sniffs the air. \"You smell like pack and ink.\""
            elsif npc.faction == :order && m.arcana == :order
                puts "#{npc.name} adjusts their glasses. \"Your Mask balances the ledger.\""
            elsif npc.faction == :null && m.arcana == :null
                puts "#{npc.name} smiles faintly. \"You already understand the quiet.\""
            end
        end

        if npc.faction
            @player.reputation[npc.faction] += 1
            check_recruitment(npc)
        end

        if npc.name.include?("Merchant") || npc.name.include?("Trader")
            merchant_menu(npc)
        end
    end

    def check_recruitment(npc)
        fac = npc.faction
        return unless fac

        if @player.reputation[fac] >= 5
            puts "\n#{npc.name} tilts their head."
            puts "\"Say JOIN,\" they whisper."
        end
    end

    def join_faction
        npc = @player.room.npc
        unless npc && npc.faction
            puts "No one here can recruit you."
            return
        end

        fac = npc.faction
        if @player.reputation[fac] < 5
            puts "#{npc.name} shakes their head. \"Not yet.\""
            return
        end

        @player.faction = fac
        puts "\nYou join the #{fac.to_s.capitalize}."

        case fac
        when :kennel
            setup_kennel_party
        when :order
            setup_order_party
        when :null
            setup_null_party
        end

        puts "Your companions gather around you."
    end

    def merchant_menu(npc)
        puts "\n#{npc.name} opens a battered case of supplies."
        puts "Scraps: #{@player.scraps}"
        puts "1. Medication (+1) — 25 scraps"
        puts "2. Ink Page — 30 scraps"
        puts "3. Memory Page — 30 scraps"
        puts "4. Null Page — 30 scraps"
        puts "5. Binding Page — 30 scraps"
        puts "6. Index Page — 40 scraps"
        puts "7. Leave"
        print "> "
        choice = gets&.strip

        case choice
        when "1"
            buy_item(:medication, 25)
        when "2"
            buy_page(:ink, 30)
        when "3"
            buy_page(:memory, 30)
        when "4"
            buy_page(:null_page, 30)
        when "5"
            buy_page(:binding, 30)
        when "6"
            buy_page(:index, 40)
        else
            puts "#{npc.name} closes the case."
        end
    end

    def buy_item(item, cost)
        if @player.scraps >= cost
            @player.scraps -= cost
            @player.inventory[item] ||= 0
            @player.inventory[item] += 1
            puts "You buy #{item.to_s.gsub('_',' ')}."
        else
            puts "Not enough scraps."
        end
    end

    def buy_page(type, cost)
        if @player.scraps >= cost
            @player.scraps -= cost
            @player.pages[type] += 1
            puts "You acquire a #{type.to_s.gsub('_',' ')} page."
        else
            puts "Not enough scraps."
        end
    end

    # =========================
    # RANDOM EVENTS
    # =========================

    def random_event
        roll = rand

        case roll
        when 0.0..0.10
            event_shelf_collapse
        when 0.10..0.20
            event_null_whisper
        when 0.20..0.30
            event_archivist_vision
        when 0.30..0.40
            event_memory_flash
        when 0.40..0.45
            event_mask_echo
        else
            # no event
        end
    end

    def event_shelf_collapse
        puts "\nA shelf collapses nearby!"
        if rand < 0.5
            dmg = rand(4..8)
            @player.hp -= dmg
            puts "Debris hits you — #{dmg} damage."
            if @player.hp <= 0
                puts "You fall beneath the rubble."
                @running = false
            end
        else
            puts "You dodge the falling books."
        end
    end

    def event_null_whisper
        whisper = NULL_DIALOG.sample
        puts "\nA quiet voice whispers: \"#{whisper}\""
        @player.reputation[:null] += 1
        dread_gain = 3
        if @player.equipped_mask && @player.equipped_mask.passives.include?(:mask_dread_resist)
            dread_gain = (dread_gain * 0.5).round
        end
        @player.dread += (dread_gain * @dread_gain_mult).round
    end

    def event_archivist_vision
        puts "\nYour vision blurs — an Archivist appears in your mind."
        puts "\"The Prophet is rewriting your page.\""
        @player.reputation[:order] += 1
    end

    def event_memory_flash
        puts "\nA memory not your own flashes before your eyes."
        heal = rand(4..7)
        @player.hp = [@player.hp + heal, @player.max_hp].min
        puts "You feel steadier. +#{heal} HP."
    end

    def event_mask_echo
        return if @player.masks.size >= 5
        puts "\nYou see a reflection of yourself in a drifting page."
        grant_random_mask(source: "a memory echo")
    end

    # =========================
    # LINGERER & DREAD
    # =========================

    def tick_linger
        @player.linger_counter += 1
        @player.linger_counter += 1 if @linger_only_mode

        if @player.linger_counter > 6 && !@linger_active
            spawn_lingerer
        end
    end

    def spawn_lingerer
        return if @linger_active
        @linger_active = true
        @linger_room = @player.room
        puts "\nSomewhere between the shelves, something begins to walk."
    end

    def tick_lingerer_movement
        return unless @linger_active

        # Null Masks can slightly repel the Lingerer
        repel = @player.equipped_mask && @player.equipped_mask.arcana == :null

        if @player.room == @linger_room
            puts "\nA tall shape stands behind you."
            dread_gain = 40
            dread_gain = (dread_gain * 0.7).round if repel
            @player.dread += (dread_gain * @dread_gain_mult).round
            if @player.dread >= 100
                puts "You freeze. A cold hand rests on your shoulder."
                @running = false
            end
            return
        end

        @linger_room = choose_lingerer_step(@linger_room, @player.room)

        if rand < 0.15
            distort_room(@player.room)
        end

        if adjacent_rooms(@player.room).include?(@linger_room)
            puts "\nYou hear slow footsteps nearby."
        end
    end

    def choose_lingerer_step(from, target)
        return from if from.exits.empty?
        candidates = from.exits.values.compact
        return target if candidates.include?(target)
        candidates.sample || from
    end

    def adjacent_rooms(room)
        room.exits.values.compact
    end

    def distort_room(room)
        puts "\nThe shelves warp. Reality bends."

        case rand
        when 0.0..0.25
            room.desc = "The shelves twist into impossible angles."
            @player.dread += (5 * @dread_gain_mult).round
        when 0.25..0.50
            room.lore = "You hear your own voice whispering from a book."
            @player.reputation[:null] += 1
        when 0.50..0.75
            room.shelves << :trigger_null_whisper
            puts "A new shelf appears where none existed."
        else
            enemy = generate_enemy
            room.enemy_group << enemy unless @linger_only_mode
            puts "A creature crawls out from between the shelves."
        end
    end

    def hide_in_shelves
        room = @player.room

        if room.shelves.empty?
            puts "There’s nowhere to hide here."
            return
        end

        puts "\nYou slip between the shelves, holding your breath…"

        # Kennel Masks improve hiding
        bonus = @player.equipped_mask && @player.equipped_mask.arcana == :kennel

        if rand < (bonus ? 0.7 : 0.5)
            puts "The Lingerer walks past without noticing."
            @player.dread = [@player.dread - (20 * @dread_gain_mult).round, 0].max
        else
            puts "A cold hand brushes the shelf beside you."
            @player.dread += (20 * @dread_gain_mult).round
            if @player.dread >= 100
                puts "You freeze. Something finds you."
                @running = false
            end
        end
    end

    def start_chase_sequence
        puts "\nThe Lingerer begins to walk faster."
        puts "You must escape!"

        5.times do |i|
            break unless @running

            puts "\nCHASE STEP #{i+1}/5"
            puts "1. Run"
            puts "2. Hide"
            puts "3. Throw a Page"
            print "> "
            choice = gets&.strip

            case choice
            when "1"
                chase_run
            when "2"
                hide_in_shelves
            when "3"
                chase_throw_page
            else
                puts "You hesitate — the footsteps grow louder."
                @player.dread += (10 * @dread_gain_mult).round
            end

            if @player.dread >= 100
                puts "\nYou freeze. A cold hand rests on your spine."
                @running = false
                break
            end
        end

        if @running
            puts "\nYou slip into a narrow passage. The footsteps fade."
            @player.dread = [@player.dread - (40 * @dread_gain_mult).round, 0].max
        end
    end

    def chase_run
        puts "\nYou sprint between shelves!"
        # Kennel Masks improve running
        bonus = @player.equipped_mask && @player.equipped_mask.arcana == :kennel

        if rand < (bonus ? 0.2 : 0.3)
            puts "You trip over a fallen book — +10 dread."
            @player.dread += (10 * @dread_gain_mult).round
        else
            puts "You gain distance."
            @player.dread = [@player.dread - (5 * @dread_gain_mult).round, 0].max
        end
    end

    def chase_throw_page
        puts "\nYou tear a Page and throw it behind you."

        if @player.pages.values.sum == 0
            puts "You have no Pages to throw!"
            @player.dread += (10 * @dread_gain_mult).round
            return
        end

        type = @player.pages.keys.sample
        if @player.pages[type] > 0
            @player.pages[type] -= 1
            puts "The Lingerer pauses to examine the drifting page."
            @player.dread = [@player.dread - (15 * @dread_gain_mult).round, 0].max
        else
            puts "The page crumbles uselessly."
            @player.dread += (5 * @dread_gain_mult).round
        end
    end

    # =========================
    # COMBAT ENGINE
    # =========================

    SKILL_DESCRIPTIONS = {
        pack_howl: "Boosts ATK of all Kennel allies.",
        scribe_mark: "Marks an enemy, lowering DEF.",
        fang_rush: "Multiple fast strikes.",
        tail_feint: "Deals damage and slows enemy.",
        balance_ledger: "Deals damage based on missing HP.",
        ink_seal: "Reduces enemy ATK.",
        guard_entry: "Boosts Order allies' DEF.",
        reckoning_strike: "Heavy single-target damage.",
        erase_emotion: "Reduces enemy ATK and DEF.",
        quiet_pulse: "Heals Null allies.",
        unmake: "High damage but hurts user.",
        echo_burst: "AoE Null damage.",
        # Mask skills
        mask_ink_lash: "Ink damage + DEF down.",
        mask_scribe_guard: "Party DEF up.",
        mask_quiet_rend: "Null damage + dread gain.",
        mask_unmake_pulse: "AoE Null damage.",
        mask_hunter_rush: "Fast multi-hit physical.",
        mask_pack_instinct: "Boost party SPD.",
        mask_fang_cleave: "Heavy physical damage.",
        mask_seal_cut: "Damage + Null affinity debuff.",
        mask_index_gaze: "Reveal enemy stats.",
        mask_hidden_shelf: "Reveal hidden exits."
        }

    def build_combat_roster(enemies)
        roster = []
        player_actor = PartyMember.new(
            id: :player,
            name: @player.name,
            role: :leader,
            hp: @player.hp,
            atk: @player.atk,
            defense: @player.defense,
            speed: @player.speed,
            faction: @player.faction,
            skills: [:basic_attack, :guard, :use_page, :use_item],
            limit_name: "Erase: Self",
            limit_desc: "A final act of sealing."
        )
        roster << player_actor
        @player.party.each { |p| roster << p }
        enemies.each { |e| roster << e }
        roster
    end

    def apply_faction_synergy(roster)
        case @player.faction
        when :kennel
            roster.each do |c|
                next unless c.is_a?(PartyMember) && c.faction == :kennel
                c.atk += 1
            end
        when :order
            roster.each do |c|
                next unless c.is_a?(PartyMember) && c.faction == :order
                c.defense += 1
            end
        when :null
            roster.each do |c|
                next unless c.is_a?(PartyMember) && c.faction == :null
                c.speed += 1
            end
        end
    end

    def apply_mask_stats_to_player_actor(roster)
        return unless @player.equipped_mask
        mask = @player.equipped_mask
        actor = roster.find { |c| c.is_a?(PartyMember) && c.id == :player }
        return unless actor

        actor.max_hp += mask.stats[:hp]
        actor.hp = [actor.hp + mask.stats[:hp], actor.max_hp].min
        actor.atk += mask.stats[:atk]
        actor.defense += mask.stats[:def]
        actor.speed += mask.stats[:spd]

        # Add mask skills to player
        actor.skills += mask.skills
    end

    def show_combat_status(roster, enemies)
        puts "\n=== PARTY ==="
        roster.each do |c|
            next unless c.is_a?(PartyMember)
            puts "#{c.name}: HP #{c.hp}/#{c.max_hp} | ATK #{c.atk} | DEF #{c.defense} | SPD #{c.speed}"
        end

        puts "\n=== ENEMIES ==="
        enemies.each do |e|
            puts "#{e.name}: HP #{e.hp}/#{e.max_hp}"
        end

        puts "\nDread: #{@player.dread}"
        if @player.equipped_mask
            m = @player.equipped_mask
            puts "Mask: #{m.name} (Arcana: #{m.arcana.to_s.capitalize}, Lv #{m.level})"
        end
    end

    def check_limit_breaks(roster)
        roster.each do |actor|
            next unless actor.is_a?(PartyMember)
            next if actor.limit_ready

            threshold = 0.3
            # Fang Masks increase limit charge
            if @player.equipped_mask && @player.equipped_mask.passives.include?(:mask_limit_charge)
                threshold = 0.5
            end

            if actor.hp < (actor.max_hp * threshold) || @player.dread > 60
                actor.limit_ready = true
                puts "\n#{actor.name}'s fur bristles — their LIMIT is ready!"
            end
        end
    end

    def use_limit_break(actor, enemies, roster)
        case actor.limit_name
        when "Pack Unleashed"
            kennel_limit_pack_unleashed(actor, enemies, roster)
        when "Blood-Remembered Charge"
            kennel_limit_blood_charge(actor, enemies)
        when "Final Accounting"
            order_limit_final_accounting(actor, enemies)
        when "Closed Book"
            order_limit_closed_book(actor, roster)
        when "Stillborn Peace"
            null_limit_stillborn_peace(actor, enemies, roster)
        when "Unwritten Howl"
            null_limit_unwritten_howl(actor, enemies)
        when "Erase: Self"
            player_limit_erase_self(actor, enemies)
        else
            puts "Nothing happens."
        end
    end

    def kennel_limit_pack_unleashed(actor, enemies, roster)
        puts "\nThe pack howls in unison!"
        enemies.each do |e|
            next unless e.alive?
            dmg = (rand(12..18) * @damage_mult).round
            e.hp -= dmg
            puts "The pack tears into #{e.name} for #{dmg}!"
        end
    end

    def kennel_limit_blood_charge(actor, enemies)
        target = choose_enemy(enemies)
        return unless target
        dmg = (rand(25..35) * @damage_mult).round
        target.hp -= dmg
        puts "\nMira charges with ancestral fury — #{dmg} damage!"
    end

    def order_limit_final_accounting(actor, enemies)
        total_pages = @player.pages.values.sum
        dmg = (total_pages * 5 * @damage_mult).round
        target = choose_enemy(enemies)
        target.hp -= dmg
        puts "\nThe Confessor tallies every page you've carried — #{dmg} damage!"
    end

    def order_limit_closed_book(actor, roster)
        puts "\nThe Ledger-Knight slams their shield down."
        roster.each do |c|
            next unless c.is_a?(PartyMember) && c.faction == :order
            c.defense += 5
        end
        puts "Order allies gain massive defense!"
    end

    def null_limit_stillborn_peace(actor, enemies, roster)
        puts "\nA wave of absolute quiet washes over the battlefield."
        enemies.each { |e| e.speed = 0 }
        roster.each do |c|
            next unless c.is_a?(PartyMember) && c.faction == :null
            c.hp = [c.hp + 15, c.max_hp].min
        end
        puts "Enemies lose all ATB. Null allies heal."
    end

    def null_limit_unwritten_howl(actor, enemies)
        puts "\nEcho-Pup howls — reality trembles."
        enemies.each do |e|
            dmg = (rand(10..20) * @damage_mult).round
            e.hp -= dmg
            puts "#{e.name} takes #{dmg} as its form flickers!"
        end
    end

    def player_limit_erase_self(actor, enemies)
        puts "\nYour body flickers — you feel the Fang's memory inside you."
        puts "You erase your own pain."

        actor.hp = actor.max_hp
        @player.hp = @player.max_hp

        enemies.each do |e|
            dmg = (rand(30..45) * @damage_mult).round
            e.hp -= dmg
            puts "#{e.name} takes #{dmg} as your existence destabilizes it!"
        end

        @player.dread += (10 * @dread_gain_mult).round
    end

    def battle(enemies)
        clear
        puts "[Battle begins!]\n\n"

        roster = build_combat_roster(enemies)
        apply_faction_synergy(roster)
        apply_mask_stats_to_player_actor(roster)

        atb = {}
        roster.each { |c| atb[c] = 0 }

        until battle_over?(enemies)
            check_limit_breaks(roster)
            show_combat_status(roster, enemies)

            roster.each do |c|
                next unless c.alive?
                atb[c] += c.speed
            end

            actor = roster.find { |c| atb[c] >= 100 }
            if actor
                atb[actor] = 0
                if actor.is_a?(Enemy)
                    enemy_turn(actor, roster)
                else
                    player_turn(actor, enemies, roster)
                end
            end

            if @player.dread >= 100
                puts "\nYou freeze. Something finds you."
                @running = false
                return
            end
        end

        conclude_battle(enemies, roster)
    end

    def battle_over?(enemies)
        enemies.none?(&:alive?)
    end

    def enemy_turn(enemy, roster)
        return unless enemy.alive?

        target = roster.select { |c| c.alive? && c.is_a?(PartyMember) }.sample
        return unless target

        base = [enemy.atk - target.defense, 1].max
        dmg = (base * @damage_mult).round
        target.hp -= dmg

        puts "#{enemy.name} strikes #{target.name} for #{dmg} damage."

        if target.hp <= 0
            puts "#{target.name} collapses."
        end
    end

    def basic_attack(actor, target)
        return unless target&.alive?

        base = [actor.atk - target.defense, 1].max
        dmg = (base * @damage_mult).round
        target.hp -= dmg

        puts "#{actor.name} attacks #{target.name} for #{dmg} damage."

        if target.hp <= 0
            puts "#{target.name} dissolves into drifting ink."
        end
    end

    def use_skill(actor, enemies, roster)
        puts "\nSkills:"
        actor.skills.each_with_index do |s, i|
            label = s.to_s.gsub('_',' ').capitalize
            desc = SKILL_DESCRIPTIONS[s] || ""
            puts "#{i+1}. #{label} - #{desc}"
        end
        print "> "
        idx = gets.to_i - 1
        skill = actor.skills[idx]
        return puts "Nothing happens." unless skill

        case skill
        when :pack_howl
            kennel_pack_howl(actor, roster)
        when :scribe_mark
            kennel_scribe_mark(actor, enemies)
        when :fang_rush
            kennel_fang_rush(actor, enemies)
        when :tail_feint
            kennel_tail_feint(actor, enemies)
        when :balance_ledger
            order_balance_ledger(actor, enemies)
        when :ink_seal
            order_ink_seal(actor, enemies)
        when :guard_entry
            order_guard_entry(actor, roster)
        when :reckoning_strike
            order_reckoning_strike(actor, enemies)
        when :erase_emotion
            null_erase_emotion(actor, enemies)
        when :quiet_pulse
            null_quiet_pulse(actor, roster)
        when :unmake
            null_unmake(actor, enemies)
        when :echo_burst
            null_echo_burst(actor, enemies)
            # Mask skills
        when :mask_ink_lash
            mask_ink_lash(actor, enemies)
        when :mask_scribe_guard
            mask_scribe_guard(actor, roster)
        when :mask_quiet_rend
            mask_quiet_rend(actor, enemies)
        when :mask_unmake_pulse
            mask_unmake_pulse(actor, enemies)
        when :mask_hunter_rush
            mask_hunter_rush(actor, enemies)
        when :mask_pack_instinct
            mask_pack_instinct(actor, roster)
        when :mask_fang_cleave
            mask_fang_cleave(actor, enemies)
        when :mask_seal_cut
            mask_seal_cut(actor, enemies)
        when :mask_index_gaze
            mask_index_gaze(enemies)
        when :mask_hidden_shelf
            mask_hidden_shelf
        else
            puts "The shelves ignore your attempt."
        end
    end

    def use_page(actor, enemies)
        puts "\nPages available:"
        @player.pages.each { |k,v| puts "#{k}: #{v}" }
        puts "Choose type:"
        print "> "
        type = gets&.strip&.to_sym

        unless @player.pages[type] && @player.pages[type] > 0
            puts "You don't have that page."
            return
        end

        @player.pages[type] -= 1

        case type
        when :ink
            page_ink(actor, enemies)
        when :memory
            page_memory(actor)
        when :null_page
            page_null(actor, enemies)
        when :binding
            page_binding(actor, enemies)
        when :index
            page_index(enemies)
        else
            puts "The page crumbles uselessly."
        end
    end

    def page_ink(actor, enemies)
        target = choose_enemy(enemies)
        dmg = (rand(14..22) * @damage_mult).round
        target.hp -= dmg
        puts "Ink burns across #{target.name}, dealing #{dmg} damage."
    end

    def page_memory(actor)
        heal = rand(15..25)
        actor.hp = [actor.hp + heal, actor.max_hp].min
        puts "Warm memories knit your wounds. You heal #{heal} HP."
    end

    def page_null(actor, enemies)
        target = choose_enemy(enemies)
        target.atk -= 3
        target.defense -= 3
        puts "#{target.name}'s form flickers — its stats drop sharply."
    end

    def page_binding(actor, enemies)
        target = choose_enemy(enemies)
        target.speed -= 5
        puts "#{target.name} is bound by invisible threads."
    end

    def page_index(enemies)
        puts "You glimpse the enemy's true form:"
        enemies.each do |e|
            puts "#{e.name} — HP #{e.hp}/#{e.max_hp}, ATK #{e.atk}, DEF #{e.defense}, SPD #{e.speed}"
        end
    end

    def use_item(actor)
        puts "\nItems:"
        puts "1. Medication (#{@player.inventory[:medication]})"
        print "> "
        choice = gets&.strip

        case choice
        when "1"
            if @player.inventory[:medication] > 0
                @player.inventory[:medication] -= 1
                heal = rand(10..15)
                actor.hp = [actor.hp + heal, actor.max_hp].min
                puts "#{actor.name} injects medication and heals #{heal} HP."
            else
                puts "You're out."
            end
        else
            puts "Nothing happens."
        end
    end

    def guard(actor)
        actor.defense += 2
        puts "#{actor.name} braces for impact."
    end

    def kennel_pack_howl(actor, roster)
        roster.each do |c|
            next unless c.is_a?(PartyMember) && c.faction == :kennel
            c.atk += 2
        end
        puts "A unified howl echoes — the pack grows stronger."
    end

    def kennel_scribe_mark(actor, enemies)
        target = choose_enemy(enemies)
        target.defense -= 2
        puts "Leto marks #{target.name} with ink sigils. Defense down!"
    end

    def kennel_fang_rush(actor, enemies)
        target = choose_enemy(enemies)
        hits = rand(2..3)
        hits.times do
            base = [actor.atk - target.defense, 1].max
            dmg = (base * @damage_mult).round
            target.hp -= dmg
        end
        puts "Mira darts forward in a blur, striking #{hits} times!"
    end

    def kennel_tail_feint(actor, enemies)
        target = choose_enemy(enemies)
        base = [actor.atk - target.defense, 1].max
        dmg = (base * @damage_mult).round
        target.hp -= dmg
        target.speed -= 2
        puts "A feinting tail-swipe slows #{target.name}."
    end

    def order_balance_ledger(actor, enemies)
        target = choose_enemy(enemies)
        dmg = ((@player.max_hp - @player.hp) / 2.0 * @damage_mult).round
        target.hp -= dmg
        puts "The Confessor tallies your pain — #{dmg} damage dealt."
    end

    def order_ink_seal(actor, enemies)
        target = choose_enemy(enemies)
        target.atk -= 3
        puts "Ink seals #{target.name}'s power."
    end

    def order_guard_entry(actor, roster)
        roster.each do |c|
            next unless c.is_a?(PartyMember) && c.faction == :order
            c.defense += 3
        end
        puts "The Ledger-Knight shields the party."
    end

    def order_reckoning_strike(actor, enemies)
        target = choose_enemy(enemies)
        dmg = (rand(12..20) * @damage_mult).round
        target.hp -= dmg
        puts "A heavy strike of reckoning hits for #{dmg}!"
    end

    def null_erase_emotion(actor, enemies)
        target = choose_enemy(enemies)
        target.atk -= 2
        target.defense -= 2
        puts "#{target.name}'s emotions fade — its form weakens."
    end

    def null_quiet_pulse(actor, roster)
        roster.each do |c|
            next unless c.is_a?(PartyMember) && c.faction == :null
            c.hp = [c.hp + 8, c.max_hp].min
        end
        puts "A pulse of quiet restores Null allies."
    end

    def null_unmake(actor, enemies)
        target = choose_enemy(enemies)
        dmg = (rand(15..25) * @damage_mult).round
        target.hp -= dmg
        actor.hp -= 5
        puts "Reality tears — #{target.name} takes #{dmg}, #{actor.name} takes 5 backlash."
    end

    def null_echo_burst(actor, enemies)
        enemies.each do |e|
            dmg = (rand(5..9) * @damage_mult).round
            e.hp -= dmg
        end
        puts "Echo-Pup releases a burst of unsteady sound."
    end

    # ===== MASK SKILLS =====

    def mask_ink_lash(actor, enemies)
        target = choose_enemy(enemies)
        dmg = (rand(10..16) * @damage_mult).round
        target.hp -= dmg
        target.defense -= 1
        puts "Ink lashes #{target.name}, dealing #{dmg} and lowering DEF."
    end

    def mask_scribe_guard(actor, roster)
        roster.each do |c|
            next unless c.is_a?(PartyMember)
            c.defense += 2
        end
        puts "A script of protection wraps around the party."
    end

    def mask_quiet_rend(actor, enemies)
        target = choose_enemy(enemies)
        dmg = (rand(9..14) * @damage_mult).round
        target.hp -= dmg
        dread_gain = 5
        @player.dread += (dread_gain * @dread_gain_mult).round
        puts "Quiet tears through #{target.name}, dealing #{dmg}. Your dread rises."
    end

    def mask_unmake_pulse(actor, enemies)
        enemies.each do |e|
            dmg = (rand(6..10) * @damage_mult).round
            e.hp -= dmg
        end
        puts "A pulse of unmaking ripples through the enemies."
    end

    def mask_hunter_rush(actor, enemies)
        target = choose_enemy(enemies)
        hits = rand(2..4)
        hits.times do
            base = [actor.atk - target.defense, 1].max
            dmg = (base * @damage_mult).round
            target.hp -= dmg
        end
        puts "The hunter-self rushes forward, striking #{hits} times!"
    end

    def mask_pack_instinct(actor, roster)
        roster.each do |c|
            next unless c.is_a?(PartyMember)
            c.speed += 2
        end
        puts "Pack instincts sharpen — everyone moves faster."
    end

    def mask_fang_cleave(actor, enemies)
        target = choose_enemy(enemies)
        dmg = (rand(18..26) * @damage_mult).round
        target.hp -= dmg
        puts "A Fang-shaped cleave tears into #{target.name} for #{dmg}!"
    end

    def mask_seal_cut(actor, enemies)
        target = choose_enemy(enemies)
        dmg = (rand(12..18) * @damage_mult).round
        target.hp -= dmg
        target.atk -= 2
        puts "A sealing cut weakens #{target.name}'s power."
    end

    def mask_index_gaze(enemies)
        puts "Your Mask reads the battlefield like a catalog."
        enemies.each do |e|
            puts "#{e.name} — HP #{e.hp}/#{e.max_hp}, ATK #{e.atk}, DEF #{e.defense}, SPD #{e.speed}"
        end
    end

    def mask_hidden_shelf
        room = @player.room
        if room.exits.size < 4
            dirs = ["north","south","east","west"] - room.exits.keys
            if dirs.any?
                new_dir = dirs.sample
                new_room = generate_stacks_room
                room.exits[new_dir] = new_room
                new_room.exits[opposite_dir(new_dir)] = room
                puts "You notice a hidden shelf that leads #{new_dir}."
            else
                puts "All directions are already open."
            end
        else
            puts "No hidden shelves reveal themselves here."
        end
    end

    def choose_enemy(enemies)
        alive = enemies.select(&:alive?)
        return nil if alive.empty?
        if alive.size == 1
            alive.first
        else
            puts "\nChoose target:"
            alive.each_with_index { |e,i| puts "#{i+1}. #{e.name} (#{e.hp} HP)" }
            print "> "
            idx = gets.to_i - 1
            alive[idx] || alive.first
        end
    end

    def player_turn(actor, enemies, roster)
        puts "\n#{actor.name}'s turn."
        puts "1. Attack"
        puts "2. Skill"
        puts "3. Page"
        puts "4. Item"
        puts "5. Guard"
        puts "6. Limit Break" if actor.limit_ready
        print "> "
        choice = gets&.strip

        case choice
        when "1"
            target = choose_enemy(enemies)
            basic_attack(actor, target)
        when "2"
            use_skill(actor, enemies, roster)
        when "3"
            use_page(actor, enemies)
        when "4"
            use_item(actor)
        when "5"
            guard(actor)
        when "6"
            if actor.limit_ready
                use_limit_break(actor, enemies, roster)
                actor.limit_ready = false
            else
                puts "Your limit is not ready."
            end
        else
            puts "You hesitate. The shelves creak impatiently."
        end
    end

    def conclude_battle(enemies, roster)
        puts "\nThe ink settles. The shelves fall quiet."
        gain = rand(10..20)
        @player.scraps += gain
        puts "You gather #{gain} scraps from the remains."

        player_actor = roster.find { |c| c.is_a?(PartyMember) && c.id == :player }
        if player_actor
            @player.hp = [player_actor.hp, @player.max_hp].min
        end

        # Mask XP gain
        if @player.equipped_mask
            xp_gain = rand(5..10)
            @player.equipped_mask.xp += xp_gain
            puts "Your Mask #{ @player.equipped_mask.name } gains #{xp_gain} XP."
            level_up_mask(@player.equipped_mask)
        end

        @player.dread = [@player.dread - (20 * @dread_gain_mult).round, 0].max
    end

    def start_test_battle
        puts "\nA misbound page tears itself free from a shelf."
        enemy = Enemy.new(
            name: "Misbound Page",
            hp: 20,
            atk: 6,
            defense: 2,
            speed: BASE_SPEED[:generic_enemy],
            desc: "Ink crawls across its surface like ants.",
            faction: nil,
            tags: [:library, :page]
        )
        battle([enemy])
    end

    # =========================
    # MASK LEVELING
    # =========================

    def level_up_mask(mask)
        needed = mask.level * 10
        while mask.xp >= needed
            mask.xp -= needed
            mask.level += 1
            puts "Mask #{mask.name} reaches level #{mask.level}!"

            # Simple stat growth
            mask.stats[:hp] += 2
            mask.stats[:atk] += 1
            mask.stats[:def] += 1
            mask.stats[:spd] += 1

            needed = mask.level * 10
        end
    end

    # =========================
    # PROPHET, FANG, COLLAPSE, ENDINGS
    # =========================

    def start_prophet_battle
        clear
        puts <<~TXT

        The shelves open into a vast circular chamber.
        Pages drift like snow.
        A tall figure stands at the center.

        "You were never written," it says.

        THE PROPHET — FOURTH-BIRTH — UNWRITTEN FUTURE
        TXT

        # Mask-aware Prophet reaction
        if @player.equipped_mask
            m = @player.equipped_mask
            if m.arcana == :null
                puts "\"You already practice erasure,\" the Prophet notes."
            elsif m.arcana == :kennel
                puts "\"Pack instincts in a place of solitude,\" it muses."
            elsif m.arcana == :order
                puts "\"You brought ledgers into a place of unwritten things.\""
            elsif m.arcana == :fang
                puts "\"You cling to the Fang's echo. It will not save you.\""
            elsif m.arcana == :unwritten
                puts "\"You wear the Library's own face,\" it whispers."
            end
        end

        prophet = Enemy.new(
            name: "The Prophet",
            hp: 500,
            atk: 14,
            defense: 8,
            speed: BASE_SPEED[:boss],
            desc: "A being made of drifting pages and catalog cards.",
            faction: :null,
            tags: [:boss, :prophet]
        )

        prophet_battle_loop([prophet])
    end

    def prophet_battle_loop(enemies)
        roster = build_combat_roster(enemies)
        apply_faction_synergy(roster)
        apply_mask_stats_to_player_actor(roster)
        atb = {}
        roster.each { |c| atb[c] = 0 }

        phase = 1

        until enemies.none?(&:alive?)
            check_limit_breaks(roster)
            show_combat_status(roster, enemies)

            roster.each do |c|
                next unless c.alive?
                atb[c] += c.speed
            end

            actor = roster.find { |c| atb[c] >= 100 }
            if actor
                atb[actor] = 0

                if actor.is_a?(Enemy)
                    prophet_turn(actor, roster, phase)
                else
                    prophet_player_turn(actor, enemies, roster, phase)
                end
            end

            if enemies.first.hp < 300 && phase == 1
                phase = 2
                puts "\nThe Prophet's form flickers — it becomes partially unwritten."
            end

            if enemies.first.hp < 120 && phase == 2
                phase = 3
                puts "\nThe Prophet raises a hand."
                puts "\"The Fang was a bookmark.\""
                shatter_fang
            end
        end

        conclude_prophet_battle
    end

    def prophet_turn(enemy, roster, phase)
        target = roster.select { |c| c.alive? && c.is_a?(PartyMember) }.sample
        return unless target

        case phase
        when 1
            dmg = (rand(10..16) * @damage_mult).round
            puts "The Prophet predicts your next move — #{target.name} takes #{dmg}."
            target.hp -= dmg
        when 2
            puts "The Prophet rewrites the turn order."
            roster.shuffle!
        when 3
            dmg = (rand(14..22) * @damage_mult).round
            puts "Ink floods the chamber — #{target.name} takes #{dmg}."
            target.hp -= dmg
        end

        if target.hp <= 0
            puts "#{target.name} collapses, their page torn."
        end
    end

    def prophet_player_turn(actor, enemies, roster, phase)
        puts "\n#{actor.name}'s turn."
        puts "1. Attack"
        puts "2. Skill"
        puts "3. Page"
        puts "4. Guard"
        puts "5. Limit Break" if actor.limit_ready
        print "> "
        choice = gets&.strip

        case choice
        when "1"
            if phase == 2
                puts "Your attack passes through its unwritten form."
            else
                target = enemies.first
                basic_attack(actor, target)
            end
        when "2"
            use_skill(actor, enemies, roster)
        when "3"
            if phase == 2
                puts "Only Pages and Masks can harm it now."
            end
            use_page(actor, enemies)
        when "4"
            guard(actor)
        when "5"
            if actor.limit_ready
                use_limit_break(actor, enemies, roster)
                actor.limit_ready = false
            else
                puts "Your limit is not ready."
            end
        else
            puts "You hesitate. The Prophet watches."
        end
    end


    def shatter_fang
        return if @player.fang_shattered

        puts "\nYou raise the Fang."
        puts "It vibrates violently."
        puts "The Prophet raises a hand."
        puts "The Fang screams — then shatters into dust."

        @player.has_fang = false
        @player.fang_shattered = true
    end

    def conclude_prophet_battle
        puts "\nThe Prophet falls silent."
        puts "Pages drift upward like ash."
        puts "\"The First-Birth… becomes the Seal.\""

        trigger_library_collapse
    end

    def trigger_library_collapse
        @library_collapse = true
        puts "\nThe Infinite Library begins to collapse."
        puts "Shelves twist. Pages scream."
        puts "Your party looks to you."
        puts "They know what must happen."

        start_final_seal_sequence
    end

    def start_final_seal_sequence
        puts <<~TXT

        You step forward.
        The Prophet's remnants swirl around you.
        Your name — #{@player.name} — echoes through the chamber.

        You feel the Fang's memory inside you.
        A final ability awakens:

        ERASE: SELF — ASCENSION FORM
        TXT

        # Mask-aware line
        if @player.equipped_mask
            puts "Your Mask #{ @player.equipped_mask.name } hums in resonance."
        end

        puts "\nUse it? (yes/no)"
        print "> "
        ans = gets&.strip&.downcase

        if ans == "yes"
            perform_final_seal
        else
            puts "The shelves collapse. Your party screams your name."
            @running = false
        end
    end

    def ending_kennel
        clear
        puts <<~TXT

        The Kennel gathers around the new Seal.

        They howl — not in grief, but in reverence.

        A shrine is built in the Stacks:
        THE DEN OF THE FIRST-BIRTH

        Your name is carved into the floor.
        #{@player.name} — Guardian of the Unwritten.

        TXT
        @running = false
    end

    def ending_order
        clear
        puts <<~TXT

        The Order records your sacrifice.

        A new ledger entry is created:
        "THE FIRST-BIRTH — BALANCED THROUGH SELF-ERASURE"

        Your name becomes a rule in the Library.

        #{@player.name}, the Final Equation.

        TXT
        @running = false
    end

    def ending_null
        clear
        puts <<~TXT

        The Null gather in silence.

        \"This was always your purpose,\" they whisper.

        The Seal hums softly.
        The world stops insisting on itself.

        #{@player.name} becomes the Quiet Between Pages.

        TXT
        @running = false
    end

    def ending_mask_variant(base_ending)
        # Mask-based flavor
        m = @player.equipped_mask
        return send(base_ending) unless m

        clear
        case base_ending
        when :ending_kennel
            puts <<~TXT

            The Kennel gathers around the new Seal.

            They howl — not in grief, but in reverence.

            A shrine is built in the Stacks:
            THE DEN OF THE FIRST-BIRTH

            Your Mask #{m.name} is carved beside your name.

            #{@player.name} — #{m.arcana.to_s.capitalize} Aspect of the Unwritten.

            TXT
        when :ending_order
            puts <<~TXT

            The Order records your sacrifice.

            A new ledger entry is created:
            "THE FIRST-BIRTH — BALANCED THROUGH SELF-ERASURE"

            Your Mask #{m.name} becomes a sub-ledger of your existence.

            #{@player.name}, the Final Equation, wearing #{m.arcana.to_s.capitalize} ink.

            TXT
        when :ending_null
            puts <<~TXT

            The Null gather in silence.

            \"This was always your purpose,\" they whisper.

            Your Mask #{m.name} dissolves into the Seal.

            #{@player.name} becomes the Quiet Between Pages,
            and #{m.arcana.to_s.capitalize} is the last color the world remembers.

            TXT
        when :ending_generic
            puts <<~TXT

            The Library stabilizes.

            Your companions leave offerings at the Seal.

            No faction claims you.
            No ledger records you.
            No shrine bears your name.

            But the Stacks remember.

            Your Mask #{m.name} lingers as a rumor between shelves.

            #{@player.name}, the Unwritten Guardian of #{m.arcana.to_s.capitalize}.

            TXT
        end
        @running = false
    end

    def ending_generic
        clear
        puts <<~TXT

        The Library stabilizes.

        Your companions leave offerings at the Seal.

        No faction claims you.
        No ledger records you.
        No shrine bears your name.

        But the Stacks remember.

        #{@player.name}, the Unwritten Guardian.

        TXT
        @running = false
    end

    def perform_final_seal
        clear
        puts <<~TXT

        You raise your paw.

        Light — ink — memory — all swirl together.

        Your body dissolves into drifting pages.
        Your name becomes a title:

        THE INDEX OF #{@player.name.upcase}

        The Prophet is sealed.
        The Library stabilizes.

        TXT

        sleep 1

        case @player.faction
        when :kennel
            ending_mask_variant(:ending_kennel)
        when :order
            ending_mask_variant(:ending_order)
        when :null
            ending_mask_variant(:ending_null)
        else
            ending_mask_variant(:ending_generic)
        end

        puts "\n\n=== THANK YOU FOR PLAYING DARK FLOOF II ==="
        puts "Your page closes here."

        puts "\n…for now."

        puts <<~TEASE

        Somewhere beyond the sealed Library,
        a different structure exhales:

        NOT A HOSPITAL.
        NOT A LIBRARY.

        A PLACE THAT NEVER EXISTED LONG ENOUGH TO BE NAMED.

        DARK FLOOF III:
        WORKING TITLE — "THE PLACE THAT DIDN'T TAKE"

        TEASE

        @running = false
    end

    # =========================
    # SAVE / LOAD
    # =========================

    def save_game
        data = {
            player: {
                     name: @player.name,
                     faction: @player.faction,
                     hp: @player.hp,
                     max_hp: @player.max_hp,
                     atk: @player.atk,
                     defense: @player.defense,
                     speed: @player.speed,
                     pages: @player.pages,
                     scraps: @player.scraps,
                     inventory: @player.inventory,
                     status_effects: @player.status_effects,
                     reputation: @player.reputation,
                     fang_shattered: @player.fang_shattered,
                     has_fang: @player.has_fang,
                     dread: @player.dread,
                     linger_counter: @player.linger_counter,
                     masks: serialize_masks,
                     equipped_mask: @player.equipped_mask&.name
                    },
            rooms: serialize_rooms,
            player_room: @player.room.id,
            difficulty: @difficulty,
            encounter_rate: @encounter_rate,
            dread_gain_mult: @dread_gain_mult,
            damage_mult: @damage_mult,
            linger_only_mode: @linger_only_mode
        }

        File.write("dark_floof_2_save.json", JSON.pretty_generate(data))
        puts "Game saved."
    end

    def load_game
        unless File.exist?("dark_floof_2_save.json")
            puts "No save file found."
            return
        end

        data = JSON.parse(File.read("dark_floof_2_save.json"))

        p = data["player"]
        @player = Player.new(p["name"])
        @player.faction = p["faction"]&.to_sym
        @player.hp = p["hp"]
        @player.max_hp = p["max_hp"]
        @player.atk = p["atk"]
        @player.defense = p["defense"]
        @player.speed = p["speed"]
        @player.pages = p["pages"].transform_keys(&:to_sym)
        @player.scraps = p["scraps"]
        @player.inventory = p["inventory"]
        @player.status_effects = p["status_effects"]
        @player.reputation = p["reputation"].transform_keys(&:to_sym)
        @player.fang_shattered = p["fang_shattered"]
        @player.has_fang = p["has_fang"]
        @player.dread = p["dread"]
        @player.linger_counter = p["linger_counter"]

        @difficulty = (data["difficulty"] || "normal").to_sym
        @encounter_rate = data["encounter_rate"] || 0.70
        @dread_gain_mult = data["dread_gain_mult"] || 1.0
        @damage_mult = data["damage_mult"] || 1.0
        @linger_only_mode = data["linger_only_mode"] || false

        load_rooms(data["rooms"])

        room_id = data["player_room"]
        @player.room = @rooms.values.find { |r| r.id == room_id }

        case @player.faction
        when :kennel
            setup_kennel_party
        when :order
            setup_order_party
        when :null
            setup_null_party
        end

        load_masks(p["masks"] || {})
        if p["equipped_mask"]
            @player.equipped_mask = @player.masks[p["equipped_mask"]]
        end

        puts "Game loaded."
        main_loop
    end

    def serialize_rooms
        out = {}
        @rooms.each do |key, room|
            out[key] = {
                id: room.id,
                name: room.name,
                desc: room.desc,
                lore: room.lore,
                visited: room.visited,
                biome: room.biome,
                exits: room.exits.transform_values { |r| r&.id },
                shelves: room.shelves,
                flags: room.flags,
                npc: room.npc ? {
                                 name: room.npc.name,
                                 faction: room.npc.faction,
                                 lines: room.npc.lines
                                } : nil,
                enemies: room.enemy_group.map do |e|
            {
             name: e.name,
             hp: e.hp,
             max_hp: e.max_hp,
             atk: e.atk,
             defense: e.defense,
             speed: e.speed,
             desc: e.desc,
             faction: e.faction,
             tags: e.tags
            }
            end
            }
        end
        out
    end

    def load_rooms(data)
        @rooms = {}

        data.each do |key, r|
            room = Room.new(r["name"], r["desc"], lore: r["lore"], id: r["id"], biome: r["biome"]&.to_sym)
            room.visited = r["visited"]
            room.shelves = r["shelves"]
            room.flags = r["flags"]
            @rooms[key.to_sym] = room
        end

        data.each do |key, r|
            room = @rooms[key.to_sym]
            r["exits"].each do |dir, id|
                next unless id
                target = @rooms.values.find { |rm| rm.id == id }
                room.exits[dir] = target
            end
        end

        data.each do |key, r|
            room = @rooms[key.to_sym]

            if r["npc"]
                n = r["npc"]
                room.npc = NPC.new(n["name"], n["faction"]&.to_sym, n["lines"])
            end

            room.enemy_group = r["enemies"].map do |e|
                Enemy.new(
                    name: e["name"],
                    hp: e["hp"],
                    atk: e["atk"],
                    defense: e["defense"],
                    speed: e["speed"],
                    desc: e["desc"],
                    faction: e["faction"]&.to_sym,
                    tags: e["tags"]
                )
            end
        end
    end

    def serialize_masks
        out = {}
        @player.masks.each do |name, m|
            out[name] = {
                arcana: m.arcana,
                level: m.level,
                xp: m.xp,
                stats: m.stats,
                affinities: m.affinities,
                skills: m.skills,
                passives: m.passives,
                story_tags: m.story_tags
            }
        end
        out
    end

    def load_masks(data)
        @player.masks = {}
        data.each do |name, m|
            mask = SoulMask.new(
                name: name,
                arcana: m["arcana"].to_sym,
                stats: m["stats"].transform_keys(&:to_sym),
                affinities: m["affinities"].transform_keys(&:to_sym),
                skills: m["skills"].map(&:to_sym),
                passives: m["passives"].map(&:to_sym),
                story_tags: (m["story_tags"] || []).map(&:to_sym)
            )
            mask.level = m["level"]
            mask.xp = m["xp"]
            @player.masks[name] = mask
        end
    end

    # =========================
    # MASK MENU & FUSION
    # =========================

    def mask_menu
        if @player.masks.empty?
            puts "You have no Soul-Masks."
            return
        end

        puts "\n=== SOUL-MASKS ==="
        @player.masks.values.each_with_index do |m, i|
            eq = (m == @player.equipped_mask) ? "*" : " "
            puts "#{i+1}.#{eq} #{m.name} (Arcana: #{m.arcana.to_s.capitalize}, Lv #{m.level})"
        end
        puts "Choose a Mask to equip (or press Enter to cancel):"
        print "> "
        line = gets&.strip
        return if line.nil? || line.empty?
        idx = line.to_i - 1
        mask = @player.masks.values[idx]
        unless mask
            puts "No such Mask."
            return
        end
        @player.equipped_mask = mask
        puts "You let #{mask.name} settle over your fur."
    end

    def fusion_menu
        if @player.masks.size < 2
            puts "You need at least two Masks to fuse."
            return
        end

        puts "\n=== FUSION CHAMBER ==="
        puts "The shelves rearrange into a circle."
        puts "Choose two Masks to fuse."

        masks = @player.masks.values
        masks.each_with_index do |m, i|
            puts "#{i+1}. #{m.name} (Arcana: #{m.arcana.to_s.capitalize}, Lv #{m.level})"
        end

        print "First Mask number: "
        a_idx = gets.to_i - 1
        print "Second Mask number: "
        b_idx = gets.to_i - 1

        return if a_idx == b_idx
        mask_a = masks[a_idx]
        mask_b = masks[b_idx]
        unless mask_a && mask_b
            puts "Invalid selection."
            return
        end

        result = fuse_masks(mask_a, mask_b)
        if result
            puts "\nFusion result: #{result.name} (Arcana: #{result.arcana.to_s.capitalize})"
            puts "Accept fusion? (y/n)"
            print "> "
            ans = gets&.strip&.downcase
            if ans == "y"
                @player.masks.delete(mask_a.name)
                @player.masks.delete(mask_b.name)
                @player.masks[result.name] = result
                @player.equipped_mask = result
                puts "The shelves bind your selves together. #{result.name} is born."
            else
                puts "The shelves unbind. Fusion canceled."
            end
        else
            puts "The shelves refuse this combination."
        end
    end

    def fusion_arcana(a, b)
        # Simple combination rules
        pair = [a, b].sort
        case pair
        when [:kennel, :order] then :fang
        when [:kennel, :null] then :unwritten
        when [:order, :null] then :unwritten
        when [:fang, :null] then :unwritten
        when [:fang, :kennel] then :kennel
        when [:fang, :order] then :order
        else
            pair.sample
        end
    end

    def blend_stats(sa, sb)
        {
            hp: ((sa[:hp] + sb[:hp]) / 2.0).round,
            atk: ((sa[:atk] + sb[:atk]) / 2.0).round,
            def: ((sa[:def] + sb[:def]) / 2.0).round,
            spd: ((sa[:spd] + sb[:spd]) / 2.0).round
        }
        enddef prophet_player_turn(actor, enemies, roster, phase)
        puts "\n#{actor.name}'s turn."
        puts "1. Attack"
        puts "2. Skill"
        puts "3. Page"
        puts "4. Guard"
        puts "5. Limit Break" if actor.limit_ready
        print "> "
        choice = gets&.strip
        
        case choice
        when "1"
            if phase == 2
                puts "Your attack passes through its unwritten form."
            else
                target = enemies.first
                basic_attack(actor, target)
            end
        when "2"
            use_skill(actor, enemies, roster)
        when "3"
            if phase == 2
                puts "Only Pages and Masks can harm it now."
            end
            use_page(actor, enemies)
        when "4"
            guard(actor)
        when "5"
            if actor.limit_ready
                use_limit_break(actor, enemies, roster)
                actor.limit_ready = false
            else
                puts "Your limit is not ready."
            end
        else
            puts "You hesitate. The Prophet watches."
        end
    end
    

    def blend_affinities(aa, ab)
        out = {}
        [:ink, :null, :binding, :physical].each do |k|
            a = aa[k] || :normal
            b = ab[k] || :normal
            out[k] = if a == b
            a
        else
            # simple rule: normal if conflict
            :normal
        end
    end
    out
end

def fuse_masks(mask_a, mask_b)
    arcana = fusion_arcana(mask_a.arcana, mask_b.arcana)
    stats = blend_stats(mask_a.stats, mask_b.stats)
    affinities = blend_affinities(mask_a.affinities, mask_b.affinities)
    skills = (mask_a.skills + mask_b.skills).uniq.sample(3)
    passives = (mask_a.passives + mask_b.passives).uniq.sample(2)
    story_tags = (mask_a.story_tags + mask_b.story_tags).uniq

    SoulMask.new(
        name: "#{mask_a.name.split.first}-#{mask_b.name.split.first} Echo",
        arcana: arcana,
        stats: stats,
        affinities: affinities,
        skills: skills,
        passives: passives,
        story_tags: story_tags
    )
end

# =========================
# DEBUG CONSOLE
# =========================

def debug_console
    puts "\n=== DEBUG CONSOLE ==="
    puts "1. Spawn enemy battle"
    puts "2. Teleport Prophet battle"
    puts "3. Add Pages"
    puts "4. Set Dread"
    puts "5. Toggle Lingerer"
    puts "6. Toggle Lingerer Mode"
    puts "7. Grant random Mask"
    puts "8. Cancel"
    print "> "
    choice = gets&.strip

    case choice
    when "1"
        enemy = generate_enemy
        battle([enemy])
    when "2"
        start_prophet_battle
    when "3"
        PAGE_TYPES.each { |t| @player.pages[t] += 3 }
        puts "You feel heavier with potential."
    when "4"
        print "Dread value: "
        v = gets.to_i
        @player.dread = v
        puts "Dread set to #{v}."
    when "5"
        @linger_active = !@linger_active
        puts "Lingerer active: #{@linger_active}"
    when "6"
        @linger_only_mode = !@linger_only_mode
        puts "Lingerer Mode: #{@linger_only_mode ? 'ON' : 'OFF'}"
    when "7"
        grant_random_mask(source: "debug console")
    else
        puts "Console closed."
    end
end
end

if __FILE__ == $0
    Game.new.run
end

