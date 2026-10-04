extends Node2D

const COLORS = ["أحمر", "أخضر", "أزرق", "أصفر"]
const COLOR_HEX = {"أحمر": Color("#e74c3c"), "أخضر": Color("#2ecc71"), "أزرق": Color("#3498db"), "أصفر": Color("#f1c40f")}
const NAMES = ["أنت", "صقر", "إياد", "الجزار"]

var players: Array = []
var deck: Array = []
var discard: Array = []
var current_player := 0
var direction := 1
var selected_card := -1
var message := "دورك! العب كرتًا مناسبًا"
var info_label: Label
var center_card: Button
var hand_box: HBoxContainer
var opponent_box: VBoxContainer
var restart_button: Button

func _ready():
    randomize()
    build_ui()
    new_game()

func build_ui():
    var bg = ColorRect.new()
    bg.color = Color("#17202a")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var title = Label.new()
    title.text = "UNO AI"
    title.position = Vector2(0, 25)
    title.size = Vector2(720, 70)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 44)
    add_child(title)

    opponent_box = VBoxContainer.new()
    opponent_box.position = Vector2(30, 105)
    opponent_box.size = Vector2(660, 150)
    opponent_box.add_theme_constant_override("separation", 10)
    add_child(opponent_box)

    center_card = Button.new()
    center_card.position = Vector2(260, 360)
    center_card.size = Vector2(200, 280)
    center_card.add_theme_font_size_override("font_size", 42)
    center_card.disabled = true
    add_child(center_card)

    info_label = Label.new()
    info_label.position = Vector2(30, 660)
    info_label.size = Vector2(660, 100)
    info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info_label.add_theme_font_size_override("font_size", 24)
    add_child(info_label)

    hand_box = HBoxContainer.new()
    hand_box.position = Vector2(15, 800)
    hand_box.size = Vector2(690, 250)
    hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
    hand_box.add_theme_constant_override("separation", 8)
    add_child(hand_box)

    restart_button = Button.new()
    restart_button.text = "لعبة جديدة"
    restart_button.position = Vector2(250, 1110)
    restart_button.size = Vector2(220, 80)
    restart_button.add_theme_font_size_override("font_size", 26)
    restart_button.pressed.connect(new_game)
    add_child(restart_button)

func make_deck():
    deck.clear()
    for c in COLORS:
        for n in range(0, 10):
            deck.append({"color": c, "value": str(n), "type": "number"})
        for n in range(2):
            for t in ["+2", "تخطي", "عكس"]:
                deck.append({"color": c, "value": t, "type": "action"})
    for n in range(4):
        deck.append({"color": "جوكر", "value": "تغيير لون", "type": "wild"})
        deck.append({"color": "جوكر", "value": "+4", "type": "wild4"})
    deck.shuffle()

func new_game():
    make_deck()
    discard.clear()
    players = [[], [], [], []]
    current_player = 0
    direction = 1
    selected_card = -1
    for i in range(4):
        for j in range(7):
            players[i].append(deck.pop_back())
    var first = deck.pop_back()
    while first.type == "wild4":
        deck.push_front(first)
        deck.shuffle()
        first = deck.pop_back()
    discard.append(first)
    message = "دورك! العب كرتًا مناسبًا"
    refresh()

func card_text(card):
    return card.color + "\n" + card.value

func can_play(card):
    var top = discard[-1]
    return card.type in ["wild", "wild4"] or card.color == top.color or card.value == top.value

func draw_card(p := 0):
    if deck.is_empty():
        if discard.size() > 1:
            var top = discard.pop_back()
            deck = discard.duplicate()
            discard.clear()
            discard.append(top)
            deck.shuffle()
    if not deck.is_empty():
        players[p].append(deck.pop_back())

func play_card(p, idx):
    var card = players[p][idx]
    if p == 0 and not can_play(card):
        message = "هذا الكرت غير مناسب للكرت الموجود بالنص"
        refresh()
        return
    players[p].remove_at(idx)
    discard.append(card)
    if players[p].is_empty():
        message = NAMES[p] + " فاز بالجولة! 🎉"
        refresh()
        return
    if card.type == "action":
        if card.value == "تخطي": current_player = next_player()
        elif card.value == "عكس": direction *= -1
        elif card.value == "+2":
            var target = next_player()
            draw_card(target); draw_card(target)
    elif card.type == "wild4":
        var target = next_player()
        for k in range(4): draw_card(target)
    current_player = next_player()
    message = "دور " + NAMES[current_player]
    refresh()
    if current_player != 0 and not players[0].is_empty():
        await get_tree().create_timer(0.65).timeout
        ai_turn()

func next_player():
    return (current_player + direction + 4) % 4

func ai_turn():
    if current_player == 0: return
    var p = current_player
    var playable: Array = []
    for i in range(players[p].size()):
        if can_play(players[p][i]): playable.append(i)
    var idx = -1
    if playable.size() > 0:
        if p == 1:
            for x in playable:
                if players[p][x].type in ["wild4", "action"]: idx = x; break
        elif p == 3:
            idx = playable[randi() % playable.size()]
        if idx == -1: idx = playable[0]
    else:
        draw_card(p)
        message = NAMES[p] + " سحب كرتًا 😄"
        refresh()
        await get_tree().create_timer(0.55).timeout
        playable.clear()
        for i in range(players[p].size()):
            if can_play(players[p][i]): playable.append(i)
        if playable.size() > 0: idx = playable[0]
    if idx >= 0:
        play_card(p, idx)

func refresh():
    info_label.text = message + "\nالكرت الأوسط: " + card_text(discard[-1]) + "   |   الكروت المتبقية: " + str(deck.size())
    center_card.text = card_text(discard[-1])
    center_card.modulate = COLOR_HEX.get(discard[-1].color, Color("#9b59b6"))

    for child in opponent_box.get_children(): child.queue_free()
    for i in range(1,4):
        var l = Label.new()
        l.text = "👤 " + NAMES[i] + "    🃏 " + str(players[i].size()) + " كروت"
        l.add_theme_font_size_override("font_size", 24)
        opponent_box.add_child(l)

    for child in hand_box.get_children(): child.queue_free()
    for i in range(players[0].size()):
        var b = Button.new()
        b.text = card_text(players[0][i])
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.custom_minimum_size = Vector2(70, 210)
        b.add_theme_font_size_override("font_size", 18)
        b.modulate = COLOR_HEX.get(players[0][i].color, Color("#9b59b6"))
        b.pressed.connect(func(): play_card(0, i))
        hand_box.add_child(b)
