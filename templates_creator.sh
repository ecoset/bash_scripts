#!/bin/bash

dir_templates="$HOME/Templates/"

folders=("prog" "text" "web")

files_prog=("assembly.asm" "c++.cpp" "golang.go" "nim.nim" "perlModule.pm" "ruby.rb" "bash-sh.sh" "c#.cs" "header.h" "ObjC.m" "perl.pl" "rust.rs" "c.c" "falcon.fal" "java.java" "perl6.pl" "python3.py" "shellcode.s")
files_text=("document.odt" "plaintext.txt" "presentation.odp" "spreadsheet.ods")
files_web=("css.css" "html.html" "javascript.js" "php.php" "xml.xml")

err="Error"

dir_or_file(){
 if [[ $1 = "-d" ]]; then
    item="Директория"
  elif [[ $1 = "-f" ]]; then
    item="Файл"
  else
    echo "$err"
  fi 
}

rights_check(){
  echo "Проверка прав $1"
  # ---------------------------------------
  successful_print="Права $1 соответствуют требованиям"
  permissions_added="Добавленно разрешиние на"
  reading="чтение"
  write="запись"
  execution="выполнение"
  # ---------------------------------------

  if [[ -f $1 || -d $1 ]]; then
    if [[ -r $1 ]]; then
      if [[ -w $1 ]]; then
        echo "$successful_print"
      else
        chmod u+w "$1" && echo "$permissions_added $write $1" && rights_check "$1"
      fi
    else
      chmod u+r "$1" && echo "$permissions_added $reading $1" && rights_check "$1" 
    fi
  fi
# Если это директория дополнительно проверяются разрешения на выполнения
  if [[ -d $1 ]]; then
    if [[ -x $1 ]]; then
      echo "$successful_print"
    else
      chmod u+x "$1" && echo "$permissions_added $execution $1" && rights_check "$1"  
    fi
  fi   

}

existence_check(){
  dir_or_file "$1"
  if [[ $1 $2 $3 ]]; then
    echo "$item уже существует"
  elif [[! "$1" "$2" ]]; then
    "$3"
  else
    echo "$err"
  fi
}

create_dir(){
  mkdir "$1"
}
