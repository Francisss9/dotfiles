-- Tmux launcher
o.bind("SUPER + ALT + RETURN", "Tmux", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" tmux new')
hl.bind("SUPER + E", hl.dsp.exec_cmd("emacsclient -c -a ''"))
-- Power profiles menu
o.bind("SUPER + ALT + B", "Power profiles", "omarchy-menu power")

-- Music controller
o.bind("SUPER + PERIOD", "Play/Pause", "omarchy-swayosd-client --playerctl play-pause")
hl.unbind("SUPER + ALT + RIGHT")
hl.unbind("SUPER + ALT + LEFT")
o.bind("SUPER + ALT + RIGHT", "Next track", "omarchy-swayosd-client --playerctl next")
o.bind("SUPER + ALT + LEFT", "Previous track", "omarchy-swayosd-client --playerctl previous")

-- Webapps (override defaults that collide on the same key)
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "ChatGPT", 'omarchy-launch-webapp "https://chatgpt.com"')

o.bind(
	"SUPER + SHIFT + T",
	"TradingView",
	'omarchy-launch-webapp "https://www.tradingview.com/chart/IRfNHvdF/?symbol=FOREXCOM%3ANAS100"'
)
o.bind("SUPER + SHIFT + ALT + C", "Claude AI", 'omarchy-launch-webapp "https://claude.ai/projects"')

hl.unbind("SUPER + SHIFT + D")
o.bind("SUPER + SHIFT + D", "Discord", 'omarchy-launch-webapp "https://discord.com/channels/@me"')

hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "GitHub", 'omarchy-launch-webapp "https://github.com/"')

hl.unbind("SUPER + SHIFT + N")
o.bind(
	"SUPER + SHIFT + N",
	"Notion",
	'omarchy-launch-webapp "https://www.notion.so/WorkStation-208f09cb5ebe800c8a44ec038098c8a0"'
)

hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "Whatsapp", 'omarchy-launch-webapp "https://web.whatsapp.com/"')

o.bind("SUPER + SHIFT + Y", "Youtube", 'omarchy-launch-webapp "https://www.youtube.com"')
