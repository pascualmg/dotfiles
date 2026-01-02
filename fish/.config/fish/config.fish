if status is-interactive
 # Terminal type for byobu/tmux compatibility
 if not set -q TERM; or test "$TERM" = "dumb"
  set -x TERM xterm-256color
 end

 set -x PATH /home/passh/.config/emacs/bin $PATH
 set -x PATH /home/passh/node_modules/.bin $PATH
 set -x PATH /home/passh/.local/bin $PATH
end
