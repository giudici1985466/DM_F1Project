import urllib.request
import json
import csv
import time

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
        session_name = session.get("session_name")
        if session_type == "Race" and session_name == "Race":
            session_key = session.get("session_key")
            race_sessions.append((meeting_key, session_key))
    return race_sessions

def get_speed(session_key, meeting_key):
    url = f"{API_BASE}/laps?session_key={session_key}&meeting_key={meeting_key}"
    data = get_json(url)
    return data  # lista di lap

def main(years, output_csv):
    all_lap_speeds = []

    for year in years:
        race_sessions = get_meetings_and_races(year)
        print(f"Trovate {len(race_sessions)} gare nella stagione {year}")

        for meeting_key, session_key in race_sessions:
            print(f"Recupero speed per {meeting_key} - {session_key}")
            laps_speed = get_speed(session_key, meeting_key)
            time.sleep(0.5)

            for lap in laps_speed:
                driver_number = lap.get("driver_number")
                st_speed = lap.get("st_speed")
                lap_number = lap.get("lap_number")
                if st_speed is not None and driver_number is not None and lap_number is not None:
                    all_lap_speeds.append({
                        "year": year,
                        "meeting_key": meeting_key,
                        "session_key": session_key,
                        "driver_number": driver_number,
                        "lap_number": lap_number,
                        "st_speed": st_speed
                    })

    with open(output_csv, "w", newline='') as f:
        fieldnames = ["year", "meeting_key", "session_key", "driver_number", "lap_number", "st_speed"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_lap_speeds)

    print(f"Salvati {len(all_lap_speeds)} giri con velocità in {output_csv}")


if __name__ == "__main__":
    main(
        years=[2023, 2024],
        output_csv="C:/Users/angel/UNIVERSITA'/Engineering in Computer Science/Secondo Semestre/DataManagement/Progetto/etl_transformation/input_files/speed_no_avg.csv"
    )
