# Radio recordings (native speakers)

`game.html` plays the radio warning from this folder first:

| File | What to record | Used in |
|---|---|---|
| `warning_zu.mp3` | A native isiZulu speaker reading the eThekwini newsflash text exactly as written (see `data/warning_language.json`, event 2023-06-27), in a radio-announcer register | Night scene, first playthrough |
| `warning_en.mp3` | The plain-language warning in `methods/scripts/game_content.ps1` (`fixed_warning`) | Night scene, replay |
| `warning_ve.mp3` (optional) | A Tshivenda version, once a verified Tshivenda warning is sourced | Future swap |

Record in a quiet room; the game adds rain and static on top. Get written consent, and credit the speakers.

If a file is missing, the game falls back to the browser's synthetic voice for that language. Microsoft Edge usually provides an isiZulu voice. If there is no voice either, it plays radio static with an on-screen caption.