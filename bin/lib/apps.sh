#!/usr/bin/env bash

workspace_member() {
  local d="${1%/}" parent
  [ -f "$d/Cargo.toml" ] && [ -f "$d/../Cargo.toml" ] || return 1
  parent="$(cd "$d/.." && pwd)"
  perl -e '
    my ($file, $name) = @ARGV;
    open my $fh, "<", $file or exit 1;
    my $text = do { local $/; <$fh> };
    my ($table) = $text =~ /^\[workspace\][ \t]*\n(.*?)(?=^\[|\z)/ms or exit 1;
    my %list;
    for my $key (qw(members exclude)) {
      my ($items) = $table =~ /^[ \t]*\Q$key\E[ \t]*=[ \t]*\[(.*?)\]/ms;
      $list{$key} = [defined $items ? $items =~ /["\x27]([^"\x27]*)["\x27]/g : ()];
    }
    my $matches = sub {
      (my $glob = shift) =~ s{\A\./|/+\z}{}g;
      (my $re = quotemeta $glob) =~ s/\\\*/[^\/]*/g;
      $re =~ s/\\\?/[^\/]/g;
      return $name =~ /\A$re\z/;
    };
    exit 1 if grep { $matches->($_) } @{ $list{exclude} };
    exit((grep { $matches->($_) } @{ $list{members} }) ? 0 : 1);
  ' "$parent/Cargo.toml" "${d##*/}"
}

is_app_dir() {
  local d="$1" x
  ! workspace_member "$d" || return 1
  [ -f "$d/package.json" ] && return 0
  [ -f "$d/Gemfile" ] && return 0
  [ -f "$d/pyproject.toml" ] && return 0
  [ -f "$d/Cargo.toml" ] && return 0
  [ -f "$d/Package.swift" ] && return 0
  for x in "$d"/*.xcodeproj "$d"/*.xcworkspace; do
    [ -e "$x" ] && return 0
  done
  [ -x "$d/test/run" ] && return 0
  return 1
}

app_language() {
  local d="$1" x
  ! workspace_member "$d" || return 1
  for x in "$d"/Package.swift "$d"/*.xcodeproj "$d"/*.xcworkspace; do
    if [ -e "$x" ]; then
      echo ios
      return 0
    fi
  done
  if [ -f "$d/Gemfile" ]; then
    echo rails
  elif [ -f "$d/Cargo.toml" ]; then
    echo rust
  elif [ -f "$d/pyproject.toml" ]; then
    echo python
  elif [ -f "$d/package.json" ] && [ -f "$d/tsconfig.json" ]; then
    echo typescript
  elif [ -f "$d/package.json" ]; then
    echo javascript
  elif [ -x "$d/test/run" ]; then
    echo shell
  else
    return 1
  fi
}
