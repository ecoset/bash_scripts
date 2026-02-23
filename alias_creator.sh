#!/bin/bash

# Messages
get_alias="Enter alias name:"
get_command="Enter command for alias:"
get_comment="Enter comment (alias description):"
get_result="Generated alias:"
get_actions="Enter \"y\" to save alias or \"n\" to cancel:"
get_terminal="Specify your shell: \n 1 - Bash \n 2 - Zsh"
get_succesfull="Success"
get_error="Error"
get_correct="Start over - \"y\" \nExit - \"q\":"
get_exit="Exiting program"
get_separator="------------------------------------------------"

# Files
fzsh="$HOME/.zshrc"  # Zsh config file
fbash="$HOME/.bashrc"  # Bash config file

# Functions

# Display message and read input
actions(){
 echo -e "$1"
 read "$2"
 echo "$get_separator"
}

# Check if file exists and writable, then append alias
check_sett_terminal(){
 if [[ -f $1 && -w $1 ]]; then
  echo -e "$2" >> "$1" && echo "$get_succesfull"
 else
  echo "$get_error"
 fi
}

# Main function to create alias
alias_formation(){
 # Get alias details
 actions "$get_alias" "set_alias"
 actions "$get_command" "set_command"
 actions "$get_comment" "set_comment"
 
 # Show generated alias
 echo "$get_result"
 set_result="\n# $set_comment \nalias $set_alias=\"$set_command\""
 echo -e "$get_separator \n$set_result \n$get_separator"

 # Confirm save
 actions "$get_actions" "set_actions"
 
 if [[ $set_actions = "n" ]]; then
  # Cancel - ask to start over or exit
  actions "$get_correct" "set_correct"

  if [[ $set_correct = "q" ]]; then
   echo "$get_exit"
  elif [[ $set_correct = "y" ]]; then
   alias_formation  # Start over
  else
   echo "$get_error"
  fi

 elif [[ $set_actions = "y" ]]; then
  # Save - select shell
  actions "$get_terminal" "set_terminal"

  if [[ $set_terminal -eq 1 ]]; then
   check_sett_terminal "$fbash" "$set_result"  # Save to bashrc
  elif [[ $set_terminal -eq 2 ]]; then
   check_sett_terminal "$fzsh" "$set_result"   # Save to zshrc
  else
   echo "$get_error"
  fi
 else
  echo "$get_error"
 fi
} 

# Start script
alias_formation
