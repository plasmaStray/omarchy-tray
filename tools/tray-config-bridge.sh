#!/usr/bin/env bash
set -euo pipefail

# The Omarchy 4 replacement-bar facade does not expose the bar drag writer.
# This narrow helper is invoked by the tray only for an explicit drag drop.
# It edits the user's shell.json under an advisory lock and replaces it
# atomically, preserving the original file mode.

action=${1:-}
tray_id=${2:-}
widget_id=${3:-}
arg4=${4:-}
arg5=${5:-}
config=${OMARCHY_SHELL_CONFIG:-"$HOME/.config/omarchy/shell.json"}

if [[ -z "$action" || -z "$tray_id" || -z "$widget_id" ]]; then
  echo "usage: $0 capture|restore tray-id widget-id [before-id|region] [region|before-id]" >&2
  exit 64
fi
[[ -f "$config" ]] || { echo "missing shell config: $config" >&2; exit 66; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 69; }

lock="${config}.lock"
exec 9>"$lock"
flock -x 9

tmp=$(mktemp "${config}.tmp.XXXXXX")
cleanup() { rm -f -- "$tmp"; }
trap cleanup EXIT

mode=$(stat -c '%a' -- "$config")

case "$action" in
  capture)
    before_id=$arg4
    jq --arg tray "$tray_id" --arg widget "$widget_id" --arg before "$before_id" '
      def eid: if type == "string" then . else (.id // "") end;
      ([.bar.layout[]?[]? | select(eid == $widget)] | first) as $source |
      if ($source == null) then error("source widget is not in bar layout")
      else
        ([.bar.layout[]?[]? | select(eid == $tray)] | first) as $tray_entry |
        if ($tray_entry == null) then error("tray is not in bar layout")
        else
          ([.plugins[]? | eid] | index($widget)) as $listed |
          .bar.layout |= with_entries(
            .value |= map(
              if eid == $widget then empty
              elif eid == $tray then
                . as $entry |
                ($entry.widgets // []) as $widgets |
                ($entry.order // [] | map(select(. != $widget))) as $clean_order |
                (if $before == "" or (($clean_order | index($before)) == null)
                 then ($clean_order + [$widget])
                 else ($clean_order | map(if . == $before then $widget, . else . end))
                 end) as $new_order |
                $entry + {widgets: ($widgets + [{entry: $source}]), order: $new_order}
              else . end
            )
          )
          | if $listed == null then .plugins = ((.plugins // []) + [{id: $widget}]) else . end
        end
      end
    ' "$config" > "$tmp"
    ;;
  restore)
    region=$arg4
    before_id=$arg5
    case "$region" in left|center|right) ;; *) echo "invalid region: $region" >&2; exit 64 ;; esac
    jq --arg tray "$tray_id" --arg widget "$widget_id" --arg region "$region" --arg before "$before_id" '
      def eid: if type == "string" then . else (.id // "") end;
      ([.bar.layout[]?[]? | select(eid == $tray) | .widgets[]? |
        select((.entry | eid) == $widget)] | first) as $wrapper |
      if ($wrapper == null) then error("widget is not hosted by tray")
      else
        .bar.layout |= with_entries(
          .value |= map(
            if eid == $tray then
              . as $entry |
              $entry + {widgets: (($entry.widgets // []) |
                map(select((.entry | eid) != $widget)))}
            else . end
          )
        )
        | .bar.layout[$region] = ((.bar.layout[$region] // []) |
            if $before == "" or (map(eid) | index($before)) == null
            then . + [$wrapper.entry]
            else map(if eid == $before then $wrapper.entry, . else . end)
            end)
        | .bar.layout |= with_entries(
            .value |= map(
              if eid == $tray then
                . + {order: ((.order // []) | map(select(. != $widget)))}
              else . end
            )
          )
      end
    ' "$config" > "$tmp"
    ;;
  *) echo "unknown action: $action" >&2; exit 64 ;;
esac

chmod "$mode" -- "$tmp"
mv -f -- "$tmp" "$config"
trap - EXIT
