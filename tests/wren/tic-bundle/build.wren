// title: foo
// author: neilpopham@gmail.com
// script: wren

var T = TIC

class Game is TIC {

	construct new() {

	}

	TIC() {
		T.cls(1)
		T.print("hello world",0,0,5)
	}
}

class Player {
	construct new() {
		_x = 0
		_y = 0		
	}
}

// <PALETTE>
// 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
// </PALETTE>