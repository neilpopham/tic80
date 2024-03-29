// title:  buttons
// author: neilpopham@gmail.com
// desc:   Test for a button class
// script: wren

var T = TIC

class Controller {

	up { btn(0) }
	down { btn(1) }
	left { btn(2) }
	right { btn(3) }
	a { btn(4) }
	b { btn(5) }
	x { btn(6) }
	y { btn(7) }

	buttons { _buttons }

	construct new() {
		init(0)
	}

	construct new(port) {
		init(port)
	}

	init(port) {
		var min = port * 8
		var max = min + 7
		_buttons = []
		for (button in min..max) {
			_buttons.add(Button.new(button))
		}
	}

	btn(n) { _buttons[n].pressed }
}

class Counter {

	tick { _tick }
	min { _min }
	max { _max }
	valid { (_tick >= _min) && (_tick <= _max) }

	onMax = (value) { _onMax = value }

	construct new(max) {
		init(0, max)
	}

	construct new(min, max) {
		init(min, max)
	}

	init(min, max) {
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

class Button {

	cutoff { _cutoff }
	tick { (_released == false) && (_counter.tick == 0) ? _counter.max : _counter.tick }
	disabled { _disabled }

	disabled = (value) { _disabled = value }
	onPress = (value) { _onPress = value }
	onRelease = (value) { _onRelease = value }
	onLong = (value) { _onLong = value }
	onShort = (value) { _onShort = value }

	construct new() {
		init(0, 20)
	}

	construct new(index) {
		init(index, 20)
	}

	construct new(index, cutoff) {
		init(index, cutoff)
	}

	init(index, cutoff) {
		_index = index
		_cutoff = cutoff
		_counter = Counter.new(1, 30)
		_released = true
		_disabled = false
		_onPress = null
		_onRelease = null
		_onLong = null
		_onShort = null
	}

	check() {
		if (T.btn(_index)) {
			if (_disabled) return
			//if ((_counter.tick == 0) && (false ==_released)) return
			if (false == _released) {
				if (_counter.tick == 0) return
			} else if (_onPress is Fn) {
				_onPress.call()
			}
			_counter.increment()
			_released = false
		} else {
			if (false == _released) {
				var t = _counter.tick == 0 ? _counter.max : _counter.tick
				if (_onRelease is Fn) {
					_onRelease.call(t)
				}
				if (t > _cutoff) {
					if (_onLong is Fn) {
						_onLong.call(t)
					}
				} else if (_onShort is Fn) {
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
}

class Game is TIC {

	construct new() {
		_controllers = []
		_state = []

		for (c in 0..3) {
			_controllers.add(Controller.new(c))
			for (b in 0..7) {
				var button = _controllers[c].buttons[b]
				button.onPress = Fn.new {
					T.trace("B" + b.toString + " Pressed")
				}
				button.onRelease = Fn.new { |tick|
					T.trace("B" + b.toString + " Released after " + tick.toString + " ticks")
				}
				button.onShort = Fn.new { |tick|
					T.trace("B" + b.toString + " Short press")
				}
				button.onLong = Fn.new { |tick|
					T.trace("B" + b.toString + " Long press")
				}
			}
		}
	}

	TIC() {
		T.cls(0)
		var directions = ["UP", "DOWN", "LEFT", "RIGHT", "A", "B", "X", "Y"]
		for (c in 0..3) {
			T.print("PLAYER " + (c + 1).toString, c * 64, 0, 11)
			for (b in 0..7) {
				T.print(
					directions[b],
					c * 64,
					b * 8 + 8,
					_controllers[c].btn(b) ? 15 : 6
				)
				var cutoff = _controllers[c].buttons[b].cutoff
				var colour = _controllers[c].buttons[b].tick > cutoff ? 9 : 13
				T.rect(c * 64 + 30, b * 8 + 8, 30, 5, 2)
				if (_controllers[c].buttons[b].tick) {
					T.rect(
						c * 64 + 60 - _controllers[c].buttons[b].tick,
						b * 8 + 8,
						_controllers[c].buttons[b].tick, 5,
						colour
					)
				}
			}
		}
	}
}

// <PALETTE>
// 000:140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6
// </PALETTE>
