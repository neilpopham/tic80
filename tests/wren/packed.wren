// C:\Users\Neil\AppData\Roaming\com.nesbox.tic\TIC-80\tests\wren\header.wren
// title:  foo
// author: neilpopham@gmail.com
// desc:   foo
// script: wren
// C:\Users\Neil\AppData\Roaming\com.nesbox.tic\TIC-80\tests\wren\player.wren
class Player {
	construct new() {
		_x = 0
		_y = 0		
	}
}
// C:\Users\Neil\AppData\Roaming\com.nesbox.tic\TIC-80\tests\wren\includes.wren
// import "./header"
// import "./player"

/*
	Admin CMD: choco install nodejs
	npm i -g scriptpacker
	scriptpacker build [input]
*/

var T = TIC

class Game is TIC {

	construct new() {
		
	}

	TIC() {
		T.cls(1)
		T.print("hello",0,0,5)
	}
}

// <PALETTE>
// 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
// </PALETTE>
