from urllib.request import urlopen, Request
import json
import csv
import time

START_KEY = 1140
END_KEY = 1251
OUTPUT_CSV = "weather_test.csv"

all_weather = []

for meeting_key in range(START_KEY, END_KEY + 1):
    url = f'https://api.openf1.org/v1/weather?meeting_key={meeting_key}'
    print(f"Fetching weather for meeting {meeting_key}...")

    try:
        req = Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            if data:
                print(f"Found {len(data)} rows for meeting {meeting_key}")
                all_weather.extend(data)
            else:
                print("No data.")
    except Exception as e:
        print(f"Error for meeting {meeting_key}: {e}")
    time.sleep(2)

# Save to CSV
if all_weather:
    keys = all_weather[0].keys()
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=keys)
        writer.writeheader()
        writer.writerows(all_weather)
    print(f"\nSaved {len(all_weather)} total rows to {OUTPUT_CSV}")
else:
    print("\n No weather data found for any meeting.")
