extends Node
class_name HealthComponent

# ============================================
# HEALTH COMPONENT
# Verwaltet HP, Schaden, Tod
# ============================================

signal health_changed(current: float, max: float)
signal died()
signal damaged(amount: float)
signal healed(amount: float)

@export var max_health: float = 100.0
@export var invincible: bool = false

var current_health: float = 0.0
var is_dead: bool = false

func _ready():
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: float) -> bool:
	"""
	Fügt Schaden zu.
	Returns: true wenn Schaden zugefügt wurde, false wenn invincible/tot
	"""
	if is_dead or invincible or amount <= 0:
		return false
	
	current_health -= amount
	current_health = max(current_health, 0.0)
	
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		_die()
	
	return true

func heal(amount: float):
	"""Heilt den Spieler"""
	if is_dead or amount <= 0:
		return
	
	current_health += amount
	current_health = min(current_health, max_health)
	
	healed.emit(amount)
	health_changed.emit(current_health, max_health)

func get_health_percent() -> float:
	"""Gibt HP als Prozent zurück (0.0 - 1.0)"""
	if max_health <= 0:
		return 0.0
	return current_health / max_health

func _die():
	"""Spieler stirbt"""
	if is_dead:
		return
	
	is_dead = true
	died.emit()
	print("Player died!")

func respawn(at_full_health: bool = true):
	"""Respawn Spieler"""
	is_dead = false
	if at_full_health:
		current_health = max_health
	health_changed.emit(current_health, max_health)

