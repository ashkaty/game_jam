class_name RingBuffer
extends RefCounted	

@export 
var buffer_size:int

var buffer:Array

var head:int = 0
var length:int = 0

var tail := 0

# -- Create Buffer -- # 
func _init(buffer_size:int) -> void:
	self.buffer_size = buffer_size
	buffer = []
	buffer.resize(buffer_size)

# -- Buffer Methods -- #

func push(value:Variant) -> void:
        buffer[head] = value
        head = (head + 1) % buffer_size
        if length < buffer_size:
                length += 1
        else:
                tail = (tail + 1) % buffer_size

func clear() -> void:
	head = 0
	length = 0
	for i in buffer_size:
		buffer[i] = null

func get_index() -> Variant:
	var returnValue: Variant = buffer[tail]
	tail = tail + 1 if tail < buffer_size else 0
	return returnValue

func get_latest(offset:int = 0) -> Variant:
	if offset >= length:
		return null
	var idx := (head - 1 - offset) % buffer_size
	return buffer[idx]
	
func get_at(index:int) -> Variant:
	if index < 0 or index >= length:
		return null
	var start := (head - length + buffer_size) % buffer_size
	return buffer[(start + index) % buffer_size]

func is_full() -> bool:
	if length == buffer_size:
		return true
	else:
		return false


func duplicate() -> Array:
	var out:Array = []
	if length == 0:
		return out
	var start := (head - length + buffer_size) % buffer_size
	for i in range(length):
		out.append(buffer[(start + i) % buffer_size])
	return out.duplicate()			# Return a safe copy


static func create_by_seconds(seconds:float, samples_per_second:float) -> RingBuffer:
	var entries := int(ceil(seconds * samples_per_second))
	return RingBuffer.new(entries)
