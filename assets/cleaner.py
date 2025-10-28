import json

# Read both files
with open('assets/hanja1.json', 'r', encoding='utf-8') as f:
    hanja1 = json.load(f)

with open('assets/hanja2.json', 'r', encoding='utf-8') as f:
    hanja2 = json.load(f)

# Combine the items
combined_items = hanja1['channel']['item'] + hanja2['channel']['item']

# Update total count
total_count = hanja1['channel']['total'] + hanja2['channel']['total']

# Create combined data structure
combined_data = {
    "channel": {
        "total": total_count,
        "item": combined_items
    }
}

# Save combined file
with open('assets/hanja_combined.json', 'w', encoding='utf-8') as f:
    json.dump(combined_data, f, ensure_ascii=False, indent=2)

print(f"Combining completed!")
print(f"hanja1 items: {hanja1['channel']['total']}")
print(f"hanja2 items: {hanja2['channel']['total']}")
print(f"Combined total: {total_count}")
print(f"Saved as assets/hanja_combined.json")