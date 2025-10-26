import urllib.request
import json
import csv
import time
from collections import defaultdict

API_BASE = "https://api.openf1.org/v1"

def get_json(url):
    with urllib.request.urlopen(url) as response:
        return json.loads(response.read().decode('utf-8'))

def get_meetings_and_races(year):
    url = f"{API_BASE}/sessions?year={year}"
    print(url)
    sessions_list = get_json(url)
    print(sessions_list)

    race_sessions = []

    for session in sessions_list:
        session_type = session.get("session_type")
        meeting_key = session.get("meeting_key")
        if session_type == "Race":
            session_key = session.get("session_key")
            race_sessions.append((meeting_key, session_key))
    return race_sessions

def get_speed(session_key, meeting_key):
    url = f"{API_BASE}/laps?session_key={session_key}&meeting_key={meeting_key}"
    data = get_json(url)
    return data  # lista di lap

def main(years, output_csv):
    all_average_speeds = []  # un unico file per tutti gli anni

    for year in years:
        speeds_data = defaultdict(lambda: {"total_speed": 0, "count": 0})

        race_sessions = get_meetings_and_races(year)
        print(f"Trovate {len(race_sessions)} gare nella stagione {year}")

        for meeting_key, session_key in race_sessions:
            print(f"Recupero speed per {meeting_key} - {session_key}")
            laps_speed = get_speed(session_key, meeting_key)
            time.sleep(0.5)

            for lap in laps_speed:
                driver_number = lap.get("driver_number")
                st_speed = lap.get("st_speed")
                if st_speed is not None and driver_number is not None:
                    key = (meeting_key, session_key, driver_number)
                    speeds_data[key]["total_speed"] += st_speed
                    speeds_data[key]["count"] += 1

        for (meeting_key, session_key, driver_number), values in speeds_data.items():
            if values["count"] > 0:
                avg_speed = int(values["total_speed"] / values["count"])  # conversione a intero
            else:
                avg_speed = 0
            all_average_speeds.append({
                "year": year,
                "meeting_key": meeting_key,
                "session_key": session_key,
                "driver_number": driver_number,
                "average_st_speed": avg_speed
            })

    with open(output_csv, "w", newline='') as f:
        fieldnames = ["year", "meeting_key", "session_key", "driver_number", "average_st_speed"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_average_speeds)

    print(f"Salvati {len(all_average_speeds)} record medi di velocità in {output_csv}")


if __name__ == "__main__":
    main(
        years=[2023, 2024],
        output_csv="C:/Users/angel/UNIVERSITA'/Engineering in Computer Science/Secondo Semestre/DataManagement/Progetto/etl_transformation/input_file/speed.csv"
    )
