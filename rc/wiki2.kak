declare-option -hidden str wiki_plugin_path %sh{ dirname "$kak_source" }


provide-module wiki %{
  require-module markdown-syntax

  declare-option -hidden str wiki_link_kind
  declare-option -hidden str wiki_link_path

  define-command wiki-next-link -docstring "navigate to the next wiki link" %{
    evaluate-commands -no-hooks -save-regs / %{
      set-register / "(%opt{wiki_anchor_regex}|%opt{wiki_link_regex})"
      execute-keys "n<a-;>ll"
    }
  }

  define-command wiki-prev-link -docstring "navigate to the previous wiki link" %{
    evaluate-commands -no-hooks -save-regs / %{
      set-register / "(%opt{wiki_anchor_regex}|%opt{wiki_link_regex})"
      execute-keys "<a-n><a-;>ll"
    }
  }

  define-command -hidden wiki-grab-link -docstring "set wiki_link_path to the value of this link, dereferencing if necessary" %{
    # detect whether the link is inline or reference, and get its path
    try %{
      evaluate-commands -draft %{
        # select the character immediately after the first ']' in a link: '(' or '['
        execute-keys <a-i>[ll
        execute-keys %sh{
          if [ "$kak_selection" = "(" ]; then
            printf "%s" "<a-i>("
            printf "%s" ": set-option buffer wiki_link_kind inline<ret>"
            printf "%s" ": set-option buffer wiki_link_path %val{selection}<ret>"
          elif [ "$kak_selection" = "[" ]; then
            printf "%s" "<a-i>["
            printf "%s" ": set-option buffer wiki_link_kind reference<ret>"
            printf "%s" ": set-option buffer wiki_link_path %val{selection}<ret>"
          else
            printf "%s" ": fail<ret>"
          fi
        }
      }
    } catch %{
      fail "invalid link"
    }

    # if the link is a reference, grab the link from the first line with [<id>]: <link>
    try %{
      execute-keys -draft %sh{
        if [ "$kak_opt_wiki_link_kind" = reference ]; then
          printf "%s" "/\Q[$kak_opt_wiki_link_path]: <ret>lGl"
          printf "%s" ": set-option buffer wiki_link_path %val{selection}<ret>"
        fi
      }
    }
  }

  define-command wiki-open-link -docstring "open the link in the default program" %{
    wiki-grab-link

    evaluate-commands %sh{
      # if link is likely a url, open it with xdg, and print any output in lower case
      case "$kak_opt_wiki_link_path" in
        http:* | https:*)
          printf "echo -markup {green}%s\n" "$(xdg-open "$kak_opt_wiki_link_path" | tr [:upper:] [:lower:])"
          exit 0
        ;;

        # if the path is absolute, do nothing. If it is relative, make it relative to the parent directory of buffile
        /*) true ;;
        *) kak_opt_wiki_link_path="$(dirname "$kak_buffile")/$kak_opt_wiki_link_path" ;;
      esac

      # if the file exists, open it with the default program. If that program is kakoune, edit it in a new buffer.
      if [ -f "$kak_opt_wiki_link_path" ]; then
        default_program=$(xdg-mime query default $(xdg-mime query filetype "$kak_opt_wiki_link_path"))

        if [ "$default_program" = kak.desktop ]; then
          printf "%s\n" "edit '$kak_opt_wiki_link_path'"
        else
          nohup xdg-open "$kak_opt_wiki_link_path" >/dev/null 2>&1 & disown
        fi

      # if the file does not exist, open it in kakoune only if it ends with *.md
      else
        case "$kak_opt_wiki_link_path" in
          *.md)
            mkdir -p "$(dirname "$kak_opt_wiki_link_path")"
            printf "%s\n" "edit '$kak_opt_wiki_link_path'"
            printf "%s\n" "echo -markup {green}created new file"
          ;;

          *) printf "%s\n" "fail 'link does not exist and doesn''t match *.md'" ;;
        esac
      fi
    }
  }

  define-command wiki-yank-link -docstring "yank and display the link's value" %{
    wiki-grab-link
    execute-keys -with-hooks ": edit -scratch<ret>i%opt{wiki_link_path}<esc>xHy:db<ret>"
    echo -markup "{green}%opt{wiki_link_path}"
  }

  define-command wiki-make-link -docstring "prompt for a url and create a link with the current selection" %{
    execute-keys %sh{
      if [ "${#kak_selection}" = 1 ]; then
        printf "%s" "<a-i><a-w><esc>"
      fi
    }

    prompt "url: " %{ execute-keys "i[<esc>a](%val{text})<esc>" }
  }
}


hook global WinSetOption filetype=markdown %{
  require-module wiki
}


# ────────────── buffer settings ──────────────
hook global BufSetOption filetype=markdown %{
  map buffer normal <tab>   ': wiki-next-link<ret>'
  map buffer normal <s-tab> ': wiki-prev-link<ret>'
  map buffer normal <ret>   ': wiki-open-link<ret>'
  map buffer normal +       ': wiki-yank-link<ret>'
  map buffer normal <c-k>   ': wiki-make-link<ret>'

  set-option buffer formatcmd "python3 %opt{wiki_plugin_path}/format.py --format"
}