define-command markdown-syntax %{
  add-highlighter -override shared/markdown regions

  add-highlighter shared/markdown/inline default-region regions
  add-highlighter shared/markdown/inline/text default-region group

  # code fences
  evaluate-commands %sh{
    languages="
      awk c cabal clojure coffee cpp css cucumber d diff dockerfile fish
      gas go haml haskell html ini java javascript json julia kak kickstart
      latex lisp lua makefile markdown moon objc perl pug python ragel
      ruby rust sass scala scss sh swift toml tupfile typescript yaml sql
    "
    for lang in ${languages}; do
      printf 'add-highlighter shared/markdown/%s region -match-capture ^(\h*)```\h*(%s|\{=%s\}))\\b ^(\h*)``` regions\n' "${lang}" "${lang}" "${lang}"
      printf 'add-highlighter shared/markdown/%s/ default-region fill meta\n' "${lang}"
      [ "${lang}" = kak ] && ref=kakrc || ref="${lang}"
      printf 'add-highlighter shared/markdown/%s/inner region ```\h*(%s|\{=%s\})\\b\K (?=```) ref %s\n' "${lang}" "${lang}" "${lang}" "${ref}"
    done
  }

  add-highlighter shared/markdown/codeblock region -match-capture \
      ^(\h*)```\h* \
      ^(\h*)```\h*$ \
      fill meta

  # header style variations
  add-highlighter shared/markdown/inline/text/ regex ^(#)\h*([^#\n]*) 1:comment 2:rgb:d33682+bu
  add-highlighter shared/markdown/inline/text/ regex ^(##)\h*([^#\n]*) 1:comment 2:rgb:d33682+b
  add-highlighter shared/markdown/inline/text/ regex ^(###[#]*)\h*([^#\n]*) 1:comment 2:rgb:d33682

  # lists
  add-highlighter shared/markdown/inline/text/unordered-list regex ^\h*([-+*])\s 1:bullet
  add-highlighter shared/markdown/inline/text/ordered-list   regex ^\h*(\d+[.)])\s 1:bullet

  # fix _ * highlighters
  add-highlighter shared/markdown/inline/code region ` ` fill meta
  add-highlighter shared/markdown/inline/emphasis region -match-capture -recurse (?:^|(?<=\s))([_*])[^_*\s] (?:^|(?<=\s))([_*])[^_*\s] [^_*\s]([_*])(?:(?=\s)|$) fill red

  # add-highlighter shared/markdown/inline/code region __ __ fill meta
  # add-highlighter shared/markdown/inline/code region * * fill meta
  # add-highlighter shared/markdown/inline/code region ** ** fill meta

  # remove-highlighter shared/markdown/inline/text/regex_^\[[^\]\n]*\]:\h*([^\n]*)_1:link
  # remove-highlighter shared/markdown/inline/text/regex_(?<!\*)(\*([^\s*]|([^\s*](\n?[^\n*])*[^\s*]))\*)(?!\*)_1:italic
  # remove-highlighter shared/markdown/inline/text/regex_(?<!_)(_([^\s_]|([^\s_](\n?[^\n_])*[^\s_]))_)(?!_)_1:italic
  # remove-highlighter shared/markdown/inline/text/regex_(?<!\*)(\*\*([^\s*]|([^\s*](\n?[^\n*])*[^\s*]))\*\*)(?!\*)_1:bold
  # remove-highlighter shared/markdown/inline/text/regex_(?<!_)(__([^\s_]|([^\s_](\n?[^\n_])*[^\s_]))__)(?!_)_1:bold

  # add-highlighter shared/markdown/inline/text/ regex \s(?<!\*)(\*([^\s*]|([^\s*](\n?[^\n*])*[^\s*]))\*)(?!\*)\s 1:italic
  # add-highlighter shared/markdown/inline/text/ regex \s(?<!_)(_([^\s_]|([^\s_](\n?[^\n_])*[^\s_]))_)(?!_)\s 1:italic
  # add-highlighter shared/markdown/inline/text/ regex \s(?<!\*)(\*\*([^\s*]|([^\s*](\n?[^\n*])*[^\s*]))\*\*)(?!\*)\s 1:bold
  # add-highlighter shared/markdown/inline/text/ regex \s(?<!_)(__([^\s_]|([^\s_](\n?[^\n_])*[^\s_]))__)(?!_)\s 1:bold

  # # block quotes
  # add-highlighter shared/markdown/inline/text/ regex ^\h*(>[^\n]*)+ 0:comment

  # # listblock marker fix for links immediately following a list bullet
  # # remove-highlighter shared/markdown/listblock/marker
  # # add-highlighter shared/markdown/listblock/marker region \A [-*] fill bullet

  # # matches [hello](link) and [hello][ref] links
  # add-highlighter shared/markdown/inline/text/link regex \
  #   %opt{markdown_link_regex} 1:comment 2:link 3:comment

  # # matches [hello] style anchors
  # add-highlighter shared/markdown/inline/text/anchor regex \
  #   %opt{markdown_anchor_regex} 1:comment 2:value

  # # matches reference links
  # add-highlighter shared/markdown/inline/text/ regex \
  #   %opt{markdown_reference_link_regex} 0:comment

}