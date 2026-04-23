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
    pass