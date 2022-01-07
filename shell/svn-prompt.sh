# bash/zsh svn prompt support
parse_svn_url() {
  svn info 2>/dev/null | sed -ne 's#^URL: ##p'
}

parse_svn_repository_root() {
  svn info 2>/dev/null | sed -ne 's#^Repository Root: ##p'
}

__svn_ps1() {
  parse_svn_url | sed -e 's#^'"$(parse_svn_repository_root)/"'##g' | awk '{print " ("$1")" }'
}
