extends Node

var auto_collector_unlocked = false
var is_transitioning = false
var auto_collector_path = "" 
var wire_mapper_node = null 
var time_multiplier = 5.0 

func _ready():
    print("[Natan_Mod] Arsitektur Auto Builder berhasil diinisialisasi.")
    _scan_direktori_auto_collector() 
    
    var mapper_script = preload("res://scripts/modules/wire_mapper.gd")
    wire_mapper_node = mapper_script.new()
    add_child(wire_mapper_node) 
    print("[Natan_Mod] Modul Wire Mapper berhasil di-load.")
    
    Engine.time_scale = time_multiplier
    print("[Natan_Mod] Fitur 41 Aktif: Kecepatan Game x", time_multiplier)

func _process(_delta):
    if is_transitioning:
        return
    if not auto_collector_unlocked:
        _pantau_research_tree()

func _scan_direktori_auto_collector():
    var target_file = "AutoCollector.tscn"
    var folders = ["res://Nodes/", "res://Entities/", "res://Scenes/", "res://Prefabs/"]
    for folder in folders:
        var path = folder + target_file
        if ResourceLoader.exists(path):
            auto_collector_path = path
            return

func _pantau_research_tree():
    if has_node("/root/GameData"):
        var game_data = get_node("/root/GameData")
        if game_data.is_unlocked("tech_auto_collector"):
            auto_collector_unlocked = true
            is_transitioning = true 
            _inisialisasi_proses_transisi()

func _inisialisasi_proses_transisi():
    _proses_eksekusi_total()

func _proses_eksekusi_total():
    var targets = get_tree().get_nodes_in_group("manual_nodes")
    if targets.is_empty():
        for node in get_tree().get_root().get_children():
            if "Manual" in node.name:
                targets.append(node)

    for mesin in targets:
        await get_tree().create_timer(0.1).timeout # Anti-spam delay
        
        mesin.process_mode = Node.PROCESS_MODE_DISABLED
        await _tunggu_kabel_bersih(mesin, 3.0)
        
        var peta_kabel_ingatan = {}
        if wire_mapper_node:
            peta_kabel_ingatan = wire_mapper_node.petakan_kabel_lama(mesin)
        
        var batas_asli = 0
        var gudang = null
        if has_node("/root/GlobalDataCenter"):
            gudang = get_node("/root/GlobalDataCenter")
            batas_asli = gudang.max_storage
            gudang.max_storage = INF
        
        var data_panen = 0
        if "internal_storage" in mesin:
            data_panen = mesin.internal_storage
        
        await _reinkarnasi_objek(mesin, data_panen, gudang, batas_asli, peta_kabel_ingatan)
        _tampilkan_notifikasi_visual(mesin.global_position)

func _tunggu_kabel_bersih(mesin, timeout_sec):
    if not mesin.has_method("get_outgoing_connections"):
        return
    var kabel_kabel = mesin.get_outgoing_connections()
    if typeof(kabel_kabel) != TYPE_ARRAY or kabel_kabel.is_empty():
        return
    var start_time = Time.get_ticks_msec()
    for kabel in kabel_kabel:
        while kabel.get_packet_count() > 0:
            if (Time.get_ticks_msec() - start_time) > (timeout_sec * 1000):
                break
            await get_tree().process_frame

func _reinkarnasi_objek(mesin_manual, data_panen, gudang, batas_asli, peta_kabel_ingatan):
    if auto_collector_path == "":
        return
    var cetakan = load(auto_collector_path)
    var mesin_baru = cetakan.instantiate()
    var pos = mesin_manual.global_position
    var induk = mesin_manual.get_parent()
    var z_indeks = mesin_manual.z_index 
    
    if "internal_storage" in mesin_baru:
        mesin_baru.internal_storage = float(data_panen)
    
    mesin_manual.queue_free()
    await get_tree().process_frame 
    
    induk.add_child(mesin_baru)
    mesin_baru.global_position = pos
    mesin_baru.z_index = z_indeks 
    mesin_baru.name = mesin_manual.name + "_Auto"
    
    if gudang:
        gudang.max_storage = batas_asli
        
    if wire_mapper_node and not peta_kabel_ingatan.is_empty():
        wire_mapper_node.jahit_kabel_baru(mesin_baru, peta_kabel_ingatan)

func _tampilkan_notifikasi_visual(pos):
    var label = Label.new()
    label.text = "AUTO-DEPLOYED"
    label.modulate = Color.GREEN
    get_tree().root.add_child(label)
    label.global_position = pos
    var tween = create_tween()
    tween.tween_property(label, "global_position:y", pos.y - 50, 1.0)
    tween.tween_property(label, "modulate:a", 0.0, 1.0)
    tween.tween_callback(label.queue_free)