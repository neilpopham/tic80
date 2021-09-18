// title:  classes
// author: neilpopham@gmail.com
// desc:   testing classes
// script: wren

var T = TIC

class Screen {
	static width { 240 }
	static height { 136 }
	static x2 { 239 }
	static y2 { 135 }
}

class Pad {
	static up { 0 }
	static down { 1 }
	static left { 2 }
	static right { 3 }
}

class Input {
	static up { T.btn(0) }
	static down { T.btn(1) }
	static left { T.btn(2) }
	static right { T.btn(3) }
}

class Hitbox {
	x { _x }
	y { _y }
	x2 { _x2 }
	y2 { _y2 }
	width { _width }
	height { _height }

	construct new() {
		init(0, 0, 8, 8, 7, 7)
	}

	construct new(x, y, w, h) {
		init(x, y, w, h, w - 1, h - 1)
	}

	construct new(x, y, w, h, x2, y2) {
		init(x, y, w, h, x2, y2)
	}

	init(x, y, w, h, x2, y2) {
		_x = x
		_y = y
		_width = w
		_height = h
		_x2 = x2
		_y2 = y2
	}
}

class Entity {
	x { _x }
	y { _y }
	hitbox { _hitbox }
	complete { _complete }
	health { _health }

	x = (value) { _x = value }
	y = (value) { _y = value }
	hitbox = (value) { _hitbox = value }
	complete = (value) { _complete = value }
	health = (value) { _health = value }

	construct new(x, y) {
		_x = x
		_y = y
		_hitbox = Hitbox.new()
		_complete = false
		_health = 0
	}

	distance(target) {
		var dx = (target.x + 4) / 1000 - (x + 4) / 1000
		var dy = (target.y + 4) / 1000 - (y + 4) / 1000
		return (dx.pow(2) + dy.pow(2)).sqrt * 1000
	}

	collide(object) {
		return collide(object, x, y)

	}

	collide(object, x, y) {
		if (complete || object.complete) return false
		return (x + hitbox.x <= object.x + object.hitbox.x2) &&
			(object.x + object.hitbox.x < x + hitbox.width) &&
			(y + hitbox.y <= object.y + object.hitbox.y2) &&
			(object.y + object.hitbox.y < y+hitbox.height)
	}

	damage(value) {
		health = health - value
		if (health > 0) hit(value) else destroy(value)
	}

	hit(value) {

	}

	destroy(value) {
		complete = true
	}
}

class Counter {

	tick { _tick }
	min { _min }
	max { _max }
	valid { (_tick >= _min) && (_tick <= _max) }

	onMax = (value) { _onMax = value }

	construct new(min, max) {
		_min = min
		_max = max
		_onMax = null
		_tick = 0
	}

	increment() {
		_tick = _tick + 1
		if (_tick > _max) {
			reset()
			if (_onMax is Fn) {
				_onMax.call()
			}
		}
	}

	reset() {
		reset(0)
	}

	reset(value) {
		_tick = value
	}
}

/*
class Button is Counter {

	tick { _tick }

	construct new(index) {
		super(1, 12)
		_index = index
		_released = true
		_disabled = false
		_onRelease = null
		_onLong = null
		_onShort = null
		_tick = 0
	}

	check() {
		if (T.btn(_index)) {
			if (_disabled) return
			if ((_tick == 0) && (false ==_released)) return
			this.increment()
			_released = false
		} else {
			if (false == _released) {
				var t = _tick == 0 ? _max : _tick
				if (_onRelease is Fn) {
					_onRelease.call(tick)
				}
				if (_tick > 12) {
					if (_onLong is Fn) {
						_onLong.call(tick)
					}
				} else {
					if (_onShort is Fn) {
						_onShort.call(tick)
					}
				}
			}
			this.reset()
			_released = true
		}
	}

	pressed {
		this.check()
		return this.valid()
	}
}
*/
class Button {

	onRelease = (value) { _onRelease = value }
	onLong = (value) { _onLong = value }
	onShort = (value) { _onShort = value }

	construct new(index) {
		_index = index
		_counter = Counter.new(1, 30)
		_released = true
		_disabled = false
		_onRelease = null
		_onLong = null
		_onShort = null
	}

	check() {
		if (T.btn(_index)) {
			if (_disabled) return
			if ((_counter.tick == 0) && (false ==_released)) return
			_counter.increment()
			_released = false
		} else {
			if (false == _released) {
				var t = _counter.tick == 0 ? _counter.max : _counter.tick
				if (_onRelease is Fn) {
					_onRelease.call(t)
				}
				if (t > 20) {
					if (_onLong is Fn) {
						_onLong.call(t)
					}
				} else  if (_onShort is Fn) {
					_onShort.call(t)
				}
			}
			_counter.reset()
			_released = true
		}
	}

	pressed {
		check()
		return _counter.valid
	}

	tick { _counter.tick }
}

class GameState {
	static game { __game }
	static game = (value) { __game = value }
	static camera { __game.camera }
}

class Game is TIC {
	camera { _camera }
	player { _player }
	enemy { _enemy }

	construct new() {

		_counter = Counter.new(0, 60)
		_counter.onMax = Fn.new { T.print("hello", 0, 10) }
		GameState.game = this

		_button = Button.new(Pad.down)
		_button.onRelease = Fn.new {|tick| T.print("released " + tick.toString, 0, 50) }
		_button.onShort = Fn.new {|tick| T.print("short " + tick.toString, 0, 60) }
		_button.onLong = Fn.new {|tick| T.print("long  " + tick.toString, 0, 60) }

		_player = Entity.new(10, 10)
	}

	TIC() {
		T.cls(0)
		_counter.increment()
		T.print(_counter.tick,0,0,6)

		T.print(_button.pressed,0,20,7)
		if (_button.pressed) {
			T.print("pressed",0,30,7)
		}
		T.print(_button.tick,20,40,7)
	}
}

// <PALETTE>
// 000:140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6
// </PALETTE>
