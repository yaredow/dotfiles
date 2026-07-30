# Qutebrowser theme — generated from active theme

def apply(c):
    # =============================================================================
    # Fonts — from theme
    # =============================================================================

    c.fonts.default_family = ["{{font_mono}}"]
    c.fonts.default_size = "{{font_size}}pt"
    c.fonts.completion.entry = "{{font_size}}pt {{font_mono}}"
    c.fonts.completion.category = "bold {{font_size}}pt {{font_mono}}"
    c.fonts.contextmenu = "{{font_size}}pt {{font_mono}}"
    c.fonts.statusbar = "{{font_size}}pt {{font_mono}}"
    c.fonts.tabs.selected = "{{font_size}}pt {{font_mono}}"
    c.fonts.tabs.unselected = "{{font_size}}pt {{font_mono}}"
    c.fonts.hints = "bold {{font_size}}pt {{font_mono}}"
    c.fonts.keyhint = "{{font_size}}pt {{font_mono}}"
    c.fonts.messages.error = "{{font_size}}pt {{font_mono}}"
    c.fonts.messages.info = "{{font_size}}pt {{font_mono}}"
    c.fonts.messages.warning = "{{font_size}}pt {{font_mono}}"
    c.fonts.prompts = "{{font_size}}pt {{font_mono}}"
    c.fonts.downloads = "{{font_size}}pt {{font_mono}}"
    c.fonts.debug_console = "{{font_size}}pt {{font_mono}}"
    c.fonts.tooltip = "{{font_size}}pt {{font_mono}}"

    # =============================================================================
    # Completion menu
    # =============================================================================

    c.colors.completion.fg = "{{text}}"
    c.colors.completion.odd.bg = "{{crust}}"
    c.colors.completion.even.bg = "{{base}}"
    c.colors.completion.category.fg = "{{blue}}"
    c.colors.completion.category.bg = "{{crust}}"
    c.colors.completion.category.border.top = "{{crust}}"
    c.colors.completion.category.border.bottom = "{{crust}}"
    c.colors.completion.item.selected.fg = "{{text}}"
    c.colors.completion.item.selected.bg = "{{surface0}}"
    c.colors.completion.item.selected.border.top = "{{surface0}}"
    c.colors.completion.item.selected.border.bottom = "{{surface0}}"
    c.colors.completion.item.selected.match.fg = "{{peach}}"
    c.colors.completion.match.fg = "{{peach}}"
    c.colors.completion.scrollbar.fg = "{{surface1}}"
    c.colors.completion.scrollbar.bg = "{{crust}}"

    # =============================================================================
    # Context menu
    # =============================================================================

    c.colors.contextmenu.disabled.bg = "{{crust}}"
    c.colors.contextmenu.disabled.fg = "{{overlay1}}"
    c.colors.contextmenu.menu.bg = "{{mantle}}"
    c.colors.contextmenu.menu.fg = "{{text}}"
    c.colors.contextmenu.selected.bg = "{{surface0}}"
    c.colors.contextmenu.selected.fg = "{{text}}"

    # =============================================================================
    # Statusbar
    # =============================================================================

    c.colors.statusbar.normal.bg = "{{base}}"
    c.colors.statusbar.normal.fg = "{{text}}"
    c.colors.statusbar.insert.bg = "{{base}}"
    c.colors.statusbar.insert.fg = "{{green}}"
    c.colors.statusbar.passthrough.bg = "{{base}}"
    c.colors.statusbar.passthrough.fg = "{{blue}}"
    c.colors.statusbar.private.bg = "{{base}}"
    c.colors.statusbar.private.fg = "{{blue}}"
    c.colors.statusbar.command.bg = "{{base}}"
    c.colors.statusbar.command.fg = "{{blue}}"
    c.colors.statusbar.command.private.bg = "{{base}}"
    c.colors.statusbar.command.private.fg = "{{blue}}"
    c.colors.statusbar.caret.bg = "{{blue}}"
    c.colors.statusbar.caret.fg = "{{base}}"
    c.colors.statusbar.caret.selection.bg = "{{blue}}"
    c.colors.statusbar.caret.selection.fg = "{{base}}"
    c.colors.statusbar.progress.bg = "{{surface0}}"
    c.colors.statusbar.url.fg = "{{text}}"
    c.colors.statusbar.url.error.fg = "{{red}}"
    c.colors.statusbar.url.hover.fg = "{{teal}}"
    c.colors.statusbar.url.success.http.fg = "{{peach}}"
    c.colors.statusbar.url.success.https.fg = "{{green}}"
    c.colors.statusbar.url.warn.fg = "{{yellow}}"

    # =============================================================================
    # Tabs
    # =============================================================================

    c.colors.tabs.bar.bg = "{{base}}"
    c.colors.tabs.indicator.start = "{{blue}}"
    c.colors.tabs.indicator.stop = "{{blue}}"
    c.colors.tabs.indicator.error = "{{red}}"
    c.colors.tabs.odd.fg = "{{overlay0}}"
    c.colors.tabs.odd.bg = "{{surface0}}"
    c.colors.tabs.even.fg = "{{overlay0}}"
    c.colors.tabs.even.bg = "{{surface0}}"
    c.colors.tabs.pinned.even.bg = "{{surface0}}"
    c.colors.tabs.pinned.even.fg = "{{overlay0}}"
    c.colors.tabs.pinned.odd.bg = "{{surface0}}"
    c.colors.tabs.pinned.odd.fg = "{{overlay0}}"
    c.colors.tabs.pinned.selected.even.fg = "{{base}}"
    c.colors.tabs.pinned.selected.even.bg = "{{blue}}"
    c.colors.tabs.pinned.selected.odd.fg = "{{base}}"
    c.colors.tabs.pinned.selected.odd.bg = "{{blue}}"
    c.colors.tabs.selected.odd.fg = "{{base}}"
    c.colors.tabs.selected.odd.bg = "{{blue}}"
    c.colors.tabs.selected.even.fg = "{{base}}"
    c.colors.tabs.selected.even.bg = "{{blue}}"

    # =============================================================================
    # Messages (info/error/warning)
    # =============================================================================

    c.colors.messages.error.bg = "{{base}}"
    c.colors.messages.error.fg = "{{red}}"
    c.colors.messages.error.border = "{{red}}"
    c.colors.messages.warning.bg = "{{base}}"
    c.colors.messages.warning.fg = "{{yellow}}"
    c.colors.messages.warning.border = "{{yellow}}"
    c.colors.messages.info.bg = "{{base}}"
    c.colors.messages.info.fg = "{{blue}}"
    c.colors.messages.info.border = "{{blue}}"

    # =============================================================================
    # Prompts
    # =============================================================================

    c.colors.prompts.bg = "{{mantle}}"
    c.colors.prompts.fg = "{{text}}"
    c.colors.prompts.border = "{{teal}}"
    c.colors.prompts.selected.bg = "{{surface0}}"
    c.colors.prompts.selected.fg = "{{text}}"

    # =============================================================================
    # Hints (link hints — f, F)
    # =============================================================================

    c.colors.hints.bg = "{{yellow}}"
    c.colors.hints.fg = "{{base}}"
    c.colors.hints.match.fg = "{{green}}"
    c.colors.keyhint.bg = "{{mantle}}"
    c.colors.keyhint.fg = "{{text}}"
    c.colors.keyhint.suffix.fg = "{{yellow}}"

    # =============================================================================
    # Downloads
    # =============================================================================

    c.colors.downloads.bar.bg = "{{mantle}}"
    c.colors.downloads.start.fg = "{{base}}"
    c.colors.downloads.start.bg = "{{blue}}"
    c.colors.downloads.stop.bg = "{{green}}"
    c.colors.downloads.stop.fg = "{{base}}"
    c.colors.downloads.error.bg = "{{red}}"
    c.colors.downloads.error.fg = "{{base}}"

    # =============================================================================
    # Tooltips
    # =============================================================================

    c.colors.tooltip.bg = "{{mantle}}"
    c.colors.tooltip.fg = "{{text}}"

    # =============================================================================
    # Web page dark mode
    # =============================================================================

    c.colors.webpage.bg = "{{base}}"
    c.colors.webpage.preferred_color_scheme = "dark"
    c.colors.webpage.darkmode.enabled = True
    c.colors.webpage.darkmode.algorithm = "lightness-cielab"
    c.colors.webpage.darkmode.policy.images = "never"
