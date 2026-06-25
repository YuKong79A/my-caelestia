hl.monitor({
  output = "eDP-1",
  mode = "2560x1440@165.003",
  position = "0x0",
  scale = 1,
})

hl.bind("SUPER + ALT + E", hl.dsp.global("caelestia:emoji"))
hl.bind("SUPER + W", hl.dsp.global("caelestia:windowSwitcher"))
hl.bind("SUPER + K", hl.dsp.global("caelestia:keybinds"))
hl.bind("SUPER + ALT + W", hl.dsp.global("caelestia:wallpaper"))
hl.bind("SUPER + F10", hl.dsp.exec_cmd("caelestia wallpaper -r"))
hl.bind("SUPER + SHIFT + F10", hl.dsp.exec_cmd("/home/yukong/.local/bin/random-anime-wallpaper-noctalia"))
hl.bind("SUPER + F11", hl.dsp.exec_cmd("/home/yukong/.local/bin/random-konachan-nsfw-lite-wallpaper-caelestia"))
hl.bind("SUPER + SHIFT + F11", hl.dsp.exec_cmd("/home/yukong/.local/bin/random-konachan-wallpaper-caelestia"))
hl.bind("SUPER + F12", hl.dsp.exec_cmd("/home/yukong/.local/bin/random-yandere-sfw-wallpaper-caelestia"))
hl.bind("SUPER + SHIFT + F12", hl.dsp.exec_cmd("/home/yukong/.local/bin/random-yandere-nsfw-wallpaper-caelestia"))
