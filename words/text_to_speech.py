import csv
import re
from pathlib import Path

from google.cloud import texttospeech

# Find the CSV file in the same folder as this script.
FOLDER = Path(__file__).resolve().parent
CSV_FILE = FOLDER / "stimuli.csv"
OUTPUT_FOLDER = FOLDER / "audio_files"

# British English female voice.
LANGUAGE_CODE = "en-GB"
VOICE_NAME = "en-GB-Standard-B"

def safe_filename(word):
    """Make a word safe to use in a filename."""
    name = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", word)
    return name.strip(" .") or "word"

def main():
    if not CSV_FILE.exists():
        print(f"Cannot find: {CSV_FILE}")
        print("Put stimuli.csv in the same folder as this script.")
        return

    # Read the first column of the CSV.
    words = []
    with CSV_FILE.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.reader(file)
        for row_number, row in enumerate(reader):
            if not row or not row[0].strip():
                continue

            word = row[0].strip()

            # Skip a common column heading if present.
            if row_number == 0 and word.lower() in {
                "word", "words", "english"
            }:
                continue

            words.append(word)

    if not words:
        print("No words found in the CSV.")
        return

    OUTPUT_FOLDER.mkdir(exist_ok=True)

    # Connect to Google Text-to-Speech.
    client = texttospeech.TextToSpeechClient()

    voice = texttospeech.VoiceSelectionParams(
        language_code=LANGUAGE_CODE,
        name=VOICE_NAME,
    )

    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.LINEAR16,
        speaking_rate=0.85,
    )

    print(f"Generating {len(words)} audio files...")

    for number, word in enumerate(words, start=1):
        synthesis_input = texttospeech.SynthesisInput(text=word)

        response = client.synthesize_speech(
            input=synthesis_input,
            voice=voice,
            audio_config=audio_config,
        )

        # Number files so duplicate words won't overwrite each other.
        filename = f"{safe_filename(word)}.wav"
        output_path = OUTPUT_FOLDER / filename

        with output_path.open("wb") as audio_file:
            audio_file.write(response.audio_content)

        print(f"{number}/{len(words)} Saved: {filename}")

    print("\nFinished! Your WAV files are in:")
    print(OUTPUT_FOLDER)

if __name__ == "__main__":
    main()