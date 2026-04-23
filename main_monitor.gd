extends Node

# ==========================================
# Natan's Auto Builder Mod - Fase 1-3 (Integrated)
# Modul: Passive Monitor & Adaptive Reconstructor
# ==========================================

var auto_collector_unlocked = false
var is_transitioning = false
var auto_collector_path = "" # [Perbaikan 4: Dynamic Pathing]

func _ready():
    print("[Natan_Mod] Arsitektur Auto Builder berhasil diinisialisasi.")
    _scan_direktori_auto_collector() # Menjalankan Perbaikan 4 saat start

func _process(_delta):
    if is_transitioning:
        return
    if not auto_collector_unlocked:
        _pantau_research_tree()

# [Perbaikan 4]: Mencari file .tscn secara dinamis agar mod tidak rusak jika game update folder
func _scan_direktori_auto_collector():
    var target_file = "AutoCollector.tscn"
    var folders = ["res://Nodes/", "res://Entities/", "res://Scenes/", "res://Prefabs/"]
    for folder in folders:
        var path = folder + target_file
        if ResourceLoader.exists(path):
            auto_collector_path = path
            print("[Natan_Mod] Path ditemukan secara dinamis: ", auto_collector_path)
            return
    print("[Natan_Mod] PERINGATAN: Path Auto Collector gagal ditemukan otomatis.")

func _pantau_research_tree():
    if has_node("/root/GameData"):
        var game_data = get_node("/root/GameData")
        if game_data.is_unlocked("tech_auto_collector"):
            auto_collector_unlocked = true
            is_transitioning = true 
            print("[Natan_Mod] Peringatan: Auto Collector Terbuka. Memulai Protokol Transisi...")
            _inisialisasi_proses_transisi()

func _inisialisasi_proses_transisi():
    print("[Natan_Mod] Fase 2 & 3 Aktif: Menjalankan Adaptive Pause, Harvest & Replace...")
    _proses_eksekusi_total()

func _proses_eksekusi_total():
    # [Perbaikan 1]: Fallback scan jika grup manual_nodes tidak didefinisikan developer
    var targets = get_tree().get_nodes_in_group("manual_nodes")
    if targets.is_empty():
        print("[Natan_Mod] Grup manual_nodes kosong, memindai manual via filter nama...")
        # Mencari semua node di root yang mengandung kata 'Manual'
        for node in get_tree().get_root().get_children():
            if "Manual" in node.name:
                targets.append(node)

    for mesin in targets:
        # Pause
        mesin.process_mode = Node.PROCESS_MODE_DISABLED
        
        # [Perbaikan 2 & 3]: Proteksi Null dan Timeout Kabel (3 detik)
        await _tunggu_kabel_bersih(mesin, 3.0)
        
        # Harvest (Bypass Storage)
        var batas_asli = 0
        var gudang = null
        if has_node("/root/GlobalDataCenter"):
            gudang = get_node("/root/GlobalDataCenter")
            batas_asli = gudang.max_storage
            gudang.max_storage = INF
        
        var data_panen = 0
        if "internal_storage" in mesin:
            data_panen = mesin.internal_storage
        
        # Reinkarnasi (Fase 3)
        await _reinkarnasi_objek(mesin, data_panen, gudang, batas_asli)

func _tunggu_kabel_bersih(mesin, timeout_sec):
    if not mesin.has_method("get_outgoing_connections"):
        return
        
    var kabel_kabel = mesin.get_outgoing_connections()
    # [Perbaikan 2]: Validasi Tipe Data Kabel sebelum looping
    if typeof(kabel_kabel) != TYPE_ARRAY or kabel_kabel.is_empty():
        return

    # [Perbaikan 3]: Sistem Timeout agar tidak stuck selamanya jika ada bug game
    var start_time = Time.get_ticks_msec()
    for kabel in kabel_kabel:
        while kabel.get_packet_count() > 0:
            if (Time.get_ticks_msec() - start_time) > (timeout_sec * 1000):
                print("[Natan_Mod] Timeout kabel pada ", mesin.name, ". Memaksa lanjut.")
                break
            await get_tree().process_frame

func _reinkarnasi_objek(mesin_manual, data_panen, gudang, batas_asli):
    if auto_collector_path == "":
        return

    var cetakan = load(auto_collector_path)
    var mesin_baru = cetakan.instantiate()
    
    # Ambil metadata mesin lama
    var pos = mesin_manual.global_position
    var induk = mesin_manual.get_parent()
    var z_indeks = mesin_manual.z_index # [Perbaikan 5: Z-Index Preservation]
    
    # [Perbaikan 6]: Type Casting ke Float untuk mencegah Type Mismatch saat suntikan data
    if "internal_storage" in mesin_baru:
        mesin_baru.internal_storage = float(data_panen)
    
    # Eksekusi Ganti
    mesin_manual.queue_free()
    await get_tree().process_frame # Memberi napas pada engine untuk membersihkan memori
    
    induk.add_child(mesin_baru)
    mesin_baru.global_position = pos
    mesin_baru.z_index = z_indeks # [Perbaikan 5]
    mesin_baru.name = mesin_manual.name + "_Auto"
    
    # Kembalikan limit gudang
    if gudang:
        gudang.max_storage = batas_asli
    
    print("[Natan_Mod] Sukses mengganti: ", mesin_baru.name)