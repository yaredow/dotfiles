-- autosub.lua
-- Fully automatic asynchronous subtitle search and downloader for MPV using Subliminal

local mp = require 'mp'
local utils = require 'mp.utils'
local opt = require 'mp.options'

-- Default options
local options = {
    subliminal_path = "/home/yada/.local/bin/subliminal",
    language = "en",              -- Primary language (ISO-639-1)
    language_alt = "eng",         -- 3-letter language code
    language_name = "English",
    auto_download = true,         -- Auto-download on video load
    force = false,                -- Force overwrite existing subs
    utf8 = true,                  -- Save as UTF-8
    min_duration = 120,           -- Skip videos under 2 minutes (120s)
    notify_duration = 3,          -- OSD notification duration in seconds
    debug = false,
}

opt.read_options(options, "autosub")

-- State tracking
local is_downloading = false

local function log_msg(msg, duration)
    duration = duration or options.notify_duration
    mp.msg.info(msg)
    mp.osd_message(msg, duration)
end

local function has_english_subtitle()
    local tracks = mp.get_property_native("track-list") or {}
    for _, track in ipairs(tracks) do
        if track["type"] == "sub" then
            local lang = track["lang"] or ""
            local title = (track["title"] or ""):lower()
            if lang == options.language or lang == options.language_alt or title:find("eng") or title:find("english") then
                return true, track["id"], track["selected"]
            end
        end
    end
    return false, nil, false
end

local function is_valid_media()
    local path = mp.get_property("path")
    if not path or path == "" then return false end

    -- Check if web stream / URL
    if path:find("^https?://") or path:find("^ytdl://") or path:find("^rtmp://") then
        return false
    end

    -- Check duration
    local duration = tonumber(mp.get_property("duration")) or 0
    if duration > 0 and duration < options.min_duration then
        return false
    end

    -- Check file format / audio only formats
    local file_format = mp.get_property("file-format") or ""
    local audio_formats = { mp3=true, flac=true, ogg=true, wav=true, m4a=true, opus=true, aac=true, ape=true }
    if audio_formats[file_format] then
        return false
    end

    return true
end

function download_subtitles(force_flag)
    if is_downloading then
        log_msg("Subtitle search already in progress...")
        return
    end

    local video_path = mp.get_property("path")
    if not video_path or video_path == "" then return end

    local dir, filename = utils.split_path(video_path)
    if not dir or not filename then return end

    -- Verify subliminal binary
    local subliminal = options.subliminal_path
    if subliminal == "" then
        subliminal = "subliminal"
    end

    local args = { subliminal, "download", "-l", options.language }

    if force_flag or options.force then
        table.insert(args, "-f")
    end

    if options.utf8 then
        table.insert(args, "-e")
        table.insert(args, "utf-8")
    end

    table.insert(args, "-d")
    table.insert(args, dir)
    table.insert(args, video_path)

    is_downloading = true
    log_msg("Searching " .. options.language_name .. " subtitles...")

    mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = args
    }, function(success, res, error)
        is_downloading = false
        if not success or res.status ~= 0 then
            mp.msg.warn("Subliminal failed with exit code: " .. tostring(res and res.status or error))
            if res and res.stderr and res.stderr ~= "" then
                mp.msg.warn("Subliminal stderr: " .. res.stderr)
            end
        end

        local stdout = (res and res.stdout) or ""
        if stdout:find("Downloaded 1 subtitle") or stdout:find("Downloaded") then
            -- Rescan directory to pick up newly downloaded subtitle
            mp.commandv("rescan_external_files", "reselect")
            mp.set_property("slang", options.language .. "," .. options.language_alt)
            log_msg("✓ " .. options.language_name .. " subtitles downloaded and loaded!")
        else
            log_msg("No " .. options.language_name .. " subtitles found")
        end
    end)
end

local function on_file_loaded()
    if not options.auto_download then return end
    if not is_valid_media() then return end

    -- Check if subtitles already present
    local has_sub, sub_id, is_selected = has_english_subtitle()
    if has_sub then
        if not is_selected and sub_id then
            mp.set_property("sid", sub_id)
        end
        mp.msg.info("English subtitle already available.")
        return
    end

    -- Trigger auto download
    mp.msg.info("No English subtitles found. Automatically downloading...")
    download_subtitles(false)
end

-- Key bindings
mp.add_key_binding("b", "download_subs", function()
    download_subtitles(false)
end)

mp.add_key_binding("B", "download_subs_force", function()
    download_subtitles(true)
end)

-- Event hook
mp.register_event("file-loaded", on_file_loaded)
