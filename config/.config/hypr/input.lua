hl.config({
	input = {
		kb_layout = "pt",
		kb_options = "caps:lock",

		repeat_rate = 40,
		repeat_delay = 600,

		numlock_by_default = true,

		sensitivity = 0.25,

		touchpad = {
			natural_scroll = true,
			scroll_factor = 1,
		},
	},
})

o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
