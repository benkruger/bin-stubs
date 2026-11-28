#!/usr/bin/env bash

workspace_member() {
  local d="${1%/}" parent
  [ -f "$d/Cargo.toml" ] && [ -f "$d/../Cargo.toml" ] || return 1
  parent="$(cd "$d/.." && pwd)"
  perl -MCwd=abs_path -e '
    my ($root, $name) = @ARGV;
    $root = abs_path($root);
    sub manifest {
      open my $fh, "<", "$_[0]/Cargo.toml" or return "";
      local $/;
      my $text = <$fh>;
      return defined $text ? $text : "";
    }
    my $text = manifest($root);
    $text =~ /^\[workspace\][ \t]*$/m or exit 1;
    my ($table) = $text =~ /^\[workspace\][ \t]*\n(.*?)(?=^\[|\z)/ms;
    $table = "" unless defined $table;
    my %list;
    for my $key (qw(members exclude)) {
      my ($items) = $table =~ /^[ \t]*\Q$key\E[ \t]*=[ \t]*\[(.*?)\]/ms;
      $list{$key} = [defined $items ? $items =~ /["\x27]([^"\x27]*)["\x27]/g : ()];
    }
    my $matches = sub {
      my ($path, $glob) = @_;
      $glob =~ s{\A\./|/+\z}{}g;
      (my $re = quotemeta $glob) =~ s/\\\*/[^\/]*/g;
      $re =~ s/\\\?/[^\/]/g;
      return $path =~ /\A$re\z/;
    };
    my $excluded = sub { my $p = shift; grep { $matches->($p, $_) } @{ $list{exclude} } };
    exit 1 if $excluded->($name);
    exit 0 if grep { $matches->($name, $_) } @{ $list{members} };
    my @queue = $text =~ /^\[package\][ \t]*$/m ? (".") : ();
    for my $glob (@{ $list{members} }) {
      for my $dir (glob("$root/$glob")) {
        push @queue, substr($dir, length("$root/")) if -f "$dir/Cargo.toml";
      }
    }
    my %seen = map { $_ => 1 } @queue;
    while (defined(my $dir = shift @queue)) {
      for my $path (manifest("$root/$dir") =~ /\bpath[ \t]*=[ \t]*["\x27]([^"\x27]+)["\x27]/g) {
        my $real = abs_path("$root/$dir/$path");
        next unless defined $real && -f "$real/Cargo.toml" && index($real, "$root/") == 0;
        my $rel = substr($real, length("$root/"));
        next if $seen{$rel}++ || $excluded->($rel);
        exit 0 if $rel eq $name;
        push @queue, $rel;
      }
    }
    exit 1;
  ' "$parent" "${d##*/}"
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
