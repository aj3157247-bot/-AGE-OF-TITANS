extends Node2D

# AGE OF TITANS - self-contained playable strategy game prototype.
# No external assets required: all visuals are drawn procedurally.

const W := 1280.0
const H := 720.0
const BASE_CAPACITY := 60

var gold := 12500
var food := 9200
var crystals := 240
var trophies := 1200
var town_level := 1
var wall_level := 1
var barracks_level := 1
var training := false
var training_time := 0.0
var message := "Welcome, Commander. Build your empire."
var message_time := 5.0
var selected_tab := "CITY"
var battle_mode := false
var battle_time := 0.0
var battle_score := 0
var battle_gold := 0
var battle_food := 0
var battle_enemy := ""
var search_busy := false
var search_time := 0.0
var enemy_power := 0
var army := {
    "Warrior": 0,
    "Archer": 0,
    "Guardian": 0,
    "Dire Wolf": 0,
    "War Troll": 0,
    "Stone Giant": 0,
    "Dragon": 0,
    "Titan": 0
}

var units := {
    "Warrior": {"cap":2, "cost":80, "food":30, "hp":80, "dmg":18, "role":"Fast melee"},
    "Archer": {"cap":3, "cost":110, "food":20, "hp":55, "dmg":28, "role":"Ranged"},
    "Guardian": {"cap":5, "cost":180, "food":55, "hp":190, "dmg":25, "role":"Tank"},
    "Dire Wolf": {"cap":6, "cost":260, "food":70, "hp":150, "dmg":42, "role":"Hunter"},
    "War Troll": {"cap":10, "cost":430, "food":120, "hp":390, "dmg":68, "role":"Siege"},
    "Stone Giant": {"cap":18, "cost":720, "food":190, "hp":950, "dmg":120, "role":"Building breaker"},
    "Dragon": {"cap":24, "cost":1200, "food":320, "hp":780, "dmg":190, "role":"Air monster"},
    "Titan": {"cap":30, "cost":1800, "food":500, "hp":1800, "dmg":260, "role":"Boss unit"}
}

var buildings := [
    {"name":"Command Center","level":1,"x":620,"y":360,"w":190,"h":130,"icon":"👑"},
    {"name":"Barracks","level":1,"x":350,"y":470,"w":150,"h":100,"icon":"⚔"},
    {"name":"Gold Vault","level":1,"x":850,"y":455,"w":150,"h":100,"icon":"G"},
    {"name":"Food Store","level":1,"x":850,"y":305,"w":150,"h":90,"icon":"F"},
    {"name":"Titan Forge","level":1,"x":360,"y":300,"w":160,"h":100,"icon":"T"}
]

func _ready():
    get_viewport().set_embedding_subwindows(false)
    queue_redraw()

func _process(delta):
    if message_time > 0: message_time -= delta
    if training:
        training_time -= delta
        if training_time <= 0:
            training = false
            message = "Training complete! Your army is ready."
            message_time = 4
    if search_busy:
        search_time -= delta
        if search_time <= 0:
            search_busy = false
            enemy_power = randi_range(8500, 42000)
            battle_enemy = ["Iron Dominion", "Crimson Horde", "Wolf Kingdom", "Dragon Pact", "Storm Empire"][randi_range(0,4)]
            message = "Target found: %s" % battle_enemy
            message_time = 4
    if battle_mode:
        battle_time -= delta
        if battle_time <= 0:
            finish_battle()
    queue_redraw()

func _input(event):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        handle_click(event.position)
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        selected_tab = "CITY"
        battle_mode = false

func handle_click(p: Vector2):
    # Top tabs
    if Rect2(20,80,130,46).has_point(p): selected_tab="CITY"
    elif Rect2(160,80,160,46).has_point(p): selected_tab="ARMY"
    elif Rect2(330,80,150,46).has_point(p): selected_tab="SEARCH"
    elif Rect2(490,80,140,46).has_point(p): selected_tab="UPGRADE"
    elif battle_mode:
        if Rect2(1040,635,200,55).has_point(p): finish_battle()
    elif selected_tab == "CITY":
        if Rect2(1030,635,210,55).has_point(p): collect_resources()
        elif Rect2(500,635,210,55).has_point(p): start_training()
    elif selected_tab == "ARMY":
        army_click(p)
    elif selected_tab == "SEARCH":
        if Rect2(500,575,280,65).has_point(p): search_target()
        elif Rect2(500,500,280,55).has_point(p) and battle_enemy != "": start_battle()
    elif selected_tab == "UPGRADE":
        upgrade_click(p)

func collect_resources():
    var amount = 350 + town_level * 100
    gold += amount
    food += amount
    message = "+%d Gold  +%d Food collected" % [amount, amount]
    message_time=3

func start_training():
    if training:
        message="Training is already running."
        message_time=3
        return
    if gold < 500 or food < 300:
        message="Not enough resources."
        message_time=3
        return
    gold -= 500
    food -= 300
    training=true
    training_time=5
    message="Training army... 5 seconds"
    message_time=3

func max_capacity():
    return BASE_CAPACITY + (town_level - 1) * 15

func army_capacity():
    var total=0
    for name in army:
        total += army[name] * units[name].cap
    return total

func army_click(p:Vector2):
    var names=units.keys()
    for i in range(names.size()):
        var y=160+i*58
        if Rect2(920,y,55,42).has_point(p): add_unit(names[i])
        if Rect2(1130,y,55,42).has_point(p): remove_unit(names[i])

func add_unit(name:String):
    var u=units[name]
    if army_capacity()+u.cap > max_capacity():
        message="Army capacity is full (%d)." % max_capacity()
    elif gold < u.cost or food < u.food:
        message="Not enough resources."
    else:
        gold-=u.cost; food-=u.food; army[name]+=1
        message="Recruited %s" % name
    message_time=2.5

func remove_unit(name:String):
    if army[name] > 0:
        army[name]-=1
        gold += int(units[name].cost*0.5)
        food += int(units[name].food*0.5)
        message="Removed %s" % name
        message_time=2

func search_target():
    if army_capacity() < 10:
        message="Train at least 10 capacity of troops first."
        message_time=3
        return
    search_busy=true
    search_time=1.2
    battle_enemy=""
    message="Searching for a worthy opponent..."
    message_time=2

func start_battle():
    if army_capacity() <= 0:
        message="Your army is empty."
        message_time=3
        return
    battle_mode=true
    battle_time=12
    battle_score=0
    battle_gold=0
    battle_food=0
    message="ATTACK! Tap FINISH BATTLE when you are satisfied with the result."
    message_time=5

func finish_battle():
    if not battle_mode: return
    battle_mode=false
    var power=army_power()
    var ratio=clamp(float(power)/max(1.0,float(enemy_power)),0.35,1.45)
    var stars=clamp(int(round(ratio*3.0)),0,3)
    battle_score=stars
    battle_gold=int((700+enemy_power*0.055)*ratio)
    battle_food=int((500+enemy_power*0.035)*ratio)
    var losses=float(army_capacity())*randf_range(0.08,0.28)
    consume_losses(int(losses))
    gold+=battle_gold
    food+=battle_food
    trophies+=stars*28-20
    trophies=max(trophies,0)
    message="Battle won! %d★  +%d Gold  +%d Food" % [stars,battle_gold,battle_food]
    message_time=6

func army_power():
    var p=0
    for name in army:
        p += army[name] * (units[name].hp + units[name].dmg*4)
    return p

func consume_losses(amount:int):
    var remaining=amount
    var names=units.keys()
    names.shuffle()
    for name in names:
        while army[name]>0 and remaining>=units[name].cap:
            army[name]-=1
            remaining-=units[name].cap
        if remaining<=0: break

func upgrade_click(p:Vector2):
    if Rect2(470,180,340,85).has_point(p):
        var cost=1800*town_level
        if gold>=cost:
            gold-=cost; town_level+=1; message="Command Center upgraded to Lv.%d" % town_level
        else: message="Need %d Gold" % cost
    elif Rect2(470,285,340,85).has_point(p):
        var cost=1200*barracks_level
        if gold>=cost:
            gold-=cost; barracks_level+=1; message="Barracks upgraded to Lv.%d" % barracks_level
        else: message="Need %d Gold" % cost
    elif Rect2(470,390,340,85).has_point(p):
        var cost=1400*wall_level
        if gold>=cost:
            gold-=cost; wall_level+=1; message="Walls upgraded to Lv.%d" % wall_level
        else: message="Need %d Gold" % cost
    message_time=3

func _draw():
    draw_rect(Rect2(0,0,W,H),Color("0e1420"))
    draw_rect(Rect2(0,0,W,65),Color("172234"))
    draw_string(ThemeDB.fallback_font,Vector2(25,43),"AGE OF TITANS",HORIZONTAL_ALIGNMENT_LEFT,300,30,Color("f7c95c"))
    draw_string(ThemeDB.fallback_font,Vector2(330,38),"ONLINE STRATEGY • BUILD • RAID • CONQUER",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("9fb2cc"))
    draw_resource(620,"G",gold,Color("f1c34e"))
    draw_resource(790,"F",food,Color("8bd36e"))
    draw_resource(960,"◆",crystals,Color("65c8ff"))
    draw_resource(1110,"🏆",trophies,Color("ff9f5b"))
    draw_tabs()
    if battle_mode: draw_battle()
    elif selected_tab=="CITY": draw_city()
    elif selected_tab=="ARMY": draw_army()
    elif selected_tab=="SEARCH": draw_search()
    elif selected_tab=="UPGRADE": draw_upgrade()
    if message_time>0:
        draw_rect(Rect2(300,675,680,32),Color(0.03,0.04,0.06,0.92))
        draw_string(ThemeDB.fallback_font,Vector2(320,697),message,HORIZONTAL_ALIGNMENT_LEFT,640,16,Color("e7edf7"))

func draw_resource(x:float,icon:String,value:int,c:Color):
    draw_string(ThemeDB.fallback_font,Vector2(x,28),icon,HORIZONTAL_ALIGNMENT_LEFT,40,22,c)
    draw_string(ThemeDB.fallback_font,Vector2(x+30,29),str(value),HORIZONTAL_ALIGNMENT_LEFT,120,18,Color("e8eef8"))

func draw_tabs():
    var tabs=[ ["CITY",20,130],["ARMY",160,160],["SEARCH",330,150],["UPGRADE",490,140] ]
    for t in tabs:
        var r=Rect2(t[1],80,t[2],46)
        draw_rect(r,Color("293850") if selected_tab!=t[0] else Color("a87b28"))
        draw_string(ThemeDB.fallback_font,Vector2(t[1]+18,110),t[0],HORIZONTAL_ALIGNMENT_LEFT,t[2]-30,17,Color("ffffff"))

func draw_city():
    draw_rect(Rect2(20,140,1240,510),Color("a7c77b"))
    # water and roads
    draw_rect(Rect2(20,140,1240,70),Color("75b8d3"))
    draw_rect(Rect2(20,550,1240,100),Color("88ad68"))
    for i in range(7):
        draw_line(Vector2(20+i*190,390),Vector2(210+i*190,390),Color("c9a66b"),18)
    # walls
    draw_rect(Rect2(170,225,940,300),Color("765d45"),false,12)
    draw_rect(Rect2(190,245,900,260),Color("d6b07b"),false,6)
    for b in buildings:
        var r=Rect2(b.x-b.w/2,b.y-b.h/2,b.w,b.h)
        draw_rect(r,Color("e9e0ce"))
        draw_rect(r,Color("3d4d61"),false,3)
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+10,r.position.y+30),b.icon,HORIZONTAL_ALIGNMENT_LEFT,40,28,Color("b07a2c"))
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+48,r.position.y+25),b.name,HORIZONTAL_ALIGNMENT_LEFT,r.size.x-55,14,Color("172234"))
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+48,r.position.y+48),"Lv.%d" % (town_level if b.name=="Command Center" else 1),HORIZONTAL_ALIGNMENT_LEFT,80,14,Color("6d7890"))
    # units around town
    for i in range(12):
        var px=250+(i%6)*145
        var py=590+(i/6)*35
        draw_circle(Vector2(px,py),10,Color("eef3f8"))
        draw_circle(Vector2(px,py),6,Color("41536c"))
    draw_string(ThemeDB.fallback_font,Vector2(35,175),"YOUR CAPITAL",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("17344b"))
    draw_rect(Rect2(500,635,210,55),Color("7b9f42"))
    draw_string(ThemeDB.fallback_font,Vector2(525,670),"TRAIN ARMY",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ffffff"))
    draw_rect(Rect2(1030,635,210,55),Color("b07d2e"))
    draw_string(ThemeDB.fallback_font,Vector2(1050,670),"COLLECT RESOURCES",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ffffff"))

func draw_army():
    draw_panel_title("ARMY FORGE", "Build your attack force. Stronger units consume more command capacity.")
    draw_string(ThemeDB.fallback_font,Vector2(55,155),"Capacity: %d / %d" % [army_capacity(),max_capacity()],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("f7c95c"))
    var names=units.keys()
    for i in range(names.size()):
        var name=names[i]; var u=units[name]; var y=180+i*58
        draw_rect(Rect2(45,y,1180,48),Color("182537"))
        draw_string(ThemeDB.fallback_font,Vector2(65,y+31),name,HORIZONTAL_ALIGNMENT_LEFT,170,17,Color("ffffff"))
        draw_string(ThemeDB.fallback_font,Vector2(235,y+30),"CAP %d"%u.cap,HORIZONTAL_ALIGNMENT_LEFT,80,14,Color("f7c95c"))
        draw_string(ThemeDB.fallback_font,Vector2(330,y+30),u.role,HORIZONTAL_ALIGNMENT_LEFT,190,14,Color("9fb2cc"))
        draw_string(ThemeDB.fallback_font,Vector2(545,y+30),"Owned: %d"%army[name],HORIZONTAL_ALIGNMENT_LEFT,120,14,Color("bcd0e6"))
        draw_string(ThemeDB.fallback_font,Vector2(680,y+30),"Gold %d / Food %d"%[u.cost,u.food],HORIZONTAL_ALIGNMENT_LEFT,190,13,Color("889bb2"))
        draw_rect(Rect2(920,y+5,55,38),Color("3c8b67")); draw_string(ThemeDB.fallback_font,Vector2(941,y+31),"+",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
        draw_rect(Rect2(1130,y+5,55,38),Color("8d4b4b")); draw_string(ThemeDB.fallback_font,Vector2(1150,y+31),"−",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(55,655),"Tip: mix tanks, ranged units and monsters instead of spending everything on Titans.",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("9fb2cc"))

func draw_search():
    draw_panel_title("BATTLE SEARCH", "Find an online-style opponent by trophy and power range. Server matchmaking can replace this simulator.")
    draw_rect(Rect2(170,175,940,360),Color("172537"))
    draw_string(ThemeDB.fallback_font,Vector2(220,220),"MATCHMAKING",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("f7c95c"))
    draw_string(ThemeDB.fallback_font,Vector2(220,270),"Your Trophies: %d"%trophies,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e8eef8"))
    draw_string(ThemeDB.fallback_font,Vector2(220,305),"Army Power: %d"%army_power(),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e8eef8"))
    if search_busy:
        draw_string(ThemeDB.fallback_font,Vector2(220,365),"SEARCHING...",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("65c8ff"))
    elif battle_enemy!="":
        draw_string(ThemeDB.fallback_font,Vector2(220,360),"TARGET: %s"%battle_enemy,HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("ffcf70"))
        draw_string(ThemeDB.fallback_font,Vector2(220,400),"Enemy Power: %d"%enemy_power,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ff9f8f"))
        draw_string(ThemeDB.fallback_font,Vector2(220,435),"Possible Loot scales with opponent strength.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("9fb2cc"))
        draw_rect(Rect2(500,500,280,55),Color("9b5d3e")); draw_string(ThemeDB.fallback_font,Vector2(590,535),"ATTACK",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
    draw_rect(Rect2(500,575,280,65),Color("b07d2e")); draw_string(ThemeDB.fallback_font,Vector2(575,615),"SEARCH OPPONENT",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)

func draw_upgrade():
    draw_panel_title("UPGRADE CITY", "Upgrade your command infrastructure to unlock a larger and stronger empire.")
    upgrade_card(470,180,"COMMAND CENTER",town_level,1800*town_level,"+ capacity, stronger economy")
    upgrade_card(470,285,"BARRACKS",barracks_level,1200*barracks_level,"faster recruitment")
    upgrade_card(470,390,"WALLS",wall_level,1400*wall_level,"better defensive strength")

func upgrade_card(x,y,title,level,cost,desc):
    draw_rect(Rect2(x,y,340,85),Color("182537"))
    draw_string(ThemeDB.fallback_font,Vector2(x+18,y+27),title,HORIZONTAL_ALIGNMENT_LEFT,200,17,Color("ffffff"))
    draw_string(ThemeDB.fallback_font,Vector2(x+18,y+52),"Lv.%d  •  %d Gold"%[level,cost],HORIZONTAL_ALIGNMENT_LEFT,220,14,Color("f7c95c"))
    draw_string(ThemeDB.fallback_font,Vector2(x+18,y+73),desc,HORIZONTAL_ALIGNMENT_LEFT,280,12,Color("8fa2bb"))
    draw_rect(Rect2(x+265,y+15,60,52),Color("a87b28"))
    draw_string(ThemeDB.fallback_font,Vector2(x+278,y+47),"UP",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)

func draw_battle():
    draw_rect(Rect2(20,140,1240,510),Color("b6cf8d"))
    # enemy base
    draw_rect(Rect2(750,220,380,290),Color("d8b28a"))
    draw_rect(Rect2(720,190,440,350),Color("6e5849"),false,10)
    for i in range(5):
        var x=780+i*70
        draw_rect(Rect2(x,285,45,55),Color("d8e0e8"))
        draw_rect(Rect2(x+10,300,25,25),Color("8d4e43"))
    draw_string(ThemeDB.fallback_font,Vector2(770,245),battle_enemy,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("3c2b25"))
    # attacking army visual
    var idx=0
    for name in army:
        if army[name] > 0:
            var count=min(army[name],4)
            for j in range(count):
                var px=100+(idx%5)*90
                var py=360+(idx/5)*65
                var rad=10+min(units[name].cap,20)*0.5
                draw_circle(Vector2(px,py),rad,Color("f0f2f4"))
                draw_circle(Vector2(px,py),rad-4,Color("44566e"))
                idx+=1
    draw_string(ThemeDB.fallback_font,Vector2(55,180),"LIVE RAID",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("7b2f2f"))
    draw_string(ThemeDB.fallback_font,Vector2(55,215),"Target Power: %d"%enemy_power,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("33465b"))
    draw_string(ThemeDB.fallback_font,Vector2(55,245),"Time: %.1fs"%max(battle_time,0),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("33465b"))
    draw_rect(Rect2(1040,635,200,55),Color("8d4b4b"))
    draw_string(ThemeDB.fallback_font,Vector2(1085,670),"FINISH BATTLE",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)

func draw_panel_title(title,sub):
    draw_string(ThemeDB.fallback_font,Vector2(45,145),title,HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color("f7c95c"))
    draw_string(ThemeDB.fallback_font,Vector2(45,170),sub,HORIZONTAL_ALIGNMENT_LEFT,1120,14,Color("91a5bf"))
