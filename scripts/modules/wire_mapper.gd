extends Node

# Kamus Penerjemah Port (Jika Port manual 0 harus ke Port otomatis 1)
var port_map = {
    0: 0, # Default: Port sama
    1: 1
}

func petakan_kabel_lama(mesin_lama) -> Dictionary:
    var peta_kabel = {"outgoing": [], "incoming": []}
    
    if mesin_lama.has_method("get_outgoing_connections"):
        for kabel in mesin_lama.get_outgoing_connections():
            if is_instance_valid(kabel.target_node):
                peta_kabel["outgoing"].append({
                    "target_node": kabel.target_node,
                    "from_port": port_map.get(kabel.from_port, 0),
                    "to_port": kabel.to_port
                })
                
    if mesin_lama.has_method("get_incoming_connections"):
        for kabel in mesin_lama.get_incoming_connections():
            if is_instance_valid(kabel.source_node):
                peta_kabel["incoming"].append({
                    "source_node": kabel.source_node,
                    "from_port": kabel.from_port,
                    "to_port": kabel.to_port
                })
    return peta_kabel

func jahit_kabel_baru(mesin_baru, peta_kabel: Dictionary):
    # Jahit Output
    for koneksi in peta_kabel["outgoing"]:
        if is_instance_valid(koneksi["target_node"]):
            mesin_baru.call_deferred("connect_to_node", koneksi["target_node"], koneksi["from_port"], koneksi["to_port"])
            
    # Jahit Input
    for koneksi in peta_kabel["incoming"]:
        if is_instance_valid(koneksi["source_node"]):
            var node_sumber = koneksi["source_node"]
            node_sumber.call_deferred("connect_to_node", mesin_baru, koneksi["from_port"], koneksi["to_port"])