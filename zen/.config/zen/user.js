// Zen Browser User Preferences - Ported from nixos-config/modules/features/zen.nix

// Hardware video decoding via VA-API on Wayland (Intel Iris Xe)
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.force-enabled", true);
user_pref("gfx.webrender.all", true);
user_pref("gfx.webrender.compositor.force-enabled", true);
user_pref("layers.gpu-process.enabled", true);

// Wayland portal integration
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);
user_pref("widget.use-xdg-desktop-portal.mime-handler", 1);
user_pref("widget.wayland.opaque-region.enabled", true);

// Natural trackpad kinetic scrolling
user_pref("general.smoothScroll.msdPhysics.enabled", true);
user_pref("apz.overscroll.enabled", true);

// WebRTC PipeWire support
user_pref("media.webrtc.hw.h264.enabled", true);
user_pref("zen.view.compact.hide-toolbar", false);

// Privacy & Tracking Protection
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("experiments.activeExperiment", false);
user_pref("experiments.supported", false);
user_pref("network.allow-experiments", false);
user_pref("extensions.pocket.enabled", false);
user_pref("app.update.auto", false);
