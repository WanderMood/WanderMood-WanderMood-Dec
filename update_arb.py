import json
import os

files = [
    "lib/l10n/app_en.arb",
    "lib/l10n/app_nl.arb",
    "lib/l10n/app_de.arb",
    "lib/l10n/app_es.arb",
    "lib/l10n/app_fr.arb"
]

updates = {
    "moodMatchHubPendingStory": "We just need your friend.",
    "moodMatchHubOpenPlan": "Open plan",
    "moodMatchHubNudgeFriend": "Nudge friend"
}

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Update existing, add new
    data["moodMatchHubPendingStory"] = updates["moodMatchHubPendingStory"]
    data["moodMatchHubOpenPlan"] = updates["moodMatchHubOpenPlan"]
    data["moodMatchHubNudgeFriend"] = updates["moodMatchHubNudgeFriend"]
    
    # Remove old keys
    if "moodMatchHubContinueWaiting" in data:
        del data["moodMatchHubContinueWaiting"]
    if "moodMatchHubShareAgain" in data:
        del data["moodMatchHubShareAgain"]
    if "moodMatchHubSendReminder" in data:
        del data["moodMatchHubSendReminder"]
        
    with open(file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')

print("Updated arb files")
