#![enable(implicit_some)]
#![enable(unwrap_newtypes)]
#![enable(unwrap_variant_newtypes)]
(
    default_album_art_path: None,
    draw_borders: false,
    show_song_table_header: false,
    symbols: (song: "🎵", dir: "📁", playlist: "🎼", marker: "\u{e0b0}"),
    layout: Split(
        direction: Vertical,
        panes: [
            (pane: Pane(Header), size: "1"),
            (pane: Pane(TabContent), size: "100%"),
            (pane: Pane(ProgressBar), size: "1"),
        ],
    ),
    progress_bar: (
        symbols: ["", "", "⭘", " ", " "],
        track_style: (bg: "{{crust}}"),
        elapsed_style: (fg: "{{blue}}", bg: "{{crust}}"),
        thumb_style: (fg: "{{blue}}", bg: "{{crust}}"),
    ),
    scrollbar: (
        symbols: ["│", "█", "▲", "▼"],
        track_style: (),
        ends_style: (),
        thumb_style: (fg: "{{blue}}"),
    ),
    browser_column_widths: [20, 38, 42],
    text_color: "{{text}}",
    background_color: "{{base}}",
    header_background_color: "{{crust}}",
    modal_background_color: None,
    modal_backdrop: false,
    tab_bar: (active_style: (fg: "{{base}}", bg: "{{blue}}", modifiers: "Bold"), inactive_style: ()),
    borders_style: (fg: "{{surface1}}"),
    highlighted_item_style: (fg: "{{blue}}", modifiers: "Bold"),
    current_item_style: (fg: "{{base}}", bg: "{{mauve}}", modifiers: "Bold"),
    highlight_border_style: (fg: "{{mauve}}"),
    song_table_format: [
        (prop: (kind: Property(Artist), style: (fg: "{{mauve}}"), default: (kind: Text("Unknown"))), width: "50%", alignment: Right),
        (prop: (kind: Text("-"), style: (fg: "{{mauve}}"), default: (kind: Text("Unknown"))), width: "1", alignment: Center),
        (prop: (kind: Property(Title), style: (fg: "{{sky}}"), default: (kind: Text("Unknown"))), width: "50%"),
    ],
    header: (
        rows: [(
            left: [(kind: Text("["), style: (fg: "{{mauve}}", modifiers: "Bold")), (kind: Property(Status(State)), style: (fg: "{{mauve}}", modifiers: "Bold")), (kind: Text("]"), style: (fg: "{{mauve}}", modifiers: "Bold"))],
            center: [(kind: Property(Song(Artist)), style: (fg: "{{yellow}}", modifiers: "Bold"), default: (kind: Text("Unknown"), style: (fg: "{{yellow}}", modifiers: "Bold"))), (kind: Text(" - ")), (kind: Property(Song(Title)), style: (fg: "{{sky}}", modifiers: "Bold"), default: (kind: Text("No Song"), style: (fg: "{{sky}}", modifiers: "Bold")))],
            right: [(kind: Text("Vol: "), style: (fg: "{{mauve}}", modifiers: "Bold")), (kind: Property(Status(Volume)), style: (fg: "{{mauve}}", modifiers: "Bold")), (kind: Text("% "), style: (fg: "{{mauve}}", modifiers: "Bold"))]
        )],
    ),
)
