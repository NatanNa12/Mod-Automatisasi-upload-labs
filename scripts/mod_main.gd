extends Node
# ==========================================
# Natan's Auto Builder Mod - Entry Point
# ==========================================

func _init():
    # Perintah ini akan memastikan Core dimuat paling pertama saat game start
    var core_script = preload("res://scripts/core/architect_core.gd")
    var core_node = core_script.new()
    core_node.name = "NatanAutoBuilderCore"
    
    # Menyuntikkan Core ke dalam root direktori game secara permanen
    get_tree().root.call_deferred("add_child", core_node)
    print("[Natan_Entry] Protokol Natan Berhasil Disuntikkan ke Root Engine.")