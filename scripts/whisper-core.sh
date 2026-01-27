#!/usr/bin/env bash
# ==============================================================================
# whisper-core.sh - Shared functions for voice input scripts
# ==============================================================================
# Common functions for voice-input-toggle and meeting-recorder-toggle
#
# Features:
#   - Microphone detection (RØDE NT-USB Mini)
#   - Audio recording wrapper (ffmpeg)
#   - Whisper transcription wrapper
#   - Utility functions (duration formatting, validation)
#
# Usage:
#   source ~/dotfiles/scripts/whisper-core.sh
#   INPUT=$(detect_microphone)
#   FFMPEG_PID=$(record_audio "/tmp/audio.wav")
#   TRANSCRIPT=$(transcribe_audio "/tmp/audio.wav" "es")
# ==============================================================================

MODEL="$HOME/.local/share/whisper/models/ggml-small.bin"

# Check if Whisper model exists
# Returns: 0 if exists, 1 if missing (shows notification)
check_model() {
	if [ ! -f "$MODEL" ]; then
		dunstify -u critical "Whisper Model Missing" \
			"Download: curl -LO https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
		return 1
	fi
	return 0
}

# Auto-detect RØDE NT-USB Mini microphone
# Returns: PulseAudio source name (or @DEFAULT_SOURCE@ if not found)
detect_microphone() {
	local rode_source

	# Look for RØDE NT-USB (handles R__DE encoding)
	rode_source=$(pactl list sources short |
		grep "alsa_input" |
		grep -i "NT-USB" |
		awk '{print $2}' |
		head -1)

	# Return RØDE if found, otherwise default
	echo "${rode_source:-@DEFAULT_SOURCE@}"
}

# Record audio from microphone (runs in background)
# Args:
#   $1 - output file path (e.g., /tmp/audio.wav)
# Returns: ffmpeg PID (use to monitor/kill process)
# Format: 16kHz mono WAV (optimal for Whisper)
record_audio() {
	local output_file="$1"
	local input_source

	# Detect microphone
	input_source=$(detect_microphone)

	# Start recording in background
	ffmpeg -f pulse -i "$input_source" \
		-ar 16000 \
		-ac 1 \
		-acodec pcm_s16le \
		"$output_file" &>/dev/null &

	# Return ffmpeg PID
	echo $!
}

# Record audio from microphone + system output (meetings, calls)
# Args:
#   $1 - output file path (e.g., /tmp/audio.wav)
#   $2 - PID file path (where to save the ffmpeg PID)
# Returns: nothing (PID saved to file)
# Format: 16kHz mono WAV (optimal for Whisper)
# Captures: Your voice (mic) + what you hear (speakers/headphones)
#
# BRUTAL SIMPLIFICATION: Use defaults, save PID to file
record_audio_full() {
	local output_file="$1"
	local pid_file="$2"

	# BRUTAL: Use @DEFAULT_SOURCE@ and @DEFAULT_MONITOR@
	# Audio quality improvements:
	#   - Monitor (system audio) boosted 8x: volume=8.0
	#   - Mic kept at 1x (natural level)
	#   - Mixed with weights favoring monitor (1:2)
	#   - Dynamic normalization to balance peaks
	#   - Final volume boost 3x
	ffmpeg -f pulse -i @DEFAULT_SOURCE@ \
		-f pulse -i @DEFAULT_MONITOR@ \
		-filter_complex "\
			[0:a]volume=1.0[mic];\
			[1:a]volume=8.0[monitor];\
			[mic][monitor]amix=inputs=2:duration=longest:dropout_transition=2:weights=1 2,\
			dynaudnorm=p=0.9:s=5,\
			volume=3.0[out]" \
		-map "[out]" \
		-ar 16000 \
		-ac 1 \
		-acodec pcm_s16le \
		"$output_file" 2>/dev/null &

	# Save PID to file immediately
	echo $! >"$pid_file"
}

# Transcribe audio file with Whisper
# Args:
#   $1 - audio file path
#   $2 - language code (default: es)
# Returns: transcribed text (stdout), empty if failed
transcribe_audio() {
	local audio_file="$1"
	local lang="${2:-es}"

	# Validate audio file exists and has content
	if [ ! -f "$audio_file" ] || [ ! -s "$audio_file" ]; then
		return 1
	fi

	# Check minimum duration (0.5 seconds)
	local duration
	duration=$(ffprobe -v error -show_entries format=duration \
		-of default=noprint_wrappers=1:nokey=1 "$audio_file" 2>/dev/null)

	# Check if duration is valid and >= 0.5s
	if [ -z "$duration" ]; then
		return 1
	fi

	# Use bc for float comparison (if available), otherwise assume valid
	if command -v bc &>/dev/null; then
		if (($(echo "$duration < 0.5" | bc -l))); then
			return 1
		fi
	fi

	# Transcribe with Whisper
	whisper-cli \
		-m "$MODEL" \
		-f "$audio_file" \
		-l "$lang" \
		-nt \
		-t 16 \
		--no-prints 2>/dev/null
}

# Get audio file duration in seconds
# Args:
#   $1 - audio file path
# Returns: duration in seconds (float), empty if failed
get_audio_duration() {
	local audio_file="$1"

	ffprobe -v error -show_entries format=duration \
		-of default=noprint_wrappers=1:nokey=1 "$audio_file" 2>/dev/null
}

# Format seconds as MM:SS
# Args:
#   $1 - seconds (integer)
# Returns: formatted string (e.g., "02:35")
format_duration() {
	local seconds="$1"
	local minutes=$((seconds / 60))
	local secs=$((seconds % 60))

	printf "%02d:%02d" "$minutes" "$secs"
}

# Copy text to clipboard (fallback for xdotool)
# Args:
#   $1 - text to copy
# Returns: 0 if successful
copy_to_clipboard() {
	local text="$1"

	if command -v xclip &>/dev/null; then
		echo -n "$text" | xclip -selection clipboard
		return 0
	else
		return 1
	fi
}
