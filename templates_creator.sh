#!/bin/bash

dir_templates="$HOME/Templates"

folders=("prog" "text" "web")

files_prog=("assembly.asm" "c++.cpp" "golang.go" "nim.nim" "perlModule.pm" "ruby.rb" "bash-sh.sh" "c#.cs" "header.h" "ObjC.m" "perl.pl" "rust.rs" "c.c" "falcon.fal" "java.java" "perl6.pl" "python3.py" "shellcode.s")
files_text=("document.odt" "plaintext.txt" "presentation.odp" "spreadsheet.ods")
files_web=("css.css" "html.html" "javascript.js" "php.php" "xml.xml")

err="Error"

# 1. Проверка существование папки Templates и её прав.
#   1. Если нет, создать и присвоить права и запустить функцию проверки
#   2. Если есть, проверить права
#     1. Если права отсутствую, присвоить и запустить функцию занова
#     2. Если есть, заупустить функцию проверки

create_item() {
	if [[ $1 = "d" ]]; then
		if [[ ! -d $2 ]]; then
			mkdir "$2" && create_item "$1" "$2"
		elif [[ -d $2 ]]; then
			if [[ ! -r $2 || ! -w $2 ]]; then
				chmod -R 744 "$2" && create_item "$1" "$2"
			elif [[ -r $2 && -w $2 ]]; then
				echo "Директрия \"$2\" создана"
			else
				echo "Ошибка на стадии создания директории \"$2\""
			fi
		fi
	elif [[ $1 = "f" ]]; then
		if [[ ! -f $2 ]]; then
			touch "$2" && create_item "$1" "$2"
		elif [[ -f $2 ]]; then
			if [[ ! -r $2 || ! -w $2 ]]; then
				chmod 744 "$2" && create_item "$1" "$2"
			elif [[ -r $2 && -w $2 ]]; then
				echo "Файл \"$2\" создан"
			else
				echo "Ошибка на стадии создания директории \"$2\""
			fi
		fi
	fi
}

create_item "d" "${dir_templates}"
