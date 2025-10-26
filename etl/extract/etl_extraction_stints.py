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
        session_name = session.get("session_name")
        meeting_key = session.get("meeting_key")
        if session_type == "Race" and session_name == "Race":
            session_key = session.get("session_key")
            race_sessions.append((meeting_key, session_key))
    return race_sessions


def get_stints_for_session(session_key):
    # Recupera gli stint per la sessione specificata
    url = f"{API_BASE}/stints?session_key={session_key}"
    data = get_json(url)
    return data  # lista di stint (dict)

def main(years, output_csv):
    all_stints = []

    for year in years:
        race_sessions = get_meetings_and_races(year)
        print(f"Trovate {len(race_sessions)} gare nella stagione {year}")

        for meeting_key, session_key in race_sessions:
            print(f"Recupero stint per {meeting_key} - {session_key}")
            stints = get_stints_for_session(session_key)
            time.sleep(10)
            for stint in stints:
                all_stints.append({
                    "year": year,  # aggiungiamo l'anno per chiarezza
                    "compound": stint.get("compound"),
                    "driver_number": stint.get("driver_number"),
                    "lap_end": stint.get("lap_end"),
                    "lap_start": stint.get("lap_start"),
                    "meeting_key": stint.get("meeting_key"),
                    "session_key": stint.get("session_key"),
                    "stint_number": stint.get("stint_number"),
                    "tyre_age_at_start": stint.get("tyre_age_at_start"),
                })

    if not all_stints:
        print("Nessun dato da scrivere.")
        return

    with open(output_csv, "w", newline='') as f:
        writer = csv.DictWriter(f, fieldnames=all_stints[0].keys())
        writer.writeheader()
        writer.writerows(all_stints)

    print(f"Salvati {len(all_stints)} stint in {output_csv}")

if __name__ == "__main__":
    main(
        years=[2023, 2024],
        output_csv="C:/Users/angel/UNIVERSITA'/Engineering in Computer Science/Secondo Semestre/DataManagement/Progetto/etl_transformation/input_files/stints.csv"
    )
