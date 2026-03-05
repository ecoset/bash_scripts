#!/bin/bash

dir_templates="$HOME/Templates"

folders=("prog" "text" "web")

files_prog=("assembly.asm" "c++.cpp" "golang.go" "nim.nim" "perlModule.pm" "ruby.rb" "bash-sh.sh" "c#.cs" "header.h" "ObjC.m" "perl.pl" "rust.rs" "c.c" "falcon.fal" "java.java" "perl6.pl" "python3.py" "shellcode.s")
files_text=("document.odt" "plaintext.txt" "presentation.odp" "spreadsheet.ods")
files_web=("css.css" "html.html" "javascript.js" "php.php" "xml.xml")

# Создание функции создание папок или файлов
# Параметры:
### $1 - d-директория, f-файл.
### $2 - адрес/название
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

# Создание папок prog, text, web в директории Templates
create() {
	for folder in $1; do
		if [[ ! -d $folder ]]; then
			create_item "d" "$folder" && create "$1" "$2"
		elif [[ -d $folder ]]; then
			for file in $2; do
				if [[ ! -f $file ]]; then
					create_item "f" "${folder}/${file}"
				elif [[ -f $file ]]; then
					echo "Файл $file уже существует"
				else
					echo "Ошибка на этапе создания файла \"$file\""
				fi
			done
		else
			echo "Ошибка на этапе создания папки \"$folder\""
		fi
	done
}

# Создание папки Templates в родительской директории
create_item "d" "${dir_templates}"
