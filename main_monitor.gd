extends Node
# ==========================================
# Natan's Auto Builder Mod - Fase 1
# Modul: Passive State Monitor
# ==========================================

# Variabel kontrol absolut
var auto_collector_unlocked = false
var is_transitioning = false # Boolean Lock (Mencegah Double-Execution Crash)

func _ready():
    # Indikator visual di console (F12) bahwa mod berhasil di-load
    print("[Natan_Mod] Arsitektur Auto Builder berhasil diinisialisasi.")

func _process(_delta):
    # Jika mod sedang sibuk menghancurkan/mengganti node, hentikan pemindaian
    if is_transitioning:
        return
        
    # Memindai status pembukaan (unlock) secara terus-menerus
    if not auto_collector_unlocked:
        _pantau_research_tree()

func _pantau_research_tree():
    # Catatan Teknis: Kita berasumsi sistem game menggunakan Autoload bernama 'GameData' atau 'Research'
    # Jika nama internal Upload Labs berbeda (misal 'TechTree'), kita akan ubah nanti saat tes
    if has_node("/root/GameData"):
        var game_data = get_node("/root/GameData")
        
        # Mengecek apakah teknologi Auto Collector gratis tersebut sudah terbuka
        if game_data.is_unlocked("tech_auto_collector"):
            auto_collector_unlocked = true
            print("[Natan_Mod] Peringatan: Auto Collector Terbuka. Memulai Protokol Transisi...")
            
            # Mengunci state agar tidak terjadi eksekusi ganda
            is_transitioning = true 
            
            # Memanggil fungsi Fase 2 (Akan kita bangun di chat selanjutnya)
            _inisialisasi_fase_dua()

func _inisialisasi_fase_dua():
    # Placeholder untuk skrip Pause & Harvest
    func _inisialisasi_fase_dua():
    print("[Natan_Mod] Fase 2 Aktif: Menjalankan protokol Pause & Harvest...")
    _bekukan_dan_ekstrak_semua()

func _bekukan_dan_ekstrak_semua():
    # Mengambil semua node yang terdaftar sebagai mesin manual di dalam game
    # (Catatan: Kita berasumsi developer Upload Labs menggunakan grup "manual_nodes")
    var mesin_manual = get_tree().get_nodes_in_group("manual_nodes")
    
    for mesin in mesin_manual:
        # 1. Memicu Penangguhan (Pause) pada mesin tersebut
        mesin.process_mode = Node.PROCESS_MODE_DISABLED
        
        # 2. Mengamankan Paket Data di Kabel (Asinkron)
        await _tunggu_kabel_kosong(mesin)
        
        # 3. Bypass Limit Gudang Sementara (Mencegah overflow)
        var batas_asli = 0
        if has_node("/root/GlobalDataCenter"):
            var gudang = get_node("/root/GlobalDataCenter")
            batas_asli = gudang.max_storage
            gudang.max_storage = INF # Bobol limit menjadi tak terhingga
            
        # 4. Ekstraksi Data (The Harvest)
        var data_panen = 0
        if "internal_storage" in mesin:
            data_panen = mesin.internal_storage
        
        print("[Natan_Mod] Mesin ", mesin.name, " dibekukan. Data diamankan: ", data_panen)
        
        # 5. Kembalikan limit gudang ke kondisi normal
        if has_node("/root/GlobalDataCenter"):
            get_node("/root/GlobalDataCenter").max_storage = batas_asli
            
        # 6. Memicu eksekusi Fase 3 (Akan kita rancang di tahap selanjutnya)
        # _eksekusi_fase_tiga(mesin, data_panen)

func _tunggu_kabel_kosong(mesin):
    # Memastikan mesin tersebut benar-benar memiliki fungsi kabel sebelum dicek
    if mesin.has_method("get_outgoing_connections"):
        var kabel_kabel = mesin.get_outgoing_connections()
        for kabel in kabel_kabel:
            # Tahan eksekusi (looping) selama masih ada paket yang berjalan di kabel
            while kabel.get_packet_count() > 0:
                await get_tree().process_frame # Tunggu 1 frame game engine