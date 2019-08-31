<?php 

$strRoot = "C:\Program Files\TIC-80";
// $strRoot = "C:\Users\Neil\AppData\Roaming\com.nesbox.tic\TIC-80";

$strMain = file_get_contents($argv[1]);

//exit(realpath($argv[1]));

if (preg_match_all('/^require "(.+?)"$/m', $strMain, $arrMatches)) {
	foreach ($arrMatches[1] as $i => $strFile) {
		$strRequire = file_get_contents("{$strRoot}\\{$strFile}.lua");
		$strRequire = trim($strRequire) . "\n\n"; 
		$strMain = str_replace(
			$arrMatches[0][$i],
			$strRequire,
			$strMain
		);
	}

	file_put_contents(str_replace(".lua", ".merged.lua", $argv[1]), $strMain);
}