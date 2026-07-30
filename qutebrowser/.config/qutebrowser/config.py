# pylint: disable=C0111
# Qutebrowser config — loaded from dotfiles

# Load autoconfig FIRST (settings changed via :set / :bind)
config.load_autoconfig()

# Load generated theme (rendered by theme-set.sh from theme template)
import theme
theme.apply(c)

# Disable dark mode for local file:// pages
config.set("colors.webpage.darkmode.enabled", False, "file://*")

# =============================================================================
# General
# =============================================================================

c.window.hide_decoration = True
c.window.title_format = "{perc}{current_title}"

# =============================================================================
# Tabs
# =============================================================================

c.tabs.position = "top"
c.tabs.show = "always"
c.tabs.tabs_are_windows = False
c.tabs.last_close = "ignore"

# =============================================================================
# URL / Start page / New tab
# =============================================================================

c.url.start_pages = ["https://duckduckgo.com"]
c.url.default_page = "about:blank"
c.url.searchengines = {
    "DEFAULT": "https://duckduckgo.com/?q={}",
    "g": "https://www.google.com/search?q={}",
    "yt": "https://www.youtube.com/results?search_query={}",
    "gh": "https://github.com/search?q={}",
    "w": "https://en.wikipedia.org/wiki/Special:Search?search={}",
    "r": "https://www.reddit.com/search/?q={}",
    "aur": "https://aur.archlinux.org/packages/?K={}",
    "wiki": "https://wiki.archlinux.org/index.php?search={}",
    "mdn": "https://developer.mozilla.org/en-US/search?q={}",
}
c.url.auto_search = "naive"
c.url.open_base_url = False

# =============================================================================
# Content / Privacy / Blocking
# =============================================================================

c.content.blocking.method = "both"
c.content.blocking.adblock.lists = [
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/quick-fixes.txt",
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
]
c.content.blocking.hosts.lists = [
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
]
c.content.blocking.whitelist = []
c.content.javascript.enabled = True
c.content.javascript.clipboard = "ask"
c.content.geolocation = False
c.content.cookies.accept = "no-3rdparty"
c.content.local_storage = True
c.content.cache.maximum_pages = 0
c.content.cache.size = 0
c.content.dns_prefetch = True
c.content.prefers_reduced_motion = True
c.content.webgl = True
c.content.canvas_reading = True
c.content.webrtc_ip_handling_policy = "default-public-interface-only"
c.content.mute = False
c.content.pdfjs = True

# =============================================================================
# Statusbar
# =============================================================================

c.statusbar.show = "always"
c.statusbar.padding = {"top": 2, "bottom": 2, "left": 4, "right": 4}
c.statusbar.widgets = [
    "url",
    "scroll",
    "progress",
    "tabs",
    "clock:HH:mm",
]

# =============================================================================
# Completion
# =============================================================================

c.completion.shrink = True
c.completion.quick = True
c.completion.delay = 0
c.completion.show = "always"
c.completion.height = "50%"
c.completion.scrollbar.width = 8
c.completion.scrollbar.padding = 2
c.completion.open_categories = ["searchengines", "quickmarks", "bookmarks", "history", "filesystem"]

# =============================================================================
# Hints
# =============================================================================

c.hints.chars = "asdfghjkl"
c.hints.min_chars = 1
c.hints.uppercase = False
c.hints.scatter = True
c.hints.leave_on_load = True
c.hints.auto_follow = "always"
c.hints.mode = "letter"
c.hints.next_regexes.append(r"\bnext\b")
c.hints.prev_regexes.append(r"\b(prev|previous)\b")

# =============================================================================
# Downloads
# =============================================================================

c.downloads.location.directory = "~/Downloads"
c.downloads.location.suggestion = "filename"
c.downloads.position = "bottom"
c.downloads.remove_finished = 5000
c.downloads.open_dispatcher = "firefox"
c.downloads.prevent_mixed_content = True

# =============================================================================
# Sessions
# =============================================================================

c.session.lazy_restore = True
c.auto_save.session = True

# =============================================================================
# Misc
# =============================================================================

c.messages.timeout = 5000
c.prompt.filebrowser = True
c.prompt.radius = 8
c.input.insert_mode.auto_enter = True
c.input.insert_mode.auto_leave = True
c.input.forward_unbound_keys = "auto"
c.input.mouse.rocker_gestures = False
c.spellcheck.languages = ["en-US"]
c.auto_save.interval = 30
c.scrolling.smooth = True
c.zoom.default = "100%"
c.zoom.levels = ["25%", "33%", "50%", "67%", "75%", "80%", "90%", "100%", "110%", "125%", "150%", "175%", "200%", "250%", "300%", "400%", "500%"]

# =============================================================================
# Keybindings
# =============================================================================

# Navigate
config.bind("gh", "history")
config.unbind("d")

# Open clipboard
config.bind("pt", "open -t -- {clipboard}")

# Command mode navigation (Ctrl+J/K to move up/down in completion)
config.bind("<Ctrl-J>", "completion-item-focus next", mode="command")
config.bind("<Ctrl-K>", "completion-item-focus prev", mode="command")

# Toggle UI
config.bind("tH", "config-cycle tabs.show multiple never")
config.bind("sH", "config-cycle statusbar.show always never")

