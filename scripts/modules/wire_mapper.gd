extends Node

# ==========================================
# Natan's Auto Builder Mod - Fase 4
# Modul: Dynamic Wire & Port Mapper
# ==========================================

# Fungsi ini akan dipanggil SESAAT SEBELUM mesin manual dihancurkan (queue_free)
func petakan_kabel_lama(mesin_lama) -> Dictionary:
    var peta_kabel = {
        "outgoing": [], # Kabel yang keluar dari mesin ini ke tempat lain
        "incoming": []  # Kabel dari tempat lain yang masuk ke mesin ini
    }
    
    # Deteksi arsitektur kabel bawaan Upload Labs
    if mesin_lama.has_method("get_outgoing_connections"):
        var outgoing = mesin_lama.get_outgoing_connections()
        for kabel in outgoing:
            # Menyimpan referensi target dan ID port secara absolut
            peta_kabel["outgoing"].append({
                "target_node": kabel.target_node,
                "from_port": kabel.from_port,
                "to_port": kabel.to_port
            })
            
    if mesin_lama.has_method("get_incoming_connections"):
        var incoming = mesin_lama.get_incoming_connections()
        for kabel in incoming:
            peta_kabel["incoming"].append({
                "source_node": kabel.source_node,
                "from_port": kabel.from_port,
                "to_port": kabel.to_port
            })
            
    print("[Natan_WireMapper] Memori kabel direkam: ", peta_kabel["outgoing"].size(), " Out, ", peta_kabel["incoming"].size(), " In.")
    return peta_kabel

# Fungsi ini dipanggil SESUDAH mesin otomatis baru diletakkan di kanvas
func jahit_kabel_baru(mesin_baru, peta_kabel: Dictionary):
    print("[Natan_WireMapper] Memulai operasi bedah saraf (Menyambung kabel)...")
    
    # 1. Menjahit kabel Output
    for koneksi in peta_kabel["outgoing"]:
        if is_instance_valid(koneksi["target_node"]):
            # Bypass deteksi sistem bawaan menggunakan Reflection
            if mesin_baru.has_method("connect_to_node"):
                mesin_baru.connect_to_node(koneksi["target_node"], koneksi["from_port"], koneksi["to_port"])
            else:
                print("[Natan_WireMapper] ERROR: Gagal menemukan fungsi koneksi pada mesin baru!")

    # 2. Menjahit kabel Input
    for koneksi in peta_kabel["incoming"]:
        if is_instance_valid(koneksi["source_node"]):
            var node_sumber = koneksi["source_node"]
            if node_sumber.has_method("connect_to_node"):
                node_sumber.connect_to_node(mesin_baru, koneksi["from_port"], koneksi["to_port"])
                
    print("[Natan_WireMapper] Rekoneksi absolut berhasil. Mesin online.")